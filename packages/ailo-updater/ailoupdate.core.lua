-- Ailo Updater ------------------------------------------------------------
-- Checks github.com/Ailoman/mudlet-packages on every game connect (and
-- every 6 hours while connected) and silently installs newer versions of
-- any package listed in packages/manifest.lua -- the same self-update
-- pattern the official Icesus core package uses against its own repo.
--
-- Never touches Icesus's own files, and never touches any package not
-- listed in this repo's manifest.lua, so it can't clobber anything else
-- installed in the profile.
--
-- Commands: aupdate  -- force a check right now (not silent).
-- Files in profile dir: AiloUpdater.state.lua (last-installed versions),
--   AiloUpdater.manifest.lua / AiloUpdater.<pkg>.mpackage (scratch downloads).
-----------------------------------------------------------------------------

ailoupdate = ailoupdate or {}
ailoupdate.repo = ailoupdate.repo or "https://raw.githubusercontent.com/Ailoman/mudlet-packages/master/"
ailoupdate.manifestUrl = ailoupdate.repo .. "packages/manifest.lua"
ailoupdate.manifestPath = getMudletHomeDir() .. "/AiloUpdater.manifest.lua"
ailoupdate.statePath = getMudletHomeDir() .. "/AiloUpdater.state.lua"
ailoupdate.pending = ailoupdate.pending or {}   -- localPath -> manifest entry
ailoupdate.checking = false

function ailoupdate.echo(msg)
  cecho(string.format("\n<sea_green>[ailo-updater]<reset> %s\n", tostring(msg)))
end

local function urlEncodePath(p)
  return (p:gsub(" ", "%%20"))
end

local function loadState()
  local t = {}
  if io.exists and table.load and io.exists(ailoupdate.statePath) then
    local ok = pcall(table.load, ailoupdate.statePath, t)
    if not ok then t = {} end
  end
  return t
end

local function saveState(t)
  if table.save then pcall(table.save, ailoupdate.statePath, t) end
end

local function readManifest()
  local f, ferr = io.open(ailoupdate.manifestPath, "r")
  if not f then return nil, ferr end
  local content = f:read("*a")
  f:close()
  local loader = load or loadstring
  local chunk, err = loader(content, "ailoupdate-manifest")
  if not chunk then return nil, err end
  local ok, result = pcall(chunk)
  if not ok then return nil, result end
  if type(result) ~= "table" then return nil, "manifest did not return a table" end
  return result
end

-- Kick off (or re-kick) a manifest check. silent=true suppresses the
-- "checking..." line and the "up to date" result line, but a real update
-- found is always announced either way.
function ailoupdate.check(silent)
  if ailoupdate.checking then return end
  ailoupdate.checking = true
  ailoupdate.silentCheck = silent
  ailoupdate.pending = {}
  if not silent then ailoupdate.echo("checking for package updates...") end
  downloadFile(ailoupdate.manifestPath, ailoupdate.manifestUrl)
end

function ailoupdate.onManifest()
  ailoupdate.checking = false
  local silent = ailoupdate.silentCheck
  local manifest, err = readManifest()
  if not manifest then
    ailoupdate.echo("could not read package manifest: " .. tostring(err))
    return
  end

  local state = loadState()
  local outdated = {}
  for _, entry in ipairs(manifest) do
    if state[entry.name] ~= entry.version then
      table.insert(outdated, entry)
    end
  end
  if #outdated == 0 then
    -- The automatic connect/6-hour checks stay quiet on a no-op (matches
    -- Icesus core's own behavior); a manual `aupdate` gets an explicit
    -- confirmation so it's never ambiguous with "still checking".
    if not silent then ailoupdate.echo("everything is up to date.") end
    return
  end

  for _, entry in ipairs(outdated) do
    local localPath = getMudletHomeDir() .. "/AiloUpdater." .. entry.folder .. ".mpackage"
    ailoupdate.pending[localPath] = entry
    ailoupdate.echo(string.format(
      "update available: %s (%s -> %s). downloading...",
      entry.name, tostring(state[entry.name] or "not installed"), entry.version))
    downloadFile(localPath, ailoupdate.repo .. urlEncodePath(entry.file))
  end
end

function ailoupdate.onPackageDownloaded(path)
  local entry = ailoupdate.pending[path]
  if not entry then return end
  ailoupdate.pending[path] = nil

  local ok, err = pcall(installPackage, path, entry.name)
  if ok then
    local state = loadState()
    state[entry.name] = entry.version
    saveState(state)
    ailoupdate.echo(string.format("%s installed (v%s).", entry.name, entry.version))
  else
    ailoupdate.echo(string.format("failed to install %s: %s", entry.name, tostring(err)))
  end
end

function ailoupdate.eventHandler(event, ...)
  local a = {...}
  if event == "sysDownloadDone" then
    local path = a[1]
    if path == ailoupdate.manifestPath then
      ailoupdate.onManifest()
    elseif ailoupdate.pending[path] then
      ailoupdate.onPackageDownloaded(path)
    end
  elseif event == "sysDownloadError" then
    -- sysDownloadError args: (errorMessage, path, ...)
    local path = a[2]
    if path == ailoupdate.manifestPath then
      ailoupdate.checking = false
      ailoupdate.echo("could not reach GitHub to check for updates (" .. tostring(a[1]) .. ").")
    elseif ailoupdate.pending[path] then
      local entry = ailoupdate.pending[path]
      ailoupdate.pending[path] = nil
      ailoupdate.echo(string.format("failed to download %s: %s", entry.name, tostring(a[1])))
    end
  end
end

function ailoupdate.onConnect()
  -- Small delay so this doesn't compete with GMCP/mapper init right at
  -- connect, mirroring the timing Icesus's own updater uses.
  tempTimer(3, function() ailoupdate.check(true) end)
end

-- Named handlers/timers auto-replace on re-registration (package reload),
-- so no manual kill-then-register dance is needed here.
registerNamedEventHandler("ailoupdate", "download-done", "sysDownloadDone", "ailoupdate.eventHandler")
registerNamedEventHandler("ailoupdate", "download-error", "sysDownloadError", "ailoupdate.eventHandler")
registerNamedEventHandler("ailoupdate", "connect", "sysConnectionEvent", "ailoupdate.onConnect")
registerNamedTimer("ailoupdate", "periodic check", 6 * 60 * 60, function() ailoupdate.check(true) end, true)
