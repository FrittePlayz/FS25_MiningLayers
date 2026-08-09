# Mining Layers (FS25)

[![Buy me fries](https://img.shields.io/badge/Buy%20me%20fries-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/fritteplayz)
[![Latest release](https://img.shields.io/github/v/release/FrittePlayz/FS25_MiningLayers?style=for-the-badge&color=2d8a4e)](https://github.com/FrittePlayz/FS25_MiningLayers/releases)
[![Language: EN + DE](https://img.shields.io/badge/in--game-English%20%2B%20German-2d8a4e?style=for-the-badge)](#)

**Real mining gameplay for Farming Simulator 25 — dig through geological layers.**
Material is determined by digging depth, not by hand selection: topsoil first, then gravel, then paydirt, then rock. Per-pit geology, spoil piles that remember what you dumped, and an in-game editor. Works on **any map** — no map editing required. **The mod and its in-game manual are fully available in English and German.**

Mining Layers builds on **[TerraFarm](https://github.com/scfmod/FS25_TerraFarm)** by scfmod, which it requires to run. Unofficial add-on, not affiliated with scfmod.

🇩🇪 **Deutsche Version: [README.de.md](README.de.md)**

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

## ⚠️ Two ways per area — read this before you judge the mod

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
- **In-game menu page** — graphical layer editor plus full documentation (English + German)
- **Depth display & depth lines** — always know how deep you are and what comes next
- **Material check at startup** — warns about the engine's 63 terrain material limit
- **Mountain bonus** — on steep slopes paydirt sits near the surface: hauling up the mountain gets rewarded
- Multiplayer-friendly sponsor sign (see below), no sync traffic

## Pitfalls worth knowing

- **63 terrain materials is a hard engine limit.** Base game + map + mods share it; additional fill type mods may get kicked out. The startup check tells you where you stand.
- **Lowering only works inside the polygon** (TerraFarm design). A wheel loader only cuts ~30–40 cm per pass — drive a ramp into the pit; the excavator is the depth tool.
- **One slope face per area.** Areas drawn across a ridge or far into a lake stretch the reference plane — draw shoreline areas mostly over land.
- **Some maps block terraforming** at riverbeds and map edges (engine blocked-area map). No mod can dig there.
- Runtime terrain texture names differ from the names in `map.i3d` — the mod resolves this automatically; override per layer via `paintLayer="..."` if you want a specific look.

## Configuration

`modSettings/FS25_MiningLayers/miningLayers.xml` — created from the template on first start, survives mod updates. Layer stacks (material + depth, per area), display options, and the sponsor sign toggle live here. Everything can also be edited from the in-game menu.

## Roadmap

Where this mod is headed. These are **intentions, not promises** — no dates, and anything here can change or be dropped.

1. **True depth** — remember the original terrain height per point instead of working with fixed height bands. Layers would then hold up on slopes, in valleys, and even without drawing an area at all.
2. **Material hardness & the right tool** — rock should not dig like soil: slower, or only after ripping/hammering it loose. Worth knowing: neither TerraFarm nor the base game has any notion of material hardness (the `hardness` value in the engine brush is edge softness, not rock strength), so this one is built from scratch.
3. **Yield** — a lean overburden and a rich seam: more or fewer liters per cubic meter depending on the layer you are in.
4. **Caprock** — a hard band sitting on top of the paydirt seam, combining 1 and 2.

### Companion project (separate mod, planned)

**TerraFarm configs for the base game machines** — right now, getting started with TerraFarm means hunting down modded excavators first: the official machines add-on covers third-party mods, and so do the community packs. Nobody covers what the game already gives you. The plan is a config add-on for the base game fleet — wheel loaders, telehandlers, front loaders and their buckets, blades and ripper attachments — so anyone can try TerraFarm with the machines already parked in their shed.

It has its own repository — **[Dig With Anything](https://github.com/FrittePlayz/FS25_DigWithAnything)** (work in progress). If a machine should work with TerraFarm and doesn't, name it in the issues over there.

Got an opinion on the order, or an idea that's missing? [Open a discussion or issue](../../issues) — this list is not set in stone.

## Sponsor

Mining Layers is supported by **[farmersingles.de](https://farmersingles.de)** — the dating site for farmers. 🚜❤️
In game this shows as a small sign at the pit edge. Don't want it? Set `sponsorSign="false"` in the config — it disappears immediately, no restart needed.

## Bugs & questions

Found a bug? [Open an issue](../../issues) — include your `log.txt` and the map you play on. Ideas for features are welcome in the same place.

## Support this mod 🍟

<p align="center">
  <a href="https://buymeacoffee.com/fritteplayz"><img src="https://img.shields.io/badge/Buy%20me%20fries-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black" alt="Buy me fries"></a>
</p>

Mining Layers is free and stays free — no paywalled early access, no ads, no strings attached.

Behind it are a lot of evenings: reading TerraFarm's source, digging test pits, and hunting bugs that only show up after the fifth reload. If the mod gave you a good afternoon in the pit, **[buy me a portion of fries](https://buymeacoffee.com/fritteplayz)** — every one of them goes straight back into testing hours and new features.

Not your thing? A ⭐ on this repo, a bug report, or telling a friend about the mod helps just as much. Thanks for playing!

## Credits

- **Author:** Tommy Honold — [seeside.ai](https://seeside.ai)
- **Sponsor:** [farmersingles.de](https://farmersingles.de) — the dating site for farmers
- A **FrittePlayz** project (YouTube)
- Built on **[TerraFarm](https://github.com/scfmod/FS25_TerraFarm)** by scfmod (required, install separately) — unofficial add-on, no affiliation with scfmod or GIANTS Software.
