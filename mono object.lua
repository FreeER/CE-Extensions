--##### mono helper stuff
--##### Author: FreeER
--##### Github: https://github.com/FreeER/CE-Extensions/blob/master/mono%20object.lua
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  Primarily seeks to add newMonoObject which provides a wrapper class around
  mono classes allowing ease of access to fields and methods.

  Methods also should have all the mono_method_'name' stuff as method_object:name()
  including compile and jit info

  eg.

  local mo1 = newMonoObject(instance_address, 'SomeClass') -- simpler
  -- invokes method getMaxHp with 1 argument of type dword (4 bytes) and value 0
  -- then writes the result of that to the field hp
  mo1.hp = mo1.getMaxHp:invoke({type=vtDword,value=0})

  mo1.Hp = 10000 -- writes 1000 to hp
  -- note that we try to ignore the case of the first letter in fields and methods
  -- so both hp and Hp will work because if the first doesn't exist it looks for the other
  -- the case of the rest of the letters DO matter however, HP/hP is not the same as Hp/hp

  -- many classes have a static field with the instance address so you can give 0
  local mo2 = newMonoObject(0, 'SomeClass') -- static instance
  -- then overwrite the address with the value from that static field
  mo2.__address = mo2.static_instance_field_name

  -- or you can use this simpler method
  local mo3 = newMonoObject('static_instance_field_name', 'SomeClass')

  -- if you have the mono class pointer available from somewhere you can use that too
  local mo4 = newMonoObject(instance_address, mono_findClass('SomeClass'))

  -- remember these are lua 'objects' aka tables so if you need another intance
  -- you can't just do new=old new.__address=whatever because you'll change old too
  -- to avoid newMonoObject having to re-ask mono for fields, statics, methods, etc.
  -- you can copy those from an existing object of the same class
  local mo5 = newMonoObject(another_instance_address, mo4)

  -- alternatively you can provide all of the information yourself
  -- newMonoObject(address, class, domain, fields, methods, static_address)
]]

-- create lookup table for defines.lua vt* var types used with invoking methods
valueTypes = {}
for k,v in pairs(_G) do
  -- valueTypes{[0]='vtByte', vtByte=0, ...} for reverse lookup as well
  if k:sub(1,2) == 'vt' then valueTypes[k]=v valueTypes[v]=k end
end

