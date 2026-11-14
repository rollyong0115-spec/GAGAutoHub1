-- Grow a Garden V9.5.1 - Pharaoh Ancient Trials LIVE MONITOR
-- Read-only: NO FireServer / InvokeServer / simulated input / submission.
-- Mobile/Delta friendly. Run while Pharaoh and the entrance HUD are visible.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
if not player then return end

-- Stop a previous copy when the executor shares its environment.
local env = _G
pcall(function() if type(getgenv) == "function" then env = getgenv() end end)
if type(env.GAG_Trials_V943_Stop) == "function" then
    pcall(env.GAG_Trials_V943_Stop)
end

local running = true
local connections = {}
local logs = {}
local cachedWorldTexts = {}
local report = "No scan yet"
local fruitDetails = {}
local protectionEvidence = {}
local favoriteComparison = "No A/B comparison captured yet."
local uiWitnesses = {}
local lastTrait = nil
local lastPoints = nil
local lastTimer = nil
local lastWorldRefresh = -1000000000
local MAX_LOGS = 65

local function connect(signal, fn)
    local ok, c = pcall(function() return signal:Connect(fn) end)
    if ok and c then table.insert(connections, c) end
    return c
end

local function trim(s)
    return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalize(s)
    s = string.lower(tostring(s or ""))
    s = s:gsub("[^%w]+", " ")
    return trim(s:gsub("%s+", " "))
end

local function say(line)
    local stamp = os.date("%H:%M:%S")
    local message = stamp .. " " .. tostring(line)
    table.insert(logs, message)
    while #logs > MAX_LOGS do table.remove(logs, 1) end
    print("[GAG V9.5.1] " .. message)
end

local function safeAttribute(instance, key)
    local ok, value = pcall(function() return instance:GetAttribute(key) end)
    if ok then return value end
    return nil
end

-- Detect protection evidence without assuming that missing flags mean safe.
-- Favorite status can be stored outside a Tool; therefore "UNVERIFIED"
-- remains the default when no readable evidence exists.
local function isProtectionKey(key)
    local keyName = normalize(key):gsub(" ", "")
    return keyName:find("favorite", 1, true) ~= nil
        or keyName:find("favourite", 1, true) ~= nil
        or keyName == "locked" or keyName == "islocked"
        or keyName == "protected" or keyName == "isprotected"
        or keyName == "heartlocked" or keyName == "isheartlocked"
end

local function readProtectionBoolean(value)
    if type(value) == "boolean" then return value end
    if type(value) == "number" and (value == 0 or value == 1) then return value == 1 end
    if type(value) == "string" then
        local low = normalize(value)
        if low == "true" or low == "yes" or low == "1" then return true end
        if low == "false" or low == "no" or low == "0" then return false end
    end
    return nil
end

local function readProtection(tool)
    local positive, negative = {}, {}
    local attributes = {}
    local ok, result = pcall(function() return tool:GetAttributes() end)
    if ok and type(result) == "table" then attributes = result end

    for key, value in pairs(attributes) do
        if isProtectionKey(key) then
            local state = readProtectionBoolean(value)
            if state == true then
                table.insert(positive, "attr:" .. key)
            elseif state == false then
                table.insert(negative, "attr:" .. key)
            end
        end
    end

    -- A Tool can contain readable BoolValue/NumberValue/StringValue flags.
    local okChildren, children = pcall(function() return tool:GetDescendants() end)
    if okChildren and children then
        for _, child in ipairs(children) do
            if isProtectionKey(child.Name) and (
                child:IsA("BoolValue") or child:IsA("IntValue")
                or child:IsA("NumberValue") or child:IsA("StringValue")
            ) then
                local okValue, value = pcall(function() return child.Value end)
                if okValue then
                    local state = readProtectionBoolean(value)
                    if state == true then
                        table.insert(positive, "value:" .. child.Name)
                    elseif state == false then
                        table.insert(negative, "value:" .. child.Name)
                    end
                end
            end
        end
    end

    if #positive > 0 then return "FLAGGED", table.concat(positive, ", "), attributes end
    if #negative > 0 then return "EXPLICIT_FALSE", table.concat(negative, ", "), attributes end
    return "UNVERIFIED", "no recognized local flag", attributes
end

