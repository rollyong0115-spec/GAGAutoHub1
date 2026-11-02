-- Grow a Garden Auto Hub V6.7 | Delta Android
-- All toggles OFF by default. Purchase requests are not confirmations.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local player = Players.LocalPlayer
local pg = player:WaitForChild('PlayerGui')
local events = RS:WaitForChild('GameEvents')
local unpackArgs = table.unpack or unpack

local old = pg:FindFirstChild('GAG_AutoHub_V67')
if old then old:Destroy() end
local alive = true
local toggles = {}
local baseline = {}
local function stockOf(item)
    local main = item:FindFirstChild('Main_Frame')
    local label = main and main:FindFirstChild('Stock_Text')
    if not label then return nil end
    return tonumber((label.Text or ''):match('[Xx]%s*(%d+)%s*[Ss]tock'))
end
local function stockMap(guiName)
    local found = {}
    local gui = pg:FindFirstChild(guiName)
    local frame = gui and gui:FindFirstChild('Frame')
    local scrolling = frame and frame:FindFirstChild('ScrollingFrame')
    if not scrolling then return found end
    for _, item in ipairs(scrolling:GetChildren()) do
        local amount = stockOf(item)
        if amount ~= nil then found[item.Name] = amount end
    end
    return found
end
local function fire(remoteName, ...)
    local remote = events:FindFirstChild(remoteName)
    if not remote then return false end
    return pcall(function(...) remote:FireServer(...) end, ...)
end
local function buyStock(key, guiName, remoteName, prefix)
    local now = stockMap(guiName)
    local previous = baseline[key] or {}
    for name, qty in pairs(now) do
        local prior = previous[name]
        local toBuy = (prior == nil) and qty or math.max(0, qty - prior)
        if toggles[key] and toBuy > 0 then
            for i = 1, math.min(toBuy, 100) do
                if not alive or not toggles[key] then break end
                if prefix then fire(remoteName, prefix, name)
                else fire(remoteName, name) end
            end
        end
    end
    baseline[key] = now
end

local function halloweenStock()
    -- UI layouts can change. Scan actual event shop item frames, not module stock ranges.
    local result = {}
    local roots = {}
    local eventsGui = pg:FindFirstChild('Events')
    if eventsGui then
        local halloween = eventsGui:FindFirstChild('Halloween2026Event')
        if halloween then table.insert(roots, halloween) end
    end
    local root = pg:FindFirstChild('HalloweenEventShop_UI')
    if root then table.insert(roots, root) end
    local function consider(label)
        local n = tonumber((label.Text or ''):match('[Xx]%s*(%d+)%s*[Ss]tock'))
        if n == nil then return end
        local main = label.Parent
        local item = main and main.Parent
        if not item then return end
        local name = item.Name
        local nameLabel = main:FindFirstChild('Seed_Text', true)
        if nameLabel and nameLabel:IsA('TextLabel') and nameLabel.Text ~= '' then
            name = nameLabel.Text
        end
        result[name] = n
    end
    for _, r in ipairs(roots) do
        for _, desc in ipairs(r:GetDescendants()) do
            if desc:IsA('TextLabel') and desc.Name == 'Stock_Text' then
                consider(desc)
            end
        end
    end
    return result
end
local scary = {
    ['Halloween Candy Corn Carrot']=true,['Halloween Spider Shrub']=true,
    ['Haunted Sprinkler']=true,['Halloween Pumpkin Lantern']=true,
    ['Halloween Candy Cluster']=true,["Halloween Witch's Broom"]=true,
    ['Halloween Webberry']=true,['Halloween Blood Kiwi']=true,
    ['Halloween Fang Root']=true,['Halloween Haunted Hallow']=true,
}
local fauna = {['Spooky Chest']=true,['Haunted Chest']=true,['Haunted Egg']=true}
local decor = {['Spooky Crate']=true,['Haunted Crate']=true,['Haunted Well']=true}
local function buyHalloween()
    local now = halloweenStock()
    local prev = baseline.halloween or {}
    for name, qty in pairs(now) do
        local delta = (prev[name] == nil) and qty or math.max(0, qty - prev[name])
        local category
        if toggles.scary and scary[name] then category = 'Scary Seeds' end
        if toggles.fauna and fauna[name] then category = 'Frightening Fauna' end
        -- Demonic Decor remote/category is not verified; keep toggle disabled below.
        if category and delta > 0 then
            for i = 1, math.min(delta, 100) do
                if not alive then break end
                fire('BuyEventShopStock', name, category)
            end
        end
    end
    baseline.halloween = now
end

local function inventoryFull()
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA('TextLabel') then
            local a,b = obj.Text:match('Fruit%s*Items%s*%((%d+)%s*/%s*(%d+)%)')
            if a and b then return tonumber(a) >= tonumber(b) end
        end
    end
    return false
end
local function harvest()
    if inventoryFull() then return end
    local farms = workspace:FindFirstChild('Farm')
    if not farms then return end
    local ownFarm
    for _, farm in ipairs(farms:GetChildren()) do
        local owner = farm:FindFirstChild('Owner')
        if owner and tostring(owner.Value) == player.Name then ownFarm = farm; break end
    end
    if not ownFarm then return end
    local important = ownFarm:FindFirstChild('Important')
    local plants = important and important:FindFirstChild('Plants_Physical')
    if not plants then return end
    local crops = events:FindFirstChild('Crops')
    local collect = crops and crops:FindFirstChild('Collect')
    if not collect then return end
    local sent = 0
    for _, plant in ipairs(plants:GetChildren()) do
        local fruits = plant:FindFirstChild('Fruits')
        if fruits then
            for _, fruit in ipairs(fruits:GetChildren()) do
                if fruit:IsA('Model') then
                    local prompt = fruit:FindFirstChildWhichIsA('ProximityPrompt', true)
                    if prompt and prompt.Enabled then
                        pcall(function() collect:FireServer({fruit}) end)
                        sent += 1
                        if sent >= 10 or not toggles.harvest or not alive then return end
                        task.wait(0.2)
                    end
                end
            end
        end
    end
