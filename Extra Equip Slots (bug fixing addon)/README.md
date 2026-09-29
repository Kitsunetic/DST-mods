# Extra Equip Slots (Bug Fixing Addon)

Compatibility addon for [Extra Equip Slots (Updated, Wilson: fix beard)](https://steamcommunity.com/sharedfiles/filedetails/?id=3681081494). Enable **both** mods on the server. This addon does not include files from the original mod.

## What it fixes

- Client item transfer recognizes a backpack equipped in `BACK` as the overflow container. The game's slot selection and transfer functions continue to decide where items go.
- Crafting uses the game's original `inventory_classified.Has`, including ingredients in open containers and `nocrafting` exclusions.

The addon loads before the target mod to save the original `Has` method, then restores it after the target's prefab hook runs. It changes the shared local overflow lookup used by the game's client inventory functions. If a game update changes that upvalue, the addon logs a warning instead of guessing which function to modify.

Only Workshop item `3681081494` is targeted. The addon does not change Shift-click priority between an open icebox and a cookpot.

## Verification

From the repository root:

```sh
lua 'Extra Equip Slots (bug fixing addon)/tests/test_addon.lua' 'Extra Equip Slots (bug fixing addon)'
luac -p 'Extra Equip Slots (bug fixing addon)/modmain.lua' 'Extra Equip Slots (bug fixing addon)/modinfo.lua'
```

The Lua test models the relevant prefab-init ordering and shared closure. It is not an in-game DST test. Before release, test the unmodified original alone and then together with this addon in a copied world, including a remote client.
