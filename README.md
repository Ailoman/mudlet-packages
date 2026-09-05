# Icesus Mudlet Packages

A mono-repo of custom Mudlet packages for [Icesus MUD](https://icesus.org).

Each package lives in `packages/<name>/` and contains:
- `config.lua` — package metadata (name, version, description)
- `<PackageName>.xml` — triggers, aliases, scripts, keys, and timers

## Auto-updating (Ailo Updater)

Install `packages/ailo-updater/` once and every other package in this repo
keeps itself current automatically — the same way the official Icesus core
package self-updates against its own repo:

1. On every game connect (and every 6 hours while connected), Ailo Updater
   downloads [`packages/manifest.lua`](packages/manifest.lua) from `master`.
2. For any package whose `version` there doesn't match what was last
   installed, it downloads that package's built `dist/<folder>.mpackage`
   and installs it (`installPackage`), replacing the old copy in place.
3. Nothing else in the profile is touched — Ailo Updater only ever installs
   packages that appear in this repo's manifest.

Force a check any time with `aupdate`.

`dist/*.mpackage` and `packages/manifest.lua` are **generated, not
hand-edited** — see [`tools/gen_manifest.py`](tools/gen_manifest.py). Pushing
a change under `packages/**` to `master` triggers
[`.github/workflows/build.yml`](.github/workflows/build.yml), which reruns
that script and commits the rebuilt `dist/` + manifest straight back, so
there's no separate release step: source lands on `master`, the build
lands a few seconds later, and every connected client picks it up on its
next connect (or within 6 hours).

## Rolling back a bad version

Every build permanently archives a copy at `archive/<folder>/<version>.mpackage`
— nothing there is ever overwritten, so every version that's ever been pushed
stays available. If a version turns out to be broken:

1. Find the last good version, either in the `archive/<folder>/` folder or in
   `git log -- packages/manifest.lua` (each entry there is one version bump).
2. Install `archive/<folder>/<good-version>.mpackage` by hand in Mudlet
   (Package Manager → Install) — this immediately reverts that one client,
   independent of what's on `master`.
3. To make the rollback stick for everyone (undo it in the repo too, so Ailo
   Updater stops trying to push the broken version back out): revert the
   offending commit(s) to that package's `packages/<folder>/` source and
   `config.lua` `version`, push, and let CI rebuild as normal. Bumping the
   version *backward* is fine — Ailo Updater only checks for a version
   *mismatch*, not that it's newer.

Git itself is also a full history of every source change (`git log -p --
packages/<folder>/`), independent of the archive — the archive exists
specifically so a `.mpackage` you can drag straight into Mudlet is always
one click away, without reconstructing it from a past commit.

## Packages

| Package | Version | Description |
|---|---|---|
| [ailo-updater](packages/ailo-updater/) | 2 | Self-updater — installs newer versions of every package below automatically |
| [elemental-bonds](packages/elemental-bonds/) | 2.9 | Templar elemental bond manager — track, balance, and manage buffs |
| [icesafe-zone](packages/icesafe-zone/) | 1.1 | Auto-removes forbidden items in safe-zone areas, re-equips on exit |
| [icesus-inventory](packages/icesus-inventory/) | 9.31 | Icesus inventory manager |
| [icesus-spell-aliases](packages/icesus-spell-aliases/) | 1.0 | Missing Templar spell-cast aliases (av, cb, esoe, msa, sof) |
| [lantern-refill](packages/lantern-refill/) | 1.0 | Auto-refills iron lanterns; swaps oil sack when empty |
| [mapper-addon](packages/mapper-addon/) | 1 | Mapper add-on for Icesus |
| [momentum-keybutton](packages/momentum-keybutton/) | 1 | Momentum keybutton |
| [movement-keybinds](packages/movement-keybinds/) | 2 | Numpad movement keybinds (normal + road-walk via Ctrl) |
| [party-info](packages/party-info/) | 2.3 | Party formation HUD — 3×3 grid vitals panel, gags spam |
| [skill-loop](packages/skill-loop/) | 2 | Generic combat-skill looper; auto-repeats on attack windows |
| [echo](packages/echo/) | 1 | *(Mudlet default)* Trigger-testing aliases — not auto-updated |
| [gui-drop](packages/gui-drop/) | 1.1 | *(Mudlet default)* Drag-and-drop image → AdjustableContainer — not auto-updated |
| [mpkg](packages/mpkg/) | 3.5 | *(Mudlet default)* Command-line package manager — not auto-updated |

## Building a `.mpackage` by hand

Normally CI does this for you (see above) — but to build locally:

```bash
python3 tools/gen_manifest.py   # rebuilds every dist/*.mpackage + manifest.lua
```

Or for a single package without touching the manifest, the old manual way
still works:

```bash
pkg=elemental-bonds
cd packages/$pkg && zip -j ../../$pkg.mpackage * && cd ../..
```

```powershell
# Windows (PowerShell) — from the repo root
$pkg = "elemental-bonds"
$src = "packages\$pkg"
Compress-Archive -Path "$src\*" -DestinationPath "$pkg.mpackage" -Force
```

Then drag the `.mpackage` into Mudlet to install/update.

## Installing into Mudlet

1. In Mudlet, go to **Package Manager** → **Install**.
2. Select the `.mpackage` file you built (or one from `dist/`).
3. Mudlet will unpack it and activate all items inside.

Re-installing a package with the same name replaces the previous version.
Once `ailo-updater` is installed, this is a one-time step for new packages
only — existing ones stay current on their own.
