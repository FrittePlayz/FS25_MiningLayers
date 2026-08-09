# Mining Layers (FS25)

**Echtes Bergbau-Gameplay für den Landwirtschafts-Simulator 25 — grab dich durch geologische Schichten.**
Das Material bestimmt die Grabtiefe, nicht die Handauswahl: erst Mutterboden, dann Kies, dann Paydirt, dann Fels. Eigene Geologie pro Grube, Halden mit Gedächtnis und ein Ingame-Editor. Läuft auf **jeder Karte** — ohne Map-Bearbeitung.

Ein inoffizielles Addon, **powered by [TerraFarm](https://github.com/scfmod/FS25_TerraFarm)** (von scfmod — keine Verbindung).

🇬🇧 **English version: [README.md](README.md)**

---

## Voraussetzungen — zuerst lesen

1. **TerraFarm** — gibt es **nur auf GitHub**: [scfmod/FS25_TerraFarm](https://github.com/scfmod/FS25_TerraFarm).
   ⚠️ Den Ordner **nicht umbenennen** — er muss `FS25_0_TerraFarm` heißen (Ladereihenfolge).
2. **Mindestens eine Maschine mit TerraFarm-Config** — TerraFarm arbeitet nur mit Maschinen, die eine Machine-Konfiguration haben.
3. Empfohlen (kein Muss): eine Bergbau-Karte wie **Yukon (RGC)**. Mining Layers macht aber *jede* Karte zur Mining-Karte, auch Standard-Maps.

## Schnellstart

1. Neuestes `FS25_MiningLayers.zip` aus den [Releases](../../releases) laden und in den `mods`-Ordner legen.
2. Im Spiel einen **TerraFarm-Bereich** (Polygon) um die geplante Grube ziehen. Fertig — die Bezugshöhe holt sich der Mod automatisch vom Gelände am Bereichsrand.
3. Graben: Mutterboden → Kies → Paydirt → Fels. Die Anzeige links zeigt Tiefe und nächste Schicht.
4. Schichten ändern über **ESC-Menü → Mining Layers** (grafischer Editor, pro Grube) — oder von Hand in `modSettings/FS25_MiningLayers/miningLayers.xml`.

## Features

- **Material nach Grabtiefe** — Schichtgrenzen in Metern unter der ursprünglichen Oberfläche
- **Geologie pro Grube** — jeder TerraFarm-Bereich kann seinen eigenen Schichtaufbau haben (verschiedene Gruben, verschiedene Materialien, eine Karte)
- **Halden-Gedächtnis** — was du abkippst, nimmst du auch wieder auf. Kein Material-Cheaten: Wer eine Halde unter ihre Basis durchgräbt, trifft wieder auf Geologie (Krater-Cheat-Sperre inklusive)
- **Automatischer Grubenboden** — Zieltiefe = unterste Schichtgrenze, zieht bei Bereichs-Änderungen nach
- **Hang- und Wasser-Behandlung** — geneigte Bezugsfläche am Hang, Grubenboden klemmt an der Wasserlinie
- **Eigene Menüseite** — grafischer Schichten-Editor plus vollständige Ingame-Doku (Deutsch + Englisch)
- **Tiefenanzeige & Tiefenlinien** — du weißt immer, wie tief du bist und was als Nächstes kommt
- **Material-Check beim Start** — warnt vor der 63-Materialien-Grenze der Engine
- **Berg-Bonus** — am Steilhang liegt Paydirt oberflächennah: Wer die Anfahrt auf sich nimmt, wird belohnt
- Multiplayer-freundliches Sponsorschild (siehe unten), kein Sync-Verkehr

## Fallstricke, die man kennen sollte

- **63 Gelände-Materialien sind ein hartes Engine-Limit.** Basisspiel + Karte + Mods teilen es sich; zusätzliche Filltype-Mods können rausfliegen. Der Start-Check sagt dir, wo du stehst.
- **Absenken geht nur innerhalb des Polygons** (TerraFarm-Design). Ein Radlader schafft nur ~30–40 cm pro Ansatz — Rampe in die Grube fahren; der Bagger ist das Tiefen-Werkzeug.
- **Eine Hangflanke pro Bereich.** Bereiche über einen Bergkamm oder weit in einen See spannen die Bezugsebene falsch — Ufer-Bereiche hauptsächlich über Land ziehen.
- **Manche Karten sperren Terraforming** an Flussbett und Kartenrand (Engine-Sperrflächen). Da kommt kein Mod durch.
- Die Terrain-Texturnamen zur Laufzeit sind andere als in der `map.i3d` — der Mod löst das automatisch; pro Schicht per `paintLayer="..."` übersteuerbar.

## Konfiguration

`modSettings/FS25_MiningLayers/miningLayers.xml` — wird beim ersten Start aus der Vorlage angelegt und überlebt Mod-Updates. Schichtaufbau (Material + Tiefe, pro Bereich), Anzeige-Optionen und der Sponsorschild-Schalter stehen hier. Alles auch über das Ingame-Menü editierbar.

## Sponsor

Mining Layers wird unterstützt von **[farmersingles.de](https://farmersingles.de)** — der Singlebörse für Landwirte. 🚜❤️
Im Spiel zeigt sich das als kleines Schild am Grubenrand. Nicht gewünscht? `sponsorSign="false"` in der Config — das Schild verschwindet sofort, ohne Neustart.

## Credits

- **Autor:** Tommy Honold — Farmersingles.de
- Ein **FrittePlayz**-Projekt (YouTube)
- Powered by **TerraFarm** von [scfmod](https://github.com/scfmod) — dies ist ein inoffizielles Addon ohne Verbindung zu scfmod oder GIANTS Software.

## Support

Fehler gefunden? [Issue aufmachen](../../issues) — bitte mit `log.txt` und der gespielten Karte.
