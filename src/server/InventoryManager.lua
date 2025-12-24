-- InventoryManager.lua
-- Manages player inventory with medicine expiry tracking

local InventoryManager = {}
InventoryManager.__index = InventoryManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- Store all player inventories
local PlayerInventories = {}

-- Reference to current day (set by GameManager)
local CurrentDay = 1

function InventoryManager.SetCurrentDay(day)
	CurrentDay = day
end

function InventoryManager.GetCurrentDay()
	return CurrentDay
end

function InventoryManager.new(player)
	local self = setmetatable({}, InventoryManager)
	self.Player = player
	-- Items now stored as array of {medicineId, expiryDay, purchaseDay}
	self.Items = {}
	PlayerInventories[player.UserId] = self
	return self
end

function InventoryManager:GetInventory(player)
	return PlayerInventories[player.UserId]
end

-- Add medicine with expiry date
function InventoryManager:AddMedicine(medicineId, currentDay)
	currentDay = currentDay or CurrentDay
	local expiryDays = GameConfig:GetRandomExpiryDays()
	local expiryDay = currentDay + expiryDays

	table.insert(self.Items, {
		medicineId = medicineId,
		expiryDay = expiryDay,
		purchaseDay = currentDay,
	})

	return expiryDay
end

-- Remove medicine (uses one closest to expiry that matches)
function InventoryManager:RemoveMedicine(medicineId)
	-- Find valid (not expired) medicine closest to expiry
	local bestIndex = nil
	local closestExpiry = math.huge

	for i, item in ipairs(self.Items) do
		if item.medicineId == medicineId then
			-- Check if not expired
			if item.expiryDay >= CurrentDay then
				if item.expiryDay < closestExpiry then
					closestExpiry = item.expiryDay
					bestIndex = i
				end
			end
		end
	end

	if bestIndex then
		table.remove(self.Items, bestIndex)
		return true
	end
	return false
end

-- Check if player has valid (non-expired) medicine
function InventoryManager:HasMedicine(medicineId)
	for _, item in ipairs(self.Items) do
		if item.medicineId == medicineId and item.expiryDay >= CurrentDay then
			return true
		end
	end
	return false
end

-- Get count of valid (non-expired) medicine
function InventoryManager:GetMedicineCount(medicineId)
	local count = 0
	for _, item in ipairs(self.Items) do
		if item.medicineId == medicineId and item.expiryDay >= CurrentDay then
			count = count + 1
		end
	end
	return count
end

-- Get the medicine item closest to expiry (for auto-select when curing)
function InventoryManager:GetMedicineClosestToExpiry(medicineId)
	local bestItem = nil
	local closestExpiry = math.huge

	for _, item in ipairs(self.Items) do
		if item.medicineId == medicineId and item.expiryDay >= CurrentDay then
			if item.expiryDay < closestExpiry then
				closestExpiry = item.expiryDay
				bestItem = item
			end
		end
	end

	return bestItem
end

-- Get all items formatted for client display
-- Returns: {valid = {...}, expired = {...}}
function InventoryManager:GetAllItemsForDisplay()
	local valid = {}
	local expired = {}

	for _, item in ipairs(self.Items) do
		local displayItem = {
			medicineId = item.medicineId,
			expiryDay = item.expiryDay,
			purchaseDay = item.purchaseDay,
		}

		if item.expiryDay >= CurrentDay then
			-- Valid medicine - show "Expires: Day X"
			displayItem.daysUntilExpiry = item.expiryDay - CurrentDay
			table.insert(valid, displayItem)
		else
			-- Expired medicine - show "Expired X days ago"
			displayItem.daysSinceExpiry = CurrentDay - item.expiryDay
			table.insert(expired, displayItem)
		end
	end

	-- Sort valid by expiry (closest first)
	table.sort(valid, function(a, b)
		return a.expiryDay < b.expiryDay
	end)

	-- Sort expired by how long ago (most recent first)
	table.sort(expired, function(a, b)
		return a.daysSinceExpiry < b.daysSinceExpiry
	end)

	return {
		valid = valid,
		expired = expired,
	}
end

-- Get simple count-based inventory (for compatibility)
function InventoryManager:GetAllItems()
	local counts = {}
	for _, item in ipairs(self.Items) do
		if item.expiryDay >= CurrentDay then
			counts[item.medicineId] = (counts[item.medicineId] or 0) + 1
		end
	end
	return counts
end

-- Get total valid items
function InventoryManager:GetTotalItems()
	local total = 0
	for _, item in ipairs(self.Items) do
		if item.expiryDay >= CurrentDay then
			total = total + 1
		end
	end
	return total
end

-- Get total expired items
function InventoryManager:GetExpiredCount()
	local count = 0
	for _, item in ipairs(self.Items) do
		if item.expiryDay < CurrentDay then
			count = count + 1
		end
	end
	return count
end

function InventoryManager:ClearInventory()
	self.Items = {}
end

function InventoryManager.RemovePlayer(player)
	PlayerInventories[player.UserId] = nil
end

return InventoryManager
