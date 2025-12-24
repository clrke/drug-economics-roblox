-- GameManager.server.lua
-- Main server script that controls the Drugstore Economy Game

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Lighting = game:GetService("Lighting")

-- Wait for modules
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MedicineData = require(ReplicatedStorage:WaitForChild("MedicineData"))
local InventoryManager = require(ServerScriptService.Modules:WaitForChild("InventoryManager"))
local EconomyManager = require(ServerScriptService.Modules:WaitForChild("EconomyManager"))
local NPCManager = require(ServerScriptService.Modules:WaitForChild("NPCManager"))

-- Create RemoteEvents folder
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if RemoteEvents then RemoteEvents:Destroy() end
RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "RemoteEvents"
RemoteEvents.Parent = ReplicatedStorage

-- Helper to create remotes
local function CreateRemote(name, isFunction)
	local remote
	if isFunction then
		remote = Instance.new("RemoteFunction")
	else
		remote = Instance.new("RemoteEvent")
	end
	remote.Name = name
	remote.Parent = RemoteEvents
	return remote
end

-- === REMOTE EVENTS ===
local BuyMedicine = CreateRemote("BuyMedicine")
local CureVillager = CreateRemote("CureVillager")
local SkipDay = CreateRemote("SkipDay")
local UpdatePlayer = CreateRemote("UpdatePlayer")
local UpdateVillagers = CreateRemote("UpdateVillagers")
local UpdateMerchant = CreateRemote("UpdateMerchant")
local UpdatePrices = CreateRemote("UpdatePrices")
local UpdateTime = CreateRemote("UpdateTime")
local NewDay = CreateRemote("NewDay")
local GameOver = CreateRemote("GameOver")
local Notification = CreateRemote("Notification")

-- === REMOTE FUNCTIONS ===
local GetPlayerData = CreateRemote("GetPlayerData", true)
local GetVillagerData = CreateRemote("GetVillagerData", true)
local GetMerchantStock = CreateRemote("GetMerchantStock", true)
local GetPrices = CreateRemote("GetPrices", true)
local GetInventoryDisplay = CreateRemote("GetInventoryDisplay", true)

-- === GAME STATE ===
local CurrentDay = 1
local IsDay = true  -- true = day, false = night
local TimeRemaining = GameConfig.Time.DayDuration
local GameRunning = false
local GameStartTime = 0

-- Player data storage
local PlayerData = {}

-- === BROADCAST FUNCTIONS ===
local function BroadcastToAll(remote, data)
	for _, player in ipairs(Players:GetPlayers()) do
		remote:FireClient(player, data)
	end
end

local function SendPlayerUpdate(player)
	local data = PlayerData[player.UserId]
	if not data then return end

	UpdatePlayer:FireClient(player, {
		Money = EconomyManager:GetMoney(player),
		Inventory = data.Inventory:GetAllItemsForDisplay(),
		Day = CurrentDay,
	})
end

local function SendTimeUpdate()
	BroadcastToAll(UpdateTime, {
		day = CurrentDay,
		isDay = IsDay,
		timeRemaining = TimeRemaining,
		merchantAwake = EconomyManager:IsMerchantAwake(),
	})
end

local function BroadcastVillagers()
	local villagerData = {}
	for index, villager in pairs(NPCManager:GetAllVillagers()) do
		villagerData[index] = {
			Index = villager.Index,
			DisplayName = villager.DisplayName,
			Sickness = villager.Sickness,
			NeededMedicine = villager.NeededMedicine and villager.NeededMedicine.name or nil,
			NeededMedicineId = villager.NeededMedicine and villager.NeededMedicine.id or nil,
			HP = villager.HP,
			MaxHP = GameConfig.Villager.MaxHP,
			IsAlive = villager.IsAlive,
		}
	end
	BroadcastToAll(UpdateVillagers, villagerData)
end

-- === SET DAY/NIGHT LIGHTING ===
local function SetDayTime()
	Lighting.ClockTime = 12 -- Noon
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(150, 150, 150)
end

local function SetNightTime()
	Lighting.ClockTime = 0 -- Midnight
	Lighting.Brightness = 0.5
	Lighting.Ambient = Color3.fromRGB(50, 50, 80)
end

