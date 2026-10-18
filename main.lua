pcall(function()
	local ts = game:GetService("TeleportService")
	if typeof(hookfunction) == "function" then
		hookfunction(ts.Teleport, function() end)
		hookfunction(ts.TeleportToPlaceInstance, function() end)
		hookfunction(ts.TeleportAsync, function() end)
	end
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Futanaris da Piroca Ereta",
   LoadingTitle = "Anime F̶U̶T̶A̶N̶A̶R̶I̶ Zero",
   LoadingSubtitle = "Roubando dados...",
   ConfigurationSaving = {
      Enabled = false,
   },
   KeySystem = false,
   Theme = "Amethyst",
})

local MainTab = Window:CreateTab("Main", 4483362458)
local TeleportsTab = Window:CreateTab("Teleports", 4483362458)
local SkillsTab = Window:CreateTab("Skills", 4483362458)
local DungeonTab = Window:CreateTab("AUTO CHISA DUNGEON", 4483362458)
local SecurityTab = Window:CreateTab("Security", 4483362458)
local DonateTab = Window:CreateTab("Donate", 4483362458)

for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
	if gui.Name == "VovoNinjaStoryGui" or gui.Name == "FloatingDonateGui" or gui.Name == "UmamusumeHubGui" then gui:Destroy() end
end
local pGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
if pGui then
	for _, gui in ipairs(pGui:GetChildren()) do
		if gui.Name == "VovoNinjaStoryGui" or gui.Name == "FloatingDonateGui" or gui.Name == "UmamusumeHubGui" then gui:Destroy() end
	end
end