local function metadataSummary(attributes)
    local keys = {}
    for key in pairs(attributes) do table.insert(keys, tostring(key)) end
    table.sort(keys)
    if #keys == 0 then return "attributes: none" end
    local shown = {}
    for i = 1, math.min(#keys, 12) do shown[i] = keys[i] end
    return "attributes: " .. table.concat(shown, ", ") .. (#keys > 12 and ", ..." or "")
end

-- Offline crop-category hints. Not authoritative for new or renamed crops.
-- Overlapping categories are supported; unknown items stay UNKNOWN.
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

local knownCrops = {}
for category, names in pairs(cropLists) do
    for word in string.gmatch(names, "[^|]+") do
        local key = normalize(word)
        if key ~= "" then
            knownCrops[key] = knownCrops[key] or {}
            knownCrops[key][category] = true
        end
    end
end
local sortedCropNames = {}
for name in pairs(knownCrops) do table.insert(sortedCropNames, name) end
table.sort(sortedCropNames, function(a, b) return #a > #b end)

-- Do not match crop words anywhere inside unrelated tool names.
-- Only exact crop identity (or an explicit crop metadata field) is accepted.
local function detectCrop(tool)
    local fields = {"FruitName", "CropName", "PlantName", "FruitType", "CropType"}
    for _, key in ipairs(fields) do
        local value = safeAttribute(tool, key)
        if type(value) == "string" then
            local keyName = normalize(value)
            if knownCrops[keyName] then
                return keyName, knownCrops[keyName], "exact metadata"
            end
        end
    end
    -- Typical harvested display: [Wet, Chilled] Tomato [2.64kg].
    -- Strip bracketed mutation/weight fields, never substring-match "Pumpkin Crate".
    local clean = tostring(tool.Name or ""):gsub("%b[]", " ")
    clean = clean:gsub("%s+[xX]%d+%s*$", "")
    local crop = normalize(clean)
    if knownCrops[crop] then
        return crop, knownCrops[crop], "exact display name"
    end
    return nil, nil, "unrecognized crop"
end

local function fromMetadata(tool, category)
    local keys = {"CropCategory", "Categories", "PlantCategories", "PlantCategory", "CropTraits", "PlantTraits"}
    for _, key in ipairs(keys) do
        local v = safeAttribute(tool, key)
        if type(v) == "string" then
            local text = " " .. normalize(v) .. " "
            if text:find(" " .. normalize(category) .. " ", 1, true) then
                return true
            end
        end
    end
    return false
end

-- Conservative harvested-crop filter. Never classify crates, drinks, pets
-- or seeds as acceptable offerings just because they contain a crop word.
local function isToolFruit(tool, crop)
    local rawName = tostring(tool.Name or "")
    local lowName = rawName:lower()
    local padded = " " .. normalize(rawName) .. " "
    local itemType = normalize(safeAttribute(tool, "ItemType") or safeAttribute(tool, "Type") or "")
    if itemType == "pet" or itemType == "seed" or itemType == "gear"
        or itemType == "egg" or itemType:find("pet", 1, true) then
        return false
    end
    if safeAttribute(tool, "IsPet") == true or safeAttribute(tool, "IsEgg") == true then
        return false
    end
    if lowName:find("%[%s*age%s*%d+") then return false end
    for _, word in ipairs({
        "seed", "sprinkler", "shovel", "trowel", "crate", "lollipop",
        "smoothie", "potion", "gear", "pack", "egg", "chest", "box",
        "mouse", "soup", "juice", "cake", "corndog"
    }) do
        if padded:find(" " .. word .. " ", 1, true) then return false end
    end
    if itemType == "fruit" or itemType == "crop" or itemType == "harvest"
        or safeAttribute(tool, "IsFruit") == true then
        return true
    end
    -- Weight is a useful candidate signal, not proof of an offerable fruit.
    if lowName:find("%d+%.?%d*%s*kg") then return true end
    return false
end

local function isVisibleText(obj)
    if not obj or not obj.Parent then return false end
    local ok, visible = pcall(function() return obj.Visible end)
    if not ok or not visible then return false end
    local parent = obj.Parent
    while parent do
        if parent:IsA("GuiObject") and parent.Visible == false then return false end
        if (parent:IsA("BillboardGui") or parent:IsA("ScreenGui") or parent:IsA("SurfaceGui")) and parent.Enabled == false then return false end
        parent = parent.Parent
    end
    return true
end

local function pathHint(obj)
    local current = obj
    local n = 0
    while current and n < 8 do
        local s = normalize(current.Name)
        if s:find("pharaoh", 1, true) or s:find("ancient trial", 1, true) or s:find("trial", 1, true) then
            return true
        end
        current = current.Parent
        n = n + 1
    end
    return false
end

local function refreshWorldTextCache()
    -- Cached BillboardGui / SurfaceGui labels; one world traversal every 25s.
    -- Yield periodically so an Android client does not freeze on large gardens.
    local nextCache = {}
    local all = Workspace:GetDescendants()
    for i, obj in ipairs(all) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
            local raw = obj.Text or ""
            if raw:lower():find("looking for", 1, true)
                or raw:find("/900", 1, true)
                or pathHint(obj) then
                table.insert(nextCache, obj)
            end
        end
        if i % 2500 == 0 then task.wait() end
        if not running then return end
    end
    cachedWorldTexts = nextCache
    lastWorldRefresh = os.clock()
end

local function getTexts()
    local result = {}
    local gui = player:FindFirstChildOfClass("PlayerGui")
    if gui then
        for _, obj in ipairs(gui:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and isVisibleText(obj) then
                -- Never read our own monitor, including old/new version names.
                -- Otherwise Status/LogText can outrank the real trial board and
                -- copied reports repeatedly ingest their previous contents.
                local rootGui = obj:FindFirstAncestorWhichIsA("ScreenGui")
                local rootName = rootGui and rootGui.Name or ""
                local ownMonitor = rootName:match("^GAGTrialMonitor") ~= nil
                    or rootName:match("^GAGTrialQuick") ~= nil
                if not ownMonitor then
                    local t = trim(obj.Text)
                    if t ~= "" then table.insert(result, {text = t, obj = obj, source = "PlayerGui"}) end
                end
            end
        end
    end
    for _, obj in ipairs(cachedWorldTexts) do
        if obj.Parent and isVisibleText(obj) then
            local t = trim(obj.Text)
            if t ~= "" then table.insert(result, {text = t, obj = obj, source = "Workspace"}) end
        end
    end
    return result
end

local function cleanText(raw)
    return trim(tostring(raw or ""):gsub("<[^>]->", ""):gsub("&nbsp;", " "))
end

local function textContext(obj)
    -- Some UI bubble layouts render "Looking for", the trait, and "plants!"
    -- in separate TextLabels; join nearby labels as a fallback.
    local root = obj:FindFirstAncestorWhichIsA("BillboardGui")
        or obj:FindFirstAncestorWhichIsA("SurfaceGui")
    if not root then
        root = obj.Parent and obj.Parent.Parent or obj.Parent
    end
    if not root then return "" end
    local lines = {}
    local count = 0
    for _, child in ipairs(root:GetDescendants()) do
        if (child:IsA("TextLabel") or child:IsA("TextButton")) and isVisibleText(child) then
            table.insert(lines, cleanText(child.Text))
            count = count + 1
            if count >= 30 then break end
        end
    end
    return table.concat(lines, " ")
end

local function detectTrial(texts)
    local trait, traitScore, traitSource, traitObject = nil, -1, "none", nil
    local progress, progressScore, progressSource = nil, -1, "none"
    local currentTimer = nil
    for _, item in ipairs(texts) do
        local low = cleanText(item.text):lower()
        local requested = low:match("looking%s+for%s+([%a]+)%s+plants")
        if not requested and low:find("looking for", 1, true) then
            requested = textContext(item.obj):lower():match("looking%s+for%s+([%a]+)%s+plants")
        end
        if requested then
            local wanted = requested:sub(1,1):upper() .. requested:sub(2):lower()
            if cropLists[wanted] then
                local score = (pathHint(item.obj) and 10 or 0) + (item.source == "Workspace" and 2 or 0)
                if score > traitScore then
                    trait, traitScore, traitSource, traitObject = wanted, score, item.source .. " > " .. item.obj:GetFullName(), item.obj
                end
            end
        end
        local p, maxp = low:match("(%d[%d,]*)%s*/%s*(%d[%d,]*)")
        if not p and low:find("900", 1, true) then
            p, maxp = textContext(item.obj):match("(%d[%d,]*)%s*/%s*(%d[%d,]*)")
        end
        if p and maxp and tonumber((maxp:gsub(",", ""))) == 900 then
            -- Prefer the real entrance ProgressBillboard over unrelated
            -- UI values that also happen to be formatted like 0/900.
            local path = item.obj:GetFullName()
            local authenticBoard = item.source == "Workspace"
                and path:find("AncientTrialsModel.Important.ProgressBoard.ProgressBillboard", 1, true) ~= nil
            local score = (authenticBoard and 100 or 0)
                + (pathHint(item.obj) and 5 or 0)
                + (item.source == "PlayerGui" and 3 or 0)
            if score > progressScore then
                progress = tonumber((p:gsub(",", "")))
                progressScore = score
                progressSource = item.source .. " > " .. item.obj:GetFullName()
            end
        end
    end
    if traitObject then
        local gui = traitObject:FindFirstAncestorWhichIsA("BillboardGui")
                    or traitObject:FindFirstAncestorWhichIsA("SurfaceGui")
        local root = gui or traitObject.Parent
        if root then
            for _, child in ipairs(root:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    local clock = cleanText(child.Text):match("^(%d?%d:%d%d)$")
                    if clock then currentTimer = clock; break end
                end
            end
        end
    end
    if not currentTimer then
        for _, item in ipairs(texts) do
            local clock = cleanText(item.text):match("^(%d?%d:%d%d)$")
            if clock and pathHint(item.obj) then
                currentTimer = clock
                break
            end
        end
    end
    return trait, progress, currentTimer, traitSource, progressSource
end

local function scanFruitTools(trait)
    local stats = {
        total = 0, match = 0, protected = 0, wrong = 0,
        unknown = 0, other = 0, explicitFalse = 0, unverifiedProtection = 0
    }
    local bins = {{}, {}, {}, {}}
    local evidenceImportant, evidenceSamples = {}, {}
    local sampleCrops = {}
    local roots = {player:FindFirstChildOfClass("Backpack"), player.Character}
    local seen = {}

    for _, root in ipairs(roots) do
        if root then
            for _, obj in ipairs(root:GetChildren()) do
                if obj:IsA("Tool") and not seen[obj] then
                    seen[obj] = true
                    local crop, categories = detectCrop(obj)
                    if isToolFruit(obj, crop) then
                        stats.total = stats.total + 1
                        local protection, proof, attrs = readProtection(obj)
                        if protection == "EXPLICIT_FALSE" then
                            stats.explicitFalse = stats.explicitFalse + 1
                        elseif protection == "UNVERIFIED" then
                            stats.unverifiedProtection = stats.unverifiedProtection + 1
                        end

                        local status, bin
                        if protection == "FLAGGED" then
                            stats.protected = stats.protected + 1
                            status, bin = "PROTECTED FLAG (" .. proof .. ")", 2
                        elseif not trait then
                            stats.unknown = stats.unknown + 1
                            status, bin = "UNKNOWN (trait not detected)", 3
                        elseif (categories and categories[trait]) or fromMetadata(obj, trait) then
                            stats.match = stats.match + 1
                            status, bin = "POSSIBLE MATCH (not verified)", 1
                        elseif categories then
                            stats.wrong = stats.wrong + 1
                            status, bin = "OTHER CATEGORY", 4
                        else
                            stats.unknown = stats.unknown + 1
                            status, bin = "UNKNOWN CROP/TOOL", 3
                        end

                        local protectionSuffix = protection == "UNVERIFIED"
                            and " [FAVORITE UNVERIFIED]"
                            or (protection == "EXPLICIT_FALSE" and " [LOCAL FLAG FALSE]" or "")
                        table.insert(bins[bin], obj.Name .. " -> " .. status .. protectionSuffix)

                        local auditLine = string.format(
                            "%s | Protection=%s (%s) | %s",
                            obj.Name, protection, proof, metadataSummary(attrs))
                        if protection ~= "UNVERIFIED" or bin == 1 or bin == 3 then
                            if #evidenceImportant < 18 then
                                table.insert(evidenceImportant, auditLine)
                            end
                        elseif #evidenceSamples < 6 then
                            local cropName = crop or normalize(obj.Name)
                            if not sampleCrops[cropName] then
                                sampleCrops[cropName] = true
                                table.insert(evidenceSamples, auditLine)
                            end
                        end
                    else
                        stats.other = stats.other + 1
                    end
                end
            end
        end
    end

    -- Highlight matches and unknowns rather than the first 70 backpack slots.
    local details = {}
    for _, bin in ipairs(bins) do
        for _, entry in ipairs(bin) do
            if #details >= 70 then break end
            table.insert(details, entry)
        end
        if #details >= 70 then break end
    end
    local evidence = {}
    for _, row in ipairs(evidenceImportant) do table.insert(evidence, row) end
    for _, row in ipairs(evidenceSamples) do table.insert(evidence, row) end
    if #evidence == 0 then
        table.insert(evidence, "No protection metadata found in harvested Tool candidates.")
    end
    return stats, details, evidence
end

-- UI setup: designed for phone portrait or landscape.
-- Prefer PlayerGui for reliable display on mobile (including Delta).
-- Some executors report a gethui()/CoreGui root that does not render.
local playerGui = player:WaitForChild("PlayerGui")
local parentGui = playerGui
local guiRoots, visited = {}, {}
local function addGuiRoot(root)
    if root and not visited[root] then
        visited[root] = true
        table.insert(guiRoots, root)
    end
end
addGuiRoot(playerGui)
pcall(function() addGuiRoot(CoreGui) end)
pcall(function()
    if type(gethui) == "function" then addGuiRoot(gethui()) end
end)
for _, root in ipairs(guiRoots) do
    pcall(function()
        for _, existing in ipairs(root:GetChildren()) do
            if existing:IsA("ScreenGui")
                and (existing.Name:match("^GAGTrialMonitor")
                  or existing.Name:match("^GAGTrialQuick")) then
                existing:Destroy()
            end
        end
    end)
end
local screen = Instance.new("ScreenGui")
screen.Name = "GAGTrialMonitor951"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.Enabled = true
screen.DisplayOrder = 200
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = parentGui
print("[GAG Ancient Trials] V9.5.1 UI mounted in PlayerGui")

local viewport = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2.new(420, 760)
local panelWidth = math.max(285, math.min(420, viewport.X - 20))
local panelHeight = math.max(340, math.min(475, viewport.Y - 38))

local function create(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local panel = create("Frame", {
    Name = "Panel", Size = UDim2.fromOffset(panelWidth, panelHeight),
    Position = UDim2.new(0.5, -math.floor(panelWidth/2), 0.36, -math.floor(panelHeight/2)),
    BackgroundColor3 = Color3.fromRGB(18, 25, 35), BorderSizePixel = 0,
    Active = true
}, screen)
create("UICorner", {CornerRadius = UDim.new(0, 12)}, panel)
create("UIStroke", {Color = Color3.fromRGB(79, 149, 176), Thickness = 1.5}, panel)

local header = create("Frame", {
    Name = "DragHeader", Size = UDim2.new(1, 0, 0, 41),
    BackgroundColor3 = Color3.fromRGB(29, 54, 69), BorderSizePixel = 0, Active = true
}, panel)
create("UICorner", {CornerRadius = UDim.new(0, 12)}, header)
-- A dedicated full-width touch target prevents TextLabels from swallowing
-- touch-start events on mobile executors. Keep X/minimize outside the handle.
local title = create("TextButton", {
    Name = "DragHandle", Text = "DRAG HERE - TRIALS V9.5.1",
    Font = Enum.Font.GothamBold, TextSize = 13,
    TextColor3 = Color3.fromRGB(237, 249, 255),
    BackgroundTransparency = 1, AutoButtonColor = false,
    Active = true, TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.fromOffset(11, 0), Size = UDim2.new(1, -92, 1, 0)
}, header)
local minimize = create("TextButton", {
    Text = "-", Font = Enum.Font.GothamBold, TextSize = 24,
    TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(68, 83, 104),
    Position = UDim2.new(1, -78, 0, 6), Size = UDim2.fromOffset(32, 30)
}, header)
create("UICorner", {CornerRadius = UDim.new(0, 7)}, minimize)
local close = create("TextButton", {
    Text = "X", Font = Enum.Font.GothamBold, TextSize = 16,
    TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(174, 64, 66),
    Position = UDim2.new(1, -41, 0, 6), Size = UDim2.fromOffset(32, 30)
}, header)
create("UICorner", {CornerRadius = UDim.new(0, 7)}, close)

local status = create("TextLabel", {
    Name = "Status", Text = "Scanning Pharaoh and entrance HUD...",
    TextColor3 = Color3.fromRGB(227, 242, 251), Font = Enum.Font.Code,
    TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, BackgroundTransparency = 1,
    Position = UDim2.fromOffset(12, 49), Size = UDim2.new(1, -24, 0, 124)
}, panel)

local buttons = create("Frame", {
    Position = UDim2.fromOffset(10, 178), Size = UDim2.new(1, -20, 0, 37),
    BackgroundTransparency = 1
}, panel)
local scanButton = create("TextButton", {
    Text = "SCAN NOW", Font = Enum.Font.GothamBold, TextSize = 13,
    TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(31, 111, 127),
    Size = UDim2.new(0.49, 0, 1, 0)
}, buttons)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, scanButton)
local copyButton = create("TextButton", {
    Text = "COPY RESULTS", Font = Enum.Font.GothamBold, TextSize = 13,
    TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(49, 106, 74),
    Position = UDim2.new(0.51, 0, 0, 0), Size = UDim2.new(0.49, 0, 1, 0)
}, buttons)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, copyButton)

local sampleRow = create("Frame", {
    Name = "FavCompareRow", Position = UDim2.fromOffset(10, 219),
    Size = UDim2.new(1, -20, 0, 34), BackgroundTransparency = 1
}, panel)
local snapAButton = create("TextButton", {
    Name = "SnapshotA", Text = "SNAP A",
    Font = Enum.Font.GothamBold, TextSize = 13,
    TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(82, 94, 135),
    Size = UDim2.new(0.49, 0, 1, 0)
}, sampleRow)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, snapAButton)
local snapBButton = create("TextButton", {
    Name = "SnapshotB", Text = "COMPARE B",
    Font = Enum.Font.GothamBold, TextSize = 13,
    TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(96, 105, 69),
    Position = UDim2.new(0.51, 0, 0, 0), Size = UDim2.new(0.49, 0, 1, 0)
}, sampleRow)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, snapBButton)

local scroll = create("ScrollingFrame", {
    Name = "LogScroll", Position = UDim2.fromOffset(10, 261),
    Size = UDim2.new(1, -20, 1, -291),
    BackgroundColor3 = Color3.fromRGB(11, 17, 25), BorderSizePixel = 0,
    ScrollBarThickness = 5, CanvasSize = UDim2.fromOffset(0, 500),
    ScrollingDirection = Enum.ScrollingDirection.Y
}, panel)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, scroll)
local logText = create("TextLabel", {
    Name = "LogText", BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(188, 227, 214), Font = Enum.Font.Code,
    TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Position = UDim2.fromOffset(7, 7), Size = UDim2.new(1, -16, 0, 475),
    Text = ""
}, scroll)
local footer = create("TextLabel", {
    Text = "READ ONLY - no fruit submissions", Font = Enum.Font.Gotham,
    TextSize = 11, TextColor3 = Color3.fromRGB(155, 184, 198),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 1, -27), Size = UDim2.new(1, -20, 0, 20)
}, panel)

