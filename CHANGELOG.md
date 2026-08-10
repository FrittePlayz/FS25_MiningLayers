# Changelog

All notable changes to Mining Layers. Newest first.

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
