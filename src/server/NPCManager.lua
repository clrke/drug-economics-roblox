-- NPCManager.lua
-- Manages villager NPCs with HP system, sicknesses, and poses

local NPCManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MedicineData = require(ReplicatedStorage:WaitForChild("MedicineData"))

-- Store all villager data
local Villagers = {}

-- Game start time for survival tracking
local GameStartTime = 0
local CurrentDay = 1

-- HP drain connection
local DrainConnection = nil

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
		local hpPercent = villager.HP / GameConfig.Villager.MaxHP

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
			healthFill.Size = UDim2.new(hpPercent, 0, 1, 0)

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

-- Set villager pose (lying on bed when sick, standing when healthy)
local function SetVillagerPose(villager)
	if not villager.Model then return end

	local hrp = villager.Model:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if not villager.IsAlive then
		-- Dead: lying flat
		if villager.BedPosition then
			hrp.CFrame = CFrame.new(villager.BedPosition) * CFrame.Angles(0, 0, math.rad(90))
		end
	elseif villager.Sickness then
		-- Sick: lying on bed
		if villager.BedPosition then
			hrp.CFrame = CFrame.new(villager.BedPosition + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90))
		end
	else
		-- Healthy: standing
		if villager.StandPosition then
			hrp.CFrame = CFrame.new(villager.StandPosition)
		end
	end
end

-- Create villager data
local function CreateVillagerData(index, model)
	local hrp = model:FindFirstChild("HumanoidRootPart")
	local bedPosition = hrp and hrp.Position or Vector3.new(0, 0, 0)

	return {
		Index = index,
		Model = model,
		DisplayName = model:GetAttribute("DisplayName") or ("Villager " .. index),
		Sickness = nil,
		NeededMedicine = nil,
		HP = GameConfig.Villager.MaxHP,
		IsAlive = true,
		BedPosition = bedPosition,
		StandPosition = bedPosition + Vector3.new(3, 0, 0), -- Stand beside bed
		LowHPWarned = false,
	}
end

function NPCManager:Initialize()
	Villagers = {}
	GameStartTime = os.time()
	CurrentDay = 1

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

			UpdateHealthBar(Villagers[i])
			SetVillagerPose(Villagers[i])
		else
			warn("Villager model not found: " .. villagerName)
		end
	end

	-- Start HP drain loop
	self:StartHPDrain()

	return Villagers
end

-- Start continuous HP drain for sick villagers
function NPCManager:StartHPDrain()
	if DrainConnection then
		DrainConnection:Disconnect()
	end

	DrainConnection = RunService.Heartbeat:Connect(function(dt)
		for _, villager in pairs(Villagers) do
			if villager.IsAlive and villager.Sickness then
				-- Drain HP
				villager.HP = villager.HP - (GameConfig.Villager.HPDrainPerSecond * dt)

				-- Check for death
				if villager.HP <= 0 then
					villager.HP = 0
					villager.IsAlive = false
					SetVillagerPose(villager)
				end

				-- Check for low HP warning
				local warningThreshold = GameConfig.Villager.MaxHP * GameConfig.Villager.LowHPWarningPercent
				if villager.HP <= warningThreshold and not villager.LowHPWarned then
					villager.LowHPWarned = true
					-- Warning event can be fired here
				end

				UpdateHealthBar(villager)
			end
		end
	end)
end

function NPCManager:StopHPDrain()
	if DrainConnection then
		DrainConnection:Disconnect()
		DrainConnection = nil
	end
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
	villager.HP = GameConfig.Villager.MaxHP -- Full restore
	villager.LowHPWarned = false

	UpdateHealthBar(villager)
	SetVillagerPose(villager)

	return true, "Cured!"
end

-- Process new day: give new sicknesses to healthy villagers
function NPCManager:ProcessNewDay()
	CurrentDay = CurrentDay + 1
	local deaths = {}
	local newSicknesses = {}

	for _, villager in pairs(Villagers) do
		if villager.IsAlive and not villager.Sickness then
			-- Healthy villagers get sick at start of new day
			local sickness = MedicineData:GetRandomSickness()
			villager.Sickness = sickness
			villager.NeededMedicine = MedicineData:GetMedicineForSickness(sickness)
			villager.LowHPWarned = false
			table.insert(newSicknesses, villager)
			UpdateHealthBar(villager)
			SetVillagerPose(villager)
		end
	end

	-- Check for deaths (from HP drain)
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

return NPCManager
