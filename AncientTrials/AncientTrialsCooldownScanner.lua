-- Grow a Garden | Ancient Trials Cooldown Inspector V1
-- READ ONLY: no FireServer, InvokeServer, button activation, input simulation,
-- harvesting, submitting, inventory mutation or teleportation.
-- Works alongside the main GAG Auto Hub. Close X disconnects listeners.

local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local WS=game:GetService("Workspace")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
local env
pcall(function() if type(getgenv)=="function" then env=getgenv() end end)
env=env or _G

if type(env.GAG_CooldownScanner_Stop)=="function" then
    pcall(env.GAG_CooldownScanner_Stop)
end
local prior=pg:FindFirstChild("GAGAncientCooldownInspector")
if prior then pcall(function() prior:Destroy() end) end

local alive=true
local connections={}
local report="Scan not run."
local baseline=nil
local eventLog={}
local lastSignal="None"
local function connect(signal,fn)
    local c=signal:Connect(fn)
    table.insert(connections,c)
    return c
end
local function say(message)
    local line=os.date("%H:%M:%S").." "..tostring(message)
    eventLog[#eventLog+1]=line
    if #eventLog>30 then table.remove(eventLog,1) end
end
local function new(class,props,parent)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent
    return o
end
local function corner(obj,r)
    new("UICorner",{CornerRadius=UDim.new(0,r or 8)},obj)
end
local width=math.max(265,math.min(365,(WS.CurrentCamera and WS.CurrentCamera.ViewportSize.X or 420)-18))
local height=math.max(340,math.min(490,(WS.CurrentCamera and WS.CurrentCamera.ViewportSize.Y or 720)-60))
local screen=new("ScreenGui",{
    Name="GAGAncientCooldownInspector",ResetOnSpawn=false,
    IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling
},pg)
local panel=new("Frame",{
    Size=UDim2.fromOffset(width,height),Position=UDim2.fromOffset(9,60),
    BackgroundColor3=Color3.fromRGB(18,24,34),BorderSizePixel=0,
    Active=true
},screen)
corner(panel,10)
local head=new("Frame",{
    Size=UDim2.new(1,0,0,40),BackgroundColor3=Color3.fromRGB(35,44,61),
    BorderSizePixel=0,Active=true
},panel)
corner(head,10)
new("TextLabel",{
    Text="ANCIENT TRIALS | COOLDOWN SCAN",Font=Enum.Font.GothamBold,
    TextSize=13,TextColor3=Color3.fromRGB(230,242,255),
    BackgroundTransparency=1,Position=UDim2.fromOffset(8,3),
    Size=UDim2.new(1,-73,0,34),TextXAlignment=Enum.TextXAlignment.Left
},head)
local function button(parent,name,label,pos,size,color)
    local b=new("TextButton",{
        Name=name,Text=label,Font=Enum.Font.GothamBold,TextSize=12,
        TextColor3=Color3.new(1,1,1),
        BackgroundColor3=color or Color3.fromRGB(47,96,131),
        BorderSizePixel=0,Position=pos,Size=size,AutoButtonColor=true
    },parent)
    corner(b,7)
    return b
end
local minimize=button(head,"Minimize","-",UDim2.new(1,-62,0,6),
    UDim2.fromOffset(26,27),Color3.fromRGB(78,89,110))
local close=button(head,"Close","X",UDim2.new(1,-32,0,6),
    UDim2.fromOffset(26,27),Color3.fromRGB(153,56,61))
local status=new("TextLabel",{
    Text="Read-only. Use SNAP A before manual submission.",
    BackgroundTransparency=1,TextWrapped=true,Font=Enum.Font.Gotham,
    TextSize=11,TextColor3=Color3.fromRGB(205,218,233),
    Position=UDim2.fromOffset(9,45),Size=UDim2.new(1,-18,0,39)
},panel)
local row=new("Frame",{
    BackgroundTransparency=1,Position=UDim2.fromOffset(9,86),
    Size=UDim2.new(1,-18,0,67)
},panel)
local half=UDim2.new(.5,-4,0,29)
local scanBtn=button(row,"Scan","SCAN NOW",UDim2.fromOffset(0,0),half)
local snapBtn=button(row,"Snap","SNAP A",UDim2.new(.5,4,0,0),half)
local compareBtn=button(row,"Compare","COMPARE B",UDim2.fromOffset(0,36),half)
local copyBtn=button(row,"Copy","COPY RESULTS",UDim2.new(.5,4,0,36),half,
    Color3.fromRGB(38,121,93))
local scroll=new("ScrollingFrame",{
    Position=UDim2.fromOffset(9,160),Size=UDim2.new(1,-18,1,-173),
    BackgroundColor3=Color3.fromRGB(9,15,24),BorderSizePixel=0,
    ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,100),
    ScrollingDirection=Enum.ScrollingDirection.Y
},panel)
corner(scroll,7)
local output=new("TextLabel",{
    Text="Press SCAN NOW to inspect event signals and visible UI.",
    TextColor3=Color3.fromRGB(194,226,207),TextWrapped=true,
    Font=Enum.Font.Code,TextSize=11,BackgroundTransparency=1,
    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
    Position=UDim2.fromOffset(6,6),Size=UDim2.new(1,-16,0,150)
},scroll)
local function draw(text)
    if not alive then return end
    output.Text=text
    local lines=1
    for _ in text:gmatch("\n") do lines=lines+1 end
    local visual=lines+math.floor(#text/53)
    local h=math.max(170,visual*14)
    output.Size=UDim2.new(1,-16,0,h)
    scroll.CanvasSize=UDim2.fromOffset(0,h+14)
end
local function byPath(root,...)
    local obj=root
    for _,name in ipairs({...}) do obj=obj and obj:FindFirstChild(name) end
    return obj
end
local function fullName(o)
    local ok,name=pcall(function() return o:GetFullName() end)
    return ok and name or tostring(o.Name)
end
local function plain(text)
    return tostring(text or ""):gsub("<[^>]+>","")
        :gsub("&nbsp;"," "):gsub("%s+"," ")
end
local function valueText(v)
    if typeof(v)=="Instance" then return "<Instance:"..v.ClassName..">" end
    if typeof(v)=="string" then
        return (v:gsub("[\r\n]+"," ")):sub(1,110)
    end
    return tostring(v):sub(1,110)
end
local function relevantKey(name)
    local k=tostring(name):lower()
    for _,term in ipairs({
        "cooldown","cool_down","submit","trial","ready","wait",
        "delay","timer","countdown","expire","reset","remaining",
        "category","trait","rotation","progress","point","next"
    }) do
        if k:find(term,1,true) then return true end
    end
    return false
end
local function safeKey(key)
    local k=tostring(key):lower()
    return not (k:find("token",1,true) or k:find("secret",1,true)
       or k:find("password",1,true) or k:find("auth",1,true))
end

local function snapshot()
    local entries,rows={},{}
    local function put(key,val)
        if #rows>=195 then return end
        key=tostring(key)
        val=valueText(val)
        if entries[key]==nil then
            entries[key]=val
            rows[#rows+1]=key.." = "..val
        end
    end
    local important=byPath(WS,"Interaction","AncientTrialsModel","Important")
    local npc=byPath(important,"TrialNPC","AncientTrailsBillboard")
    local trait=byPath(npc,"BubbleBillboard","BG","TextLabel")
    local points=byPath(important,"ProgressBoard","ProgressBillboard",
        "UpgradeBar","ProgressionLabel")
    put("InspectorVersion","V1 - READ ONLY")
    put("SnapshotLocalTime",os.date("%H:%M:%S"))
    put("LastPassiveEvent",lastSignal)
    put("TrialModel",important and fullName(important) or "NOT FOUND")
    put("RawTrait",trait and trait.Text or "NOT FOUND")
    put("PlainTrait",trait and plain(trait.Text) or "NOT FOUND")
    put("GatePoints",points and points.Text or "NOT FOUND")

    local remoteRoot=byPath(RS,"GameEvents","Events","AnubisEvent","AncientTrials")
    put("AncientTrialsRemotes",remoteRoot and fullName(remoteRoot) or "NOT FOUND")
    if remoteRoot then
        for _,obj in ipairs(remoteRoot:GetChildren()) do
            put("REMOTE "..obj.Name,obj.ClassName)
        end
    end
    local function scanAttrs(obj,tag)
        if not obj then return end
        local ok,attrs=pcall(function() return obj:GetAttributes() end)
        if not ok then return end
        for k,v in pairs(attrs) do
            if relevantKey(k) and safeKey(k) then
                put(tag..".Attribute."..k,v)
            end
        end
    end
    scanAttrs(player,"Player")
    scanAttrs(important,"TrialImportant")
    scanAttrs(npc,"TrialNPC")
    scanAttrs(remoteRoot,"TrialRemotes")
    if remoteRoot then
        for _,child in ipairs(remoteRoot:GetChildren()) do
            scanAttrs(child,"Remote."..child.Name)
        end
    end
    local function inspectValue(o,group)
        local label=o.Name
        if (o:IsA("StringValue") or o:IsA("IntValue")
            or o:IsA("NumberValue") or o:IsA("BoolValue")) and relevantKey(label) then
            put(group.." "..fullName(o),o.Value)
        end
    end
    if important then
        local count=0
        for _,obj in ipairs(important:GetDescendants()) do
            if not alive then break end
            count=count+1
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local t=tostring(obj.Text or "")
                if t~="" and #t<200 then put("WORLD TEXT "..fullName(obj),t) end
            end
            inspectValue(obj,"WORLD VALUE")
            if count<=250 then scanAttrs(obj,"World."..fullName(obj)) end
            if count%500==0 then task.wait() end
            if count>4500 then break end
        end
    end
    local count=0
    for _,obj in ipairs(pg:GetDescendants()) do
        if not alive then break end
        count=count+1
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local t=tostring(obj.Text or "")
            local str=t:lower()
            local name=fullName(obj):lower()
            if #t>0 and #t<220 and (
                relevantKey(str) or (name:find("ancient",1,true)
                or name:find("trial",1,true) or name:find("anubis",1,true)
                or name:find("pharaoh",1,true))
            ) then
                put("PLAYER GUI "..fullName(obj),t)
            end
        end
        if relevantKey(obj.Name) then
            inspectValue(obj,"PLAYER VALUE")
            scanAttrs(obj,"PlayerGUI."..fullName(obj))
        end
        if count%700==0 then task.wait() end
        if count>8000 then break end
    end
    table.sort(rows)
    return {entries=entries,rows=rows,count=#rows}
end
local function formatSnapshot(s,label)
    local lines={
        "GAG ANCIENT TRIALS COOLDOWN INSPECTOR V1 (READ ONLY)",
        label,
        "Entries="..tostring(s.count),
        "No remote calls were sent.",
        "--- Snapshot ---"
    }
    for _,l in ipairs(s.rows) do lines[#lines+1]=l end
    lines[#lines+1]="--- Passive event log ---"
    for _,line in ipairs(eventLog) do lines[#lines+1]=line end
    return table.concat(lines,"\n")
end
local function compare(a,b,label)
    local changed={}
    for k,v in pairs(b.entries) do
        if a.entries[k]~=v then
            changed[#changed+1]=k.." | A="..tostring(a.entries[k] or "(missing)")
                .." | B="..v
        end
    end
    for k,v in pairs(a.entries) do
        if b.entries[k]==nil then
            changed[#changed+1]=k.." | A="..v.." | B=(missing)"
        end
    end
    table.sort(changed)
    local lines={
        "GAG ANCIENT TRIALS COOLDOWN COMPARISON V1 (READ ONLY)",
        label,
        "ChangedFields="..#changed,
        "NOTE: Category rotation countdown is not necessarily submission cooldown.",
        "No remote calls were sent.",
        "--- Changed fields (max 65) ---"
    }
    for i=1,math.min(#changed,65) do lines[#lines+1]=changed[i] end
    lines[#lines+1]="--- Current snapshot ---"
    for _,line in ipairs(b.rows) do lines[#lines+1]=line end
    lines[#lines+1]="--- Passive event log ---"
    for _,line in ipairs(eventLog) do lines[#lines+1]=line end
    return table.concat(lines,"\n")
end

local busy=false
local function scan(mode)
    if busy or not alive then return end
    busy=true
    status.Text="Inspecting visible event UI and metadata..."
    task.spawn(function()
        local ok,result=pcall(snapshot)
        if ok and alive then
            if mode=="snap" then
                baseline=result
                report=formatSnapshot(result,"SNAP A captured. Submit manually, then COMPARE B.")
                status.Text="SNAP A saved. Submit manually, then press COMPARE B."
            elseif mode=="compare" then
                if baseline then
                    report=compare(baseline,result,"Manual A/B comparison")
                    status.Text="COMPARE B: inspect changed fields in COPY RESULTS."
                else
                    report=formatSnapshot(result,"No SNAP A baseline. Take SNAP A first.")
                    status.Text="No baseline. Press SNAP A before manual submission."
                end
            else
                report=formatSnapshot(result,"Manual SCAN NOW")
                status.Text="Scan complete. COPY RESULTS shares details."
            end
            draw(report)
        elseif alive then
            report="SCAN ERROR: "..tostring(result)
            status.Text="Scan error. COPY RESULTS for details."
            draw(report)
        end
        busy=false
    end)
end
connect(scanBtn.MouseButton1Click,function() scan("manual") end)
connect(snapBtn.MouseButton1Click,function() scan("snap") end)
connect(compareBtn.MouseButton1Click,function() scan("compare") end)
connect(copyBtn.MouseButton1Click,function()
    if not alive then return end
    local fn=type(setclipboard)=="function" and setclipboard
        or (type(toclipboard)=="function" and toclipboard or nil)
    if fn then
        local ok=pcall(fn,report)
        status.Text=ok and "Report copied. Paste it in ChatGPT."
            or "Copy failed. Check console output."
    else
        status.Text="Clipboard unavailable. Results printed in Delta console."
    end
    print(report)
end)

local function stop()
    if not alive then return end
    alive=false
    for _,conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
    table.clear(connections)
    pcall(function() screen:Destroy() end)
    if env.GAG_CooldownScanner_Stop==stop then env.GAG_CooldownScanner_Stop=nil end
end
env.GAG_CooldownScanner_Stop=stop
connect(close.MouseButton1Click,stop)

local minimized=false
connect(minimize.MouseButton1Click,function()
    minimized=not minimized
    for _,obj in ipairs({status,row,scroll}) do obj.Visible=not minimized end
    panel.Size=minimized and UDim2.fromOffset(width,40)
        or UDim2.fromOffset(width,height)
    minimize.Text=minimized and "+" or "-"
end)

local dragging=false
local dragStart,startPos,dragInput
connect(head.InputBegan,function(input)
    if input.UserInputType~=Enum.UserInputType.Touch
        and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    if dragging then return end
    dragging=true
    dragInput=input
    dragStart=Vector2.new(input.Position.X,input.Position.Y)
    startPos=panel.Position
end)
connect(UIS.InputChanged,function(input)
    if not dragging then return end
    if input~=dragInput and not (dragInput
        and dragInput.UserInputType==Enum.UserInputType.MouseButton1
        and input.UserInputType==Enum.UserInputType.MouseMovement) then return end
    local delta=Vector2.new(input.Position.X,input.Position.Y)-dragStart
    local viewport=WS.CurrentCamera and WS.CurrentCamera.ViewportSize or Vector2.new(420,720)
    local x=math.clamp(startPos.X.Offset+delta.X,0,math.max(0,viewport.X-width))
    local y=math.clamp(startPos.Y.Offset+delta.Y,0,math.max(0,viewport.Y-40))
    panel.Position=UDim2.fromOffset(x,y)
end)
connect(UIS.InputEnded,function(input)
    if input==dragInput
        or (dragInput and dragInput.UserInputType==Enum.UserInputType.MouseButton1
            and input.UserInputType==Enum.UserInputType.MouseButton1) then
        dragging=false
        dragInput=nil
    end
end)

local eventRoot=byPath(RS,"GameEvents","Events","AnubisEvent","AncientTrials")
if eventRoot then
    for _,name in ipairs({
        "TrialsSync","TrialsSubmitted","TrialsClaimed",
        "TrialsRewards","TrialsTeleported"
    }) do
        local obj=eventRoot:FindFirstChild(name)
        if obj and obj:IsA("RemoteEvent") then
            connect(obj.OnClientEvent,function(...)
                if not alive then return end
                lastSignal=name.." at "..os.date("%H:%M:%S")
                    .." ("..select("#",...).." args)"
                say("PASSIVE "..lastSignal.."; no call sent")
                -- Don't auto-scan on every remote; manually compare after submit
                -- so UI has had time to render its authoritative cooldown.
                status.Text="Saw "..name..". Use COMPARE B to inspect cooldown changes."
            end)
            say("LISTENING "..name)
        end
    end
else
    say("AncientTrials remotes unavailable; UI scan still works.")
end
say("Cooldown Inspector V1 ready. No submissions/harvests performed.")
scan("manual")
