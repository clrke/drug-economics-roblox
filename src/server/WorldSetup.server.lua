-- WorldSetup.server.lua
-- Creates NPCs, beds, and spawn point at game start

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- House data for bed and villager placement (from exploration)
local HouseData = {
	{center = Vector3.new(-157, 4, 73), rotation = -60},
	{center = Vector3.new(155, 4, 48), rotation = 75},
	{center = Vector3.new(-60, 4, 148), rotation = -15},
	{center = Vector3.new(57, 4, 141), rotation = 30},
	{center = Vector3.new(-152, 4, -66), rotation = -105},
	{center = Vector3.new(48, 4, -144), rotation = 165},
	{center = Vector3.new(-74, 4, -157), rotation = -150},
	{center = Vector3.new(150, 4, -75), rotation = 120},
}

local TentPosition = Vector3.new(-38, 1, 0.6)

-- Lobby position (high up, separate from game world)
local LobbyPosition = Vector3.new(0, 500, 0)

-- Merchant position - OUTSIDE the fountain (fountain is at ~18, 10, -3 with ~49 stud bounds)
-- Place near tent area but visible
local MerchantPosition = Vector3.new(-10, 2, 25)

local SkinTones = {
	Color3.fromRGB(255, 204, 153),
	Color3.fromRGB(234, 184, 146),
	Color3.fromRGB(198, 156, 109),
	Color3.fromRGB(160, 95, 53),
	Color3.fromRGB(86, 66, 54),
	Color3.fromRGB(255, 220, 185),
	Color3.fromRGB(215, 168, 140),
	Color3.fromRGB(180, 130, 100),
}

-- Hair styles (Part-based configurations)
local HairStyles = {
	{name = "Short", parts = {{size = Vector3.new(1.1, 0.4, 1.1), offset = Vector3.new(0, 0.5, 0)}}},
	{name = "Spiky", parts = {
		{size = Vector3.new(0.3, 0.6, 0.3), offset = Vector3.new(0.3, 0.6, 0)},
		{size = Vector3.new(0.3, 0.5, 0.3), offset = Vector3.new(-0.3, 0.55, 0)},
		{size = Vector3.new(0.3, 0.45, 0.3), offset = Vector3.new(0, 0.65, 0.2)},
	}},
	{name = "Long", parts = {
		{size = Vector3.new(1.1, 0.3, 1.1), offset = Vector3.new(0, 0.5, 0)},
		{size = Vector3.new(1, 1.2, 0.4), offset = Vector3.new(0, -0.3, -0.4)},
	}},
	{name = "Ponytail", parts = {
		{size = Vector3.new(1.1, 0.3, 1.1), offset = Vector3.new(0, 0.5, 0)},
		{size = Vector3.new(0.3, 0.8, 0.3), offset = Vector3.new(0, 0.2, -0.5)},
	}},
	{name = "Bald", parts = {}},
	{name = "Afro", parts = {{size = Vector3.new(1.4, 1.2, 1.4), offset = Vector3.new(0, 0.4, 0), shape = "Ball"}}},
	{name = "Mohawk", parts = {{size = Vector3.new(0.2, 0.7, 1), offset = Vector3.new(0, 0.6, 0)}}},
	{name = "SidePart", parts = {
		{size = Vector3.new(1.1, 0.35, 1.1), offset = Vector3.new(0, 0.5, 0)},
		{size = Vector3.new(0.4, 0.2, 0.8), offset = Vector3.new(0.4, 0.4, 0)},
	}},
}

-- Hair colors
local HairColors = {
	Color3.fromRGB(30, 20, 15),    -- Black
	Color3.fromRGB(60, 40, 25),    -- Dark brown
	Color3.fromRGB(120, 80, 40),   -- Brown
	Color3.fromRGB(180, 130, 70),  -- Light brown
	Color3.fromRGB(220, 180, 100), -- Blonde
	Color3.fromRGB(200, 80, 40),   -- Red
	Color3.fromRGB(150, 150, 160), -- Gray
	Color3.fromRGB(255, 255, 255), -- White
}

