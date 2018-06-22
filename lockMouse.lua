--##### Lock Mouse Script for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  adds a menu option to lock the mouse where it's at until a hotkey is pressed
]]

-- START OF USER CONFIG --
local useGroupMenu = true
-- table of VK codes for keycombo to trigger hotkey
local hotkeyTrigger = {VK_CONTROL, VK_F12}
-- string of password required to disable mouse lock
local password = nil -- '5f4dcc3b5aa765d61d8327deb882cf99' -- md5 'password'
-- true if password is hash from stringToMD5String (not the plaintext password)
local passwordHashed     = false
local lockInterval       = 1     -- milliseconds between calling setMousePos
local specificXY         = nil   -- if table of x,y will set mouse there rather than current pos
local hotkeyStartsFreeze = false -- if false pressing the hotkey when not locked does nothing
local menuEndsFreeze     = false -- if false activating the menu with the keyboard does nothing
-- END OF CONFIG --

-- START OF EXT TEMPLATE CONFIG --
local extGroupMenuCaption = 'F&reeER\'s Extensions'
local extItemCaption = 'Lock Mouse'
local requiredVersion = 6.4
-- START OF EXT TEMPLATE CONFIG --

if getCEVersion() < requiredVersion then
    error(("%s requires CE >= %d, update CE!"):format(extItemCaption, requiredVersion))
end

-- menu code --
local mf = getMainForm()
local mm = mf.Menu
local extMenu = nil

if useGroupMenu then
  -- look for existing group menu
  for i=0,mm.Items.Count-1 do
      if mm.Items.Item[i].Caption == extGroupMenuCaption then
          extMenu = mm.Items.Item[i]
          break
      end
  end
  if not extMenu then -- not found so create it
      extMenu = createMenuItem(mm)
      extMenu.Caption = extGroupMenuCaption
      mm.Items.add(extMenu)
  end
else
  extMenu = mm.Items
end

local extMenuItem = createMenuItem(extMenu)
extMenuItem.Caption = extItemCaption
extMenu.add(extMenuItem)
-- menu code --

FreeER = FreeER or {}
FreeER.mouseFreezeHotkey = createHotkey(function(hk)
  -- do nothing if mosue is not locked
  if not FreeER.mouseFreezeTimer then
    if hotkeyStartsFreeze then extMenuItem.doClick() end
    return
  end

  local user = nil
  if password then
    user = inputQuery('Password', 'Password', '')
    if not user then return end
    if passwordHashed then
      user = stringToMD5String(user)
    end
  end

  if user == password then
    FreeER.mouseFreezeTimer.destroy(); FreeER.mouseFreezeTimer = nil;
  end
end, hotkeyTrigger)

extMenuItem.OnClick = function()
  if FreeER.mouseFreezeTimer then
    FreeER.mouseFreezeTimer.destroy(); FreeER.mouseFreezeTimer = nil
    if menuEndsFreeze then return end
  end

  local pos                        = specificXY or {getMousePos()}
  FreeER.mouseFreezeTimer          = createTimer()
  FreeER.mouseFreezeTimer.Interval = lockInterval
  FreeER.mouseFreezeTimer.OnTimer  = function(t)
    setMousePos(unpack(pos))
  end
end
