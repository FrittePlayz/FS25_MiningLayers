# Changelog

All notable changes to Mining Layers. Newest first.

## [1.6.3.3] — 2026-08-26 (in-game test pending)

### Fixed
- **Grade lock: scoops no longer flip material at a layer boundary.** Found by Tommy ("another 0.0 m to GRAVEL" that never resolved) and independently by TacticalOreo ("every scoop is different instead of sticking to said layer"): the layer choice only flips once the terrain drops *below* the boundary, but the terrain deformation lands millimetres *above* it — so a spot could hang on the old layer forever while neighbouring spots in the same scoop had already flipped, and scoops seemed to change material at random. Grade lock now aims 5 cm below the boundary, so each spot crosses it decisively: one pass, one material, and the next pass reliably picks up the next layer. A manually set target height within 5 cm of a boundary is still respected.

## [1.6.3.2] — 2026-08-26 (in-game test pending)

### Fixed
- **The mode status lines show on every display path now.** They were appended only on the layer path — on a fresh spot ("reference height not set yet"), in manual areas and other early exits they were missing, and the mode keys felt dead because nothing visible changed (found by Tommy the same night). The status block now lives in the one place every path runs through, right above the rotating tip.

## [1.6.3.1] — 2026-08-25 (in-game test pending)

### Fixed
- **Spoil mode no longer digs the seam as spoil.** Found by Tommy in the first real spoil-mode dig: the mode treated every layer with another layer below it as overburden — but in the mod's own standard scheme (overburden → seam → floor) the floor (STONE) always lies below the seam, so COAL and PAYDIRT dug as DIRT too. The seam has carried a `seam="true"` marker since 1.4.0 and the editor uses it; the spoil decision just never asked. Now the seam stays real (marker, or PAYDIRT as the fallback for older configs — the same rule the editor applies), the floor stays real as before, and the HUD line says "the seam and the floor stay real" in all seven languages.

## [1.6.3.0] — 2026-08-25 (in-game test pending)

### Changed
- **The mode switches are always visible now.** Spoil mode and grade lock used to appear in the height display only while ON — anyone who did not know the modes existed never learned about them. The display now carries two compact status lines with the current state and the key hint ("Spoil mode: OFF (Num 5)" / "Grade lock: ON (Num 2)"), green when active, dimmed when off; the key hint follows your actual binding. The detailed explanation lines still appear only while a mode is active. Suggested by Tommy while testing 1.6.2.

## [1.6.2.1] — 2026-08-25 (in-game test pending)

### Fixed
- **The Download Key file is now an `.xml`** (root element `<downloadKey>`, same markers and token inside). Measured on the first 1.6.2.0 start: the engine's `io.open` does not read a file, it EMPTIES it (0 bytes, write-mode semantics) — so the plain-text read path is gone and the key is read through the game's own XML API, which is read-only and proven across the mod corpus. A leftover `.txt` key now gets a log hint pointing at the `.xml` download instead of a silent "no key found".

## [1.6.2.0] — 2026-08-25 (superseded by 1.6.2.1 on the same evening, never shipped)

### Added
- **Grade lock** (Num 2, off by default): the dig stops at the layer boundary instead of cutting through two materials in one pass — the next pass picks up the next layer with its material. Asked for by the RGC mining crew ("digging less confusing"). Works in the lower/flatten path; a target height you set by hand yourself always wins, piles are exempt, and the deepest layer digs free as before. Also switchable via `holdGrade` in `miningLayers.xml`. Note: Num 2 doubles with a base-game light binding — rebindable under Options > Controls > Mining Layers.
- **Download Key check (report mode).** Mining Layers stays free — the Download Key from fsmodworks.com costs nothing and marks your copy against re-uploads. This build looks for the key file (`modSettings/FSMW/`, or a file with "key" in its name in the mods folder), verifies it offline and reports the result in log and height display. **It does not block anything yet**: this build measures the key path first; enforcement comes with a later release once the read path is proven in-game.

## [1.6.1.0] — 2026-08-25 (tester build for the RGC circle, in-game test pending)

