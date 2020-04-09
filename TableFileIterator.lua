--##### TableFileIterator script for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  provides two functions tableFileIterator and tableFileIteratorReverse which
  return iterators for CE's table files, only works for versions with offsets
  listed in table below because it works by reading memory directly.
  Probably best not to store the iterators since the table files could change before use...

  If getCheatEngineFileVersion function does not exist, it also provides that

  inspired by http://forum.cheatengine.org/viewtopic.php?p=5734637#5734637
]]

-- https://youtu.be/s87WtAw636M updating offsets for different versions
-- (first 5 minutes, rest is a quick attempt to show why it works)
--
-- text explanation
-- to find offsets start 2 instances of CE, in the first add some tablefiles in the second scan for the number of table files there are
-- find what accesses the address, you'll find an instruction with either 0x10 (x64) or 0x8, take the register value (probably in *bx)
-- and scan for it, you should only have a few results, check each to see which is accessed when you click the Tables menu
-- once you've found the one that's actually used, that's the offset from the MainForm
-- the key in the table below is the integer (first) result of getCheatEngineFileVersion()
local knownTableFileOffsets = {
  [1688879925040206] = {0x0900}, -- CE 6.7 x86, 0x0910 for rcg4u's CE with same file version...
  [1688879925040207] = {0x1058}, -- CE 6.7 x64, 0x1078 for rcg4u's CE with same file version...
  [1688875630072592] = {0x08F0}, -- CE 6.6 x86
  [1688875630072593] = {0x1030}, -- CE 6.6 x64
  [1688884220007827] = {0x0938}, -- CE 6.8 x86
  [1688884220007828] = {0x10C8}, -- CE 6.8 x64
  [1688884220073440] = {0x10C8, 0x0938}, -- CE 6.8.1 x64, x86, same file version!
  [1688884220139078] = {0x10E0, 0x0948}, -- CE 6.8.2
  [1688884220204715] = {0x10E0, 0x0948}, -- CE 6.8.3 pre-postfix
  [1688884220204718] = {0x10E0, 0x0948}, -- CE 6.8.3 postfix
  [1970324836980594] = {0x11A8, 0x09B0},  -- CE 7.0
  [1970324836980599] = {0x11B0, 0x09B4},  -- CE 7.0 rerelease
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
  local offsets = knownTableFileOffsets[getCheatEngineFileVersion()]
  if not offsets then return nil end
  -- incase both the x86 and x64 exes have the same file version
  return offsets[CheatEngineIs64Bit() and 1 or 2]
end

if not getTableFileOffset() then
  local msg = "unkown CE version %d, update offset for TableFile\nRun shellExecute(getCheatEngineDir() .. 'autorun') to open autorun directory and fix the table file"
  print(msg:format(getCheatEngineFileVersion()))
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
