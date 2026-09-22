# Plan: Audit-Fixes cscircles-docker

Stand: 2026-09-22

## Phase 1 – risikoarm (ohne Versionswechsel)

- [ ] **Secrets aus Compose entfernen**: Passwörter via `.env` (`${MYSQL_ROOT_PASSWORD}`, `${WORDPRESS_DB_PASSWORD}`), `.env.example` committen, `.env` in `.gitignore`.
- [ ] **Eigener DB-User**: `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` setzen; `WORDPRESS_DB_USER`/`WORDPRESS_DB_NAME`/`WORDPRESS_DB_HOST` entsprechend.
- [ ] **Port nur lokal**: `127.0.0.1:8888:80`.
- [ ] **MySQL persistent**: Volume `./data/mysql:/var/lib/mysql`.
- [ ] **Abhängigkeiten**: `depends_on: [mysql]`, `restart: unless-stopped` für `cscircles`.
- [ ] **Hygiene**: `MAINTAINER` → `LABEL maintainer=…`; `version: '2'` entfernen; `sudo` aus apt-Liste streichen.
- [ ] README an neue Schritte anpassen (`.env` anlegen statt Compose editieren).

## Phase 2 – Härtung

- [ ] **`privileged: true` entfernen**: benötigte Capabilities von safeexec ermitteln (vermutl. `SYS_CHROOT`, `SETUID`, `SETGID`, `SYS_RESOURCE`) und nur diese per `cap_add` vergeben. Testen: Python-Code in CS-Circles ausführen.
- [ ] **Pinning**: safeexec/python3jail auf feste Commit-Hashes; Python-Tarball per SHA256 prüfen.
- [ ] **Jail verschlanken**: statt `cp /lib* ` nur per `ldd` ermittelte Libs kopieren.
- [ ] **Multi-Stage-Build**: Build-Tools und Python-Quellen nicht ins finale Image (TODO Dockerfile:25).

## Phase 3 – Modernisierung (größtes Risiko)

- [ ] Basis-Image: `wordpress:4.9` → aktuelles `wordpress:6.x-apache`.
- [ ] DB: `mysql:5.7` → `mysql:8` bzw. `mariadb:11`; Migration bestehender Daten klären.
- [ ] Python in der Jail: 3.6.1 → aktuelle Version.
- [ ] Kompatibilität prüfen: safeexec, python3jail, cscircles-wp-content-Plugin mit neuen Versionen.
- [ ] Optional: HTTPS via Reverse Proxy (z. B. Caddy/Traefik), falls nicht nur lokal genutzt.

## Offene Fragen

- Läuft die Instanz nur lokal oder öffentlich erreichbar? (beeinflusst Port-Binding, HTTPS)
- Existieren produktive Daten, die migriert werden müssen?
