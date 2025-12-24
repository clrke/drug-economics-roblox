-- WorldSetup.server.lua
-- Creates NPCs, beds, and spawn point at game start

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- House positions (approximate centers for placing beds/villagers)
local HousePositions = {
	Vector3.new(-164, 28, 44),   -- House1
	Vector3.new(137, 32, 77),    -- House2
	Vector3.new(-88, 31, 130),   -- House3
	Vector3.new(27, 29, 148),    -- House4
	Vector3.new(-136, 29, -91),  -- House5
	Vector3.new(73, 29, -128),   -- House6
	Vector3.new(-46, 28, -163),  -- House7
	Vector3.new(157, 31, -43),   -- House8
}

local TentPosition = Vector3.new(-38, 1, 0.6)
local FountainPosition = Vector3.new(18, 1, -3)

-- Random appearance assets (clothing catalog IDs)
local ShirtIds = {
	607785314, 398633812, 102537952, 102537946, 102537934,
	1028596420, 3996936998, 6078569916, 148989963, 1536472465,
}

local PantsIds = {
	129458426, 1823536380, 382537569, 398635354, 1014001419,
	3442596224, 5105573435, 1243946494, 1236413403, 1236413612,
}

local SkinTones = {
	Color3.fromRGB(255, 204, 153),  -- Light
	Color3.fromRGB(234, 184, 146),  -- Light tan
	Color3.fromRGB(198, 156, 109),  -- Tan
	Color3.fromRGB(160, 95, 53),    -- Brown
	Color3.fromRGB(86, 66, 54),     -- Dark brown
	Color3.fromRGB(255, 220, 185),  -- Pale
}

local HairColors = {
	Color3.fromRGB(0, 0, 0),        -- Black
	Color3.fromRGB(50, 30, 20),     -- Dark brown
	Color3.fromRGB(100, 60, 30),    -- Brown
	Color3.fromRGB(180, 130, 70),   -- Light brown
	Color3.fromRGB(255, 200, 100),  -- Blonde
	Color3.fromRGB(200, 60, 30),    -- Red
	Color3.fromRGB(150, 150, 150),  -- Gray
}

-- Create a simple bed model
local function CreateBed(position, parent)
	local bed = Instance.new("Model")
	bed.Name = "Bed"

	-- Bed frame
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Size = Vector3.new(4, 0.5, 7)
	frame.Position = position + Vector3.new(0, 0.25, 0)
	frame.Anchored = true
	frame.BrickColor = BrickColor.new("Reddish brown")
	frame.Material = Enum.Material.Wood
	frame.Parent = bed

	-- Mattress
	local mattress = Instance.new("Part")
	mattress.Name = "Mattress"
	mattress.Size = Vector3.new(3.5, 0.4, 6.5)
	mattress.Position = position + Vector3.new(0, 0.7, 0)
	mattress.Anchored = true
	mattress.BrickColor = BrickColor.new("Institutional white")
	mattress.Material = Enum.Material.Fabric
	mattress.Parent = bed

	-- Pillow
	local pillow = Instance.new("Part")
	pillow.Name = "Pillow"
	pillow.Size = Vector3.new(2.5, 0.3, 1)
	pillow.Position = position + Vector3.new(0, 1, 2.5)
	pillow.Anchored = true
	pillow.BrickColor = BrickColor.new("White")
	pillow.Material = Enum.Material.Fabric
	pillow.Parent = bed

	bed.PrimaryPart = frame
	bed.Parent = parent

	return bed
end