local function drawLogs()
    if not running then return end
    local displayed = table.concat(logs, "\n")
    if #fruitDetails > 0 then
        displayed = displayed .. "\n--- FRUIT DETAILS ---\n" .. table.concat(fruitDetails, "\n")
    end
    logText.Text = displayed
    local visualLines = #logs + #fruitDetails + (#fruitDetails > 0 and 2 or 0)
    for _, message in ipairs(logs) do visualLines = visualLines + math.floor(#message / 48) end
    for _, message in ipairs(fruitDetails) do visualLines = visualLines + math.floor(#message / 48) end
    local h = math.max(220, visualLines * 15 + 20)
    logText.Size = UDim2.new(1, -16, 0, h)
    scroll.CanvasSize = UDim2.new(0, 0, 0, h + 15)
end

local function cleanup()
    if not running then return end
    running = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    table.clear(connections)
    pcall(function() screen:Destroy() end)
    if env.GAG_Trials_V943_Stop == cleanup then env.GAG_Trials_V943_Stop = nil end
end
env.GAG_Trials_V943_Stop = cleanup
connect(close.MouseButton1Click, cleanup)

local minimized = false
connect(minimize.MouseButton1Click, function()
    minimized = not minimized
    status.Visible = not minimized
    buttons.Visible = not minimized
    sampleRow.Visible = not minimized
    scroll.Visible = not minimized
    footer.Visible = not minimized
    panel.Size = minimized and UDim2.fromOffset(panelWidth, 41) or UDim2.fromOffset(panelWidth, panelHeight)
    minimize.Text = minimized and "+" or "-"
end)

-- Mobile drag-handle support (touch + mouse). Move the floating panel,
-- not the scrolling log area. One active touch is expected on phones.
local dragging = false
local pointerStart, panelStart, activeType

local function beginDrag(input)
    local kind = input.UserInputType
    if kind ~= Enum.UserInputType.Touch
       and kind ~= Enum.UserInputType.MouseButton1 then return end
    if dragging then return end
    dragging = true
    activeType = kind
    pointerStart = Vector2.new(input.Position.X, input.Position.Y)
    panelStart = panel.AbsolutePosition
end

local function moveDrag(input)
    if not dragging or not pointerStart or not panelStart then return end
    local kind = input.UserInputType
    if activeType == Enum.UserInputType.Touch then
        if kind ~= Enum.UserInputType.Touch then return end
    else
        if kind ~= Enum.UserInputType.MouseMovement
           and kind ~= Enum.UserInputType.MouseButton1 then return end
    end
    local delta = Vector2.new(input.Position.X, input.Position.Y) - pointerStart
    local camera = Workspace.CurrentCamera
    local size = camera and camera.ViewportSize or Vector2.new(420, 760)
    -- Keep the drag bar visible even when the GUI is minimized.
    local x = math.clamp(panelStart.X + delta.X, 0, math.max(0, size.X - panel.AbsoluteSize.X))
    local y = math.clamp(panelStart.Y + delta.Y, 0, math.max(0, size.Y - 41))
    panel.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
end

local function endDrag(input)
    if not dragging then return end
    local kind = input.UserInputType
    if (activeType == Enum.UserInputType.Touch and kind == Enum.UserInputType.Touch)
       or (activeType == Enum.UserInputType.MouseButton1
          and kind == Enum.UserInputType.MouseButton1) then
        dragging, pointerStart, panelStart, activeType = false, nil, nil, nil
    end
end

connect(title.InputBegan, beginDrag)
connect(header.InputBegan, beginDrag)
connect(title.InputChanged, moveDrag)
connect(header.InputChanged, moveDrag)
connect(UserInputService.InputChanged, moveDrag)
connect(UserInputService.TouchMoved, moveDrag)
connect(UserInputService.InputEnded, endDrag)

-- Experimental A/B metadata comparison. No changes are sent to the game.
-- User manually favorites/unfavorites a disposable fruit between snapshots.
local firstSnapshot = nil
local function selectedTool()
    local character = player.Character
    if character then
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("Tool") then return obj, "equipped" end
        end
    end
    return nil, "Equip the disposable fruit you want to compare, then press SNAP A"
end

local function snapshotValue(value)
    local kind = typeof(value)
    if kind == "string" then return "string:" .. value end
    if kind == "boolean" then return "bool:" .. tostring(value) end
    if kind == "number" then return "number:" .. tostring(value) end
    if kind == "Color3" then return "color:" .. tostring(value) end
    if kind == "Vector3" then return "vector:" .. tostring(value) end
    if kind == "BrickColor" then return "brickcolor:" .. tostring(value) end
    return kind .. ":" .. tostring(value)
end

local function snapshotTool(tool)
    local map = {}
    local ok, attrs = pcall(function() return tool:GetAttributes() end)
    if ok and type(attrs) == "table" then
        for k, v in pairs(attrs) do map["attr:" .. tostring(k)] = snapshotValue(v) end
    end
    local okChildren, children = pcall(function() return tool:GetDescendants() end)
    if okChildren and children then
        local collected = 0
        for _, child in ipairs(children) do
            if child:IsA("BoolValue") or child:IsA("IntValue")
                or child:IsA("NumberValue") or child:IsA("StringValue") then
                collected = collected + 1
                if collected > 80 then break end
                local relative = child:GetFullName():gsub("^" .. tool:GetFullName():gsub("([^%w])","%%%1"), "")
                local okValue, v = pcall(function() return child.Value end)
                if okValue then map["value:" .. relative] = snapshotValue(v) end
            end
        end
    end
    local collection = game:GetService("CollectionService")
    local okTags, tags = pcall(function() return collection:GetTags(tool) end)
    if okTags and type(tags) == "table" then
        for _, tag in ipairs(tags) do map["tag:" .. tostring(tag)] = "present" end
    end
    return {tool = tool, name = tool.Name, fields = map}
end

-- Print only small nonidentifying values. Large IDs and strings are redacted
-- while still exposing whether a key changed.
local function preview(v)
    if v == nil then return "(missing)" end
    if v:sub(1, 7) == "string:" then
        local raw = v:sub(8)
        if #raw > 24 or raw:find("%d%d%d%d%d%d%d%d") then
            return "(string changed, redacted)"
        end
    end
    if #v > 85 then return v:sub(1, 80) .. "..." end
    return v
end

local function resolveSameTool(a)
    if a.tool and a.tool.Parent then return a.tool end
    local matches = {}
    for _, root in ipairs({player:FindFirstChildOfClass("Backpack"), player.Character}) do
        if root then
            for _, obj in ipairs(root:GetChildren()) do
                if obj:IsA("Tool") and obj.Name == a.name then
                    table.insert(matches, obj)
                end
            end
        end
    end
    if #matches == 1 then return matches[1] end
    if #matches > 1 then return nil, "Multiple tools have that name; re-equip the original" end
    return nil, "Original tool not found. Re-equip it and try again"
end

connect(snapAButton.MouseButton1Click, function()
    local tool, why = selectedTool()
    if not tool then
        favoriteComparison = "SNAP A failed: " .. tostring(why)
        say(favoriteComparison); drawLogs()
        return
    end
    firstSnapshot = snapshotTool(tool)
    local count = 0
    for _ in pairs(firstSnapshot.fields) do count = count + 1 end
    favoriteComparison = "A captured: " .. tool.Name .. " (" .. count .. " fields). "
        .. "Now manually change its favorite state in the game's UI, then press COMPARE B."
    say("SNAP A saved for " .. tool.Name .. " (" .. count .. " fields)")
    drawLogs()
end)

connect(snapBButton.MouseButton1Click, function()
    if not firstSnapshot then
        favoriteComparison = "Press SNAP A on an equipped fruit first"
        say(favoriteComparison); drawLogs(); return
    end
    local tool, why = resolveSameTool(firstSnapshot)
    if not tool then
        favoriteComparison = "COMPARE B failed: " .. tostring(why)
        say(favoriteComparison); drawLogs(); return
    end
    local other = snapshotTool(tool)
    local union = {}
    for k in pairs(firstSnapshot.fields) do union[k] = true end
    for k in pairs(other.fields) do union[k] = true end
    local keys = {}
    for k in pairs(union) do table.insert(keys, k) end
    table.sort(keys)
    local changed = {}
    for _, k in ipairs(keys) do
        local before, after = firstSnapshot.fields[k], other.fields[k]
        if before ~= after then
            table.insert(changed, k .. ": " .. preview(before) .. " -> " .. preview(after))
        end
    end
    local rows = {"Tool=" .. firstSnapshot.name,
        "ChangedFields=" .. tostring(#changed),
        "No automatic favorite inference; review the changes below."}
    if #changed == 0 then
        table.insert(rows, "No Tool attribute, Value object, or tag changes were visible.")
        table.insert(rows, "The favorite state may be stored in player data or inventory UI.")
    end
    for i = 1, math.min(30, #changed) do
        table.insert(rows, changed[i])
    end
    favoriteComparison = table.concat(rows, "\n")
    say("COMPARE B: " .. tostring(#changed) .. " changed fields for " .. firstSnapshot.name)
    drawLogs()
end)

local function fullReport()
    return table.concat({
        "GAG V9.5.1 TRIAL REPORT (READ ONLY)",
        report,
        "--- UI text witnesses (max 20) ---",
        table.concat(uiWitnesses, "\n"),
        "--- Fruit/tool details (max 70) ---",
        table.concat(fruitDetails, "\n"),
        "--- Protection metadata audit (max 24) ---",
        table.concat(protectionEvidence, "\n"),
        "--- Favorite A/B comparison ---",
        favoriteComparison,
        "--- Live logs ---",
        table.concat(logs, "\n")
    }, "\n")
end

connect(copyButton.MouseButton1Click, function()
    local copy = nil
    if type(setclipboard) == "function" then copy = setclipboard
    elseif type(toclipboard) == "function" then copy = toclipboard end
    if copy then
        local ok = pcall(copy, fullReport())
        if ok then say("Copied full report to clipboard")
        else say("Clipboard copy failed; report remains in log") end
    else
        say("Clipboard unsupported by executor; report remains visible")
    end
    drawLogs()
end)

local remoteNames = {"TrialsSync", "TrialsSubmitted", "TrialsClaimed", "TrialsTeleported"}
local remoteFolder = ReplicatedStorage:FindFirstChild("GameEvents")
if remoteFolder then remoteFolder = remoteFolder:FindFirstChild("Events") end
if remoteFolder then remoteFolder = remoteFolder:FindFirstChild("AnubisEvent") end
if remoteFolder then remoteFolder = remoteFolder:FindFirstChild("AncientTrials") end
if remoteFolder then
    for _, name in ipairs(remoteNames) do
        local event = remoteFolder:FindFirstChild(name)
        if event and event:IsA("RemoteEvent") then
            say("REMOTE FOUND: " .. event:GetFullName())
            connect(event.OnClientEvent, function(...)
                local n = select("#", ...)
                say("PASSIVE EVENT " .. name .. " (args=" .. n .. "; no call sent)")
                drawLogs()
            end)
        end
    end
else
    say("AncientTrials remote folder not available; GUI detection still enabled")
end

local scanning = false
local function scanNow(forceWorld)
    if scanning or not running then return end
    scanning = true
    local ok, err = pcall(function()
        if forceWorld or (os.clock() - lastWorldRefresh > 25) then
            refreshWorldTextCache()
        end
        local texts = getTexts()
        uiWitnesses = {}
        for _, item in ipairs(texts) do
            local low = cleanText(item.text):lower()
            if low:find("looking", 1, true) or low:find("plants", 1, true)
                or low:find("900", 1, true) or low:find("entrance", 1, true) then
                if #uiWitnesses < 20 then
                    table.insert(uiWitnesses, item.source .. " [" .. item.obj:GetFullName() .. "] " .. cleanText(item.text))
                end
            end
        end
        local trait, points, timer, traitSrc, pointsSrc = detectTrial(texts)
        local stats, details, evidence = scanFruitTools(trait)
        fruitDetails = details
        protectionEvidence = evidence
        local t = trait or "?"
        local p = points and tostring(points) or "?"
        local clock = timer or "?"
        report = string.format("Trait=%s Points=%s/900 RotationCountdown=%s\nFruits=%d Matching=%d Protected=%d\nExplicitFalseFlags=%d ProtectionUnverified=%d\nWrongCategory=%d Unknown=%d OtherTools=%d\nNote=Fruit count means candidates only. ExplicitFalseFlags are not server-verified safe. ProtectionUnverified must not be auto-offered.\nTraitSource=%s\nPointsSource=%s",
            t, p, clock, stats.total, stats.match, stats.protected,
            stats.explicitFalse, stats.unverifiedProtection,
            stats.wrong, stats.unknown, stats.other, traitSrc, pointsSrc)
        status.Text = string.format(
            "REQUESTED: %s    ENTRANCE: %s/900\nNEXT TRAIT CHANGE: %s    READ ONLY\nCandidates: %d  Possible match: %d\nFlagged: %d  Flag=false: %d\nFavorite unknown: %d  Wrong: %d  Crop unknown: %d\n*No match is automatically safe to submit\nUI sources: %s / %s",
            t, p, clock, stats.total, stats.match, stats.protected,
            stats.explicitFalse, stats.unverifiedProtection,
            stats.wrong, stats.unknown,
            traitSrc ~= "none" and "FOUND" or "MISSING",
            pointsSrc ~= "none" and "FOUND" or "MISSING")
        if trait ~= lastTrait then
            if lastTrait ~= nil and trait ~= nil then
                say("CATEGORY ROTATED: " .. lastTrait .. " -> " .. t .. " (countdown reset expected)")
            else
                say("TRAIT DETECTED: " .. tostring(lastTrait or "?") .. " -> " .. t)
            end
            if traitSrc ~= "none" then say("TRAIT UI: " .. traitSrc) end
            lastTrait = trait
        end
        if points ~= lastPoints then
            say("ENTRANCE POINTS: " .. p .. "/900")
            if pointsSrc ~= "none" then say("PROGRESS UI: " .. pointsSrc) end
            lastPoints = points
        end
        if timer and timer ~= lastTimer then lastTimer = timer end
        say(string.format("SCAN: fruits=%d match=%d protected=%d wrong=%d unknown=%d", stats.total,
            stats.match, stats.protected, stats.wrong, stats.unknown))
        if stats.total == 0 then
            say("No harvested Tool fruits in Backpack/Character; custom inventory may use other storage")
        end
        drawLogs()
    end)
    if not ok then say("SCAN ERROR: " .. tostring(err)); drawLogs() end
    scanning = false
end

connect(scanButton.MouseButton1Click, function() task.spawn(scanNow, true) end)
say("V9.5.1 started (read-only). Stand near Pharaoh; keep entrance HUD visible.")
say("World text cache refreshes every 25s; UI/inventory refreshes every 4s.")
drawLogs()
task.spawn(function()
    while running and screen.Parent do
        scanNow(false)
        task.wait(4)
    end
    cleanup()
end)