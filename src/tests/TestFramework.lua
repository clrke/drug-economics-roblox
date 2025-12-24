-- TestFramework.lua
-- Lightweight test framework for when TestEZ is not available

local TestFramework = {}

local currentSuite = nil
local results = {
	passed = 0,
	failed = 0,
	errors = {},
}

function TestFramework.describe(name, fn)
	print("\n=== " .. name .. " ===")
	currentSuite = name
	local success, err = pcall(fn)
	if not success then
		results.failed = results.failed + 1
		table.insert(results.errors, {suite = name, error = err})
		warn("  ERROR in suite: " .. tostring(err))
	end
	currentSuite = nil
end

function TestFramework.it(name, fn)
	local success, err = pcall(fn)
	if success then
		results.passed = results.passed + 1
		print("  [PASS] " .. name)
	else
		results.failed = results.failed + 1
		table.insert(results.errors, {
			suite = currentSuite,
			test = name,
			error = tostring(err)
		})
		warn("  [FAIL] " .. name)
		warn("         " .. tostring(err))
	end
end

function TestFramework.expect(value)
	local expectation = {}

	function expectation.toBe(expected)
		if value ~= expected then
			error("Expected " .. tostring(expected) .. " but got " .. tostring(value))
		end
	end

	function expectation.toEqual(expected)
		if type(value) == "table" and type(expected) == "table" then
			for k, v in pairs(expected) do
				if value[k] ~= v then
					error("Expected table[" .. tostring(k) .. "] to be " .. tostring(v) .. " but got " .. tostring(value[k]))
				end
			end
			for k, v in pairs(value) do
				if expected[k] ~= v then
					error("Unexpected key " .. tostring(k) .. " in result")
				end
			end
		elseif value ~= expected then
			error("Expected " .. tostring(expected) .. " but got " .. tostring(value))
		end
	end

	function expectation.toBeGreaterThan(expected)
		if value <= expected then
			error("Expected " .. tostring(value) .. " to be greater than " .. tostring(expected))
		end
	end

	function expectation.toBeLessThan(expected)
		if value >= expected then
			error("Expected " .. tostring(value) .. " to be less than " .. tostring(expected))
		end
	end

	function expectation.toBeGreaterThanOrEqual(expected)
		if value < expected then
			error("Expected " .. tostring(value) .. " to be >= " .. tostring(expected))
		end
	end

	function expectation.toBeLessThanOrEqual(expected)
		if value > expected then
			error("Expected " .. tostring(value) .. " to be <= " .. tostring(expected))
		end
	end

	function expectation.toBeNil()
		if value ~= nil then
			error("Expected nil but got " .. tostring(value))
		end
	end

	function expectation.toBeTruthy()
		if not value then
			error("Expected truthy value but got " .. tostring(value))
		end
	end

	function expectation.toBeFalsy()
		if value then
			error("Expected falsy value but got " .. tostring(value))
		end
	end

	function expectation.toContain(expected)
		if type(value) == "table" then
			local found = false
			for _, v in ipairs(value) do
				if v == expected then
					found = true
					break
				end
			end
			if not found then
				error("Expected table to contain " .. tostring(expected))
			end
		elseif type(value) == "string" then
			if not string.find(value, expected, 1, true) then
				error("Expected string to contain " .. tostring(expected))
			end
		else
			error("toContain only works with tables and strings")
		end
	end

	function expectation.toHaveLength(expected)
		local len = #value
		if len ~= expected then
			error("Expected length " .. tostring(expected) .. " but got " .. tostring(len))
		end
	end

	function expectation.toBeType(expected)
		local actualType = typeof(value)
		if actualType ~= expected then
			error("Expected type " .. tostring(expected) .. " but got " .. actualType)
		end
	end

	function expectation.never()
		local negated = {}
		for k, v in pairs(expectation) do
			if type(v) == "function" and k ~= "never" then
				negated[k] = function(...)
					local success = pcall(v, ...)
					if success then
						error("Expected assertion to fail but it passed")
					end
				end
			end
		end
		return negated
	end

	return expectation
end

function TestFramework.getResults()
	return results
end

function TestFramework.printSummary()
	print("\n=== TEST SUMMARY ===")
	print("Passed: " .. results.passed)
	print("Failed: " .. results.failed)
	print("Total:  " .. (results.passed + results.failed))

	if #results.errors > 0 then
		print("\n=== FAILURES ===")
		for _, err in ipairs(results.errors) do
			print("Suite: " .. (err.suite or "unknown"))
			if err.test then
				print("Test:  " .. err.test)
			end
			print("Error: " .. err.error)
			print("")
		end
	end

	if results.failed > 0 then
		warn("TESTS FAILED!")
		return false
	else
		print("ALL TESTS PASSED!")
		return true
	end
end

function TestFramework.reset()
	results = {
		passed = 0,
		failed = 0,
		errors = {},
	}
end

return TestFramework
