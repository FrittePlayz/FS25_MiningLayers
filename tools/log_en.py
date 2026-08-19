#!/usr/bin/env python3
"""Stellt die Log-Ausgaben von Mining Layers auf Englisch um.

Das Log ist das Support-Werkzeug: es landet in GitHub-Issues und im Discord, wo
Englisch die Arbeitssprache ist. Oreo (RGC) konnte seine eigenen Logs nicht lesen.

Sicherheit: jeder String muss exakt so oft vorkommen wie erwartet, und die
%-Platzhalter jeder Datei muessen vor und nach dem Umbau identisch sein -
sonst bricht das Skript ab, ohne zu schreiben.
"""
import json
import pathlib
import re
import sys

MAP_FILE = pathlib.Path(__file__).parent / 'log_map.json'


def placeholders(text):
    """Alle %-Platzhalter in Reihenfolge - die Signatur, die stimmen muss."""
    return re.findall(r'%[-+ #0-9.]*[sdifxXeEgGqc%]', text)


def log_strings(text):
    return [m.group(1) for m in re.finditer(r"MiningLayers\.log\(\s*'((?:[^'\\]|\\.)*)'", text)]


def main():
    root = pathlib.Path(sys.argv[1])
    mapping = json.loads(MAP_FILE.read_text(encoding='utf-8'))

    total = 0

    for rel, pairs in mapping.items():
        path = root / rel
        text = path.read_text(encoding='utf-8')
        before = log_strings(text)

        for de, en in pairs.items():
            # ⚠️ Ein Apostroph beendet den mit ' begrenzten Lua-String vorzeitig -
            # Syntaxfehler, der Mod laedt nicht mehr. Passiert beim Uebersetzen sofort
            # ("TerraFarm's"). Deshalb hier hart verboten: umformulieren.
            if "'" in en:
                sys.exit('ABBRUCH %s: Apostroph im englischen Text - umformulieren:\n  %s'
                         % (rel, en))

            if placeholders(de) != placeholders(en):
                sys.exit('ABBRUCH %s: Platzhalter weichen ab\n  DE %s\n  EN %s'
                         % (rel, de, en))

            needle = "'" + de + "'"
            count = text.count(needle)

            if count == 0:
                # Schon uebersetzt? Dann ist der Lauf eine Wiederholung - kein Fehler.
                if "'" + en + "'" in text:
                    continue

                sys.exit('ABBRUCH %s: nicht gefunden: %s' % (rel, de[:70]))

            text = text.replace(needle, "'" + en + "'")

        after = log_strings(text)

        if len(before) != len(after):
            sys.exit('ABBRUCH %s: Anzahl der Log-Aufrufe geaendert (%d -> %d)'
                     % (rel, len(before), len(after)))

        for i, (b, a) in enumerate(zip(before, after)):
            if placeholders(b) != placeholders(a):
                sys.exit('ABBRUCH %s: Platzhalter in Aufruf %d weichen ab\n  %s\n  %s'
                         % (rel, i, b, a))

        rest = [s for s in after if re.search(r'[äöüÄÖÜß]|ae |ue |oe |Gelaende|Bezugshoehe|Schicht|Bereich', s)]

        path.write_text(text, encoding='utf-8')
        total += len(pairs)
        print('%-45s %3d übersetzt, %d Zeilen noch mit deutschen Spuren'
              % (rel, len(pairs), len(rest)))

    print('\nGESAMT in diesem Lauf: %d Strings' % total)


if __name__ == '__main__':
    main()
