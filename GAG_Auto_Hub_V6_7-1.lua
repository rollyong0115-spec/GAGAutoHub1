
--[[
    GROW A GARDEN AUTO HUB V6.8
    Delta Android

    FIXED:
    - Haunted Egg stock detection
    - HalloweenEvent nested GUI path
    - Separate Halloween category tracking
    - Compact draggable UI
    - Minimize / restore

    FEATURES:
    - Auto Buy Normal Seeds
    - Auto Buy Normal Gear
    - Auto Buy Normal Eggs
    - Auto Harvest
    - Auto Sell
    - Auto Buy Scary Seeds
    - Auto Buy Frightening Fauna

    Normal Cosmetics excluded.
    Demonic Decor / Haunted Stall disabled
    until their purchase paths are verified.

    ALL TOGGLES DEFAULT OFF.
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local events = RS:WaitForChild("GameEvents")

-- Remove previous versions

for _, name in ipairs({
    "GAG_AutoHub_V67",
    "GAG_AutoHub_V68"
}) do
    local old = pg:FindFirstChild(name)
    if old then
        old:Destroy()
    end
end

local alive = true
local toggles = {}
local baselines = {}
local pending = {}

-- Purchase request helper

local function fire(remoteName, ...)
    local remote = events:FindFirstChild(remoteName)

    if not remote then
        warn("[GAG V6.8] Missing remote:", remoteName)
        return false
    end

    local ok, err = pcall(function(...)
        remote:FireServer(...)
    end, ...)

    if not ok then
        warn("[GAG V6.8]", err)
    end

    return ok
end

-- Read a stock label

local function parseStock(text)
    if type(text) ~= "string" then
        return nil
    end

    return tonumber(
        text:match("[Xx]%s*(%d+)%s*[Ss]tock")
    )
end

-- Normal shop stock

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

-- Normal shop auto-buy
-- Buy current stock when first enabled.
-- Buy additional quantities when stock rises.

local function buyNormal(key, guiName, remoteName, prefix)
    if not toggles[key] then
        return
    end

    local current = normalStock(guiName)
    local previous = baselines[key] or {}

    for name, qty in pairs(current) do
        local oldQty = previous[name]

        local amount

        if oldQty == nil then
            amount = qty
        else
            amount = math.max(0, qty - oldQty)
        end

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

-- Halloween shop discovery
-- Includes the exact path confirmed by
-- the Haunted Egg diagnostic scanner.

local function halloweenShopRoots()
    local roots = {}

    local eventsGui = pg:FindFirstChild("Events")

    if eventsGui then
        local oldHalloween = eventsGui:FindFirstChild(
            "HalloweenEvent"
        )

        if oldHalloween then
            local shop = oldHalloween:FindFirstChild(
                "HalloweenEventShop_UI"
            )

            if shop then
                table.insert(roots, shop)
            end
        end

        local newHalloween = eventsGui:FindFirstChild(
            "Halloween2026Event"
        )

        if newHalloween then
            for _, obj in ipairs(
                newHalloween:GetDescendants()
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

                        -- Keep the highest detected stock
                        -- if multiple event UIs list an item.
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

-- Selected Halloween items

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

-- Separate baseline per Halloween category.
-- Avoids one toggle resetting another.

local function buyHalloweenCategory(key, category, selected)
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

            local amount

            if oldQty == nil then
                amount = qty
            else
                amount = math.max(0, qty - oldQty)
            end

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

-- Inventory capacity

local function inventoryFull()
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local current, maximum = obj.Text:match(
                "Fruit%s*Items%s*%((%d+)%s*/%s*(%d+)%)"
            )

            if current and maximum then
                return tonumber(current) >= tonumber(maximum)
            end
        end
    end

    return false
end

-- Auto Harvest

local function harvest()
    if inventoryFull() then
        return
    end

    local farms = workspace:FindFirstChild("Farm")
    if not farms then
        return
    end

    local ownFarm

    for _, farm in ipairs(farms:GetChildren()) do
        local owner = farm:FindFirstChild("Owner")

        if owner
            and tostring(owner.Value) == player.Name then

            ownFarm = farm
            break
        end
    end

    if not ownFarm then
        return
    end

    local important = ownFarm:FindFirstChild("Important")
    local plants = important and important:FindFirstChild(
        "Plants_Physical"
    )

    if not plants then
        return
    end

    local crops = events:FindFirstChild("Crops")
    local collect = crops and crops:FindFirstChild("Collect")

    if not collect then
        return
    end

    local sent = 0

    for _, plant in ipairs(plants:GetChildren()) do
        local fruits = plant:FindFirstChild("Fruits")

        if fruits then
            for _, fruit in ipairs(fruits:GetChildren()) do
                if fruit:IsA("Model") then
                    local prompt = fruit:FindFirstChildWhichIsA(
                        "ProximityPrompt",
                        true
                    )

                    if prompt and prompt.Enabled then
                        pcall(function()
                            collect:FireServer({fruit})
                        end)

                        sent += 1

                        if sent >= 10
                            or not toggles.harvest
                            or not alive then
                            return
                        end

                        task.wait(0.2)
                    end
                end
            end
        end
    end
end

-- Auto Sell
-- Sells the entire inventory.

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

-- UI

local gui = Instance.new("ScreenGui")
gui.Name = "GAG_AutoHub_V68"
gui.ResetOnSpawn = false
gui.Parent = pg

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(290, 355)
panel.Position = UDim2.new(0.5, -145, 0.17, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 29, 40)
panel.Active = true
panel.Draggable = true
panel.Parent = gui

Instance.new("UICorner", panel).CornerRadius =
    UDim.new(0, 10)

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -76, 0, 36)
header.Position = UDim2.fromOffset(10, 0)
header.BackgroundTransparency = 1
header.Text = "GAG AUTO HUB V6.8"
header.TextColor3 = Color3.new(1, 1, 1)
header.Font = Enum.Font.GothamBold
header.TextSize = 15
header.TextXAlignment = Enum.TextXAlignment.Left
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

local minimize = topButton("_", 229)
local close = topButton("X", 259)

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
            -- First scan after activation
            -- buys all currently available stock.
            baselines[key] = {}
        else
            baselines[key] = nil
        end
    end)
end

row("seeds", "Normal Seeds - Buy ALL")
row("gear", "Normal Gear - Buy ALL")
row("eggs", "Normal Eggs - Buy ALL")
row("harvest", "Auto Harvest")
row("sell", "Auto Sell - Entire Inventory")
row("scary", "Scary Seeds - Buy ALL")
row("fauna", "Frightening Fauna - 3 Selected")

row("decor", "Demonic Decor", true)
row("stall", "Haunted Stall - Once Only", true)

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -8, 0, 65)
note.BackgroundTransparency = 1
note.TextWrapped = true
note.TextSize = 11
note.TextColor3 = Color3.fromRGB(200, 205, 215)
note.Text =
    "V6.8: Haunted Egg detection fixed. "
    .. "Decor and Stall remain disabled. "
    .. "Normal Cosmetics excluded."
note.Parent = scroller

-- Minimize / restore

minimize.MouseButton1Click:Connect(function()
    local expanded = scroller.Visible

    scroller.Visible = not expanded

    panel.Size = expanded
        and UDim2.fromOffset(290, 36)
        or UDim2.fromOffset(290, 355)
end)

-- Close

close.MouseButton1Click:Connect(function()
    alive = false
    gui:Destroy()
end)

-- Normal shops + Halloween shops

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

        task.wait(0.5)
    end
end)

-- Harvest loop

task.spawn(function()
    while alive and gui.Parent do
        if toggles.harvest then
            pcall(harvest)
        end

        task.wait(3)
    end
end)

-- Sell loop

task.spawn(function()
    while alive and gui.Parent do
        if toggles.sell then
            pcall(sell)
        end

        task.wait(10)
    end
end)

print("[GAG AUTO HUB V6.8] Loaded successfully")
