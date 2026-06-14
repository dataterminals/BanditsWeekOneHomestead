# Bandits Week One — Homestead

A small standalone add-on for **Project Zomboid (Build 42)** that fixes the *"I spawned inside a house with no key, and [**Bandits Week One**](https://steamcommunity.com/sharedfiles/filedetails/?id=3403180543) NPCs move in the moment I leave"* problem — and adds quality-of-life key-forging for keyless starts.

> The **home** feature requires **Bandits Week One** (and its dependency, **Bandits**). The door- and vehicle-key features work in any save. Safe to add or remove at any time.

## Why a locked door isn't enough

Week One's "inhabitant" NPCs are **teleported onto a free tile inside a room** by `BWOPopControl.InhabitantsSpawn` — they never walk in through the door, so locking it does nothing. Keeping a building NPC-free actually takes **two** registrations the base mods normally set up separately:

1. **The "home" flag** (`BWOBuildings.IsEventBuilding(building, "home")`) — the spawner *skips* home buildings, so no fresh NPCs spawn inside. Normally set once, for your starting building, by `BWOEvents.Start` (which also hands you a "Home Key").
2. **A player base** (core Bandits `gmd.Bases`) — an inhabitant that *wanders* in through a window or from an adjacent unit checks `BanditPlayerBase.GetBase` and **flees** if it's inside one (`ZPInhabitant.Main`). A base is normally created only the **first time you put something in a fridge/freezer** (`BanditActionInterceptor`).

A fresh, keyless, unstocked spawn usually has **neither**, which is why NPCs colonise it even after you "claim" it. This mod sets both at once.

## What it adds

All via the right-click world menu — no debug mode required:

- **Claim this house as home** — appears while you're standing inside a building, with Bandits Week One loaded. It:
  1. Registers the building as your `home` (Week One's `EventBuildingAdd`) → **no new NPCs spawn inside**.
  2. Registers the building as your **base** (core Bandits' `BaseUpdate`, same as stocking a fridge) → **inhabitants that wander in flee**, and any already inside leave on their next tick.
  3. Stamps every door in the building to the building's key id, so one key works on all of them.
  4. Hands you that key, named **Home Key**.

  Both registrations are fully save-compatible (they just call the base mods' own commands).
- **Forge key for this door** — on any door you don't already have a key for. Mirrors the vanilla debug `getDoorKey` logic (handles double and garage doors). Works in any save.
- **Forge key for this vehicle** — on any car you don't already have a key for. Creates a matching `Base.CarKey`. Works in any save.
- **Scrub all blood from this house** — while standing in any building. Wipes blood and grime from every tile of the building (`square:removeBlood` / `removeGrime`, the same calls the vanilla mop uses) — no bucket, bleach, or mopping required. Repeatable after a fight. Works in any save.

Key-forging is intentionally **free and instant** — it's there to unstick a keyless spawn, not to be a balanced crafting recipe.

## How it works

A single client file, [`BWOHomestead.lua`](42/media/lua/client/BWOHomestead.lua), that listens to `Events.OnFillWorldObjectContextMenu` and adds the options above. It **overrides nothing** in the base game or Bandits mods — the home option just calls Week One's existing server command, and the key options reuse the same engine calls (`instanceItem`, `setKeyId`, `buildUtil` door helpers) the vanilla debug menu uses. Remove the mod and everything reverts cleanly.

## Compatibility

- **Project Zomboid Build 42.**
- The home feature needs **Bandits Week One**; without it, only the door/vehicle key options appear.

## License

[MIT](LICENSE) © 2026 dataterminals