local env = (typeof(getgenv) == "function" and getgenv()) or _G
if env.VovoNinjaCleanup then
	pcall(env.VovoNinjaCleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local connections = {}
local running = true
local function track(conn)
	table.insert(connections, conn)
	return conn
end

env.VovoNinjaCleanup = function()
	running = false
	for _, c in ipairs(connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(connections)
end

local _G_SecurityEnabled = false
local _G_MaxPlayers = 1
local ejecting = false

local function overLimit()
	return _G_SecurityEnabled and #Players:GetPlayers() > _G_MaxPlayers
end

local function emergencyEject()
	if not _G_SecurityEnabled or ejecting then return end
	ejecting = true
	pcall(function()
		LocalPlayer:Kick("Um ADM veio aqui. Mas eu te tirei daqui, cê tá seguro, eu acho.")
	end)
	pcall(function()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end)
end

task.spawn(function()
	while running do
		task.wait(0.1)
		if overLimit() then
			emergencyEject()
		end
	end
end)

track(Players.PlayerAdded:Connect(function(player)
	if overLimit() then
		emergencyEject()
	end
end))

local _G_Active = false
local DG = {Lever = false, Doors = false, Kill = false, Toggles = {}}
local _G_KillAura = false
local _G_KillAuraRange = 200
local _G_Distance = 6
local _G_Radius = 80
local _G_Mode = "atrás"
local _G_WaveDelay = 1.5
local _G_AntiAFK = true
local _G_AutoSkip = false
local _G_AutoRetry = true
local _G_TInterval = 10
local _G_Skills = {
	M1 = true,
	One = true,
	Two = true,
	Three = true,
	T = false,
	G = true
}

local MAX_AREA = 5
local M1_INTERVAL = 0.35
local TARGET_TIMEOUT = 30
local NO_PROGRESS_TIMEOUT = 10
local ROCK_NO_PROGRESS_TIMEOUT = 3.0
local ROCK_GAP = 3.5

local currentArea = 1
local arrived = false
local enemiesEncountered = false
local storyDone = false
local endScreenShown = false
local endAttempt = 0
local currentTarget = nil
local currentKind = nil
local targetDir = Vector3.new(0, 0, 1)
local targetSince = 0
local targetLastHP = 0
local targetLastChange = 0
local blacklist = {}
local lastEnemyTime = 0
local tSpamming = false
local finishedTime = 0

local lastM1 = 0
local lastSkillsTime = 0
local lastTTime = 0
local lastGTime = 0
local lastScan = 0

track(LocalPlayer.Idled:Connect(function()
	if _G_AntiAFK then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end))

local function getRoot()
	local c = LocalPlayer.Character
	return c and c:FindFirstChild("HumanoidRootPart"), c
end

local function triggerM1()
	local vp = Camera.ViewportSize
	local centerX = vp.X / 2
	local centerY = vp.Y / 2

	if VirtualInputManager then
		VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
		task.wait(0.03)
		VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
	else
		VirtualUser:CaptureController()
		VirtualUser:ClickButton1(Vector2.new(centerX, centerY))
	end
end

local function pressKey(key, hold)
	VirtualInputManager:SendKeyEvent(true, key, false, game)
	task.wait(hold)
	VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function isNum(v)
	return v == v and v ~= math.huge and v ~= -math.huge
end

local function isVec3Ok(v)
	return v ~= nil and isNum(v.X) and isNum(v.Y) and isNum(v.Z)
end

local function isReallyVisible(gui)
	if not gui then return false end
	local node = gui
	while node and not node:IsA("ScreenGui") do
		if node:IsA("GuiObject") and not node.Visible then return false end
		node = node.Parent
	end
	if not node or not node.Enabled then return false end
	return gui.AbsoluteSize.X > 0
end

local function getEndButtons()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local endScreen = playerGui and playerGui:FindFirstChild("EndScreen")
	local holder = endScreen and endScreen:FindFirstChild("Holder")
	local constrained = holder and holder:FindFirstChild("ConstraintedHolder")
	local buttonsHolder = constrained and constrained:FindFirstChild("ButtonsHolder")
	if not buttonsHolder then return nil, nil end

	local retryB = buttonsHolder:FindFirstChild("RetryButton")
	local nextB = buttonsHolder:FindFirstChild("NextButton")

	if retryB and not isReallyVisible(retryB) then retryB = nil end
	if nextB and not isReallyVisible(nextB) then nextB = nil end
	return retryB, nextB
end

local function clickGuiButton(btn, attempt)
	if attempt % 2 == 1 and typeof(firesignal) == "function" then
		local ok1 = pcall(function() firesignal(btn.MouseButton1Click) end)
		pcall(function() firesignal(btn.Activated) end)
		if ok1 then return end
	end

	local pos = btn.AbsolutePosition
	local size = btn.AbsoluteSize
	local inset = GuiService:GetGuiInset()
	
	local clickX = pos.X + (size.X / 2)
	local clickY = pos.Y + (size.Y / 2) + inset.Y

	if VirtualInputManager then
		VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
		task.wait(0.02)
		VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
	else
		VirtualUser:CaptureController()
		VirtualUser:ClickButton1(Vector2.new(clickX, clickY))
	end
end

local function resetRun()
	currentArea = 1
	arrived = false
	enemiesEncountered = false
	storyDone = false
	currentTarget = nil
	currentKind = nil
	blacklist = {}
	lastEnemyTime = tick()
	finishedTime = 0
end

task.spawn(function()
	while running do
		task.wait(0.15)

		pcall(function()
			local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
			local startVote = playerGui and playerGui:FindFirstChild("StartVote")
			local holder = startVote and startVote:FindFirstChild("Holder")
			local main = holder and holder:FindFirstChild("Main")
			local startBtn = main and main:FindFirstChild("StartButton")
			local targetClick = startBtn and startBtn:FindFirstChild("Txt(Shadow)") or startBtn
			if targetClick and isReallyVisible(targetClick) then
				clickGuiButton(targetClick, 1)
			end
		end)

		local retryB, nextB = getEndButtons()
		if retryB or nextB then
			endScreenShown = true
			endAttempt = endAttempt + 1

			if _G_AutoRetry and retryB then
				clickGuiButton(retryB, endAttempt)
			elseif _G_AutoSkip and nextB then
				clickGuiButton(nextB, endAttempt)
			end
		else
			if endScreenShown then
				endScreenShown = false
				endAttempt = 0
				resetRun()
			end
		end
	end
end)

local function getAreasFolder()
	local world = workspace:FindFirstChild("World")
	return world and world:FindFirstChild("Areas")
end

local function findArea(n)
	local folder = getAreasFolder()
	if not folder then return nil end

	local exact = folder:FindFirstChild(tostring(n))
	if exact then return exact end

	for _, child in ipairs(folder:GetChildren()) do
		if child.Name:match("%d+") == tostring(n) then
			return child
		end
	end
	return nil
end

local function getMapFolder()
	local world = workspace:FindFirstChild("World")
	return world and world:FindFirstChild("Map")
end

local function getInstPos(inst)
	if not inst then return nil end
	if inst:IsA("BasePart") then return inst.Position end
	if inst:IsA("Model") then return inst:GetPivot().Position end
	if inst:IsA("Attachment") then return inst.WorldPosition end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then
			return d.Position
		end
	end
	return nil
end

local function touchArea(inst, root)
	if typeof(firetouchinterest) ~= "function" then return end

	local parts = {}
	if inst:IsA("BasePart") then table.insert(parts, inst) end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") and #parts < 10 then
			table.insert(parts, d)
		end
	end

	for _, p in ipairs(parts) do
		pcall(function()
			firetouchinterest(root, p, 0)
			firetouchinterest(root, p, 1)
		end)
	end
end

local function getBounds(t)
	if t:IsA("Model") then
		local cf = t:GetBoundingBox()
		return cf, t:GetExtentsSize()
	end
	if t:IsA("BasePart") then
		return t.CFrame, t.Size
	end
	return nil, nil
end

local function edgeDistance(t, fromPos)
	local cf, size = getBounds(t)
	if not cf or not isVec3Ok(cf.Position) or not isVec3Ok(size) then return nil end
	local r = math.max(size.X, size.Z) / 2
	return math.max(0, (cf.Position - fromPos).Magnitude - r)
end

local function resolveTarget(part, char)
	local node = part
	while node and node ~= workspace do
		if node:IsA("Model") and node ~= char then
			local hum = node:FindFirstChildOfClass("Humanoid")
			if hum and hum.MaxHealth > 0 and hum.Health > 0 and not Players:GetPlayerFromCharacter(node) then
				return node, "npc"
			end
		end
		node = node.Parent
	end
	return nil
end

local function scanForAreaRubbleParts()
	local mapFolder = getMapFolder()
	if not mapFolder then return nil end

	local border = mapFolder:FindFirstChild("Border" .. tostring(currentArea))
	if border then
		local rubbleFolder = border:FindFirstChild("Rubble")
		if rubbleFolder then
			local children = rubbleFolder:GetChildren()
			table.sort(children, function(a, b) return a.Name < b.Name end)
			for _, child in ipairs(children) do
				if not blacklist[child] and child:IsDescendantOf(workspace) then
					return child
				end
			end
		end
	end

	return nil
end

local function isTargetValid(target, kind, root)
	if not target or not target.Parent or blacklist[target] then return false end
	if not target:IsDescendantOf(workspace) then return false end
	
	if kind == "rock" then
		return true
	end

	local hum = target:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end

	local maxRadius = _G_KillAura and _G_KillAuraRange or (_G_Radius * 1.5)
	local d = edgeDistance(target, root.Position)
	if not d or d > maxRadius then return false end
	return true
end

local function scanForTarget(root, char)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}

	local scanRadius = _G_KillAura and _G_KillAuraRange or _G_Radius
	local parts = workspace:GetPartBoundsInRadius(root.Position, scanRadius, params)
	local bestNpc, bestNpcDist = nil, math.huge
	local seen = {}

	for _, part in ipairs(parts) do
		local t, kind = resolveTarget(part, char)
		if t and kind == "npc" and not blacklist[t] and not seen[t] then
			seen[t] = true
			local d = edgeDistance(t, root.Position)
			if d and d < bestNpcDist then
				bestNpc, bestNpcDist = t, d
			end
		end
	end

	if bestNpc then return bestNpc, "npc" end

	if not _G_KillAura then
		local rubblePartTarget = scanForAreaRubbleParts()
		if rubblePartTarget then
			return rubblePartTarget, "rock"
		end
	end

	return nil, nil
end

local function getPivotCF(t)
	if t:IsA("Model") then return t:GetPivot() end
	if t:IsA("BasePart") then return t.CFrame end
	return nil
end

local function getCamSubject(t)
	if t:IsA("Model") then
		local hum = t:FindFirstChildOfClass("Humanoid")
		if hum then return hum end
		return t.PrimaryPart or t:FindFirstChildWhichIsA("BasePart", true)
	end
	if t:IsA("BasePart") then return t end
	return nil
end

local KillAuraToggle
local StoryToggle

KillAuraToggle = MainTab:CreateToggle({
   Name = "OLHAR ME MIL JARDAS DO ANJO CAÍDO (Kill Aura)",
   CurrentValue = false,
   Flag = "KillAuraFlag",
   Callback = function(Value)
      if Value and not _G_SecurityEnabled then
         _G_KillAura = false
         if KillAuraToggle then KillAuraToggle:Set(false) end
         pcall(function()
            Rayfield:Notify({Title = "Segurança desligada", Content = "Ligue o Sistema de Segurança na aba Security antes de usar o Kill Aura.", Duration = 5})
         end)
         return
      end
      if Value and (DG.Lever or DG.Doors or DG.Kill) then
         _G_KillAura = false
         if KillAuraToggle then KillAuraToggle:Set(false) end
         pcall(function()
            Rayfield:Notify({Title = "Auto Dungeon ligado", Content = "Desligue o Auto Dungeon antes de usar o Kill Aura.", Duration = 5})
         end)
         return
      end
      _G_KillAura = Value
      if Value and _G_Active then
         _G_Active = false
         if StoryToggle then StoryToggle:Set(false) end
      end
   end,
})

MainTab:CreateSection("Use o kill aura APENAS nos modos TRIAL, INFINITE e RAID SHADOW GATE.")

MainTab:CreateSlider({
   Name = "Alcance",
   Range = {0, 1000},
   Increment = 10,
   CurrentValue = 200,
   Flag = "KillAuraRangeSlider",
   Callback = function(Value)
      _G_KillAuraRange = Value
   end,
})

MainTab:CreateSection("se você odeia o modo história, use as funções abaixo")

StoryToggle = MainTab:CreateToggle({
   Name = "Se tornar o Bolsonaro Hipotético e Obliterar o modo história",
   CurrentValue = false,
   Flag = "ActiveFarm",
   Callback = function(Value)
      if Value and not _G_SecurityEnabled then
         _G_Active = false
         if StoryToggle then StoryToggle:Set(false) end
         pcall(function()
            Rayfield:Notify({Title = "Segurança desligada", Content = "Ligue o Sistema de Segurança na aba Security antes de usar o Autofarm.", Duration = 5})
         end)
         return
      end
      if Value and (DG.Lever or DG.Doors or DG.Kill) then
         _G_Active = false
         if StoryToggle then StoryToggle:Set(false) end
         pcall(function()
            Rayfield:Notify({Title = "Auto Dungeon ligado", Content = "Desligue o Auto Dungeon antes de usar o Autofarm.", Duration = 5})
         end)
         return
      end
      _G_Active = Value
      if Value then
         if _G_KillAura then
            _G_KillAura = false
            if KillAuraToggle then KillAuraToggle:Set(false) end
         end
         if currentArea > MAX_AREA then currentArea = 1 end
         arrived = false
         enemiesEncountered = false
         storyDone = false
         blacklist = {}
         currentTarget = nil
         lastEnemyTime = tick()
         finishedTime = 0
      else
         currentTarget = nil
         currentKind = nil
         local _, char = getRoot()
         local hum = char and char:FindFirstChildOfClass("Humanoid")
         if hum then Camera.CameraSubject = hum end
      end
   end,
})

MainTab:CreateToggle({
   Name = "Anti-AFK",
   CurrentValue = true,
   Flag = "AntiAFK",
   Callback = function(Value)
      _G_AntiAFK = Value
   end,
})

MainTab:CreateToggle({
   Name = "Auto Skip",
   CurrentValue = false,
   Flag = "AutoSkip",
   Callback = function(Value)
      _G_AutoSkip = Value
   end,
})

MainTab:CreateToggle({
   Name = "Auto Retry",
   CurrentValue = true,
   Flag = "AutoRetry",
   Callback = function(Value)
      _G_AutoRetry = Value
   end,
})

MainTab:CreateSection("Configurações")

MainTab:CreateDropdown({
   Name = "Modo de Posicionamento",
   Options = {"ANAL (Atrás)", "ORAL (em cima)", "VAGINAL (Abaixo)"},
   CurrentOption = "ANAL (Atrás)",
   Flag = "ModeDropdown",
   Callback = function(Option)
      if type(Option) == "table" then Option = Option[1] end
      if Option == "ORAL (em cima)" then
         _G_Mode = "acima"
      elseif Option == "ANAL (Atrás)" then
         _G_Mode = "atrás"
      elseif Option == "VAGINAL (Abaixo)" then
         _G_Mode = "abaixo"
      end
   end,
})

MainTab:CreateSlider({
   Name = "Distância dos NPCs",
   Range = {0, 20},
   Increment = 1,
   CurrentValue = 6,
   Flag = "DistanceSlider",
   Callback = function(Value)
      _G_Distance = Value
   end,
})

MainTab:CreateSlider({
   Name = "Espera de Ondas (s)",
   Range = {0, 10},
   Increment = 0.5,
   CurrentValue = 1.5,
   Flag = "WaveDelaySlider",
   Callback = function(Value)
      _G_WaveDelay = Value
   end,
})

TeleportsTab:CreateSection("Seleção Rápida de Área")
for i = 1, MAX_AREA do
	TeleportsTab:CreateButton({
	   Name = "Teleportar para Área " .. i,
	   Callback = function()
		  currentArea = i
		  arrived = false
		  enemiesEncountered = false
		  storyDone = false
		  currentTarget = nil
		  lastEnemyTime = tick()
		  teleportToArea(i)
	   end,
	})
end

SkillsTab:CreateSection("Golpes Ativos")

SkillsTab:CreateToggle({
   Name = "M1 (Ataque Básico)",
   CurrentValue = true,
   Flag = "SkillM1",
   Callback = function(Value)
      _G_Skills.M1 = Value
   end,
})

SkillsTab:CreateToggle({
   Name = "Skill 1",
   CurrentValue = true,
   Flag = "SkillOne",
   Callback = function(Value)
      _G_Skills.One = Value
   end,
})

SkillsTab:CreateToggle({
   Name = "Skill 2",
   CurrentValue = true,
   Flag = "SkillTwo",
   Callback = function(Value)
      _G_Skills.Two = Value
   end,
})

SkillsTab:CreateToggle({
   Name = "Skill 3",
   CurrentValue = true,
   Flag = "SkillThree",
   Callback = function(Value)
      _G_Skills.Three = Value
   end,
})

SkillsTab:CreateToggle({
   Name = "Skill T",
   CurrentValue = false,
   Flag = "SkillT",
   Callback = function(Value)
      _G_Skills.T = Value
   end,
})

SkillsTab:CreateToggle({
   Name = "Skill G",
   CurrentValue = true,
   Flag = "SkillG",
   Callback = function(Value)
      _G_Skills.G = Value
   end,
})

SkillsTab:CreateSection("Configuração de Tempo")

SkillsTab:CreateSlider({
   Name = "Tempo da Skill T (Segundos)",
   Range = {1, 60},
   Increment = 1,
   CurrentValue = 10,
   Flag = "TSlider",
   Callback = function(Value)
      _G_TInterval = Value
   end,
})

SecurityTab:CreateSection("Proteção contra Intrusos e ADMs")

SecurityTab:CreateToggle({
   Name = "Ligar/Desligar Sistema de Segurança",
   CurrentValue = false,
   Flag = "SecurityToggle",
   Callback = function(Value)
      _G_SecurityEnabled = Value
      if not Value then
         _G_KillAura = false
         _G_Active = false
         if KillAuraToggle then KillAuraToggle:Set(false) end
         if StoryToggle then StoryToggle:Set(false) end
         DG.Lever, DG.Doors, DG.Kill = false, false, false
         for _, t in pairs(DG.Toggles) do
            pcall(function() t:Set(false) end)
         end
      end
   end,
})

SecurityTab:CreateDropdown({
   Name = "Máximo de Jogadores no servidor (contando você)",
   Options = {"1", "2", "3", "4", "5", "6"},
   CurrentOption = "1",
   Flag = "MaxPlayersDropdown",
   Callback = function(Option)
      local v = Option
      if type(v) == "table" then v = v[1] end
      _G_MaxPlayers = tonumber(v) or _G_MaxPlayers
   end,
})

DonateTab:CreateSection("Apoie o Projeto")
DonateTab:CreateParagraph({Title = "Chave Pix", Content = "lolizinhatrap214@gmail.com"})

local function triggerPrank()
	local prankGui = Instance.new("ScreenGui")
	prankGui.Name = "GokuPrankGui"
	prankGui.IgnoreGuiInset = true
	prankGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function() prankGui.Parent = game:GetService("CoreGui") end)
	if not prankGui.Parent then prankGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.Parent = prankGui

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, 0, 0, 60)
	txt.Position = UDim2.new(0, 0, 0.8, 0)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.SourceSansBold
	txt.Text = "Durma de olhos abertos hoje..."
	txt.TextColor3 = Color3.fromRGB(255, 0, 0)
	txt.TextSize = 36
	txt.Parent = prankGui

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://5077336384"
	sound.Volume = 10
	sound.Parent = workspace
	pcall(function() sound:Play() end)

	task.delay(4, function()
		pcall(function() sound:Stop(); sound:Destroy() end)
		pcall(function() prankGui:Destroy() end)
	end)
