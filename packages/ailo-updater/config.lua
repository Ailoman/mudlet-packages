mpackage = [[Ailo Updater]]
author = [[Ailo]]
title = [[Auto-updater for Ailo's custom Icesus packages]]
description = [[Checks github.com/Ailoman/mudlet-packages on every connect (and every 6 hours while connected) and silently installs newer versions of any package listed in the repo's manifest.lua -- the same self-update pattern the official Icesus core package uses against its own repo. Never touches Icesus's own files or any package not in this repo. Manual check: `aupdate` (reports "everything is up to date" when there's nothing to do).

v3 (2026-09-05): fixed a Windows bug where every check after the very first one silently did nothing. getMudletHomeDir() returns backslash paths, but this file joined the manifest/package paths with a literal "/"; Mudlet's sysDownloadDone/sysDownloadError events hand back a fully forward-slash-normalised path, so the exact-string match against the stored path never succeeded on Windows. The manifest download itself worked fine (the file really did land on disk with the latest content) but onManifest()/onPackageDownloaded() never ran, so the "checking" flag never cleared and every later aupdate silently no-opped on that guard -- no error, no message, and AiloUpdater.state.lua never got created. Path comparisons are now done on normalised (forward-slash) copies, and a 20s backstop timer clears a stuck "checking" flag on its own so a future silent failure can't wedge the updater permanently again.]]
version = [[3]]
created = "2026-09-04"
