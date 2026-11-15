-- GAG Ancient Trials | Focused Remote Spy V1 | Delta Android
-- OBSERVATION ONLY: does not submit, collect, click, teleport, or call remotes.
-- Intercepts only outgoing TrialsSubmit or legacy AncientArc.Submit calls.
-- Existing remote calls are passed through unchanged.
-- CLOSE (X) disables capture and disconnects event listeners.
-- Executor hooks cannot reliably be uninstalled; a single dormant hook stays
-- installed in this Roblox session after Close, and is reused on reload.

local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local WS=game:GetService("Workspace")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")

local sharedEnv
pcall(function()
    if type(getgenv)=="function" then sharedEnv=getgenv() end
end)
sharedEnv=sharedEnv or _G
if type(sharedEnv.GAG_TrialsRemoteSpy_Close)=="function" then
    pcall(sharedEnv.GAG_TrialsRemoteSpy_Close)
end
local previous=pg:FindFirstChild("GAGAncientTrialsRemoteSpy")
if previous then pcall(function() previous:Destroy() end) end

local function path(root,...)
    for _,part in ipairs({...}) do
        root=root and root:FindFirstChild(part)
    end
    return root
end
local arc=path(RS,"GameEvents","Events","AnubisEvent","AncientArc")
local trials=path(RS,"GameEvents","Events","AnubisEvent","AncientTrials")
local submit=trials and trials:FindFirstChild("TrialsSubmit")
local legacy=arc and arc:FindFirstChild("Submit")
local registry=sharedEnv.GAG_TrialsRemoteSpyRegistry
if type(registry)~="table" then
    registry={installed=false,enabled=false,handler=nil,target=nil,legacy=nil}
    sharedEnv.GAG_TrialsRemoteSpyRegistry=registry
end
registry.enabled=false
registry.handler=nil
registry.target=submit
registry.legacy=legacy