end

local DonateScreenGui = Instance.new("ScreenGui")
DonateScreenGui.Name = "FloatingDonateGui"
DonateScreenGui.ResetOnSpawn = false
pcall(function() DonateScreenGui.Parent = game:GetService("CoreGui") end)
if not DonateScreenGui.Parent then DonateScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local DonateFrame = Instance.new("Frame")
DonateFrame.Name = "DonateFrame"
DonateFrame.Parent = DonateScreenGui
DonateFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
DonateFrame.Position = UDim2.new(0.02, 0, 0.72, 0)
DonateFrame.Size = UDim2.new(0, 280, 0, 85)
DonateFrame.Active = true
DonateFrame.Draggable = true

local DonateText = Instance.new("TextLabel")
DonateText.Parent = DonateFrame
DonateText.BackgroundTransparency = 1
DonateText.Size = UDim2.new(1, -24, 1, 0)
DonateText.Position = UDim2.new(0, 8, 0, 0)
DonateText.Font = Enum.Font.SourceSansBold
DonateText.Text = "Faz o pix pra ajudar :D\n\nlolizinhatrap214@gmail.com"
DonateText.TextColor3 = Color3.fromRGB(100, 255, 150)
DonateText.TextSize = 13
DonateText.TextWrapped = true

local CloseDonate = Instance.new("TextButton")
CloseDonate.Parent = DonateFrame
CloseDonate.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseDonate.Position = UDim2.new(1, -22, 0, 4)
CloseDonate.Size = UDim2.new(0, 18, 0, 18)
CloseDonate.Font = Enum.Font.SourceSansBold
CloseDonate.Text = "X"
CloseDonate.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseDonate.TextSize = 11

CloseDonate.MouseButton1Click:Connect(function()
	DonateScreenGui:Destroy()
	triggerPrank()
end)

-- ============================================================
-- FULL CHISA DUNGEON  (Kill All > Alavanca > Zona da FloodGateMarker > Subir pro Boss)
-- ============================================================
local DG_LEVER_NAME = "CONS_LEVER"
local DG_SWEEP_PAUSE = 12

DG.ZoneRadius = 20
DG.ZoneHeight = 2
DG.KillRange = 400
DG.FarRange = 3000       -- busca longa (só com zona ativa) quando não há inimigo perto
DG.farCache = nil
DG.LeverReach = 12
DG.MaxExcursion = 8
DG.Grace = 8
DG.AscentSpeed = 40
DG.AscentMax = 400
DG.NoProgress = 6        -- desiste do alvo se o HP não mexer por X s
DG.MaxFight = 120        -- teto absoluto por alvo (s), mesmo com HP mexendo
DG.AscentTries = 0
DG.AscentTriesMax = 2    -- quantas subidas completas antes de desistir
DG.PostKillPause = 2     -- pausa antes de voltar a subir depois de matar algo
DG.lastActivity = 0      -- última vez que fez algo útil (lutar, alavanca, zona)
DG.IdleBeforeAscent = 6  -- fica PARADO procurando por X s antes de subir
DG.AscentHold = 4        -- a cada degrau da subida, para X s procurando
DG.AscentStep = 60       -- altura de cada degrau (studs)
DG.Click = false
DG.ClickInterval = 1
DG.status = "Desligado"
DG.marker = nil
DG.markerPos = nil
DG.goneAt = nil
DG.sweepPause = 0
DG.ascent = nil
DG.ascentPause = 0
DG.progress = 0
DG.endSeen = false
DG.doneZones = {}
DG.doneLevers = setmetatable({}, {__mode = "k"})
DG.mLever = setmetatable({}, {__mode = "k"})
DG.sweepDone = setmetatable({}, {__mode = "k"})
DG.sweepTries = setmetatable({}, {__mode = "k"})
DG.leverFail = setmetatable({}, {__mode = "k"})
DG.badEnemy = setmetatable({}, {__mode = "k"})
DG.badCount = setmetatable({}, {__mode = "k"})
DG.cache = {levers = {}, t = 0}

local function dgNotify(title, content)
	pcall(function()
		Rayfield:Notify({Title = title, Content = content, Duration = 5})
	end)
end

local function dgPos(inst)
	if not inst then return nil end
	if inst:IsA("ProximityPrompt") then inst = inst.Parent end
	return getInstPos(inst)
