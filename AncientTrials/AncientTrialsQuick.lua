-- GAG Ancient Trials V9.4.3 QUICK: READ ONLY / NO SUBMISSIONS
local p=game:GetService('Players').LocalPlayer
local ws=game:GetService('Workspace')
local uis=game:GetService('UserInputService')
local env=_G
pcall(function() if getgenv then env=getgenv() end end)
for _,key in ipairs({'GAG_Trials_V943_Stop','GAG_Trials_Lite_Stop','GAG_Trials_Quick_Stop'}) do
 if type(env[key])=='function' then pcall(env[key]) end
end
local running,links,world=true,{},{}
local lastWorld,report=0,'No scan yet'
local function on(s,f) local c=s:Connect(f);links[#links+1]=c;return c end
local function make(class,props,parent)
 local o=Instance.new(class)
 for k,v in pairs(props) do o[k]=v end
 o.Parent=parent;return o
end
local gui=make('ScreenGui',{Name='GAGTrialQuick943',ResetOnSpawn=false},p:WaitForChild('PlayerGui'))
local panel=make('Frame',{Size=UDim2.fromOffset(300,230),Position=UDim2.new(.5,-150,.15,0),BackgroundColor3=Color3.fromRGB(28,33,45)},gui)
make('UICorner',{CornerRadius=UDim.new(0,9)},panel)
local head=make('Frame',{Size=UDim2.new(1,0,0,38),BackgroundColor3=Color3.fromRGB(47,60,87)},panel)
make('TextLabel',{Size=UDim2.new(1,-80,1,0),Position=UDim2.fromOffset(9,0),BackgroundTransparency=1,Text='GAG Ancient Trials QUICK',TextSize=14,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},head)
local function button(txt,x,y,w,h)
 return make('TextButton',{Text=txt,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),TextSize=13,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(64,87,124),Font=Enum.Font.GothamBold},panel)
end
local x=button('X',269,4,26,29)
local mini=button('-',238,4,26,29)
local readout=make('TextLabel',{Text='Scanning...',Position=UDim2.fromOffset(9,45),Size=UDim2.fromOffset(282,112),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),TextSize=14,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true},panel)
local scan=button('SCAN NOW',8,166,135,37)
local copy=button('COPY RESULTS',155,166,136,37)
local hint=make('TextLabel',{Text='Read-only: no fruit submissions',Position=UDim2.fromOffset(8,207),Size=UDim2.fromOffset(280,19),BackgroundTransparency=1,TextSize=11,TextColor3=Color3.fromRGB(186,210,229)},panel)
local function stop()
 if not running then return end
 running=false
 for _,c in ipairs(links) do pcall(function() c:Disconnect() end) end
 gui:Destroy()
 if env.GAG_Trials_Quick_Stop==stop then env.GAG_Trials_Quick_Stop=nil end
end
env.GAG_Trials_Quick_Stop=stop
on(x.MouseButton1Click,stop)
local folded=false
on(mini.MouseButton1Click,function()
 folded=not folded; panel.Size=UDim2.fromOffset(300,folded and 38 or 230)
 for _,o in ipairs({readout,scan,copy,hint}) do o.Visible=not folded end
 mini.Text=folded and '+' or '-'
end)
local dragging,pos,start=false,nil,nil
on(head.InputBegan,function(i)
 if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
  dragging=true;pos=i.Position;start=panel.Position
 end
end)
on(uis.InputChanged,function(i)
 if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
  local d=i.Position-pos
  panel.Position=UDim2.new(start.X.Scale,start.X.Offset+d.X,start.Y.Scale,start.Y.Offset+d.Y)
 end
end)
on(uis.InputEnded,function(i)
 if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)
local function text(o)
 return (o.Text or ''):gsub('<[^>]*>',''):gsub('^%s+',''):gsub('%s+$','')
end
local function isText(o) return o:IsA('TextLabel') or o:IsA('TextButton') end
local function context(o)
 local root=o:FindFirstAncestorWhichIsA('BillboardGui') or o:FindFirstAncestorWhichIsA('SurfaceGui') or o.Parent
 if not root then return text(o) end
 local t={}
 for _,v in ipairs(root:GetDescendants()) do
  if isText(v) then t[#t+1]=text(v) end
  if #t>=20 then break end
 end
 return table.concat(t,' ')
end
local function fromTrial(o)
 for i=1,8 do
  if not o then break end
  if o.Name:lower():find('pharaoh') or o.Name:lower():find('trial') then return true end
  o=o.Parent
 end
 return false
end
local function refresh()
 world={}
 for i,o in ipairs(ws:GetDescendants()) do
  if isText(o) and (fromTrial(o) or text(o):lower():find('looking for',1,true) or text(o):find('/900',1,true)) then
   world[#world+1]=o
  end
  if i%1800==0 then task.wait() end
  if not running then return end
 end
 lastWorld=os.clock()
end
local busy=false
local function check(force)
 if busy or not running then return end
 busy=true
 local ok,err=pcall(function()
  if force or os.clock()-lastWorld>20 then refresh() end
  if not running then return end
  local labels={}
  for _,o in ipairs(p.PlayerGui:GetDescendants()) do
   if isText(o) and not o:IsDescendantOf(gui) then labels[#labels+1]=o end
  end
  for _,o in ipairs(world) do if o.Parent then labels[#labels+1]=o end end
  local trait,points,timer='?','?','?'
  for _,o in ipairs(labels) do
   local s=text(o)
   if trait=='?' and s:lower():find('looking for',1,true) then
    local t=(s..' '..context(o)):lower():match('looking%s+for%s+([%a%s]+)%s+plants')
    if t and #t<32 then trait=t:sub(1,1):upper()..t:sub(2) end
   end
   if points=='?' then
    local a,b=s:match('([%d,]+)%s*/%s*([%d,]+)')
    if b and tonumber(b:gsub(',',''))==900 then points=a:gsub(',','') end
   end
   if timer=='?' and fromTrial(o) then timer=s:match('^(%d?%d:%d%d)$') or timer end
  end
  local count,protected,tools=0,0,{}
  for _,root in ipairs({p:FindFirstChildOfClass('Backpack'),p.Character}) do
   if root then for _,o in ipairs(root:GetChildren()) do
    if o:IsA('Tool') then
     count=count+1
     local locked=false
     for _,k in ipairs({'Favorited','Favorite','Locked','Protected','IsFavorite','IsLocked'}) do
      if o:GetAttribute(k)==true then locked=true end
     end
     if locked then protected=protected+1 end
     if #tools<40 then tools[#tools+1]=o.Name..(locked and ' [flagged]' or '') end
    end
   end end
  end
  readout.Text=('Trait: %s\nProgress: %s/900\nTimer: %s\nBackpack/equipped tools: %d\nFlagged protected: %d'):format(trait,points,timer,count,protected)
  report=('GAG V9.4.3 QUICK (READ ONLY)\nTrait=%s Points=%s/900 Timer=%s\nTools=%d ProtectedFlags=%d\n%s'):format(trait,points,timer,count,protected,table.concat(tools,'\n'))
  hint.Text='Watching every 4s | World text every 20s'
 end)
 if not ok and running then hint.Text='Scan error: '..tostring(err) end
 busy=false
end
on(scan.MouseButton1Click,function() task.spawn(check,true) end)
on(copy.MouseButton1Click,function()
 local fn=setclipboard or toclipboard
 if type(fn)=='function' and pcall(fn,report) then hint.Text='Copied! Paste results into chat.'
 else hint.Text='Clipboard unavailable; read the panel.' end
end)
task.spawn(function() while running and gui.Parent do check(false);task.wait(4) end end)