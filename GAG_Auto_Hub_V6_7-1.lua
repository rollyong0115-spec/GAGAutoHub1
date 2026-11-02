--[[
    GROW A GARDEN AUTO HUB V7.0
    Delta Android

    NORMAL SHOPS
    - Auto Buy ALL Seeds
    - Auto Buy ALL Gear
    - Auto Buy ALL Eggs

    FARM
    - Instant Collect
    - Auto Sell Entire Inventory

    HALLOWEEN
    - Auto Buy ALL Scary Seeds
    - Auto Buy Selected Frightening Fauna
    - Auto Buy Selected Demonic Decor

    EXCLUDED
    - Normal Cosmetics
    - Pumpkin Crate

    LOCKED
    - Haunted Stall

    All toggles start OFF.
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local events = RS:WaitForChild("GameEvents")

-- Stop a previous V7.0 instance.
-- This prevents duplicate background loops.

local globalEnv = (getgenv and getgenv()) or _G

if globalEnv.GAG_AutoHub_Stop then
    pcall(globalEnv.GAG_AutoHub_Stop)
end

local alive = true
local toggles = {}
local baselines = {}

globalEnv.GAG_AutoHub_Stop = function()
    alive = false
end

-- Remove older hub windows

for _, name in ipairs({
    "GAG_AutoHub_V67",
    "GAG_AutoHub_V68",
    "GAG_AutoHub_V69",
    "GAG_AutoHub_V70"
}) do
    local old = pg:FindFirstChild(name)
    if old then
        old:Destroy()
    end
end

-- Remote helper

local function fire(remoteName, ...)
    local remote = events:FindFirstChild(remoteName)

    if not remote then
        warn("[GAG V7.0] Missing remote:", remoteName)
        return false
    end

    local args = table.pack(...)

    local ok, err = pcall(function()
        remote:FireServer(
            table.unpack(args, 1, args.n)
        )
    end)

    if not ok then
        warn("[GAG V7.0]", err)
    end

    return ok
end

-- Parse stock labels such as X2 Stock

local function parseStock(value)
    if type(value) ~= "string" then
        return nil
    end

    return tonumber(
        value:match("[Xx]%s*(%d+)%s*[Ss]tock")
    )
end

-- Normal shop stock scanner

local function normalStock(guiName)
    local result = {}

    local gui = pg:FindFirstChild(guiName)
    local frame = gui and gui:FindFirstChild("Frame")
    local scrolling = frame and frame:FindFirstChild(
        "ScrollingFrame"
    )

    if not scrolling then
        return result
    end

    for _, item in ipairs(scrolling:GetChildren()) do
        local main = item:FindFirstChild("Main_Frame")
        local label = main and main:FindFirstChild(
            "Stock_Text"
        )

        if label and label:IsA("TextLabel") then
            local qty = parseStock(label.Text)

            if qty ~= nil then
                result[item.Name] = qty
            end
        end
    end

    return result
end

-- Normal shop auto-buyer

local function buyNormal(
    key,
    guiName,
    remoteName,
    prefix
)
    if not toggles[key] then
        return
    end

    local current = normalStock(guiName)
    local previous = baselines[key] or {}

    for name, qty in pairs(current) do
        local oldQty = previous[name]

        local amount = oldQty == nil
            and qty
            or math.max(0, qty - oldQty)

        if amount > 0 then
            for i = 1, math.min(amount, 100) do
                if not alive or not toggles[key] then
                    break
                end

                if prefix then
                    fire(remoteName, prefix, name)
                else
                    fire(remoteName, name)
                end
            end
        end
    end

    baselines[key] = current
end

-- Halloween shop roots

local function halloweenShopRoots()
    local roots = {}
    local eventFolder = pg:FindFirstChild("Events")

    if eventFolder then
        local oldEvent = eventFolder:FindFirstChild(
            "HalloweenEvent"
        )

        if oldEvent then
            local shop = oldEvent:FindFirstChild(
                "HalloweenEventShop_UI"
            )

            if shop then
                table.insert(roots, shop)
            end
        end

        local newEvent = eventFolder:FindFirstChild(
            "Halloween2026Event"
        )

        if newEvent then
            for _, obj in ipairs(
                newEvent:GetDescendants()
            ) do
                if obj:IsA("ScreenGui")
                    and obj.Name:lower():find("shop") then

                    table.insert(roots, obj)
                end
            end
        end
    end

    local standalone = pg:FindFirstChild(
        "HalloweenEventShop_UI"
    )

    if standalone then
        table.insert(roots, standalone)
    end

    return roots
end

-- Halloween stock scanner

local function halloweenStock()
    local result = {}

    for _, root in ipairs(halloweenShopRoots()) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextLabel")
                and obj.Name == "Stock_Text" then

                local qty = parseStock(obj.Text)

                if qty ~= nil then
                    local main = obj.Parent
                    local item = main and main.Parent

                    if item then
                        local name = item.Name

                        local nameLabel = main:FindFirstChild(
                            "Seed_Text"
                        )

                        if nameLabel
                            and nameLabel:IsA("TextLabel")
                            and nameLabel.Text ~= "" then

                            name = nameLabel.Text
                        end

                        result[name] = math.max(
                            result[name] or 0,
                            qty
                        )
                    end
                end
            end
        end
    end

    return result
end

-- Halloween item selections

local scarySeeds = {
    ["Halloween Candy Corn Carrot"] = true,
    ["Halloween Spider Shrub"] = true,
    ["Haunted Sprinkler"] = true,
    ["Halloween Pumpkin Lantern"] = true,
    ["Halloween Candy Cluster"] = true,
    ["Halloween Witch's Broom"] = true,
    ["Halloween Webberry"] = true,
    ["Halloween Blood Kiwi"] = true,
    ["Halloween Fang Root"] = true,
    ["Halloween Haunted Hallow"] = true
}

local frighteningFauna = {
    ["Spooky Chest"] = true,
    ["Haunted Chest"] = true,
    ["Haunted Egg"] = true
}

local demonicDecor = {
    ["Spooky Crate"] = true,
    ["Haunted Crate"] = true,
    ["Haunted Well"] = true
}

-- Halloween auto-buyer

local function buyHalloweenCategory(
    key,
    category,
    selected
)
    if not toggles[key] then
        return
    end

    local current = halloweenStock()
    local previous = baselines[key] or {}
    local nextBaseline = {}

    for name in pairs(selected) do
        local qty = current[name]

        if qty ~= nil then
            local oldQty = previous[name]

            local amount = oldQty == nil
                and qty
                or math.max(0, qty - oldQty)

            if amount > 0 then
                for i = 1, math.min(amount, 100) do
                    if not alive or not toggles[key] then
                        break
                    end

                    fire(
                        "BuyEventShopStock",
                        name,
                        category
                    )
                end
            end

            nextBaseline[name] = qty
        end
    end

    baselines[key] = nextBaseline
end

-- Correct farm detection
-- Confirmed path:
-- Farm.Important.Data.Owner

local function getMyFarm()
    local farms = workspace:FindFirstChild("Farm")

    if not farms then
        return nil
    end

    for _, farm in ipairs(farms:GetChildren()) do
        local important = farm:FindFirstChild("Important")
        local data = important and important:FindFirstChild(
            "Data"
        )

        local owner = data and data:FindFirstChild("Owner")

        if owner then
            local value = owner.Value

            if value == player
                or tostring(value) == player.Name
                or tostring(value) == tostring(player.UserId) then

                return farm
            end
        end
    end

    return nil
end

-- Fruit inventory capacity
-- Looks for "Fruit Items (54/250)"

local function getFruitCapacity()
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local current, maximum = obj.Text:match(
                "Fruit%s*Items%s*%((%d+)%s*/%s*(%d+)%)"
            )

            if current and maximum then
                return tonumber(current), tonumber(maximum)
            end
        end
    end

    return nil, nil
end

local function inventoryFull()
    local current, maximum = getFruitCapacity()

    if current and maximum then
        return current >= maximum
    end

    return false
end

-- INSTANT COLLECT V7.0
-- Uses the tested batch collection method.
-- Up to 20 fruits per request.

local function instantCollect()
    if not toggles.harvest or not alive then
        return
    end

    if inventoryFull() then
        return
    end

    local farm = getMyFarm()

    if not farm then
        warn("[GAG V7.0] Your farm not found")
        return
    end

    local important = farm:FindFirstChild("Important")
    local plants = important and important:FindFirstChild(
        "Plants_Physical"
    )

    if not plants then
        return
    end

    local crops = events:FindFirstChild("Crops")
    local collect = crops and crops:FindFirstChild(
        "Collect"
    )

    if not collect then
        return
    end

    local batch = {}
    local batchesSent = 0
    local maxBatchesPerCycle = 5
    local batchSize = 20

    local function sendBatch()
        if #batch == 0 then
            return
        end

        if not alive
            or not toggles.harvest
            or inventoryFull() then

            batch = {}
            return
        end

        local request = batch
        batch = {}

        local ok, err = pcall(function()
            collect:FireServer(request)
        end)

        if not ok then
            warn("[GAG V7.0] Collect error:", err)
        end

        batchesSent += 1

        task.wait(0.35)
    end

    for _, plant in ipairs(plants:GetChildren()) do
        if not alive or not toggles.harvest then
            break
        end

        if inventoryFull() then
            break
        end

        local fruits = plant:FindFirstChild("Fruits")

        if fruits then
            for _, fruit in ipairs(fruits:GetChildren()) do
                if not alive or not toggles.harvest then
                    break
                end

                if fruit:IsA("Model") then
                    table.insert(batch, fruit)

                    if #batch >= batchSize then
                        sendBatch()

                        if batchesSent >= maxBatchesPerCycle then
                            return
                        end

                        if inventoryFull() then
                            return
                        end
                    end
                end
            end
        end
    end

    if #batch > 0
        and batchesSent < maxBatchesPerCycle then

        sendBatch()
    end
end

-- Auto Sell
-- Sells entire inventory when enabled.

local function sell()
    local ev = events:FindFirstChild("Events")
    local halloween = ev and ev:FindFirstChild(
        "Halloween2026Event"
    )

    local remote = halloween and halloween:FindFirstChild(
        "HalloweenSellInventoryRE"
    )

    if remote then
        pcall(function()
            remote:FireServer()
        end)
    end
end

-- GUI

local gui = Instance.new("ScreenGui")
gui.Name = "GAG_AutoHub_V70"
gui.ResetOnSpawn = false
gui.Parent = pg

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(295, 355)
panel.Position = UDim2.new(0.5, -147, 0.17, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 29, 40)
panel.Active = true
panel.Parent = gui

Instance.new("UICorner", panel).CornerRadius =
    UDim.new(0, 10)

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -75, 0, 36)
header.Position = UDim2.fromOffset(10, 0)
header.BackgroundTransparency = 1
header.Text = "GAG AUTO HUB V7.0"
header.TextColor3 = Color3.new(1, 1, 1)
header.Font = Enum.Font.GothamBold
header.TextSize = 15
header.TextXAlignment = Enum.TextXAlignment.Left
header.Active = true
header.Parent = panel

local function topButton(text, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(26, 27)
    b.Position = UDim2.fromOffset(x, 5)
    b.Text = text
    b.TextSize = 12
    b.TextColor3 = Color3.new(1, 1, 1)
    b.BackgroundColor3 = Color3.fromRGB(61, 68, 88)
    b.Parent = panel

    Instance.new("UICorner", b).CornerRadius =
        UDim.new(0, 5)

    return b
end

local minimize = topButton("_", 233)
local close = topButton("X", 263)

local scroller = Instance.new("ScrollingFrame")
scroller.Position = UDim2.fromOffset(7, 40)
scroller.Size = UDim2.new(1, -14, 1, -47)
scroller.BackgroundTransparency = 1
scroller.ScrollBarThickness = 3
scroller.CanvasSize = UDim2.new()
scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroller.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = scroller

-- Toggle rows

local function row(key, label, disabled)
    toggles[key] = false

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -5, 0, 37)
    b.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Text = "  OFF  |  " .. label
    b.Parent = scroller

    Instance.new("UICorner", b).CornerRadius =
        UDim.new(0, 7)

    if disabled then
        b.Text = "  LOCKED  |  " .. label
        b.TextColor3 = Color3.fromRGB(165, 165, 165)
        return
    end

    b.MouseButton1Click:Connect(function()
        toggles[key] = not toggles[key]

        b.Text = "  "
            .. (toggles[key] and "ON   |  " or "OFF  |  ")
            .. label

        b.BackgroundColor3 = toggles[key]
            and Color3.fromRGB(36, 104, 75)
            or Color3.fromRGB(45, 50, 65)

        if toggles[key] then
            baselines[key] = {}
        else
            baselines[key] = nil
        end
    end)
end

row("seeds", "Normal Seeds - Buy ALL")
row("gear", "Normal Gear - Buy ALL")
row("eggs", "Normal Eggs - Buy ALL")
row("harvest", "Instant Collect - Auto Harvest")
row("sell", "Auto Sell - Entire Inventory")
row("scary", "Scary Seeds - Buy ALL")
row("fauna", "Frightening Fauna - 3 Selected")
row("decor", "Demonic Decor - 3 Selected")
row("stall", "Haunted Stall - Once Only", true)

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -8, 0, 75)
note.BackgroundTransparency = 1
note.TextWrapped = true
note.TextSize = 11
note.TextColor3 = Color3.fromRGB(200, 205, 215)
note.Text =
    "V7.0: Instant Collect uses your confirmed farm "
    .. "and batches up to 20 fruits. "
    .. "Haunted Stall locked. Cosmetics excluded."