### Added
- **Spoil mode** (Num 5, off by default): while a layer still has another layer below it, it digs as the spoil material (default DIRT) — only the deepest layer (the seam) stays real. One keypress turns a pit into overburden-and-seam instead of a rainbow of materials. Recognised mounds are exempt: the mound memory keeps its promise that what was dumped comes back. Asked for by the RGC mining crew.
- **Material colours in the height display.** The layer line and the next-layer line now carry the material's editor colour (dark materials are brightened so COAL stays readable on the dark HUD box), and the "another X m to <material>" line fades from the material colour to red as the bucket approaches the boundary — the layer change catches the eye before the bucket is in the new material. Display only, no change to digging.
- **A slots-full hint with a way out.** When the map's ground-material slots are full, the map report now points at filltype mods like Nonnus' *63 Alternative Filltypes* and explains the trade-off (fresh mining savegame, base-game crops lose tipping), plus a matching FAQ entry in the in-game manual. All seven languages.

### Removed
- **The sponsor sign at the pit edge is gone.** Until now every drawn area got a small farmersingles.de sign at one corner, switchable only per player via `sponsorSign="false"` in the local `miningLayers.xml` — a server admin could not turn it off for everyone, and the switch needed a savegame reload despite the docs saying "immediately". Asked for by TacticalOreo (RGC). Decision: the sign goes, the sponsor line in the credits stays. The `sponsorSign` attribute in existing config files is ignored and drops out the next time the editor saves; `signCompany01.i3d` from the base game is no longer loaded, the two logo textures have left the mod.

### Changed
- **Roadmap: mixed bucket loads** added to the Director's Cut — a per-material ledger in the bucket across a layer boundary, dumped as a mixed material that a screening plant separates. Community suggestion, too large for a point release (a fill unit holds one material, the mixed material needs its own ground slot, and dumping proportionally runs into the same engine limit scfmod flagged in TerraFarm #123).

### Changed
- **A Portuguese mod page** (`README.pt.md`), linked from the language switcher on all five other pages. The in-game manual has spoken Portuguese since 1.6.0; the page had not.

### Fixed
- **Eleven dead links in the FAQ index** on the English and German pages. The 1.6 FAQ entry *"Can I use everywhere and drawn areas at the same time?"* was inserted as number 9, which pushed every question after it up by one — the index still pointed at the old anchors, so jumping to any question from 9 on landed nowhere. The index is now generated from the headings themselves.

## [1.6.0.0] — 2026-08-16