local alive=true
local connections={}
local eventLog={}
local attemptCount=0
local lastAttempt="None"
local lastResponse="None"
local lastCooldown="(not read)"
local lastDelta=nil
local lastAttemptAt=nil
local hookStatus="Not installed"
local report="Starting..."
local function addConnection(c)
    connections[#connections+1]=c
    return c
end
local function bind(signal,fn)
    return addConnection(signal:Connect(fn))
end
local function line(message)
    eventLog[#eventLog+1]=os.date("%H:%M:%S").." "..tostring(message)
    if #eventLog>75 then table.remove(eventLog,1) end
end
local function datum(v)
    local kind=typeof(v)
    if kind=="Instance" then
        local name,class="?", "?"
        pcall(function() name=v.Name;class=v.ClassName end)
        return "<"..class..":"..name..">"
    elseif kind=="Vector3" or kind=="Vector2" or kind=="CFrame" then
        return "<"..kind..">"
    elseif type(v)=="string" then
        if #v>72 then return "<string "..#v.." chars withheld>" end
        return string.format("%q",(v:gsub("[\r\n]"," ")))
    elseif type(v)=="number" or type(v)=="boolean" or type(v)=="nil" then
        return tostring(v)
    end
    return "<"..kind..">"
end
local function sensitive(k)
    if type(k)~="string" then return false end
    local l=k:lower()
    for _,word in ipairs({"token","password","secret","key","auth",
        "session","nonce","signature","cookie","jwt","credential"}) do
        if l:find(word,1,true) then return true end
    end
    return false
end
local function serialize(value,depth,visited)
    depth=depth or 0
    visited=visited or {}
    if type(value)~="table" then return datum(value) end
    if visited[value] then return "<cycle>" end
    if depth>=3 then return "<table(depth limit)>" end
    visited[value]=true
    local keys={}
    local n=0
    for k in pairs(value) do
        keys[#keys+1]=k
        n=n+1
        if n>=35 then break end
    end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    local items={}
    for i=1,math.min(#keys,18) do
        local k=keys[i]
        local key=type(k)=="number" and "["..tostring(k).."]"
            or tostring(k):sub(1,30)
        if sensitive(k) then
            items[#items+1]=key.."=<redacted>"
        else
            items[#items+1]=key.."="..serialize(value[k],depth+1,visited)
        end
    end
    if #keys>18 then items[#items+1]="...more fields" end
    visited[value]=nil
    return "{"..table.concat(items,", ").."}"
end
local function safeResponse(args)
    if type(args)~="table" then return "No result data" end
    local good={
        Success=true,Reason=true,Status=true,Added=true,Progress=true,
        Points=true,Cooldown=true,CooldownUntil=true,Remaining=true,
        RetryAfter=true,Wait=true,Trait=true,Category=true,MaxProgress=true
    }
    local parts={}
    for i=1,math.min(args.n or #args,2) do
        local a=args[i]
        if type(a)=="table" then
            local payload={}
            for k,v in pairs(a) do
                if type(k)=="string" and good[k] then
                    if type(v)=="number" or type(v)=="boolean" then
                        payload[#payload+1]=k.."="..tostring(v)
                    elseif type(v)=="string" and #v<=45 and
                        v:match("^[%a%d_ %-%+]+$") then
                        payload[#payload+1]=k.."="..v
                    else
                        payload[#payload+1]=k.."=<"..typeof(v)..">"
                    end
                end
            end
            table.sort(payload)
            parts[#parts+1]="arg"..i..":{"..
                (#payload>0 and table.concat(payload,",") or "no public status fields").."}"
        else
            parts[#parts+1]="arg"..i..":"..typeof(a)
        end
    end
    return table.concat(parts," | ")
end
local function new(class,props,parent)
    local obj=Instance.new(class)
    for k,v in pairs(props or {}) do obj[k]=v end
    obj.Parent=parent
    return obj
end
local function round(obj)
    new("UICorner",{CornerRadius=UDim.new(0,8)},obj)
end
local viewport=WS.CurrentCamera and WS.CurrentCamera.ViewportSize
    or Vector2.new(430,760)
local width=math.max(280,math.min(370,viewport.X-18))
local height=math.max(340,math.min(490,viewport.Y-45))
local gui=new("ScreenGui",{Name="GAGAncientTrialsRemoteSpy",
    ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)
local panel=new("Frame",{Size=UDim2.fromOffset(width,height),
    Position=UDim2.fromOffset(9,46),BackgroundColor3=Color3.fromRGB(17,25,35),
    BorderSizePixel=0,Active=true},gui)
round(panel)
local head=new("Frame",{Size=UDim2.new(1,0,0,39),
    BackgroundColor3=Color3.fromRGB(35,46,65),BorderSizePixel=0,
    Active=true},panel)
round(head)
new("TextLabel",{Text="ANCIENT TRIALS | REMOTE SPY V1",
    Position=UDim2.fromOffset(8,4),Size=UDim2.new(1,-77,0,30),
    BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
    TextColor3=Color3.fromRGB(230,242,255),
    Font=Enum.Font.GothamBold,TextSize=12},head)
local function button(parent,name,text,pos,size,color)
    local b=new("TextButton",{Name=name,Text=text,
        Position=pos,Size=size,
        Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(1,1,1),
        BackgroundColor3=color or Color3.fromRGB(46,99,140),
        AutoButtonColor=true,BorderSizePixel=0},parent)
    round(b)
    return b
end
local minBtn=button(head,"Minimize","-",UDim2.new(1,-62,0,5),
    UDim2.fromOffset(26,27),Color3.fromRGB(78,88,106))
local closeBtn=button(head,"Close","X",UDim2.new(1,-32,0,5),
    UDim2.fromOffset(26,27),Color3.fromRGB(167,66,66))
local status=new("TextLabel",{Text="Initializing outgoing-call hook...",
    Position=UDim2.fromOffset(8,43),Size=UDim2.new(1,-16,0,49),
    BackgroundTransparency=1,TextWrapped=true,
    TextColor3=Color3.fromRGB(220,237,255),
    Font=Enum.Font.Gotham,TextSize=11},panel)
local control=new("Frame",{Position=UDim2.fromOffset(9,95),
    Size=UDim2.new(1,-18,0,31),BackgroundTransparency=1},panel)
local refreshBtn=button(control,"Refresh","REFRESH STATUS",
    UDim2.fromOffset(0,0),UDim2.new(.5,-4,1,0))
local copyBtn=button(control,"Copy","COPY RESULTS",
    UDim2.new(.5,4,0,0),UDim2.new(.5,-4,1,0),
    Color3.fromRGB(38,130,90))
local watchBtn=button(panel,"Watch","PAUSE WATCH",
    UDim2.fromOffset(9,132),UDim2.new(1,-18,0,30),
    Color3.fromRGB(125,85,47))
local scroll=new("ScrollingFrame",{Position=UDim2.fromOffset(9,170),
    Size=UDim2.new(1,-18,1,-181),
    BackgroundColor3=Color3.fromRGB(7,14,23),
    BorderSizePixel=0,ScrollBarThickness=4,
    CanvasSize=UDim2.fromOffset(0,300)},panel)
round(scroll)
local txt=new("TextLabel",{Text="Waiting for an outgoing TrialsSubmit...",
    Position=UDim2.fromOffset(6,6),Size=UDim2.new(1,-15,0,220),
    BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,
    Font=Enum.Font.Code,TextSize=11,
    TextColor3=Color3.fromRGB(183,230,207)},scroll)
local function render(value)
    report=value
    if not alive then return end
    txt.Text=value
    local num=1
    for _ in value:gmatch("\n") do num=num+1 end
    local h=math.max(220,(num+math.floor(#value/58))*14)
    txt.Size=UDim2.new(1,-15,0,h)
    scroll.CanvasSize=UDim2.fromOffset(0,h+16)
end
local function currentState()
    local progress=trials and trials:GetAttribute("Progress")
    local maximum=trials and trials:GetAttribute("MaxProgress")
    local cooldown=trials and trials:GetAttribute("CooldownUntil")
    local trait=trials and trials:GetAttribute("Trait")
    return tostring(progress).."/"..tostring(maximum),
        tostring(cooldown),tostring(trait)
end
local function display(reason)
    if not alive then return end
    local progress,cooldown,trait=currentState()
    lastCooldown=cooldown
    local lines={
        "GAG ANCIENT TRIALS REMOTE SPY V1 (OBSERVE ONLY)",
        "Reason="..tostring(reason),
        "HookStatus="..hookStatus,
        "WatchEnabled="..tostring(registry.enabled),
        "Target="..(submit and "AncientTrials.TrialsSubmit" or "MISSING"),
        "LegacyTarget="..(legacy and "AncientArc.Submit" or "MISSING"),
        "CurrentCategory="..trait,
        "Gate="..progress,
        "CooldownUntil="..cooldown,
        "OutgoingSubmitAttempts="..tostring(attemptCount),
        "LastAttempt="..lastAttempt,
        "LastAttemptIntervalSeconds="..tostring(lastDelta),
        "LastPassiveResponse="..lastResponse,
        "CaptureLimit=TrialsSubmit/AncientArc.Submit only",
        "All outgoing calls passed through unchanged.",
        "No remote calls sent by this scanner.",
        "--- Chronological event log (latest 75) ---"
    }
    for _,v in ipairs(eventLog) do lines[#lines+1]=v end
    render(table.concat(lines,"\n"))
    status.Text="Hook: "..hookStatus.." | Gate: "..progress..
        "\nCalls captured: "..attemptCount.." | CooldownUntil: "..cooldown
end

-- The hook has a shared dispatcher and is installed only once per session.
-- On Close the dispatcher is inactive; Roblox executor metamethod hooks
-- generally cannot be safely unhooked.
if registry.installed then
    hookStatus="ACTIVE (existing hook reused)"
elseif type(hookmetamethod)=="function" and
    type(getnamecallmethod)=="function" then
    local oldNamecall
    local function intercepted(self,...)
        -- Capture varargs only in the vararg function itself. This keeps the
        -- original method call intact and avoids Luau nested-vararg errors.
        if registry.enabled and
            (self==registry.target or self==registry.legacy) then
            local packed=table.pack(...)
            pcall(function()
                local method=getnamecallmethod()
                if method~="FireServer" and method~="InvokeServer" then return end
                local callback=registry.handler
                if type(callback)=="function" then
                    task.defer(function()
                        if registry.enabled and registry.handler==callback then
                            pcall(callback,self,method,packed)
                        end
                    end)
                end
            end)
        end
        return oldNamecall(self,...)
    end
    local ok,err=pcall(function()
        local wrapped=(type(newcclosure)=="function")
            and newcclosure(intercepted) or intercepted
        oldNamecall=hookmetamethod(game,"__namecall",wrapped)
    end)
    if ok and type(oldNamecall)=="function" then
        registry.installed=true
        hookStatus="ACTIVE (__namecall)"
    else
        hookStatus="FAILED: "..tostring(err):sub(1,75)
    end
else
    hookStatus="UNAVAILABLE: executor lacks hookmetamethod/getnamecallmethod"
end

registry.enabled=registry.installed
registry.handler=function(receiver,method,args)
    if not alive then return end
    attemptCount=attemptCount+1
    local now=os.clock()
    if lastAttemptAt then lastDelta=math.floor((now-lastAttemptAt)*100)/100 end
    lastAttemptAt=now
    local tag=(receiver==submit) and "AncientTrials.TrialsSubmit"
        or "AncientArc.Submit"
    local parts={}
    for i=1,math.min(args.n or #args,8) do
        local ok,text=pcall(serialize,args[i],0,{})
        parts[#parts+1]="arg"..i.."="..(ok and text or "<unreadable>")
    end
    if (args.n or #args)>8 then parts[#parts+1]="...more args" end
    local argText=table.concat(parts," | ")
    if #argText>850 then argText=argText:sub(1,850).." [truncated]" end
    lastAttempt="#"..attemptCount.." "..tag.."."..method..
        " args="..tostring(args.n or #args).." "..argText
    -- Log first eight, then every fifth call or when signature changes.
    if attemptCount<=8 or attemptCount%5==0 then
        line("OUTGOING "..lastAttempt)
    end
    display("Outgoing submission observed")
end
line("Spy ready. Start SpeedHub with Auto Submit OFF, then enable that toggle.")
line("Only these two event submission remotes are observed.")
if not submit then
    line("WARNING: AncientTrials.TrialsSubmit not found.")
end
if not registry.installed then
    line("WARNING: Outgoing remote hook unavailable; response/status only.")
end

if trials then
    for _,attribute in ipairs({"Progress","CooldownUntil","Trait"}) do
        bind(trials:GetAttributeChangedSignal(attribute),function()
            if not alive then return end
            line("ATTRIBUTE "..attribute.." -> "..
                tostring(trials:GetAttribute(attribute)))
            display(attribute.." changed")
        end)
    end
    for _,name in ipairs({"TrialsSubmitted","TrialsSync","TrialsRewards",
        "TrialsClaimed"}) do
        local r=trials:FindFirstChild(name)
        if r and r:IsA("RemoteEvent") then
            bind(r.OnClientEvent,function(...)
                if not alive then return end
                local args=table.pack(...)
                local ok,s=pcall(safeResponse,args)
                lastResponse=name.." "..(ok and s or "<unreadable>")
                line("PASSIVE "..lastResponse)
                display(name.." observed")
            end)
        end
    end
end

bind(refreshBtn.MouseButton1Click,function()
    display("Manual refresh")
end)
bind(copyBtn.MouseButton1Click,function()
    local copy=type(setclipboard)=="function" and setclipboard or
        (type(toclipboard)=="function" and toclipboard or nil)
    local ok=false
    if copy then ok=pcall(copy,report) end
    if ok then
        status.Text="Results copied! Paste them into ChatGPT."
    else
        status.Text="Clipboard unavailable; report printed to Delta console."
    end
    print(report)
end)
bind(watchBtn.MouseButton1Click,function()
    if not registry.installed then
        status.Text="Hook unavailable. Screenshot the reason in COPY RESULTS."
        return
    end
    registry.enabled=not registry.enabled
    watchBtn.Text=registry.enabled and "PAUSE WATCH" or "RESUME WATCH"
    line(registry.enabled and "Outgoing watch resumed" or "Outgoing watch paused")
    display("Watch toggle")
end)

local function close()
    if not alive then return end
    alive=false
    registry.enabled=false
    registry.handler=nil
    for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    table.clear(connections)
    pcall(function() gui:Destroy() end)
    if sharedEnv.GAG_TrialsRemoteSpy_Close==close then
        sharedEnv.GAG_TrialsRemoteSpy_Close=nil
    end
end
sharedEnv.GAG_TrialsRemoteSpy_Close=close
bind(closeBtn.MouseButton1Click,close)

local minimized=false
bind(minBtn.MouseButton1Click,function()
    minimized=not minimized
    for _,obj in ipairs({status,control,watchBtn,scroll}) do
        obj.Visible=not minimized
    end
    panel.Size=minimized and UDim2.fromOffset(width,39)
        or UDim2.fromOffset(width,height)
    minBtn.Text=minimized and "+" or "-"
end)
local dragging=false
local draggingInput=nil
local startInput,startPosition
bind(head.InputBegan,function(input)
    if input.UserInputType~=Enum.UserInputType.Touch and
        input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    dragging=true
    draggingInput=input
    startInput=Vector2.new(input.Position.X,input.Position.Y)
    startPosition=panel.Position
end)
bind(UIS.InputChanged,function(input)
    if not dragging then return end
    if input~=draggingInput and not
        (draggingInput and draggingInput.UserInputType==Enum.UserInputType.MouseButton1
        and input.UserInputType==Enum.UserInputType.MouseMovement) then return end
    local d=Vector2.new(input.Position.X,input.Position.Y)-startInput
    local v=WS.CurrentCamera and WS.CurrentCamera.ViewportSize or viewport
    panel.Position=UDim2.fromOffset(
        math.clamp(startPosition.X.Offset+d.X,0,math.max(0,v.X-width)),
        math.clamp(startPosition.Y.Offset+d.Y,0,math.max(0,v.Y-40))
    )
end)
bind(UIS.InputEnded,function(input)
    if input==draggingInput or (draggingInput and
        draggingInput.UserInputType==Enum.UserInputType.MouseButton1 and
        input.UserInputType==Enum.UserInputType.MouseButton1) then
        dragging=false
        draggingInput=nil
    end
end)
display("Initial status")
print("[GAG TRIALS REMOTE SPY V1] "..hookStatus..
    ". Only TrialsSubmit / AncientArc.Submit calls are observed.")
