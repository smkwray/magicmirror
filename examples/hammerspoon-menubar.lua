-- Optional Hammerspoon menu bar control for MagicMirror.
-- Paste this into ~/.hammerspoon/init.lua after requiring hs.ipc.

local TRACKPAD_ORIENTATION_DIR = os.getenv("HOME") .. "/.hammerspoon/trackpad-orientation"
local TRACKPAD_CONF = TRACKPAD_ORIENTATION_DIR .. "/orient.conf"
local trackpadMenu = hs.menubar.new()

-- Read the toggle-target trackpad's orientation straight from orient.conf, the
-- single source of truth that both the scripts and the mt-orient daemon key off.
-- (A separate "state" file used to hold this; nothing kept it current, so the
-- menu bar silently showed whatever it last said -- for months.)
local function readTrackpadState()
  local f = io.open(TRACKPAD_CONF, "r")
  if not f then return "unconfigured" end
  local target, orientation = nil, {}
  for line in f:lines() do
    local t = line:match("^toggle%-target%s+(%S+)")
    if t then target = t end
    local p, o = line:match("^product%s+(%S+)%s+(%S+)")
    if p then orientation[p] = o end
  end
  f:close()
  if not target then return "unconfigured" end
  return orientation[target] or "unconfigured"
end

local function updateTrackpadMenu()
  if not trackpadMenu then return end
  local state = readTrackpadState()
  if state == "upside-down" then
    trackpadMenu:setTitle("TP UD")
    trackpadMenu:setTooltip("Magic Trackpad: upside down")
  elseif state == "normal" then
    trackpadMenu:setTitle("TP OK")
    trackpadMenu:setTooltip("Magic Trackpad: normal")
  else
    trackpadMenu:setTitle("TP --")
    trackpadMenu:setTooltip("Magic Trackpad: no toggle target configured")
  end
end

-- set-orientation.sh replaces orient.conf atomically, so watch the directory and
-- refresh the title when a shell command or editor changes it.
local trackpadWatcher = hs.pathwatcher.new(TRACKPAD_ORIENTATION_DIR, function()
  updateTrackpadMenu()
end):start()

local function runTrackpadScript(script, label)
  hs.task.new(TRACKPAD_ORIENTATION_DIR .. "/" .. script, function(exitCode, _, stdErr)
    updateTrackpadMenu()
    if exitCode ~= 0 then
      local msg = (stdErr and stdErr ~= "") and stdErr or ("exit " .. tostring(exitCode))
      hs.alert.show("Trackpad failed: " .. msg, 1.2)
    end
  end):start()
end

trackpadMenu:setMenu(function()
  local state = readTrackpadState()
  return {
    { title = "Upside-down", checked = state == "upside-down", fn = function()
      runTrackpadScript("apply-upside-down.sh", "Magic Trackpad: upside down")
    end },
    { title = "Normal", checked = state == "normal", fn = function()
      runTrackpadScript("apply-normal.sh", "Magic Trackpad: normal")
    end },
    { title = "-" },
    { title = "Toggle", fn = function()
      runTrackpadScript("toggle.sh", "Magic Trackpad: toggled")
    end },
    { title = "Reapply Current", fn = function()
      runTrackpadScript("apply-current.sh", "Magic Trackpad: reapplied")
    end },
    { title = "Open Log", fn = function()
      hs.execute("open -a Console /tmp/magicmirror.out.log /tmp/magicmirror.err.log >/dev/null 2>&1")
    end },
  }
end)

updateTrackpadMenu()