end

local function dgAlive()
	local root, char = getRoot()
	if not root or not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return nil end
	return root, char, hum
end

local function dgTP(pos)
	local root = dgAlive()
	if not root or not isVec3Ok(pos) then return false end
	root.CFrame = CFrame.new(pos)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	return true
end

local function dgClear(t)
	for k in pairs(t) do t[k] = nil end
end

-- zera a blacklist temporária (fase concluída / retry / botão)
local function dgReset()
	DG.marker = nil
	DG.markerPos = nil
	DG.goneAt = nil
	DG.sweepPause = 0
	DG.ascent = nil
	DG.ascentPause = 0
	DG.progress = 0
	DG.doneZones = {}
	dgClear(DG.doneLevers)
	dgClear(DG.mLever)
	dgClear(DG.sweepDone)
	dgClear(DG.sweepTries)
	dgClear(DG.leverFail)
	dgClear(DG.badEnemy)
	dgClear(DG.badCount)
	DG.ascentTries = 0
	DG.cache.t = 0
	DG.cache.levers = {}
	DG.farCache = nil
	DG.lastActivity = tick()
end

-- A marcação que define a zona CERTA (some quando o objetivo é concluído).
-- Ignora marcações em cima de zonas já concluídas (blacklist) e prefere a que já estava em uso.
local function dgFindMarker(fromPos)
	local w = workspace:FindFirstChild("World")
	local mo = w and w:FindFirstChild("MapObjects")
	local zone = mo and mo:FindFirstChild("FloodGateZone")
	if not zone then return nil end

	local best, bestPos, bestD = nil, nil, math.huge
	local current, currentPos
	for _, d in ipairs(zone:GetDescendants()) do
		if d.Name == "FloodGateMarker" and d:IsDescendantOf(workspace) then
			local pos = dgPos(d) or dgPos(zone)
			if pos and isVec3Ok(pos) then
				local skip = false
				for _, z in ipairs(DG.doneZones) do
					if (z - pos).Magnitude <= 10 then skip = true break end
				end
				if not skip then
					if d == DG.marker then current, currentPos = d, pos end
					local dist = fromPos and (pos - fromPos).Magnitude or 0
					if dist < bestD then best, bestPos, bestD = d, pos, dist end
				end
			end
		end
	end
	if current then return current, currentPos end
	return best, bestPos
end

-- estou dentro da zona? (raio ao redor da marcação OU dentro do volume dela)
local function dgInZone(marker, mpos)
	local root = dgAlive()
	if not root then return false end
	local p = root.Position
	if (p - mpos).Magnitude <= DG.ZoneRadius then return true end
	local cf, size = getBounds(marker)
	if cf and size and isVec3Ok(cf.Position) and isVec3Ok(size) then
		local rel = cf:PointToObjectSpace(p)
		if math.abs(rel.X) <= size.X / 2 + 2
			and math.abs(rel.Y) <= size.Y / 2 + 8
			and math.abs(rel.Z) <= size.Z / 2 + 2 then
			return true
		end
	end
	return false
end

local function dgReturnToZone(marker, mpos, stand)
	for _ = 1, 6 do
		if not (running and DG.Doors) then return false end
		if not marker.Parent then return false end
		dgTP(stand)
		task.wait(0.15)
		if dgInZone(marker, mpos) then return true end
	end
	return false
end

-- Varre o mapa procurando TODAS as CONS_LEVER (por nome, sem depender de índice)
local function dgCollectLevers(base, out)
	for _, d in ipairs(base:GetDescendants()) do
		if d.Name == DG_LEVER_NAME and not d:FindFirstAncestor(DG_LEVER_NAME) then
			table.insert(out, d)
		end
	end
end

local function dgRefresh(force)
	local now = tick()
	-- cache vazio ou com alavanca destruída (mapa novo / nova run): reescaneia logo
	local stale = #DG.cache.levers == 0
	if not stale then
		for _, l in ipairs(DG.cache.levers) do
			if not (l.Parent and l:IsDescendantOf(workspace)) then stale = true break end
		end
	end
	if not force and now - DG.cache.t < (stale and 1.5 or (DG.ascent and 2 or 8)) then return end
	DG.cache.t = now

	local levers = {}
	local map = getMapFolder()
	if map then dgCollectLevers(map, levers) end
	-- não achou no Map: procura no World inteiro (MapObjects etc.)
	if #levers == 0 then
		local world = workspace:FindFirstChild("World")
		if world then dgCollectLevers(world, levers) end
	end
	-- último recurso: workspace todo (pesado, então no máx. a cada 10s)
	if #levers == 0 and now - (DG.cache.wideT or 0) >= 10 then
		DG.cache.wideT = now
		dgCollectLevers(workspace, levers)
	end
	-- fallback: o índice 339, caso o scan por nome não ache nada
	if #levers == 0 then
		local c = map and map:GetChildren()[339]
		if c then
			local inner = (c.Name == DG_LEVER_NAME) and c or c:FindFirstChild(DG_LEVER_NAME, true)
			if inner then table.insert(levers, inner) end
		end
	end
	DG.cache.levers = levers
end

local function dgNearest(list, pos, ignore)
	local best, bestD = nil, math.huge
	for _, inst in ipairs(list) do
		if inst.Parent and inst:IsDescendantOf(workspace) and not (ignore and ignore(inst)) then
			local p = dgPos(inst)
			if p and isVec3Ok(p) then
				local d = (p - pos).Magnitude
				if d < bestD then best, bestD = inst, d end
			end
		end
	end
	return best, bestD
end

local function dgPrompt(lever)
	if lever:IsA("ProximityPrompt") then return lever end
	return lever:FindFirstChildWhichIsA("ProximityPrompt", true)
end

-- alavanca ainda utilizável? (fora da blacklist e com prompt ligado)
local function dgLeverUsable(lever)
	if DG.doneLevers[lever] then return false end
	local p = dgPrompt(lever)
	if p and p.Parent and not p.Enabled then return false end
	return true
end

local function dgSweepIgnore(lever)
	return DG.sweepDone[lever] or (DG.leverFail[lever] or 0) > tick() or not dgLeverUsable(lever)
end

-- "impressão digital" da alavanca: se mudar depois de interagir, a interação funcionou
local function dgFingerprint(inst, prompt)
	local out = {}
	local list = {}
	if inst:IsA("BasePart") then table.insert(list, inst) end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(list, d)
			if #list >= 15 then break end
		end
	end
	for _, p in ipairs(list) do
		local c = p.CFrame
		table.insert(out, string.format("%.2f,%.2f,%.2f,%.2f,%.2f,%.2f|%s|%.2f|%s",
			c.X, c.Y, c.Z, c.LookVector.X, c.LookVector.Y, c.LookVector.Z,
			tostring(p.Color), p.Transparency, tostring(p.CanCollide)))
	end
	local keys = {}
	local attrs = inst:GetAttributes()
	for k in pairs(attrs) do table.insert(keys, k) end
	table.sort(keys)
	for _, k in ipairs(keys) do table.insert(out, k .. "=" .. tostring(attrs[k])) end
	if prompt then
		table.insert(out, "prompt=" .. tostring(prompt.Parent ~= nil) .. tostring(prompt.Enabled) .. prompt.ActionText)
	end
	return table.concat(out, ";")
end

-- verificação: estou perto de uma CONS_LEVER?
local function dgNearLever(pos)
	local root = dgAlive()
	if not root then return false end
	if (root.Position - pos).Magnitude > DG.LeverReach then return false end
	local _, nd = dgNearest(DG.cache.levers, root.Position)
	return nd <= DG.LeverReach
end

local function dgHoldKey(key, seconds, stayPos)
	pcall(function() VirtualInputManager:SendKeyEvent(true, key, false, game) end)
	local t0 = tick()
	while tick() - t0 < seconds and running and DG.Lever do
		local root = dgAlive()
		if root and stayPos and (root.Position - stayPos).Magnitude > DG.LeverReach then
			dgTP(stayPos)
		end
		task.wait(0.05)
	end
	pcall(function() VirtualInputManager:SendKeyEvent(false, key, false, game) end)
end

