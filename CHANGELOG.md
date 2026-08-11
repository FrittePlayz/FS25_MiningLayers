# Changelog

All notable changes to Mining Layers. Newest first.

## [1.4.2.0] — 2026-08-11 (in test, not yet released)

### Added
- **Movable display.** Num * (rebindable) toggles a move mode with a mouse cursor: left-click the display to pick it up, click again to drop it — the position saves automatically and is resolution-independent (normalized coordinates in `modSettings/FS25_MiningLayers/hud.xml`, clamped back on screen after resolution changes). Right-click resets to the default position. Drag&drop mechanics inspired by **HappyLooser's HL Hud System** (openly shared via FS25_ProductionInfoHud) — own implementation, no code copied. This replaces the HUD presets planned earlier.
- **"No input area assigned" hint.** The display now says explicitly when the machine has no area assigned as its input area — the number one support cause ("why do I get no layers?") — including where to fix it (machine menu, default `Y`). The quickstart texts in all four languages got the same clarification.
- **Display polish** (Tommy's design pass): a clear title band with a fine separator line, calmer padding, and the tip ticker at the bottom sits on its own darker band — layer data and news ticker are visually separated now.
- **Display width is capped** at the F1 help menu's width (read from the game, not hardcoded) — the box no longer grows with the longest tip; long lines wrap at word boundaries, wrapped tip lines indent slightly.
- Tips rotate slower: 20 seconds per tip instead of 12 (one constant, easy to tune).
- **Third key-registration path** for the toggle key, after HappyLooser's pattern: globally via `PlayerInputComponent.registerGlobalPlayerActionEvents`, which re-registers on every input context change and can never hold a stale event id. This is a live experiment for the still-open question why the game's binding resolution drops our callbacks on large mod lists (HL's mouse key demonstrably works on a 1721-mod installation). The log states once which path delivers callbacks; duplicate callbacks from two paths within 50 ms are deduplicated.

### Fixed
- **Dumping is no longer silently blocked when a layer zone is the machine's output area.** With a TerraFarm output area assigned, TerraFarm only dumps inside that area and only up to its target height — and the mod auto-sets a layer zone's target height to the pit floor below the terrain, so nothing would ever dump, anywhere, with no message (found live on the 243 Quarry map). The mod now detects a layer zone acting as output area and lets the output run free (exactly as without an area, one log line states it once); path areas, manual-material areas and disabled zones keep pure TerraFarm behavior.
- **Both timing edges of the 1-second handshake** between action system and direct fallback (known limits of 1.4.1.6): the handshake now works per press cycle instead of a global 1-second window, and only the action callbacks stamp it. Holding the key longer than a second no longer cancels its own toggle, and a quick double-tap on fallback installations no longer swallows the second press. A press that starts inside a menu (numpad input in dialogs!) no longer toggles when released outside.
- **Toggle key survives implement selection:** the registration guard now also accepts `isActiveForInputIgnoreSelection` — selecting an attached implement in the vehicle chain no longer kills the action path on the root vehicle (gamepads had no fallback to save them there).
- **Fallback key resolution hardened:** modifier keys are skipped (a binding like LCtrl+X no longer makes the fallback listen to LCtrl), and if the action is rebound to gamepad/mouse with no keyboard key left, the fallback disarms with one log line instead of silently polling the old default key. The resolver now logs errors instead of swallowing them.
- Map exit resets the complete fallback/input state (no ghost toggle on the next map load), the two independent registration warnings no longer suppress each other, the toggle log line is capped like the registration log, and the per-frame key polling now skips dedicated servers and caches its capability check.

### Docs
- New FAQ entry in all four READMEs: does the mod add a paydirt fill type to the map? (asked by SecondChanceGaming3709 on itch.io) — no, the mod registers no fill types. PAYDIRT is now correctly listed as non-base-game next to COAL and LIMESTONE (verified against the FS25 game data: `maps_fillTypes.xml` contains no PAYDIRT).
- Stale comments from the 1.4.1.x registration saga rewritten (spec header, registration docstring, history, loadMap) — they still described the EnhancedVehicle attempt instead of the shipped vehicle-API + fallback solution.
- README credit for HappyLooser; author link cleanup.

*Built locally by Dredd (Percy's 12-point review backlog + the movable-HUD spec), to be live-tested by Tommy before release.*

## [1.4.1.6] — 2026-08-10

### Fixed
- **The depth display toggle (Numpad 5) finally works — verified in-game.** The evening's diagnosis builds (1.4.1.4/1.4.1.5, never released) proved the action registration itself was fine: `success=true`, real event id, correct VEHICLE context, the binding present in the profile — and the callback still never fired, on any key. The game's binding resolution simply does not deliver the event on this installation (334 mods; suspicion: load order, since TerraFarm loads early as `FS25_0_*`). The registration now goes through the vehicle's own `addActionEvent` (TerraFarm's proven pattern, parameters included), and on top sits a **direct fallback**: if a key press is not handled by the action system within a second, the mod reads the key itself and toggles on release. Self-calibrating — on installations where the action system works, the fallback stays silent. Rebinding works in both paths: the fallback re-resolves the bound key from the input system after every menu close. The log states once when the fallback is active (our remote-diagnosis data point in every user log).
- Registration log lines now include the input context name (capped at 25 lines).

### Known limits (fallback path only)
- Keyboard only — no gamepad buttons in the fallback.
- No F1-help entry on installations where the action system drops the binding.
- The key also toggles on foot there (harmless: without a machine there is no display to show).
- Tap the key, don't hold it: two timing edges in the 1-second handshake between the two input
  paths are known and queued for 1.4.2 (holding >1 s can cancel its own toggle; on fallback
  installations a second tap within one second is ignored). Normal tapping is unaffected.

*Built and diagnosed locally by Dredd, live-tested by Tommy (toggle + rebinding), reviewed and released by Percy.*

## [1.4.1.3] — 2026-08-10 (pre-release until the in-game test passes)

### Docs
- FAQ (all four languages): "Why do I get no layers?" — top 3 causes, led by the real number one: the machine needs your area assigned as INPUT AREA (machine settings, default `Y`); TerraFarm links areas to the machine, not to your position. Root cause of raver's report, found via his log + screenshot. Quickstart/in-game texts get the same clarification with the next release.

### Fixed
- **Toggle key: registration now matches FS25_EnhancedVehicle exactly.** 1.4.1.2 registered an event (eventId returned) but the key stayed dead and the F1 help never showed the entry — Dredd's narrowing. Three deviations from the proven pattern removed: no more `removeActionEventsByTarget` inside the rebuild window (it most likely deleted the freshly added event), the event target is now the vehicle instead of the mod object, and the guard is `isOnActiveVehicle and getIsControlled` like EnhancedVehicle. Every registration is now logged with a counter, success flag and event id (capped at 25 lines).

## [1.4.1.2] — 2026-08-10 (pre-release until the in-game test passes)

### Fixed
- **Toggle key, third attempt — now via a proper vehicle specialization** (the exact pattern EnhancedVehicle, AutoDrive and Courseplay use in FS25). Dredd's log pinpointed why 1.4.1.1 stayed dead: `FSBaseMission.registerActionEvents` does not exist in FS25, so the registration was never called. The key now registers through the game's own `onRegisterActionEvents` event on every enterable motorized vehicle. Consequence: the key works while sitting in a vehicle (on foot there is no display, so no key needed). The log reports how many vehicle types carry the input spec.

## [1.4.1.1] — 2026-08-10

### Fixed
- **The Numpad 5 toggle did not react** (caught by Tommy's live test minutes after the 1.4.1.0 release). The key now registers on the mission's own input rebuild — at mission start and after every menu close — instead of through TerraFarm's machine specialization path, which never fired. Side effect, intended: the key also works on foot now. The log states explicitly whether the key was registered and, if not, why.

## [1.4.1.0] — 2026-08-10

### Added
- **Toggle key for the depth display** — **Numpad 5** switches the height/depth readout on and off while a machine is active. Rebindable in the game options (Options → Controls → Mining Layers), shown in the F1 help. Requested by raver on Discord — thanks! The key registers through TerraFarm's own input lifecycle, so it survives menu and vehicle changes (the reason an earlier attempt at this key was removed before release).
- FAQ (all four languages): how to toggle the display and how to move it via `displayPosX` / `displayPosY` — no extra HUD mod needed.
- FAQ + mod description (all four languages): there is **no pile limit** — dumped material becomes real terrain, the 2 m pile memory has no cap; one material per 2 m cell (last dump wins). Asked by GA on Discord — thanks!
- Bug report form on GitHub: `log.txt` is now a required attachment (it contains the full mod list and the actual error — the Hof Bergmann support rule). READMEs updated accordingly.
- FAQ (all four languages): custom layers — more dirt / different soil types per pit, all in the in-game editor. Asked by Slightpilot on Discord — thanks!

## [1.4.0.0] — 2026-08-10

### Added
- **Selectable pay seam** — the seam below the overburden is no longer hardwired to PAYDIRT. Pick COAL for a coal mine, LIMESTONE and STONE for a gravel pit, or GRAVEL, SAND, DIRT, SOIL. In the editor the seam is the fixed last row: material selectable, thickness and position fixed, bedrock below stays fixed. Requested by Tazweb on itch.io — thanks!
- Seam layers are marked `seam="true"` in `miningLayers.xml`, so hand-written configs with a non-PAYDIRT seam survive the editor round-trip. Old configs load as before (PAYDIRT above the bedrock counts as the seam).
- Fallback: if the map does not know the chosen seam material (COAL and LIMESTONE are not base-game fill types), the seam reverts to PAYDIRT with a log line instead of silently producing a pit with nothing in it.

### Changed
- **Minimum layer thickness enforced in the editor** — 1 m for the top layer, 1.5 m for every layer below; the thickness selector simply starts at the minimum for the selected layer. Thinner layers break spoil pile pickup; with big machines 2 m is the better choice (hint added to editor and manual).
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
