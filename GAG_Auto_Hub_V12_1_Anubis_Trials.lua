
-- GAG Auto Hub V12.3 | Anubis Ancient Trials | Delta Android / Xeno
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

local previous = nil
pcall(function()
    if type(getgenv)=="function" then
        local env=getgenv()
        previous=env.GAG_V123 or env.GAG_V122 or env.GAG_V121 or env.GAG_V12 or env.GAG_V71
    end
end)
if previous then
    previous.alive=false
    for _,conn in ipairs(previous.connections or {}) do
        pcall(function() conn:Disconnect() end)
    end
    for _,fn in ipairs(previous.cleanupCallbacks or {}) do pcall(fn) end
end
for _,name in ipairs({"GAG_AutoHub_V123","GAG_AutoHub_V122","GAG_AutoHub_V121","GAG_AutoHub_V12","GAG_AutoHub_V71"}) do
    local old=pg:FindFirstChild(name)
    if old then old:Destroy() end
end

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
    category = nil,
    legacyCategory = nil,
    eventMode = "No event detected",
    trial = {
        active=false, category=nil, lastObservedCategory=nil, points=nil,
        timer=nil, source="none", pointsSource="none",
        rawText="(not detected)", rawProgress="(not detected)", collectionStatus="PAUSED"
    },
    nextTrialCheck = 0,
    locatorReport = "Not scanned yet",
    favoriteReport = "Not tested yet",
    cleanupCallbacks = {},
    stage = nil,
    requirement = nil,
    progress = nil,
    eventLog = {},
    connections = {},
    lastEventCollect = 0,
    lastEventSubmit = 0,
    switches = {}
}

pcall(function()
    if type(getgenv)=="function" then
        getgenv().GAG_V123=state
        getgenv().GAG_V12=state
    end
end)

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
    Name = "GAG_AutoHub_V123",
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
    Text = "GAG AUTO HUB V12.3",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