-- TP na alavanca + segurar E, com várias camadas de verificação
-- retorna: resultado ("ok"/"fail"/"abort"), nota, confirmado (true/false)
local function dgDoLever(lever)
	local pos = dgPos(lever)
	if not pos or not isVec3Ok(pos) then return "fail", "alavanca sem posição", false end
	local standPos = pos + Vector3.new(0, 3, 0)
	local prompt = dgPrompt(lever)

	local arrived = false
	for attempt = 1, 6 do
		if not (running and DG.Lever) then return "abort" end
		DG.status = string.format("Indo até a alavanca (tentativa %d/6)", attempt)
		dgTP(standPos)
		task.wait(0.2)
		if dgNearLever(pos) then
			task.wait(0.25)
			if dgNearLever(pos) then arrived = true break end
		end
	end
	if not arrived then return "fail", "não consegui chegar perto da alavanca", false end

	if prompt and prompt.Parent and not prompt.Enabled then
		return "ok", "alavanca já estava usada", true
	end

	local key = Enum.KeyCode.E
	if prompt and prompt.KeyboardKeyCode ~= Enum.KeyCode.Unknown then key = prompt.KeyboardKeyCode end
	local hold = prompt and prompt.HoldDuration or 0.5
	local before = dgFingerprint(lever, prompt)

	for attempt = 1, 3 do
		if not (running and DG.Lever) then return "abort" end
		if not dgNearLever(pos) then dgTP(standPos) task.wait(0.2) end
		DG.status = string.format("Segurando %s na alavanca (tentativa %d/3)", key.Name, attempt)

		if attempt == 2 and prompt and typeof(fireproximityprompt) == "function" then
			local old = prompt.HoldDuration
			pcall(function() prompt.HoldDuration = 0 end)
			pcall(fireproximityprompt, prompt)
			task.wait(0.2)
			pcall(function() prompt.HoldDuration = old end)
		else
			local mult = (attempt == 3) and 2 or 1
			dgHoldKey(key, math.max(hold, 0.4) * mult + 0.35, standPos)
		end

		task.wait(0.4)
		if not lever.Parent then return "ok", "alavanca sumiu (acionada)", true end
		if dgFingerprint(lever, prompt) ~= before then
			return "ok", "interação confirmada", true
		end
	end
	return "ok", "sem confirmação visual", false
end

-- ---------------- combate ----------------
local dgLastM1, dgLastSkills, dgLastT, dgLastG, dgTSpam = 0, 0, 0, 0, false

local function dgAttack(now, skillGap)
	skillGap = skillGap or 1.5
	if _G_Skills.M1 and now - dgLastM1 >= M1_INTERVAL then
		dgLastM1 = now
		task.spawn(triggerM1)
	end
	if now - dgLastSkills >= skillGap then
		dgLastSkills = now
		task.spawn(function()
			if _G_Skills.One then pressKey(Enum.KeyCode.One, 0.02) end
			if _G_Skills.Two then pressKey(Enum.KeyCode.Two, 0.02) end
			if _G_Skills.Three then pressKey(Enum.KeyCode.Three, 0.02) end
		end)
	end
	if now - dgLastT >= _G_TInterval and not dgTSpam then
		dgLastT = now
		dgTSpam = true
		task.spawn(function()
			local startT = tick()
			while tick() - startT < 2.4 and DG.Kill and _G_Skills.T do
				pressKey(Enum.KeyCode.T, 0.05)
				task.wait(0.1)
			end
			dgTSpam = false
		end)
	end
	if now - dgLastG >= 30 then
		dgLastG = now
		task.spawn(function()
			if _G_Skills.G then pressKey(Enum.KeyCode.G, 0.02) end
		end)
	end
end

-- Posiciona perto do alvo SEM distinção de boss/NPC.
-- Direção fixada no mundo no começo da luta (não gira junto com o alvo)
-- e só teleporta quando o alvo se afasta além da tolerância (sem TP a cada frame).
local function dgPlaceAt(enemy, fs)
	local root = dgAlive()
	if not root then return end

	local center, radius, halfH = nil, 0, 0
	local bcf, bsize = getBounds(enemy)
	if bcf and isVec3Ok(bcf.Position) and isVec3Ok(bsize) then
		center = bcf.Position
		radius = math.min(math.max(bsize.X, bsize.Z) / 2, 60)
		halfH = math.min(bsize.Y / 2, 60)
	else
		local cf = getPivotCF(enemy)
		if not cf or not isVec3Ok(cf.Position) then return end
		center = cf.Position
	end

	local dist = math.max(_G_Distance, radius + 2)
	local desired
	if _G_Mode == "atrás" then
		desired = center + fs.dir * dist
	elseif _G_Mode == "acima" then
		desired = center + Vector3.new(0, math.max(_G_Distance, halfH + 2), 0)
	else
		desired = center - Vector3.new(0, math.max(_G_Distance, halfH + 2), 0)
	end
	if not isVec3Ok(desired) then return end

	local pos = root.Position
	if (pos - desired).Magnitude > 3 then
		pos = desired
	end
	if (pos - center).Magnitude < 0.5 then return end

	root.CFrame = CFrame.new(pos, center)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

-- escolhe o inimigo mais perto (qualquer coisa com Humanoid vivo, sem prioridade de boss)
local function dgScanEnemy(origin, radius, char)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}
	local parts = workspace:GetPartBoundsInRadius(origin, radius, params)
	local best, bestDist, seen = nil, math.huge, {}
	local now = tick()
	for _, part in ipairs(parts) do
		local t, kind = resolveTarget(part, char)
		if t and kind == "npc" and not seen[t] then
			seen[t] = true
			local bad = DG.badEnemy[t]
			if not (bad and bad > now) then
				local cf = getPivotCF(t)
				if cf and isVec3Ok(cf.Position) then
					local d = (cf.Position - origin).Magnitude
					if d < bestDist then best, bestDist = t, d end
				end
			end
		end
	end
	return best
end

-- escolhe o inimigo mais perto; com `wide` (zona ativa) e nada por perto, procura o mapa todo
local function dgPickEnemy(origin, char, wide)
	local best = dgScanEnemy(origin, DG.KillRange, char)
	if best or not wide then return best end

	local now = tick()
	local c = DG.farCache
	if c and c.enemy and c.enemy.Parent then
		local h = c.enemy:FindFirstChildOfClass("Humanoid")
		local bad = DG.badEnemy[c.enemy]
		if h and h.Health > 0 and not (bad and bad > now) then return c.enemy end
	end
	if c and now - c.t < 0.75 then return nil end
	local found = dgScanEnemy(origin, DG.FarRange, char)
	DG.farCache = {t = now, enemy = found}
	return found
end

local function dgGiveUp(enemy, now)
	-- alvo já bem machucado (quase morto): tenta de novo logo, sem blacklist longa
	local h = enemy:FindFirstChildOfClass("Humanoid")
	if h and h.MaxHealth > 0 and h.Health / h.MaxHealth < 0.5 then
		DG.badEnemy[enemy] = now + 2
		return
	end
	local n = (DG.badCount[enemy] or 0) + 1
	DG.badCount[enemy] = n
	-- cada vez que desiste do mesmo alvo, ignora por mais tempo (8s, 16s, 32s... até 120s)
	DG.badEnemy[enemy] = now + math.min(8 * 2 ^ (n - 1), 120)
end

-- luta até o alvo morrer; desiste só se o HP parar de mexer (alvo imune/inalcançável)
local function dgFight(enemy)
	local hum = enemy:FindFirstChildOfClass("Humanoid")
	if not hum then return "sem humanoid" end
	local startT = tick()
	local lastHP, lastChange = hum.Health, startT

	local fs = {dir = Vector3.new(0, 0, 1)}
	local cf0 = getPivotCF(enemy)
	if cf0 and isVec3Ok(cf0.Position) then
		local back = -cf0.LookVector
		local flat = Vector3.new(back.X, 0, back.Z)
		if flat.Magnitude > 0.1 then fs.dir = flat.Unit end
	end

	while running and DG.Kill do
		local now = tick()
		local root = dgAlive()
		if not root then return "morri" end
		if not enemy.Parent or hum.Health <= 0 then return "morto" end

		if math.abs(hum.Health - lastHP) > 0.01 then
			lastHP, lastChange = hum.Health, now
		elseif now - lastChange > DG.NoProgress then
			dgGiveUp(enemy, now)
			return "sem progresso"
		end
		if now - startT > DG.MaxFight then
			dgGiveUp(enemy, now)
			return "tempo máximo"
		end

		dgPlaceAt(enemy, fs)
		dgAttack(now, 1.0)
		task.wait(0.05)
	end
	return "abortado"
end

-- alavanca que ainda precisa ser acionada para a marcação atual (a mais perto DA ZONA)
local function dgLeverPending(marker, mpos)
	local rec = DG.mLever[marker]
	if rec and rec.confirmed then return nil end
	if rec and (tick() - rec.t < 20 or rec.tries >= 3) then return nil end
	local lever = dgNearest(DG.cache.levers, mpos)
	if not lever then return nil end
	if not dgLeverUsable(lever) then return nil end
	if (DG.leverFail[lever] or 0) > tick() then return nil end
	return lever
end