### Late additions (folded in before release, 2026-08-18)
- **★ A target height you set yourself is never touched again — and the automatic pit floor is back.** The mod watches TerraFarm's area save path (`LandscapingManager:updateArea`): a *changed* target height arriving there can only come from the player (the editor only touches an unset height while drawing). Hand-set heights are remembered per savegame. Everything else gets a pit floor below the deepest layer automatically, as it did up to 1.5.0 — the 1.6 dilemma (Oreo's pad turning into a pit) is solved by watching the hand, not guessing from the value.
- **★ The target height now shows in the height display** — value and origin (`set by you` / `automatic`), plus a warning when it cuts off the lowest layer. Until now this stood only in the log, where nobody reads it.
- **The water clamp checks every corner of an area** (it sampled only point 1 and let a −7.2 m floor through at a shore), probes at terrain height too, and a floor below the water line that nobody set by hand heals itself on load. Deliberately flooding a pit stays possible: set the height yourself.
- **Rejected terrain changes are visible now** — engine state name in the log, and the display says when three strokes in a row moved zero volume (*"map block or target height reached"*) instead of leaving you digging against silence.
- The in-game manual no longer claims the mod moves the target height automatically in all cases (all seven languages updated).
- **The map report is no longer cut off in the menu.** It was the only paragraph assembled at runtime and inherited the four-line limit of the static ones — on maps with several findings the last sentences simply vanished (Percy's QC find). It now gets its own tall template and shrinks to its actual text height after filling.
- The "dig and sell only" line no longer says "them/they got no slot" — rephrased without number agreement in all seven languages, so it reads correctly for one material as for five.


### Added
- **Portuguese (pt) and Brazilian Portuguese (br)**, contributed by **Alicopower**. The mod page, the layer editor and the map report are now available in seven languages.
- **Layers now work without a drawn area.** Until now a TerraFarm polygon had to exist and be assigned to the machine before anything happened at all — the single most common reason people concluded the mod was not working. The surface reference grid from 1.5.0 supplies what was missing: the reference height is frozen from the undisturbed ground the first time a bucket touches a spot, so layers follow the terrain anywhere on the map without a fixed height being written into a file. A drawn area still wins wherever one is assigned to the machine, and the two deliberate exits stay exactly as they were — an area set to `enabled="false"` and an area with a material set by hand get no layers, so building sites and pipe trenches stay clean with the global mode on.
- **A switch on the layers page.** Target **"Everywhere (no area needed)"**, set it to *Mining Layers*, save. A fresh install already has it on; an existing installation keeps its behaviour until someone flips it, because an update should not change a running game. Switching it off keeps your layers instead of discarding them.
- **★ The target height becomes a tool.** With the mod no longer moving it (see *Fixed* below), the target height of a TerraFarm area does what it says: level a pad at ground level, cut a berm halfway up the pit wall, grade a ramp at a fixed slope — the dozer holds that line instead of digging through it. Until 1.5.0 this could not be used at all, because the mod pulled the height down by itself whenever it sat near ground level. Where your target height cuts off the lowest layer, the log now says so once per area and leaves the decision to you. Step 9 in the README shows it with a dozer.
- **Slot diagnosis at startup — with your map's real numbers.** The report now states how many ground slots this map has, how many are taken, and how wide its channel is: *"This map has 63 ground slots (6 channels) — 63 in use."* Both numbers are read from the running game, not calculated from an assumption, and the mod says when they are full — which is the actual cause behind material that digs and sells but will not tip back onto the ground. Measured on two maps while building this: a 6-channel map sat at 63 of 63 with three mining materials rejected, a 7-channel map at 83 of 127 with none rejected.
- **One line per session naming which side runs the digging path** (`Seite: dedicatedServer=…`). No effect on the game; it answers a multiplayer question from real server logs instead of a test session set up for it.

### Fixed
- **★ Fixed: the game could freeze with the bucket deep in the terrain.** With the bucket rammed into the ground or working against a steep wall, the mod threw a Lua error every frame — the log grew by ~10,000 lines per second, FS25 climbed to ~215% CPU, and the game had to be killed from outside. **This affected 1.4.3.0 and 1.5.0.0**; the setting behind it, `freeDumpHeight`, is on by default, so it reached you without you changing anything. Cause: TerraFarm guards ground-dumping twice — once for the bucket being inside the ground, once for the 0.5 m height check. We meant to lift only the height check and lifted both. Verified A/B/A/B on the same machine against the same wall: three freezes with the guard removed, zero errors across 3,825 log lines with it restored, including a deliberate ram. **If you are staying on an older version, set `freeDumpHeight="false"` in `miningLayers.xml`.**
- **Switching off a named area no longer wipes its layers.** Disabling an area in the editor left nothing behind but `<zone area="…" enabled="false"/>` — switch it back on and you got the defaults instead of your setup. The same action on the global target kept its layers, so the identical switch in the identical menu had two different outcomes, with no warning. Named areas now keep their layers too, on both the saving and the loading side. A disabled area still gets no layers, exactly as before.
- **★ The mod no longer moves a target height you set yourself.** Until now it lowered the pit floor of a layered area whenever that height sat within a metre of ground level — meant to catch the value an area starts out with, but it could not tell that apart from a height you set on purpose. Build a flat pad at ground level and you got a pit instead. Reported by TacticalOreo: *"it was digging to china when i set the height. I was making a pad but it was not paying attention to the target height."* **`autoTargetHeight` is off by default from now on**, and on existing installations it is switched off once, with a line in the log saying why. The mod instead tells you when your target height cuts off the lowest layer, and leaves the decision to you. Want the old behaviour? Set `autoTargetHeight="true"` — it then stays on.
- **The display no longer prints `globalZone` at you.** With layers applying everywhere, the panel showed the mod's internal name for that setting — a term from our own XML, untranslated in every language. It now shows the same word the editor uses for the target: `Zone: Everywhere   Layer: DIRT`. Where a drawn area applies, its name is shown as before.
- **The yellow scope line under the editor knew nothing about the target "Everywhere".** It fell into the default-zone branch and stated the opposite of what the target does ("applies to every area without its own layers"). It now has its own text in all seven languages.
- **"TerraFarm decides: the map's material" was wrong.** The normal case is the material set on your machine; the map's own material only takes over when the map ships resources *and* map resources are switched on both globally and on the machine (`LandscapingBase.lua:72` in TerraFarm 1.6.3.0). Display text and log line now say so.
- **The "no input area" message named only one of two ways out** — it now also points at the "Everywhere" target, which sits right next to it since 1.6.
- A disabled global zone no longer reports that layers apply "again" inside drawn areas when they never stopped.
- **A disabled global zone no longer vanishes from your configuration.** It was dropped at load time and therefore not written back when the layer editor saved — so the block silently disappeared from `miningLayers.xml` on the first save, without a word. It is now kept with its layers.
- **The depth display no longer goes quiet outside a drawn area.** It read the fixed reference height straight from the configuration; without one it had nothing to show while digging worked fine. It now takes the same route as the digging code.
- **No layer is guessed before the ground has been touched.** Without a reference height the topmost layer used to be returned, which is wrong on a spoil pile or at someone else's pit edge. The display now says the reference height is not set yet, and the log explains that it appears with the first bucket.
- **A refusal to dump now prints what the startup check said about that same material**, including the fill type index — and states plainly whether the two agree. Where they disagree, the log says it is a bug in this mod rather than blaming the map. Chasing GitHub issue #3 cost two days precisely because those two verdicts sat thousands of log lines apart.

### Changed
- **New header image on all five mod pages.** Shows the 1.6 headline feature — digging without a
  drawn area — with the in-game display as proof. The layer legend is back, now in English with a
  note that the depths are configurable; the old header mixed English and German. Brand mark
  updated to the current FrittePlayz logo.
- **A 29-minute video tutorial now sits at the top of every mod page**, right above the requirements — setup, ground slots, the target height, the water case and digging without a drawn area, shown in the running game. Subtitles in English, German, French, Polish, Italian and Portuguese.
- **The log is in English now.** Every line the mod writes to `log.txt` used to be German — including the diagnostics we ask you to send us. A player on the RGC server hit exactly that: his own log told him what was happening and he could not read it. All 195 messages are translated; the in-game display and the menu keep using your language as before. Logs travel to GitHub issues and Discord, so one shared language beats seven.
- **The `globalZone` in the template is no longer a test switch.** It ships enabled, without `surfaceY`, and with the same layer structure as the default zone. ⚠️ The old example carried a fixed `surfaceY="64.3"`: anyone enabling that block by hand put every layer at one single elevation — paydirt under the grass in a valley, nothing at all on a slope. If you edit the file by hand, set `enabled="true"` **and delete the `surfaceY` line**. If your `miningLayers.xml` has no `globalZone` block at all — which is the case for anyone who has ever saved in the layer editor, since that rewrites the file — there is nothing to edit: use the switch on the layers page, it writes the block for you.
- `aboveY` layers are rejected with a log line when there is no fixed reference height, instead of being sorted into the wrong place. Absolute and relative heights cannot be ordered against each other without a common reference — that is a limit, not a gap.

## [1.5.0.1] — 2026-08-15

Diagnostic build. No behaviour change — one log message was rewritten.

### Changed
- **A dump block now states what the map check said at load time, right next to the block.** Both verdicts come from the same function, so within one session they cannot disagree — but they used to sit thousands of log lines apart, which made GitHub issue #3 ("cant dump gravel", TacticalOreo) undecidable: one log said "0 materials without a terrain type" at startup, a screenshot from another session said GRAVEL had none. The message now names the fill type index, repeats the load-time verdict for that material, and says plainly whether the two agree. If they disagree, the log says it is a bug in Mining Layers and asks for the log; if they agree, it says the map and mod list ran out of ground-material slots. Height is still ruled out explicitly, and the message no longer asserts anything about the map that the mod has not measured.

## [1.5.0.0] — 2026-08-12

### Added
- **Layers now follow the terrain instead of one flat plane per area.** Until now the reference height was a single tilted plane fitted to the area outline, so over a crest or a hollow the layer boundary sat at the same absolute height everywhere — near the surface on the high ground, metres deep in the dip. The mod now freezes the height of the *undisturbed* ground in a 2 m grid at the moment the bucket first touches a spot, and every layer boundary is measured from the height at **that** spot. A 2 m topsoil layer is 2 m below the surface on the hill and 2 m below the surface in the hollow. On flat ground nothing changes.
- **The frozen reference survives the savegame.** Without it the first bucket after a restart would take the already lowered pit floor for grown ground, and the whole geology would sink with the pit. Stored per savegame in `modSettings/FS25_MiningLayers/surfaceMemory<index>.xml`, written through occasionally so a crash does not cost the session.
- **Italian**, contributed by **marcols13**. The mod page, the layer editor and the map report are now available in five languages.
- **The layer editor now knows what your map can actually do.** On every map load the mod checks each of its eight materials once: is the fill type registered here at all, and can it be dumped back onto the ground? The material picker then offers only what this map has — anything the map does not know disappears from the list instead of producing a seam that never shows up. What is missing is named right under the cross-section ("Not available on this map: …"), so the map gets the blame, not the mod. No more testing map by map.
- **Materials you can dig but not dump are marked `(!)`** — in the picker and in the cross-section — with one plain-language line explaining why: your mod list hit the engine's limit of 63 terrain materials, so digging, hauling and selling still work, only dumping back onto the ground does not. This is the case behind GitHub issue #3 (TacticalOreo, "cant dump gravel") and behind PAYDIRT/SOIL/LIMESTONE on the 243 Quarry map; it applies to the default layers as well, not just to named areas.
- The fallback for an unknown seam material is no longer hardcoded to PAYDIRT: it walks the map's actual material pool, so a map without PAYDIRT no longer ends up with a pit that has no pay seam at all.
- **Map report on the quickstart page: what THIS map can do.** Right at the top, before any general explanation, the mod now states which materials are usable here, which can only be dug and sold, and which are missing entirely — plus why (63 ground-material slots, 48 taken by the base game). Maps that bring a lot of their own ground materials — common for maps carried over from FS19/FS22 — run out of slots early; the report says so as an explanation, never as a verdict on the map. When everything works, it stays a single line.
- **Dumping now works at any bucket height, on any map.** TerraFarm refuses to dump onto the ground while terrain sits within about half a metre below the bucket edge (and while a work node is inside the terrain) — on flat ground that is almost always, and the message it shows ("action cannot be performed here") points at the place instead of the height. That is why dumping worked over a dug pit and failed two metres away on untouched ground. Mining Layers lifts that check. Set `freeDumpHeight="false"` in `miningLayers.xml` for TerraFarm's original behaviour.

### Changed
- **The display toggle moved from Numpad 5 to Numpad /.** Numpad 5 is the base game's front work light — our default sat on an occupied key, which is why the toggle could end up with no key at all. Measured against the base game and a 348-mod list, exactly two numpad keys are free: **Num /** (toggle display) and **Num ✱** (move display). ⚠️ **If you already have the mod installed, this changes nothing for you** — a new default only applies to profiles that do not know the action yet. If the display toggle or the move mode has no key on your setup, assign it once under **Options → Controls → Mining Layers**.
- **The limit on ground materials comes from the map, not from the game — the mod said otherwise and was wrong.** How many materials can lie on the ground is set by the channel width of the map's height density map, and maps differ: many allow 63, wider ones allow more. The base game takes 48 slots, the map's own materials register next, and the mod list gets what is left. Every text that called the 63 a hard engine limit has been rewritten, and the advice "remove mods" is no longer given where the map has room. Measured: one map registered 83 materials with nothing rejected, while another stopped at 63 and rejected ten. `grep addDensityMapHeightType log.txt` names every material a map turned away.

### Fixed
- **Saving in the editor no longer drops a hand-written `paintLayer`.** The editor rebuilt every layer from scratch, so a zone with `paintLayer="CONCRETE"` lost that attribute the moment you saved on that page — silently, and only visible later in the ground texture. Custom ground textures now survive editing; they are only dropped when you change that layer's material yourself (the setting would no longer match the layer). The "hand-written zone" warning was corrected accordingly — it still applies to fixed reference heights, not to paint layers.
- **Layers whose material a map does not know are no longer erased from your configuration.** They used to be skipped on load and were therefore missing from the file after the next save — one trip to a map without PAYDIRT and the setup was gone for good. They now rest instead: inactive on that map, written back on save, active again on a map that has the material. Never two pay seams: a resting seam comes back as a normal layer if the stack already has one.

### Docs
- FAQ from the 1.4.2.0 test day, in all four READMEs: dumping refused on flat ground (TerraFarm's ~0.5 m bucket-edge check), material in the bucket but not tippable (the 63 height-type limit), output-area behavior for free dumping. The move-display answer now describes the Num * move mode instead of the old config-file-only way.

## [1.4.2.0] — 2026-08-11

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

*Built locally by Dredd (Percy's 12-point review backlog + the movable-HUD spec), live-tested by Tommy on the 243 Quarry map — all test points green.*

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
