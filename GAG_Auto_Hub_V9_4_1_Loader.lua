-- GAG Auto Hub V9.4.1 | Minimal GitHub Loader
-- Loads the standalone V9.4.1 source from Gagv2.
-- Existing V8.6 launcher and all prior versions are left untouched.
-- WARNING: The loaded hub offers an opt-in 1T paid restart. All toggles begin OFF.

local URL = "https://raw.githubusercontent.com/rollyong0115-spec/Gagv2/main/GAG_Auto_Hub_V9_4_1_Neon_Delta.lua"

local ok, source = pcall(function()
    return game:HttpGet(URL)
end)
if not ok or type(source) ~= "string" or source == "" then
    warn("[GAG V9.4.1] Download failed: " .. tostring(source))
    return
end

local compiled, compileError = loadstring(source)
if type(compiled) ~= "function" then
    warn("[GAG V9.4.1] Compile failed: " .. tostring(compileError))
    return
end

local ran, runError = pcall(compiled)
if not ran then
    warn("[GAG V9.4.1] Run failed: " .. tostring(runError))
end
