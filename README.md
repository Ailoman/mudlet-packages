# Icesus Mudlet Packages

A mono-repo of custom Mudlet packages for [Icesus MUD](https://icesus.org).

Each package lives in `packages/<name>/` and contains:
- `config.lua` — package metadata (name, version, description)
- `<PackageName>.xml` — triggers, aliases, scripts, keys, and timers

## Packages

| Package | Version | Description |
|---|---|---|
| [elemental-bonds](packages/elemental-bonds/) | 2.9 | Templar elemental bond manager — track, balance, and manage buffs |
| [icesafe-zone](packages/icesafe-zone/) | 1.1 | Auto-removes forbidden items in safe-zone areas, re-equips on exit |
| [icesus-inventory](packages/icesus-inventory/) | — | Icesus inventory manager |
| [icesus-spell-aliases](packages/icesus-spell-aliases/) | 1.0 | Missing Templar spell-cast aliases (av, cb, esoe, msa, sof) |
| [lantern-refill](packages/lantern-refill/) | 1.0 | Auto-refills iron lanterns; swaps oil sack when empty |
| [mapper-addon](packages/mapper-addon/) | 1 | Mapper add-on for Icesus |
| [momentum-keybutton](packages/momentum-keybutton/) | 1 | Momentum keybutton |
| [movement-keybinds](packages/movement-keybinds/) | 2 | Numpad movement keybinds (normal + road-walk via Ctrl) |
| [party-info](packages/party-info/) | 2.3 | Party formation HUD — 3×3 grid vitals panel, gags spam |
| [skill-loop](packages/skill-loop/) | 2 | Generic combat-skill looper; auto-repeats on attack windows |
| [echo](packages/echo/) | 1 | *(Mudlet default)* Trigger-testing aliases |
| [gui-drop](packages/gui-drop/) | 1.1 | *(Mudlet default)* Drag-and-drop image → AdjustableContainer |
| [mpkg](packages/mpkg/) | 3.5 | *(Mudlet default)* Command-line package manager |

## Building a `.mpackage`

Each package folder is already in the correct layout for `zip`:

```powershell
# Windows (PowerShell) — from the repo root
$pkg = "elemental-bonds"
$src = "packages\$pkg"
Compress-Archive -Path "$src\*" -DestinationPath "$pkg.mpackage" -Force
```

Or on Linux/macOS:

```bash
pkg=elemental-bonds
cd packages/$pkg && zip -j ../../$pkg.mpackage * && cd ../..
```

Then drag the `.mpackage` into Mudlet to install/update.

## Installing into Mudlet

1. In Mudlet, go to **Package Manager** → **Install**.
2. Select the `.mpackage` file you built.
3. Mudlet will unpack it and activate all items inside.

Re-installing a package with the same name replaces the previous version.
