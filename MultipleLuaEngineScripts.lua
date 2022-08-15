--##### Multiple Lua Engine Scripts for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  adds a listbox and button to the lua engine that lets you create new scripts and switch between them

  WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING 

  switching to another script OVERWRITES the previous one!
  using ctrl+enter to execute a script deletes the script, if you then switch
  you will overwrite that file with an empty file!

  Switching also breaks the undo history!
  so you won't be able to get that original file back without rewriting it
  redownloading it or having some backup/source control!

  WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING 
]]
local lua -- engine

local last = -1
local cur = -1
local list
local fullpathlist

function SwitchLuaEngineScript(from,to)
  if not from or not to then error("Can't switch lua engine to nonexistent script!", 2) end
  --print('switching', from, to)
  -- save
  if from ~= -1 then
    --print('from',fullpathlist[from])
    local f = io.open(fullpathlist[from],'w')
    f:write(lua.mscript.lines.Text)
    f:close()
  end
  -- load
  --print('to', fullpathlist[to])
  local f = io.open(fullpathlist[to],'r')
  lua.mscript.lines.setText(f:read('*all'))
  f:close()
end

local t = createTimer()
t.Interval = 100
t.OnTimer = function()
  for i=0,getFormCount()-1 do
    local f=getForm(i)
    if (f.ClassName=='TfrmLuaEngine') then
      t.destroy()
      lua = f
      lua.btnExecute.Parent.ChildSizing.Layout='cclLeftToRightThenTopToBottom'
      lua.btnExecute.Parent.ChildSizing.ControlsPerLine=1
      lua.btnExecute.Left = 0
      lua.btnExecute.Width = lua.btnExecute.parent.width
      lua.btnExecute.Anchors = '[akLeft,akRight]'

      local b = createButton(lua.btnExecute.Parent)
      b.Name = 'btnNewScript'
      b.Caption = 'New Script'
      b.OnClick = function()
        local d = createSaveDialog(MainForm)
        d.DefaultExt = 'lua'
        d.execute()
        local function get_file_name(file)
          -- https://stackoverflow.com/a/56513627
          local file_name = file:match("[^/\\]*.lua$")
          return file_name:sub(0, #file_name - 4)
        end
        if d.Files.Count > 0 then
          fullpathlist.add(d.Files[0])
          list.Items.add(get_file_name(d.Files[0]))
          list.ItemIndex = list.Items.Count-1
          SwitchLuaEngineScript(last,cur)
        end
      end

      list = createListBox(lua.btnExecute.Parent)
      list.Name = 'LstBoxScripts'
      fullpathlist = createStringlist()
      fullpathlist.setText(getCheatEngineDir() .. 'LuaEngine.lua')
      list.Items.setText('LuaEngine')
      list.Selected = 0
      local f = io.open(fullpathlist[0],'w')
      f:write(lua.mscript.lines.Text)
      f:close()

      list.OnSelectionChange = function(sender, user)
        last = cur
        cur = list.ItemIndex
      end

      list.OnDblClick = function()
        SwitchLuaEngineScript(last,cur)
      end
    end
  end
end

