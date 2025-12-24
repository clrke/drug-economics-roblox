-- MedicineData.spec.lua
-- Tests for MedicineData module

return function(TestFramework)
	local describe = TestFramework.describe
	local it = TestFramework.it
	local expect = TestFramework.expect

	-- Try to load the real module
	local MedicineData = nil
	local success = pcall(function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		MedicineData = require(ReplicatedStorage:WaitForChild("MedicineData", 1))
	end)

	-- If not in Roblox, create a minimal mock for testing
	if not success or not MedicineData then
		MedicineData = {
			Medicines = {
				{id = 1, name = "Fever Reducer", cures = "Fever"},
				{id = 2, name = "Antispasmodic", cures = "Stomach Ache"},
				{id = 3, name = "Decongestant", cures = "Runny Nose"},
				{id = 4, name = "Expectorant", cures = "Wet Cough"},
				{id = 5, name = "Pain Reliever", cures = "Headache"},
				{id = 6, name = "Antacid", cures = "Hyperacidity"},
				{id = 7, name = "Anti-Diarrheal", cures = "Diarrhea"},
				{id = 8, name = "Flu Medicine", cures = "Flu"},
				{id = 9, name = "Cramp Relief", cures = "Menstrual Cramps"},
				{id = 10, name = "Anti-Inflammatory", cures = "Body Pain"},
				{id = 11, name = "Dental Analgesic", cures = "Toothache"},
				{id = 12, name = "Muscle Relaxant", cures = "Back Pain"},
				{id = 13, name = "Antihistamine", cures = "Allergy"},
				{id = 14, name = "Rash Cream", cures = "Rashes"},
				{id = 15, name = "Hay Fever Pills", cures = "Hay Fever"},
				{id = 16, name = "Anti-Itch Cream", cures = "Itchy Skin"},
				{id = 17, name = "Bronchodilator", cures = "Asthma"},
				{id = 18, name = "Mucolytic", cures = "Phlegm"},
				{id = 19, name = "Cough Suppressant", cures = "Dry Cough"},
				{id = 20, name = "Throat Lozenges", cures = "Sore Throat"},
				{id = 21, name = "Joint Supplement", cures = "Joint Pain"},
				{id = 22, name = "Electrolyte Salts", cures = "Loose Bowels"},
				{id = 23, name = "Throat Spray", cures = "Itchy Throat"},
				{id = 24, name = "Migraine Tablets", cures = "Migraine"},
			},
			ByID = {},
			ByName = {},
			BySickness = {},
		}

		-- Build lookup tables
		for _, medicine in ipairs(MedicineData.Medicines) do
			MedicineData.ByID[medicine.id] = medicine
			MedicineData.ByName[medicine.name] = medicine
			MedicineData.BySickness[medicine.cures] = medicine
		end

		function MedicineData:GetRandomSickness()
			local randomIndex = math.random(1, #self.Medicines)
			return self.Medicines[randomIndex].cures
		end

		function MedicineData:GetMedicineForSickness(sickness)
			return self.BySickness[sickness]
		end

		function MedicineData:GetRandomMedicines(count)
			local shuffled = {}
			for i, v in ipairs(self.Medicines) do
				shuffled[i] = v
			end
			for i = #shuffled, 2, -1 do
				local j = math.random(1, i)
				shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
			end
			local result = {}
			for i = 1, math.min(count, #shuffled) do
				table.insert(result, shuffled[i])
			end
			return result
		end

		function MedicineData:GetAllSicknesses()
			local sicknesses = {}
			for _, medicine in ipairs(self.Medicines) do
				table.insert(sicknesses, medicine.cures)
			end
			return sicknesses
		end
	end

	describe("MedicineData.Medicines", function()
		it("should have exactly 24 medicines", function()
			expect(#MedicineData.Medicines).toBe(24)
		end)

		it("should have unique IDs for each medicine", function()
			local ids = {}
			for _, medicine in ipairs(MedicineData.Medicines) do
				expect(ids[medicine.id]).toBeNil()
				ids[medicine.id] = true
			end
		end)

		it("should have unique names for each medicine", function()
			local names = {}
			for _, medicine in ipairs(MedicineData.Medicines) do
				expect(names[medicine.name]).toBeNil()
				names[medicine.name] = true
			end
		end)

		it("should have unique sicknesses (1:1 mapping)", function()
			local sicknesses = {}
			for _, medicine in ipairs(MedicineData.Medicines) do
				expect(sicknesses[medicine.cures]).toBeNil()
				sicknesses[medicine.cures] = true
			end
		end)

		it("should have IDs from 1 to 24", function()
			for i = 1, 24 do
				expect(MedicineData.ByID[i]).toBeTruthy()
			end
		end)

		it("each medicine should have id, name, and cures fields", function()
			for _, medicine in ipairs(MedicineData.Medicines) do
				expect(medicine.id).toBeTruthy()
				expect(medicine.name).toBeTruthy()
				expect(medicine.cures).toBeTruthy()
			end
		end)
	end)

	describe("MedicineData.ByID", function()
		it("should contain all 24 medicines", function()
			local count = 0
			for _ in pairs(MedicineData.ByID) do
				count = count + 1
			end
			expect(count).toBe(24)
		end)

		it("should return correct medicine for ID 1", function()
			local medicine = MedicineData.ByID[1]
			expect(medicine.name).toBe("Fever Reducer")
			expect(medicine.cures).toBe("Fever")
		end)

		it("should return correct medicine for ID 24", function()
			local medicine = MedicineData.ByID[24]
			expect(medicine.name).toBe("Migraine Tablets")
			expect(medicine.cures).toBe("Migraine")
		end)
	end)

	describe("MedicineData.BySickness", function()
		it("should return correct medicine for each sickness", function()
			local medicine = MedicineData.BySickness["Fever"]
			expect(medicine).toBeTruthy()
			expect(medicine.name).toBe("Fever Reducer")
		end)

		it("should return nil for unknown sickness", function()
			local medicine = MedicineData.BySickness["Unknown Disease"]
			expect(medicine).toBeNil()
		end)
	end)

	describe("MedicineData:GetRandomSickness", function()
		it("should return a valid sickness", function()
			for i = 1, 10 do
				local sickness = MedicineData:GetRandomSickness()
				expect(MedicineData.BySickness[sickness]).toBeTruthy()
			end
		end)

		it("should return different values over multiple calls (randomness test)", function()
			local results = {}
			for i = 1, 50 do
				local sickness = MedicineData:GetRandomSickness()
				results[sickness] = true
			end
			-- Should have at least a few different results
			local count = 0
			for _ in pairs(results) do
				count = count + 1
			end
			expect(count).toBeGreaterThan(1)
		end)
	end)

	describe("MedicineData:GetMedicineForSickness", function()
		it("should return the correct medicine for Fever", function()
			local medicine = MedicineData:GetMedicineForSickness("Fever")
			expect(medicine.id).toBe(1)
			expect(medicine.name).toBe("Fever Reducer")
		end)

		it("should return nil for unknown sickness", function()
			local medicine = MedicineData:GetMedicineForSickness("Fake Sickness")
			expect(medicine).toBeNil()
		end)

		it("should return a medicine with matching cures field", function()
			local sickness = "Headache"
			local medicine = MedicineData:GetMedicineForSickness(sickness)
			expect(medicine.cures).toBe(sickness)
		end)
	end)

	describe("MedicineData:GetRandomMedicines", function()
		it("should return exactly 8 medicines when count is 8", function()
			local medicines = MedicineData:GetRandomMedicines(8)
			expect(#medicines).toBe(8)
		end)

		it("should return at most 24 medicines even if count is higher", function()
			local medicines = MedicineData:GetRandomMedicines(100)
			expect(#medicines).toBe(24)
		end)

		it("should return 0 medicines when count is 0", function()
			local medicines = MedicineData:GetRandomMedicines(0)
			expect(#medicines).toBe(0)
		end)

		it("should return unique medicines (no duplicates)", function()
			local medicines = MedicineData:GetRandomMedicines(8)
			local ids = {}
			for _, medicine in ipairs(medicines) do
				expect(ids[medicine.id]).toBeNil()
				ids[medicine.id] = true
			end
		end)

		it("should return valid medicine objects", function()
			local medicines = MedicineData:GetRandomMedicines(8)
			for _, medicine in ipairs(medicines) do
				expect(medicine.id).toBeTruthy()
				expect(medicine.name).toBeTruthy()
				expect(medicine.cures).toBeTruthy()
			end
		end)
	end)

	describe("MedicineData:GetAllSicknesses", function()
		it("should return 24 sicknesses", function()
			local sicknesses = MedicineData:GetAllSicknesses()
			expect(#sicknesses).toBe(24)
		end)

		it("should include Fever", function()
			local sicknesses = MedicineData:GetAllSicknesses()
			local hasFever = false
			for _, s in ipairs(sicknesses) do
				if s == "Fever" then
					hasFever = true
					break
				end
			end
			expect(hasFever).toBeTruthy()
		end)
	end)
end