-- === PROCESS NEW DAY ===
local function ProcessNewDay()
	CurrentDay = CurrentDay + 1
	print("=== Day " .. CurrentDay .. " ===")

	-- Update all systems
	NPCManager:SetCurrentDay(CurrentDay)
	EconomyManager:SetCurrentDay(CurrentDay)
	InventoryManager.SetCurrentDay(CurrentDay)

	-- Process villager sicknesses (healthy get sick)
	local deaths, newSicknesses = NPCManager:ProcessNewDay()

	-- Process economy (fluctuate prices, refresh stock)
	EconomyManager:ProcessNewDay()

	-- Check game over
	if NPCManager:IsGameOver() then
		GameRunning = false
		local survivalDays = CurrentDay - 1

		print("=== GAME OVER ===")
		print("Survived " .. survivalDays .. " days")

		BroadcastToAll(GameOver, {
			survivalDays = survivalDays,
			message = "All villagers have died!"
		})

		NPCManager:StopHPDrain()
		return
	end

	-- Broadcast new day
	BroadcastToAll(NewDay, {
		day = CurrentDay,
		deaths = #deaths,
	})

	-- Send updates
	BroadcastVillagers()
	BroadcastToAll(UpdatePrices, EconomyManager:GetAllPrices())

	for _, player in ipairs(Players:GetPlayers()) do
		SendPlayerUpdate(player)
		UpdateMerchant:FireClient(player, EconomyManager:GetMerchantStockForPlayer(player))
	end
end