-- Create R15 humanoid NPC with random appearance
local function CreateNPC(name, position, isMerchant)
	local npc = Instance.new("Model")
	npc.Name = name

	-- Create humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = npc

	-- Create R15 rig parts
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = true
	hrp.Position = position
	hrp.Parent = npc

	local torso = Instance.new("Part")
	torso.Name = "UpperTorso"
	torso.Size = Vector3.new(2, 1.6, 1)
	torso.Position = position + Vector3.new(0, 0.5, 0)
	torso.Anchored = true
	torso.Parent = npc

	local lowerTorso = Instance.new("Part")
	lowerTorso.Name = "LowerTorso"
	lowerTorso.Size = Vector3.new(2, 0.4, 1)
	lowerTorso.Position = position + Vector3.new(0, -0.4, 0)
	lowerTorso.Anchored = true
	lowerTorso.Parent = npc

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Position = position + Vector3.new(0, 1.9, 0)
	head.Anchored = true
	head.Parent = npc

	-- Add face
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	-- Arms
	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftUpperArm"
	leftArm.Size = Vector3.new(0.5, 1.2, 0.5)
	leftArm.Position = position + Vector3.new(-1.25, 0.4, 0)
	leftArm.Anchored = true
	leftArm.Parent = npc

	local rightArm = Instance.new("Part")
	rightArm.Name = "RightUpperArm"
	rightArm.Size = Vector3.new(0.5, 1.2, 0.5)
	rightArm.Position = position + Vector3.new(1.25, 0.4, 0)
	rightArm.Anchored = true
	rightArm.Parent = npc

	-- Legs
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "LeftUpperLeg"
	leftLeg.Size = Vector3.new(0.5, 1.4, 0.5)
	leftLeg.Position = position + Vector3.new(-0.5, -1.4, 0)
	leftLeg.Anchored = true
	leftLeg.Parent = npc

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "RightUpperLeg"
	rightLeg.Size = Vector3.new(0.5, 1.4, 0.5)
	rightLeg.Position = position + Vector3.new(0.5, -1.4, 0)
	rightLeg.Anchored = true
	rightLeg.Parent = npc

	-- Apply random skin tone
	local skinColor = SkinTones[math.random(1, #SkinTones)]
	for _, part in ipairs(npc:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.BrickColor = BrickColor.new(skinColor)
			part.Material = Enum.Material.SmoothPlastic
		end
	end

	-- Add shirt and pants
	local shirt = Instance.new("Shirt")
	shirt.ShirtTemplate = "rbxassetid://" .. ShirtIds[math.random(1, #ShirtIds)]
	shirt.Parent = npc

	local pants = Instance.new("Pants")
	pants.PantsTemplate = "rbxassetid://" .. PantsIds[math.random(1, #PantsIds)]
	pants.Parent = npc

	-- Merchant has special appearance
	if isMerchant then
		shirt.ShirtTemplate = "rbxassetid://607785314" -- Specific merchant shirt
		head.BrickColor = BrickColor.new("Bright yellow") -- Stand out
	end

	npc.PrimaryPart = hrp
	npc.Parent = workspace

	return npc
end

-- Create spawn location near tent
local function CreateSpawnPoint()
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = TentPosition + Vector3.new(10, 0.5, 0) -- Beside tent
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Parent = workspace
	return spawn
end

-- Main setup
local function SetupWorld()
	print("=== Setting up world ===")

	-- Create spawn point
	local existingSpawn = workspace:FindFirstChild("SpawnLocation")
	if existingSpawn then existingSpawn:Destroy() end
	CreateSpawnPoint()
	print("Spawn point created beside tent")

	-- Track used names
	local usedNames = {}

	-- Create beds and villagers in each house
	for i = 1, 8 do
		local houseName = "House" .. i
		local house = workspace:FindFirstChild(houseName)

		if house then
			-- Calculate bed position (lower than house position, inside)
			local bedPos = HousePositions[i] + Vector3.new(0, -25, 0) -- Adjust Y to be at floor level

			-- Check if bed already exists
			local existingBed = house:FindFirstChild("Bed")
			if existingBed then existingBed:Destroy() end

			-- Create bed inside house
			local bed = CreateBed(bedPos, house)

			-- Get unique villager name
			local villagerName = GameConfig:GetRandomVillagerName(usedNames)
			usedNames[villagerName] = true

			-- Check if villager already exists
			local existingVillager = workspace:FindFirstChild("Villager" .. i)
			if existingVillager then existingVillager:Destroy() end

			-- Create villager NPC near bed
			local villagerPos = bedPos + Vector3.new(0, 2, 0)
			local villager = CreateNPC("Villager" .. i, villagerPos, false)

			-- Store villager's display name
			villager:SetAttribute("DisplayName", villagerName)
			villager:SetAttribute("HouseNumber", i)

			print("Created bed and villager '" .. villagerName .. "' in " .. houseName)
		else
			warn("Could not find " .. houseName)
		end
	end

	-- Create merchant near fountain
	local existingMerchant = workspace:FindFirstChild("Merchant")
	if existingMerchant then existingMerchant:Destroy() end

	local merchantPos = FountainPosition + Vector3.new(5, 3, 5)
	local merchant = CreateNPC("Merchant", merchantPos, true)
	merchant:SetAttribute("DisplayName", "Merchant")
	print("Merchant created near fountain")

	print("=== World setup complete ===")
end

-- Run setup
SetupWorld()