-- Hat/Accessory types
local HatTypes = {
	{name = "None"},
	{name = "Cap", parts = {{size = Vector3.new(1.2, 0.25, 1.2), offset = Vector3.new(0, 0.55, 0)}, {size = Vector3.new(0.8, 0.1, 0.5), offset = Vector3.new(0, 0.5, 0.6)}}},
	{name = "Beanie", parts = {{size = Vector3.new(1.15, 0.5, 1.15), offset = Vector3.new(0, 0.5, 0)}}},
	{name = "TopHat", parts = {{size = Vector3.new(0.9, 0.8, 0.9), offset = Vector3.new(0, 0.8, 0)}, {size = Vector3.new(1.3, 0.1, 1.3), offset = Vector3.new(0, 0.45, 0)}}},
	{name = "Bandana", parts = {{size = Vector3.new(1.12, 0.2, 1.12), offset = Vector3.new(0, 0.35, 0)}}},
	{name = "Crown", parts = {{size = Vector3.new(1, 0.4, 1), offset = Vector3.new(0, 0.6, 0)}}},
}

-- Shirt colors
local ShirtColors = {
	BrickColor.new("Bright red"),
	BrickColor.new("Bright blue"),
	BrickColor.new("Bright green"),
	BrickColor.new("Bright yellow"),
	BrickColor.new("Bright orange"),
	BrickColor.new("Bright violet"),
	BrickColor.new("Medium lilac"),
	BrickColor.new("Teal"),
	BrickColor.new("Dusty Rose"),
	BrickColor.new("Olive"),
	BrickColor.new("White"),
	BrickColor.new("Institutional white"),
}

-- Pants colors
local PantsColors = {
	BrickColor.new("Dark stone grey"),
	BrickColor.new("Really black"),
	BrickColor.new("Navy blue"),
	BrickColor.new("Brown"),
	BrickColor.new("Reddish brown"),
	BrickColor.new("Sand blue"),
	BrickColor.new("Khaki"),
}

-- Face expressions (decal IDs) - using Roblox built-in and common faces
local FaceTextures = {
	"rbxasset://textures/face.png",                    -- Default smile
	"rbxassetid://7074882124",                          -- Friendly
	"rbxassetid://31117192",                            -- Happy
	"rbxassetid://7074954229",                          -- Content
	"rbxassetid://7074891385",                          -- Joyful
}

-- Create a simple bed model inside house with proper rotation
local function CreateBed(position, rotationDegrees)
	local bed = Instance.new("Model")
	bed.Name = "Bed"

	local rotation = CFrame.Angles(0, math.rad(rotationDegrees), 0)
	local baseCFrame = CFrame.new(position) * rotation

	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Size = Vector3.new(3, 0.4, 6)
	frame.CFrame = baseCFrame * CFrame.new(0, 0.2, 0)
	frame.Anchored = true
	frame.BrickColor = BrickColor.new("Reddish brown")
	frame.Material = Enum.Material.Wood
	frame.Parent = bed

	local mattress = Instance.new("Part")
	mattress.Name = "Mattress"
	mattress.Size = Vector3.new(2.8, 0.3, 5.5)
	mattress.CFrame = baseCFrame * CFrame.new(0, 0.55, 0)
	mattress.Anchored = true
	mattress.BrickColor = BrickColor.new("Institutional white")
	mattress.Material = Enum.Material.Fabric
	mattress.Parent = bed

	local pillow = Instance.new("Part")
	pillow.Name = "Pillow"
	pillow.Size = Vector3.new(2, 0.25, 0.8)
	pillow.CFrame = baseCFrame * CFrame.new(0, 0.75, 2.2)
	pillow.Anchored = true
	pillow.BrickColor = BrickColor.new("White")
	pillow.Material = Enum.Material.Fabric
	pillow.Parent = bed

	bed.PrimaryPart = frame
	bed.Parent = workspace

	return bed
end

