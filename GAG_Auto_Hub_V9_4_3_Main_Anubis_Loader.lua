-- GAG Auto Hub V9.4.3 | MAIN ANUBIS Loader
-- No Ancient Trials module. V9.4.1 and V9.4.2 remain separate.
-- Smart Collect Pause available (OFF by default).
-- 1T paid restart remains OFF by default; inspect before using.

local URL="https://raw.githubusercontent.com/rollyong0115-spec/Gagv2/main/GAG_Auto_Hub_V9_4_3_Main_Anubis_Neon_Delta.lua"
local ok,source=pcall(function() return game:HttpGet(URL) end)
if not ok or type(source)~="string" or source=="" then
    warn("[GAG V9.4.3] Download failed: "..tostring(source))
    return
end
local run,err=loadstring(source)
if type(run)~="function" then
    warn("[GAG V9.4.3] Compile error: "..tostring(err))
    return
end
local success,runtimeError=pcall(run)
if not success then
    warn("[GAG V9.4.3] Runtime error: "..tostring(runtimeError))
end
