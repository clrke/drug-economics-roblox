-- RunTests.server.lua
-- Standalone test runner using built-in TestFramework
-- Place in ServerScriptService and run in Studio to execute all tests

local ServerScriptService = game:GetService("ServerScriptService")

print("\n")
print("╔════════════════════════════════════════════════════════════╗")
print("║          DRUGSTORE ECONOMY GAME - TEST SUITE               ║")
print("╚════════════════════════════════════════════════════════════╝")
print("\n")

-- Load the test framework
local Tests = ServerScriptService:FindFirstChild("Tests")
if not Tests then
	warn("Tests folder not found in ServerScriptService!")
	return
end

local TestFramework = require(Tests:WaitForChild("TestFramework"))

-- List of test specs to run
local testSpecs = {
	"GameConfig.spec",
	"MedicineData.spec",
	"InventoryManager.spec",
	"EconomyManager.spec",
	"NPCManager.spec",
	"BugFixTests",
}

-- Run each test spec
local totalPassed = 0
local totalFailed = 0

for _, specName in ipairs(testSpecs) do
	local specModule = Tests:FindFirstChild(specName)
	if specModule then
		print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print("Running: " .. specName)
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

		TestFramework.reset()

		local success, err = pcall(function()
			local testFn = require(specModule)
			testFn(TestFramework)
		end)

		if not success then
			warn("Error loading " .. specName .. ": " .. tostring(err))
			totalFailed = totalFailed + 1
		else
			local results = TestFramework.getResults()
			totalPassed = totalPassed + results.passed
			totalFailed = totalFailed + results.failed
		end
	else
		warn("Test spec not found: " .. specName)
	end
end

-- Print final summary
print("\n")
print("╔════════════════════════════════════════════════════════════╗")
print("║                    FINAL SUMMARY                           ║")
print("╠════════════════════════════════════════════════════════════╣")
print(string.format("║  Passed: %-48d ║", totalPassed))
print(string.format("║  Failed: %-48d ║", totalFailed))
print(string.format("║  Total:  %-48d ║", totalPassed + totalFailed))
print("╠════════════════════════════════════════════════════════════╣")

if totalFailed > 0 then
	print("║                    ❌ TESTS FAILED                        ║")
	warn("Tests failed! See above for details.")
else
	print("║                    ✅ ALL TESTS PASSED                    ║")
end

print("╚════════════════════════════════════════════════════════════╝")
