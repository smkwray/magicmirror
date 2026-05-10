-- Optional Hammerspoon menu bar control for MagicMirror.
-- Paste this into ~/.hammerspoon/init.lua after requiring hs.ipc.

local TRACKPAD_ORIENTATION_DIR = os.getenv("HOME") .. "/.hammerspoon/trackpad-orientation"
local TRACKPAD_STATE_FILE = TRACKPAD_ORIENTATION_DIR .. "/state"
local trackpadMenu = hs.menubar.new()

local function readTrackpadState()
  local f = io.open(TRACKPAD_STATE_FILE, "r")
  if not f then return "normal" end
  local state = f:read("*l") or "normal"
  f:close()
  if state == "upside-down" then return state end
  return "normal"
end

local function updateTrackpadMenu()
  if not trackpadMenu then return end
  local state = readTrackpadState()
  if state == "upside-down" then
    trackpadMenu:setTitle("TP UD")
    trackpadMenu:setTooltip("Magic Trackpad: upside down")
  else
    trackpadMenu:setTitle("TP OK")
    trackpadMenu:setTooltip("Magic Trackpad: normal")
  end
end

local function runTrackpadScript(script, label)
  hs.task.new(TRACKPAD_ORIENTATION_DIR .. "/" .. script, function(exitCode, _, stdErr)
    updateTrackpadMenu()
    if exitCode == 0 then
      hs.alert.show(label, 1.2)
    else
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
      hs.execute("open -a Console /tmp/trackpad-orientation.log >/dev/null 2>&1")
    end },
  }
end)

updateTrackpadMenu()

