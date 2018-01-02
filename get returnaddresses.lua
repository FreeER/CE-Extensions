--##### Get Return Address POC Lua Function for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  creates printRetAddressesList which takes an address and the amount of time to check then prints the values that were on top of the stack (ie. the return address for ret instructions)
  FO: Find out what address this RETNs to when right clicking on a RETN operation code (extremely useful for microsecond calls  to determine the highest XREF count resources)(edited)
]]

getRetAddressesList = {}
function getRetAddresses(addr, stopChecking)
  if not debug_isDebugging() then debugProcess(0) end
  if stopChecking then 
    debug_removeBreakpoint(addr)
    local addresses = getRetAddressesList[addr]
    if addresses then addresses.endUpdate() end
    return addresses
  end
  -- else
  local addresses = createStringlist()
  addresses.Duplicates = 'dupIgnore'
  addresses.Sorted = true
  addresses.beginUpdate()
  getRetAddressesList[addr] = addresses
  debug_setBreakpoint(addr, getInstructionSize(addr), bptExecute, function(...)
    addresses.add(("%X"):format(readPointer(ESP)))
    debug_continueFromBreakpoint(co_run)
    return 0
  end)
end

function printRetAddressesList(addr, time)
  addr = getAddressSafe(type(addr) == 'number' and ('%x'):format(addr) or addr)
  if not addr then error("Invalid address", 2) end
  getRetAddresses(addr)

  time = tonumber(time)
  time = time and math.ceil(time) or 10000 -- default to 10 seconds
  local t = createTimer()
  t.Interval = time
  t.OnTimer = function(t)
    t.destroy()
    local list = getRetAddresses(addr,true)
    if list then
      print(('found %i return addresses for %s'):format(list.Count, getNameFromAddress(addr)))
      for i=0,list.Count-1 do
        print(list[i])
      end
      list.destroy()
    else
      print('hm, getRetAddresses seems to have returned nil...sorry')
    end
  end
end