-- === INITIALIZATION ===
local function InitializeGame()
	print("=== Initializing Drugstore Economy Game ===")

	GameStartTime = os.time()
	CurrentDay = 1
	IsDay = true
	TimeRemaining = GameConfig.Time.DayDuration

	-- Set day lighting
	SetDayTime()

	-- Wait for world setup
	task.wait(2)

	-- Initialize systems
	NPCManager:Initialize()
	EconomyManager:InitializePrices()
	EconomyManager:GenerateMerchantStock()
	EconomyManager:SetMerchantAwake(true)

	-- Sync day to all systems
	NPCManager:SetCurrentDay(CurrentDay)
	EconomyManager:SetCurrentDay(CurrentDay)
	InventoryManager.SetCurrentDay(CurrentDay)

	GameRunning = true

	print("Game initialized! Day 1 starting...")
	print("Merchant has " .. #EconomyManager:GetMerchantStock() .. " medicines")
	print("Villagers: " .. NPCManager:GetAliveCount() .. " alive")
end

-- === PLAYER HANDLERS ===
local function OnPlayerAdded(player)
	print("Player joined: " .. player.Name)

	local inventory = InventoryManager.new(player)
	local economy = EconomyManager.new(player)

	PlayerData[player.UserId] = {
		Inventory = inventory,
		Economy = economy,
	}

	task.wait(1)

	-- Send initial data
	SendPlayerUpdate(player)
	BroadcastVillagers()
	UpdateMerchant:FireClient(player, EconomyManager:GetMerchantStockForPlayer(player))
	UpdatePrices:FireClient(player, EconomyManager:GetAllPrices())
	SendTimeUpdate()
end

local function OnPlayerRemoving(player)
	print("Player left: " .. player.Name)
	InventoryManager.RemovePlayer(player)
	EconomyManager.RemovePlayer(player)
	PlayerData[player.UserId] = nil
end

-- === BUY MEDICINE ===
BuyMedicine.OnServerEvent:Connect(function(player, medicineId)
	if not GameRunning then return end

	local data = PlayerData[player.UserId]
	if not data then return end

	local success, result = EconomyManager:BuyMedicine(player, medicineId)

	if success then
		local expiryDay = data.Inventory:AddMedicine(medicineId, CurrentDay)

		SendPlayerUpdate(player)
		UpdateMerchant:FireClient(player, EconomyManager:GetMerchantStockForPlayer(player))

		Notification:FireClient(player, {
			text = "Bought " .. result.name .. " for $" .. EconomyManager:GetPrice(medicineId) .. " (Expires: Day " .. expiryDay .. ")",
			color = "green"
		})

		print(player.Name .. " bought " .. result.name)
	else
		Notification:FireClient(player, {
			text = result,
			color = "red"
		})
	end
end)

-- === CURE VILLAGER ===
CureVillager.OnServerEvent:Connect(function(player, villagerIndex)
	if not GameRunning then return end

	local data = PlayerData[player.UserId]
	if not data then return end

	local villager = NPCManager:GetVillager(villagerIndex)
	if not villager or not villager.IsAlive or not villager.Sickness then
		Notification:FireClient(player, {
			text = "Cannot cure this villager",
			color = "red"
		})
		return
	end

	local neededMedicineId = villager.NeededMedicine and villager.NeededMedicine.id
	if not neededMedicineId then return end

	-- Check if player has the medicine
	if not data.Inventory:HasMedicine(neededMedicineId) then
		Notification:FireClient(player, {
			text = "You don't have " .. villager.NeededMedicine.name,
			color = "red"
		})
		return
	end

	-- Remove medicine (uses closest to expiry)
	data.Inventory:RemoveMedicine(neededMedicineId)

	-- Cure the villager
	local success, message = NPCManager:TryCure(villagerIndex, neededMedicineId)

	if success then
		local earnings = EconomyManager:SellMedicine(player, neededMedicineId)

		SendPlayerUpdate(player)
		BroadcastVillagers()

		Notification:FireClient(player, {
			text = villager.DisplayName .. " cured! Earned $" .. earnings,
			color = "green"
		})

		print(player.Name .. " cured " .. villager.DisplayName)
	end
end)

-- === SKIP DAY ===
SkipDay.OnServerEvent:Connect(function(player)
	if not GameRunning then return end

	print(player.Name .. " skipped to next day")

	Notification:FireClient(player, {
		text = "Skipping to next day...",
		color = "blue"
	})

	-- Transition to night briefly then to next day
	IsDay = false
	SetNightTime()
	EconomyManager:SetMerchantAwake(false)
	SendTimeUpdate()

	task.wait(1)

	-- Process new day
	IsDay = true
	TimeRemaining = GameConfig.Time.DayDuration
	SetDayTime()
	EconomyManager:SetMerchantAwake(true)
	ProcessNewDay()
	SendTimeUpdate()
end)

-- === REMOTE FUNCTIONS ===
GetPlayerData.OnServerInvoke = function(player)
	local data = PlayerData[player.UserId]
	if not data then return nil end

	return {
		Money = EconomyManager:GetMoney(player),
		Inventory = data.Inventory:GetAllItemsForDisplay(),
		Day = CurrentDay,
		IsDay = IsDay,
		TimeRemaining = TimeRemaining,
	}
end

GetVillagerData.OnServerInvoke = function(player, villagerIndex)
	if villagerIndex then
		local villager = NPCManager:GetVillager(villagerIndex)
		if villager then
			return {
				Index = villager.Index,
				DisplayName = villager.DisplayName,
				Sickness = villager.Sickness,
				NeededMedicine = villager.NeededMedicine and villager.NeededMedicine.name or nil,
				NeededMedicineId = villager.NeededMedicine and villager.NeededMedicine.id or nil,
				HP = villager.HP,
				MaxHP = GameConfig.Villager.MaxHP,
				IsAlive = villager.IsAlive,
			}
		end
	end

	local villagerData = {}
	for index, villager in pairs(NPCManager:GetAllVillagers()) do
		villagerData[index] = {
			Index = villager.Index,
			DisplayName = villager.DisplayName,
			Sickness = villager.Sickness,
			NeededMedicine = villager.NeededMedicine and villager.NeededMedicine.name or nil,
			NeededMedicineId = villager.NeededMedicine and villager.NeededMedicine.id or nil,
			HP = villager.HP,
			MaxHP = GameConfig.Villager.MaxHP,
			IsAlive = villager.IsAlive,
		}
	end
	return villagerData
end

GetMerchantStock.OnServerInvoke = function(player)
	return EconomyManager:GetMerchantStockForPlayer(player)
end

GetPrices.OnServerInvoke = function(player)
	return EconomyManager:GetAllPrices()
end

GetInventoryDisplay.OnServerInvoke = function(player)
	local data = PlayerData[player.UserId]
	if not data then return nil end
	return data.Inventory:GetAllItemsForDisplay()
end

-- === TIME LOOP ===
task.spawn(function()
	InitializeGame()

	while GameRunning do
		task.wait(1)
		TimeRemaining = TimeRemaining - 1

		-- Broadcast time every 10 seconds
		if TimeRemaining % 10 == 0 then
			SendTimeUpdate()
		end

		-- Phase transition
		if TimeRemaining <= 0 then
			if IsDay then
				-- Transition to night
				IsDay = false
				TimeRemaining = GameConfig.Time.NightDuration
				SetNightTime()
				EconomyManager:SetMerchantAwake(false)

				BroadcastToAll(Notification, {
					text = "Night has fallen. The merchant is sleeping.",
					color = "blue"
				})
			else
				-- Transition to day (new day)
				IsDay = true
				TimeRemaining = GameConfig.Time.DayDuration
				SetDayTime()
				EconomyManager:SetMerchantAwake(true)
				ProcessNewDay()
			end
			SendTimeUpdate()
		end

		-- Check for game over from HP drain
		if NPCManager:IsGameOver() and GameRunning then
			GameRunning = false
			local survivalDays = CurrentDay

			print("=== GAME OVER ===")
			print("Survived " .. survivalDays .. " days")

			BroadcastToAll(GameOver, {
				survivalDays = survivalDays,
				message = "All villagers have died!"
			})

			NPCManager:StopHPDrain()
		end
	end
end)

-- === CONNECT EVENTS ===
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(OnPlayerAdded, player)
end

print("GameManager loaded!")