-- sobe em DEGRAUS: sobe um pouco, PARA e procura (inimigos/alavancas), sobe mais um pouco...
-- (limitado: no máximo DG.AscentTriesMax subidas completas; depois para e espera)
local function dgAscend(root, now)
	if DG.ascentTries >= DG.AscentTriesMax then
		DG.status = "Subida concluída sem achar nada; parado (reinicie o progresso pra tentar de novo)"
		return
	end

	local p = root.Position
	local a = DG.ascent
	if not a then
		a = {x = p.X, z = p.Z, startY = p.Y, y = p.Y, stageY = p.Y, t = now}
		DG.ascent = a
	end

	-- se algo moveu o personagem, retoma de onde ele está (sem voltar pra coluna antiga)
	if (p - Vector3.new(a.x, a.y, a.z)).Magnitude > 15 then
		a.x, a.z, a.y = p.X, p.Z, p.Y
		a.stageY = p.Y
		a.holdUntil = nil
		a.t = now
	end

	-- parado no degrau, só procurando
	if a.holdUntil and now < a.holdUntil then
		a.t = now
		root.CFrame = CFrame.new(a.x, a.y, a.z)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		DG.status = string.format("Parado no degrau, procurando (%.0fs)...", a.holdUntil - now)
		return
	end
	a.holdUntil = nil

	local dt = math.min(now - a.t, 0.3)
	a.t = now
	a.y += DG.AscentSpeed * dt

	if a.y - a.startY > DG.AscentMax then
		DG.ascent = nil
		DG.ascentTries += 1
		DG.ascentPause = now + 15
		dgTP(Vector3.new(a.x, a.startY, a.z))
		if DG.ascentTries >= DG.AscentTriesMax then
			DG.status = "Subida concluída sem achar nada; parado"
		else
			DG.status = "Subida sem resultado; voltando e tentando de novo em 15s"
		end
		return
	end

	if a.y - a.stageY >= DG.AscentStep then
		a.stageY = a.y
		a.holdUntil = now + DG.AscentHold
	end

	root.CFrame = CFrame.new(a.x, a.y, a.z)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	DG.status = string.format("Subindo (+%.0f/%d studs) tentativa %d/%d", a.y - a.startY, DG.AscentMax, DG.ascentTries + 1, DG.AscentTriesMax)
end

