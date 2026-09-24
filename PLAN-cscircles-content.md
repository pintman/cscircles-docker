
---

# Plan: CS-Circles-Inhalte reproduzierbar einrichten

Stand: 2026-09-24

**Problem:** Container läuft, zeigt aber nur leeres WordPress 4.9.8 – README-Schritt 6 (cscircles-wp-content) nie ausgeführt, `pybox`-Plugin fehlt. Laufzeit ok: `safeexec` setuid, `python3jail/bin/python3` + `scratch/` vorhanden, `mysqli`/`mbstring` geladen.

**Ziel:** Idempotentes Setup-Skript macht WP-Instanz zu CS-Circles; Lektionen via CEMC-XML-Import (auf Anfrage/Erlaubnis bei CEMC).

Quellen: `cemc/cscircles-wp-content` → `README.md`, `install_content.txt`, `plugins/pybox/admin-options.php` (Options `cscircles_pjail`, `cscircles_psafeexec`), `plugins/pybox/plugin-config.php` (`PPYTHON3MODJAIL='/bin/python3'`, `PSCRATCHDIRMODJAIL='scratch/'` passen zur Jail).

## Dockerfile

- [x] `git clone https://github.com/cemc/cscircles-wp-content.git /usr/src/cscircles-wp-content`, auf Commit pinnen (`396f40d`).
- [x] wp-cli 2.10.0 (`/usr/local/bin/wp`, `/etc/wp-cli.yml` mit `mod_rewrite`) + `mysql-client`. PHP-Kompatibilität noch ungetestet.
- [x] `COPY cscircles-setup.sh /usr/local/bin/cscircles-setup`.

## Neu: `cscircles-setup.sh` (idempotent, root, `wp --allow-root`)

Skript geschrieben, **noch nie ausgeführt** (Build auf arm64-Mac scheitert an `cp /lib64/*` – Altproblem, Ziel ist x86; Test auf x86-Rechner).

- [ ] Auf DB warten (`wp db check` mit Retry).
- [ ] Fehlt `wp-content/plugins/pybox`: altes wp-content → `wp-content.bak-<datum>`, `/usr/src/cscircles-wp-content` kopieren, `chown -R www-data:www-data`.
- [ ] `wp-content/uploads` (optional `wp-content/latex`) anlegen, für www-data beschreibbar.
- [ ] `wp core install` nur falls nicht installiert (URL/Titel/Admin aus ENV).
- [ ] Plugins `pybox`, `polylang`, `wp-latex`, `wordpress-importer` aktivieren – alle bereits in `cscircles-wp-content` enthalten (Polylang 2.7.4, WP ≥ 4.9), keine Installation nötig.
- [ ] Polylang: Sprachen en/de per `PLL_Admin_Model` anlegen, `default_lang=en`, `browser=0`.
- [ ] Pybox 2011 Child Theme aktivieren (Slug aus `themes/`).
- [ ] `wp option update cscircles_pjail /cscircles/python3jail/`, `wp option update cscircles_psafeexec /cscircles/safeexec/safeexec`.
- [ ] `wp rewrite structure '/%postname%/' --hard`.
- [ ] Falls `/import/*.xml` vorhanden und Marker `cscircles_content_imported` fehlt: `wp import <xml> --authors=skip`, Startseite „0: Hello!“ (`show_on_front=page`, `page_on_front`), „Rebuild Databases“ per `wp eval` (Funktion in `admin-make-databases.php` prüfen), Marker setzen. Achtung: Rebuild bricht ab („Halting“), wenn nicht EN- **und** Nicht-EN-Seiten vorhanden sind → reiner DE-Import reicht nicht.
- [ ] Verbleibende manuelle Schritte ausgeben.

## docker-compose.yml

- [x] `./import:/import:ro` mounten.
- [x] ENV: `WORDPRESS_DB_HOST=mysql`, `CSCIRCLES_URL`, `CSCIRCLES_ADMIN_USER/PASSWORD/EMAIL`.
- [x] `depends_on: [mysql]`; `version: '2'` entfernt.

## .gitignore / README

- [x] `import/` ignorieren (Inhalte nicht im Repo, nur Skripte).
- [ ] README: `docker-compose up -d --build` → XML optional nach `./import/` → `docker-compose exec cscircles cscircles-setup` → manuell: Polylang Standardsprache en + „Detect browser language“ aus, Menü „Primary Menu English“ zuweisen (per wp-cli, falls einfach).
- [ ] Hinweis: XML bei CEMC anfragen (Kontakt s. u.).

