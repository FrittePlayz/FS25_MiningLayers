#!/usr/bin/env python3
"""Prueft Lua-Dateien auf unbalancierte String-Literale.

Hintergrund: beim Uebersetzen der Logs auf Englisch sind Apostrophe in den Text
geraten ("TerraFarm's"), die einen mit ' begrenzten Lua-String vorzeitig beenden -
ein Syntaxfehler, der den ganzen Mod am Laden hindert. Ohne luac im System ist
das hier die Absicherung.

Lua-Kurzstrings duerfen keinen echten Zeilenumbruch enthalten: bleibt am
Zeilenende ein String offen, ist das ein Fehler.
"""
import pathlib
import sys

def check_line(line):
    """Gibt None zurueck, wenn die Zeile sauber ist, sonst eine Meldung."""
    i = 0
    n = len(line)
    quote = None
    start = 0

    while i < n:
        c = line[i]

        if quote is None:
            if c in ("'", '"'):
                quote = c
                start = i
            elif c == '-' and line.startswith('--', i):
                if line.startswith('--[[', i) or line.startswith('--[=', i):
                    return None
                return None  # Zeilenkommentar: Rest ist egal
            elif c == '[' and line.startswith('[[', i):
                return None  # Langstring - zeilenuebergreifend, hier nicht bewertbar
        else:
            if c == '\\':
                i += 2
                continue
            if c == quote:
                quote = None

        i += 1

    if quote is not None:
        return 'offener %s-String ab Spalte %d' % (quote, start + 1)

    return None


def main():
    root = pathlib.Path(sys.argv[1])
    files = sorted(root.glob('scripts/**/*.lua'))
    bad = 0

    for f in files:
        for num, line in enumerate(f.read_text(encoding='utf-8').splitlines(), 1):
            problem = check_line(line)

            if problem is not None:
                bad += 1
                print('  %s:%d  %s' % (f.relative_to(root), num, problem))
                print('       %s' % line.strip()[:120])

    print('\n%d Dateien geprueft, %s' % (len(files), 'ALLES SAUBER' if bad == 0 else '%d PROBLEM(E)' % bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
