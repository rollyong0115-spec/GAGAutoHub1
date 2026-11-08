
-- GAG AUTO HUB V8.2 COMPACT | Delta Android
-- All automation OFF by default. Back up V7.1 before replacing it.
-- Anubis crop categories are provisional; verify with event results.
local PROFILE_IMAGE_ASSET_ID = ""
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local events = RS:WaitForChild("GameEvents", 12)
if not events then warn("GAG V8.2: GameEvents missing") return end
local env = (getgenv and getgenv()) or _G
if type(env.GAG_V8_Close) == "function" then pcall(env.GAG_V8_Close) end
local state = {
    alive=true, switches={}, connections={}, logLines={}, lastLog="Ready",
    count=0, capacity=250, inventoryKnown=false,
    lastNormal=0, lastAnubisHarvest=0,
    lastSubmit=0, lastRestart=0, pending=nil, token=math.random(100000,900000),
    submitted=0, accepted=0, harvestBatches=0, restarts=0,
    trait="?", stage="?", eventStatus="Stopped", restartBusy=false,
    done=false, lastResult=0, restartFault=false
}
env.GAG_V8 = state
local function new(class, props, parent)
    local obj=Instance.new(class)
    for k,v in pairs(props or {}) do obj[k]=v end
    obj.Parent=parent
    return obj
