#!/usr/bin/env python3
"""Build packages/ailo-updater/Ailo Updater.xml from ailoupdate.core.lua.

Uses xml.etree.ElementTree so `&`/`<`/`>` in the Lua get escaped correctly
(see claude/Mudlet package XML escaping pitfall.md in the Claude project --
a single unescaped `<` silently truncates everything after it on import).

Run this after editing ailoupdate.core.lua, then run
tools/gen_manifest.py from the repo root to rebuild dist/ + manifest.lua.
"""
import os
import subprocess
import sys
import tempfile
import xml.dom.minidom as minidom
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
LUA_SRC = os.path.join(HERE, "ailoupdate.core.lua")
ALIASES = [
    ("Force update check", r"^aupdate$", "ailoupdate.check(false)"),
]


def build():
    # utf-8-sig strips a leading UTF-8 BOM if present (e.g. from PowerShell's
    # `Set-Content -Encoding utf8`, which -- unlike plain Python utf-8 writes
    # -- adds one) and is a no-op otherwise. Without this, a BOM in the
    # source file gets embedded as the first three bytes of the <script>
    # text in the built XML, which Lua's loader does NOT treat as ignorable
    # whitespace -- it breaks the whole script with a syntax error the
    # moment Mudlet tries to run it.
    with open(LUA_SRC, encoding="utf-8-sig") as f:
        lua_source = f.read()

    root = ET.Element("MudletPackage", version="1.001")
    ET.SubElement(root, "TriggerPackage")
    ET.SubElement(root, "TimerPackage")

    alias_pkg = ET.SubElement(root, "AliasPackage")
    group = ET.SubElement(
        alias_pkg, "AliasGroup", isActive="yes", isFolder="yes"
    )
    ET.SubElement(group, "name").text = "Ailo Updater"
    ET.SubElement(group, "script").text = ""
    ET.SubElement(group, "command").text = ""
    ET.SubElement(group, "packageName").text = "Ailo Updater"
    ET.SubElement(group, "regex").text = ""
    for name, regex, script in ALIASES:
        alias = ET.SubElement(group, "Alias", isActive="yes", isFolder="no")
        ET.SubElement(alias, "name").text = name
        ET.SubElement(alias, "script").text = script
        ET.SubElement(alias, "command").text = ""
        ET.SubElement(alias, "packageName").text = "Ailo Updater"
        ET.SubElement(alias, "regex").text = regex

    ET.SubElement(root, "ActionPackage")

    script_pkg = ET.SubElement(root, "ScriptPackage")
    top_group = ET.SubElement(
        script_pkg, "ScriptGroup", isActive="yes", isFolder="yes"
    )
    ET.SubElement(top_group, "name").text = "Ailo Updater"
    ET.SubElement(top_group, "packageName").text = "Ailo Updater"
    ET.SubElement(top_group, "script").text = ""
    ET.SubElement(top_group, "eventHandlerList")

    inner_group = ET.SubElement(
        top_group, "ScriptGroup", isActive="yes", isFolder="yes"
    )
    ET.SubElement(inner_group, "name").text = "Ailo Updater"
    ET.SubElement(inner_group, "packageName").text = "Ailo Updater"
    ET.SubElement(inner_group, "script").text = ""
    ET.SubElement(inner_group, "eventHandlerList")

    core = ET.SubElement(inner_group, "Script", isActive="yes", isFolder="no")
    ET.SubElement(core, "name").text = "ailoupdate.core"
    ET.SubElement(core, "packageName").text = "Ailo Updater"
    ET.SubElement(core, "script").text = lua_source
    ET.SubElement(core, "eventHandlerList")

    ET.SubElement(root, "KeyPackage")

    rough = ET.tostring(root, encoding="unicode")
    pretty = minidom.parseString(rough).toprettyxml(indent="\t")
    # Drop minidom's own <?xml?> line; we prepend our own header + doctype.
    pretty_body = "\n".join(pretty.split("\n")[1:])
    out = '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE MudletPackage>\n' + pretty_body

    out_path = os.path.join(HERE, "Ailo Updater.xml")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(out)
    return out_path


def validate(xml_path):
    # 1. Re-parse -- a ParseError means something didn't escape correctly.
    tree = ET.parse(xml_path)

    # 2. luac-check every <script>/<pattern> chunk under both Lua versions
    #    Mudlet actually runs (5.1) and a modern one (5.4), for a syntax
    #    cross-check.
    ok = True
    for tag in ("Trigger", "Alias", "Script", "Timer", "Key"):
        for el in tree.iter(tag):
            sc = el.findtext("script")
            if not sc or not sc.strip():
                continue
            tmp = os.path.join(tempfile.gettempdir(), "_ailoupdate_chunk_check.lua")
            with open(tmp, "w", encoding="utf-8") as f:
                f.write(sc)
            for luac in ("luac5.1", "luac5.4"):
                try:
                    r = subprocess.run([luac, "-p", tmp], capture_output=True, text=True)
                except FileNotFoundError:
                    # luac isn't installed on this machine (common on a
                    # plain Windows setup) -- skip the syntax cross-check
                    # rather than failing the whole build over a missing
                    # optional tool.
                    print(f"skip [{luac}]: not installed", file=sys.stderr)
                    continue
                if r.returncode:
                    ok = False
                    name = el.findtext("name")
                    print(f"FAIL [{luac}] {tag} {name}: {r.stderr.strip()[:300]}", file=sys.stderr)

    # 3. Sanity: a couple of distinctive symbols must have survived.
    xml_text = open(xml_path, encoding="utf-8").read()
    for needle in ("ailoupdate.onManifest", "registerNamedEventHandler", "installPackage"):
        if needle not in xml_text:
            ok = False
            print(f"FAIL missing expected symbol: {needle}", file=sys.stderr)

    return ok


if __name__ == "__main__":
    path = build()
    print(f"built {path}")
    if validate(path):
        print("validation OK")
    else:
        print("validation FAILED", file=sys.stderr)
        sys.exit(1)