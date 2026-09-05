#!/usr/bin/env python3
"""Regenerate dist/*.mpackage and packages/manifest.lua from packages/*.

Run this after any change under packages/, before pushing to master — or
just let .github/workflows/build.yml run it automatically on every push
that touches packages/. It follows the exact zip layout already documented
in README.md ("Building a .mpackage"), so a built file is byte-identical
to what you'd get zipping a package folder by hand.

packages/manifest.lua is what Ailo Updater (packages/ailo-updater) polls
on every game connect to decide what needs installing — see that
package's config.lua for how it's consumed.

Every build also drops a permanent, never-overwritten copy at
archive/<folder>/<version>.mpackage — see "Rolling back" in README.md for
how to use it if a pushed version turns out to be broken.
"""
import os
import re
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PKG_DIR = os.path.join(ROOT, "packages")
DIST_DIR = os.path.join(ROOT, "dist")
ARCHIVE_DIR = os.path.join(ROOT, "archive")

# Packages that ship with Mudlet itself / aren't part of the auto-update
# rollout (per README's "(Mudlet default)" annotation). Still built to
# dist/ for convenience, just left out of manifest.lua.
SKIP_MANIFEST = {"echo", "gui-drop", "mpkg"}


def parse_lua_config(text):
    """Pull top-level `key = value` assignments out of a config.lua.

    Handles the three shapes actually used in this repo: `[[ ... ]]`
    long-strings (possibly multi-line), single/double-quoted strings, and
    bare tokens. Good enough for config.lua's simple, controlled format —
    not a general Lua parser.
    """
    result = {}
    pattern = re.compile(r"^(\w+)\s*=\s*", re.M)
    matches = list(pattern.finditer(text))
    for idx, m in enumerate(matches):
        key = m.group(1)
        rest = text[m.end():]
        if rest.startswith("[["):
            end = rest.find("]]", 2)
            val = rest[2:end] if end != -1 else rest[2:]
        elif rest[:1] in ("'", '"'):
            q = rest[0]
            end = rest.find(q, 1)
            val = rest[1:end] if end != -1 else rest[1:]
        else:
            end = rest.find("\n")
            val = (rest[:end] if end != -1 else rest).strip()
        result[key] = val.strip()
    return result


def lua_str(s):
    """Render a Python string as a safe single-quoted Lua string literal."""
    return "'" + str(s).replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n") + "'"


def safe_version_filename(version):
    """Turn a config.lua version string into a safe filename component."""
    return re.sub(r"[^A-Za-z0-9._-]+", "_", str(version)).strip("_") or "0"


def archive_build(folder, version, dist_path):
    """Copy a freshly-built .mpackage into archive/<folder>/<version>.mpackage.

    Never overwrites an existing archived file — a version string is only
    ever built once (bump version in config.lua for any change you want
    archived separately), so an existing file at that path means this exact
    version was already archived and is left alone.
    """
    folder_dir = os.path.join(ARCHIVE_DIR, folder)
    os.makedirs(folder_dir, exist_ok=True)
    archive_path = os.path.join(folder_dir, f"{safe_version_filename(version)}.mpackage")
    if os.path.exists(archive_path):
        return archive_path, False
    with open(dist_path, "rb") as src, open(archive_path, "wb") as dst:
        dst.write(src.read())
    return archive_path, True


def build_package(folder):
    pkg_path = os.path.join(PKG_DIR, folder)
    config_path = os.path.join(pkg_path, "config.lua")
    if not os.path.isdir(pkg_path) or not os.path.isfile(config_path):
        return None

    with open(config_path, encoding="utf-8") as f:
        cfg = parse_lua_config(f.read())

    xml_files = [fn for fn in os.listdir(pkg_path) if fn.lower().endswith(".xml")]
    if not xml_files:
        print(f"  skip {folder}: no .xml file", file=sys.stderr)
        return None

    # Only config.lua + the .xml(s) go into the installable .mpackage --
    # a folder can also hold source helpers (e.g. ailo-updater's build.py
    # and ailoupdate.core.lua) that Mudlet has no use for and shouldn't ship.
    ship_names = set(xml_files) | {"config.lua"}
    dist_name = f"{folder}.mpackage"
    dist_path = os.path.join(DIST_DIR, dist_name)
    with zipfile.ZipFile(dist_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for fn in sorted(os.listdir(pkg_path)):
            full = os.path.join(pkg_path, fn)
            if fn in ship_names and os.path.isfile(full):
                zf.write(full, arcname=fn)

    version = cfg.get("version", "0")
    archive_path, archived_new = archive_build(folder, version, dist_path)

    return {
        "name": cfg.get("mpackage", folder),
        "folder": folder,
        "version": version,
        "file": f"dist/{dist_name}",
        "archive_path": archive_path,
        "archived_new": archived_new,
    }


def write_manifest_lua(entries):
    lines = [
        "-- AUTO-GENERATED by tools/gen_manifest.py — do not hand-edit.",
        "-- Regenerate with: python3 tools/gen_manifest.py",
        "return {",
    ]
    for e in entries:
        lines.append(
            "  { name = %s, folder = %s, version = %s, file = %s },"
            % (lua_str(e["name"]), lua_str(e["folder"]), lua_str(e["version"]), lua_str(e["file"]))
        )
    lines.append("}")
    lines.append("")
    out_path = os.path.join(PKG_DIR, "manifest.lua")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    return out_path


def main():
    os.makedirs(DIST_DIR, exist_ok=True)
    os.makedirs(ARCHIVE_DIR, exist_ok=True)
    entries = []
    for folder in sorted(os.listdir(PKG_DIR)):
        built = build_package(folder)
        if built is None:
            continue
        archive_note = "archived" if built["archived_new"] else "already archived"
        print(f"  built dist/{built['folder']}.mpackage  (v{built['version']}, {archive_note})")
        if folder not in SKIP_MANIFEST:
            entries.append(built)
    out_path = write_manifest_lua(entries)
    print(f"wrote {out_path} with {len(entries)} package(s)")


if __name__ == "__main__":
    main()
