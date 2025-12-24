-- EconomyManager.lua
-- Manages player money, unified medicine prices, and merchant state

local EconomyManager = {}
EconomyManager.__index = EconomyManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MedicineData = require(ReplicatedStorage:WaitForChild("MedicineData"))

-- Store player money
local PlayerMoney = {}

-- Track what each player has bought today (reset each day)
local PlayerPurchasesToday = {}

-- Current unified prices for all medicines (same for buy and sell)
local MedicinePrices = {}

-- Current merchant stock (8 random medicines available today)
local MerchantStock = {}

-- Merchant state
local MerchantAwake = true -- Only available during day

-- Current day number
local CurrentDay = 1

function EconomyManager.new(player)
	local self = setmetatable({}, EconomyManager)
	self.Player = player
	PlayerMoney[player.UserId] = GameConfig.Economy.StartingMoney
	PlayerPurchasesToday[player.UserId] = {}
	return self
end

function EconomyManager:GetMoney(player)
	return PlayerMoney[player.UserId] or 0
end

function EconomyManager:SetMoney(player, amount)
	PlayerMoney[player.UserId] = math.max(0, amount)
end

function EconomyManager:AddMoney(player, amount)
	local current = self:GetMoney(player)
	self:SetMoney(player, current + amount)
end

function EconomyManager:SpendMoney(player, amount)
	local current = self:GetMoney(player)
	if current >= amount then
		self:SetMoney(player, current - amount)
		return true
	end
	return false
end

function EconomyManager:CanAfford(player, amount)
	return self:GetMoney(player) >= amount
end

-- Merchant awake state (day/night)
function EconomyManager:SetMerchantAwake(awake)
	MerchantAwake = awake
end

function EconomyManager:IsMerchantAwake()
	return MerchantAwake
end

-- Initialize all medicine prices at base price
function EconomyManager:InitializePrices()
	MedicinePrices = {}
	for _, medicine in ipairs(MedicineData.Medicines) do
		MedicinePrices[medicine.id] = GameConfig.Economy.BasePrice
	end
	return MedicinePrices
end

-- Get current price for a medicine (same for buy and sell)
function EconomyManager:GetPrice(medicineId)
	if not MedicinePrices[medicineId] then
		MedicinePrices[medicineId] = GameConfig.Economy.BasePrice
	end
	return MedicinePrices[medicineId]
end

-- Get all current prices
function EconomyManager:GetAllPrices()
	return MedicinePrices
end

-- Fluctuate all prices (called on new day)
function EconomyManager:FluctuatePrices()
	local changes = {}
	for medicineId, currentPrice in pairs(MedicinePrices) do
		local oldPrice = currentPrice
		local newPrice = GameConfig:FluctuatePrice(currentPrice)
		MedicinePrices[medicineId] = newPrice
		changes[medicineId] = {
			old = oldPrice,
			new = newPrice,
			change = newPrice - oldPrice,
		}
	end
	return changes
end

-- Generate merchant stock (8 random medicines out of 24)
function EconomyManager:GenerateMerchantStock()
	MerchantStock = {}
	local medicines = MedicineData:GetRandomMedicines(GameConfig.Economy.MerchantStockCount)
	for _, medicine in ipairs(medicines) do
		table.insert(MerchantStock, {
			id = medicine.id,
			name = medicine.name,
			cures = medicine.cures,
		})
	end
	return MerchantStock
end

function EconomyManager:GetMerchantStock()
	if #MerchantStock == 0 then
		self:GenerateMerchantStock()
	end
	return MerchantStock
end

-- Check if merchant has a specific medicine
function EconomyManager:MerchantHasMedicine(medicineId)
	for _, item in ipairs(MerchantStock) do
		if item.id == medicineId then
			return true
		end
	end
	return false
end

-- Check if player already bought this medicine today
function EconomyManager:HasBoughtToday(player, medicineId)
	local purchases = PlayerPurchasesToday[player.UserId]
	if not purchases then return false end
	return purchases[medicineId] == true
end

-- Get merchant stock with availability for a specific player
function EconomyManager:GetMerchantStockForPlayer(player)
	local stock = {}
	for _, item in ipairs(MerchantStock) do
		table.insert(stock, {
			id = item.id,
			name = item.name,
			cures = item.cures,
			price = self:GetPrice(item.id),
			soldOut = self:HasBoughtToday(player, item.id),
		})
	end
	return stock
end

-- Buy medicine from merchant (limited to 1 per medicine per day)
function EconomyManager:BuyMedicine(player, medicineId)
	-- Check if merchant is awake
	if not MerchantAwake then
		return false, "Merchant is sleeping"
	end

	-- Check if merchant has this medicine
	if not self:MerchantHasMedicine(medicineId) then
		return false, "Not in stock today"
	end

	-- Check if already bought today
	if self:HasBoughtToday(player, medicineId) then
		return false, "Already purchased today"
	end

	local price = self:GetPrice(medicineId)
	if not self:CanAfford(player, price) then
		return false, "Not enough money"
	end

	self:SpendMoney(player, price)

	-- Mark as bought today
	if not PlayerPurchasesToday[player.UserId] then
		PlayerPurchasesToday[player.UserId] = {}
	end
	PlayerPurchasesToday[player.UserId][medicineId] = true

	return true, MedicineData.ByID[medicineId]
end

-- Sell medicine to villager (player earns money at same price)
function EconomyManager:SellMedicine(player, medicineId)
	local price = self:GetPrice(medicineId)
	self:AddMoney(player, price)
	return price
end

-- New day: refresh stock, fluctuate prices, reset purchases
function EconomyManager:ProcessNewDay()
	CurrentDay = CurrentDay + 1
	self:FluctuatePrices()
	self:GenerateMerchantStock()

	-- Reset all player purchases for new day
	for playerId, _ in pairs(PlayerPurchasesToday) do
		PlayerPurchasesToday[playerId] = {}
	end

	return CurrentDay
end

function EconomyManager:GetCurrentDay()
	return CurrentDay
end

function EconomyManager:SetCurrentDay(day)
	CurrentDay = day
end

function EconomyManager.RemovePlayer(player)
	PlayerMoney[player.UserId] = nil
	PlayerPurchasesToday[player.UserId] = nil
end

-- Initialize on first load
if next(MedicinePrices) == nil then
	EconomyManager:InitializePrices()
	EconomyManager:GenerateMerchantStock()
end

return EconomyManager