new("TextLabel", {
    Position = UDim2.fromOffset(64, 34),
    Size = UDim2.fromOffset(190, 18),
    BackgroundTransparency = 1,
    Text = "Anubis | Pharaoh Ancient Trials",
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
    Text = "V12.3",
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
section("EVENT", "ANUBIS / ANCIENT TRIALS")
local eventInfo = new("TextLabel", {
    Size = UDim2.new(1,-5,0,100), BackgroundColor3=C.panel,
    Text = "Waiting for Anubis request...", TextWrapped=true,
    TextColor3=C.white, Font=Enum.Font.Gotham, TextSize=12
}, pages.EVENT)
corner(eventInfo,9)
toggle("EVENT", "eventCollect", "Collect Matching Fruits", "OFF by default - harvest only, no offerings")
section("EVENT", "AUTO SUBMIT: LOCKED (UNVERIFIED FAVORITES)")
local eventHint = new("TextLabel", {
    Size=UDim2.new(1,-5,0,75), BackgroundColor3=C.panel,
    Text="Pharaoh trial category, 900-point gate and countdown are observed automatically. Manual Collect Matching uses exact crop-category hints. Auto Submit is disabled to protect your inventory.",
    TextColor3=C.muted,TextWrapped=true,TextSize=11,Font=Enum.Font.Gotham
},pages.EVENT)
corner(eventHint,9)
local copyEvent = btn(pages.EVENT,"COPY RESULTS",UDim2.fromOffset(0,0),UDim2.new(1,-5,0,35))
copyEvent.Position=UDim2.fromOffset(0,0)
copyEvent.MouseButton1Click:Connect(function()
    local tr=state.trial
    local lines={
        "GAG AUTO HUB V12.3 ANUBIS / ANCIENT TRIALS",
        "EventMode="..tostring(state.eventMode),
        "Category="..tostring(state.category),
        "DisplayedRequest="..tostring(tr.category),
        "Gate="..tostring(tr.points).."/900",
        "RotationCountdown="..tostring(tr.timer),
        "RawTraitText="..tostring(tr.rawText),
        "RawProgressText="..tostring(tr.rawProgress),
        "LastObservedCategory="..tostring(tr.lastObservedCategory),
        "CollectionStatus="..tostring(tr.collectionStatus),
        "TraitSource="..tostring(tr.source),
        "PointsSource="..tostring(tr.pointsSource),
        "LegacyStage="..tostring(state.stage),
        "LegacyProgress="..tostring(state.progress),
        "LegacyRequired="..tostring(state.requirement),
        "AutoSubmit=LOCKED",
        "Locator="..tostring(state.locatorReport),
        "FavoriteComparison="..tostring(state.favoriteReport),
        "--- Event log ---"
    }
    for _,v in ipairs(state.eventLog) do lines[#lines+1]=v end
    local result=table.concat(lines,"\n")
    local copier=type(setclipboard)=="function" and setclipboard
        or (type(toclipboard)=="function" and toclipboard or nil)
    if copier then
        local ok=pcall(copier,result)
        log(ok and "Event report copied" or "Clipboard failed")
    else log("Clipboard unsupported; report printed to console") end
    print(result)
end)

-- Garden fruit locator and favorite comparison (read-only tools).
section("EVENT", "FIND FRUITS / FAVORITE TEST")
local locatorText = new("TextLabel", {
    Size=UDim2.new(1,-5,0,49), BackgroundColor3=C.panel,
    Text="LOCATOR: Search your farm for nearby fruit models.",
    TextColor3=C.white, TextWrapped=true, Font=Enum.Font.Gotham, TextSize=11
},pages.EVENT)
corner(locatorText,8)
local locateBtn=btn(pages.EVENT,"FIND FRUITS",UDim2.fromOffset(0,0),UDim2.new(1,-5,0,34))
local nextBtn=btn(pages.EVENT,"NEXT FRUIT",UDim2.fromOffset(0,0),UDim2.new(1,-5,0,34))
local clearBtn=btn(pages.EVENT,"CLEAR HIGHLIGHT",UDim2.fromOffset(0,0),UDim2.new(1,-5,0,34))
local snapBtn=btn(pages.EVENT,"SNAP A (EQUIPPED FRUIT)",UDim2.fromOffset(0,0),UDim2.new(1,-5,0,34))
local compareBtn=btn(pages.EVENT,"COMPARE B (AFTER FAVORITING)",UDim2.fromOffset(0,0),UDim2.new(1,-5,0,34))

-- FARM PAGE

section("FARM", "FARM AUTOMATION")

toggle(
    "FARM",
    "harvest",
    "Instant Collect Fruits",
    "Collect from your own farm"
)

-- Halloween-only sell removed; standard FARM harvest remains available

local farmHint = new("TextLabel", {
    Size = UDim2.new(1, -5, 0, 60),
    BackgroundColor3 = C.panel,
    Text = "Harvest pauses at full inventory. Selling resumes harvesting only if the inventory count drops. The server decides which fruits are ready. FARM harvest is not category-filtered; leave it OFF when using Anubis-only collection.",
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

section("INFO", "ABOUT V12.3")

local info = new("TextLabel", {
    Size = UDim2.new(1, -5, 0, 190),
    BackgroundColor3 = C.panel,
    TextWrapped = true,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextColor3 = C.white,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    Text = [[
GAG AUTO HUB V12.3

- Original V12 Farm/Shop features retained
- New Pharaoh Ancient Trials observer
- Live requested crop, points and countdown
- Matching-fruit collection from owned farm
- Auto submit LOCKED pending safety tests
- Fruit locator and favorite A/B checker
- All automation toggles OFF by default
- Minimize, Copy Results and Close X

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

    local moved=UIS.InputChanged:Connect(function(i)
        if not state.alive then return end
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
    table.insert(state.connections,moved)
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
    state.alive=false
    for _,fn in ipairs(state.cleanupCallbacks) do pcall(fn) end
    for _,conn in ipairs(state.connections) do
        pcall(function() conn:Disconnect() end)
    end
    pcall(function() gui:Destroy() end)
    pcall(function()
        if type(getgenv)=="function" then
            local env=getgenv()
            if env.GAG_V123==state then env.GAG_V123=nil end
            if env.GAG_V12==state then env.GAG_V12=nil end
        end
    end)
end)

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

-- ANUBIS CATEGORY OBSERVER AND SAFE EVENT AUTOMATION
local categories = {"Berry","Sour","Sweet","Spicy","Stalky","Leafy","Root","Fruit","Flower","Tropical","Woody","Prickly","Vegetable","Citrus","Nightshade","Fungus"}
local function normalizeCrop(raw)
    return tostring(raw or ""):lower():gsub("%b[]","")
        :gsub("[^%w]+"," "):gsub("^%s+",""):gsub("%s+$","")
end
local cropLists = {
    Berry = [[Astrobush|Banesberry|Blue Raspberry|Blueberry|Bunny Berry|Celestiberry|Chocolate Berry|Cranberry|Crimson Cranberry|Elder Strawberry|Evo Blueberry|Fall Berry|Fissure Berry|Gift Berry|Glacial Petal|Grape|Grape Droplet|Hearth Reed|Hexberry|Holly Berry|Jelly Bean Sprout|Lingonberry|Mandrone Berry|Persimmon|Pollenvine|Pomegranate|Pyracantha|Raspberry|Royal Jelly Cup|Speargrass|Strawberry|Sunbulb|Viburnum Berry|Vio Puff|White Mulberry|Willowberry]],
    Root = [[Auburn Pine|Aurora Vine|Bumble Bulb|Candy Carrot|Carrot|Chocolate Carrot|Egg Shroom|Evo Beetroot|Firefly Spiral|Ghoul Root|Honey Hollow|Horsetail|Mandrake|Mangrove|Marshmallow Root|Mummy's Hand|Mutant Carrot|Obby Oddvine|Octobloom|Onion|Potato|Radish|Reindeer Root|Rhubarb|Shadow Spine|Smoke Stalk|Spring Onion|Tall Asparagus|Taro Flower|Trinity Fruit|Turnip|Wild Carrot]],
    Tropical = [[Ackee|Aqua Lily|Banana|Birds of Paradise|Coconut|Cocovine|Dragon Fruit|Durian|Firefly Spiral|Fissure Berry|Honey Dew|Mango|Orange Delight|Papaya|Parasol Flower|Passionfruit|Persimmon|Pineapple|Pinkfruit Palm|Pomegranate|Starfruit|Sugarcane|Watermelon|Wild Frond]],
    Woody = [[Acorn|Aetherfruit|Amberfruit Shrub|Amberheart|Antlerbloom|Apple|Auburn Pine|Aurora Vine|Avocado|Bamboo|Bamboo Tree|Baobab|Basket Bouquet|Bendbark|Bendboo|Boneboo|Cacao|Castor Bean|Cherry|Chocolate Coconut|Christmas Tree|Cocomango|Coconut|Cocovine|Crimson Cranberry|Dragon Sapling|Durian|Duskpuff|Evo Apple|Fall Berry|Feijoa|Firewell|Frostspike|Giant Pinecone|Gift Berry|Gleamroot|Glowpod|Hazelnut|Hive Fruit|Honey Dipper|Honey Hollow|Jungle Cherry|Kiwi|Lucky Bamboo|Madcrown Vine|Mahogany|Mango|Mangosteen|Mangrove|Maple Apple|Maple Resin|Marshmallow Root|Moon Blossom|Moon Mango|Naval Wort|Nectarine|Papaya|Peach|Pear|Pecan|Plumwillow|Pohutukawa|Poison Apple|Purple Treeshroom|Reindeer Root|Rhubarb|Severed Spine|Shadow Spine|Speargrass|Spiked Mango|Sugar Apple|Traveler's Fruit|Trinity Fruit|Waddling Willow|Walnut|Weeping Branch|Willowberry|Wintercreep|Woodbine]],
    Sour = [[Blood Orange|Buddhas Hand|Cocomango|Cranberry|Crimson Cranberry|Fissure Berry|Flare Melon|Golden Peach|Hexberry|Horned Melon|Jungle Cherry|Kiwi|Lemon|Lime|Mangosteen|Meyer Lemon|Passionfruit|Pinkfruit Palm|Poison Apple|Pollenvine|Pomegranate|Severed Spine|Shadow Spine|Sour Lemon|Speargrass|Starfruit|Sunbulb|Wild Pineapple]],
    Sweet = [[Banana|Bee Bell|Bendbark|Blue Lollipop|Blue Raspberry|Blueberry|Buddhas Hand|Bunny Berry|Canary Melon|Candlite|Candy Blossom|Candy Blossom 2026|Candy Cornflower|Candy Sunflower|Carnival Pumpkin|Cherry|Chicken Feed|Chocolate Carrot|Cocoa Pod|Cocomango|Confetti Tula|Cookie Stack|Crimson Cranberry|Crown Melon|DJ Delight|Easter Egg|Egg Melon|Egg Shroom|Elder Candy Blossom|Evo Blueberry|Evo Pumpkin|Faestar|Fall Berry|Golden Peach|Grape|Grape Droplet|Honey Dew|Honey Dipper|Honey Hollow|Jelly Bean Sprout|Jungle Cherry|Madras Thorn|Mango|Mangosteen|Marshmallow Root|Monarch Jellpod|Moon Melon|Nectar Thorn|Peach|Pear|Peppermint Vine|Persimmon|Pineapple|Pixie Faern|Plumwillow|Poison Apple|Pomegranate|Raspberry|Red Lollipop|Romanesco|Sparkle Slice|Spiked Mango|Starfruit|Strawberry|Sugar Apple|Sugar Melon|Sugar Snapdragon|Sugarcane|Sugarglaze|Sun Bloom|Trinity Fruit|Untold Bell|Waddling Willow|Watermelon|Zucchini]],
    Stalky = [[Bamboo|Bamboo Tree|Beanstalk|Bendboo|Birds of Paradise|Blooming Cactus|Boneboo|Brussels Sprout|Bumble Bulb|Burning Bud|Candy Cornflower|Chicken Feed|Corn|Crimson Thorn|Dandelion|Eggsnapper|Elephant Ears|Firefly Fern|Firefly Spiral|Firework Fern|Flare Melon|Hearth Reed|Jelly Bean Sprout|Lucky Bamboo|Mushroom|Papyrus|Parsley|Pitcher Plant|Pollenvine|Pricklefruit|Reindeer Root|Shadow Spine|Smoke Stalk|Spring Onion|Sugarcane|Sunflower|Sweetheart Flower|Tall Asparagus|Violet Corn|Waddling Willow|Zebrazinkle|Zucchini]],
    Leafy = [[Apple|Aloe Vera|Bamboo Tree|Beanstalk|Blueberry|Cacao|Celestiberry|Cocomango|Cranberry|Crimson Cranberry|Eggplant|Evo Blueberry|Fall Berry|Firefly Spiral|Geode Root|Giant Pinecone|Gift Berry|Grape|Grape Droplet|Holly Berry|Mangosteen|Mango|Mint|Moon Blossom|Parasol Flower|Peach|Pineapple|Poison Apple|Pomegranate|Pumpkin|Raspberry|Rose|Speargrass|Starfruit|Strawberry|Sugar Apple|Sugarcane|Sunflower|Tomato|Traveler's Fruit|Watermelon|Willowberry]],
    Vegetable = [[Carrot|Corn|Potato|Radish|Tomato|Pepper|Bell Pepper|Pumpkin|Onion|Eggplant|Zucchini|Cauliflower|Broccoli|Cabbage|Brussels Sprout|Romanesco|Tall Asparagus|Grand Tomato|Ghost Pepper|Jalapeno|Evo Beetroot|Evo Pumpkin|Turnip|Rhubarb|Dragon Pepper|Pollenvine]],
    Prickly = [[Aloe Vera|Bendbark|Blooming Cactus|Cactus|Celestiberry|Crimson Thorn|Crown Of Thorns|Dragon Fruit|Prickly Pear|Pricklefruit|Shadow Spine|Swivel Stinger|Venus Fly Trap|Pollenvine]],
    Flower = [[Ambercomb|Bee Balm|Bee Bell|Birds of Paradise|Bone Blossom|Broccoli|Buttercup|Calla Lily|Candy Blossom|Cherry Blossom|Coneflower|Daffodil|Daisy|Dandelion|Elder Candy Blossom|Ember Lily|Firefly Spiral|Firework Flower|Moon Blossom|Parasol Flower|Rose|Spirit Flower|Sunflower|Sweetheart Flower|Taro Flower|Wild Pineapple|Zucchini]],
    Fruit = [[Ackee|Apple|Avocado|Banana|Blue Raspberry|Blueberry|Carrot|Celestiberry|Cherry|Coconut|Corn|Cranberry|Dragon Fruit|Durian|Elder Strawberry|Evo Blueberry|Fall Berry|Grape|Kiwi|Lemon|Lime|Mango|Melon|Papaya|Passionfruit|Peach|Pear|Pineapple|Pomegranate|Pumpkin|Raspberry|Starfruit|Strawberry|Sugar Apple|Tomato|Watermelon|Zombie Fruit]],
}

local knownCrops={}
for cat,names in pairs(cropLists) do
    for n in names:gmatch("[^|]+") do
        local key=normalizeCrop(n)
        knownCrops[key]=knownCrops[key] or {}
        knownCrops[key][cat]=true
    end
end

local berryNames = {strawberry=true,blueberry=true,raspberry=true,blackberry=true,cranberry=true,elderberry=true,gojiberry=true}
local function eventLog(message)
    local line=os.date("!%H:%M:%S",os.time()+8*3600).." "..message
    state.eventLog[#state.eventLog+1]=line
    if #state.eventLog>65 then table.remove(state.eventLog,1) end
    log(message)
end
local function learnCategory(t)
    if type(t)~="string" then return end
    local lower=t:lower()
    local found
    for _,cat in ipairs(categories) do
        local c=cat:lower()
        if lower:find("submitted %d+ "..c.." plants") or
           lower:find("submit "..c.." plants",1,true) or
           lower:find("requires "..c.." plants",1,true) or
           lower:find("needs "..c.." plants",1,true) then found=cat;break end
    end
    if found and found~=state.category then
        state.legacyCategory=found
        if not state.trial.active then
            state.category=found
            state.eventMode="Legacy Anubis"
        end
        eventLog("Legacy Anubis requests "..found.." plants")
    end
    local p,r=t:match("%(([%d%.]+)kg/([%d%.]+)kg%)")
    if p and r then state.progress=tonumber(p);state.requirement=tonumber(r) end
end
local function observeGuiText(o)
    if not (o:IsA("TextLabel") or o:IsA("TextButton")) then return end
    local function update()
        if not state.alive then return end
        local txt=o.Text
        if txt and (txt:lower():find("anubis",1,true) or txt:lower():find("plants",1,true) or txt:lower():find("submitted",1,true)) then learnCategory(txt) end
    end
    update()
    state.connections[#state.connections+1]=o:GetPropertyChangedSignal("Text"):Connect(update)
end
for _,o in ipairs(pg:GetDescendants()) do observeGuiText(o) end
state.connections[#state.connections+1]=pg.DescendantAdded:Connect(observeGuiText)
local anubisResult=remote("Events/AnubisEvent/AncientArc/SubmitResult")
if anubisResult and anubisResult:IsA("RemoteEvent") then
    state.connections[#state.connections+1]=anubisResult.OnClientEvent:Connect(function(data)
        if not state.alive or type(data)~="table" then return end
        if type(data.Stage)=="number" then state.stage=data.Stage end
        if type(data.Required)=="number" then state.requirement=data.Required end
        if data.Reason=="Uncovered" then state.progress=state.requirement end
        eventLog("Submit result: "..tostring(data.Reason).." | Stage "..tostring(data.Stage).." | Added "..tostring(data.Added))
    end)
end
-- This is an exact crop classification hint, NOT a verified server category.
-- If a crop isn't listed and has no explicit category metadata, never collect it.
local function matchesRequestedCategory(plant,fruit,requested)
    if not requested then return false end
    for _,obj in ipairs({plant,fruit}) do
        for _,key in ipairs({"PlantType","Category","FruitType","CropType"}) do
            local v=obj:GetAttribute(key)
            if type(v)=="string" and v:lower()==requested:lower() then
                return true
            end
        end
    end
    local key=normalizeCrop(plant.Name):gsub(" plant$",""):gsub(" crop$","")
    if knownCrops[key] then return knownCrops[key][requested]==true end
    if requested=="Berry" and berryNames[key:gsub("%s+","")] then return true end
    return false
end

local function eventCollect()
    if not state.category then return end
    -- Never collect against an absent or completed Pharaoh objective.
    -- Any unknown gate state must also fail closed.
    if state.trial.active and (
        state.trial.category ~= state.category
        or state.trial.points == nil
        or state.trial.points >= 900
    ) then return end
    local farm=ownFarm()
    local plants=farm and farm:FindFirstChild("Important")
    plants=plants and plants:FindFirstChild("Plants_Physical")
    local collect=remote("Crops/Collect")
    if not plants or not collect or not collect:IsA("RemoteEvent") then return end
    local batch={}
    for _,plant in ipairs(plants:GetChildren()) do
        local fruits=plant:FindFirstChild("Fruits")
        if fruits then
            for _,fruit in ipairs(fruits:GetChildren()) do
                if fruit:IsA("Model") and matchesRequestedCategory(plant,fruit,state.category) then
                    batch[#batch+1]=fruit
                    if #batch>=20 then break end
                end
            end
        end
        if #batch>=20 then break end
    end
    if #batch>0 then
        local ok=pcall(collect.FireServer,collect,batch)
        if ok then eventLog("Collected request sent: "..#batch.." "..state.category.." fruit refs") end
    end
end
local function safeSubmit()
    if not state.category then return end
    -- No server-side inventory-category API is available in the supplied script.
    -- Never fire Submit("All") blindly: it could consume unrelated crops.
    -- Locate a visible native Anubis button, but require explicit confirmation
    -- of its semantics before activating it automatically.
    if not state.submitVerified then
        state.switches.eventSubmit=false
        eventLog("Auto Submit paused: game UI submit action not verified")
        return
    end
end

-- CURRENT ANCIENT TRIALS EVENT SUPPORT.
-- These paths are grounded in previously copied, live V9.5.3 reports.
local function byPath(root,...)
    local obj=root
    for _,part in ipairs({...}) do obj=obj and obj:FindFirstChild(part) end
    return obj
end
local function readAncientTrials()
    local important=byPath(workspace,"Interaction","AncientTrialsModel","Important")
    local board=important and important:FindFirstChild("ProgressBoard")
    local text=byPath(important,"TrialNPC","AncientTrailsBillboard",
        "BubbleBillboard","BG","TextLabel")
    local progress=byPath(board,"ProgressBillboard","UpgradeBar","ProgressionLabel")
    local fullRaw=text and tostring(text.Text or "") or ""
    -- Roblox RichText uses nested <b>/<font> tags around category names.
    -- Strip markup before parsing, but retain the raw string for diagnostics.
    local function plainRequest(value)
        return tostring(value or ""):gsub("<[^>]+>", "")
            :gsub("&nbsp;", " "):gsub("%s+", " "):lower()
    end
    local raw=plainRequest(fullRaw)
    local wanted=raw:match("looking%s+for%s+([%a]+)%s+plants")
    local requested
    for _,cat in ipairs(categories) do
        if wanted and cat:lower()==wanted then requested=cat;break end
    end
    -- Some billboard variants separate 'Looking for', category, and
    -- 'plants' into multiple TextLabels. Don't inspect our own UI.
    local npc=important and important:FindFirstChild("TrialNPC")
    local billboard=npc and npc:FindFirstChild("AncientTrailsBillboard")
    if not requested and billboard then
        local tokens={}
        for _,obj in ipairs(billboard:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local str=tostring(obj.Text or "")
                if str~="" then table.insert(tokens,str) end
            end
        end
        local combined=plainRequest(table.concat(tokens," "))
        wanted=combined:match("looking%s+for%s+([%a]+)%s+plants")
        for _,cat in ipairs(categories) do
            if wanted and cat:lower()==wanted then requested=cat;break end
        end
    end
    local points
    local progressRaw=progress and tostring(progress.Text or "") or ""
    local a,b=progressRaw:match("(%d[%d,]*)%s*/%s*(%d[%d,]*)")
    if a and b and tonumber((b:gsub(",","")))==900 then
        points=tonumber((a:gsub(",","")))
    end
    local timer
    if billboard then
        for _,obj in ipairs(billboard:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local clock=tostring(obj.Text or ""):match("^%s*(%d?%d:%d%d)%s*$")
                if clock then timer=clock;break end
            end
        end
    end
    local hadTrialUI=state.trial.active
    local before=state.trial.category
    local modeBefore=state.eventMode
    local trialVisible=important~=nil and (text~=nil or progress~=nil)
    state.trial.active=trialVisible
    state.trial.category=requested
    if requested then state.trial.lastObservedCategory=requested end
    state.trial.points=points
    state.trial.timer=timer
    state.trial.source=text and text:GetFullName() or "none"
    state.trial.pointsSource=progress and progress:GetFullName() or "none"
    state.trial.rawText=fullRaw:gsub("[\r\n]+"," "):sub(1,160)
    state.trial.rawProgress=progressRaw:sub(1,70)
    if trialVisible then
        -- A full gate may hide/replace the category text; don't call
        -- the event absent or reuse the previous category to collect.
        if points~=nil and points>=900 then
            -- Display the actual requested category, even though harvesting
            -- must remain paused for a completed entrance gate.
            state.category=requested
            state.eventMode="Pharaoh AncientTrials - GATE FULL"
            state.trial.collectionStatus="PAUSED: gate at 900/900"
        elseif requested then
            state.category=requested
            state.eventMode="Pharaoh AncientTrials - request active"
            state.trial.collectionStatus=(points~=nil)
                and "AVAILABLE: toggle required to collect" or "PAUSED: points unavailable"
        else
            state.category=nil
            state.eventMode="Pharaoh AncientTrials - request not shown"
            state.trial.collectionStatus="PAUSED: category not detected"
        end
        if requested and before~=requested then
            eventLog((before and "PHARAOH CATEGORY CHANGE: " or "PHARAOH CATEGORY: ")
                .. (before and (before.." -> ") or "")..requested)
        end
        if modeBefore~=state.eventMode then
            eventLog("TRIAL STATUS: "..state.eventMode)
        end
    else
        state.category=state.legacyCategory
        state.eventMode=state.legacyCategory and "Legacy Anubis" or "No event detected"
        state.trial.collectionStatus="PAUSED: no Pharaoh UI"
        if hadTrialUI then eventLog("Pharaoh trial UI unavailable; switching to legacy observer") end
    end
end
for _,remoteName in ipairs({
    "TrialsSync","TrialsSubmitted","TrialsClaimed","TrialsTeleported","TrialsRewards"
}) do
    local event=remote("Events/AnubisEvent/AncientTrials/"..remoteName)
    if event and event:IsA("RemoteEvent") then
        table.insert(state.connections,event.OnClientEvent:Connect(function(...)
            if not state.alive then return end
            eventLog("PASSIVE "..remoteName.." args="..select("#",...).." (no call sent)")
            state.nextTrialCheck=0
        end))
    end
end

-- On-demand fruit locator using the OWN FARM structure from the original V12.
-- Does not harvest, move the character, or make network requests.
local fruitCandidates, fruitIndex = {},0
local marker, markerGui = nil,nil
local function clearMarker()
    if marker then pcall(function() marker:Destroy() end) end
    if markerGui then pcall(function() markerGui:Destroy() end) end
    marker,markerGui=nil,nil
end
local function clearLocator()
    fruitCandidates,fruitIndex={},0
    clearMarker()
    state.locatorReport="Cleared"
    locatorText.Text="LOCATOR: cleared"
end
table.insert(state.cleanupCallbacks,clearLocator)
local function fruitPivot(o)
    local ok,cf=pcall(function() return o:GetPivot() end)
    if ok then return cf.Position end
    return nil
end
local function selectLocator(i)
    clearMarker()
    if #fruitCandidates==0 then
        locatorText.Text="LOCATOR: No fruit candidates. Use FIND."
        return
    end
    fruitIndex=((i-1)%#fruitCandidates)+1
    local entry=fruitCandidates[fruitIndex]
    if not entry.fruit.Parent then
        locatorText.Text="LOCATOR: Fruit moved/unloaded. Scan again."
        return
    end
    local h=Instance.new("Highlight")
    h.Name="V123FruitLocator"
    h.FillColor=Color3.fromRGB(244,196,59)
    h.OutlineColor=Color3.fromRGB(255,235,147)
    h.FillTransparency=0.7
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee=entry.fruit
    h.Parent=workspace.CurrentCamera or workspace
    marker=h
    local part=entry.fruit:FindFirstChildWhichIsA("BasePart",true)
    if part then
        local b=Instance.new("BillboardGui")
        b.Name="V123FruitName"
        b.Adornee=part
        b.AlwaysOnTop=true
        b.Size=UDim2.fromOffset(200,45)
        b.StudsOffsetWorldSpace=Vector3.new(0,3,0)
        local t=new("TextLabel",{
            Size=UDim2.fromScale(1,1),
            BackgroundColor3=C.panel,TextColor3=C.white,
            TextWrapped=true,TextSize=12,Font=Enum.Font.GothamBold,
            Text=entry.name.." | "..entry.distance.." studs"
        },b)
        b.Parent=gui
        markerGui=b
    end
    locatorText.Text=string.format("LOCATOR: %d/%d %s (%d studs)",
        fruitIndex,#fruitCandidates,entry.name,entry.distance)
    state.locatorReport=string.format("Found=%d Selected=%d Crop=%s Distance=%d studs Path=%s. "
        .."Candidate only: ownership verified by farm, maturity unverified.",
        #fruitCandidates,fruitIndex,entry.name,entry.distance,entry.fruit:GetFullName())
end
local function scanOwnFruits()
    clearLocator()
    local farm=ownFarm()
    local plants=byPath(farm,"Important","Plants_Physical")
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not plants or not root then
        locatorText.Text="LOCATOR: Farm/character not found."
        state.locatorReport="Farm/character not found"
        return
    end
    local matches={}
    for i,plant in ipairs(plants:GetChildren()) do
        local fruits=plant:FindFirstChild("Fruits")
        if fruits then
            for _,fruit in ipairs(fruits:GetChildren()) do
                if fruit:IsA("Model") then
                    local pos=fruitPivot(fruit)
                    local dist=pos and (pos-root.Position).Magnitude or 999999
                    if dist<=220 then
                        local eligible=matchesRequestedCategory(plant,fruit,state.category)
                        table.insert(matches,{
                            fruit=fruit,name=plant.Name,
                            distance=math.floor(dist+0.5),match=eligible
                        })
                    end
                end
            end
        end
        if i%120==0 then task.wait() end
        if not state.alive then return end
    end
    table.sort(matches,function(a,b)
        if a.match~=b.match then return a.match end
        return a.distance<b.distance
    end)
    for i=1,math.min(80,#matches) do fruitCandidates[i]=matches[i] end
    if #fruitCandidates>0 then selectLocator(1)
    else
        locatorText.Text="LOCATOR: No fruits within 220 studs."
        state.locatorReport="Found=0; low performance mode may hide models"
    end
    eventLog("LOCATOR: nearby="..#matches.." shown="..#fruitCandidates
        .." (visual candidates only)")
end
locateBtn.MouseButton1Click:Connect(function() task.spawn(scanOwnFruits) end)
nextBtn.MouseButton1Click:Connect(function() selectLocator(fruitIndex+1) end)
clearBtn.MouseButton1Click:Connect(clearLocator)

-- Read-only favorite A/B test; reject tools other than harvested fruits.
local firstSample=nil
local function equippedFruit()
    local char=player.Character
    if not char then return nil end
    for _,tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("%d+%.?%d*%s*kg") then
            -- Strip [mutations] and [weight] before exact crop matching.
            -- Don't accidentally select Watering Cans or other gear.
            local key=normalizeCrop(tool.Name:gsub("%b[]",""))
            if knownCrops[key] then return tool end
        end
    end
end
local function fruitSnapshot(tool)
    local values={}
    for k,v in pairs(tool:GetAttributes()) do
        if typeof(v)=="boolean" or typeof(v)=="number"
            or (typeof(v)=="string" and #v<30) then
            values["attr:"..k]=tostring(v)
        end
    end
    for _,obj in ipairs(tool:GetDescendants()) do
        if obj:IsA("BoolValue") or obj:IsA("IntValue") then
            values["value:"..obj.Name]=tostring(obj.Value)
        end
    end
    return values
end
snapBtn.MouseButton1Click:Connect(function()
    local tool=equippedFruit()
    if not tool then
        state.favoriteReport="SNAP A rejected: equip an actual harvested fruit (not gear)."
        eventLog(state.favoriteReport)
        return
    end
    firstSample={tool=tool,name=tool.Name,values=fruitSnapshot(tool)}
    state.favoriteReport="A saved: "..tool.Name.."; manually toggle favorite then COMPARE B."
    eventLog(state.favoriteReport)
end)
compareBtn.MouseButton1Click:Connect(function()
    if not firstSample then
        state.favoriteReport="SNAP A missing; equip fruit and capture first."
        eventLog(state.favoriteReport)
        return
    end
    local tool=firstSample.tool
    if not tool.Parent then
        state.favoriteReport="Original tool unavailable; re-equip the same fruit."
        eventLog(state.favoriteReport)
        return
    end
    local second=fruitSnapshot(tool)
    local fields={}
    for k,v in pairs(firstSample.values) do
        if second[k]~=v then fields[k]=true end
    end
    for k,v in pairs(second) do
        if firstSample.values[k]~=v then fields[k]=true end
    end
    local changes={}
    for k in pairs(fields) do table.insert(changes,k) end
    table.sort(changes)
    state.favoriteReport="Tool="..firstSample.name.."; changedFields="
        ..#changes.."; keys="..table.concat(changes,", ")
        ..". Changes alone do not prove favorite protection."
    eventLog(state.favoriteReport)
end)


-- AUTOMATION LOOP

task.spawn(function()
    while state.alive and gui.Parent do
        local now = os.clock()
        if now >= state.nextTrialCheck then
            state.nextTrialCheck=now+3
            local ok,err=pcall(readAncientTrials)
            if not ok then log("Trial observer error: "..tostring(err)) end
        end

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
                and not state.switches.eventCollect
                and not full then
                collectFruit()
            end
        end

        -- Anubis requested-plant collection (independent of FARM harvest)
        if state.switches.eventCollect and not full and now-state.lastEventCollect>=3 then
            state.lastEventCollect=now
            eventCollect()
        end
        if state.switches.eventSubmit and now-state.lastEventSubmit>=8 then
            state.lastEventSubmit=now
            safeSubmit()
        end
        if state.trial.active then
            local tr=state.trial
            eventInfo.Text=string.format(
                "PHARAOH ANCIENT TRIALS\nStatus: %s\nRequested: %s | Gate: %s/900\nRotation: %s | Collection: %s\nSubmit: LOCKED",
                state.eventMode:gsub("Pharaoh AncientTrials %- ",""),
                tostring(tr.category or "(not shown)"),
                tostring(tr.points or "?"),
                tostring(tr.timer or "?"),
                (tr.points and tr.points>=900) and "PAUSED"
                    or (state.switches.eventCollect and tr.category and "ON" or "OFF/PAUSED"))
        else
            eventInfo.Text=string.format(
                "Event: %s\nLegacy category: %s\nStage: %s  Weight: %s/%s kg\nSubmit: LOCKED",
                state.eventMode,tostring(state.category or "?"),
                tostring(state.stage or "?"),tostring(state.progress or "?"),
                tostring(state.requirement or "?"))
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