
-- GAG Auto Hub V7.1 | Delta Android
-- All automations start OFF.
-- Profile: set your uploaded Roblox image asset ID below.

local PROFILE_IMAGE_ASSET_ID = ""

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local events = RS:WaitForChild("GameEvents", 12)

if not events then
    warn("GAG Hub: GameEvents missing")
    return
end

local old = pg:FindFirstChild("GAG_AutoHub_V71")
if old then old:Destroy() end

local previous = getgenv and getgenv().GAG_V71
if previous then previous.alive = false end

local state = {
    alive = true,
    minimized = false,
    count = 0,
    capacity = 250,
    lastSell = 0,
    lastHarvest = 0,
    lastBuy = 0,
    lastNormal = 0,
    log = "Ready",
    switches = {}
}

if getgenv then
    getgenv().GAG_V71 = state
end

local function remote(path)
    local obj = events
    for part in path:gmatch("[^/]+") do
        obj = obj and obj:FindFirstChild(part)
    end
    return obj
end

local function fire(path, ...)
    local r = remote(path)
    if not r or not r:IsA("RemoteEvent") then
        return false
    end
    return pcall(r.FireServer, r, ...)
end

local function log(s)
    state.log = s
end

local function new(class, props, parent)
    local x = Instance.new(class)
    for k, v in pairs(props or {}) do
        x[k] = v
    end
    x.Parent = parent
    return x
end

local C = {
    bg = Color3.fromRGB(14, 12, 25),
    panel = Color3.fromRGB(28, 23, 43),
    tile = Color3.fromRGB(37, 29, 55),
    accent = Color3.fromRGB(166, 86, 255),
    white = Color3.fromRGB(244, 235, 255),
    muted = Color3.fromRGB(175, 162, 192),
    green = Color3.fromRGB(106, 241, 164)
}

local function corner(o, r)
    new("UICorner", {
        CornerRadius = UDim.new(0, r or 10)
    }, o)
end

local function stroke(o)
    new("UIStroke", {
        Color = C.accent,
        Thickness = 1,
        Transparency = 0.35
    }, o)
end

-- MAIN GUI

local gui = new("ScreenGui", {
    Name = "GAG_AutoHub_V71",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 900
}, pg)

local main = new("Frame", {
    Size = UDim2.fromOffset(332, 454),
    Position = UDim2.new(0.5, -166, 0.5, -227),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Active = true
}, gui)

corner(main, 15)
stroke(main)

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 66),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    Active = true
}, main)

corner(header, 15)

local avatarSource =
    PROFILE_IMAGE_ASSET_ID ~= ""
    and PROFILE_IMAGE_ASSET_ID
    or (
        "rbxthumb://type=AvatarHeadShot&id="
        .. player.UserId
        .. "&w=150&h=150"
    )

local function avatar(parent, sz, x, y)
    local a = new("ImageLabel", {
        Size = UDim2.fromOffset(sz, sz),
        Position = UDim2.fromOffset(x, y),
        BackgroundColor3 = C.tile,
        Image = avatarSource,
        ScaleType = Enum.ScaleType.Crop
    }, parent)

    new("UICorner", {
        CornerRadius = UDim.new(1, 0)
    }, a)

    stroke(a)
    return a
end

avatar(header, 45, 11, 10)

