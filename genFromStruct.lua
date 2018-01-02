--##### Save Dissect Code Lua Script for Cheat Engine
--##### Author: FreeER (based on DB code snippet)
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw

-- START OF USER CONFIG --
local useGroupMenu = true
-- END OF CONFIG --

-- TODO better differentiation between x and valid ModalResult on closing
-- IDEA rethink if pointers without childStructs should be ignored or autoGened (note no named elems) etc.

-- START OF EXT TEMPLATE CONFIG --
local extGroupMenuCaption = 'FreeER\'s Extensions'
local extItemCaption = 'GenFromStruct'
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

local uniquifier = 0xFFFF

local function getStructureIDByName(name)
  local lname = name:lower()
  local casematch = nil
  local count = getStructureCount()-1
  for i=0, count do
    local struct = getStructure(i)
    -- if there are two structs with the exact same name, not my problem if you get the wrong one!
    if struct.Name == name then return i
    elseif struct.Name:lower() == lname then
      if casematch == nil then casematch = i
        -- potentially misses case where exact match exists after two caseinsensitive matches
        -- ... can fix easily enough with two loops but... people probably should have that many
        -- structures with the same name right? right? I'll find out I guess lol
      else return nil, "more than one structure matches when ignoring case"
      end
    end
  end
  if casematch then return casematch else return nil, ("No structure with the name '%s' exists"):format(name) end
end

local function getStructureByName(name)
  local id, errmsg = getStructureIDByName(name)
  if not id then
    return nil, errmsg
  else
    return getStructure(id)
  end
end

local function getNamedElementsFromStructure(struct)
  if not struct then error("No struct given to getNamedElementsFromStructure!", 2) end
  local elements = {}
  for i=0, struct.Count-1 do
    if struct.Element[i].Name ~= "" then
      table.insert(elements, struct.Element[i])
    end
  end
  return elements
end

local function flash(control, color, time)
  if not inheritsFromControl(control) then
    local class = inheritsFromObject(control) and control.ClassName or tostring(control)
    local err = "non control component (%s) given to flash"
    return error(err:format(class))
  end
  if not color then color = 0xFF end
  if not time then time = 300 end

  local og = control.Color
  control.Color = color
  local t = createTimer()
  t.Interval = time
  t.OnTimer = function(t)
    control.Color = og
    t.destroy()
  end
end

local function createStructForm(editBoxOnEnter, comboBoxSetup, buttonOnClick)
  structForm = createForm(false)
  local f = structForm
  f.Caption = 'Pick the structure'
  f.centerScreen()
  f.DoNotSaveInTable = true
  f.OnClose = function(sender)
    if sender.ModalResult >= uniquifier then return sender.ModalResult end
    -- else user clicked the x and we should signal that it was canceled
    sender.ModalResult = -1
    return sender.ModalResult
  end

  local e = createEdit(f)
  e.Name = 'EditBox'
  e.onKeyUp = editBoxOnEnter

  local c = createComboBox(f)
  c.Name = 'ComboBox'
  c.ReadOnly = true

  local b = createButton(f)
  b.Name = 'Button'
  b.OnClick = buttonOnClick

  if comboBoxSetup and type(comboBoxSetup) == 'function' then
    local success, err = pcall(comboBoxSetup,c,f)
    -- rethrow, with message that makes it obvious who caused the error
    if not success then error(("\r\ncomboBoxSetup failed: %s"):format(err), 2) end
  end

  e.Text = c.Items[0]
  return f
end

local function commonComboBoxSetup(c,f,comboMaxWidth)
  local b = f.Button
  local e = f.EditBox
  local swidth = getWorkAreaWidth()
  comboMaxWidth = math.min(math.max(comboMaxWidth + c.getExtraWidth(), 100), swidth)
  c.Width = comboMaxWidth

  e.Width = c.Width
  local cWidth = c.Width
  c.Left = c.getExtraWidth()/1.3 -- try to center it...
  e.Left = c.Left
  c.Top = e.Height
  c.ItemIndex = 0

  f.ClientWidth = cWidth
  f.ClientHeight = e.Height + c.Height + b.Height

  b.Caption = 'Submit'
  b.Left = (f.ClientWidth - b.Width)/2
  b.Top = c.Top + c.Height
end

