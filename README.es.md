# Mining Layers (FS25)

[![Buy me fries](https://img.shields.io/badge/Buy%20me%20fries-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/fritteplayz)
[![Latest release](https://img.shields.io/github/v/release/FrittePlayz/FS25_MiningLayers?style=for-the-badge&color=2d8a4e)](https://github.com/FrittePlayz/FS25_MiningLayers/releases)
[![Idiomas](https://img.shields.io/badge/en--el--juego-ES%20·%20EN%20·%20DE%20·%20FR%20·%20PL%20·%20IT%20·%20PT-2d8a4e?style=for-the-badge)](#)

![Mining Layers — el material depende de la profundidad a la que excavas, un complemento para TerraFarm](docs/images/00_header.jpg)

**Minería de verdad en Farming Simulator 25: excava a través de capas geológicas, o monta tu propia gravera en FS25.**
Lo que acaba en la cuchara depende de lo hondo que excaves, no de un menú desplegable: primero tierra vegetal, después grava, más abajo la veta rentable y roca al fondo. Desde la 1.4.0 la veta es seleccionable — mina de carbón, gravera o cantera de caliza, en cualquier mapa y sin editar el mapa. **El mod y su manual dentro del juego están completos en español.**

🇬🇧 [English](README.md) · 🇩🇪 [Deutsch](README.de.md) · 🇫🇷 [Français](README.fr.md) · 🇵🇱 [Polski](README.pl.md) · 🇮🇹 [Italiano](README.it.md) · 🇵🇹 [Português](README.pt.md) — *página ES compacta; la documentación completa está en la versión en inglés, el manual íntegro está en el juego, en español.*

---

## Vídeo

[![Este addon cambia TerraFarm en FS25 — Mining Layers, por Trakatrukis](docs/images/14_video_tutorial.jpg)](https://www.youtube.com/watch?v=2h5MmHTxUwU)

**[Trakatrukis](https://www.youtube.com/watch?v=2h5MmHTxUwU) presenta el mod en español** — el vídeo que dio origen a esta traducción.
El tutorial completo (29 minutos, de la instalación al bulldozer: las ranuras de terreno, la altura objetivo, el caso del agua y cómo excavar sin área dibujada) está [en alemán con subtítulos](https://www.youtube.com/watch?v=kR0h1_S8oHc) en inglés, alemán, francés, polaco, italiano y portugués.

---

## Requisitos

- **[TerraFarm](https://github.com/scfmod/FS25_TerraFarm)** de scfmod — solo en GitHub. No cambies el nombre de su carpeta: tiene que seguir siendo `FS25_0_TerraFarm` (orden de carga).
- Al menos **una máquina con configuración de TerraFarm** (por ejemplo el oficial `FS25_TerraFarmMachines`).
- **Solo PC o Mac** — es un script mod, las consolas no lo admiten.

Complemento no oficial, sin vinculación con scfmod ni con GIANTS. No se incluye ni se modifica ningún archivo de TerraFarm.

## Instalación

1. Descarga TerraFarm (enlace arriba).
2. Descarga `FS25_MiningLayers.zip` de las [releases](https://github.com/FrittePlayz/FS25_MiningLayers/releases).
3. Pon los dos ZIP — tal cual, sin descomprimir — en la carpeta de mods:
   `Documentos\My Games\FarmingSimulator2025\mods\`
4. Activa LOS DOS mods en la selección de mods de tu partida.

## Novedad en la 1.6: ya no hace falta dibujar un área

Hasta ahora había que trazar un polígono de TerraFarm y asignarlo a la máquina antes de que pasara nada — y esa era la razón número uno por la que la gente creía que el mod no funcionaba.

Ahora las capas valen en todo el mapa: en la página de capas elige el objetivo **«En todas partes (sin área)»**, ponlo en *Mining Layers* y guarda. Una instalación nueva ya viene así. **Una instalación existente mantiene su comportamiento** hasta que tú lo cambies — una actualización no debe tocar una partida en marcha.

Un área dibujada sigue valiendo donde la asignes, y las dos salidas intencionadas siguen igual: un área desactivada y un área con material puesto a mano no reciben capas. Así las obras y las zanjas siguen limpias con el modo global activado.

## La primera excavación, en un paso

Traza un área de TerraFarm (polígono) alrededor de la futura excavación y **deja vacíos los campos de material**. Eso es todo: excava en cualquier punto dentro del área y el material viene de la profundidad. O usa el modo «En todas partes» de arriba y no dibujes nada.

Ajustes y capas: menú ESC → Mining Layers. Ahí está también el manual completo, en español.

## Espesor de las capas

Mínimo 1,5 m por capa (el editor exige 1 m en la de arriba, 1,5 m debajo) — más fina que eso y la recogida de escombreras se rompe. **Con máquinas grandes como la PC 8000, 2 m por capa excava bastante mejor.**

## Las tres causas más habituales de «no me salen las capas»

1. **La máquina no tiene área de entrada asignada.** TerraFarm vincula las áreas a la MÁQUINA, no al sitio donde estás: ajustes de la máquina (`Y` por defecto) → elige tu área como entrada. Es el caso de soporte número uno.
2. **Hay un material puesto en el área** → el área trabaja a propósito como TerraFarm normal, sin capas (modo obra). Deja los campos de material vacíos.
3. **Estás excavando fuera del polígono**, o en un área de tipo camino — los caminos nunca tienen capas.

## Dos cosas que sorprenden

**El material entra en la cuchara pero no se descarga al suelo.** Cuántos materiales caben en el terreno lo decide tu mapa, no el juego: vale el ancho de canal de su height density map, según 2^n−1 — 63 ranuras con 6 bits, 127 con 7, 255 con 8. El juego base ya ocupa 48. Cuando se acaban las ranuras, los materiales registrados en último lugar se quedan fuera: funcionan en la cuchara y se venden, pero no se descargan sobre el terreno. El mod los marca con `(!)`, y el informe del mapa, en su página de menú, te dice en qué situación estás.

**PAYDIRT, COAL y LIMESTONE no son materiales del juego base** — tienen que venir de tu mapa o de un mod de minería (los mapas RGC como el Yukon Back Country los traen).

El resto de preguntas — graveras, carbón, capas personalizadas, descarga, mover el indicador — está en la [página en inglés](README.md), que es la completa.

## Teclas

**Teclado numérico /** muestra y oculta el indicador de profundidad mientras una máquina está activa (era Num 5 hasta la 1.4.3). **Num ✱** activa el modo mover: haz clic en el indicador para cogerlo, clic otra vez para soltarlo. Los dos se pueden reasignar en Opciones → Controles → Mining Layers.

## Traducción

El español del juego lo hemos traducido nosotros, a raíz del vídeo de **[Trakatrukis](https://www.youtube.com/watch?v=2h5MmHTxUwU)**. El portugués (pt y br) es una contribución de **Alicopower** ([Issue #7](https://github.com/FrittePlayz/FS25_MiningLayers/issues/7)) y el italiano de **marcols13** ([Discussion #1](https://github.com/FrittePlayz/FS25_MiningLayers/discussions/1)) — ¡gracias! **Las correcciones de hablantes nativos son muy bienvenidas**: abre una [issue](https://github.com/FrittePlayz/FS25_MiningLayers/issues) o un pull request (los archivos de idioma son XML sencillo en `l10n/`), y entras en los créditos.

Un apunte sobre los nombres de material: `DIRT`, `GRAVEL`, `PAYDIRT`, `COAL` y los demás **se quedan en inglés** en todos los idiomas. Son los nombres de tipo de relleno que el editor muestra tal cual — traducirlos mandaría a buscar un material que en el menú no existe.

## Fallos y dudas

[GitHub Issues](https://github.com/FrittePlayz/FS25_MiningLayers/issues) — **adjunta siempre tu `log.txt`** (`Documentos/My Games/FarmingSimulator2025/log.txt`, copiado justo después del problema). Trae la lista completa de mods y el error de verdad — sin él, normalmente no se puede ayudar.

## Patrocinio

Este mod está patrocinado por [farmersingles.de](https://www.farmersingles.de), una web de citas para gente del campo. El cartelito en la esquina de cada área ya no existe desde la 1.6.1.

*Mining Layers de Tommy Honold, Farmersingles.de. Un proyecto de [FrittePlayz](https://www.youtube.com/@FrittePlayz). Gratuito hasta ahora.*