end
local function connect(signal, fn)
    local c=signal:Connect(fn)
    state.connections[#state.connections+1]=c
    return c
end
local function log(s)
    s=tostring(s)
    state.lastLog=s
    state.logLines[#state.logLines+1]=os.date("%H:%M:%S").." "..s
    if #state.logLines>120 then table.remove(state.logLines,1) end
end
local function remote(path)
    local obj=events
    for part in path:gmatch("[^/]+") do obj=obj and obj:FindFirstChild(part) end
    return obj
end
local function fire(path,...)
    local r=remote(path)
    if not r or not r:IsA("RemoteEvent") then return false end
    return pcall(r.FireServer,r,...)
end
local C={
    bg=Color3.fromRGB(14,12,25),
    panel=Color3.fromRGB(28,23,43),
    tile=Color3.fromRGB(37,29,55),
    accent=Color3.fromRGB(166,86,255),
    white=Color3.fromRGB(244,235,255),
    muted=Color3.fromRGB(175,162,192),
    green=Color3.fromRGB(106,241,164),
    red=Color3.fromRGB(130,48,76)
}
local function corner(o,r)
    new("UICorner",{CornerRadius=UDim.new(0,r or 7)},o)
end
local function btn(parent,text,pos,size,color)
    local b=new("TextButton",{
        Position=pos,Size=size,BackgroundColor3=color or C.tile,
        Text=text,TextColor3=C.white,Font=Enum.Font.GothamBold,
        TextSize=10,AutoButtonColor=true
    },parent)
    corner(b,6)
    return b
end
local gui=new("ScreenGui",{
    Name="GAG_AutoHub_V82",ResetOnSpawn=false,
    IgnoreGuiInset=true,DisplayOrder=900
},pg)
local main=new("Frame",{
    Size=UDim2.fromOffset(294,336),
    Position=UDim2.new(.5,-147,.5,-168),
    BackgroundColor3=C.bg,BorderSizePixel=0,Active=true
},gui)
corner(main,11)
new("UIStroke",{Color=C.accent,Thickness=1,Transparency=.3},main)
local header=new("Frame",{
    Size=UDim2.new(1,0,0,45),BackgroundColor3=C.panel,
    BorderSizePixel=0,Active=true
},main)
corner(header,11)
local avatarSource=PROFILE_IMAGE_ASSET_ID~="" and
    ((PROFILE_IMAGE_ASSET_ID:match("^rbxassetid://") and PROFILE_IMAGE_ASSET_ID)
    or "rbxassetid://"..PROFILE_IMAGE_ASSET_ID)
    or ("rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=150&h=150")
local avatar=new("ImageLabel",{
    Position=UDim2.fromOffset(7,6),Size=UDim2.fromOffset(32,32),
    BackgroundColor3=C.tile,Image=avatarSource,
    ScaleType=Enum.ScaleType.Crop
},header)
new("UICorner",{CornerRadius=UDim.new(1,0)},avatar)
new("TextLabel",{
    Position=UDim2.fromOffset(45,6),Size=UDim2.fromOffset(164,18),
    BackgroundTransparency=1,Text="GAG HUB V8.2",
    TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left
},header)
new("TextLabel",{
    Position=UDim2.fromOffset(45,24),Size=UDim2.fromOffset(164,13),
    BackgroundTransparency=1,Text="Anubis • Shops",
    TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left
},header)
local minimize=btn(header,"-",UDim2.new(1,-59,0,9),UDim2.fromOffset(23,23))
local exit=btn(header,"X",UDim2.new(1,-31,0,9),UDim2.fromOffset(23,23),C.red)
local mini=new("ImageButton",{
    Size=UDim2.fromOffset(44,44),Position=UDim2.new(1,-56,.65,0),
    BackgroundColor3=C.panel,Image=avatarSource,
    ScaleType=Enum.ScaleType.Crop,Visible=false,Active=true
},gui)
new("UICorner",{CornerRadius=UDim.new(1,0)},mini)
local tabs=new("Frame",{
    Position=UDim2.fromOffset(7,50),Size=UDim2.new(1,-14,0,27),
    BackgroundTransparency=1
},main)
local pages,tabButtons={},{}
local tabNames={"EVENT","SHOPS","INFO"}
for i,name in ipairs(tabNames) do
    tabButtons[name]=btn(tabs,name,
        UDim2.new((i-1)/#tabNames,2,0,0),
        UDim2.new(1/#tabNames,-4,1,0),
        i==1 and C.accent or C.tile)
    local sc=new("ScrollingFrame",{
        Position=UDim2.fromOffset(7,82),
        Size=UDim2.new(1,-14,1,-119),
        BackgroundTransparency=1,BorderSizePixel=0,
        ScrollBarThickness=2,CanvasSize=UDim2.fromOffset(0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=i==1
    },main)
    new("UIListLayout",{
        Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder
    },sc)
    pages[name]=sc
end
local function selectTab(name)
    for n,p in pairs(pages) do
        p.Visible=n==name
        tabButtons[n].BackgroundColor3=n==name and C.accent or C.tile
    end
end
for name,b in pairs(tabButtons) do
    connect(b.MouseButton1Click,function() selectTab(name) end)
end
local function section(page,text)
    new("TextLabel",{
        Size=UDim2.new(1,-4,0,18),BackgroundTransparency=1,
        Text=text,TextColor3=C.accent,Font=Enum.Font.GothamBold,
        TextSize=10,TextXAlignment=Enum.TextXAlignment.Left
    },pages[page])
end
local function hint(page,text,height)
    local label=new("TextLabel",{
        Size=UDim2.new(1,-4,0,height or 35),
        BackgroundColor3=C.panel,Text=text,TextWrapped=true,
        TextColor3=C.muted,TextSize=9,Font=Enum.Font.Gotham,
        BorderSizePixel=0
    },pages[page])
    corner(label,6)
    return label
end
local function toggle(page,key,text,desc)
    local box=new("Frame",{
        Size=UDim2.new(1,-4,0,43),
        BackgroundColor3=C.panel,BorderSizePixel=0
    },pages[page])
    corner(box,7)
    new("TextLabel",{
        Position=UDim2.fromOffset(8,5),Size=UDim2.new(1,-67,0,17),
        BackgroundTransparency=1,Text=text,TextColor3=C.white,
        Font=Enum.Font.GothamBold,TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left
    },box)
    new("TextLabel",{
        Position=UDim2.fromOffset(8,23),Size=UDim2.new(1,-67,0,13),
        BackgroundTransparency=1,Text=desc,TextColor3=C.muted,
        Font=Enum.Font.Gotham,TextSize=8,
        TextXAlignment=Enum.TextXAlignment.Left
    },box)
    local b=btn(box,"OFF",UDim2.new(1,-51,0,9),UDim2.fromOffset(43,25))
    state.switches[key]=false
    connect(b.MouseButton1Click,function()
        state.switches[key]=not state.switches[key]
        b.Text=state.switches[key] and "ON" or "OFF"
        b.BackgroundColor3=state.switches[key] and C.accent or C.tile
        if key=="anubis" then
            if state.switches[key] then
                state.done=false
                state.restartFault=false
                state.pending=nil
                state.eventStatus="Running"
                log("Anubis started")
            else
                state.pending=nil
                state.eventStatus="Stopped"
                log("Anubis stopped")
            end
        end
    end)
end
section("EVENT","ANUBIS ANCIENT ARC")
toggle("EVENT","anubis","Auto Anubis Event","Trait harvest + submit")
toggle("EVENT","anubisRestart","Auto Paid Restart","1T per confirmed restart")
local arcLabel=hint("EVENT","Trait: ? | Stage: ?\nStopped",39)
local copyResults=btn(pages.EVENT,"COPY RESULTS",
    UDim2.new(0,0,0,0),UDim2.new(1,-4,0,27),C.accent)
section("SHOPS","STANDARD SHOPS")
toggle("SHOPS","seeds","Auto Buy Seeds","Visible stock")
toggle("SHOPS","gear","Auto Buy Gear","Visible stock")
toggle("SHOPS","eggs","Auto Buy Eggs","Visible stock")
section("INFO","ABOUT V8.2")
hint("INFO",
    "GAG AUTO HUB V8.2 COMPACT\n\nAll switches OFF by default.\n"..
    "Root crops: Octobloom, Ghoul Root and more.\n"..
    "Halloween + generic harvest archived.\n"..
    "Paid restart uses separate toggle.\n"..
    "Spider + Mimic work independently.\n"..
    "Close X cleans up connections.",140)
local footer=new("Frame",{
    Position=UDim2.new(0,7,1,-31),Size=UDim2.new(1,-14,0,25),
    BackgroundColor3=C.panel
},main)
corner(footer,6)
local status=new("TextLabel",{
    Position=UDim2.fromOffset(5,0),Size=UDim2.new(1,-10,1,0),
    BackgroundTransparency=1,Text="Ready",TextColor3=C.green,
    Font=Enum.Font.Gotham,TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left,
    TextTruncate=Enum.TextTruncate.AtEnd
},footer)
local function drag(target,handle)
    local active=false
    local start,initial,dragInput
    connect(handle.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or
           input.UserInputType==Enum.UserInputType.MouseButton1 then
            active=true;start=input.Position
            initial=target.Position;dragInput=input
        end
    end)
    connect(UIS.InputChanged,function(input)
        if not active or not dragInput then return end
        if input~=dragInput and not (
            dragInput.UserInputType==Enum.UserInputType.MouseButton1 and
            input.UserInputType==Enum.UserInputType.MouseMovement
        ) then return end
        local delta=input.Position-start
        target.Position=UDim2.new(
            initial.X.Scale,initial.X.Offset+delta.X,
            initial.Y.Scale,initial.Y.Offset+delta.Y)
    end)
    connect(UIS.InputEnded,function(input)
        if input==dragInput then active=false;dragInput=nil end
    end)
end
drag(main,header)
drag(mini,mini)
connect(minimize.MouseButton1Click,function()
    main.Visible=false;mini.Visible=true
end)
connect(mini.MouseButton1Click,function()
    main.Visible=true;mini.Visible=false
end)
local function cleanup()
    if not state.alive then return end
    state.alive=false
    for k in pairs(state.switches) do state.switches[k]=false end
    for _,c in ipairs(state.connections) do
        pcall(function() c:Disconnect() end)
    end
    if gui then gui:Destroy() end
    if env.GAG_V8_Close==cleanup then env.GAG_V8_Close=nil end
end
env.GAG_V8_Close=cleanup
connect(exit.MouseButton1Click,cleanup)
connect(copyResults.MouseButton1Click,function()
    local text=table.concat(state.logLines,"\n")
    if type(setclipboard)=="function" then
        local ok=pcall(setclipboard,text)
        log(ok and "Results copied" or "Clipboard failed")
    else log("Clipboard not supported") end
end)
local function getCapacity()
    for _,obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local a,b=obj.Text:match(
                "Fruit%s*Items%s*%(%s*(%d+)%s*/%s*(%d+)%s*%)")
            if a and b then return tonumber(a),tonumber(b) end
        end
    end
end
local function ownFarm()
    local root=workspace:FindFirstChild("Farm")
    if not root then return end
    for _,farm in ipairs(root:GetChildren()) do
        local imp=farm:FindFirstChild("Important")
        local data=imp and imp:FindFirstChild("Data")
        local owner=data and data:FindFirstChild("Owner")
        if owner and tostring(owner.Value)==player.Name then return farm end
    end
end
local function plantsFolder()
    local farm=ownFarm()
    local imp=farm and farm:FindFirstChild("Important")
    return imp and imp:FindFirstChild("Plants_Physical")
end
local function stockAvailable(stock)
    if not stock or not stock:IsA("TextLabel") then return false end
    local n=tostring(stock.Text):match("(%d+)")
    return n~=nil and tonumber(n)>0
end
local function normalShop(kind)
    local rootName=kind=="seeds" and "Seed_Shop" or
        (kind=="gear" and "Gear_Shop" or "PetEggShop")
    local root=pg:FindFirstChild(rootName)
    if not root then return end
    local calls=0
    for _,obj in ipairs(root:GetDescendants()) do
        if obj.Name=="Stock_Text" and stockAvailable(obj) then
            local frame=obj.Parent and obj.Parent.Parent
            local name=frame and frame.Name
            if name and name~="" and name~="ScrollingFrame" and
                name~="Main_Frame" then
                local ok=false
                if kind=="seeds" then
                    ok=fire("BuySeedStock","Shop",name)
                elseif kind=="gear" then
                    ok=fire("BuyGearStock",name)
                else ok=fire("BuyPetEgg",name) end
                if ok then calls+=1 end
            end
            if calls>=10 then break end
        end
    end
    if calls>0 then log("Shop "..kind..": "..calls.." requests") end
end
local cropTraits={
    ["Beanstalk"]={"Leafy","Stalky","Vegetable"},
    ["Blue Candypop"]={"Flower"},
    ["Bone Blossom"]={"Flower"},
    ["Candy Blossom 2026"]={"Flower","Sweet"},
    ["Celestiberry"]={"Berry","Fruit","Leafy","Prickly"},
    ["Dragon Fruit"]={"Fruit","Prickly","Tropical"},
    ["Moon Mango"]={"Fruit","Leafy","Woody"},
    ["Poison Apple"]={"Fruit","Leafy","Prickly","Sour","Sweet","Woody"},
    ["Tomato"]={"Fruit","Leafy"},
    ["Carrot"]={"Root"},["Potato"]={"Root"},["Radish"]={"Root"},
    ["Octobloom"]={"Root","Flower"},["Ghoul Root"]={"Root"},
    ["Wild Carrot"]={"Root"},["Onion"]={"Root"},
    ["Spring Onion"]={"Root"},["Firefly Spiral"]={"Root"},
    ["Beach Brella"]={"Root"},["Bear Claw Flower"]={"Root"},
    ["Evo Beetroot II"]={"Root"},["Evo Beetroot I"]={"Root"},
    ["Evo Beetroot III"]={"Root"},["Evo Beetroot IV"]={"Root"},
    ["Halloween Fang Root"]={"Root"},["Fang Root"]={"Root"},
    ["Auburn Pine"]={"Root"},["Aurora Vine"]={"Root"},
    ["Mangrove"]={"Root"},["Reindeer Root"]={"Root"},
    ["Trinity Fruit"]={"Root"},["Rhubarb"]={"Root"},
    ["Tall Asparagus"]={"Root"},["Turnip"]={"Root"},
    ["Anubis Bramble"]={"Root"},["Wraproot"]={"Root"},
    ["Bumble Bulb"]={"Root"},["Taro Flower"]={"Root"},
    ["Mummy's Hand"]={"Root"},["Marshmallow Root"]={"Root"},
    ["Shadow Spine"]={"Root"},["Smoke Stalk"]={"Root"},
    ["Obby Oddvine"]={"Root"},["Egg Shroom"]={"Root"}
}
local function qualifies(name,trait)
    name=tostring(name):gsub("%s+Seed$","")
    local list=cropTraits[name]
    if not list then return false end
    for _,t in ipairs(list) do
        if t==trait then return true end
    end
    return false
end
local arc=remote("Events/AnubisEvent/AncientArc")
local submit=arc and arc:FindFirstChild("Submit")
local submitResult=arc and arc:FindFirstChild("SubmitResult")
local restart=arc and arc:FindFirstChild("Restart")
local function anubisCollect(now)
    if now-state.lastAnubisHarvest<5 then return end
    state.lastAnubisHarvest=now
    local trait=arc and arc:GetAttribute("Trait")
    if type(trait)~="string" or trait=="" then
        state.eventStatus="Trait unavailable";return
    end
    state.trait=trait
    local plants=plantsFolder()
    local collect=remote("Crops/Collect")
    if not plants or not collect or not collect:IsA("RemoteEvent") then
        state.eventStatus="Farm/collect missing";return
    end
    if state.inventoryKnown and state.count>=state.capacity then
        state.eventStatus="Inventory full";return
    end
    local serverNow=workspace:GetServerTimeNow()
    local batch={}
    local selected=0
    local eligible=0
    local function sendBatch()
        if #batch==0 then return end
        local ok=pcall(collect.FireServer,collect,batch)
        if ok then state.harvestBatches+=1 end
        batch={}
    end
    for _,plant in ipairs(plants:GetChildren()) do
        if not state.alive or not state.switches.anubis then return end
        if qualifies(plant.Name,trait) then
            eligible+=1
            local fruits=plant:FindFirstChild("Fruits")
            if fruits then
                for _,fruit in ipairs(fruits:GetChildren()) do
                    if fruit:IsA("Model") then
                        local done=fruit:GetAttribute("DoneGrowTime")
                        local weight=fruit:FindFirstChild("Weight")
                        if type(done)=="number" and done<=serverNow and
                            weight and weight:IsA("NumberValue") and
                            weight.Value>0 then
                            batch[#batch+1]=fruit
                            selected+=1
                            if #batch>=20 then
                                sendBatch();task.wait(.2)
                                if selected>=100 then break end
                            end
                        end
                    end
                end
            end
        end
        if selected>=100 then break end
    end
    sendBatch()
    if selected>0 then
        state.eventStatus="Collect sent: "..selected
        log("Anubis "..trait..": "..selected.." fruit refs")
    elseif eligible==0 then
        state.eventStatus="No planted crops for "..trait
    else state.eventStatus="Waiting for ripe "..trait end
end
local function requestSubmit(now)
    if not submit or not submit:IsA("RemoteEvent") then
        state.eventStatus="Submit remote missing";return
    end
    if state.pending then
        if now-state.pending.sent<10 then return end
        log("Submit timeout; retry later")
        state.pending=nil;state.lastSubmit=now
        return
    end
    if now-state.lastSubmit<3 then return end
    state.lastSubmit=now;state.token+=1
    local token=state.token
    state.pending={token=token,sent=now}
    local ok=pcall(submit.FireServer,submit,{Token=token,Mode="All"})
    if not ok then
        state.pending=nil;state.eventStatus="Submit send failed"
    else
        state.submitted+=1
        state.eventStatus="Awaiting submit result"
    end
end
local function requestRestart(now)
    if not state.done or not state.switches.anubisRestart or
        state.restartBusy or state.restartFault or
        now-state.lastRestart<15 then return end
    if not restart or not restart:IsA("RemoteFunction") then
        state.eventStatus="Restart remote missing";return
    end
    state.restartBusy=true;state.lastRestart=now
    state.eventStatus="Restart pending (1T)"
    local invocation=state.restarts+1
    task.spawn(function()
        local finished=false
        local success,result=false,nil
        task.spawn(function()
            success,result=pcall(restart.InvokeServer,restart)
            finished=true
        end)
        local started=os.clock()
        while state.alive and not finished and
            os.clock()-started<12 do task.wait(.1) end
        if not state.alive then return end
        if not finished then
            state.restartFault=true
            state.eventStatus="Restart timed out; halted"
            log("Restart timeout: halted to avoid double charge")
        elseif success and type(result)=="table" and result.Success==true then
            state.restarts=invocation
            state.done=false;state.pending=nil
            state.eventStatus="Restart confirmed"
            log("Restart confirmed #"..state.restarts)
        else
            state.eventStatus="Restart rejected"
            log("Restart rejected: "..tostring(
                type(result)=="table" and result.Reason or result))
        end
        state.restartBusy=false
    end)
end
if submitResult and submitResult:IsA("RemoteEvent") then
    connect(submitResult.OnClientEvent,function(result)
        if not state.alive or not state.switches.anubis or
            type(result)~="table" then return end
        local pending=state.pending
        if not pending then return end
        if result.Token~=nil and tonumber(result.Token)~=pending.token then
            return
        end
        state.pending=nil;state.lastResult=os.clock()
        if result.Stage~=nil then state.stage=tostring(result.Stage) end
        if result.Success==true then
            state.accepted+=1
            state.eventStatus="Submission accepted"
            log("Submit OK | stage "..state.stage..
                " | added "..tostring(result.Added or "?"))
        else
            local reason=tostring(result.Reason or "Unknown")
            state.eventStatus=reason
            if reason=="Done" then
                state.done=true
                log("Excavation complete; restart available")
            elseif reason=="AlreadyReady" then
                state.lastSubmit=os.clock()+2
            elseif reason=="NoneFound" then
                state.lastSubmit=os.clock()+12
            elseif reason=="TooFar" then
                state.lastSubmit=os.clock()+8
                log("Too far: stand near Anubis")
            else log("Submit: "..reason) end
        end
    end)
else log("SubmitResult remote unavailable") end
log("V8.2 Compact loaded - all toggles OFF")
task.spawn(function()
    while state.alive and gui.Parent do
        local now=os.clock()
        local count,cap=getCapacity()
        if count and cap and cap>0 then
            state.count=count;state.capacity=cap;state.inventoryKnown=true
        else state.inventoryKnown=false end
        if now-state.lastNormal>=15 then
            state.lastNormal=now
            for _,kind in ipairs({"seeds","gear","eggs"}) do
                if state.switches[kind] then normalShop(kind) end
            end
        end
        if state.switches.anubis then
            if arc then
                state.trait=tostring(arc:GetAttribute("Trait") or "?")
            end
            if state.done then
                if state.switches.anubisRestart then
                    requestRestart(now)
                else state.eventStatus="Done - restart OFF" end
            elseif not state.restartBusy then
                anubisCollect(now)
                requestSubmit(now)
            end
        end
        arcLabel.Text=string.format(
            "Trait: %s | Stage: %s\n%s | Restarts: %d",
            state.trait,state.stage,state.eventStatus,state.restarts)
        status.Text=string.format(
            "%s | Fruit: %s/%s",state.lastLog,
            state.inventoryKnown and tostring(state.count) or "?",
            state.inventoryKnown and tostring(state.capacity) or "?")
        task.wait(1)
    end
end)
