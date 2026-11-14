-- GAG Ancient Trials UI Cleaner
-- Only removes our Ancient Trials monitor/quick GUIs.
local envs = {_G}
pcall(function()
    if type(getgenv) == "function" then
        table.insert(envs, getgenv())
    end
end)

local keys = {
    "GAG_Trials_V943_Stop",
    "GAG_Trials_Quick_Stop",
    "GAG_Trials_Lite_Stop"
}
for _, env in ipairs(envs) do
    if type(env) == "table" then
        for _, key in ipairs(keys) do
            local cleanup = env[key]
            if type(cleanup) == "function" then
                pcall(cleanup)
                env[key] = nil
            end
        end
    end
end

local roots, visited = {}, {}
local function add(root)
    if root and not visited[root] then
        visited[root] = true
        table.insert(roots, root)
    end
end
local player = game:GetService("Players").LocalPlayer
if player then add(player:FindFirstChildOfClass("PlayerGui")) end
add(game:GetService("CoreGui"))
pcall(function()
    if type(gethui) == "function" then add(gethui()) end
end)

local removed = 0
for _, root in ipairs(roots) do
    local ok, descendants = pcall(function() return root:GetDescendants() end)
    if ok and descendants then
        for _, obj in ipairs(descendants) do
            if obj:IsA("ScreenGui") and (
                obj.Name:match("^GAGTrialMonitor")
                or obj.Name:match("^GAGTrialQuick")
            ) then
                pcall(function() obj:Destroy() end)
                removed = removed + 1
            end
        end
    end
end
print("[Ancient Trials Cleaner] Finished. UI panels removed:", removed)