local function dgStep()
	if not (DG.Lever or DG.Doors or DG.Kill) then
		DG.status = "Desligado"
		DG.ascent = nil
		return
	end
	if not _G_SecurityEnabled then
		DG.status = "Ligue o Sistema de Segurança na aba Security"
		return
	end

	-- fase concluída / retry: limpa a blacklist temporária
	if endScreenShown then
		if not DG.endSeen then
			DG.endSeen = true
			dgReset()
			dgNotify("Auto Dungeon", "Fase concluída: blacklist limpa.")
		end
		DG.status = "Fase concluída: aguardando retry..."
		return
	end
	DG.endSeen = false

	local root, char = dgAlive()
	if not root then
		DG.status = "Aguardando personagem..."
		return
	end

	if DG.Lever then dgRefresh(false) end

	local now = tick()
	local marker, mpos = dgFindMarker(root.Position)

	-- ciclo de vida da marcação: nova / sumiu (objetivo concluído -> blacklist da zona e da alavanca)
	if marker then
		if DG.marker ~= marker then
			DG.marker = marker
			DG.goneAt = nil
			DG.ascent = nil
			DG.ascentTries = 0
			dgClear(DG.sweepDone)
		end
		DG.markerPos = mpos
	elseif DG.marker then
		local lastPos = DG.markerPos
		DG.marker = nil
		DG.goneAt = now
		DG.lastActivity = now
		dgClear(DG.sweepDone)
		DG.sweepPause = 0
		if lastPos then
			table.insert(DG.doneZones, lastPos)
			local lever = dgNearest(DG.cache.levers, lastPos)
			if lever then DG.doneLevers[lever] = true end
		end
		DG.progress += 1
		dgNotify("Auto Dungeon", "Objetivo concluído: alavanca e zona na blacklist.")
	end

	------------------------------------------------------------
	-- A) MARCAÇÃO ATIVA
	------------------------------------------------------------
	if marker then
		DG.lastActivity = now
		DG.ascent = nil
		local stand = mpos + Vector3.new(0, DG.ZoneHeight, 0)
		local lever = DG.Lever and dgLeverPending(marker, mpos) or nil

		-- 1) Kill All (prioridade máxima; boss primeiro) e volta pra zona depois
		if DG.Kill then
			local origin = (DG.Doors and not lever) and stand or root.Position
			local enemy = dgPickEnemy(origin, char, true)
			if enemy then
				DG.status = "Kill All: atacando inimigo"
				local fightRes = dgFight(enemy)
				if fightRes == "morto" then
					DG.ascentTries = 0
					DG.ascent = nil
				end
				DG.lastActivity = tick()
				DG.ascent = nil
				if DG.Doors and not lever and DG.marker then
					dgReturnToZone(marker, mpos, stand)
				end
				return
			end
		end

		-- 2) alavanca da zona ainda não confirmada -> interagir
		if lever then
			local res, note, confirmed = dgDoLever(lever)
			if res == "abort" then return end
			if res == "fail" then
				DG.leverFail[lever] = tick() + 10
				DG.status = "Alavanca falhou: " .. tostring(note)
			else
				local rec = DG.mLever[marker] or {tries = 0}
				rec.t = tick()
				rec.tries = rec.tries + 1
				rec.confirmed = confirmed
				DG.mLever[marker] = rec
				DG.status = "Alavanca: " .. tostring(note)
			end
			return
		end

		-- 3) focar na zona da marcação, spamando skills
		if DG.Doors then
			if dgInZone(marker, mpos) then
				root.AssemblyLinearVelocity = Vector3.zero
				dgAttack(now, 0.7)
				DG.status = "Guardando a zona (FloodGateMarker) + spam de skills"
			else
				DG.status = "Voltando pra zona da FloodGateMarker..."
				dgReturnToZone(marker, mpos, stand)
			end
		else
			DG.status = "Marcação ativa (Doors desligado)"
		end
		return
	end

	------------------------------------------------------------
	-- B) SEM MARCAÇÃO
	------------------------------------------------------------
	-- 1) Kill All (boss primeiro)
	if DG.Kill then
		local enemy = dgPickEnemy(root.Position, char)
		if enemy then
			DG.status = "Kill All: atacando inimigo"
			local fightRes = dgFight(enemy)
			if fightRes == "morto" then
				DG.ascentTries = 0
				DG.ascent = nil
			end
			DG.lastActivity = tick()
			DG.ascent = nil
			return
		end
	end

	-- 2) marcação acabou de sumir: dar um tempo pra próxima aparecer
	if DG.goneAt and now - DG.goneAt < DG.Grace then
		DG.status = string.format("Marcação sumiu; aguardando a próxima (%.0fs)...", DG.Grace - (now - DG.goneAt))
		return
	end

	-- 3) não apareceu: alguma alavanca foi ignorada -> varrer só as que NÃO estão na blacklist
	if DG.Lever and (now >= DG.sweepPause or DG.ascent) then
		local lever = dgNearest(DG.cache.levers, root.Position, dgSweepIgnore)
		if lever then
			DG.ascent = nil
			DG.lastActivity = now
			DG.status = "Sem marcação: indo numa alavanca ignorada"
			local res, note, confirmed = dgDoLever(lever)
			if res ~= "abort" then
				DG.sweepDone[lever] = true
				local tries = (DG.sweepTries[lever] or 0) + 1
				DG.sweepTries[lever] = tries
				DG.lastActivity = tick()
				if confirmed then
					DG.doneLevers[lever] = true
					DG.progress += 1
				elseif tries >= 2 then
					-- sem confirmação: ignora só por 30s e tenta de novo depois (não é blacklist eterna)
					DG.leverFail[lever] = tick() + 30
					DG.sweepTries[lever] = 0
				end
				DG.status = "Varredura: " .. tostring(note)
			end
			return
		end
		local triedAny = next(DG.sweepDone) ~= nil
		DG.sweepPause = now + (triedAny and DG_SWEEP_PAUSE or 3)
		dgClear(DG.sweepDone)
	end

	-- 4) nada pra fazer (sem inimigo, marcação ou alavanca): subir pro próximo andar pra spawnar os inimigos
	do
		local idle = now - DG.lastActivity
		if not DG.ascent and idle < DG.IdleBeforeAscent then
			DG.status = string.format("Parado procurando alavancas/inimigos (sobe em %.0fs)", DG.IdleBeforeAscent - idle)
			return
		end
		if now < DG.ascentPause then
			DG.status = "Aguardando pra tentar subir de novo..."
			return
		end
		dgAscend(root, now)
		return
	end

	if #DG.cache.levers == 0 then
		DG.status = "Procurando alavancas (CONS_LEVER) no mapa..."
	else
		DG.status = string.format("%d alavanca(s) achada(s), nenhuma utilizável agora; tentando de novo...", #DG.cache.levers)
	end
end

task.spawn(function()
	while running do
		task.wait(0.05)
		local ok, err = pcall(dgStep)
		if not ok then
			DG.status = "Erro: " .. tostring(err)
			warn("[AutoDungeon] " .. tostring(err))
			task.wait(1)
		end
	end
end)

-- autoclick no centro exato da tela (escolher carta de dano/vida/speed)
task.spawn(function()
	while running do
		task.wait(DG.ClickInterval)
		if DG.Click then
			task.spawn(triggerM1)
		end
	end
end)

-- ---------------- Interface ----------------
DG.label = DungeonTab:CreateLabel("Status: desligado")

task.spawn(function()
	local last = ""
	while running do
		task.wait(0.5)
		local txt = "Status: " .. tostring(DG.status)
		if txt ~= last and DG.label then
			last = txt
			pcall(function() DG.label:Set(txt) end)
		end
	end
end)

DungeonTab:CreateSection("Controle (prioridade: Kill All > Alavanca > Zona > Subir pro Boss)")

DG.Toggles.Full = DungeonTab:CreateToggle({
	Name = "FULL CHISA DUNGEON (Lever + Doors + Kill All)",
	CurrentValue = false,
	Flag = "DGFullFlag",
	Callback = function(Value)
		if Value then
			local reason
			if not _G_SecurityEnabled then
				reason = "Ligue o Sistema de Segurança na aba Security antes de usar o Full Chisa Dungeon."
			elseif _G_KillAura or _G_Active then
				reason = "Desligue o Kill Aura e o Autofarm da aba Main antes de usar o Full Chisa Dungeon."
			end
			if reason then
				DG.Lever, DG.Doors, DG.Kill = false, false, false
				if DG.Toggles.Full then DG.Toggles.Full:Set(false) end
				dgNotify("Full Chisa Dungeon bloqueado", reason)
				return
			end
		end
		DG.Lever, DG.Doors, DG.Kill = Value, Value, Value
		if not Value then DG.ascent = nil end
	end,
})

DungeonTab:CreateToggle({
	Name = "Auto Click no centro da tela (escolher carta)",
	CurrentValue = false,
	Flag = "DGClickFlag",
	Callback = function(Value) DG.Click = Value end,
})

DungeonTab:CreateSection("Configurações")

DungeonTab:CreateSlider({
	Name = "Intervalo do autoclick (s)",
	Range = {0.2, 5},
	Increment = 0.1,
	Suffix = "s",
	CurrentValue = 1,
	Flag = "DGClickInterval",
	Callback = function(Value) DG.ClickInterval = Value end,
})

DungeonTab:CreateSlider({
	Name = "Raio da zona ao redor da marcação",
	Range = {5, 60},
	Increment = 1,
	Suffix = "studs",
	CurrentValue = 20,
	Flag = "DGZoneRadius",
	Callback = function(Value) DG.ZoneRadius = Value end,
})

DungeonTab:CreateSlider({
	Name = "Altura de espera (acima da marcação)",
	Range = {0, 15},
	Increment = 1,
	Suffix = "studs",
	CurrentValue = 2,
	Flag = "DGZoneHeight",
	Callback = function(Value) DG.ZoneHeight = Value end,
})

DungeonTab:CreateSlider({
	Name = "Espera antes de varrer alavancas (s)",
	Range = {2, 30},
	Increment = 1,
	Suffix = "s",
	CurrentValue = 8,
	Flag = "DGGrace",
	Callback = function(Value) DG.Grace = Value end,
})

DungeonTab:CreateSlider({
	Name = "Alcance de busca de inimigos",
	Range = {20, 1000},
	Increment = 10,
	Suffix = "studs",
	CurrentValue = 400,
	Flag = "DGKillRange",
	Callback = function(Value) DG.KillRange = Value end,
})

DungeonTab:CreateSlider({
	Name = "Desistir do alvo se não causar dano em (s)",
	Range = {2, 20},
	Increment = 1,
	Suffix = "s",
	CurrentValue = 6,
	Flag = "DGMaxExcursion",
	Callback = function(Value) DG.NoProgress = Value end,
})

DungeonTab:CreateSlider({
	Name = "Distância máx. da alavanca pra interagir",
	Range = {4, 25},
	Increment = 1,
	Suffix = "studs",
	CurrentValue = 12,
	Flag = "DGLeverReach",
	Callback = function(Value) DG.LeverReach = Value end,
})

DungeonTab:CreateSlider({
	Name = "Velocidade de subida pro Boss (studs/s)",
	Range = {10, 120},
	Increment = 5,
	Suffix = "studs/s",
	CurrentValue = 40,
	Flag = "DGAscentSpeed",
	Callback = function(Value) DG.AscentSpeed = Value end,
})

DungeonTab:CreateSlider({
	Name = "Altura máxima de subida",
	Range = {50, 1500},
	Increment = 50,
	Suffix = "studs",
	CurrentValue = 400,
	Flag = "DGAscentMax",
	Callback = function(Value) DG.AscentMax = Value end,
})

DungeonTab:CreateSlider({
	Name = "Tentativas de subida (depois disso para)",
	Range = {1, 5},
	Increment = 1,
	Suffix = "x",
	CurrentValue = 2,
	Flag = "DGAscentTries",
	Callback = function(Value) DG.AscentTriesMax = Value end,
})

DungeonTab:CreateSlider({
	Name = "Ficar parado procurando antes de subir (s)",
	Range = {2, 30},
	Increment = 1,
	Suffix = "s",
	CurrentValue = 6,
	Flag = "DGIdleBeforeAscent",
	Callback = function(Value) DG.IdleBeforeAscent = Value end,
})

DungeonTab:CreateSlider({
	Name = "Pausa em cada degrau da subida (s)",
	Range = {1, 15},
	Increment = 1,
	Suffix = "s",
	CurrentValue = 4,
	Flag = "DGAscentHold",
	Callback = function(Value) DG.AscentHold = Value end,
})

DungeonTab:CreateSection("Ferramentas")

DungeonTab:CreateButton({
	Name = "Escanear marcação e alavancas (lista no console F9)",
	Callback = function()
		task.spawn(function()
			dgRefresh(true)
			local root = dgAlive()
			local origin = root and root.Position or Vector3.zero
			local marker, mpos = dgFindMarker(origin)
			if marker then
				print(string.format("[AutoDungeon] FloodGateMarker: %s | dist %d", marker:GetFullName(), math.floor((mpos - origin).Magnitude)))
				local near = dgNearest(DG.cache.levers, mpos)
				if near then print("[AutoDungeon] Alavanca mais perto da zona: " .. near:GetFullName()) end
			else
				print("[AutoDungeon] FloodGateMarker NÃO existe agora (ou está na blacklist)")
			end
			print(string.format("[AutoDungeon] %d %s encontradas | %d zonas e %s alavancas na blacklist | progresso %d",
				#DG.cache.levers, DG_LEVER_NAME, #DG.doneZones, tostring(next(DG.doneLevers) ~= nil), DG.progress))
			for i, l in ipairs(DG.cache.levers) do
				local p = dgPos(l)
				print(string.format("  LEVER %d: %s | dist %s | %s", i, l:GetFullName(),
					p and tostring(math.floor((p - origin).Magnitude)) or "?",
					DG.doneLevers[l] and "BLACKLIST" or "ativa"))
			end
			dgNotify("Scan concluído", string.format("Marcação: %s | %d alavancas (veja o console F9).", marker and "existe" or "não existe", #DG.cache.levers))
		end)
	end,
})

DungeonTab:CreateButton({
	Name = "Reiniciar progresso (limpar blacklist)",
	Callback = function()
		dgReset()
		DG.cache.t = 0
		dgNotify("Auto Dungeon", "Progresso e blacklist reiniciados.")
	end,
})

track(RunService.Heartbeat:Connect(function()
	local now = tick()

	if not _G_SecurityEnabled then return end
	if not _G_Active and not _G_KillAura then return end

	local root, char = getRoot()
	if not root then return end

	if _G_KillAura then
		if not isTargetValid(currentTarget, currentKind, root) then
			currentTarget, currentKind = scanForTarget(root, char)
		end

		if currentTarget then
			local cf = getPivotCF(currentTarget)
			if cf and isVec3Ok(cf.Position) then
				local targetCFrame
				if _G_Mode == "atrás" then
					targetCFrame = cf * CFrame.new(0, 0, _G_Distance)
				elseif _G_Mode == "acima" then
					targetCFrame = cf * CFrame.new(0, _G_Distance, 0)
				else
					targetCFrame = cf * CFrame.new(0, -_G_Distance, 0)
				end

				root.CFrame = CFrame.new(targetCFrame.Position, cf.Position)
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end

			if _G_Skills.M1 and now - lastM1 >= M1_INTERVAL then
				lastM1 = now
				task.spawn(triggerM1)
			end

			if now - lastSkillsTime >= 2 then
				lastSkillsTime = now
				task.spawn(function()
					local keys = {}
					if _G_Skills.One then table.insert(keys, Enum.KeyCode.One) end
					if _G_Skills.Two then table.insert(keys, Enum.KeyCode.Two) end
					if _G_Skills.Three then table.insert(keys, Enum.KeyCode.Three) end
					for _, key in ipairs(keys) do
						pressKey(key, 0.02)
					end
				end)
			end

			if now - lastTTime >= _G_TInterval and not tSpamming then
				lastTTime = now
				tSpamming = true
				task.spawn(function()
					local startT = tick()
					while tick() - startT < 2.4 and _G_KillAura and _G_Skills.T do
						pressKey(Enum.KeyCode.T, 0.05)
						task.wait(0.1)
					end
					tSpamming = false
				end)
			end

			if now - lastGTime >= 30 then
				lastGTime = now
				task.spawn(function()
					if _G_Skills.G then pressKey(Enum.KeyCode.G, 0.02) end
				end)
			end
		end
		return
	end

	if endScreenShown then
		currentTarget = nil
		currentKind = nil
		finishedTime = 0
		return
	end

	if currentTarget then
		local thum = currentTarget:FindFirstChildOfClass("Humanoid")
		local currentHP = thum and thum.Health or 1

		if thum then
			if math.abs(currentHP - targetLastHP) > 0.01 then
				targetLastHP = currentHP
				targetLastChange = now
			else
				local timeout = (currentKind == "rock") and ROCK_NO_PROGRESS_TIMEOUT or NO_PROGRESS_TIMEOUT
				if now - targetLastChange >= timeout then
					blacklist[currentTarget] = true
					currentTarget = nil
					currentKind = nil
				end
			end
		else
			if now - targetSince >= ROCK_NO_PROGRESS_TIMEOUT then
				blacklist[currentTarget] = true
				currentTarget = nil
				currentKind = nil
			end
		end
	end

	if not isTargetValid(currentTarget, currentKind, root) then
		if currentTarget and currentTarget.Parent and now - targetSince >= TARGET_TIMEOUT then
			blacklist[currentTarget] = true
		end
		currentTarget = nil
		currentKind = nil

		if now - lastScan >= 0.15 then
			lastScan = now
			local t, kind = scanForTarget(root, char)
			if t then
				currentTarget = t
				currentKind = kind
				targetSince = now

				local th = t:FindFirstChildOfClass("Humanoid")
				targetLastHP = th and th.Health or 1
				targetLastChange = now

				if kind == "rock" then
					local bcf = getBounds(t)
					if bcf and isVec3Ok(bcf.Position) then
						local c = bcf.Position
						local flat = Vector3.new(root.Position.X - c.X, 0, root.Position.Z - c.Z)
						targetDir = flat.Magnitude > 0.5 and flat.Unit or Vector3.new(0, 0, 1)
					end
				end
			end
		end
	end

	if currentTarget then
		if currentKind == "npc" then
			enemiesEncountered = true
			lastEnemyTime = now
		end

		local positioned = false

		if currentKind == "rock" then
			local bcf, bsize = getBounds(currentTarget)
			if bcf and isVec3Ok(bcf.Position) and isVec3Ok(bsize) then
				local c = bcf.Position
				local radius = math.max(bsize.X, bsize.Z) / 2
				local gap = radius + ROCK_GAP
				
				local flat = Vector3.new(root.Position.X - c.X, 0, root.Position.Z - c.Z)
				if flat.Magnitude < 0.5 then flat = Vector3.new(0, 0, 1) end
				flat = flat.Unit

				local sx = c.X + flat.X * gap
				local sz = c.Z + flat.Z * gap

				local rp = RaycastParams.new()
				rp.FilterType = Enum.RaycastFilterType.Exclude
				rp.FilterDescendantsInstances = {char, currentTarget}

				local ray = workspace:Raycast(Vector3.new(sx, c.Y + 50, sz), Vector3.new(0, -150, 0), rp)
				local gy = ray and ray.Position.Y or (c.Y - bsize.Y / 2)
				local sy = gy + 3.0

				root.CFrame = CFrame.new(Vector3.new(sx, sy, sz), Vector3.new(c.X, sy, c.Z))
				positioned = true
			end
		else
			local cf = getPivotCF(currentTarget)
			if cf and isVec3Ok(cf.Position) then
				local targetCFrame
				if _G_Mode == "atrás" then
					targetCFrame = cf * CFrame.new(0, 0, _G_Distance)
				elseif _G_Mode == "acima" then
					targetCFrame = cf * CFrame.new(0, _G_Distance, 0)
				else
					targetCFrame = cf * CFrame.new(0, -_G_Distance, 0)
				end

				root.CFrame = CFrame.new(targetCFrame.Position, cf.Position)
				positioned = true
			end
		end

		if positioned then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero

			local subject = getCamSubject(currentTarget)
			if subject then
				pcall(function() Camera.CameraSubject = subject end)
			end
		else
			blacklist[currentTarget] = true
			currentTarget = nil
			currentKind = nil
			return
		end

		if _G_Skills.M1 and now - lastM1 >= M1_INTERVAL then
			lastM1 = now
			task.spawn(triggerM1)
		end

		if now - lastSkillsTime >= 2 then
			lastSkillsTime = now
			task.spawn(function()
				local keys = {}
				if _G_Skills.One then table.insert(keys, Enum.KeyCode.One) end
				if _G_Skills.Two then table.insert(keys, Enum.KeyCode.Two) end
				if _G_Skills.Three then table.insert(keys, Enum.KeyCode.Three) end
				for _, key in ipairs(keys) do
					pressKey(key, 0.02)
				end
			end)
		end

		if now - lastTTime >= _G_TInterval and not tSpamming then
			lastTTime = now
			tSpamming = true
			task.spawn(function()
				local startT = tick()
				while tick() - startT < 2.4 and _G_Active and _G_Skills.T do
					pressKey(Enum.KeyCode.T, 0.05)
					task.wait(0.1)
				end
				tSpamming = false
			end)
		end

		if now - lastGTime >= 30 then
			lastGTime = now
			task.spawn(function()
				if _G_Skills.G then pressKey(Enum.KeyCode.G, 0.02) end
			end)
		end

		return
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and Camera.CameraSubject ~= hum then
		Camera.CameraSubject = hum
	end

	if storyDone then
		if finishedTime == 0 then finishedTime = now end
		if now - finishedTime > 7.0 then
			currentArea = 1
			storyDone = false
			arrived = false
			enemiesEncountered = false
			finishedTime = 0
			blacklist = {}
			return
		end
		return
	end

	local areaInst = findArea(currentArea)
	if not areaInst then return end

	local areaPos = getInstPos(areaInst)
	if not areaPos then return end

	local dest = areaPos + Vector3.new(0, 3, 0)

	if not arrived then
		local diff = dest - root.Position
		if diff.Magnitude > 8 then
			root.CFrame = CFrame.new(dest)
			root.AssemblyLinearVelocity = Vector3.zero
		else
			arrived = true
			enemiesEncountered = false
			lastEnemyTime = now
			touchArea(areaInst, root)
		end
	else
		local border = getMapFolder() and getMapFolder():FindFirstChild("Border" .. tostring(currentArea))
		local hasRubbles = false
		if border then
			local rubbleFolder = border:FindFirstChild("Rubble")
			if rubbleFolder and #rubbleFolder:GetChildren() > 0 then
				hasRubbles = true
			end
		end

		local timeSinceLast = now - lastEnemyTime
		local waveFinished = false

		if not hasRubbles and (not enemiesEncountered or timeSinceLast >= 0.2) then
			waveFinished = true
		elseif enemiesEncountered and timeSinceLast >= _G_WaveDelay then
			waveFinished = true
		end

		if waveFinished then
			currentArea = currentArea + 1
			arrived = false
			enemiesEncountered = false
			lastEnemyTime = now

			if currentArea > MAX_AREA then
				currentArea = MAX_AREA
				if _G_AutoRetry or _G_AutoSkip then
					storyDone = true
					finishedTime = now
				else
					currentArea = 1
					_G_Active = false
				end
			end
		end
	end
end))