local function structurePrompt()
  if not structForm then
    local function editOnEnter(sender, key)
      if key == VK_ENTER or key == VK_RETURN then
        local structName =  sender.Text
        if tonumber(structName) then
          local index = tonumber(structName)
          if getStructureCount() > index and index >= 0 then
            sender.Owner.ModalResult = index+uniquifier
          else flash(sender) end
        else
          local id,errmsg = getStructureIDByName(sender.Text)
          if id then sender.Owner.ModalResult = id+uniquifier else flash(sender) end
        end
      end
      return true
    end

    local function comboSetup(c,f)
      local mwidth = -1e309 -- negative infinity
      -- same order so ItemIndex == structure index
      for i=0,getStructureCount()-1 do
        local name = getStructure(i).Name
        mwidth = math.max(mwidth, c.canvas.getTextWidth(name))
        c.Items.add(name)
      end
      commonComboBoxSetup(c,f,mwidth)
    end

    local function buttonClick(sender)
      local c = sender.Owner.ComboBox
      sender.Owner.ModalResult = c.ItemIndex+uniquifier -- 0 ignored so +uniquifier
    end
    local f = createStructForm(editOnEnter,comboSetup, buttonClick)
  end

  structForm.Visible = false
  local res = structForm.showModal()
  if res < 0 then return nil, 'cancelled' end -- -1 when closed
  res = res - uniquifier
  -- simple fix to Access Violation on second use... lol
  structForm.destroy()
  structForm = nil
  return getStructure(res)
end

local function structureElementPrompt(struct)
  if not struct then error("No struct given to structureElementPrompt!", 2) end
  local namedElems = getNamedElementsFromStructure(struct)
  if not structForm then
    local function editOnEnter(sender, key)
      if key == VK_ENTER or key == VK_RETURN then
        local structName =  sender.Text
        if tonumber(structName,16) then
          local offset = tonumber(structName,16)
          sender.Owner.ModalResult = offset+uniquifier
        else
          local found = false
          for k,v in pairs(namedElems) do
            local c = sender.Owner.ComboBox
            if v.Name == sender.Text then
              sender.Owner.ModalResult = v.Offset + uniquifier
              found = true
              break
            end
          end
          if not found then flash(sender) end
        end
      end
      return true
    end

    local function comboSetup(c,f)
      local mwidth = -1e309 -- negative infinity
      for k,v in pairs(namedElems) do
        local name = v.Name
        local width = c.canvas.getTextWidth(name)
        if width > mwidth then mwidth = width end
        c.Items.add(name)
      end
      commonComboBoxSetup(c,f,mwidth)
    end

    local function buttonClick(sender)
      local c = sender.Owner.ComboBox
      for k,v in pairs(namedElems) do
        if v.Name == c.Items[c.ItemIndex] then
          sender.Owner.ModalResult = v.Offset+uniquifier
          break
        end
      end
    end
    local f = createStructForm(editOnEnter,comboSetup, buttonClick)
  end

  structForm.Visible = false
  local res = structForm.showModal()
  if res < 0 then return nil, 'cancelled' end -- -1 when closed
  res = res - uniquifier

  -- simple fix to Access Violation on second use... lol
  structForm.destroy()
  structForm = nil
  return res
end

-- mostly debug
local function nameFromVartype(type)
      if (type == vtByte)          then return 'Byte'
  elseif (type == vtWord)          then return 'Word'
  elseif (type == vtDword)         then return 'Dword'
  elseif (type == vtQword)         then return 'Qword'
  elseif (type == vtSingle)        then return 'Float'
  elseif (type == vtDouble)        then return 'Double'
  elseif (type == vtString)        then return 'String'
  elseif (type == vtUnicodeString) then return 'UnicodeString'
  elseif (type == vtByteArray)     then return 'ByteArray'
  elseif (type == vtBinary)        then return 'Binary'
  elseif (type == vtAutoAssembler) then return 'Auto Assembler Script'
  elseif (type == vtPointer)       then return 'Pointer'
  elseif (type == vtCustom)        then return 'Custom'
  elseif (type == vtGrouped)       then return 'Grouped'
  else                                  return ("'%s' is an unknown type"):format(type)
  end
end

local al = getAddressList()

local function offsetToStr(initialOffset, prependHex, invert)
  local offset = ("%+d"):format(initialOffset * (invert and -1 or 1))
  offset = ("%s %s%s"):format(offset:sub(1,1), 
  prependHex and '0x' or '',
  ("%X"):format(math.abs(initialOffset)))
  return offset
end

local function isMemRec(mr)
  return mr and mr.ClassName and mr.ClassName == 'TMemoryRecord'
end

local AllMemoryRecordOptions = {'moHideChildren', 'moActivateChildrenAsWell',
  'moDeactivateChildrenAsWell', 'moRecursiveSetValue',
  'moAllowManualCollapseAndExpand', 'moManualExpandCollapse'}
for k,v in ipairs(AllMemoryRecordOptions) do AllMemoryRecordOptions[v] = true end

