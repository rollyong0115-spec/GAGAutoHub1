
-- GAG AUTO HUB V8.6 NEON
-- Android Delta / Xeno
-- Preserves V8.5 and adds Auto Jump
-- Normal interval: 300 seconds
-- Test interval: 1 second

local BASE_URL =
    "https://raw.githubusercontent.com/" ..
    "rollyong0115-spec/Gagv2/main/" ..
    "GAG_Auto_Hub_V8_5_Neon_Delta.lua"

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

-- Stop an earlier instance
if type(env.GAG_V8_Close) == "function" then
    pcall(env.GAG_V8_Close)
end

-- Load the existing complete hub
local ok, err = pcall(function()
    local source = game:HttpGet(BASE_URL)
    local run = loadstring(source)
    assert(type(run) == "function", "Compile failed")
    run()
end)

if not ok then
    warn("[GAG V8.6] Base load failed: " .. tostring(err))
    return
end

local state = env.GAG_V8
if not state or not state.alive then
    warn("[GAG V8.6] Base hub unavailable")
    return
end

local originalClose = env.GAG_V8_Close
local token = {}
env.GAG_V86_JumpToken = token

local running = true
local jumpEnabled = false
local testMode = false
local lastJump = os.clock()

local function new(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function track(signal, fn)
    local connection = signal:Connect(fn)
    table.insert(state.connections, connection)
    return connection
end

local function log(message)
    table.insert(
        state.logLines,
        os.date("%H:%M:%S") .. " " .. message
    )
    state.lastLog = message
    print("[GAG V8.6] " .. message)
end

local function stop()
    running = false
    jumpEnabled = false
    env.GAG_V86_JumpToken = nil
end

-- Preserve the original cleanup
env.GAG_V8_Close = function()
    stop()
    if type(originalClose) == "function" then
        pcall(originalClose)
    end
end

-- Find the EVENT scrolling panel
local gui = player.PlayerGui:FindFirstChild(
    "GAG_AutoHub_V85"
)

if not gui then
    warn("[GAG V8.6] Hub GUI not found")
    stop()
    return
end

local eventPage

for _, obj in ipairs(gui:GetDescendants()) do
    if obj:IsA("TextLabel")
        and obj.Text == "Auto Anubis Event" then

        local box = obj.Parent
        if box and box.Parent
            and box.Parent:IsA("ScrollingFrame") then
            eventPage = box.Parent
            break
        end
    end
end

if not eventPage then
    warn("[GAG V8.6] EVENT page not found")
    stop()
    return
end

local purple = Color3.fromRGB(166, 86, 255)
local dark = Color3.fromRGB(28, 23, 43)
local white = Color3.fromRGB(244, 235, 255)
local muted = Color3.fromRGB(175, 162, 192)

local function rounded(obj)
    new("UICorner", {
        CornerRadius = UDim.new(0, 8)
    }, obj)
end

local title = new("TextLabel", {
    Size = UDim2.new(1, -5, 0, 20),
    BackgroundTransparency = 1,
    Text = "V8.6 AUTO JUMP",
    TextColor3 = purple,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 100
}, eventPage)

local panel = new("Frame", {
    Size = UDim2.new(1, -5, 0, 102),
    BackgroundColor3 = dark,
    BorderSizePixel = 0,
    LayoutOrder = 101
}, eventPage)

rounded(panel)

local function makeButton(text, y, color)
    local button = new("TextButton", {
        Position = UDim2.fromOffset(8, y),
        Size = UDim2.new(1, -16, 0, 28),
        BackgroundColor3 = color or purple,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = white,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = true
    }, panel)

    rounded(button)
    return button
end

local jumpButton = makeButton(
    "AUTO JUMP 5 MIN: OFF", 7
)

local testButton = makeButton(
    "TEST 1 SEC: OFF", 39
)

local info = new("TextLabel", {
    Position = UDim2.fromOffset(8, 73),
    Size = UDim2.new(1, -16, 0, 22),
    BackgroundTransparency = 1,
    Text = "Jump status: OFF",
    TextColor3 = muted,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left
}, panel)

local function refresh()
    jumpButton.Text = jumpEnabled and
        "AUTO JUMP 5 MIN: ON" or
        "AUTO JUMP 5 MIN: OFF"

    testButton.Text = testMode and
        "TEST 1 SEC: ON" or
        "TEST 1 SEC: OFF"

    info.Text = not jumpEnabled and
        "Jump status: OFF" or
        (testMode and
            "Jump status: TESTING (1 sec)" or
            "Jump status: EVERY 5 MIN")
end

track(jumpButton.MouseButton1Click, function()
    if jumpEnabled and not testMode then
        jumpEnabled = false
        log("Auto Jump OFF")
    else
        jumpEnabled = true
        testMode = false
        lastJump = os.clock()
        log("Auto Jump ON - 300 seconds")
    end

    refresh()
end)

track(testButton.MouseButton1Click, function()
    if jumpEnabled and testMode then
        jumpEnabled = false
        testMode = false
        log("Auto Jump test OFF")
    else
        jumpEnabled = true
        testMode = true
        lastJump = os.clock()
        log("Auto Jump test ON - 1 second")
    end

    refresh()
end)

-- Background jump worker
task.spawn(function()
    while running
        and state.alive
        and env.GAG_V86_JumpToken == token do

        if jumpEnabled then
            local interval = testMode and 1 or 300

            if os.clock() - lastJump >= interval then
                lastJump = os.clock()

                local character = player.Character
                local humanoid = character and
                    character:FindFirstChildOfClass(
                        "Humanoid"
                    )

                if humanoid
                    and humanoid.Health > 0 then

                    humanoid.Jump = true
                    log("Auto Jump executed")
                end
            end
        end

        task.wait(0.2)
    end

    stop()
end)

-- Update the header version
for _, obj in ipairs(gui:GetDescendants()) do
    if obj:IsA("TextLabel")
        and obj.Text == "GAG HUB V8.5" then
        obj.Text = "GAG HUB V8.6"
    end
end

log("V8.6 loaded successfully")
log("Auto Jump is OFF by default")
