# Mining Layers (FS25)

[![Download](https://img.shields.io/badge/⬇%20Download-latest%20release-2d8a4e?style=for-the-badge&logo=github&logoColor=white)](https://github.com/FrittePlayz/FS25_MiningLayers/releases/latest)
[![Latest release](https://img.shields.io/github/v/release/FrittePlayz/FS25_MiningLayers?style=for-the-badge&color=2d8a4e)](https://github.com/FrittePlayz/FS25_MiningLayers/releases)
[![Languages](https://img.shields.io/badge/in--game-EN%20·%20DE%20·%20FR%20·%20PL%20·%20IT%20·%20PT-2d8a4e?style=for-the-badge)](#)
[![Buy me fries](https://img.shields.io/badge/Buy%20me%20fries-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/fritteplayz)

![Mining Layers — material by digging depth, a TerraFarm add-on](docs/images/00_header.jpg)

**Real mining gameplay for Farming Simulator 25 — dig through geological layers, or make your own gravel pit in FS25.**
Material is determined by digging depth, not by hand selection: topsoil first, then gravel, then paydirt, then rock. Since 1.4.0 the pay seam is selectable — build a coal mine, a gravel pit or a limestone quarry on any map. Per-pit geology, spoil piles that remember what you dumped, and an in-game editor. Works on **any map** — no map editing required. **The mod and its in-game manual are fully available in English, German, French, Polish, Italian and Portuguese.**

Mining Layers builds on **[TerraFarm](https://github.com/scfmod/FS25_TerraFarm)** by scfmod, which it requires to run. Unofficial add-on, not affiliated with scfmod.

🇩🇪 [Deutsch](README.de.md) · 🇫🇷 [Français](README.fr.md) · 🇵🇱 [Polski](README.pl.md) · 🇮🇹 [Italiano](README.it.md) · 🇵🇹 [Português](README.pt.md)

**[Video](#video-tutorial) · [Requirements](#requirements--read-this-first) · [Installation](#installation) · [First pit](#step-by-step-your-first-pit) · [FAQ](#faq) · [Changelog](#changelog) · [Roadmap](#roadmap)**

---

## Video tutorial

[![Mining Layers 1.6 — the full tutorial on YouTube](docs/images/14_video_tutorial.jpg)](https://www.youtube.com/watch?v=kR0h1_S8oHc)

29 minutes, from installation to the dozer: ground slots, the target height, the water case — and digging without a drawn area. Subtitles in English, German, French, Polish, Italian and Portuguese.

---

## Requirements — read this first

1. **TerraFarm** — available **only on GitHub**: [scfmod/FS25_TerraFarm](https://github.com/scfmod/FS25_TerraFarm).
   ⚠️ Do **not** rename its folder — it must stay `FS25_0_TerraFarm` (load order).
2. **At least one machine with a TerraFarm config** — TerraFarm only works with machines that have a machine configuration.
3. Recommended (not required): a mining map like **Yukon (RGC)**. Mining Layers turns *any* map into a mining map, including stock maps.

## Installation

1. Download the latest `FS25_MiningLayers.zip` from [Releases](../../releases).
2. Put the **ZIP file as-is** (do not unpack!) into your mods folder:
   - **Windows:** `Documents\My Games\FarmingSimulator2025\mods\`
   - **Steam on Linux (Proton):** inside the Proton prefix — `<your Steam root>/steamapps/compatdata/2300320/pfx/drive_c/users/steamuser/Documents/My Games/FarmingSimulator2025/mods/`. The Steam root varies by install (`~/.local/share/Steam`, `~/.steam/debian-installation`, …); the `compatdata/2300320` part is fixed.
3. Make sure [TerraFarm](https://github.com/scfmod/FS25_TerraFarm) (`FS25_0_TerraFarm`) is in the same folder.
4. Start the game and enable **both mods** in the mod selection of your savegame.

After starting, you'll find a new **Mining Layers** page in the ESC menu — with the full manual in-game:

![Mining Layers menu page](docs/images/01_menu_after_install.jpg)

## Step-by-step: your first pit

**1. Draw a TerraFarm area (polygon) around your future pit.** That's the whole setup — the mod takes the reference height automatically from the terrain at the area's edge:

![Draw an area](docs/images/03_draw_area.jpg)

**2. Start digging.** The Mining Layers panel on the left shows your zone, the current layer, your depth — and how far to the next layer:

![First dig — topsoil](docs/images/04_display_first_dig.jpg)

**3. Dig deeper: topsoil → gravel → paydirt → rock.** The pit floor stops automatically below the last layer:

![Deeper — gravel, paydirt next](docs/images/05_display_paydirt.jpg)

**4. Set your own layers — per pit.** ESC menu → Mining Layers → Layers tab. Under *Applies to* you pick the target: all areas as the default, or one specific pit — and whether that pit uses layers at all. Below that you set material and thickness per layer, and the preview on the left shows the resulting profile live:

![Layer editor](docs/images/02_layer_editor.jpg)

**5. Spoil piles remember their material.** Dump gravel, pick up gravel — even from the flanks. The panel tells you when pile memory is active. No material cheating: below the pile's base you're back in geology:

![Spoil pile memory](docs/images/07_mound_gravel.jpg)

**6. Mountain mining pays off.** On steep slopes paydirt sits near the surface — the reward for hauling up the mountain:

![Mountain mining](docs/images/10_mountain_paydirt.jpg)

**7. Know the limits.** Pits at the waterline flood visually (great for placer mining); some maps block digging at riverbeds and map edges entirely:

![Riverbed limit](docs/images/12_riverbed_limit.jpg)

**8. Dozers reach the second layer too.** With the blade alone — mode *Flatten*, no rear ripper. Make the run long enough: the longer the pass, the deeper it cuts per go:

![Second layer with a dozer blade](docs/images/13_dozer_second_layer.jpg)

**9. ★ Level to an exact height — the target height is your floor.** Set the pit floor of a
TerraFarm area in its editor, and the dozer levels down to that height and stops there. Build a
flat pad at ground level, a bench halfway down the pit, a haul road at a fixed grade — the height
you typed is the height you get. **New in 1.6:** until 1.5.0 the mod lowered that value on its own
whenever it sat near ground level, which turned a pad into a pit; it now leaves your target height
alone and only tells you in the log when it cuts off the lowest layer. Reported by TacticalOreo:
*"I was making a pad but it was not paying attention to the target height."*

![Levelling to the target height](docs/images/14_dozer_target_height.jpg)

## Any map

Mining Layers runs on any map. Layer textures automatically pick the closest ground texture the map offers (standard names like `GRAVEL`, `MOUNTAINROCK`, `MOSS_STONES`). If a map has nothing suitable, the player's own texture selection stays active — materials, layers and mounds work regardless. On the first dig the mod writes the map's full texture list to the log, so you can set your own `paintLayer` overrides.

## ⚠️ Two material fields per area — the one thing to get right

The single most common point of confusion. In the TerraFarm menu → **Landscaping areas** → select your area, there are **two material fields**: **Terraform** and **Discharge** (set via *Change material*). Both default to **"Not set"**.

1. **Both fields on "Not set"** → Mining Layers works: what ends up in the bucket depends on how deep you dig. **This is the delivery state of a freshly drawn area** — you don't have to do anything.
2. **Set a material on *Terraform*** → that area runs as a completely normal TerraFarm polygon area, no layers. Exactly right for construction sites, road building and levelling — anywhere you always need the same material.
3. Same result from Mining Layers' **Layers tab**: pick the area under *Applies to* and set it to "Plain TerraFarm".
4. **Path areas are excluded entirely** — layers only ever apply to polygon areas. A path area always behaves like plain TerraFarm, no matter what you configure.

This is **not a defect and not a mod conflict — it's the intended switch.** If a zone gives you "the wrong material", check the area's material fields first.

## Features

- **Material by digging depth** — layer boundaries in meters below the original surface
- **Geology per pit** — every area can have its own layer stack, set right in the in-game editor (different pits, different materials, one map)
- **Overburden is yours, the seam is not** — you configure the layers above the paydirt seam; paydirt and rock are placed by the mod itself. Deliberate: this is a mining mod, not a material dispenser
- **Per pit: layers or plain TerraFarm** — pick the target area in the editor and decide for each pit individually
- **Spoil pile memory** — what you dump is what you pick back up. No material cheating: dig a pile below its base and you hit geology again (crater-cheat protection included)
- **Automatic pit floor** — target depth is set to the lowest layer boundary, follows area changes
- **Slope & water handling** — tilted reference plane on hillsides, pit floor clamps to the waterline
- **In-game menu page** — graphical layer editor plus the full manual in all seven languages
- **Depth display & depth lines** — always know how deep you are and what comes next; **Numpad /** toggles the display, **Numpad ✱** moves it (both rebindable in the game options). ⚠️ Upgrading from an older version? A changed default only reaches profiles that do not know the action yet — if a key is missing, assign it once under Options → Controls → Mining Layers.
- **Material check at startup** — tells you how many ground slots this map offers and which materials missed out
- **Mountain bonus** — on steep slopes paydirt sits near the surface: hauling up the mountain gets rewarded
- Multiplayer-friendly sponsor sign (see below), no sync traffic

## Pitfalls worth knowing

- **Layer thickness: don't go thin.** The editor enforces 1 m for the top layer and 1.5 m for every layer below — thinner layers break spoil pile pickup. **With big machines (PC 8000 class), 2 m per layer digs noticeably smoother.**
- **Ground material slots are limited — by the MAP, not by the game.** The map sets the channel width of its height density map; the count follows 2^n-1, so 6 bit gives 63 slots, 7 bit gives 127 and 8 bit gives 255. Measured so far: 63 on a 6-bit map (the engine names that number itself) and 83 occupied slots on a 7-bit map with no rejection at all. The base game takes 48, and map plus mods share the rest. So a wide map has room where a narrow one does not. The startup check tells you where you stand; `grep addDensityMapHeightType log.txt` names every material that missed out.
- **Lowering only works inside the polygon** (TerraFarm design). A wheel loader only cuts ~30–40 cm per pass — drive a ramp into the pit; the excavator is the depth tool.
- **Some maps block terraforming** at riverbeds and map edges (engine blocked-area map). No mod can dig there.
- Runtime terrain texture names differ from the names in `map.i3d` — the mod resolves this automatically; override per layer via `paintLayer="..."` if you want a specific look.

## Configuration

`modSettings/FS25_MiningLayers/miningLayers.xml` — created from the template on first start, survives mod updates. Layer stacks (material + depth, per area), display options, and the sponsor sign toggle live here. Everything can also be edited from the in-game menu.

### Custom geology — gravel pit, coal mine

Since 1.4.0 the pay seam is selectable in the editor (ESC menu → Mining Layers → Layers): the seam is the fixed last row — pick COAL, LIMESTONE, STONE, GRAVEL, SAND, DIRT or SOIL instead of PAYDIRT. Its position stays fixed: the seam always sits below the overburden, bedrock below it ends the pit.

The same per area in the XML:

```xml
<zone area="gravel-pit">
    <layer depth="1" fillType="DIRT" />
    <layer depth="7" fillType="LIMESTONE" seam="true" />
    <layer           fillType="STONE" />
</zone>

<zone area="coal-mine">
    <layer depth="2"  fillType="DIRT" />
    <layer depth="6"  fillType="STONE" />
    <layer depth="12" fillType="COAL" seam="true" />
    <layer            fillType="STONE" />
</zone>
```

One catch: PAYDIRT, COAL and LIMESTONE are not base-game fill types — your map, a mining mod or another mod has to bring them. The log lists every fill type your map knows on startup; unknown materials are skipped with a warning (and the editor falls back to PAYDIRT rather than saving a pit with nothing in it).

## FAQ

Jump to a question:

1. [Does Mining Layers work on any map?](#1-does-mining-layers-work-on-any-map)
2. [Do I need a new savegame?](#2-do-i-need-a-new-savegame)
3. [How do I make a gravel pit in FS25?](#3-how-do-i-make-a-gravel-pit-in-fs25)
4. [How do I mine coal in FS25?](#4-how-do-i-mine-coal-in-fs25)
5. [Does Mining Layers add a paydirt fill type to my map?](#5-does-mining-layers-add-a-paydirt-fill-type-to-my-map)
6. [Can I set up my own layers — more dirt, different soil types?](#6-can-i-set-up-my-own-layers--more-dirt-different-soil-types)
7. [Why is my excavator not digging?](#7-why-is-my-excavator-not-digging)
8. [Why do I always get the same material, no matter how deep I dig?](#8-why-do-i-always-get-the-same-material-no-matter-how-deep-i-dig)
9. [Can I use "everywhere" and drawn areas at the same time? (1.6)](#9-can-i-use-everywhere-and-drawn-areas-at-the-same-time-16)
10. [Why do I get no layers, even though I drew an area? (top 3 causes)](#10-why-do-i-get-no-layers-even-though-i-drew-an-area-top-3-causes)
11. [How deep can I dig?](#11-how-deep-can-i-dig)
12. [How thick should my layers be?](#12-how-thick-should-my-layers-be)
13. [Is there a pile limit — how much can I dump?](#13-is-there-a-pile-limit--how-much-can-i-dump)
14. [Dumping on the ground says "action not possible"?](#14-dumping-on-the-ground-says-action-not-possible)
15. [Material sits in the bucket but will not tip onto the ground?](#15-material-sits-in-the-bucket-but-will-not-tip-onto-the-ground)
16. [Why does my machine only dump inside one area — or nowhere at all?](#16-why-does-my-machine-only-dump-inside-one-area--or-nowhere-at-all)
17. [How do I turn the depth display off (or back on)?](#17-how-do-i-turn-the-depth-display-off-or-back-on)
18. [Can I move the display so it does not overlap other HUD mods?](#18-can-i-move-the-display-so-it-does-not-overlap-other-hud-mods)
19. [Does it work on PS5 or Xbox?](#19-does-it-work-on-ps5-or-xbox)
20. [Which languages are supported?](#20-which-languages-are-supported)

---

#### 1. Does Mining Layers work on any map?

Yes. No map editing is needed: draw a TerraFarm area around your future pit and start digging. For layer textures the mod automatically picks the closest ground texture the map offers; if nothing fits, your own texture selection simply stays active.

#### 2. Do I need a new savegame?

No. Mining Layers works with existing saves — install, enable both mods for the savegame, keep playing. Existing TerraFarm areas keep working; areas without a material set simply get layers.

#### 3. How do I make a gravel pit in FS25?

Install TerraFarm and Mining Layers, draw a TerraFarm area, then open ESC menu → Mining Layers → Layers and set DIRT on top with LIMESTONE or STONE as the pay seam. Since 1.4.0 the seam material is selectable right in the editor — no XML needed.

#### 4. How do I mine coal in FS25?

Pick COAL as the pay seam in the layer editor. Note: COAL is not a base-game fill type — your map or a mining mod has to provide it (RGC maps like Yukon Back Country do).

#### 5. Does Mining Layers add a paydirt fill type to my map?

No — the mod never registers fill types. It only uses what the base game, your map and your other mods already provide. PAYDIRT itself is not a base-game fill type: mining maps and mining mods bring it, which is why it is often there anyway. No paydirt in your game? Pick a seam material your map does know in the layer editor — the startup log lists them all.

#### 6. Can I set up my own layers — more dirt, different soil types?

Yes, that is the core feature. ESC menu → Mining Layers → Layers: per pit you pick material AND thickness of every overburden layer. More dirt? Make the DIRT layer 4 m instead of 2. Variety? Stack DIRT over SOIL over gravel. Anything your map knows as a material works, and the pay seam at the bottom is selectable too. Minimums: 1 m for the top layer, 1.5 m below (2 m digs smoother with big machines).

#### 7. Why is my excavator not digging?

TerraFarm needs a machine configuration for that vehicle — without one, nothing happens (that is not a Mining Layers issue). Install a config pack such as scfmod's FS25_TerraFarmMachines, and avoid duplicate machine entries from several packs.

#### 8. Why do I always get the same material, no matter how deep I dig?

A material is set on your TerraFarm area — that switches the area to plain TerraFarm without layers (by design, for construction work). Leave the material fields empty and the layers take over.

#### 9. Can I use "everywhere" and drawn areas at the same time? (1.6)

Yes, and they do not fight. **What decides is the area assigned to the MACHINE, not where you are standing.**

- Machine with an input area assigned → that area's layers.
- Machine without one → the global layers, anywhere on the map.
- Area set to `enabled="false"`, or an area with a material set by hand → still no layers, even with global switched on. Building sites and pipe trenches stay clean.

**Switching it on:** a fresh install has it on already. An existing installation keeps its behaviour — turn it on under **ESC → Mining Layers → Layers**, target **"Everywhere (no area needed)"**, set it to *Mining Layers*, save. If you edit `miningLayers.xml` by hand instead, set `enabled="true"` **and delete the `surfaceY` line** — a fixed reference height puts every layer at one single elevation and fits almost no map. **No `globalZone` block in your file at all?** That happens to everyone who has saved in the layer editor, because saving rewrites the file. Then there is nothing to edit by hand — use the switch above, it writes the block for you.

#### 10. Why do I get no layers, even though I drew an area? (top 3 causes)

1. **The machine has no input area assigned.** TerraFarm links areas to the MACHINE, not to your position: machine settings (default `Y`) → select your area as input. Saved per machine and savegame — this is the number one support case; the TerraFarm HUD then shows your area instead of just a material.
2. **A material is set in the area** → the area is plain TerraFarm on purpose (construction mode). Leave the material fields empty.
3. **You are digging outside the area polygon** (or on a path area — paths never get layers).

#### 11. How deep can I dig?

Down to the bedrock below your deepest layer — there digging ends on purpose. That is what makes it mining instead of a bottomless money hole.

#### 12. How thick should my layers be?

At least 1.5 m (the editor enforces 1 m for the top layer, 1.5 m below). With big machines like the PC 8000, 2 m per layer digs noticeably smoother.

#### 13. Is there a pile limit — how much can I dump?

No. Dumped material becomes real terrain via TerraFarm, not a base-game heap — so no heap capacity applies. The pile memory is a 2 m grid per savegame with no cap on pile count or size. One thing to know: each 2 m cell remembers ONE material (the last dump wins), so don't mix materials on the same spot if you want them back separately.

#### 14. Dumping on the ground says "action not possible"?

TerraFarm checks straight down from the bucket edge: if terrain is closer than about 0.5 m, ground-dumping is blocked (dig-pose protection). What counts is the distance below the edge, not how high the boom is — over an excavated hollow it works even with a low boom; on flat ground lift briefly until the message disappears. There is an upper limit too: the dump still has to hit the ground. So: edge clear by a good half metre, but low enough to drop.

#### 15. Material sits in the bucket but will not tip onto the ground?

How many materials can lie on the ground (height types) is set by your map, not by the game: the channel width of its height density map decides, following 2^n-1 — 6 bit gives 63 slots, 7 bit gives 127, 8 bit gives 255. The 63 are confirmed by the engine's own error message; on a 7-bit map we measured 83 occupied slots without a single rejection, so the ceiling there is higher but its exact value is calculated, not measured. The base game already uses 48; the map's own materials are registered before any mod's, and whatever is left goes to the mod list in load order. When a map runs out, late-registered fill types lose their slot: they work in the bucket and sell fine, but cannot be tipped onto the terrain. Your log then shows `maximum number (63) of height types already registered` — one line per rejected material, so `grep addDensityMapHeightType log.txt` gives you the full list. Since 1.4.2 the mod warns per zone when a layer material is affected. Two ways out: trim fill-type-heavy mods, or play a map built with more channels. Measured example: on a 6-bit map ten materials were rejected, while the same mod list on a 7-bit map registered 83 height types with none rejected.

#### 16. Why does my machine only dump inside one area — or nowhere at all?

An output area is assigned in the machine menu: TerraFarm then dumps only inside that area. Since 1.4.2 a layer zone assigned as output runs free automatically (one log line says so). For free dumping anywhere, set the machine's output area to "not set".

#### 17. How do I turn the depth display off (or back on)?

Press **Numpad /** while a machine is active (Numpad 5 before 1.5.0). The key is rebindable: Options → Controls → Mining Layers. To start with the display hidden, set `showHeightDisplay="false"` in `modSettings/FS25_MiningLayers/miningLayers.xml`.

#### 18. Can I move the display so it does not overlap other HUD mods?

Yes — since 1.4.2 press **Num *** (rebindable): click the display to pick it up, click again to drop it, right-click resets to the default spot. The position saves automatically (stored in `modSettings/FS25_MiningLayers/hud.xml`). No extra HUD mod needed.

#### 19. Does it work on PS5 or Xbox?

No. Mining Layers is a script mod, and script mods only run on PC/Mac.

#### 20. Which languages are supported?

English, German, French, Polish, Italian and Portuguese — including the full in-game manual.

## Translations

The mod and its in-game manual are available in **English, German, French, Polish, Italian and Portuguese** (Italian contributed by **marcols13**, Portuguese by **Alicopower**; FR/PL machine-translated — corrections welcome!). Which language should come next? **[Vote in the poll](https://github.com/FrittePlayz/FS25_MiningLayers/discussions/1)** — or translate it yourself: the language files are plain XML (`l10n/`), no coding needed, and you'll be credited.

## Changelog

Every release with its changes: [CHANGELOG.md](CHANGELOG.md)

## Roadmap

Where this mod is headed. These are **intentions, not promises** — no dates, and anything here can change or be dropped.

*Slot diagnosis and layers without a drawn area shipped in 1.6.0 — see the [changelog](CHANGELOG.md).*

### v1.6.1 — Community / Oreo RGC Update

Two requests from the RGC Discord, landing roughly a week after the 1.6 release.

- **Material names in material colour** in the height display — the same colours the layer editor already uses.
- **Overburden mode** — everything above the seam digs and dumps as *one* material, only the seam stays real. Solves having to bring a separate truck for every layer you cut through.

### FS25 Mining Layers-Director's Cut V2

Everything that gets you into the pit is in the version above. Everything below is depth for people already standing in one, and it lands in the next big version.

1. **Editor** — offer the materials your map actually provides instead of hand-editing `miningLayers.xml`, put the map report on the layers page, and make spoil piles visible and resettable per zone.
2. **Multiplayer** — partly tested. The mod runs on a dedicated server: zones, layers and the spoil memory all survive a restart there. What has not been tested is the client side, so treat multiplayer as unproven until it has been.
3. **Material hardness & the right tool** — rock should not dig like soil: slower, or only after ripping/hammering it loose. Worth knowing: neither TerraFarm nor the base game has any notion of material hardness (the `hardness` value in the engine brush is edge softness, not rock strength), so this one is built from scratch.
4. **Yield** — a lean overburden and a rich seam: more or fewer liters per cubic meter depending on the layer you are in.
5. **Caprock** — a hard band sitting on top of the paydirt seam, combining 4 and 3.
6. **Transition band at layer boundaries** — a small tolerance zone so a tool working right on a boundary keeps delivering one material instead of flip-flopping between two (the engine dislikes mixed fill types on the ground — thanks to scfmod for flagging this in [#123](https://github.com/scfmod/FS25_TerraFarm/discussions/123)). The band will be drawn to scale in the layer editor, so it explains itself.

### Companion project (separate mod, planned)

**TerraFarm configs for the base game machines** — right now, getting started with TerraFarm means hunting down modded excavators first: the official machines add-on covers third-party mods, and so do the community packs. Nobody covers what the game already gives you. The plan is a config add-on for the base game fleet — wheel loaders, telehandlers, front loaders and their buckets, blades and ripper attachments — so anyone can try TerraFarm with the machines already parked in their shed.

It has its own repository — **[Dig With Anything](https://github.com/FrittePlayz/FS25_DigWithAnything)** (work in progress). If a machine should work with TerraFarm and doesn't, name it in the issues over there.

Got an opinion on the order, or an idea that's missing? [Open a discussion or issue](../../issues) — this list is not set in stone.

## Sponsor

Mining Layers is supported by **[farmersingles.de](https://farmersingles.de)** — the dating site for farmers. 🚜❤️
In game this shows as a small sign at the pit edge. Don't want it? Set `sponsorSign="false"` in the config — it disappears immediately, no restart needed.

## Bugs & questions

Found a bug? [Open an issue](../../issues) — **always attach your `log.txt`** (`Documents/My Games/FarmingSimulator2025/log.txt`, copied right after the problem happened). It contains your full mod list and the actual error — without it we usually cannot help. Ideas for features are welcome in the same place.

## Support this mod 🍟

<p align="center">
  <a href="https://buymeacoffee.com/fritteplayz"><img src="https://img.shields.io/badge/Buy%20me%20fries-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black" alt="Buy me fries"></a>
</p>

Mining Layers is free so far — no paywalled early access, no ads, no strings attached.

Behind it are a lot of evenings: reading TerraFarm's source, digging test pits, and hunting bugs that only show up after the fifth reload. If the mod gave you a good afternoon in the pit, **[buy me a portion of fries](https://buymeacoffee.com/fritteplayz)** — every one of them goes straight back into testing hours and new features.

Not your thing? A ⭐ on this repo, a bug report, or telling a friend about the mod helps just as much. Thanks for playing!

## Credits

- **Author:** Tommy Honold
- **Italian translation:** **marcols13** — contributed via [Discussion #1](https://github.com/FrittePlayz/FS25_MiningLayers/discussions/1), thank you!
- **Portuguese (pt/br) translation:** **Alicopower** — contributed via [Issue #7](https://github.com/FrittePlayz/FS25_MiningLayers/issues/7), thank you!
- **Sponsor:** [farmersingles.de](https://farmersingles.de) — the dating site for farmers
- A **[FrittePlayz](https://www.youtube.com/@FrittePlayz)** project (YouTube)
- Built on **[TerraFarm](https://github.com/scfmod/FS25_TerraFarm)** by scfmod (required, install separately) — unofficial add-on, no affiliation with scfmod or GIANTS Software.
- HUD drag&drop mechanics inspired by **HappyLooser's HL Hud System** (as seen in FS25_ProductionInfoHud) — own implementation, no code copied. Thanks for openly sharing the system!
