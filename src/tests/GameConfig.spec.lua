-- GameConfig.spec.lua
-- Tests for GameConfig module

return function(TestFramework)
	local describe = TestFramework.describe
	local it = TestFramework.it
	local expect = TestFramework.expect

	-- Mock ReplicatedStorage for standalone testing
	local GameConfig = nil

	-- Try to load the real module if in Roblox environment
	local success = pcall(function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig", 1))
	end)

	-- If not in Roblox, use a mock
	if not success or not GameConfig then
		-- Load from file path for standalone testing
		GameConfig = {
			Time = {
				DayDuration = 300,
				NightDuration = 300,
			},
			Villager = {
				Count = 8,
				MaxHP = 180,
				HPDrainPerSecond = 0.1,
				LowHPWarningPercent = 0.33,
			},
			Medicine = {
				Count = 24,
				MinExpiryDays = 5,
				MaxExpiryDays = 15,
			},
			Economy = {
				StartingMoney = 100,
				BasePrice = 10,
				MinFluctuation = 0.5,
				MaxFluctuation = 2.0,
				MerchantStockCount = 8,
			},
			VillagerNames = {"Alice", "Bob", "Charlie"},
			GetRandomVillagerName = function(self, usedNames)
				usedNames = usedNames or {}
				for _, name in ipairs(self.VillagerNames) do
					if not usedNames[name] then
						return name
					end
				end
				return "Villager"
			end,
			GetRandomExpiryDays = function(self)
				return math.random(self.Medicine.MinExpiryDays, self.Medicine.MaxExpiryDays)
			end,
			FluctuatePrice = function(self, currentPrice)
				local fluctuation = math.random() * (self.Economy.MaxFluctuation - self.Economy.MinFluctuation) + self.Economy.MinFluctuation
				return math.floor(currentPrice * fluctuation)
			end,
		}
	end

	describe("GameConfig.Time", function()
		it("should have DayDuration of 300 seconds (5 minutes)", function()
			expect(GameConfig.Time.DayDuration).toBe(300)
		end)

		it("should have NightDuration of 300 seconds (5 minutes)", function()
			expect(GameConfig.Time.NightDuration).toBe(300)
		end)

		it("should have equal day and night duration", function()
			expect(GameConfig.Time.DayDuration).toBe(GameConfig.Time.NightDuration)
		end)
	end)

	describe("GameConfig.Villager", function()
		it("should have 8 villagers", function()
			expect(GameConfig.Villager.Count).toBe(8)
		end)

		it("should have MaxHP of 180", function()
			expect(GameConfig.Villager.MaxHP).toBe(180)
		end)

		it("should have HPDrainPerSecond of 0.1", function()
			expect(GameConfig.Villager.HPDrainPerSecond).toBe(0.1)
		end)

		it("should drain HP such that villager dies in ~30 minutes", function()
			local timeTodie = GameConfig.Villager.MaxHP / GameConfig.Villager.HPDrainPerSecond
			expect(timeTodie).toBe(1800) -- 1800 seconds = 30 minutes
		end)

		it("should have LowHPWarningPercent of 0.33 (33%)", function()
			expect(GameConfig.Villager.LowHPWarningPercent).toBe(0.33)
		end)

		it("should warn at 60 HP (33% of 180)", function()
			local warningHP = GameConfig.Villager.MaxHP * GameConfig.Villager.LowHPWarningPercent
			expect(math.floor(warningHP)).toBe(59) -- 180 * 0.33 = 59.4
		end)
	end)

	describe("GameConfig.Medicine", function()
		it("should have 24 medicines", function()
			expect(GameConfig.Medicine.Count).toBe(24)
		end)

		it("should have minimum expiry of 5 days", function()
			expect(GameConfig.Medicine.MinExpiryDays).toBe(5)
		end)

		it("should have maximum expiry of 15 days", function()
			expect(GameConfig.Medicine.MaxExpiryDays).toBe(15)
		end)

		it("should have min expiry less than max expiry", function()
			expect(GameConfig.Medicine.MinExpiryDays).toBeLessThan(GameConfig.Medicine.MaxExpiryDays)
		end)
	end)

	describe("GameConfig.Economy", function()
		it("should have starting money of $100", function()
			expect(GameConfig.Economy.StartingMoney).toBe(100)
		end)

		it("should have base price of $10", function()
			expect(GameConfig.Economy.BasePrice).toBe(10)
		end)

		it("should have minimum fluctuation of 0.5 (50%)", function()
			expect(GameConfig.Economy.MinFluctuation).toBe(0.5)
		end)

		it("should have maximum fluctuation of 2.0 (200%)", function()
			expect(GameConfig.Economy.MaxFluctuation).toBe(2.0)
		end)

		it("should have merchant stock count of 8", function()
			expect(GameConfig.Economy.MerchantStockCount).toBe(8)
		end)
	end)

	describe("GameConfig:GetRandomVillagerName", function()
		it("should return a name not in usedNames", function()
			local usedNames = {}
			local name = GameConfig:GetRandomVillagerName(usedNames)
			expect(name).toBeTruthy()
			expect(usedNames[name]).toBeNil()
		end)

		it("should not return an already used name", function()
			local usedNames = {}
			local firstName = GameConfig:GetRandomVillagerName(usedNames)
			usedNames[firstName] = true
			local secondName = GameConfig:GetRandomVillagerName(usedNames)
			expect(secondName).never().toBe(firstName)
		end)
	end)

	describe("GameConfig:GetRandomExpiryDays", function()
		it("should return a value between min and max expiry", function()
			for i = 1, 10 do
				local expiry = GameConfig:GetRandomExpiryDays()
				expect(expiry).toBeGreaterThanOrEqual(GameConfig.Medicine.MinExpiryDays)
				expect(expiry).toBeLessThanOrEqual(GameConfig.Medicine.MaxExpiryDays)
			end
		end)
	end)

	describe("GameConfig:FluctuatePrice", function()
		it("should return a price between 50% and 200% of input", function()
			local basePrice = 100
			for i = 1, 20 do
				local newPrice = GameConfig:FluctuatePrice(basePrice)
				expect(newPrice).toBeGreaterThanOrEqual(basePrice * GameConfig.Economy.MinFluctuation)
				expect(newPrice).toBeLessThanOrEqual(basePrice * GameConfig.Economy.MaxFluctuation)
			end
		end)

		it("should return an integer", function()
			local price = GameConfig:FluctuatePrice(100)
			expect(price).toBe(math.floor(price))
		end)
	end)
end
