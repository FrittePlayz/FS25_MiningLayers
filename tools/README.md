# tools/ — Prüfskripte

Entwicklungswerkzeuge. **Gehören nicht ins Mod-Zip** — beim Bauen ausschließen (siehe unten).

## lua_strings.py

```
python3 tools/lua_strings.py .
```

Prüft jede Zeile in `scripts/**/*.lua` auf unbalancierte String-Literale. Rückgabewert 0 = sauber.

**Warum:** Beim Übersetzen der Log-Ausgaben auf Englisch (1.6.0.0) sind Apostrophe in die Texte
geraten — `'... TerraFarm's height check ...'`. Das Apostroph beendet den mit `'` begrenzten
Lua-String vorzeitig: Syntaxfehler, der Mod lädt nicht mehr. Sieben Stellen waren betroffen, alle
vor dem Bauen gefunden.

**Nach jeder Codeänderung laufen lassen.** Auf diesem Rechner gibt es keinen Lua-Interpreter
(nur `liblua*`, kein `lua`/`luac`/`luajit`-Binary) — dieses Skript ist der lokale Ersatz.
Auf dem Server steht `luac -p scripts/*.lua scripts/gui/*.lua` zur Verfügung; das ist die
härtere Prüfung, weil sie den vollen Parser benutzt. Beide fanden am 16.08. dasselbe Ergebnis.

**Regel für neuen Text:** englische Log-Strings ohne Apostroph formulieren
(„the TerraFarm height check" statt „TerraFarm's height check").

## log_en.py + log_map.json

Übersetzt Log-Strings anhand der Zuordnungstabelle. Bricht ab, wenn Platzhalter abweichen oder
ein Apostroph im Zieltext steht.

## Beim Bauen ausschließen

```
zip -q -r -X <ziel>.zip . -x ".git/*" ".github/*" ".gitignore" "dist/*" "tools/*"
```

Der `dist/`-Ausschluss verhindert, dass das alte Zip ins neue wandert; `tools/*` hält die
Python-Skripte aus dem Auslieferungspaket.