## Lektionen bei CEMC anfragen

`install_content.txt`: „If you are seeking to make a complete clone of the CS Circles site, this requires contacting us for permission." Keine dedizierte CS-Circles-Mail bekannt.

- Kontaktformular: https://cemc.uwaterloo.ca/contact-us → Kategorie „Courseware“
- Telefon: +1 519 888 4808
- Post: CEMC, Faculty of Mathematics, University of Waterloo, 200 University Ave. W., Waterloo, ON N2L 3G1, Canada
- Alternativ: GitHub-Issue in `cemc/cscircles-wp-content` (öffentlich)
- Status 2026-09-23: CS Circles laut CEMC-Seite „undergoing maintenance and will be back soon“ → Antwort ggf. verzögert/Inhalte in Überarbeitung.

- [x] Anfrage absenden (Entwurf unten, Platzhalter `<…>` ausfüllen). → Abgeschickt am 2026-09-23 via Kontaktformular (Kategorie „Courseware“).
- [ ] Antwort/Erlaubnis dokumentieren (Lizenzbedingungen, erlaubte Nutzung, Sprachen).

### Entwurf

> **Subject:** Request for permission and lesson content export – self-hosted CS Circles instance for classroom use
>
> Dear CEMC Courseware team,
>
> I am a computer science teacher at <school name, city, Germany> and have been using CS Circles with my students for Python programming. As CS Circles is currently under maintenance, I would like to run a self-hosted copy for my classes so they can continue working with it.
>
> I have set up a Docker-based installation following the instructions in your GitHub repository `cemc/cscircles-wp-content` (WordPress with the pybox plugin, the Pybox 2011 child theme, and the safeexec/python3jail sandbox). The platform itself works, but the lessons and exercises are not part of the repository. `install_content.txt` states that a complete clone requires your permission, so I am writing to ask:
>
> 1. May I host a copy of the CS Circles lessons for non-commercial educational use at my school?
> 2. If so, could you provide the WordPress XML export of the lessons and exercises (English and, if available, German)?
> 3. Are there any licence terms or conditions I should follow (attribution, access restrictions, no public redistribution, etc.)?
>
> Planned use:
> - Audience: about <number> students at my school, access limited to <school network / login>.
> - Non-commercial, no fees, full attribution to CEMC / University of Waterloo.
> - The XML export will not be redistributed; it is kept out of the public repository (git-ignored) and only imported locally.
>
> I would be happy to share any fixes to the setup (e.g. the Docker configuration) with you if they are useful.
>
> Thank you very much for creating CS Circles and for considering my request.
>
> Kind regards,
> Marco Bakera
> <school name, address>
> <email>

## Deutsche Lektionen (Teilmenge)

- [x] `tools/html2wxr.py` erzeugt `import/cscircles-de.xml` aus lokal abgelegten `import/sources-de/*.html` (gespeicherte „Page source“-Seiten 2018, CC BY-NC-SA 3.0) – 19 Seiten, Details s. README. Inhalte nicht im Repo.
- Fehlen: Lektionen 11, 12, 15+; keine Polylang-Verknüpfung zu EN-Seiten.
- `@file:`-Referenzen zeigen auf `wp-content/lesson_files/` aus `cscircles-wp-content` (alle vorhanden).
- Setup-Skript: `/import/*.xml` bzw. Startseite „0: Hello!“ → bei nur DE-Import Startseite `0-de`.

## Risiken

- Plugin-Versionen für WP 4.9 und wp-cli/PHP-Kompatibilität beim Umsetzen ermitteln; aktuelle Polylang/Importer brauchen neueres WP → Pinning.
- Upgrade bleibt Phase 3 oben.

## Verifikation

- [ ] `docker-compose build && docker-compose up -d`, `docker-compose exec cscircles cscircles-setup` fehlerfrei.
- [ ] Zweiter Lauf: keine Änderung, kein Re-Import.
- [ ] `curl -s localhost:8888` zeigt pybox-Theme statt twentyseventeen.
- [ ] `wp option get cscircles_pjail` / `cscircles_psafeexec` korrekt.
- [ ] Übung: `print(1+1)` → „Run program“ → `2`.
- [ ] Mit Import: „My progress“ zeigt ~100 Übungen nach Lektionen.
