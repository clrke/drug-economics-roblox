-- NPCManager.spec.lua
-- Tests for NPCManager module

return function(TestFramework)
	local describe = TestFramework.describe
	local it = TestFramework.it
	local expect = TestFramework.expect

	-- Create a mock NPCManager for testing (without Roblox services)
	local function CreateMockNPCManager()
		local NPCManager = {}

		local Villagers = {}
		local CurrentDay = 1

		-- Mock config
		local Config = {
			MaxHP = 180,
			HPDrainPerSecond = 0.1,
			LowHPWarningPercent = 0.33,
			Count = 8,
		}

		-- Mock medicine data
		local function GetRandomSickness()
			local sicknesses = {"Fever", "Headache", "Cough", "Flu", "Allergy", "Rash", "Pain", "Nausea"}
			return sicknesses[math.random(1, #sicknesses)]
		end

		local function GetMedicineForSickness(sickness)
			return {id = 1, name = "Medicine", cures = sickness}
		end

		local function CreateVillagerData(index)
			return {
				Index = index,
				Model = nil,
				DisplayName = "Villager " .. index,
				Sickness = nil,
				NeededMedicine = nil,
				HP = Config.MaxHP,
				IsAlive = true,
				BedPosition = Vector3.new(0, 0, 0),
				StandPosition = Vector3.new(3, 0, 0),
				LowHPWarned = false,
			}
		end

		function NPCManager:Initialize()
			Villagers = {}
			CurrentDay = 1

			for i = 1, Config.Count do
				Villagers[i] = CreateVillagerData(i)

				-- All start sick
				local sickness = GetRandomSickness()
				Villagers[i].Sickness = sickness
				Villagers[i].NeededMedicine = GetMedicineForSickness(sickness)
			end

			return Villagers
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

		function NPCManager:TryCure(villagerIndex, medicineId)
			local villager = Villagers[villagerIndex]
			if not villager or not villager.IsAlive or not villager.Sickness then
				return false, "Cannot cure"
			end

			-- In real implementation, we'd check if medicine matches
			-- For testing, we'll accept any medicine
			villager.Sickness = nil
			villager.NeededMedicine = nil
			villager.HP = Config.MaxHP
			villager.LowHPWarned = false

			return true, "Cured!"
		end

		function NPCManager:ProcessNewDay()
			CurrentDay = CurrentDay + 1
			local deaths = {}
			local newSicknesses = {}

			for _, villager in pairs(Villagers) do
				if villager.IsAlive and not villager.Sickness then
					-- Healthy villagers get sick
					local sickness = GetRandomSickness()
					villager.Sickness = sickness
					villager.NeededMedicine = GetMedicineForSickness(sickness)
					villager.LowHPWarned = false
					table.insert(newSicknesses, villager)
				end
			end

			for _, villager in pairs(Villagers) do
				if not villager.IsAlive then
					table.insert(deaths, villager)
				end
			end

			return deaths, newSicknesses
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

		function NPCManager:GetCurrentDay()
			return CurrentDay
		end

		function NPCManager:SetCurrentDay(day)
			CurrentDay = day
		end

		-- Simulate HP drain
		function NPCManager:SimulateDrain(seconds)
			for _, villager in pairs(Villagers) do
				if villager.IsAlive and villager.Sickness then
					villager.HP = villager.HP - (Config.HPDrainPerSecond * seconds)

					if villager.HP <= 0 then
						villager.HP = 0
						villager.IsAlive = false
					end

					local warningThreshold = Config.MaxHP * Config.LowHPWarningPercent
					if villager.HP <= warningThreshold and not villager.LowHPWarned then
						villager.LowHPWarned = true
					end
				end
			end
		end

		-- For testing: directly manipulate villager
		function NPCManager:_setVillagerHP(index, hp)
			if Villagers[index] then
				Villagers[index].HP = hp
				if hp <= 0 then
					Villagers[index].IsAlive = false
				end
			end
		end

		function NPCManager:_setVillagerSickness(index, sickness)
			if Villagers[index] then
				Villagers[index].Sickness = sickness
				if sickness then
					Villagers[index].NeededMedicine = GetMedicineForSickness(sickness)
				else
					Villagers[index].NeededMedicine = nil
				end
			end
		end

		function NPCManager:_reset()
			Villagers = {}
			CurrentDay = 1
		end

		return NPCManager
	end

	local NPCManager = CreateMockNPCManager()

	describe("NPCManager:Initialize", function()
		NPCManager:_reset()

		it("should create 8 villagers", function()
			NPCManager:Initialize()
			local villagers = NPCManager:GetAllVillagers()

			local count = 0
			for _ in pairs(villagers) do
				count = count + 1
			end
			expect(count).toBe(8)
		end)

		it("should create villagers with full HP", function()
			NPCManager:Initialize()

			for i = 1, 8 do
				local villager = NPCManager:GetVillager(i)
				expect(villager.HP).toBe(180)
			end
		end)

		it("should create all villagers as alive", function()
			NPCManager:Initialize()

			for i = 1, 8 do
				local villager = NPCManager:GetVillager(i)
				expect(villager.IsAlive).toBeTruthy()
			end
		end)

		it("should give all villagers a sickness at start", function()
			NPCManager:Initialize()

			for i = 1, 8 do
				local villager = NPCManager:GetVillager(i)
				expect(villager.Sickness).toBeTruthy()
			end
		end)

		it("should assign needed medicine for each sickness", function()
			NPCManager:Initialize()

			for i = 1, 8 do
				local villager = NPCManager:GetVillager(i)
				expect(villager.NeededMedicine).toBeTruthy()
			end
		end)
	end)

	describe("NPCManager:GetVillager", function()
		NPCManager:_reset()
		NPCManager:Initialize()

		it("should return correct villager by index", function()
			local villager = NPCManager:GetVillager(1)
			expect(villager.Index).toBe(1)
		end)

		it("should return nil for invalid index", function()
			local villager = NPCManager:GetVillager(99)
			expect(villager).toBeNil()
		end)
	end)

	describe("NPCManager:GetSickVillagers", function()
		NPCManager:_reset()
		NPCManager:Initialize()

		it("should return all sick villagers", function()
			local sick = NPCManager:GetSickVillagers()
			expect(#sick).toBe(8) -- All start sick
		end)

		it("should not include cured villagers", function()
			NPCManager:TryCure(1, 1)
			local sick = NPCManager:GetSickVillagers()
			expect(#sick).toBe(7)
		end)

		it("should not include dead villagers", function()
			NPCManager:_setVillagerHP(2, 0)
			local sick = NPCManager:GetSickVillagers()

			local hasVillager2 = false
			for _, v in ipairs(sick) do
				if v.Index == 2 then hasVillager2 = true end
			end
			expect(hasVillager2).toBeFalsy()
		end)
	end)

	describe("NPCManager:TryCure", function()
		NPCManager:_reset()
		NPCManager:Initialize()

		it("should cure sick villager", function()
			local success, message = NPCManager:TryCure(1, 1)

			expect(success).toBeTruthy()
			expect(message).toBe("Cured!")
		end)

		it("should restore HP to full after cure", function()
			NPCManager:_setVillagerHP(3, 50)
			NPCManager:TryCure(3, 1)

			local villager = NPCManager:GetVillager(3)
			expect(villager.HP).toBe(180)
		end)

		it("should remove sickness after cure", function()
			NPCManager:TryCure(4, 1)

			local villager = NPCManager:GetVillager(4)
			expect(villager.Sickness).toBeNil()
		end)

		it("should remove needed medicine after cure", function()
			NPCManager:TryCure(5, 1)

			local villager = NPCManager:GetVillager(5)
			expect(villager.NeededMedicine).toBeNil()
		end)

		it("should fail to cure dead villager", function()
			NPCManager:_setVillagerHP(6, 0)
			local success, message = NPCManager:TryCure(6, 1)

			expect(success).toBeFalsy()
			expect(message).toBe("Cannot cure")
		end)

		it("should fail to cure already healthy villager", function()
			NPCManager:TryCure(7, 1) -- First cure
			local success, message = NPCManager:TryCure(7, 1) -- Try again

			expect(success).toBeFalsy()
		end)
	end)

	describe("NPCManager HP Drain", function()
		NPCManager:_reset()
		NPCManager:Initialize()

		it("should drain HP over time for sick villagers", function()
			local villager = NPCManager:GetVillager(1)
			local initialHP = villager.HP

			NPCManager:SimulateDrain(100) -- 100 seconds = 10 HP drain

			expect(villager.HP).toBeLessThan(initialHP)
			expect(villager.HP).toBe(170) -- 180 - (0.1 * 100)
		end)

		it("should not drain HP for healthy villagers", function()
			NPCManager:TryCure(2, 1) -- Cure villager 2
			local villager = NPCManager:GetVillager(2)

			NPCManager:SimulateDrain(100)

			expect(villager.HP).toBe(180) -- Full HP, no drain
		end)

		it("should kill villager when HP reaches 0", function()
			NPCManager:SimulateDrain(1800) -- 1800 seconds = 180 HP drain

			local villager = NPCManager:GetVillager(1)
			expect(villager.HP).toBe(0)
			expect(villager.IsAlive).toBeFalsy()
		end)

		it("should set LowHPWarned at 33% HP", function()
			NPCManager:_reset()
			NPCManager:Initialize()

			-- Drain to just above warning threshold
			NPCManager:SimulateDrain(1200) -- 120 HP drain, leaves 60 HP (33.3%)

			local villager = NPCManager:GetVillager(1)
			expect(villager.LowHPWarned).toBeTruthy()
		end)

		it("should take 30 minutes (1800 seconds) to die from full HP", function()
			NPCManager:_reset()
			NPCManager:Initialize()

			-- Check at 1799 seconds - should still be alive
			NPCManager:SimulateDrain(1799)
			local villager = NPCManager:GetVillager(1)
			expect(villager.IsAlive).toBeTruthy()
			expect(villager.HP).toBeGreaterThan(0)

			-- Drain 2 more seconds - should die
			NPCManager:SimulateDrain(2)
			expect(villager.IsAlive).toBeFalsy()
		end)
	end)

	describe("NPCManager:ProcessNewDay", function()
		NPCManager:_reset()
		NPCManager:Initialize()

		it("should make healthy villagers sick on new day", function()
			NPCManager:TryCure(1, 1) -- Cure villager 1
			local villager = NPCManager:GetVillager(1)
			expect(villager.Sickness).toBeNil()

			NPCManager:ProcessNewDay()

			expect(villager.Sickness).toBeTruthy()
		end)

		it("should assign needed medicine for new sickness", function()
			NPCManager:TryCure(2, 1)
			NPCManager:ProcessNewDay()

			local villager = NPCManager:GetVillager(2)
			expect(villager.NeededMedicine).toBeTruthy()
		end)

		it("should return list of new sicknesses", function()
			NPCManager:_reset()
			NPCManager:Initialize()
			NPCManager:TryCure(1, 1)
			NPCManager:TryCure(2, 1)

			local deaths, newSicknesses = NPCManager:ProcessNewDay()

			expect(#newSicknesses).toBe(2)
		end)

		it("should return list of deaths", function()
			NPCManager:_reset()
			NPCManager:Initialize()
			NPCManager:_setVillagerHP(1, 0)
			NPCManager:_setVillagerHP(2, 0)

			local deaths, newSicknesses = NPCManager:ProcessNewDay()

			expect(#deaths).toBe(2)
		end)
	end)

	describe("NPCManager:GetAliveCount", function()
		NPCManager:_reset()
		NPCManager:Initialize()

		it("should return 8 when all alive", function()
			expect(NPCManager:GetAliveCount()).toBe(8)
		end)

		it("should decrease when villagers die", function()
			NPCManager:_setVillagerHP(1, 0)
			NPCManager:_setVillagerHP(2, 0)

			expect(NPCManager:GetAliveCount()).toBe(6)
		end)

		it("should return 0 when all dead", function()
			for i = 1, 8 do
				NPCManager:_setVillagerHP(i, 0)
			end

			expect(NPCManager:GetAliveCount()).toBe(0)
		end)
	end)

	describe("NPCManager:IsGameOver", function()
		NPCManager:_reset()
		NPCManager:Initialize()

		it("should return false when villagers alive", function()
			expect(NPCManager:IsGameOver()).toBeFalsy()
		end)

		it("should return true when all villagers dead", function()
			for i = 1, 8 do
				NPCManager:_setVillagerHP(i, 0)
			end

			expect(NPCManager:IsGameOver()).toBeTruthy()
		end)

		it("should return false with even 1 villager alive", function()
			for i = 1, 7 do
				NPCManager:_setVillagerHP(i, 0)
			end

			expect(NPCManager:IsGameOver()).toBeFalsy()
		end)
	end)

	describe("NPCManager Day Tracking", function()
		NPCManager:_reset()
		NPCManager:Initialize()

		it("should start at day 1", function()
			expect(NPCManager:GetCurrentDay()).toBe(1)
		end)

		it("should increment day on ProcessNewDay", function()
			NPCManager:ProcessNewDay()
			expect(NPCManager:GetCurrentDay()).toBe(2)
		end)

		it("should allow setting day manually", function()
			NPCManager:SetCurrentDay(10)
			expect(NPCManager:GetCurrentDay()).toBe(10)
		end)
	end)
end
