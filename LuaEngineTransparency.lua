--##### Lua Engine Transparency Script for Cheat Engine
--##### Author: FreeER (based on DB code snippet)
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  http://forum.cheatengine.org/viewtopic.php?t=606479
  add a menu option to make the lua engine always on top and transparent (based on given alpha value 0-255)
]]

-- START OF USER CONFIG --
local useGroupMenu = true
-- END OF CONFIG --

-- START OF EXT TEMPLATE CONFIG --
local extGroupMenuCaption = 'F&reeER\'s Extensions'
local extItemCaption = 'Lua Engine Transparency'
local requiredVersion = 6.4 -- requirement for inputQuery
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

local stateTransparent = false
local previousValue = 127

local function enableTransparency()
  local alpha = inputQuery('Alpha/Opacity/Transparency value','Alpha/Opacity/Transparency value: ',  previousValue)
  if not alpha then return end -- if they hit cancel

  local f=getLuaEngine() 
  f.AlphaBlend=true 
  f.AlphaBlendValue = alpha
  previousValue = alpha
  stateTransparent = true
  
  f.FormStyle="fsSystemStayOnTop" 
end

local function disableTransparency()
  local f=getLuaEngine() 
  f.AlphaBlend=false
  stateTransparent = false

  f.FormStyle="fsNormal" 
end


extMenuItem.OnClick = function()
  if stateTransparent then
    disableTransparency()
  else
    enableTransparency()
  end
end
