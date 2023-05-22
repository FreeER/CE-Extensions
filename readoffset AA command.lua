registerAutoAssemblerCommand('readoffset', function(addr)
    local _,info = splitDisassembledString(disassemble(addr))
    local offset = info:match('[+-](%x+)')
    local function toHexBytes(num)
      if type(num) == 'string' then num = tonumber(num,16) end -- assume strings are hex
      local t = dwordToByteTable(num)
      local hex = {}
      for _,b in ipairs(t) do hex[#hex+1] = ("%02X"):format(b) end
      return table.concat(hex, ' ')
    end
    local res = ('db %s'):format(toHexBytes(offset))
    return res
  end
)

