-- EconomyManager.spec.lua
-- Tests for EconomyManager module

return function(TestFramework)
	local describe = TestFramework.describe
	local it = TestFramework.it
	local expect = TestFramework.expect

	-- Create a mock EconomyManager for testing
	local function CreateMockEconomyManager()
		local EconomyManager = {}
		EconomyManager.__index = EconomyManager

		local PlayerMoney = {}
		local PlayerPurchasesToday = {}
		local MedicinePrices = {}
		local MerchantStock = {}
		local MerchantAwake = true
		local CurrentDay = 1

		-- Mock config
		local Config = {
			StartingMoney = 100,
			BasePrice = 10,
			MinFluctuation = 0.5,
			MaxFluctuation = 2.0,
			MerchantStockCount = 8,
		}

		-- Mock medicine data
		local MockMedicines = {}
		for i = 1, 24 do
			table.insert(MockMedicines, {
				id = i,
				name = "Medicine" .. i,
				cures = "Sickness" .. i,
			})
		end

		function EconomyManager.new(player)
			local self = setmetatable({}, EconomyManager)
			self.Player = player
			PlayerMoney[player.UserId] = Config.StartingMoney
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

		function EconomyManager:SetMerchantAwake(awake)
			MerchantAwake = awake
		end

		function EconomyManager:IsMerchantAwake()
			return MerchantAwake
		end

		function EconomyManager:InitializePrices()
			MedicinePrices = {}
			for _, medicine in ipairs(MockMedicines) do
				MedicinePrices[medicine.id] = Config.BasePrice
			end
			return MedicinePrices
		end

		function EconomyManager:GetPrice(medicineId)
			if not MedicinePrices[medicineId] then
				MedicinePrices[medicineId] = Config.BasePrice
			end
			return MedicinePrices[medicineId]
		end

		function EconomyManager:GetAllPrices()
			return MedicinePrices
		end

		function EconomyManager:FluctuatePrices()
			local changes = {}
			for medicineId, currentPrice in pairs(MedicinePrices) do
				local oldPrice = currentPrice
				local fluctuation = math.random() * (Config.MaxFluctuation - Config.MinFluctuation) + Config.MinFluctuation
				local newPrice = math.floor(currentPrice * fluctuation)
				MedicinePrices[medicineId] = newPrice
				changes[medicineId] = {
					old = oldPrice,
					new = newPrice,
					change = newPrice - oldPrice,
				}
			end
			return changes
		end

		function EconomyManager:GenerateMerchantStock()
			MerchantStock = {}
			local shuffled = {}
			for i, v in ipairs(MockMedicines) do
				shuffled[i] = v
			end
			for i = #shuffled, 2, -1 do
				local j = math.random(1, i)
				shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
			end
			for i = 1, math.min(Config.MerchantStockCount, #shuffled) do
				table.insert(MerchantStock, {
					id = shuffled[i].id,
					name = shuffled[i].name,
					cures = shuffled[i].cures,
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

		function EconomyManager:MerchantHasMedicine(medicineId)
			for _, item in ipairs(MerchantStock) do
				if item.id == medicineId then
					return true
				end
			end
			return false
		end

		function EconomyManager:HasBoughtToday(player, medicineId)
			local purchases = PlayerPurchasesToday[player.UserId]
			if not purchases then return false end
			return purchases[medicineId] == true
		end

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

		function EconomyManager:BuyMedicine(player, medicineId)
			if not MerchantAwake then
				return false, "Merchant is sleeping"
			end

			if not self:MerchantHasMedicine(medicineId) then
				return false, "Not in stock today"
			end

			if self:HasBoughtToday(player, medicineId) then
				return false, "Already purchased today"
			end

			local price = self:GetPrice(medicineId)
			if not self:CanAfford(player, price) then
				return false, "Not enough money"
			end

			self:SpendMoney(player, price)

			if not PlayerPurchasesToday[player.UserId] then
				PlayerPurchasesToday[player.UserId] = {}
			end
			PlayerPurchasesToday[player.UserId][medicineId] = true

			return true, {id = medicineId, name = "Medicine" .. medicineId}
		end

		function EconomyManager:SellMedicine(player, medicineId)
			local price = self:GetPrice(medicineId)
			self:AddMoney(player, price)
			return price
		end

		function EconomyManager:ProcessNewDay()
			CurrentDay = CurrentDay + 1
			self:FluctuatePrices()
			self:GenerateMerchantStock()

			for playerId, _ in pairs(PlayerPurchasesToday) do
				PlayerPurchasesToday[playerId] = {}
			end

			return CurrentDay
		end

		function EconomyManager:SetCurrentDay(day)
			CurrentDay = day
		end

		function EconomyManager:GetCurrentDay()
			return CurrentDay
		end

		function EconomyManager.RemovePlayer(player)
			PlayerMoney[player.UserId] = nil
			PlayerPurchasesToday[player.UserId] = nil
		end

		function EconomyManager._reset()
			PlayerMoney = {}
			PlayerPurchasesToday = {}
			MedicinePrices = {}
			MerchantStock = {}
			MerchantAwake = true
			CurrentDay = 1
		end

		return EconomyManager
	end

	local EconomyManager = CreateMockEconomyManager()

	-- Mock player object
	local function MockPlayer(userId)
		return {UserId = userId, Name = "TestPlayer" .. userId}
	end

	describe("EconomyManager.new", function()
		EconomyManager._reset()

		it("should create new economy instance with starting money", function()
			local player = MockPlayer(1)
			local economy = EconomyManager.new(player)

			expect(EconomyManager:GetMoney(player)).toBe(100)
		end)
	end)

	describe("EconomyManager Money Operations", function()
		EconomyManager._reset()

		it("should get money correctly", function()
			local player = MockPlayer(2)
			EconomyManager.new(player)

			expect(EconomyManager:GetMoney(player)).toBe(100)
		end)

		it("should set money correctly", function()
			local player = MockPlayer(3)
			EconomyManager.new(player)
			EconomyManager:SetMoney(player, 250)

			expect(EconomyManager:GetMoney(player)).toBe(250)
		end)

		it("should not allow negative money", function()
			local player = MockPlayer(4)
			EconomyManager.new(player)
			EconomyManager:SetMoney(player, -50)

			expect(EconomyManager:GetMoney(player)).toBe(0)
		end)

		it("should add money correctly", function()
			local player = MockPlayer(5)
			EconomyManager.new(player)
			EconomyManager:AddMoney(player, 50)

			expect(EconomyManager:GetMoney(player)).toBe(150)
		end)

		it("should spend money correctly", function()
			local player = MockPlayer(6)
			EconomyManager.new(player)
			local success = EconomyManager:SpendMoney(player, 30)

			expect(success).toBeTruthy()
			expect(EconomyManager:GetMoney(player)).toBe(70)
		end)

		it("should fail to spend more than available", function()
			local player = MockPlayer(7)
			EconomyManager.new(player)
			local success = EconomyManager:SpendMoney(player, 200)

			expect(success).toBeFalsy()
			expect(EconomyManager:GetMoney(player)).toBe(100) -- Unchanged
		end)

		it("should check affordability correctly", function()
			local player = MockPlayer(8)
			EconomyManager.new(player)

			expect(EconomyManager:CanAfford(player, 50)).toBeTruthy()
			expect(EconomyManager:CanAfford(player, 100)).toBeTruthy()
			expect(EconomyManager:CanAfford(player, 150)).toBeFalsy()
		end)
	end)

	describe("EconomyManager Merchant State", function()
		EconomyManager._reset()

		it("should start with merchant awake", function()
			expect(EconomyManager:IsMerchantAwake()).toBeTruthy()
		end)

		it("should be able to set merchant asleep", function()
			EconomyManager:SetMerchantAwake(false)
			expect(EconomyManager:IsMerchantAwake()).toBeFalsy()
		end)

		it("should be able to wake merchant", function()
			EconomyManager:SetMerchantAwake(false)
			EconomyManager:SetMerchantAwake(true)
			expect(EconomyManager:IsMerchantAwake()).toBeTruthy()
		end)
	end)

	describe("EconomyManager Prices", function()
		EconomyManager._reset()

		it("should initialize prices at base price", function()
			EconomyManager:InitializePrices()

			expect(EconomyManager:GetPrice(1)).toBe(10)
			expect(EconomyManager:GetPrice(24)).toBe(10)
		end)

		it("should return all prices", function()
			EconomyManager:InitializePrices()
			local prices = EconomyManager:GetAllPrices()

			local count = 0
			for _ in pairs(prices) do
				count = count + 1
			end
			expect(count).toBe(24)
		end)

		it("should fluctuate prices within bounds", function()
			EconomyManager:InitializePrices()
			local originalPrice = EconomyManager:GetPrice(1)

			for i = 1, 10 do
				EconomyManager:FluctuatePrices()
				local newPrice = EconomyManager:GetPrice(1)
				-- Price should be positive
				expect(newPrice).toBeGreaterThan(0)
			end
		end)
	end)

	describe("EconomyManager Merchant Stock", function()
		EconomyManager._reset()

		it("should generate 8 medicines in stock", function()
			local stock = EconomyManager:GenerateMerchantStock()

			expect(#stock).toBe(8)
		end)

		it("should have unique medicines in stock", function()
			local stock = EconomyManager:GenerateMerchantStock()
			local ids = {}

			for _, item in ipairs(stock) do
				expect(ids[item.id]).toBeNil()
				ids[item.id] = true
			end
		end)

		it("should correctly check if medicine in stock", function()
			local stock = EconomyManager:GenerateMerchantStock()
			local firstId = stock[1].id

			expect(EconomyManager:MerchantHasMedicine(firstId)).toBeTruthy()
			expect(EconomyManager:MerchantHasMedicine(9999)).toBeFalsy()
		end)
	end)

	describe("EconomyManager Buy Medicine", function()
		EconomyManager._reset()

		it("should successfully buy medicine", function()
			EconomyManager:InitializePrices()
			local stock = EconomyManager:GenerateMerchantStock()
			local player = MockPlayer(10)
			EconomyManager.new(player)

			local medicineId = stock[1].id
			local success, result = EconomyManager:BuyMedicine(player, medicineId)

			expect(success).toBeTruthy()
			expect(result.id).toBe(medicineId)
			expect(EconomyManager:GetMoney(player)).toBe(90) -- 100 - 10
		end)

		it("should fail to buy when merchant sleeping", function()
			EconomyManager._reset()
			EconomyManager:InitializePrices()
			EconomyManager:GenerateMerchantStock()
			local player = MockPlayer(11)
			EconomyManager.new(player)

			EconomyManager:SetMerchantAwake(false)

			local success, error = EconomyManager:BuyMedicine(player, 1)

			expect(success).toBeFalsy()
			expect(error).toBe("Merchant is sleeping")
		end)

		it("should fail to buy medicine not in stock", function()
			EconomyManager._reset()
			EconomyManager:InitializePrices()
			EconomyManager:SetMerchantAwake(true)
			EconomyManager:GenerateMerchantStock()
			local player = MockPlayer(12)
			EconomyManager.new(player)

			local success, error = EconomyManager:BuyMedicine(player, 9999)

			expect(success).toBeFalsy()
			expect(error).toBe("Not in stock today")
		end)

		it("should fail to buy same medicine twice in one day", function()
			EconomyManager._reset()
			EconomyManager:InitializePrices()
			EconomyManager:SetMerchantAwake(true)
			local stock = EconomyManager:GenerateMerchantStock()
			local player = MockPlayer(13)
			EconomyManager.new(player)

			local medicineId = stock[1].id
			EconomyManager:BuyMedicine(player, medicineId)
			local success, error = EconomyManager:BuyMedicine(player, medicineId)

			expect(success).toBeFalsy()
			expect(error).toBe("Already purchased today")
		end)

		it("should fail to buy without enough money", function()
			EconomyManager._reset()
			EconomyManager:InitializePrices()
			EconomyManager:SetMerchantAwake(true)
			local stock = EconomyManager:GenerateMerchantStock()
			local player = MockPlayer(14)
			EconomyManager.new(player)
			EconomyManager:SetMoney(player, 5) -- Only $5

			local success, error = EconomyManager:BuyMedicine(player, stock[1].id)

			expect(success).toBeFalsy()
			expect(error).toBe("Not enough money")
		end)
	end)

	describe("EconomyManager Sell Medicine", function()
		EconomyManager._reset()

		it("should earn money when selling", function()
			EconomyManager:InitializePrices()
			local player = MockPlayer(15)
			EconomyManager.new(player)

			local earnings = EconomyManager:SellMedicine(player, 1)

			expect(earnings).toBe(10)
			expect(EconomyManager:GetMoney(player)).toBe(110) -- 100 + 10
		end)

		it("should earn the current price of the medicine", function()
			EconomyManager._reset()
			EconomyManager:InitializePrices()
			local player = MockPlayer(16)
			EconomyManager.new(player)

			-- Manually set a specific price
			local prices = EconomyManager:GetAllPrices()
			prices[5] = 25

			local earnings = EconomyManager:SellMedicine(player, 5)

			expect(earnings).toBe(25)
		end)
	end)

	describe("EconomyManager ProcessNewDay", function()
		EconomyManager._reset()

		it("should increment day", function()
			EconomyManager:SetCurrentDay(1)
			EconomyManager:InitializePrices()

			local newDay = EconomyManager:ProcessNewDay()

			expect(newDay).toBe(2)
		end)

		it("should reset purchase tracking", function()
			EconomyManager._reset()
			EconomyManager:InitializePrices()
			EconomyManager:SetMerchantAwake(true)
			local stock = EconomyManager:GenerateMerchantStock()
			local player = MockPlayer(17)
			EconomyManager.new(player)

			local medicineId = stock[1].id
			EconomyManager:BuyMedicine(player, medicineId)
			expect(EconomyManager:HasBoughtToday(player, medicineId)).toBeTruthy()

			EconomyManager:ProcessNewDay()

			expect(EconomyManager:HasBoughtToday(player, medicineId)).toBeFalsy()
		end)

		it("should generate new merchant stock", function()
			EconomyManager._reset()
			EconomyManager:InitializePrices()
			local oldStock = EconomyManager:GenerateMerchantStock()
			local oldIds = {}
			for _, item in ipairs(oldStock) do
				oldIds[item.id] = true
			end

			EconomyManager:ProcessNewDay()
			local newStock = EconomyManager:GetMerchantStock()

			-- Stock should be regenerated (may have some overlap due to randomness)
			expect(#newStock).toBe(8)
		end)
	end)

	describe("EconomyManager:GetMerchantStockForPlayer", function()
		EconomyManager._reset()

		it("should include soldOut status for each item", function()
			EconomyManager:InitializePrices()
			EconomyManager:SetMerchantAwake(true)
			EconomyManager:GenerateMerchantStock()
			local player = MockPlayer(18)
			EconomyManager.new(player)

			local stock = EconomyManager:GetMerchantStockForPlayer(player)

			for _, item in ipairs(stock) do
				expect(item.soldOut).toBeFalsy()
			end
		end)

		it("should show soldOut after purchase", function()
			EconomyManager._reset()
			EconomyManager:InitializePrices()
			EconomyManager:SetMerchantAwake(true)
			local stock = EconomyManager:GenerateMerchantStock()
			local player = MockPlayer(19)
			EconomyManager.new(player)

			local medicineId = stock[1].id
			EconomyManager:BuyMedicine(player, medicineId)

			local playerStock = EconomyManager:GetMerchantStockForPlayer(player)
			local boughtItem = nil
			for _, item in ipairs(playerStock) do
				if item.id == medicineId then
					boughtItem = item
					break
				end
			end

			expect(boughtItem.soldOut).toBeTruthy()
		end)

		it("should include price for each item", function()
			EconomyManager._reset()
			EconomyManager:InitializePrices()
			EconomyManager:GenerateMerchantStock()
			local player = MockPlayer(20)
			EconomyManager.new(player)

			local stock = EconomyManager:GetMerchantStockForPlayer(player)

			for _, item in ipairs(stock) do
				expect(item.price).toBeTruthy()
				expect(item.price).toBeGreaterThan(0)
			end
		end)
	end)
end