function findMonoFields(class, domain)
  if type(class) == 'string' then class = mono_findClass(class, domain) end
  local fields = mono_class_enumFields(class,true)
  if #fields == 0 then return nil end
  -- swap {[1]={name='...', ...} to {name={...}} so eg. fields.name.offset is valid
  -- rather than needing to loop and check fields[i].name == '...' then whatever
  for k,v in ipairs(fields) do
    fields[v.name] = v
    fields[k] = nil
  end
  return fields
end

-- Seems like a common and simple function
monoStringLenOffset = nil -- try to avoid hardcoding the offsets without
monoStringChrOffset = nil -- having to-get them every single call
function findMonoStringOffsets()
  LaunchMonoDataCollector()
  local fields = findMonoFields(mono_findClass('String'))
  if fields then
    monoStringLenOffset = fields.m_stringLength.offset
    monoStringChrOffset = fields.m_firstChar.offset
    return true
  end
end

function readMonoString(strAddress, lenOffset, chrOffset)
  if not lenOffset and not monoStringLenOffset and not findMonoStringOffsets() then
    error('Failed to detect mono string len offset',2)
  end
  local base = readPointer(strAddress)
  if not base then return nil end
  local len = readInteger(base+(lenOffset or monoStringLenOffset))
  if not len then return end
  return readString(base+(chrOffset or monoStringChrOffset), len*2, true), len
end

function findMonoMethods(class)
  if not class then error('No class provided to find mono methods on', 2) end
  local methods = mono_class_enumMethods(class,true)
  -- swap {[1]={name='...', ...} to {name={...}} so eg. fields.name.offset is valid
  -- rather than needing to loop and check fields[i].name == '...' then whatever
  for k,v in ipairs(methods) do
    methods[v.name] = v
    methods[k] = nil
  end
  return methods
end

function findMonoListFields(classname)
  local class = mono_findClass('',classname)
  local list = mono_class_findInstancesOfClassListOnly('',class)
  local fields = findMonoFields(class)
  return list, fields, class
end

-- global tables so that people could register their own types...
-- hopefully making these global rather than local doesn't cause
-- too much of a performance impact in a loop, though you should
-- be able to optimize things like that by knowing the type anyway
readVarTypeTable = {
  [vtByte]=function(address) return readBytes(address,1) end,
  [vtWord]=readSmallInteger,
  [vtDword]=readInteger,
  [vtQword]=readQword,
  [vtSingle]=readFloat,
  [vtDouble]=readDouble,
  [vtString]=readString,
  [vtUnicodeString]=function(address,len) return readString(address, len or 0 *2, true) end,
  [vtWideString]=function(address,len) return readString(address, len or 0 *2, true) end,
  [vtByteArray]=function(address, len) return readBytes(address, len, true) end,
  [vtBinary]=function() error('vtBinary is unsupported') end,
  [vtAll]=function() error('vtAll is unsupported') end,
  [vtAutoAssembler]=function() error('vtAutoAssembler is unsupported') end,
  [vtPointer]=readPointer,
  [vtCustom]=function() error('vtCustom is unsupported') end,
  [vtGrouped]=function() error('vtGrouped is unsupported') end
}

writeVarTypeTable = {
  [vtByte]=writeBytes,
  [vtWord]=writeSmallInteger,
  [vtDword]=writeInteger,
  [vtQword]=writeQword,
  [vtSingle]=writeFloat,
  [vtDouble]=writeDouble,
  [vtString]=writeString,
  [vtUnicodeString]=function(address,str) return writeString(address, str, true) end,
  [vtWideString]=function(address,str) return readString(address,str, true) end,
  [vtByteArray]=writeBytes,
  [vtBinary]=function() error('vtBinary is unsupported') end,
  [vtAll]=function() error('vtAll is unsupported') end,
  [vtAutoAssembler]=function() error('vtAutoAssembler is unsupported') end,
  [vtPointer]=writePointer,
  [vtCustom]=function() error('vtCustom is unsupported') end,
  [vtGrouped]=function() error('vtGrouped is unsupported') end
}

function readVarType(address, VarType, ... --[[ length for strings/arrays, but varargs for future possibilities... ]])
  if readVarTypeTable[VarType] then return readVarTypeTable[VarType](address, ...) end
end

function writeVarType(address, VarType, value, ...)
  if writeVarTypeTable[VarType] then return writeVarTypeTable[VarType](address, value, ...)
else error(('%s is an unsupported variable type'):format(tostring(VarType)), 3) end
end

mono_method = {
  -- called with method_object:mono_...() or method_object:mono_...(method_object)
  -- since these are wrappers that pass the method_object.mono_method to the mono funcs
  getJitInfo = function(self) return mono_getJitInfo(self:compile()) end, -- ?? or does this need the compile_method + address?
  getName = function(self) return mono_method_getName(self.mono_method) end,
  get_parameters = function(self) return mono_method_get_parameters(self.mono_method) end,
  disassemble = function(self) return mono_method_disassemble(self.mono_method) end,
  invoke = function(self, args, object)
    args = args or {}
    local params = self:get_parameters()
    if #args ~= #params.parameters then error(('argument mismatch for method %s, got %d expected %d'):format(self:getName(), #args, #params.parameters)) end
    for k,v in ipairs(params.parameters) do
      local a = monoTypeToVarType(v.type)
      local b = args[k].type
      if a ~= b then
        error(('invoke argument failure: exepcted type %d (%s) and got type %d (%s)'):format(a, valueTypes[a], b, valueTypes[b]), 2)
      end
    end
    return mono_invoke_method(self.__domain, self.mono_method, object or self.__address, args)
  end,
  invoke_method_dialog = function(self,address) return mono_invoke_method_dialog(self.__domain, self.mono_method, address or self.__address) end,
  compile = function(self) return mono_compile_method(self.mono_method) end,
  getClass = function(self) return mono_method_getClass(self.mono_method) end,
  getSignature = function(self) return mono_method_getSignature(self.mono_method) end,
  getHeader = function(self) return mono_method_getHeader(self.mono_method) end,
  getILCode = function(self) return mono_methodheader_getILCode(mono_method_getHeader(self.mono_method)) end,
  free = function(self) return mono_free_method(self.mono_method) end
}

function newMonoMethod(method, address, domain)
  if type(method == 'table') then -- mono_findMethod returns table of name and method object address
    -- it's not really worth keeping the name since we can get it later, certainly
    -- not in a table if we really did want to avoid calling mono_method_getName later
    if method.name and method.method then
      method = method.method
    else error('unknown method provided for new mono method, given table but no valid name or method fields', 2)
    end
  end
  local meth = {mono_method = method, __address = address, __domain = domain}
  setmetatable(meth, {__index=mono_method})
  return meth
end

-- could probably make .__fields and .__methods have __index methods that
-- check for this but... kinda seems unnecessary to hide it beind that
local function getField(fields, name)
  return fields[name] or fields[string.char(name:byte()~32) .. name:sub(2)]
end
mono_object = {
  __index = function(t,k)
    local field = getField(t.__fields, k)
    if field then
      -- getAddress in case user gave a string/symbol (which could be updated to another value later)
      -- we need the numeric address here for math with the offset, or needless string manipulation
      -- static addresses should always be coming from mono as actual addresses however
      -- (even user given static addresses from copies should derive from mono...right? lol)
      local addr = field.isStatic and t.__static_address or getAddressSafe(t.__address)

      -- support reading unity/C# strings...
      -- note that _writing_ them is NOT supported, CE sees them as dwords/pointers
      if field.typename == 'System.String' then
        -- assuming .type is an internal vtable pointer or something that changes
        -- fortunately typename is made readily available by CE/Dark Byte (THANKS!)
        return readMonoString(addr+field.offset)
      else
        print('reading', field.name, field.type, field.typename, monoTypeToVarType(field.monotype), valueTypes[monoTypeToVarType(field.monotype)])
        return readVarType(addr + field.offset, monoTypeToVarType(field.monotype))
      end
    else
      field = getField(t.__methods, k)
      if not field then
        error(('%s is neither a field nor method of class %s'):format(k,t.__classname), 2)
      else
        return newMonoMethod(field, t.__address, t.__domain)
      end
    end
  end,
  __newindex = function(t,k,v)
    local field = getField(t.__fields, k)
    local addr = field.isStatic and t.__static_address or t.__address
    return writeVarType(addr + field.offset, monoTypeToVarType(field.monotype), v)
  end
}

-- address is needed for accessing fields and methods (non-static)
-- class is used for finding fields and methods, similarly domain for static fields (if needed)
-- can pass an existing mono object as the class to instead copy fields, etc.

-- not sure if this should be :new or something... this seemed simpler during development.
function newMonoObject(address, class, domain, fields, methods, static_address)
  LaunchMonoDataCollector()
  local mo
  if type(class) == 'string' then class = mono_findClass(class, domain) end
  -- if user gives a mono object as the second argument then just copy that data
  if type(class) == 'table' and getmetatable(class) == mono_object then
    mo = {}
    -- simple copy should work here since tables (fields/methods) will be mostly static stuff that won't change
    for k,v in pairs(class) do mo[k] = v end
    mo.__address = address
  else
    mo = {
      -- HOPEFULLY having these start with __ will reduce collisions with valid field names...
      -- I guess if they do at some point you'd have to use eg.
      -- mo.__fields.__address.offset to access the real mono objects __address field info
      -- and of course call the read and write functions yourself as well. sorry.
      -- defaults are necessary otherwise they fall into the __index metamethod, which we don't want here
      __classname = mono_class_getName(class) or 'UnknownClassName', -- could avoid this if the user gives the classname, which is likely...
      __domain = domain or '',
      __static_address = mono_class_getStaticFieldAddress(domain or '', class) or 0,
      __address=address or 0,
      __fields=fields or findMonoFields(class) or {},
      __methods=methods or findMonoMethods(class) or {},
      -- should I have a copy function here?? would probably be useful...
    }
  end

  -- now the data is known, setup the meta table so they get looked up when asked for
  setmetatable(mo, mono_object)

  -- try to support static instances by passing their field name as the address
  if type(address) == 'string' and not getAddressSafe(address) then
    local a = getField(mo.__fields, address)
    if a then mo.__address = mo[address] end
  end
  return mo
end
