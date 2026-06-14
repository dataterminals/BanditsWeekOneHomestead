# Bandits Week One — Homestead

A small standalone add-on for **Project Zomboid (Build 42)** that fixes the *"I spawned inside a house with no key, and [**Bandits Week One**](https://steamcommunity.com/sharedfiles/filedetails/?id=3403180543) NPCs move in the moment I leave"* problem — and adds quality-of-life key-forging for keyless starts.

> The **home** feature requires **Bandits Week One** (and its dependency, **Bandits**). The door- and vehicle-key features work in any save. Safe to add or remove at any time.

## Why a locked door isn't enough

Week One's "inhabitant" NPCs are **teleported onto a free tile inside a room** by `BWOPopControl.InhabitantsSpawn` — they never walk in through the door, so locking it does nothing. The **only** building the spawner skips is the one flagged as your **home** (`BWOBuildings.IsEventBuilding(building, "home")`). That flag is normally set once, for your starting building, by `BWOEvents.Start` (which also gives you a "Home Key"). If NPCs are colonising the house you're standing in, it simply was never flagged as home.

## What it adds

All via the right-click world menu — no debug mode required:

- **Claim this house as home** — appears while you're standing inside a building, with Bandits Week One loaded. It:
  1. Registers the building as your `home` using Week One's own `EventBuildingAdd` command (fully save-compatible) → **NPCs stop moving in**.
  2. Stamps every door in the building to the building's key id, so one key works on all of them.
  3. Hands you that key, named **Home Key**.
- **Forge key for this door** — on any door you don't already have a key for. Mirrors the vanilla debug `getDoorKey` logic (handles double and garage doors). Works in any save.
- **Forge key for this vehicle** — on any car you don't already have a key for. Creates a matching `Base.CarKey`. Works in any save.

Key-forging is intentionally **free and instant** — it's there to unstick a keyless spawn, not to be a balanced crafting recipe.

## How it works

A single client file, [`BWOHomestead.lua`](42/media/lua/client/BWOHomestead.lua), that listens to `Events.OnFillWorldObjectContextMenu` and adds the options above. It **overrides nothing** in the base game or Bandits mods — the home option just calls Week One's existing server command, and the key options reuse the same engine calls (`instanceItem`, `setKeyId`, `buildUtil` door helpers) the vanilla debug menu uses. Remove the mod and everything reverts cleanly.

## Compatibility

- **Project Zomboid Build 42.**
- The home feature needs **Bandits Week One**; without it, only the door/vehicle key options appear.

## License

[MIT](LICENSE) © 2026 dataterminals
