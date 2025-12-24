-- GameConfig.lua
-- Contains all game configuration values

local GameConfig = {}

-- === TIME SETTINGS ===
GameConfig.Time = {
	DayDuration = 300,          -- 5 minutes (in seconds)
	NightDuration = 300,        -- 5 minutes (in seconds)
}

-- === VILLAGER SETTINGS ===
GameConfig.Villager = {
	Count = 8,                  -- 8 villagers total
	MaxHP = 180,                -- 180 HP (divisible by 60 mins)
	HPDrainPerSecond = 0.1,     -- 6 HP per minute = dies in 30 mins (3 days)
	LowHPWarningPercent = 0.33, -- Warning at 33% HP (~60 HP)
}

-- === MEDICINE SETTINGS ===
GameConfig.Medicine = {
	Count = 24,                 -- 24 medicines total
	MinExpiryDays = 5,          -- Minimum 5 days expiry
	MaxExpiryDays = 15,         -- Maximum 15 days expiry
}

-- === ECONOMY SETTINGS ===
GameConfig.Economy = {
	StartingMoney = 100,        -- Player starts with $100
	BasePrice = 10,             -- Starting price for all medicines
	MinFluctuation = 0.5,       -- Price can drop to 50%
	MaxFluctuation = 2.0,       -- Price can rise to 200%
	MerchantStockCount = 8,     -- Merchant sells 8 out of 24 medicines
}

-- === INTERACTION SETTINGS ===
GameConfig.Interaction = {
	VillagerDistance = 10,      -- Distance to interact with villager
	MerchantDistance = 15,      -- Distance to interact with merchant
	TentDistance = 15,          -- Distance to interact with tent
	InteractKey = Enum.KeyCode.E,
}

-- === RANDOM VILLAGER NAMES ===
GameConfig.VillagerNames = {
	"Tom", "Maria", "John", "Anna", "Pedro", "Elena",
	"Carlos", "Sofia", "Miguel", "Rosa", "Luis", "Carmen",
	"Diego", "Isabel", "Marco", "Lucia", "Pablo", "Teresa",
	"Andres", "Gloria", "Fernando", "Beatriz", "Ricardo", "Marta",
}

-- Calculate fluctuated price (no min/max cap - endless content)
function GameConfig:FluctuatePrice(currentPrice)
	local multiplier = self.Economy.MinFluctuation +
		math.random() * (self.Economy.MaxFluctuation - self.Economy.MinFluctuation)
	local newPrice = math.floor(currentPrice * multiplier)
	return math.max(1, newPrice) -- Minimum $1
end

-- Get random expiry days for a medicine
function GameConfig:GetRandomExpiryDays()
	return math.random(self.Medicine.MinExpiryDays, self.Medicine.MaxExpiryDays)
end

-- Get random villager name
function GameConfig:GetRandomVillagerName(usedNames)
	usedNames = usedNames or {}
	local available = {}
	for _, name in ipairs(self.VillagerNames) do
		if not usedNames[name] then
			table.insert(available, name)
		end
	end
	if #available > 0 then
		return available[math.random(1, #available)]
	end
	return "Villager" -- Fallback
end

function GameConfig:FormatMoney(amount)
	return "$" .. tostring(amount)
end

return GameConfig
