# Mining Layers (FS25)

**Real mining gameplay for Farming Simulator 25 — dig through geological layers.**
Material is determined by digging depth, not by hand selection: topsoil first, then gravel, then paydirt, then rock. Per-pit geology, spoil piles that remember what you dumped, and an in-game editor. Works on **any map** — no map editing required.

An unofficial add-on **powered by [TerraFarm](https://github.com/scfmod/FS25_TerraFarm)** (by scfmod — no affiliation).

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
   - **Steam on Linux (Proton):** inside the Proton prefix — `steamapps/compatdata/<FS25-AppID>/pfx/drive_c/users/steamuser/Documents/My Games/FarmingSimulator2025/mods/`
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

**4. Set your own layers — per pit.** ESC menu → Mining Layers → Layers tab: pick materials and depths for each area separately (or for all at once):

![Layer editor](docs/images/02_layer_editor.jpg)

**5. Spoil piles remember their material.** Dump gravel, pick up gravel — even from the flanks. The panel tells you when pile memory is active. No material cheating: below the pile's base you're back in geology:

![Spoil pile memory](docs/images/07_mound_gravel.jpg)

**6. Mountain mining pays off.** On steep slopes paydirt sits near the surface — the reward for hauling up the mountain:

![Mountain mining](docs/images/10_mountain_paydirt.jpg)

**7. Know the limits.** Pits at the waterline flood visually (great for placer mining); some maps block digging at riverbeds and map edges entirely:

![Riverbed limit](docs/images/12_riverbed_limit.jpg)

## ⚠️ Two ways per area — read this before you judge the mod

The single most common point of confusion:

1. **Leave the material fields on the TerraFarm area EMPTY** and Mining Layers does its job: what ends up in the bucket depends on how deep you dig. That is the normal case for a pit.
2. **Enter a material on the area instead** and you get plain TerraFarm without layers. Exactly right for construction sites, road building and levelling — anywhere you just want to move soil and always need the same material.
3. You get the same result from the **Layers tab**: pick an area there and set it to "Plain TerraFarm". Both routes lead to the same place, take whichever you prefer.

So: if a zone gives you "the wrong material", it's not broken — check whether a material is set on the area.

## Features

- **Material by digging depth** — layer boundaries in meters below the original surface
- **Per-pit geology** — every TerraFarm area can have its own layer stack (different pits, different materials, one map)
- **Per-pit opt-out** — decide for each area: Mining Layers geology or plain TerraFarm terraforming
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

## Sponsor

Mining Layers is supported by **[farmersingles.de](https://farmersingles.de)** — the dating site for farmers. 🚜❤️
In game this shows as a small sign at the pit edge. Don't want it? Set `sponsorSign="false"` in the config — it disappears immediately, no restart needed.

## Credits

- **Author:** Tommy Honold — [seeside.ai](https://seeside.ai)
- **Sponsor:** [farmersingles.de](https://farmersingles.de) — the dating site for farmers
- A **FrittePlayz** project (YouTube)
- Powered by **TerraFarm** by [scfmod](https://github.com/scfmod) — this is an unofficial add-on with no affiliation to scfmod or GIANTS Software.

## Support

Found a bug? [Open an issue](../../issues) — include your `log.txt` and the map you play on.
