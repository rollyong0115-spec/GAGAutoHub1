-- GAG Auto Hub V9.4.2 | GitHub Loader
-- Loads standalone Gagv2 V9.4.2; previous versions remain unchanged.
-- Trial tracking is READ ONLY. It never auto-submits fruits.
-- Existing paid Arc restart uses 1T and is OFF by default.

local URL = "https://raw.githubusercontent.com/rollyong0115-spec/Gagv2/main/GAG_Auto_Hub_V9_4_2_Neon_Delta.lua"
local ok, source = pcall(function()
    return game:HttpGet(URL)
end)
if not ok or type(source) ~= "string" or source == "" then
    warn("[GAG V9.4.2] Download failed: "..tostring(source))
    return
end

local compiled, compileError = loadstring(source)
if type(compiled) ~= "function" then
    warn("[GAG V9.4.2] Compile failed: "..tostring(compileError))
    return
end

local success, err = pcall(compiled)
if not success then
    warn("[GAG V9.4.2] Runtime error: "..tostring(err))
end
