#!/bin/bash
# Idempotent setup: turns the plain WordPress instance into CS Circles.
# Run inside the container: docker compose exec cscircles cscircles-setup
set -euo pipefail

WP_ROOT=/var/www/html
WP_CONTENT_SRC=/usr/src/cscircles-wp-content
IMPORT_DIR=/import

URL=${CSCIRCLES_URL:-http://localhost:8888}
TITLE=${CSCIRCLES_TITLE:-CS Circles}
ADMIN_USER=${CSCIRCLES_ADMIN_USER:-admin}
ADMIN_PASSWORD=${CSCIRCLES_ADMIN_PASSWORD:-}
ADMIN_EMAIL=${CSCIRCLES_ADMIN_EMAIL:-admin@example.com}

wp() { command wp --allow-root --path="$WP_ROOT" "$@"; }
log() { echo "==> $*"; }

cd "$WP_ROOT"

if [ ! -f wp-config.php ]; then
  echo "wp-config.php fehlt - Container-Entrypoint noch nicht gelaufen?" >&2
  exit 1
fi

log "Warte auf Datenbank"
for i in $(seq 1 30); do
  wp db check >/dev/null 2>&1 && break
  if [ "$i" -eq 30 ]; then
    echo "Datenbank nicht erreichbar." >&2
    exit 1
  fi
  sleep 2
done

if [ ! -d wp-content/plugins/pybox ]; then
  backup="wp-content.bak-$(date +%Y%m%d-%H%M%S)"
  log "Ersetze wp-content (Backup: $backup)"
  mv wp-content "$backup"
  cp -a "$WP_CONTENT_SRC" wp-content
fi
mkdir -p wp-content/uploads wp-content/latex
chown -R www-data:www-data wp-content

if ! wp core is-installed 2>/dev/null; then
  if [ -z "$ADMIN_PASSWORD" ]; then
    echo "CSCIRCLES_ADMIN_PASSWORD nicht gesetzt." >&2
    exit 1
  fi
  log "Installiere WordPress ($URL)"
  wp core install --url="$URL" --title="$TITLE" \
    --admin_user="$ADMIN_USER" --admin_password="$ADMIN_PASSWORD" \
    --admin_email="$ADMIN_EMAIL" --skip-email
fi

log "Aktiviere Plugins und Theme"
wp plugin activate pybox polylang wp-latex wordpress-importer
wp theme activate pybox2011childTheme

log "Setze Pfade zu python3jail/safeexec"
wp option update cscircles_pjail /cscircles/python3jail/
wp option update cscircles_psafeexec /cscircles/safeexec/safeexec

log "Permalinks"
wp rewrite structure '/%postname%/' --hard

log "Polylang: Sprachen en/de, Standard en, keine Browser-Erkennung"
wp eval '
$model = new PLL_Admin_Model(get_option("polylang"));
$langs = array(
  array("name" => "English", "slug" => "en", "locale" => "en_US", "rtl" => 0, "term_group" => 0, "flag" => "us"),
  array("name" => "Deutsch", "slug" => "de", "locale" => "de_DE", "rtl" => 0, "term_group" => 1, "flag" => "de"),
);
foreach ($langs as $l) {
  if (!$model->get_language($l["slug"])) {
    $model->add_language($l);
    echo "Sprache angelegt: {$l["slug"]}\n";
  }
}
$opt = get_option("polylang");
$opt["default_lang"] = "en";
$opt["browser"] = 0;
update_option("polylang", $opt);
'

shopt -s nullglob
xmls=("$IMPORT_DIR"/*.xml)
if [ ${#xmls[@]} -gt 0 ] && [ "$(wp option get cscircles_content_imported 2>/dev/null || true)" != "1" ]; then
  for xml in "${xmls[@]}"; do
    log "Importiere $xml"
    wp import "$xml" --authors=skip
  done
  chown -R www-data:www-data wp-content

  log "Startseite"
  front=$(wp post list --post_type=page --title='0: Hello!' --field=ID --posts_per_page=1)
  [ -z "$front" ] && front=$(wp post list --post_type=page --name=0-de --field=ID --posts_per_page=1)
  if [ -n "$front" ]; then
    wp option update show_on_front page
    wp option update page_on_front "$front"
  else
    echo "Keine Startseite ('0: Hello!' bzw. 0-de) gefunden."
  fi

  log "Rebuild Databases"
  wp eval '$_REQUEST["submitted"] = "true"; cscircles_makedb_page();' \
    | sed -e 's/<[^>]*>/ /g' | grep -E 'insert (ok|bad)|Halting' || true

  wp option update cscircles_content_imported 1
elif [ ${#xmls[@]} -eq 0 ]; then
  log "Keine XML-Datei in $IMPORT_DIR - Import übersprungen"
else
  log "Inhalte bereits importiert - Import übersprungen"
fi

cat <<EOF

Fertig. Manuell noch (Admin: $URL/wp-admin):
- Appearance -> Menus: englisches Menü wählen, "Primary Menu English" anhaken
  (nur mit CEMC-Import vorhanden).
- Rebuild Databases braucht englische UND anderssprachige Seiten; bei reinem
  DE-Import meldet es "Halting".
EOF