local function memrecOptionsList(mr)
  if not isMemRec(mr) then error(('%s is not a memory record!'):format(mr), 2) end
  local options,temp = {}, {}
  for i in mr.Options:gmatch('[^,%[%]]+') do temp[i] = true end
  for k,v in ipairs(AllMemoryRecordOptions) do options[v] = (temp[v] == true) end
  return options
end

local function memrecOptionsSet(mr,option,value,shutUpIKnowWhatImDoing)
  if not isMemRec(mr) then error(('%s is not a memory record!'):format(mr), 2) end
  if type(option) ~= 'string' and not shutUpIKnowWhatImDoing then
    error(('Memory options must be strings!'):format(mr), 2)
  end

  local newOptions = {}
  for i in option:gmatch('[^,]+') do
    if not shutUpIKnowWhatImDoing and not AllMemoryRecordOptions[i] then
      error(('%s is not a valid memory record option!'):format(i), 2)
    end
    table.insert(newOptions, i)
  end

  local options = memrecOptionsList(mr)
  for k,v in ipairs(newOptions) do options[v] = value end

  -- table.concat only works for numeric indexes
  for k,v in pairs(options) do if type(k) == 'string' and v then table.insert(options,k) end end
  local new = '[' .. table.concat(options, ',') .. ']'

  mr.Options = new
end

-- no, we won't just take an address and generate one in the main addresslist
-- if that's what you want then you create a memrec there and set the addr for us
function generateFromStructure(mmr, struct, offset)
  local isPointer = mmr and struct and offset == "pointer"
  if isPointer then offset = nil end
  if offset and type(offset) ~= "number" then error(("Given offset '%s' is not a number!"):format(offset),2)
  elseif offset == nil then offset = 0
  end
  if struct and (not struct.ClassName or struct.ClassName ~= 'TDissectedStruct') then
    error(("'%s' is not a valid struct!"):format(struct),2)
  end

  if not (mmr and struct) then -- onclick or "api" w/o info
    if mmr == nil then
      mmr = al.SelectedRecord
      -- ignore if it's an AA script or group header (no address)
      if mmr.Type == vtAutoAssembler or mmr.IsGroupHeader then return end
    end -- default to SelectedRecord

    if not mmr or not mmr.ClassName or not mmr.ClassName == "TMemoryRecord" then
      error(('%s is not a memory record'):format(tostring(mmr)),2)
    elseif mmr.Type == vtAutoAssembler then
      error(('%s is an AA script without an address!'):format(tostring(mmr)),2)
    end

    local errmsg = nil
    struct, errmsg = structurePrompt()
    if not struct then showMessage(errmsg) return end

    offset, errmsg = structureElementPrompt(struct)
    if not offset then showMessage(errmsg) return end
  end
  if offset ~= nil and offset ~= 0 then
    offset = offsetToStr(offset, mmr.Address:sub(1,1) == '$', true)
    mmr.Address = ("%s %s"):format(mmr.Address,offset)
  end

  local elems = getNamedElementsFromStructure(struct)
  for i,v in ipairs(elems) do
    local mr = al.createMemoryRecord()
    mr.Description = v.Name
    mr.Type = v.Vartype
    if not isPointer then
      mr.Address = offsetToStr(v.Offset)
      mr.ShowAsHex = v.DisplayMethod == 'dtHexadecimal'
      mr.ShowAsSigned = v.DisplayMethod == 'dtSignedInteger'
    else
      mr.Address = "+0"
      mr.OffsetCount = 1
      mr.OffsetText[0] = offsetToStr(v.Offset)
    end

    local doAdd = true
    if mr.Type == vtUnicodeString then mr.Type = vtString mr.String.Unicode = true end
    if mr.Type == vtString then mr.String.Size = v.Bytesize end
    if mr.Type == vtCustom then mr.CustomTypeName = v.CustomType.Name end
    if mr.Type == vtByteArray then mr.Aob.Size = v.Bytesiz end
    if mr.Type == vtPointer then
      mr.Type = vtDword -- vtPointer is just for struct, so use vtDword arbitrarily
      if v.childStruct then
        memrecOptionsSet(mr, 'moAllowManualCollapseAndExpand,moManualExpandCollapse', true)
        -- need delay before collapsed will work
        -- while it might work to simply move after gen, better safe
        local t = createTimer() t.Interval=50 t.OnTimer = function(t)
          mr.Collapsed = true t.destroy()
        end
        generateFromStructure(mr, v.childStruct, "pointer")
      else
        doAdd = false
      end
    end

    if doAdd then mr.appendToEntry(mmr) else mr.destroy() end
  end
end

extMenuItem.OnClick = function(sender) generateFromStructure() end

