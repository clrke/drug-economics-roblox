-- TestRunner.server.lua
-- Run all tests using TestEZ framework
-- To run: Place this in ServerScriptService and run in Studio

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for TestEZ (install via Wally or include manually)
local TestEZ = require(ReplicatedStorage:WaitForChild("TestEZ"))

-- Collect all test modules
local testModules = {}

local function findTests(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
			table.insert(testModules, child)
		end
		findTests(child)
	end
end

-- Find tests in the Tests folder
local testsFolder = ServerScriptService:FindFirstChild("Tests")
if testsFolder then
	findTests(testsFolder)
end

-- Also check ReplicatedStorage for shared tests
local sharedTests = ReplicatedStorage:FindFirstChild("Tests")
if sharedTests then
	findTests(sharedTests)
end

print("=== Running " .. #testModules .. " test modules ===")

-- Run tests
local results = TestEZ.TestBootstrap:run(testModules, TestEZ.Reporters.TextReporter)

-- Print summary
if results.failureCount > 0 then
	warn("TESTS FAILED: " .. results.failureCount .. " failures")
else
	print("ALL TESTS PASSED!")
end
