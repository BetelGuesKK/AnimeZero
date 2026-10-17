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

local _G_SecurityEnabled = true
local _G_MaxPlayers = 1

local function emergencyEject()
	if not _G_SecurityEnabled then return end
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
		if _G_SecurityEnabled and #Players:GetPlayers() > _G_MaxPlayers then
			emergencyEject()
		end
	end
end)

track(Players.PlayerAdded:Connect(function(player)
	if _G_SecurityEnabled and #Players:GetPlayers() > _G_MaxPlayers then
		emergencyEject()
	end
end))

track(RunService.Heartbeat:Connect(function()
	if _G_SecurityEnabled and #Players:GetPlayers() > _G_MaxPlayers then
		emergencyEject()
	end
end))

local _G_Active = false
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
	T = true,
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
   CurrentValue = true,
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
   CurrentValue = true,
   Flag = "SecurityToggle",
   Callback = function(Value)
      _G_SecurityEnabled = Value
   end,
})

SecurityTab:CreateDropdown({
   Name = "Máximo de Jogadores",
   Options = {"1", "2", "3", "4", "5", "6"},
   CurrentOption = "1",
   Flag = "MaxPlayersDropdown",
   Callback = function(Option)
      _G_MaxPlayers = tonumber(Option) or 1
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

track(RunService.Heartbeat:Connect(function()
	local now = tick()

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