end
local function sell()
    local ev = events:FindFirstChild('Events')
    local halloween = ev and ev:FindFirstChild('Halloween2026Event')
    local remote = halloween and halloween:FindFirstChild('HalloweenSellInventoryRE')
    if remote then pcall(function() remote:FireServer() end) end
end

local gui = Instance.new('ScreenGui')
gui.Name = 'GAG_AutoHub_V67'; gui.ResetOnSpawn = false; gui.Parent = pg
local panel = Instance.new('Frame')
panel.Size = UDim2.fromOffset(290, 355)
panel.Position = UDim2.new(.5,-145,.17,0)
panel.BackgroundColor3 = Color3.fromRGB(25,29,40)
panel.Active = true; panel.Draggable = true; panel.Parent = gui
Instance.new('UICorner',panel).CornerRadius = UDim.new(0,10)
local header = Instance.new('TextLabel')
header.Size = UDim2.new(1,-76,0,36); header.Position = UDim2.fromOffset(10,0)
header.BackgroundTransparency = 1; header.Text = 'GAG AUTO HUB V6.7'
header.TextColor3 = Color3.new(1,1,1); header.Font = Enum.Font.GothamBold
header.TextSize = 15; header.TextXAlignment = Enum.TextXAlignment.Left; header.Parent = panel
local function button(text,x,w)
    local b = Instance.new('TextButton'); b.Size = UDim2.fromOffset(w,27)
    b.Position = UDim2.fromOffset(x,5); b.Text = text; b.TextSize = 12
    b.TextColor3 = Color3.new(1,1,1); b.BackgroundColor3 = Color3.fromRGB(61,68,88)
    b.Parent = panel; Instance.new('UICorner',b).CornerRadius = UDim.new(0,5)
    return b
end
local minimize = button('_',229,26)
local close = button('X',259,26)
local scroller = Instance.new('ScrollingFrame')
scroller.Position = UDim2.fromOffset(7,40); scroller.Size = UDim2.new(1,-14,1,-47)
scroller.BackgroundTransparency = 1; scroller.ScrollBarThickness = 3
scroller.CanvasSize = UDim2.new(); scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroller.Parent = panel
local layout = Instance.new('UIListLayout')
layout.Padding = UDim.new(0,6); layout.Parent = scroller
local function row(key,label,disabled)
    toggles[key] = false
    local b = Instance.new('TextButton')
    b.Size = UDim2.new(1,-5,0,37); b.BackgroundColor3 = Color3.fromRGB(45,50,65)
    b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.Gotham
    b.TextSize = 12; b.TextXAlignment = Enum.TextXAlignment.Left
    b.Text = '  OFF  |  '..label..(disabled and ' (unverified)' or '')
    b.Parent = scroller
    Instance.new('UICorner',b).CornerRadius = UDim.new(0,7)
    if not disabled then
        b.MouseButton1Click:Connect(function()
            toggles[key] = not toggles[key]
            b.Text = '  '..(toggles[key] and 'ON   |  ' or 'OFF  |  ')..label
            b.BackgroundColor3 = toggles[key] and Color3.fromRGB(36,104,75) or Color3.fromRGB(45,50,65)
            if toggles[key] then
                if key == 'seeds' or key == 'gear' or key == 'eggs' then
                    baseline[key] = {} -- buy current visible stock on activation
                elseif key == 'scary' or key == 'fauna' then
                    baseline.halloween = {} -- buy currently visible event stock on activation
                end
            end
        end)
    else
        b.TextColor3 = Color3.fromRGB(170,170,170)
    end
end
row('seeds','Normal Seeds - Buy ALL')
row('gear','Normal Gear - Buy ALL')
row('eggs','Normal Eggs - Buy ALL')
row('harvest','Auto Harvest')
row('sell','Auto Sell - Entire Inventory')
row('scary','Scary Seeds - Buy ALL')
row('fauna','Frightening Fauna - 3 Selected')
row('decor','Demonic Decor - 3 Selected',true)
row('stall','Haunted Stall - Once Only',true)
local note = Instance.new('TextLabel')
note.Size = UDim2.new(1,-8,0,60); note.BackgroundTransparency = 1
note.TextWrapped = true; note.TextSize = 11; note.TextColor3 = Color3.fromRGB(200,205,215)
note.Text = 'Halloween decor/stall disabled until their correct purchase remote is confirmed. Normal Cosmetics excluded.'
note.Parent = scroller
minimize.MouseButton1Click:Connect(function()
    local collapsed = scroller.Visible
    scroller.Visible = not collapsed
    panel.Size = collapsed and UDim2.fromOffset(290,36) or UDim2.fromOffset(290,355)
end)
close.MouseButton1Click:Connect(function()
    alive = false
    gui:Destroy()
end)

task.spawn(function()
    while alive and gui.Parent do
        pcall(function() buyStock('seeds','Seed_Shop','BuySeedStock','Shop') end)
        pcall(function() buyStock('gear','Gear_Shop','BuyGearStock') end)
        pcall(function() buyStock('eggs','PetShop_UI','BuyPetEgg') end)
        pcall(buyHalloween)
        task.wait(.5)
    end
end)
task.spawn(function()
    while alive and gui.Parent do
        if toggles.harvest then pcall(harvest) end
        task.wait(3)
    end
end)
task.spawn(function()
    while alive and gui.Parent do
        if toggles.sell then pcall(sell) end
        task.wait(10)
    end
end)