note.Parent = scroller

-- Android touch dragging

local dragging = false
local dragStart
local startPos
local dragInput

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        dragInput = input

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart

        panel.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Minimize / restore

minimize.MouseButton1Click:Connect(function()
    local expanded = scroller.Visible

    scroller.Visible = not expanded

    panel.Size = expanded
        and UDim2.fromOffset(295, 36)
        or UDim2.fromOffset(295, 355)
end)

-- Close and stop loops

close.MouseButton1Click:Connect(function()
    alive = false
    gui:Destroy()
end)

-- Auto-buy loop

task.spawn(function()
    while alive and gui.Parent do

        pcall(function()
            buyNormal(
                "seeds",
                "Seed_Shop",
                "BuySeedStock",
                "Shop"
            )
        end)

        pcall(function()
            buyNormal(
                "gear",
                "Gear_Shop",
                "BuyGearStock"
            )
        end)

        pcall(function()
            buyNormal(
                "eggs",
                "PetShop_UI",
                "BuyPetEgg"
            )
        end)

        pcall(function()
            buyHalloweenCategory(
                "scary",
                "Scary Seeds",
                scarySeeds
            )
        end)

        pcall(function()
            buyHalloweenCategory(
                "fauna",
                "Frightening Fauna",
                frighteningFauna
            )
        end)

        pcall(function()
            buyHalloweenCategory(
                "decor",
                "Demonic Decor",
                demonicDecor
            )
        end)

        task.wait(0.5)
    end
end)

-- Instant Collect loop

task.spawn(function()
    while alive and gui.Parent do
        if toggles.harvest then
            pcall(instantCollect)
        end

        task.wait(2)
    end
end)

-- Auto Sell loop

task.spawn(function()
    while alive and gui.Parent do
        if toggles.sell then
            pcall(sell)
        end

        task.wait(10)
    end
end)

print("[GAG AUTO HUB V7.0] Loaded successfully")

