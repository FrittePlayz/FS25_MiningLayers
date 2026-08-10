# Changelog

All notable changes to Mining Layers. Newest first.

## [1.4.0.0] — 2026-08-10

### Added
- **Selectable pay seam** — the seam below the overburden is no longer hardwired to PAYDIRT. Pick COAL for a coal mine, LIMESTONE and STONE for a gravel pit, or GRAVEL, SAND, DIRT, SOIL. In the editor the seam is the fixed last row: material selectable, thickness and position fixed, bedrock below stays fixed. Requested by Tazweb on itch.io — thanks!
- Seam layers are marked `seam="true"` in `miningLayers.xml`, so hand-written configs with a non-PAYDIRT seam survive the editor round-trip. Old configs load as before (PAYDIRT above the bedrock counts as the seam).
- Fallback: if the map does not know the chosen seam material (COAL and LIMESTONE are not base-game fill types), the seam reverts to PAYDIRT with a log line instead of silently producing a pit with nothing in it.

### Changed
- **Minimum layer thickness enforced in the editor** — 1 m for the top layer, 1.5 m for every layer below. Thinner layers break spoil pile pickup; with big machines 2 m is the better choice (hint added to editor and manual).
- Help texts (editor hint, quickstart, manual) now describe the selectable seam.

### Fixed
- Version string in the log said 1.3.7.0.

### Translations
- **French and Polish** added — full UI and in-game manual (`l10n_fr.xml`, `l10n_pl.xml`), machine-translated; native-speaker corrections welcome via PR or the language poll.

## [1.3.7.0] — 2026-08-10

### Added
- New tip with screenshot in the in-game help: reaching the second layer with a dozer blade alone (mode *Flatten*, no rear ripper). Make the run long enough — the longer the pass, the deeper it cuts per go.
- Help note on how layer textures resolve on any map (automatic fallback, `paintLayer` override).

### Fixed
- Version string in the log said 1.3.5.0.

## [1.3.6.0] — 2026-08-09

### Changed
- STONE now paints a loose-stones ground texture (`MOSS_STONES` / `FOREST_STONES`) instead of a bare rock face where the map provides one. Maps without those layers fall back to `MOUNTAINROCK` / `ROCK` as before. Custom `paintLayer` settings are unaffected.

## [1.3.5.0] — 2026-08-09 — first public release

### Added
- **Material by digging depth** — topsoil, gravel, paydirt, rock. Layer boundaries in meters below the original surface.
- **Geology per pit** — every TerraFarm area can have its own layer stack, set in the in-game editor.
- **Spoil pile memory** — dumped material comes back as what it was; digging below a pile's base returns to geology. Includes crater-cheat protection.
- **Automatic pit floor**, tilted reference plane on slopes, waterline clamping.
- **In-game menu page** with a graphical layer editor and the full manual (English and German).
- **Depth display and depth lines**, plus a startup check against the engine's 63 terrain material limit.
- **Sponsor sign** at the pit edge, removable with `sponsorSign="false"`.

### Notes
- Requires [TerraFarm](https://github.com/scfmod/FS25_TerraFarm) by scfmod. Areas with a material assigned behave like plain TerraFarm; path areas are never layered.
- PC/Mac only — script mod, not available for console crossplay.

[1.3.7.0]: https://github.com/FrittePlayz/FS25_MiningLayers/releases/tag/v1.3.7.0
[1.3.6.0]: https://github.com/FrittePlayz/FS25_MiningLayers/releases/tag/v1.3.6.0
[1.3.5.0]: https://github.com/FrittePlayz/FS25_MiningLayers/releases/tag/v1.3.5.0
