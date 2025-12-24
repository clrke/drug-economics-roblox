-- NPCManager.lua
-- Manages villager NPCs with HP system, sicknesses, and poses

local NPCManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MedicineData = require(ReplicatedStorage:WaitForChild("MedicineData"))

-- Store all villager data
local Villagers = {}

-- Game time tracking (for HP calculation)
local CurrentDay = 1
local CurrentPhaseIsDay = true
local CurrentPhaseElapsed = 0  -- seconds into current phase

-- House data for positioning (from exploration)
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

-- Face textures
local FACE_HAPPY = "rbxasset://textures/face.png"
local FACE_SAD = "rbxassetid://147144198" -- Built-in sad face

-- Calculate total game time in seconds
local function GetGameTime()
	local dayDuration = GameConfig.Time.DayDuration + GameConfig.Time.NightDuration
	local dayTime = (CurrentDay - 1) * dayDuration

	-- Add current phase progress
	if CurrentPhaseIsDay then
		dayTime = dayTime + CurrentPhaseElapsed
	else
		dayTime = dayTime + GameConfig.Time.DayDuration + CurrentPhaseElapsed
	end

	return dayTime
end

-- Calculate villager HP based on game time (not real-time)
local function CalculateVillagerHP(villager)
	if not villager.IsAlive then return 0 end
	if not villager.Sickness then return GameConfig.Villager.MaxHP end
	if not villager.SickSinceGameTime then return GameConfig.Villager.MaxHP end

	local currentGameTime = GetGameTime()
	local sickDuration = currentGameTime - villager.SickSinceGameTime
	local hpLost = sickDuration * GameConfig.Villager.HPDrainPerSecond
	local currentHP = GameConfig.Villager.MaxHP - hpLost

	return math.max(0, currentHP)
end

