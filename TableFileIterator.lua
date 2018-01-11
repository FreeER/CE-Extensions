-- to find offsets start 2 instances of CE, in the first add some tablefiles in the second scan for the number of table files there are
-- find what accesses the address, you'll find an instruction with either 0x10 (x64) or 0x8, take the register value (probably in *bx)
-- and scan for it, you should only have a few results, check each to see which is accessed when you click the Tables menu
-- once you've found the one that's actually used, that's the offset from the MainForm
local knownTableFileOffsets = {
  [1688879925040206] = 0x0900, -- CE 6.7 x86, 0x0910 for rcg4u's CE with same file version...
  [1688879925040207] = 0x1058, -- CE 6.7 x64, 0x1078 for rcg4u's CE with same file version...
  [1688875630072592] = 0x08F0, -- CE 6.6 x86
  [1688875630072593] = 0x1030, -- CE 6.6 x64
}

if not getCheatEngineFileVersion then
  -- getCheatEngineFileVersion does not exist in CE 6.6
  function getCheatEngineFileVersion()
    local cepid = executeCodeLocal('GetProcessId',-1) -- getCheatEngineProcessID also does not exist in 6.6
    local cename = getProcesslist()[cepid]
    return getFileVersion(getCheatEngineDir() .. cename)
  end
end

local function getTableFileOffset()
  return knownTableFileOffsets[getCheatEngineFileVersion()]
end

if not getTableFileOffset() then
  print('unkown CE version, update offset for TableFile')
  return
end

local TFPGListOfTLuaFilesOffset = getTableFileOffset()
local pointerSize = cheatEngineIs64Bit() and 8 or 4
local TFPGListOfTLuaFiles = readPointerLocal(userDataToInteger(getMainForm())+TFPGListOfTLuaFilesOffset)

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