new("TextLabel", {
    Position = UDim2.fromOffset(64, 11),
    Size = UDim2.fromOffset(190, 22),
    BackgroundTransparency = 1,
    Text = "GAG AUTO HUB  V7.1",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

new("TextLabel", {
    Position = UDim2.fromOffset(64, 34),
    Size = UDim2.fromOffset(190, 18),
    BackgroundTransparency = 1,
    Text = "Grow a Garden | Halloween",
    TextColor3 = C.muted,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local function btn(parent, text, pos, size, color)
    local b = new("TextButton", {
        Position = pos,
        Size = size,
        BackgroundColor3 = color or C.tile,
        Text = text,
        TextColor3 = C.white,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        AutoButtonColor = true
    }, parent)

    corner(b, 8)
    return b
end

local min = btn(
    header,
    "-",
    UDim2.new(1, -70, 0, 15),
    UDim2.fromOffset(29, 29)
)

local exit = btn(
    header,
    "X",
    UDim2.new(1, -37, 0, 15),
    UDim2.fromOffset(29, 29),
    Color3.fromRGB(105, 42, 77)
)

-- MINIMIZED PROFILE BUTTON

local mini = new("ImageButton", {
    Size = UDim2.fromOffset(62, 62),
    Position = UDim2.new(1, -79, 0.65, 0),
    BackgroundColor3 = C.panel,
    Image = avatarSource,
    ScaleType = Enum.ScaleType.Crop,
    Visible = false,
    Active = true
}, gui)

new("UICorner", {
    CornerRadius = UDim.new(1, 0)
}, mini)

stroke(mini)

new("TextLabel", {
    Size = UDim2.fromOffset(23, 19),
    Position = UDim2.new(1, -16, 0, -4),
    Text = "V7",
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextColor3 = C.white,
    BackgroundColor3 = C.accent
}, mini)

-- TABS

local tabs = new("Frame", {
    Position = UDim2.fromOffset(9, 73),
    Size = UDim2.new(1, -18, 0, 36),
    BackgroundTransparency = 1
}, main)

local pages = {}
local tabButtons = {}

local tabNames = {
    "EVENT",
    "FARM",
    "SHOPS",
    "INFO"
}

for i, name in ipairs(tabNames) do
    tabButtons[name] = btn(
        tabs,
        name,
        UDim2.new((i - 1) / 4, 2, 0, 0),
        UDim2.new(0.25, -4, 1, 0),
        i == 1 and C.accent or C.tile
    )

    local sc = new("ScrollingFrame", {
        Position = UDim2.fromOffset(9, 116),
        Size = UDim2.new(1, -18, 1, -164),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = i == 1
    }, main)

    new("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, sc)

    pages[name] = sc
end

local function selectTab(name)
    for n, p in pairs(pages) do
        p.Visible = (n == name)
        tabButtons[n].BackgroundColor3 =
            n == name and C.accent or C.tile
    end
end

for name, b in pairs(tabButtons) do
    b.MouseButton1Click:Connect(function()
        selectTab(name)
    end)
end

local function section(page, text)
    return new("TextLabel", {
        Size = UDim2.new(1, -5, 0, 26),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.accent,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, pages[page])
end

local function toggle(page, key, text, desc)
    local box = new("Frame", {
        Size = UDim2.new(1, -5, 0, 55),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0
    }, pages[page])

    corner(box, 9)

    new("TextLabel", {
        Position = UDim2.fromOffset(10, 7),
        Size = UDim2.new(1, -84, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.white,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, box)

    new("TextLabel", {
        Position = UDim2.fromOffset(10, 29),
        Size = UDim2.new(1, -84, 0, 17),
        BackgroundTransparency = 1,
        Text = desc,
        TextColor3 = C.muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    }, box)

    local b = btn(
        box,
        "OFF",
        UDim2.new(1, -66, 0, 12),
        UDim2.fromOffset(55, 30)
    )

    state.switches[key] = false

    b.MouseButton1Click:Connect(function()
        state.switches[key] = not state.switches[key]

        b.Text = state.switches[key] and "ON" or "OFF"
        b.BackgroundColor3 =
            state.switches[key] and C.accent or C.tile
    end)
end

-- EVENT PAGE

section("EVENT", "HALLOWEEN EVENT")

toggle(
    "EVENT",
    "scary",
    "Auto Buy - Scary Seeds",
    "9 captured valid item names"
)

toggle(
    "EVENT",
    "fauna",
    "Auto Buy - Frightening Fauna",
    "Haunted Egg / Spooky Chest"
)

toggle(
    "EVENT",
    "decor",
    "Auto Buy - Demonic Decor",
    "3 captured decor items"
)

section("EVENT", "INVENTORY CONTROL")

toggle(
    "EVENT",
    "sell",
    "Sell Halloween When Full",
    "Only triggers at detected capacity"
)

local eventHint = new("TextLabel", {
    Size = UDim2.new(1, -5, 0, 49),
    BackgroundColor3 = C.panel,
    Text = "Sell remote affects Halloween plants only. Other fruit types may remain in inventory.",
    TextColor3 = C.muted,
    TextWrapped = true,
    TextSize = 11,
    Font = Enum.Font.Gotham
}, pages.EVENT)

corner(eventHint, 9)

-- FARM PAGE

section("FARM", "FARM AUTOMATION")

toggle(
    "FARM",
    "harvest",
    "Instant Collect Fruits",
    "Collect from your own farm"
)

toggle(
    "FARM",
    "farmSell",
    "Sell When Inventory Full",
    "Uses Halloween sell remote only"
)

local farmHint = new("TextLabel", {
    Size = UDim2.new(1, -5, 0, 60),
    BackgroundColor3 = C.panel,
    Text = "Harvest pauses at full inventory. Selling resumes harvesting only if the inventory count drops. The server decides which fruits are ready.",
    TextWrapped = true,
    TextColor3 = C.muted,
    TextSize = 11,
    Font = Enum.Font.Gotham
}, pages.FARM)

corner(farmHint, 9)

-- STANDARD SHOPS PAGE

section("SHOPS", "STANDARD SHOPS")

toggle(
    "SHOPS",
    "seeds",
    "Auto Buy Seeds",
    "Uses visible stock entries"
)

toggle(
    "SHOPS",
    "gear",
    "Auto Buy Gear",
    "Uses visible stock entries"
)

toggle(
    "SHOPS",
    "eggs",
    "Auto Buy Eggs",
    "Uses visible stock entries"
)

-- INFO PAGE

section("INFO", "ABOUT V7.1")

local info = new("TextLabel", {
    Size = UDim2.new(1, -5, 0, 190),
    BackgroundColor3 = C.panel,
    TextWrapped = true,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextColor3 = C.white,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    Text = [[
GAG AUTO HUB V7.1

- All toggles OFF by default
- 14 captured Halloween shop items
- Empty item names skipped
- Full-inventory harvest pause
- Halloween-only auto sell
- Minimize to circular profile icon

To use your own picture, set
PROFILE_IMAGE_ASSET_ID at the top.
]]
}, pages.INFO)

corner(info, 9)

-- FOOTER STATUS

local footer = new("Frame", {
    Position = UDim2.new(0, 9, 1, -41),
    Size = UDim2.new(1, -18, 0, 32),
    BackgroundColor3 = C.panel
}, main)

corner(footer, 8)

local status = new("TextLabel", {
    Position = UDim2.fromOffset(7, 0),
    Size = UDim2.new(1, -14, 1, 0),
    BackgroundTransparency = 1,
    Text = "Ready | Inventory: --/--",
    TextColor3 = C.green,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd
}, footer)

-- MOBILE DRAGGING

local function drag(target, handle)
    local active = false
    local start
    local initial
    local inputRef

    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
            or i.UserInputType == Enum.UserInputType.MouseButton1 then

            active = true
            start = i.Position
            initial = target.Position
            inputRef = i

            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    active = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(i)
        if i.UserInputType ==
            Enum.UserInputType.MouseMovement then
            inputRef = i
        end
    end)

    UIS.InputChanged:Connect(function(i)
        if active and (
            i == inputRef
            or i.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = i.Position - start

            target.Position = UDim2.new(
                initial.X.Scale,
                initial.X.Offset + d.X,
                initial.Y.Scale,
                initial.Y.Offset + d.Y
            )
        end
    end)
end

drag(main, header)
drag(mini, mini)

min.MouseButton1Click:Connect(function()
    main.Visible = false
    mini.Visible = true
    state.minimized = true
end)

mini.MouseButton1Click:Connect(function()
    main.Visible = true
    mini.Visible = false
    state.minimized = false
end)

exit.MouseButton1Click:Connect(function()
    state.alive = false
    gui:Destroy()
end)

-- CAPTURED HALLOWEEN ITEMS

local halloween = {
    ["Scary Seeds"] = {
        "Halloween Candy Corn Carrot",
        "Halloween Candy Cluster",
        "Halloween Witch's Broom",
        "Halloween Webberry",
        "Halloween Blood Kiwi",
        "Halloween Fang Root",
        "Halloween Haunted Hallow",
        "Halloween Pumpkin Lantern",
        "Haunted Sprinkler"
    },

    ["Frightening Fauna"] = {
        "Haunted Egg",
        "Spooky Chest"
    },

    ["Demonic Decor"] = {
        "Haunted Crate",
        "Haunted Well",
        "Spooky Crate"
    }
}

-- INVENTORY DETECTION

local function getCapacity()
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel")
            or obj:IsA("TextButton") then

            local t = obj.Text

            if type(t) == "string" then
                local a, b = t:match(
                    "Fruit%s*Items%s*%(%s*(%d+)%s*/%s*(%d+)%s*%)"
                )

                if a and b then
                    return tonumber(a), tonumber(b)
                end
            end
        end
    end

    return nil, nil
end

-- FARM DETECTION

local function ownFarm()
    local root = workspace:FindFirstChild("Farm")
    if not root then return nil end

    for _, farm in ipairs(root:GetChildren()) do
        local imp = farm:FindFirstChild("Important")
        local data = imp and imp:FindFirstChild("Data")
        local owner = data and data:FindFirstChild("Owner")

        if owner
            and owner:IsA("StringValue")
            and owner.Value == player.Name then

            return farm
        end
    end
end

-- INSTANT HARVEST

local function collectFruit()
    local farm = ownFarm()

    if not farm then
        log("Your farm not found")
        return
    end

    local imp = farm:FindFirstChild("Important")
    local plants = imp and imp:FindFirstChild("Plants_Physical")

    if not plants then return end

    local collect = remote("Crops/Collect")

    if not collect then
        log("Collect remote unavailable")
        return
    end

    local batch = {}
    local batches = 0

    for _, plant in ipairs(plants:GetChildren()) do
        if not state.alive
            or not state.switches.harvest then
            return
        end

        local fruits = plant:FindFirstChild("Fruits")

        if fruits then
            for _, fruit in ipairs(fruits:GetChildren()) do
                if fruit:IsA("Model") then
                    batch[#batch + 1] = fruit

                    if #batch >= 20 then
                        pcall(
                            collect.FireServer,
                            collect,
                            batch
                        )

                        batches += 1
                        batch = {}

                        task.wait(0.2)

                        if batches >= 5 then
                            log(
                                "Harvest: sent "
                                .. (batches * 20)
                                .. " fruit refs"
                            )
                            return
                        end
                    end
                end
            end
        end
    end

    if #batch > 0 then
        pcall(collect.FireServer, collect, batch)
    end

    log("Harvest checked your farm")
end

-- NORMAL SHOP HELPERS

local function stockAvailable(stock)
    if not stock then return false end

    local text = tostring(stock.Text or "")
    local number = text:match("(%d+)")

    return number ~= nil
        and tonumber(number) > 0
end

local function normalShop(kind)
    local rootName =
        kind == "seeds" and "Seed_Shop"
        or (
            kind == "gear"
            and "Gear_Shop"
            or "PetEggShop"
        )

    local root = pg:FindFirstChild(rootName)

    if not root then return end

    local calls = 0

    for _, obj in ipairs(root:GetDescendants()) do
        if obj.Name == "Stock_Text"
            and obj:IsA("TextLabel")
            and stockAvailable(obj) then

            local itemFrame =
                obj.Parent and obj.Parent.Parent

            local name = itemFrame and itemFrame.Name

            if name
                and name ~= ""
                and name ~= "ScrollingFrame"
                and name ~= "Main_Frame" then

                local ok = false

                if kind == "seeds" then
                    ok = fire(
                        "BuySeedStock",
                        "Shop",
                        name
                    )

                elseif kind == "gear" then
                    ok = fire(
                        "BuyGearStock",
                        name
                    )

                else
                    ok = fire(
                        "BuyPetEgg",
                        name
                    )
                end

                if ok then
                    calls += 1
                end
            end

            if calls >= 10 then
                break
            end
        end
    end

    if calls > 0 then
        log(
            "Shop " .. kind
            .. ": " .. calls
            .. " requests"
        )
    end
end

-- HALLOWEEN AUTO BUY

local function buyHalloween()
    local keyByCategory = {
        ["Scary Seeds"] = "scary",
        ["Frightening Fauna"] = "fauna",
        ["Demonic Decor"] = "decor"
    }

    local count = 0

    for category, items in pairs(halloween) do
        local key = keyByCategory[category]

        if state.switches[key] then
            for _, item in ipairs(items) do
                if not state.alive
                    or not state.switches[key] then
                    break
                end

                -- Never send empty item names
                if item ~= "" then
                    if fire(
                        "BuyEventShopStock",
                        item,
                        category
                    ) then
                        count += 1
                    end

                    task.wait(0.16)
                end
            end
        end
    end

    if count > 0 then
        log(
            "Halloween: "
            .. count
            .. " requests sent"
        )
    end
end

-- AUTO SELL ONLY WHEN FULL

local function sellIfFull(now)
    if not (
        state.switches.sell
        or state.switches.farmSell
    ) then
        return
    end

    if state.count <= 0
        or state.capacity <= 0
        or state.count < state.capacity then
        return
    end

    if now - state.lastSell < 12 then
        return
    end

    state.lastSell = now

    if fire(
        "Events/Halloween2026Event/HalloweenSellInventoryRE"
    ) then
        log("Inventory full: Halloween sell requested")
    else
        log("Halloween sell remote unavailable")
    end
end

-- AUTOMATION LOOP

task.spawn(function()
    while state.alive and gui.Parent do
        local now = os.clock()

        local count, cap = getCapacity()

        if count and cap then
            state.count = count
            state.capacity = cap
        end

        local full =
            count and cap
            and cap > 0
            and count >= cap

        -- Harvest every 2.5 seconds
        if now - state.lastHarvest >= 2.5 then
            state.lastHarvest = now

            if state.switches.harvest
                and not full then
                collectFruit()
            end
        end

        -- Sell when inventory reaches limit
        sellIfFull(now)

        -- Halloween purchases every 15 seconds
        if now - state.lastBuy >= 15 then
            state.lastBuy = now

            if state.switches.scary
                or state.switches.fauna
                or state.switches.decor then
                buyHalloween()
            end
        end

        -- Standard shops every 15 seconds
        if now - state.lastNormal >= 15 then
            state.lastNormal = now

            for _, kind in ipairs({
                "seeds",
                "gear",
                "eggs"
            }) do
                if state.switches[kind] then
                    normalShop(kind)
                end
            end
        end

        status.Text = string.format(
            "%s | Fruit: %s/%s",
            state.log,
            count or "?",
            cap or "?"
        )

        task.wait(1)
    end
end)

log("Hub loaded - toggles OFF")
