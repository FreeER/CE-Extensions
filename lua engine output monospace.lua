--##### Lua Engine Output Monospace Setter for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  sets the lua engine output text to use the same font as the script input
  (which is monospace)
]]
getLuaEngine().mOutput.Font.Assign(getLuaEngine().mScript.Font)