-- Create health bar billboard above villager
local function CreateHealthBar(villagerModel)
	local head = villagerModel:FindFirstChild("Head")
	if not head then return nil end

	local existing = villagerModel:FindFirstChild("HealthBillboard")
	if existing then existing:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBillboard"
	billboard.Size = UDim2.new(0, 120, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 50
	billboard.Adornee = head
	billboard.Parent = villagerModel

	-- Background frame
	local bgFrame = Instance.new("Frame")
	bgFrame.Name = "Background"
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bgFrame.BackgroundTransparency = 0.3
	bgFrame.BorderSizePixel = 0
	bgFrame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = bgFrame

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = villagerModel:GetAttribute("DisplayName") or villagerModel.Name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = bgFrame

	-- Health bar background
	local healthBg = Instance.new("Frame")
	healthBg.Name = "HealthBg"
	healthBg.Size = UDim2.new(0.9, 0, 0.35, 0)
	healthBg.Position = UDim2.new(0.05, 0, 0.5, 0)
	healthBg.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = bgFrame

	local healthCorner = Instance.new("UICorner")
	healthCorner.CornerRadius = UDim.new(0, 4)
	healthCorner.Parent = healthBg

	-- Health bar fill
	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = healthFill

	return billboard
end

-- Update villager health bar
local function UpdateHealthBar(villager)
	if not villager.Model then return end

	local billboard = villager.Model:FindFirstChild("HealthBillboard")
	if not billboard then
		billboard = CreateHealthBar(villager.Model)
	end
	if not billboard then return end

	local bgFrame = billboard:FindFirstChild("Background")
	if not bgFrame then return end

	local healthBg = bgFrame:FindFirstChild("HealthBg")
	local healthFill = healthBg and healthBg:FindFirstChild("HealthFill")
	local nameLabel = bgFrame:FindFirstChild("NameLabel")

	-- Calculate current HP from game time
	local currentHP = CalculateVillagerHP(villager)

	if not villager.IsAlive then
		-- Dead
		if nameLabel then
			nameLabel.Text = villager.DisplayName .. " (DEAD)"
			nameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
		if healthFill then
			healthFill.Size = UDim2.new(0, 0, 1, 0)
			healthFill.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		end
	else
		-- Alive
		local hpPercent = currentHP / GameConfig.Villager.MaxHP

		if nameLabel then
			if villager.Sickness then
				nameLabel.Text = villager.DisplayName .. " - " .. villager.Sickness
				nameLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
			else
				nameLabel.Text = villager.DisplayName .. " - Healthy"
				nameLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
			end
		end

		if healthFill then
			healthFill.Size = UDim2.new(math.max(0, hpPercent), 0, 1, 0)

			-- Color based on HP
			if hpPercent > 0.66 then
				healthFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
			elseif hpPercent > 0.33 then
				healthFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
			else
				healthFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
			end
		end
	end
end

-- Update villager face texture based on health
local function UpdateVillagerFace(villager)
	if not villager.Model then return end

	local head = villager.Model:FindFirstChild("Head")
	if not head then return end

	local face = head:FindFirstChild("face")
	if not face then return end

	-- Set face texture based on health
	if not villager.IsAlive then
		face.Texture = FACE_SAD
	elseif villager.Sickness then
		face.Texture = FACE_SAD
	else
		face.Texture = FACE_HAPPY
	end

	-- Fix face orientation: when lying down, face should point UP (Top), when standing point FORWARD (Front)
	local isLying = not villager.IsAlive or villager.Sickness
	if isLying then
		face.Face = Enum.NormalId.Top
	else
		face.Face = Enum.NormalId.Front
	end
end

-- R15 Body part offsets for standing pose (relative to HumanoidRootPart position)
local StandingOffsets = {
	Head = Vector3.new(0, 2.1, 0),
	UpperTorso = Vector3.new(0, 0.9, 0),
	LowerTorso = Vector3.new(0, 0.1, 0),
	Torso = Vector3.new(0, 0.5, 0),  -- Legacy invisible part
	["Left Arm"] = Vector3.new(-1.1, 0.8, 0),
	["Right Arm"] = Vector3.new(1.1, 0.8, 0),
	LeftLowerArm = Vector3.new(-1.1, 0, 0),
	RightLowerArm = Vector3.new(1.1, 0, 0),
	LeftHand = Vector3.new(-1.1, -0.5, 0),
	RightHand = Vector3.new(1.1, -0.5, 0),
	["Left Leg"] = Vector3.new(-0.5, -0.6, 0),
	["Right Leg"] = Vector3.new(0.5, -0.6, 0),
	LeftLowerLeg = Vector3.new(-0.5, -1.4, 0),
	RightLowerLeg = Vector3.new(0.5, -1.4, 0),
	LeftFoot = Vector3.new(-0.5, -1.95, 0.1),
	RightFoot = Vector3.new(0.5, -1.95, 0.1),
}

-- R15 Body part offsets for lying pose (on back, on bed)
local LyingOffsets = {
	Head = Vector3.new(2.1, 0.8, 0),
	UpperTorso = Vector3.new(0.3, 0.8, 0),
	LowerTorso = Vector3.new(-0.5, 0.8, 0),
	Torso = Vector3.new(0, 0.8, 0),  -- Legacy invisible part
	["Left Arm"] = Vector3.new(0.3, 0.8, 1.1),
	["Right Arm"] = Vector3.new(0.3, 0.8, -1.1),
	LeftLowerArm = Vector3.new(-0.5, 0.8, 1.1),
	RightLowerArm = Vector3.new(-0.5, 0.8, -1.1),
	LeftHand = Vector3.new(-1, 0.8, 1.1),
	RightHand = Vector3.new(-1, 0.8, -1.1),
	["Left Leg"] = Vector3.new(-1.2, 0.8, 0.5),
	["Right Leg"] = Vector3.new(-1.2, 0.8, -0.5),
	LeftLowerLeg = Vector3.new(-2, 0.8, 0.5),
	RightLowerLeg = Vector3.new(-2, 0.8, -0.5),
	LeftFoot = Vector3.new(-2.5, 0.8, 0.5),
	RightFoot = Vector3.new(-2.5, 0.8, -0.5),
}

-- Move all body parts to create a pose
local function SetVillagerPose(villager)
	if not villager.Model then return end

	local houseIndex = villager.Index
	local houseInfo = HouseData[houseIndex]
	if not houseInfo then return end

	-- Get size scale from NPC attributes (for R15 variations)
	local sizeScale = villager.Model:GetAttribute("SizeScale") or 1

	local houseRotation = math.rad(houseInfo.rotation)
	local bedPosition = houseInfo.center + Vector3.new(0, 1, 0) -- Bed is at floor level + 1

	-- Calculate standing position outside house (15 studs in front direction)
	local frontOffset = CFrame.Angles(0, houseRotation, 0) * CFrame.new(0, 0, -15)
	local standPosition = houseInfo.center + frontOffset.Position

	local isLying = not villager.IsAlive or villager.Sickness
	local basePosition = isLying and bedPosition or standPosition
	local offsets = isLying and LyingOffsets or StandingOffsets

	-- Calculate rotation for the pose
	local poseRotation
	if isLying then
		-- Lying: rotated to be on back on bed, aligned with house
		poseRotation = CFrame.Angles(math.rad(-90), houseRotation, 0)
	else
		-- Standing: facing away from house
		poseRotation = CFrame.Angles(0, houseRotation, 0)
	end

	-- Move HumanoidRootPart
	local hrp = villager.Model:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = CFrame.new(basePosition) * poseRotation
	end

	-- Move all body parts with proper offsets
	for partName, offset in pairs(offsets) do
		local part = villager.Model:FindFirstChild(partName)
		if part then
			-- Scale offset by size
			local scaledOffset = offset * sizeScale

			-- Transform offset by house rotation
			if isLying then
				local worldOffset = CFrame.Angles(0, houseRotation, 0) * CFrame.new(scaledOffset)
				part.CFrame = CFrame.new(basePosition + worldOffset.Position) * poseRotation
			else
				part.CFrame = CFrame.new(basePosition + scaledOffset) * CFrame.Angles(0, houseRotation, 0)
			end
		end
	end

	-- Move hair and accessories with head
	local head = villager.Model:FindFirstChild("Head")
	if head then
		local hairFolder = villager.Model:FindFirstChild("Hair")
		if hairFolder then
			for _, hairPart in ipairs(hairFolder:GetChildren()) do
				if hairPart:IsA("BasePart") then
					-- Hair stays on top of head
					local hairOffset = hairPart.Position - head.Position
					if isLying then
						-- Recalculate position relative to lying head
						local headPos = head.Position
						hairPart.CFrame = CFrame.new(headPos + hairOffset) * poseRotation
					end
				end
			end
		end

		local hatFolder = villager.Model:FindFirstChild("HatAccessory")
		if hatFolder then
			for _, hatPart in ipairs(hatFolder:GetChildren()) do
				if hatPart:IsA("BasePart") then
					local hatOffset = hatPart.Position - head.Position
					if isLying then
						local headPos = head.Position
						hatPart.CFrame = CFrame.new(headPos + hatOffset) * poseRotation
					end
				end
			end
		end
	end

	-- Update face
	UpdateVillagerFace(villager)
end

-- Create villager data
local function CreateVillagerData(index, model)
	return {
		Index = index,
		Model = model,
		DisplayName = model:GetAttribute("DisplayName") or ("Villager " .. index),
		Sickness = nil,
		NeededMedicine = nil,
		SickSinceGameTime = nil,  -- Game time when became sick (for HP calculation)
		IsAlive = true,
		LowHPWarned = false,
	}
end

function NPCManager:Initialize()
	Villagers = {}
	CurrentDay = 1
	CurrentPhaseIsDay = true
	CurrentPhaseElapsed = 0

	-- Wait for WorldSetup to create villagers
	task.wait(1)

	for i = 1, GameConfig.Villager.Count do
		local villagerName = "Villager" .. i
		local villagerModel = workspace:FindFirstChild(villagerName)
		if villagerModel then
			Villagers[i] = CreateVillagerData(i, villagerModel)

			-- All start with sickness
			local sickness = MedicineData:GetRandomSickness()
			Villagers[i].Sickness = sickness
			Villagers[i].NeededMedicine = MedicineData:GetMedicineForSickness(sickness)
			Villagers[i].SickSinceGameTime = GetGameTime()

			SetVillagerPose(Villagers[i])
			UpdateHealthBar(Villagers[i])
		else
			warn("Villager model not found: " .. villagerName)
		end
	end

	return Villagers
end

-- Update game time from GameManager (called every second)
function NPCManager:UpdateGameTime(day, isDay, phaseElapsed)
	CurrentDay = day
	CurrentPhaseIsDay = isDay
	CurrentPhaseElapsed = phaseElapsed

	-- Check for deaths and update health bars
	self:CheckForDeaths()
	self:UpdateAllHealthBars()
end

-- Check if any villagers have died from HP drain
function NPCManager:CheckForDeaths()
	for _, villager in pairs(Villagers) do
		if villager.IsAlive and villager.Sickness then
			local hp = CalculateVillagerHP(villager)

			if hp <= 0 then
				villager.IsAlive = false
				SetVillagerPose(villager)
			end

			-- Check for low HP warning
			local warningThreshold = GameConfig.Villager.MaxHP * GameConfig.Villager.LowHPWarningPercent
			if hp <= warningThreshold and not villager.LowHPWarned then
				villager.LowHPWarned = true
			end
		end
	end
end

-- Get villager's current HP (calculated from game time)
function NPCManager:GetVillagerHP(villagerIndex)
	local villager = Villagers[villagerIndex]
	if not villager then return 0 end
	return CalculateVillagerHP(villager)
end

-- Legacy function for compatibility - no longer needed with game-time HP
function NPCManager:StopHPDrain()
	-- No-op: HP is now calculated from game time, not drained in real-time
end

function NPCManager:GetVillager(index)
	return Villagers[index]
end

function NPCManager:GetAllVillagers()
	return Villagers
end

function NPCManager:GetSickVillagers()
	local sick = {}
	for _, villager in pairs(Villagers) do
		if villager.IsAlive and villager.Sickness then
			table.insert(sick, villager)
		end
	end
	return sick
end

-- Try to cure a villager (only correct medicine allowed)
function NPCManager:TryCure(villagerIndex, medicineId)
	local villager = Villagers[villagerIndex]
	if not villager or not villager.IsAlive or not villager.Sickness then
		return false, "Cannot cure"
	end

	local medicine = MedicineData.ByID[medicineId]
	if not medicine then
		return false, "Invalid medicine"
	end

	-- Only allow correct medicine
	if medicine.cures ~= villager.Sickness then
		return false, "Wrong medicine"
	end

	-- Cure the villager
	villager.Sickness = nil
	villager.NeededMedicine = nil
	villager.SickSinceGameTime = nil  -- Clear sick time (HP becomes full)
	villager.LowHPWarned = false

	UpdateHealthBar(villager)
	SetVillagerPose(villager)

	return true, "Cured!"
end

-- Process new day: give new sicknesses to healthy villagers
-- NOTE: CurrentDay is already set by GameManager via SetCurrentDay before calling this
function NPCManager:ProcessNewDay()
	-- Reset phase tracking for new day (do NOT increment CurrentDay here - GameManager does it)
	CurrentPhaseIsDay = true
	CurrentPhaseElapsed = 0

	local deaths = {}
	local newSicknesses = {}

	for _, villager in pairs(Villagers) do
		if villager.IsAlive and not villager.Sickness then
			-- Healthy villagers get sick at start of new day
			local sickness = MedicineData:GetRandomSickness()
			villager.Sickness = sickness
			villager.NeededMedicine = MedicineData:GetMedicineForSickness(sickness)
			villager.SickSinceGameTime = GetGameTime()  -- Set sick time for HP calculation
			villager.LowHPWarned = false
			table.insert(newSicknesses, villager)
			UpdateHealthBar(villager)
			SetVillagerPose(villager)
		end
	end

	-- Check for deaths (from HP drain based on game time)
	for _, villager in pairs(Villagers) do
		if not villager.IsAlive then
			table.insert(deaths, villager)
		end
	end

	return deaths, newSicknesses
end

function NPCManager:UpdateAllHealthBars()
	for _, villager in pairs(Villagers) do
		UpdateHealthBar(villager)
	end
end

function NPCManager:GetAliveCount()
	local count = 0
	for _, villager in pairs(Villagers) do
		if villager.IsAlive then
			count = count + 1
		end
	end
	return count
end

function NPCManager:IsGameOver()
	return self:GetAliveCount() == 0
end

function NPCManager:GetSurvivalDays()
	return CurrentDay
end

function NPCManager:GetCurrentDay()
	return CurrentDay
end

function NPCManager:SetCurrentDay(day)
	CurrentDay = day
end

-- ============================================
-- TEST HELPER FUNCTIONS (prefixed with _)
-- ============================================

function NPCManager:_reset()
	Villagers = {}
	CurrentDay = 1
	CurrentPhaseIsDay = true
	CurrentPhaseElapsed = 0
end

function NPCManager:_setVillagerHP(index, hp)
	local villager = Villagers[index]
	if not villager then return end

	-- For testing: directly set HP by adjusting SickSinceGameTime
	if hp <= 0 then
		villager.IsAlive = false
		villager.SickSinceGameTime = 0 -- died long ago
	else
		-- Calculate what SickSinceGameTime would need to be for this HP
		local hpLost = GameConfig.Villager.MaxHP - hp
		local sickDuration = hpLost / GameConfig.Villager.HPDrainPerSecond
		villager.SickSinceGameTime = GetGameTime() - sickDuration

		-- Check low HP warning
		local warningThreshold = GameConfig.Villager.MaxHP * GameConfig.Villager.LowHPWarningPercent
		if hp <= warningThreshold and not villager.LowHPWarned then
			villager.LowHPWarned = true
		end
	end

	-- Update villager.HP for test access
	villager.HP = hp
end

function NPCManager:SimulateDrain(seconds)
	-- Advance game time
	CurrentPhaseElapsed = CurrentPhaseElapsed + seconds

	-- Update all villagers
	for _, villager in pairs(Villagers) do
		if villager.IsAlive and villager.Sickness then
			local hp = CalculateVillagerHP(villager)
			villager.HP = hp

			-- Check low HP warning
			local warningThreshold = GameConfig.Villager.MaxHP * GameConfig.Villager.LowHPWarningPercent
			if hp <= warningThreshold and not villager.LowHPWarned then
				villager.LowHPWarned = true
			end

			-- Check death
			if hp <= 0 then
				villager.IsAlive = false
				villager.HP = 0
			end
		end
	end
end

return NPCManager
