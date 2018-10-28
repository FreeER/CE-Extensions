--##### Popout Address List
--##### Author: Dark Byte, menu added by FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  https://forum.cheatengine.org/viewtopic.php?p=5743590#5743590
]]

-- START OF USER CONFIG --
local useGroupMenu = true
local extItemShortcut = ''
-- END OF CONFIG --

-- START OF EXT TEMPLATE CONFIG --
local extGroupMenuCaption = 'F&reeER\'s Extensions'
local extItemCaption = 'Popout Address List'
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
extMenuItem.Shortcut = extItemShortcut
extMenu.add(extMenuItem)
-- menu code --

local alw=createForm() 
alw.PopupMode='pmNone' --comment this if you want stay on top behaviour 
alw.Caption="Address List" 
alw.BorderStyle="bsSizeable" 
alw.ClientWidth=AddressList.Width 
alw.visible = false

local alwsettings=getSettings('alw') 
if alwsettings.Value['x']~='' then alw.left=tonumber(alwsettings.Value['x']) end 
if alwsettings.Value['y']~='' then alw.top=tonumber(alwsettings.Value['y']) end 
if alwsettings.Value['width']~='' then alw.width=tonumber(alwsettings.Value['width']) end 
if alwsettings.Value['height']~='' then alw.height=tonumber(alwsettings.Value['height']) end 

alw.OnCloseQuery=function(sender) 
  AddressList.Parent = MainForm.Panel1
  alw.visible=false
  return false 
end 

alw.OnDestroy=function(sender)  
  alwsettings.Value['x']=alw.left 
  alwsettings.Value['y']=alw.top 
  alwsettings.Value['width']=alw.width 
  alwsettings.Value['height']=alw.height 
end 

extMenuItem.OnClick = function()
  if AddressList.Parent==alw then
    AddressList.Parent = MainForm.Panel1
    alw.visible=false
  else
    AddressList.Parent = alw
    alw.visible=true
  end
end