-- Create R15-style humanoid NPC with random features
local function CreateNPC(name, position, isMerchant)
	local npc = Instance.new("Model")
	npc.Name = name

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.Parent = npc

	-- Random variation for age/size (0.85 to 1.1 scale)
	local sizeScale = 0.85 + math.random() * 0.25
	local isElder = math.random() < 0.2 -- 20% chance of being elder

	-- Pick random appearance
	local skinColor = SkinTones[math.random(1, #SkinTones)]
	local hairStyle = HairStyles[math.random(1, #HairStyles)]
	local hairColor = HairColors[math.random(1, #HairColors)]
	local hatType = HatTypes[math.random(1, #HatTypes)]
	local shirtColor = ShirtColors[math.random(1, #ShirtColors)]
	local pantsColor = PantsColors[math.random(1, #PantsColors)]
	local faceTexture = FaceTextures[math.random(1, #FaceTextures)]

	-- Elder gets gray/white hair
	if isElder then
		hairColor = HairColors[math.random(7, 8)] -- Gray or white
		sizeScale = sizeScale * 0.95 -- Slightly smaller
	end

	-- Merchant has specific look
	if isMerchant then
		skinColor = Color3.fromRGB(255, 220, 185)
		shirtColor = BrickColor.new("Bright orange")
		hatType = {name = "MerchantHat", parts = {{size = Vector3.new(1.4, 0.15, 1.4), offset = Vector3.new(0, 0.55, 0)}, {size = Vector3.new(1.2, 0.5, 1.2), offset = Vector3.new(0, 0.85, 0)}}}
		sizeScale = 1.0
	end

	-- Root part (invisible, R15 style)
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1) * sizeScale
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = true
	hrp.Position = position
	hrp.Parent = npc

	-- R15-style Head (slightly more oval)
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2) * sizeScale
	head.Position = position + Vector3.new(0, 2.1 * sizeScale, 0)
	head.Anchored = true
	head.Color = skinColor
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = npc

	-- Add face mesh for more rounded look
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	headMesh.Parent = head

	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = faceTexture
	face.Face = Enum.NormalId.Front
	face.Parent = head

	-- R15-style Upper Torso
	local upperTorso = Instance.new("Part")
	upperTorso.Name = "UpperTorso"
	upperTorso.Size = Vector3.new(2, 1.2, 1) * sizeScale
	upperTorso.Position = position + Vector3.new(0, 0.9 * sizeScale, 0)
	upperTorso.Anchored = true
	upperTorso.BrickColor = shirtColor
	upperTorso.Material = Enum.Material.SmoothPlastic
	upperTorso.Parent = npc

	-- R15-style Lower Torso
	local lowerTorso = Instance.new("Part")
	lowerTorso.Name = "LowerTorso"
	lowerTorso.Size = Vector3.new(1.8, 0.6, 1) * sizeScale
	lowerTorso.Position = position + Vector3.new(0, 0.1 * sizeScale, 0)
	lowerTorso.Anchored = true
	lowerTorso.BrickColor = shirtColor
	lowerTorso.Material = Enum.Material.SmoothPlastic
	lowerTorso.Parent = npc

	-- Legacy Torso reference for compatibility
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1) * sizeScale
	torso.Position = position + Vector3.new(0, 0.5 * sizeScale, 0)
	torso.Anchored = true
	torso.Transparency = 1
	torso.CanCollide = false
	torso.Parent = npc

	-- R15-style Arms (Upper + Lower)
	local function CreateArm(side)
		local xOffset = side == "Left" and -1.1 or 1.1

		local upperArm = Instance.new("Part")
		upperArm.Name = side .. " Arm"  -- Keep legacy name for compatibility
		upperArm.Size = Vector3.new(0.5, 0.8, 0.5) * sizeScale
		upperArm.Position = position + Vector3.new(xOffset * sizeScale, 0.8 * sizeScale, 0)
		upperArm.Anchored = true
		upperArm.Color = skinColor
		upperArm.Material = Enum.Material.SmoothPlastic
		upperArm.Parent = npc

		local lowerArm = Instance.new("Part")
		lowerArm.Name = side .. "LowerArm"
		lowerArm.Size = Vector3.new(0.5, 0.8, 0.5) * sizeScale
		lowerArm.Position = position + Vector3.new(xOffset * sizeScale, 0 * sizeScale, 0)
		lowerArm.Anchored = true
		lowerArm.Color = skinColor
		lowerArm.Material = Enum.Material.SmoothPlastic
		lowerArm.Parent = npc

		local hand = Instance.new("Part")
		hand.Name = side .. "Hand"
		hand.Size = Vector3.new(0.4, 0.4, 0.4) * sizeScale
		hand.Position = position + Vector3.new(xOffset * sizeScale, -0.5 * sizeScale, 0)
		hand.Anchored = true
		hand.Color = skinColor
		hand.Material = Enum.Material.SmoothPlastic
		hand.Parent = npc
	end

	CreateArm("Left")
	CreateArm("Right")

	-- R15-style Legs (Upper + Lower)
	local function CreateLeg(side)
		local xOffset = side == "Left" and -0.5 or 0.5

		local upperLeg = Instance.new("Part")
		upperLeg.Name = side .. " Leg"  -- Keep legacy name for compatibility
		upperLeg.Size = Vector3.new(0.6, 0.8, 0.6) * sizeScale
		upperLeg.Position = position + Vector3.new(xOffset * sizeScale, -0.6 * sizeScale, 0)
		upperLeg.Anchored = true
		upperLeg.BrickColor = pantsColor
		upperLeg.Material = Enum.Material.SmoothPlastic
		upperLeg.Parent = npc

		local lowerLeg = Instance.new("Part")
		lowerLeg.Name = side .. "LowerLeg"
		lowerLeg.Size = Vector3.new(0.6, 0.8, 0.6) * sizeScale
		lowerLeg.Position = position + Vector3.new(xOffset * sizeScale, -1.4 * sizeScale, 0)
		lowerLeg.Anchored = true
		lowerLeg.BrickColor = pantsColor
		lowerLeg.Material = Enum.Material.SmoothPlastic
		lowerLeg.Parent = npc

		local foot = Instance.new("Part")
		foot.Name = side .. "Foot"
		foot.Size = Vector3.new(0.6, 0.3, 0.8) * sizeScale
		foot.Position = position + Vector3.new(xOffset * sizeScale, -1.95 * sizeScale, 0.1 * sizeScale)
		foot.Anchored = true
		foot.BrickColor = BrickColor.new("Really black")
		foot.Material = Enum.Material.SmoothPlastic
		foot.Parent = npc
	end

	CreateLeg("Left")
	CreateLeg("Right")

	-- Add Hair (if not bald and no hat covering it)
	local hairFolder = Instance.new("Folder")
	hairFolder.Name = "Hair"
	hairFolder.Parent = npc

	if hairStyle.name ~= "Bald" and hatType.name == "None" then
		for i, partConfig in ipairs(hairStyle.parts) do
			local hairPart = Instance.new("Part")
			hairPart.Name = "HairPart" .. i
			hairPart.Size = partConfig.size * sizeScale
			hairPart.Position = head.Position + partConfig.offset * sizeScale
			hairPart.Anchored = true
			hairPart.Color = hairColor
			hairPart.Material = Enum.Material.SmoothPlastic
			hairPart.CanCollide = false

			if partConfig.shape == "Ball" then
				hairPart.Shape = Enum.PartType.Ball
			end

			hairPart.Parent = hairFolder
		end
	end

	-- Add Hat/Accessory
	local hatFolder = Instance.new("Folder")
	hatFolder.Name = "HatAccessory"
	hatFolder.Parent = npc

	if hatType.name ~= "None" and hatType.parts then
		local hatColor = BrickColor.random()
		if isMerchant then
			hatColor = BrickColor.new("Bright orange")
		end

		for i, partConfig in ipairs(hatType.parts) do
			local hatPart = Instance.new("Part")
			hatPart.Name = "HatPart" .. i
			hatPart.Size = partConfig.size * sizeScale
			hatPart.Position = head.Position + partConfig.offset * sizeScale
			hatPart.Anchored = true
			hatPart.BrickColor = hatColor
			hatPart.Material = Enum.Material.SmoothPlastic
			hatPart.CanCollide = false
			hatPart.Parent = hatFolder
		end
	end

	-- Merchant gets shop sign
	if isMerchant then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "MerchantSign"
		billboard.Size = UDim2.new(0, 100, 0, 24)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.AlwaysOnTop = false
		billboard.Enabled = false
		billboard.Adornee = head
		billboard.Parent = npc

		local signLabel = Instance.new("TextLabel")
		signLabel.Size = UDim2.new(1, 0, 1, 0)
		signLabel.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
		signLabel.BackgroundTransparency = 0.4
		signLabel.Text = "SHOP"
		signLabel.TextColor3 = Color3.new(1, 1, 1)
		signLabel.TextSize = 14
		signLabel.Font = Enum.Font.GothamBold
		signLabel.Parent = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = signLabel
	end

	-- Store appearance info for later use
	npc:SetAttribute("HairStyle", hairStyle.name)
	npc:SetAttribute("HatType", hatType.name)
	npc:SetAttribute("IsElder", isElder)
	npc:SetAttribute("SizeScale", sizeScale)

	npc.PrimaryPart = hrp
	npc.Parent = workspace

	return npc
end

-- Create the lobby area
local function CreateLobby()
	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"

	-- Main platform
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = Vector3.new(80, 3, 80)
	platform.Position = LobbyPosition
	platform.Anchored = true
	platform.BrickColor = BrickColor.new("Dark stone grey")
	platform.Material = Enum.Material.Slate
	platform.Parent = lobby

	-- Floor texture
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(70, 0.2, 70)
	floor.Position = LobbyPosition + Vector3.new(0, 1.6, 0)
	floor.Anchored = true
	floor.BrickColor = BrickColor.new("Brick yellow")
	floor.Material = Enum.Material.WoodPlanks
	floor.Parent = lobby

	-- Railings
	local railingPositions = {
		{pos = Vector3.new(35, 3.5, 0), size = Vector3.new(1, 5, 80)},
		{pos = Vector3.new(-35, 3.5, 0), size = Vector3.new(1, 5, 80)},
		{pos = Vector3.new(0, 3.5, 35), size = Vector3.new(80, 5, 1)},
		{pos = Vector3.new(0, 3.5, -35), size = Vector3.new(80, 5, 1)},
	}

	for i, rail in ipairs(railingPositions) do
		local railing = Instance.new("Part")
		railing.Name = "Railing" .. i
		railing.Size = rail.size
		railing.Position = LobbyPosition + rail.pos
		railing.Anchored = true
		railing.BrickColor = BrickColor.new("Reddish brown")
		railing.Material = Enum.Material.Wood
		railing.Parent = lobby
	end

	-- Title sign (big board)
	local signBoard = Instance.new("Part")
	signBoard.Name = "TitleBoard"
	signBoard.Size = Vector3.new(40, 15, 1)
	signBoard.Position = LobbyPosition + Vector3.new(0, 15, -30)
	signBoard.Anchored = true
	signBoard.BrickColor = BrickColor.new("Bright orange")
	signBoard.Material = Enum.Material.SmoothPlastic
	signBoard.Parent = lobby

	-- Title text
	local titleGui = Instance.new("SurfaceGui")
	titleGui.Name = "TitleGui"
	titleGui.Face = Enum.NormalId.Back
	titleGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	titleGui.PixelsPerStud = 20
	titleGui.Parent = signBoard

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "DRUGSTORE"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Parent = titleGui

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.Size = UDim2.new(1, 0, 0.3, 0)
	subtitleLabel.Position = UDim2.new(0, 0, 0.65, 0)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "ECONOMY GAME"
	subtitleLabel.TextColor3 = Color3.new(1, 1, 1)
	subtitleLabel.TextScaled = true
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.Parent = titleGui

	-- Decorative pillars
	local pillarPositions = {
		Vector3.new(-30, 8, -30),
		Vector3.new(30, 8, -30),
		Vector3.new(-30, 8, 30),
		Vector3.new(30, 8, 30),
	}

	for i, pos in ipairs(pillarPositions) do
		local pillar = Instance.new("Part")
		pillar.Name = "Pillar" .. i
		pillar.Size = Vector3.new(4, 14, 4)
		pillar.Position = LobbyPosition + pos
		pillar.Anchored = true
		pillar.BrickColor = BrickColor.new("Institutional white")
		pillar.Material = Enum.Material.Marble
		pillar.Parent = lobby
	end

	-- Medicine bottle decorations
	local bottleColors = {
		BrickColor.new("Bright red"),
		BrickColor.new("Bright blue"),
		BrickColor.new("Bright green"),
		BrickColor.new("Bright orange"),
	}

	for i = 1, 4 do
		local bottle = Instance.new("Part")
		bottle.Name = "Bottle" .. i
		bottle.Shape = Enum.PartType.Cylinder
		bottle.Size = Vector3.new(6, 3, 3)
		bottle.CFrame = CFrame.new(LobbyPosition + Vector3.new(-15 + (i * 8), 5, 25)) * CFrame.Angles(0, 0, math.rad(90))
		bottle.Anchored = true
		bottle.BrickColor = bottleColors[i]
		bottle.Material = Enum.Material.Glass
		bottle.Transparency = 0.3
		bottle.Parent = lobby
	end

	-- Lobby spawn point
	local lobbySpawn = Instance.new("SpawnLocation")
	lobbySpawn.Name = "LobbySpawn"
	lobbySpawn.Size = Vector3.new(10, 1, 10)
	lobbySpawn.Position = LobbyPosition + Vector3.new(0, 2, 10)
	lobbySpawn.Anchored = true
	lobbySpawn.CanCollide = false
	lobbySpawn.Transparency = 1
	lobbySpawn.Neutral = true
	lobbySpawn.Parent = lobby

	lobby.Parent = workspace
	return lobby
end

-- Create spawn location near tent (game area spawn)
local function CreateGameSpawnPoint()
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = TentPosition + Vector3.new(8, 0.5, 0)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Parent = workspace
	return spawn
end

-- Fix tent to have a proper PrimaryPart for detection
local function FixTent()
	local tent = workspace:FindFirstChild("Tent")
	if not tent then return end

	-- Find any part inside the tent to use as reference
	local tentFolder = tent:FindFirstChild("Tent")
	if tentFolder then
		local firstPart = tentFolder:FindFirstChildWhichIsA("BasePart")
		if firstPart then
			-- Create an invisible interaction part at tent center
			local interactPart = Instance.new("Part")
			interactPart.Name = "TentInteract"
			interactPart.Size = Vector3.new(8, 6, 8)
			interactPart.Position = TentPosition + Vector3.new(0, 3, 0)
			interactPart.Anchored = true
			interactPart.CanCollide = false
			interactPart.Transparency = 1
			interactPart.Parent = tent

			tent.PrimaryPart = interactPart
			print("Fixed tent PrimaryPart")
		end
	end
end

-- Main setup
local function SetupWorld()
	print("=== Setting up world ===")

	-- Create lobby first
	local existingLobby = workspace:FindFirstChild("Lobby")
	if existingLobby then existingLobby:Destroy() end
	CreateLobby()
	print("Lobby created")

	-- Fix tent
	FixTent()

	-- Create game spawn point (disabled initially - players spawn in lobby)
	local existingSpawn = workspace:FindFirstChild("SpawnLocation")
	if existingSpawn then existingSpawn:Destroy() end
	local gameSpawn = CreateGameSpawnPoint()
	gameSpawn.Enabled = false -- Disabled until game starts
	print("Game spawn point created (disabled)")

	-- Track used names
	local usedNames = {}

	-- Create villagers and beds at house centers
	for i = 1, 8 do
		-- Remove existing villager
		local existingVillager = workspace:FindFirstChild("Villager" .. i)
		if existingVillager then existingVillager:Destroy() end

		-- Remove existing bed
		local existingBed = workspace:FindFirstChild("Bed" .. i)
		if existingBed then existingBed:Destroy() end

		-- Get house data
		local houseInfo = HouseData[i]
		if not houseInfo then continue end

		-- Get villager name
		local villagerName = GameConfig:GetRandomVillagerName(usedNames)
		usedNames[villagerName] = true

		-- Create bed at house center with house rotation
		local bedPos = houseInfo.center
		local bed = CreateBed(bedPos, houseInfo.rotation)
		bed.Name = "Bed" .. i

		-- Calculate villager standing position OUTSIDE house
		-- 15 studs in front of house (negative Z in local space)
		local houseRotation = math.rad(houseInfo.rotation)
		local frontOffset = CFrame.Angles(0, houseRotation, 0) * CFrame.new(0, 0, -15)
		local villagerPos = houseInfo.center + frontOffset.Position + Vector3.new(0, 1, 0)

		local villager = CreateNPC("Villager" .. i, villagerPos, false)
		villager:SetAttribute("DisplayName", villagerName)
		villager:SetAttribute("BedName", "Bed" .. i)
		villager:SetAttribute("HouseIndex", i)

		print("Created " .. villagerName .. " at house " .. i)
	end

	-- Create merchant in CENTER - very visible
	local existingMerchant = workspace:FindFirstChild("Merchant")
	if existingMerchant then existingMerchant:Destroy() end

	local merchant = CreateNPC("Merchant", MerchantPosition, true)
	merchant:SetAttribute("DisplayName", "Merchant")
	print("Merchant created at center: " .. tostring(MerchantPosition))

	print("=== World setup complete ===")
end

-- Run setup
SetupWorld()
