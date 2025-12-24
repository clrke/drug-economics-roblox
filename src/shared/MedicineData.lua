-- MedicineData.lua
-- ModuleScript: Contains all 24 medicines and their matching sicknesses (1:1)

local MedicineData = {}

-- Medicine Database: 24 generic medicines matched to 24 sicknesses
MedicineData.Medicines = {
	-- Common Ailments
	{id = 1, name = "Fever Reducer", cures = "Fever"},
	{id = 2, name = "Antispasmodic", cures = "Stomach Ache"},
	{id = 3, name = "Decongestant", cures = "Runny Nose"},
	{id = 4, name = "Expectorant", cures = "Wet Cough"},
	{id = 5, name = "Pain Reliever", cures = "Headache"},
	{id = 6, name = "Antacid", cures = "Hyperacidity"},
	{id = 7, name = "Anti-Diarrheal", cures = "Diarrhea"},
	{id = 8, name = "Flu Medicine", cures = "Flu"},

	-- Pain & Inflammation
	{id = 9, name = "Cramp Relief", cures = "Menstrual Cramps"},
	{id = 10, name = "Anti-Inflammatory", cures = "Body Pain"},
	{id = 11, name = "Dental Analgesic", cures = "Toothache"},
	{id = 12, name = "Muscle Relaxant", cures = "Back Pain"},

	-- Allergies & Skin
	{id = 13, name = "Antihistamine", cures = "Allergy"},
	{id = 14, name = "Rash Cream", cures = "Rashes"},
	{id = 15, name = "Hay Fever Pills", cures = "Hay Fever"},
	{id = 16, name = "Anti-Itch Cream", cures = "Itchy Skin"},

	-- Respiratory
	{id = 17, name = "Bronchodilator", cures = "Asthma"},
	{id = 18, name = "Mucolytic", cures = "Phlegm"},
	{id = 19, name = "Cough Suppressant", cures = "Dry Cough"},
	{id = 20, name = "Throat Lozenges", cures = "Sore Throat"},

	-- Others
	{id = 21, name = "Joint Supplement", cures = "Joint Pain"},
	{id = 22, name = "Electrolyte Salts", cures = "Loose Bowels"},
	{id = 23, name = "Throat Spray", cures = "Itchy Throat"},
	{id = 24, name = "Migraine Tablets", cures = "Migraine"},
}

-- Assign random basePrice ($4-$16) to each medicine
for _, medicine in ipairs(MedicineData.Medicines) do
	medicine.basePrice = math.random(4, 16)
end

-- Create lookup tables for easy access
MedicineData.ByID = {}
MedicineData.ByName = {}
MedicineData.BySickness = {}

for _, medicine in ipairs(MedicineData.Medicines) do
	MedicineData.ByID[medicine.id] = medicine
	MedicineData.ByName[medicine.name] = medicine
	MedicineData.BySickness[medicine.cures] = medicine
end

-- Get random sickness
function MedicineData:GetRandomSickness()
	local randomIndex = math.random(1, #self.Medicines)
	return self.Medicines[randomIndex].cures
end

-- Get medicine that cures a specific sickness
function MedicineData:GetMedicineForSickness(sickness)
	return self.BySickness[sickness]
end

-- Get random medicines for merchant (returns n random medicines)
function MedicineData:GetRandomMedicines(count)
	local shuffled = {}
	for i, v in ipairs(self.Medicines) do
		shuffled[i] = v
	end

	-- Fisher-Yates shuffle
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

-- Get all sicknesses
function MedicineData:GetAllSicknesses()
	local sicknesses = {}
	for _, medicine in ipairs(self.Medicines) do
		table.insert(sicknesses, medicine.cures)
	end
	return sicknesses
end

return MedicineData
