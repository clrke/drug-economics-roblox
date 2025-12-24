-- InventoryManager.spec.lua
-- Tests for InventoryManager module

return function(TestFramework)
	local describe = TestFramework.describe
	local it = TestFramework.it
	local expect = TestFramework.expect

	-- Create a mock InventoryManager for testing
	-- (The real one requires Roblox services)
	local function CreateMockInventoryManager()
		local InventoryManager = {}
		InventoryManager.__index = InventoryManager

		local CurrentDay = 1

		function InventoryManager.SetCurrentDay(day)
			CurrentDay = day
		end

		function InventoryManager.GetCurrentDay()
			return CurrentDay
		end

		function InventoryManager.new()
			local self = setmetatable({}, InventoryManager)
			self.Items = {}
			return self
		end

		function InventoryManager:AddMedicine(medicineId, currentDay)
			currentDay = currentDay or CurrentDay
			-- Mock expiry: use fixed value for testing predictability
			local expiryDay = currentDay + 10

			table.insert(self.Items, {
				medicineId = medicineId,
				expiryDay = expiryDay,
				purchaseDay = currentDay,
			})

			return expiryDay
		end

		function InventoryManager:RemoveMedicine(medicineId)
			local bestIndex = nil
			local closestExpiry = math.huge

			for i, item in ipairs(self.Items) do
				if item.medicineId == medicineId then
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

		function InventoryManager:HasMedicine(medicineId)
			for _, item in ipairs(self.Items) do
				if item.medicineId == medicineId and item.expiryDay >= CurrentDay then
					return true
				end
			end
			return false
		end

		function InventoryManager:GetMedicineCount(medicineId)
			local count = 0
			for _, item in ipairs(self.Items) do
				if item.medicineId == medicineId and item.expiryDay >= CurrentDay then
					count = count + 1
				end
			end
			return count
		end

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
					displayItem.daysUntilExpiry = item.expiryDay - CurrentDay
					table.insert(valid, displayItem)
				else
					displayItem.daysSinceExpiry = CurrentDay - item.expiryDay
					table.insert(expired, displayItem)
				end
			end

			table.sort(valid, function(a, b)
				return a.expiryDay < b.expiryDay
			end)

			table.sort(expired, function(a, b)
				return a.daysSinceExpiry < b.daysSinceExpiry
			end)

			return {
				valid = valid,
				expired = expired,
			}
		end

		function InventoryManager:GetTotalItems()
			local total = 0
			for _, item in ipairs(self.Items) do
				if item.expiryDay >= CurrentDay then
					total = total + 1
				end
			end
			return total
		end

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

		return InventoryManager
	end

	local InventoryManager = CreateMockInventoryManager()

	describe("InventoryManager.new", function()
		it("should create a new inventory instance", function()
			local inv = InventoryManager.new()
			expect(inv).toBeTruthy()
			expect(#inv.Items).toBe(0)
		end)
	end)

	describe("InventoryManager:AddMedicine", function()
		it("should add a medicine to inventory", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)

			local expiryDay = inv:AddMedicine(1, 1)

			expect(#inv.Items).toBe(1)
			expect(expiryDay).toBeGreaterThan(1)
		end)

		it("should store correct medicine ID", function()
			local inv = InventoryManager.new()
			inv:AddMedicine(5, 1)

			expect(inv.Items[1].medicineId).toBe(5)
		end)

		it("should store purchase day", function()
			local inv = InventoryManager.new()
			inv:AddMedicine(1, 3)

			expect(inv.Items[1].purchaseDay).toBe(3)
		end)

		it("should allow multiple of same medicine", function()
			local inv = InventoryManager.new()
			inv:AddMedicine(1, 1)
			inv:AddMedicine(1, 1)
			inv:AddMedicine(1, 1)

			expect(#inv.Items).toBe(3)
		end)
	end)

	describe("InventoryManager:HasMedicine", function()
		it("should return true when medicine exists", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)
			inv:AddMedicine(5, 1)

			expect(inv:HasMedicine(5)).toBeTruthy()
		end)

		it("should return false when medicine doesn't exist", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)

			expect(inv:HasMedicine(5)).toBeFalsy()
		end)

		it("should return false when medicine is expired", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)
			inv:AddMedicine(5, 1) -- Expires on day 11

			InventoryManager.SetCurrentDay(20) -- Past expiry

			expect(inv:HasMedicine(5)).toBeFalsy()
		end)
	end)

	describe("InventoryManager:GetMedicineCount", function()
		it("should return correct count", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)
			inv:AddMedicine(1, 1)
			inv:AddMedicine(1, 1)
			inv:AddMedicine(2, 1)

			expect(inv:GetMedicineCount(1)).toBe(2)
			expect(inv:GetMedicineCount(2)).toBe(1)
			expect(inv:GetMedicineCount(3)).toBe(0)
		end)

		it("should not count expired medicines", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)
			inv:AddMedicine(1, 1) -- Expires day 11

			InventoryManager.SetCurrentDay(20)

			expect(inv:GetMedicineCount(1)).toBe(0)
		end)
	end)

	describe("InventoryManager:RemoveMedicine", function()
		it("should remove medicine and return true", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)
			inv:AddMedicine(5, 1)

			local result = inv:RemoveMedicine(5)

			expect(result).toBeTruthy()
			expect(#inv.Items).toBe(0)
		end)

		it("should return false when medicine not found", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)

			local result = inv:RemoveMedicine(5)

			expect(result).toBeFalsy()
		end)

		it("should remove medicine closest to expiry first", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)

			-- Add medicines with different expiry dates
			table.insert(inv.Items, {medicineId = 1, expiryDay = 15, purchaseDay = 1})
			table.insert(inv.Items, {medicineId = 1, expiryDay = 5, purchaseDay = 1})  -- Closest to expiry
			table.insert(inv.Items, {medicineId = 1, expiryDay = 10, purchaseDay = 1})

			inv:RemoveMedicine(1)

			-- Should have removed the one expiring on day 5
			expect(#inv.Items).toBe(2)
			local hasDay5 = false
			for _, item in ipairs(inv.Items) do
				if item.expiryDay == 5 then hasDay5 = true end
			end
			expect(hasDay5).toBeFalsy()
		end)

		it("should not remove expired medicines", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)
			inv:AddMedicine(1, 1) -- Expires day 11

			InventoryManager.SetCurrentDay(20) -- Past expiry

			local result = inv:RemoveMedicine(1)
			expect(result).toBeFalsy()
		end)
	end)

	describe("InventoryManager:GetMedicineClosestToExpiry", function()
		it("should return item closest to expiry", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)

			table.insert(inv.Items, {medicineId = 1, expiryDay = 15, purchaseDay = 1})
			table.insert(inv.Items, {medicineId = 1, expiryDay = 5, purchaseDay = 1})
			table.insert(inv.Items, {medicineId = 1, expiryDay = 10, purchaseDay = 1})

			local closest = inv:GetMedicineClosestToExpiry(1)

			expect(closest.expiryDay).toBe(5)
		end)

		it("should return nil when no medicine found", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)

			local closest = inv:GetMedicineClosestToExpiry(1)

			expect(closest).toBeNil()
		end)
	end)

	describe("InventoryManager:GetAllItemsForDisplay", function()
		it("should separate valid and expired items", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(10)

			table.insert(inv.Items, {medicineId = 1, expiryDay = 15, purchaseDay = 1}) -- Valid
			table.insert(inv.Items, {medicineId = 2, expiryDay = 5, purchaseDay = 1})  -- Expired
			table.insert(inv.Items, {medicineId = 3, expiryDay = 20, purchaseDay = 1}) -- Valid

			local display = inv:GetAllItemsForDisplay()

			expect(#display.valid).toBe(2)
			expect(#display.expired).toBe(1)
		end)

		it("should include daysUntilExpiry for valid items", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(10)

			table.insert(inv.Items, {medicineId = 1, expiryDay = 15, purchaseDay = 1})

			local display = inv:GetAllItemsForDisplay()

			expect(display.valid[1].daysUntilExpiry).toBe(5) -- 15 - 10 = 5
		end)

		it("should include daysSinceExpiry for expired items", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(10)

			table.insert(inv.Items, {medicineId = 1, expiryDay = 7, purchaseDay = 1})

			local display = inv:GetAllItemsForDisplay()

			expect(display.expired[1].daysSinceExpiry).toBe(3) -- 10 - 7 = 3
		end)

		it("should sort valid items by expiry (closest first)", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)

			table.insert(inv.Items, {medicineId = 1, expiryDay = 20, purchaseDay = 1})
			table.insert(inv.Items, {medicineId = 2, expiryDay = 10, purchaseDay = 1})
			table.insert(inv.Items, {medicineId = 3, expiryDay = 15, purchaseDay = 1})

			local display = inv:GetAllItemsForDisplay()

			expect(display.valid[1].expiryDay).toBe(10)
			expect(display.valid[2].expiryDay).toBe(15)
			expect(display.valid[3].expiryDay).toBe(20)
		end)
	end)

	describe("InventoryManager:GetTotalItems", function()
		it("should count only valid items", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(10)

			table.insert(inv.Items, {medicineId = 1, expiryDay = 15, purchaseDay = 1}) -- Valid
			table.insert(inv.Items, {medicineId = 2, expiryDay = 5, purchaseDay = 1})  -- Expired
			table.insert(inv.Items, {medicineId = 3, expiryDay = 20, purchaseDay = 1}) -- Valid

			expect(inv:GetTotalItems()).toBe(2)
		end)
	end)

	describe("InventoryManager:GetExpiredCount", function()
		it("should count only expired items", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(10)

			table.insert(inv.Items, {medicineId = 1, expiryDay = 15, purchaseDay = 1}) -- Valid
			table.insert(inv.Items, {medicineId = 2, expiryDay = 5, purchaseDay = 1})  -- Expired
			table.insert(inv.Items, {medicineId = 3, expiryDay = 8, purchaseDay = 1})  -- Expired

			expect(inv:GetExpiredCount()).toBe(2)
		end)
	end)

	describe("InventoryManager:ClearInventory", function()
		it("should remove all items", function()
			local inv = InventoryManager.new()
			InventoryManager.SetCurrentDay(1)
			inv:AddMedicine(1, 1)
			inv:AddMedicine(2, 1)
			inv:AddMedicine(3, 1)

			inv:ClearInventory()

			expect(#inv.Items).toBe(0)
		end)
	end)
end
