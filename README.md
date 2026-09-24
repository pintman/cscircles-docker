# cscircles-docker

Docker Container for CS-Circles. Mainly its based on the wordpress container but enriched
with python3jail and safeexec which are needed to safely execute python code.

## Installation

1. Check out this repo.
2. Change the mysql root password in ``docker-compose.yml``.
3. Start the services with ``docker-compose up -d`` (this may take a
   while). During this step python3jail and safeexec will be installed
   at ``/cscircles/python3jail`` and ``/cscircles/safeexec``.
4. Go to http://localhost:8888 and follow the installation
   instructions of your wordpress installation - the service is by
   default exposed on port 8888.
5. All files will be created in a new folder ``data`` next to the 
   ``docker-compose.yml`` file.
6. Follow the instructions from
[cscircles-wp-content repo](https://github.com/cemc/cscircles-wp-content) to
   replace the wp-content folder and setup the cscircles wordpress plugin.

## Deutsche Lektionen (Teilmenge)

`tools/html2wxr.py` wandelt gespeicherte „Page source“-Seiten von
<https://cscircles.cemc.uwaterloo.ca/> (Links „source code for the page“)
in eine WordPress-WXR-Datei um. Die Inhalte selbst liegen nicht im Repo
(`import/` ist ignoriert).

- Lizenz der Inhalte: © CEMC, University of Waterloo,
  [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/).
- HTML-Dateien nach `import/sources-de/` legen, dann:
  `python3 tools/html2wxr.py import/sources-de -o import/cscircles-de.xml`
- Vorhandener Bestand (2018): 19 Lektionen 0, 1, 1E, 2, 2X, 3, 4, 5, 6,
  6D, 7, 7A, 7B, 7C, 8, 9, 10, 13, 14; es fehlen 11, 12, 15+; keine
  Polylang-Verknüpfung zu den englischen Seiten.
- Import (Polylang-Sprache „Deutsch“/`de` vorher anlegen, `wordpress-importer` aktiv):
  `wp import import/cscircles-de.xml --authors=skip`, danach in pybox
  „Rebuild Databases“ ausführen.
- `@file:`-Referenzen benötigen `wp-content/lesson_files/` aus
  `cscircles-wp-content`.
