-- to find offsets start 2 instances of CE, in the first add some tablefiles in the second scan for the number of table files there are
-- find what accesses the address, you'll find an instruction with either 0x10 (x64) or 0x8, take the register value (probably in *bx)
-- and scan for it, you should only have a few results, check each to see which is accessed when you click the Tables menu
-- once you've found the one that's actually used, that's the offset from the MainForm
local knownTableFileOffsets = {
  [1688879925040206] = 0x900, -- 0x910 for rcg4u's CE with same file version...
  [1688879925040207] = 0x1058, -- 0x1078 for rcg4u's CE with same file version...
}

local function getTableFileOffset()
  return knownTableFileOffsets[getCheatEngineFileVersion()]
end

if not getTableFileOffset() then print('unkown CE version, update offset for TableFile') end

local TFPGListOfTLuaFilesOffset = getTableFileOffset()
local pointerSize = cheatEngineIs64Bit() and 8 or 4
local TFPGListOfTLuaFiles = readPointerLocal(userDataToInteger(MainForm)+TFPGListOfTLuaFilesOffset)

-- warning it's probably not safe to delete files directly from the iterator
-- create a table using it or try the reverse table iterator which _may_ be safer
function tableFileIterator()
  -- https://www.lua.org/pil/7.1.html
  local i = 0
  local itemsBase = readPointerLocal(TFPGListOfTLuaFiles + pointerSize)
  return function()
    local count = readIntegerLocal(TFPGListOfTLuaFiles + pointerSize*2)
    if i < count then
      local file = integerToUserData(readPointerLocal(itemsBase+pointerSize*i))
      i = i + 1
      return file
    end
  end
end

function tableFileIteratorReverse()
  -- https://www.lua.org/pil/7.1.html
  local i = readIntegerLocal(TFPGListOfTLuaFiles + pointerSize*2)-1
  local itemsBase = readPointerLocal(TFPGListOfTLuaFiles + pointerSize)
  return function()
    local count = readIntegerLocal(TFPGListOfTLuaFiles + pointerSize*2)
    if i < count and i >= 0 then
      local file = integerToUserData(readPointerLocal(itemsBase+pointerSize*i))
      i = i - 1
      return file
    end
  end
end

--[[
for file in tableFileIterator() do
  print(file.name)
end
]]
