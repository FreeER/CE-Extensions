--##### Randomize Selected Addresslist Values for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  Request from TwilightKillerX on Discord
  Randomizes the values of selected addresses
]]

local function findMenu(mi)
  while not mi.Menu do mi = mi.Parent end
  return mi.Menu
end
local del_mi = MainForm.Deletethisrecord1
local del_menu = findMenu(del_mi)

local mi = createMenuItem(del_menu)
mi.Caption = 'Randomize Values'

local miPrompt = createMenuItem(del_menu)
miPrompt.Caption = 'Randomize Values (range prompt)'

function randomize(mr)
  local types  = {
    [vtByte]   = function() return math.random(0, 0xFF) end,
    -- *smallInteger added in CE 6.7
    [vtWord]   = function() return math.random(0, 0xFFFF) end,
    [vtDword]  = function() return math.random(0, 0xFFFFFFFF) end,
    [vtQword]  = function() return math.random(0, 0x7FFFFFFFFFFFFFFF) * (math.random() > 0.5 and -1 or 1) end,
    --[vtSingle] set outside, refers to vtDword
    --[vtDouble] set outside, refers to vtQword
    --[vtByteArray] set outside, refers to vtByte

    -- unsupported
    --[[
    -- probably not the most _logical_ thing to do, but just as a demonstration of how it could be done
    [vtString] = function(len)
      local chars = {}
      for i=0,len do
        chars[#chars+1] = string.char(math.random(('a'):byte(1), ('z'):byte(1)))
      end
      return table.concat(chars,'')
    end,
    ]]
    --[vtGrouped],
    --[vtBinary], -- probably simple enough just not certain
    --[vtPointer], -- not a normal type, fix table to have 4/8?
    --[vtCustom] -- no way to get size, getCustomType(name).scriptUsesFloat
    --  exists for float/int but not size (other than parsing the script... not
    --  too hard but I don't feel like it right now)
  }
  types[vtSingle] = function() return string.unpack('f',string.pack('I4',types[vtDword]())) end
  types[vtDouble] = function() return string.unpack('d',string.pack('I8',types[vtQword]())) end
  types[vtByteArray] = function(len) 
    local bytes = {}
    for i=0, len do
      bytes[#bytes+1] = ('%X'):format(types[vtByte]())
    end
    return table.concat(bytes,' ')
  end

  if mr.Type == vtByteArray then
    return types[mr.Type](mr.Aob.Size)
  elseif types[mr.Type] then
    --print(mr.Description, types[mr.Type]())
    return types[mr.Type]()
  else
    --print('unknown type', mr.Type)
    return nil
  end
end

mi.OnClick = function()
  local al = getAddressList()
  local records = al.getSelectedRecords()
  if not records then return end
  for k,v in pairs(records) do
    if v.Type ~= vtAutoAssembler and not v.isGroupHeader then
      local val = randomize(v)
      if val then v.Value = val end
    end
  end
end

miPrompt.onClick = function()
  local valid = {vtByte, vtWord, vtDword, vtQword, vtSingle, vtDouble}
  local al = getAddressList()
  local records = al.getSelectedRecords()
  if not records then return end

  min = inputQuery('min value', 'Min value:', 0)
  max = inputQuery('max value', 'Max value:', 100)
  min = tonumber(min)
  max = tonumber(max)
  if not min or not max then -- probably hit cancel
    return
  end

  local success = pcall(math.random, min, max)
  if not success then
    showMessage('invalid range, math.random failed!')
    return
  end

  for k,v in pairs(records) do
    if valid[v.type] then
      local success, val = pcall(math.random, min, max)
      if success then
        v.Value = v.ShowAsHex and ('%X'):format(val) or val
      end
    end
  end
end

--[[
-- don't really want to prompt for every single record and
-- remembering values really only works for a single memory record huh...
local lastMinValues = {}
local lastMaxValues = {}
miPrompt.onClick = function()
  local valid = {vtByte, vtWord, vtDword, vtQword, vtSingle, vtDouble}
  local al = getAddressList()
  local records = al.getSelectedRecords()
  for k,v in pairs(records) do
    if valid[v.type] then
      local min = lastMinValues[mr.id] or 0
      local max = lastMaxValues[mr.id] or 100
      min = inputQuery('min value', 'Min value:', min)
      max = inputQuery('max value', 'Max value:', max)
      min = tonumber(min)
      max = tonumber(max)

      if min and max then
        lastMinValues[mr.id] = min
        lastMinValues[mr.id] = max
        local success, val = pcall(math.random, min, max)
        print('random:', val)
        if success then mr.Value = val end
      end
    end
  end
end
]]

del_menu.Items.insert(del_mi.MenuIndex, mi)
del_menu.Items.insert(del_mi.MenuIndex, miPrompt)

--[[
-- mr generation test
local address = 0x400290
local types = {
  vtByte, vtWord, vtDword, vtQword, vtSingle, vtDouble, vtString, vtUnicodeString,
  vtByteArray, vtBinary, vtAutoAssembler, vtPointer, vtCustom, vtGrouped
}
fullAccess(address, #types*0x10)

for _,t in ipairs(types) do
  local mr = AddressList.CreateMemoryRecord()
  mr.Address = ('%X'):format(address)
  address = address + 0x10
  mr.type = t
  mr.Description = _
end
]]
