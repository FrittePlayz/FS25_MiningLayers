#!/usr/bin/env python3
"""Prueft die l10n-Dateien gegen l10n_en.xml.

Drei Fehlerklassen, die im Spiel erst spaet auffallen:

1. Fehlender Key  -> das Menue zeigt den rohen Namen (ml_edSave) statt Text.
2. Platzhalter    -> %s/%d muessen in Zahl und Reihenfolge zu EN passen,
                     sonst bricht string.format zur Laufzeit ab.
3. Material-Token -> DIRT, GRAVEL, PAYDIRT usw. sind Fill-Type-Namen, die der
                     Editor englisch anzeigt. Wer sie uebersetzt, schickt den
                     Spieler nach einem Material suchen, das es im Menue nicht
                     gibt (l10n_it.xml, Stand 31.08.2026).

    python3 tools/l10n_check.py .

Rueckgabewert 0 = sauber.
"""
import pathlib
import re
import sys
import xml.etree.ElementTree as ET

MATERIALS = ["PAYDIRT", "LIMESTONE", "GRAVEL", "STONE", "DIRT", "SOIL", "SAND", "COAL"]
PLACEHOLDER = re.compile(r"%[sd]")


def load(path):
    texts = ET.parse(path).getroot().find("texts")
    return {e.get("name"): e.get("text") or "" for e in texts.findall("text")}


def main(root):
    l10n = pathlib.Path(root) / "l10n"
    base_path = l10n / "l10n_en.xml"
    if not base_path.exists():
        print(f"FEHLER: {base_path} fehlt")
        return 1

    base = load(base_path)
    problems = 0

    for path in sorted(l10n.glob("l10n_*.xml")):
        if path == base_path:
            continue
        lang = path.stem.replace("l10n_", "")
        try:
            cur = load(path)
        except ET.ParseError as exc:
            print(f"[{lang}] XML kaputt: {exc}")
            problems += 1
            continue

        for key, en_text in base.items():
            if key not in cur:
                print(f"[{lang}] fehlender Key: {key}")
                problems += 1
                continue

            if PLACEHOLDER.findall(en_text) != PLACEHOLDER.findall(cur[key]):
                print(f"[{lang}] Platzhalter weichen ab bei {key}: "
                      f"EN {PLACEHOLDER.findall(en_text)} -> {PLACEHOLDER.findall(cur[key])}")
                problems += 1

            for material in MATERIALS:
                if material in en_text and material not in cur[key]:
                    print(f"[{lang}] Material-Token {material} fehlt bei {key} "
                          f"- Fill-Type-Namen bleiben englisch")
                    problems += 1

        for key in cur:
            if key not in base:
                print(f"[{lang}] Key ohne EN-Gegenstueck: {key}")
                problems += 1

    if problems:
        print(f"\n{problems} Befund(e).")
        return 1

    print(f"l10n sauber: {len(base)} Keys in "
          f"{len(list(l10n.glob('l10n_*.xml')))} Sprachen.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "."))
