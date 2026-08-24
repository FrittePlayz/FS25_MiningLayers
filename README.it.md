# Mining Layers (FS25)

[![Buy me fries](https://img.shields.io/badge/Buy%20me%20fries-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/fritteplayz)
[![Latest release](https://img.shields.io/github/v/release/FrittePlayz/FS25_MiningLayers?style=for-the-badge&color=2d8a4e)](https://github.com/FrittePlayz/FS25_MiningLayers/releases)
[![Lingue](https://img.shields.io/badge/in--gioco-IT%20·%20EN%20·%20DE%20·%20FR%20·%20PL%20·%20PT-2d8a4e?style=for-the-badge)](#)

![Mining Layers — il materiale dipende dalla profondità di scavo, un add-on per TerraFarm](docs/images/00_header.jpg)

**Vero gameplay minerario per Farming Simulator 25 — scava attraverso strati geologici, o crea la tua cava di ghiaia in FS25.**
Il materiale nella benna dipende da quanto scavi in profondità, non da un menu a tendina: prima il terreno vegetale, poi la ghiaia, poi il filone, roccia madre sul fondo. Dalla 1.4.0 il filone è selezionabile — miniera di carbone, cava di ghiaia o cava di calcare, su qualsiasi mappa, senza modificarla. **La mod e il suo manuale in gioco esistono per intero in italiano**, tradotti da **marcols13**.

🇬🇧 [English](README.md) · 🇩🇪 [Deutsch](README.de.md) · 🇫🇷 [Français](README.fr.md) · 🇵🇱 [Polski](README.pl.md) · 🇵🇹 [Português](README.pt.md) — *pagina IT compatta; la documentazione completa vive nella versione inglese, il manuale integrale è in gioco, in italiano.*

---

## Video tutorial

[![Mining Layers 1.6 — il tutorial completo su YouTube](docs/images/14_video_tutorial.jpg)](https://www.youtube.com/watch?v=kR0h1_S8oHc)

29 minuti, dall'installazione al dozer: gli slot di terreno, l'altezza obiettivo, il caso dell'acqua — e scavare senza un'area disegnata. Sottotitoli in italiano, inglese, tedesco, francese, polacco e portoghese.

---

## Requisiti

- **[TerraFarm](https://github.com/scfmod/FS25_TerraFarm)** di scfmod — solo su GitHub. Non rinominare la sua cartella: deve restare `FS25_0_TerraFarm` (ordine di caricamento).
- Almeno **una macchina con configurazione TerraFarm** (per esempio l'ufficiale `FS25_TerraFarmMachines`).
- **Solo PC o Mac** — è una script mod, le console non le accettano.

Add-on non ufficiale, nessuna affiliazione con scfmod né GIANTS. Nessun file di TerraFarm viene incluso o modificato.

## Installazione

1. Scarica TerraFarm (link qui sopra).
2. Scarica `FS25_MiningLayers.zip` dalle [release](https://github.com/FrittePlayz/FS25_MiningLayers/releases).
3. Metti entrambi gli ZIP — così come sono, senza estrarli — nella cartella mod:
   `Documenti\My Games\FarmingSimulator2025\mods\`
4. Attiva ENTRAMBE le mod nella selezione mod della tua partita.

## La prima cava, in un passaggio

Traccia un'area TerraFarm (poligono) attorno alla futura cava e **lascia vuoti i campi del materiale**. Tutto qui: scava ovunque dentro l'area e il materiale arriva dalla profondità.

Impostazioni e strati: menu ESC → Mining Layers. Lì trovi anche il manuale completo, in italiano.

## Spessore degli strati

Almeno 1,5 m per strato (l'editor impone 1 m per quello superiore, 1,5 m sotto) — più sottile e la ripresa dei cumuli si rompe. **Con macchine grandi come la PC 8000, 2 m per strato scava nettamente meglio.**

## Le tre cause più frequenti di "non ottengo strati"

1. **La macchina non ha un'area di ingresso assegnata.** TerraFarm lega le aree alla MACCHINA, non a dove ti trovi: impostazioni macchina (`Y` di default) → scegli la tua area come ingresso. È il caso di assistenza numero uno.
2. **Un materiale è indicato nell'area** → l'area lavora di proposito come TerraFarm normale, senza strati (modalità cantiere). Lascia vuoti i campi del materiale.
3. **Stai scavando fuori dal poligono**, oppure in un'area di tipo percorso — i percorsi non hanno mai strati.

## Due cose che sorprendono

**Il materiale resta nella benna ma non si scarica a terra.** Quanti materiali possono stare a terra lo decide la tua mappa, non il gioco: conta la larghezza di canale della sua height density map, secondo 2^n−1 — 63 posti a 6 bit, 127 a 7 bit, 255 a 8 bit. Il gioco base ne occupa già 48. Quando i posti finiscono, i materiali registrati per ultimi lo perdono: funzionano nella benna e si vendono, ma non si scaricano sul terreno. La mod li segna con `(!)` e il rapporto sulla mappa, nella sua pagina di menu, dice a che punto sei.

**PAYDIRT, COAL e LIMESTONE non sono materiali del gioco base** — devono arrivare dalla tua mappa o da una mod mineraria (le mappe RGC come Yukon Back Country li hanno).

Il resto delle domande — cave di ghiaia, carbone, strati personalizzati, scarico, spostare il display — è nella [pagina inglese](README.md), che è quella completa.

## Tasti

**Tastierino /** mostra e nasconde il display della profondità mentre una macchina è attiva (era Tastierino 5 fino alla 1.4.3). **Tastierino ✱** attiva la modalità sposta: clicca il display per prenderlo, riclicca per posarlo. Entrambi riassegnabili in Opzioni → Comandi → Mining Layers.

## Traduzione

L'italiano in gioco è un contributo di **marcols13** ([Discussion #1](https://github.com/FrittePlayz/FS25_MiningLayers/discussions/1)) — grazie! Il portoghese in gioco (pt e br) è un contributo di **Alicopower** ([Issue #7](https://github.com/FrittePlayz/FS25_MiningLayers/issues/7)) — grazie! Questa pagina è tradotta da noi: correzioni da madrelingua sono benvenute, apri una [issue](https://github.com/FrittePlayz/FS25_MiningLayers/issues) o una pull request (i file di lingua sono semplice XML in `l10n/`), e finirai nei crediti.

## Bug e domande

[GitHub Issues](https://github.com/FrittePlayz/FS25_MiningLayers/issues) — **allega sempre il tuo `log.txt`** (`Documenti/My Games/FarmingSimulator2025/log.txt`, copiato subito dopo il problema). Contiene la lista mod completa e l'errore vero — senza, di solito non possiamo aiutare.

## Sponsor

Questa mod è sostenuta da [farmersingles.de](https://www.farmersingles.de), un sito di incontri per agricoltori — da lì il piccolo cartello all'angolo di ogni area. `sponsorSign="false"` in `miningLayers.xml` e sparisce; nient'altro cambia.

*Mining Layers di Tommy Honold, Farmersingles.de. Un progetto [FrittePlayz](https://www.youtube.com/@FrittePlayz). Gratis finora.*

## Licenza

Mining Layers è gratuito da scaricare e da giocare, ma **non è libero di essere ridistribuito** — fsmodworks.com è l'unico luogo di download. Mirror, fork e mod pack non sono consentiti; quasi tutto il resto sì, e ciò che non è coperto viene di norma concesso se lo chiedi prima. Condizioni complete in [LICENSE](LICENSE).
