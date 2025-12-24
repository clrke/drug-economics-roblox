-- GameClient.client.lua
-- Handles all client-side UI and Press E interactions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Wait for modules
local MedicineData = require(ReplicatedStorage:WaitForChild("MedicineData"))

-- Wait for remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 30)
if not RemoteEvents then
	warn("RemoteEvents not found!")
	return
end

-- Remote Events
local BuyMedicine = RemoteEvents:WaitForChild("BuyMedicine")
local CureVillager = RemoteEvents:WaitForChild("CureVillager")
local SkipDay = RemoteEvents:WaitForChild("SkipDay")
local UpdatePlayer = RemoteEvents:WaitForChild("UpdatePlayer")
local UpdateVillagers = RemoteEvents:WaitForChild("UpdateVillagers")
local UpdateMerchant = RemoteEvents:WaitForChild("UpdateMerchant")
local UpdatePrices = RemoteEvents:WaitForChild("UpdatePrices")
local UpdateTime = RemoteEvents:WaitForChild("UpdateTime")
local NewDay = RemoteEvents:WaitForChild("NewDay")
local GameOver = RemoteEvents:WaitForChild("GameOver")
local Notification = RemoteEvents:WaitForChild("Notification")

-- Remote Functions
local GetPlayerData = RemoteEvents:WaitForChild("GetPlayerData")
local GetVillagerData = RemoteEvents:WaitForChild("GetVillagerData")
local GetMerchantStock = RemoteEvents:WaitForChild("GetMerchantStock")
local GetPrices = RemoteEvents:WaitForChild("GetPrices")
local GetInventoryDisplay = RemoteEvents:WaitForChild("GetInventoryDisplay")

-- === CLIENT STATE ===
local PlayerMoney = 100
local PlayerInventory = { valid = {}, expired = {} }
local CurrentDay = 1
local IsDay = true
local TimeRemaining = 300
local MerchantAwake = true
local VillagerData = {}
local MerchantStock = {}
local MedicinePrices = {}
local IsGameOver = false

-- Interaction state
local CurrentInteractTarget = nil -- {type = "villager"|"merchant"|"tent", index = number (for villager)}
local InteractPanelOpen = false

-- Proximity distances
local VILLAGER_INTERACT_DISTANCE = 12
local MERCHANT_INTERACT_DISTANCE = 15
local TENT_INTERACT_DISTANCE = 15

-- === UI SETUP ===
local GameUI = PlayerGui:FindFirstChild("GameUI")
if GameUI then GameUI:Destroy() end

GameUI = Instance.new("ScreenGui")
GameUI.Name = "GameUI"
GameUI.ResetOnSpawn = false
GameUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GameUI.Parent = PlayerGui

-- === UI HELPER FUNCTIONS ===
local function CreateFrame(props)
	local frame = Instance.new("Frame")
	frame.Name = props.Name or "Frame"
	frame.Size = props.Size or UDim2.new(0, 200, 0, 100)
	frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
	frame.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	frame.BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(30, 30, 40)
	frame.BackgroundTransparency = props.BackgroundTransparency or 0.1
	frame.BorderSizePixel = 0
	frame.Visible = props.Visible ~= false
	frame.Parent = props.Parent or GameUI

	if props.Corner then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, props.Corner)
		corner.Parent = frame
	end

	return frame
end

local function CreateLabel(props)
	local label = Instance.new("TextLabel")
	label.Name = props.Name or "Label"
	label.Size = props.Size or UDim2.new(1, 0, 0, 30)
	label.Position = props.Position or UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = props.BackgroundTransparency or 1
	label.BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(0, 0, 0)
	label.Text = props.Text or ""
	label.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	label.TextSize = props.TextSize or 18
	label.Font = props.Font or Enum.Font.GothamBold
	label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center
	label.TextWrapped = props.TextWrapped or false
	label.Parent = props.Parent
	return label
end

local function CreateButton(props)
	local button = Instance.new("TextButton")
	button.Name = props.Name or "Button"
	button.Size = props.Size or UDim2.new(0, 150, 0, 40)
	button.Position = props.Position or UDim2.new(0, 0, 0, 0)
	button.BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(0, 120, 80)
	button.Text = props.Text or "Button"
	button.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	button.TextSize = props.TextSize or 16
	button.Font = props.Font or Enum.Font.GothamBold
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Parent = props.Parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local function CreateScrollFrame(props)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = props.Name or "ScrollFrame"
	scroll.Size = props.Size or UDim2.new(1, 0, 1, 0)
	scroll.Position = props.Position or UDim2.new(0, 0, 0, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = props.Parent
	return scroll
end

-- === TOP BAR (Money, Day, Time) ===
local TopBar = CreateFrame({
	Name = "TopBar",
	Size = UDim2.new(0, 400, 0, 60),
	Position = UDim2.new(0.5, 0, 0, 10),
	AnchorPoint = Vector2.new(0.5, 0),
	Corner = 10,
})

local MoneyLabel = CreateLabel({
	Name = "MoneyLabel",
	Size = UDim2.new(0.33, 0, 0.5, 0),
	Position = UDim2.new(0, 10, 0, 5),
	Text = "$" .. PlayerMoney,
	TextColor3 = Color3.fromRGB(100, 255, 100),
	TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = TopBar,
})

local DayLabel = CreateLabel({
	Name = "DayLabel",
	Size = UDim2.new(0.33, 0, 0.5, 0),
	Position = UDim2.new(0.33, 0, 0, 5),
	Text = "Day " .. CurrentDay,
	TextColor3 = Color3.fromRGB(255, 220, 100),
	TextSize = 22,
	Parent = TopBar,
})

local TimeLabel = CreateLabel({
	Name = "TimeLabel",
	Size = UDim2.new(0.33, -10, 0.5, 0),
	Position = UDim2.new(0.67, 0, 0, 5),
	Text = "DAY",
	TextColor3 = Color3.fromRGB(255, 255, 150),
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = TopBar,
})

local TimeRemainingLabel = CreateLabel({
	Name = "TimeRemainingLabel",
	Size = UDim2.new(1, -20, 0.4, 0),
	Position = UDim2.new(0, 10, 0.55, 0),
	Text = "5:00 remaining",
	TextColor3 = Color3.fromRGB(180, 180, 180),
	TextSize = 14,
	Parent = TopBar,
})

-- === INTERACTION PROMPT ===
local InteractPrompt = CreateFrame({
	Name = "InteractPrompt",
	Size = UDim2.new(0, 250, 0, 45),
	Position = UDim2.new(0.5, 0, 0.75, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Corner = 10,
	Visible = false,
})

local InteractLabel = CreateLabel({
	Name = "Label",
	Size = UDim2.new(1, 0, 1, 0),
	Text = "[E] Interact",
	TextSize = 20,
	Parent = InteractPrompt,
})

-- === INVENTORY DISPLAY ===
local InventoryFrame = CreateFrame({
	Name = "InventoryFrame",
	Size = UDim2.new(0, 280, 0, 300),
	Position = UDim2.new(1, -290, 0, 10),
	Corner = 10,
})

local InventoryTitle = CreateLabel({
	Name = "Title",
	Size = UDim2.new(1, 0, 0, 30),
	Text = "INVENTORY",
	TextSize = 16,
	Parent = InventoryFrame,
})

local InventoryScroll = CreateScrollFrame({
	Name = "Scroll",
	Size = UDim2.new(1, -10, 1, -40),
	Position = UDim2.new(0, 5, 0, 35),
	Parent = InventoryFrame,
})

local InventoryListLayout = Instance.new("UIListLayout")
InventoryListLayout.Padding = UDim.new(0, 3)
InventoryListLayout.Parent = InventoryScroll

-- === VILLAGER INTERACTION PANEL ===
local VillagerPanel = CreateFrame({
	Name = "VillagerPanel",
	Size = UDim2.new(0, 380, 0, 220),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Corner = 12,
	Visible = false,
})

local VillagerTitle = CreateLabel({
	Name = "Title",
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = Color3.fromRGB(20, 20, 30),
	BackgroundTransparency = 0,
	Text = "Villager",
	TextSize = 22,
	Parent = VillagerPanel,
})
Instance.new("UICorner", VillagerTitle).CornerRadius = UDim.new(0, 12)

local VillagerStatus = CreateLabel({
	Name = "Status",
	Size = UDim2.new(1, -20, 0, 25),
	Position = UDim2.new(0, 10, 0, 50),
	Text = "Status: Healthy",
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = VillagerPanel,
})

local VillagerSickness = CreateLabel({
	Name = "Sickness",
	Size = UDim2.new(1, -20, 0, 25),
	Position = UDim2.new(0, 10, 0, 75),
	Text = "",
	TextColor3 = Color3.fromRGB(255, 100, 100),
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = VillagerPanel,
})

local VillagerNeeds = CreateLabel({
	Name = "Needs",
	Size = UDim2.new(1, -20, 0, 25),
	Position = UDim2.new(0, 10, 0, 100),
	Text = "",
	TextColor3 = Color3.fromRGB(100, 200, 255),
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = VillagerPanel,
})

-- HP Bar
local VillagerHPBg = CreateFrame({
	Name = "HPBg",
	Size = UDim2.new(0.9, 0, 0, 20),
	Position = UDim2.new(0.05, 0, 0, 130),
	BackgroundColor3 = Color3.fromRGB(60, 20, 20),
	Corner = 5,
	Parent = VillagerPanel,
})

local VillagerHPFill = CreateFrame({
	Name = "HPFill",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(0, 200, 0),
	Corner = 5,
	Parent = VillagerHPBg,
})

local VillagerHPText = CreateLabel({
	Name = "HPText",
	Size = UDim2.new(1, 0, 1, 0),
	Text = "180 / 180 HP",
	TextSize = 12,
	Parent = VillagerHPBg,
})

local VillagerCureBtn = CreateButton({
	Name = "CureButton",
	Size = UDim2.new(0, 140, 0, 45),
	Position = UDim2.new(0.25, 0, 1, -55),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.fromRGB(0, 150, 50),
	Text = "CURE",
	TextSize = 16,
	Parent = VillagerPanel,
})

local VillagerCloseBtn = CreateButton({
	Name = "CloseButton",
	Size = UDim2.new(0, 100, 0, 45),
	Position = UDim2.new(0.75, 0, 1, -55),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.fromRGB(120, 50, 50),
	Text = "CLOSE",
	TextSize = 16,
	Parent = VillagerPanel,
})

-- === MERCHANT PANEL ===
local MerchantPanel = CreateFrame({
	Name = "MerchantPanel",
	Size = UDim2.new(0, 450, 0, 400),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Corner = 12,
	Visible = false,
})

local MerchantTitle = CreateLabel({
	Name = "Title",
	Size = UDim2.new(1, 0, 0, 45),
	BackgroundColor3 = Color3.fromRGB(80, 60, 20),
	BackgroundTransparency = 0,
	Text = "MERCHANT",
	TextSize = 24,
	Parent = MerchantPanel,
})
Instance.new("UICorner", MerchantTitle).CornerRadius = UDim.new(0, 12)

local MerchantSleepLabel = CreateLabel({
	Name = "SleepLabel",
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0, 0, 0, 45),
	Text = "The merchant is sleeping...",
	TextColor3 = Color3.fromRGB(150, 150, 200),
	TextSize = 16,
	Visible = false,
	Parent = MerchantPanel,
})

local MerchantScroll = CreateScrollFrame({
	Name = "Scroll",
	Size = UDim2.new(1, -20, 1, -110),
	Position = UDim2.new(0, 10, 0, 55),
	Parent = MerchantPanel,
})

local MerchantListLayout = Instance.new("UIListLayout")
MerchantListLayout.Padding = UDim.new(0, 5)
MerchantListLayout.Parent = MerchantScroll

local MerchantCloseBtn = CreateButton({
	Name = "CloseButton",
	Size = UDim2.new(0, 120, 0, 40),
	Position = UDim2.new(0.5, 0, 1, -50),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.fromRGB(150, 50, 50),
	Text = "CLOSE",
	Parent = MerchantPanel,
})

-- === TENT PANEL ===
local TentPanel = CreateFrame({
	Name = "TentPanel",
	Size = UDim2.new(0, 320, 0, 180),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Corner = 12,
	Visible = false,
})

local TentTitle = CreateLabel({
	Name = "Title",
	Size = UDim2.new(1, 0, 0, 45),
	BackgroundColor3 = Color3.fromRGB(60, 40, 80),
	BackgroundTransparency = 0,
	Text = "REST AT TENT",
	TextSize = 22,
	Parent = TentPanel,
})
Instance.new("UICorner", TentTitle).CornerRadius = UDim.new(0, 12)

local TentInfo = CreateLabel({
	Name = "Info",
	Size = UDim2.new(1, -20, 0, 50),
	Position = UDim2.new(0, 10, 0, 55),
	Text = "Skip to next day?\nPrices will change!",
	TextSize = 16,
	TextWrapped = true,
	Parent = TentPanel,
})

local TentSkipBtn = CreateButton({
	Name = "SkipButton",
	Size = UDim2.new(0, 140, 0, 45),
	Position = UDim2.new(0.25, 0, 1, -55),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.fromRGB(100, 80, 150),
	Text = "SKIP DAY",
	Parent = TentPanel,
})

local TentCloseBtn = CreateButton({
	Name = "CloseButton",
	Size = UDim2.new(0, 100, 0, 45),
	Position = UDim2.new(0.75, 0, 1, -55),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.fromRGB(120, 50, 50),
	Text = "CLOSE",
	Parent = TentPanel,
})

-- === GAME OVER PANEL ===
local GameOverPanel = CreateFrame({
	Name = "GameOverPanel",
	Size = UDim2.new(0, 450, 0, 280),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Corner = 15,
	Visible = false,
})

local GameOverTitle = CreateLabel({
	Name = "Title",
	Size = UDim2.new(1, 0, 0, 70),
	BackgroundColor3 = Color3.fromRGB(150, 30, 30),
	BackgroundTransparency = 0,
	Text = "GAME OVER",
	TextSize = 36,
	Parent = GameOverPanel,
})
Instance.new("UICorner", GameOverTitle).CornerRadius = UDim.new(0, 15)

local GameOverMessage = CreateLabel({
	Name = "Message",
	Size = UDim2.new(1, -20, 0, 40),
	Position = UDim2.new(0, 10, 0, 85),
	Text = "All villagers have died!",
	TextSize = 20,
	TextColor3 = Color3.fromRGB(255, 150, 150),
	Parent = GameOverPanel,
})

local GameOverStats = CreateLabel({
	Name = "Stats",
	Size = UDim2.new(1, -20, 0, 80),
	Position = UDim2.new(0, 10, 0, 130),
	Text = "You survived 0 days",
	TextSize = 28,
	TextColor3 = Color3.fromRGB(255, 220, 100),
	Parent = GameOverPanel,
})

-- === NOTIFICATION SYSTEM ===
local NotificationFrame = CreateFrame({
	Name = "NotificationFrame",
	Size = UDim2.new(0, 400, 0, 55),
	Position = UDim2.new(0.5, 0, 0, 80),
	AnchorPoint = Vector2.new(0.5, 0),
	Corner = 10,
	Visible = false,
})

local NotificationLabel = CreateLabel({
	Name = "Text",
	Size = UDim2.new(1, -20, 1, 0),
	Position = UDim2.new(0, 10, 0, 0),
	Text = "",
	TextSize = 16,
	TextWrapped = true,
	Parent = NotificationFrame,
})

-- === UPDATE FUNCTIONS ===
local function FormatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", mins, secs)
end

local function UpdateTopBar()
	MoneyLabel.Text = "$" .. PlayerMoney
	DayLabel.Text = "Day " .. CurrentDay

	if IsDay then
		TimeLabel.Text = "DAY"
		TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
	else
		TimeLabel.Text = "NIGHT"
		TimeLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
	end

	TimeRemainingLabel.Text = FormatTime(TimeRemaining) .. " remaining"
end

local function UpdateInventoryUI()
	-- Clear existing items
	for _, child in ipairs(InventoryScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local hasValidItems = #PlayerInventory.valid > 0
	local hasExpiredItems = #PlayerInventory.expired > 0

	-- Show valid medicines
	if hasValidItems then
		for _, item in ipairs(PlayerInventory.valid) do
			local medicine = MedicineData.ByID[item.medicineId]
			if medicine then
				local itemFrame = CreateFrame({
					Name = "Item_" .. item.medicineId,
					Size = UDim2.new(1, -5, 0, 40),
					BackgroundColor3 = Color3.fromRGB(40, 60, 40),
					Corner = 6,
					Parent = InventoryScroll,
				})

				CreateLabel({
					Name = "Name",
					Size = UDim2.new(1, -10, 0, 20),
					Position = UDim2.new(0, 5, 0, 2),
					Text = medicine.name,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = itemFrame,
				})

				local expiryColor = Color3.fromRGB(150, 255, 150)
				local expiryText = "Expires: Day " .. item.expiryDay

				-- Warning colors based on days until expiry
				if item.daysUntilExpiry == 0 then
					expiryColor = Color3.fromRGB(255, 100, 100)
					expiryText = "EXPIRES TODAY!"
				elseif item.daysUntilExpiry == 1 then
					expiryColor = Color3.fromRGB(255, 200, 100)
					expiryText = "Expires tomorrow"
				elseif item.daysUntilExpiry <= 3 then
					expiryColor = Color3.fromRGB(255, 255, 100)
				end

				CreateLabel({
					Name = "Expiry",
					Size = UDim2.new(1, -10, 0, 16),
					Position = UDim2.new(0, 5, 0, 22),
					Text = expiryText,
					TextSize = 11,
					TextColor3 = expiryColor,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = itemFrame,
				})
			end
		end
	end

	-- Separator if we have both valid and expired
	if hasValidItems and hasExpiredItems then
		local separator = CreateLabel({
			Name = "Separator",
			Size = UDim2.new(1, -10, 0, 20),
			Text = "--- EXPIRED ---",
			TextSize = 11,
			TextColor3 = Color3.fromRGB(150, 100, 100),
			Parent = InventoryScroll,
		})
	end

	-- Show expired medicines (at bottom)
	if hasExpiredItems then
		for _, item in ipairs(PlayerInventory.expired) do
			local medicine = MedicineData.ByID[item.medicineId]
			if medicine then
				local itemFrame = CreateFrame({
					Name = "Expired_" .. item.medicineId,
					Size = UDim2.new(1, -5, 0, 35),
					BackgroundColor3 = Color3.fromRGB(50, 40, 40),
					Corner = 6,
					Parent = InventoryScroll,
				})

				CreateLabel({
					Name = "Name",
					Size = UDim2.new(1, -10, 0, 18),
					Position = UDim2.new(0, 5, 0, 2),
					Text = medicine.name,
					TextSize = 13,
					TextColor3 = Color3.fromRGB(150, 100, 100),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = itemFrame,
				})

				local expiredText = "Expired " .. item.daysSinceExpiry .. " day" .. (item.daysSinceExpiry > 1 and "s" or "") .. " ago"

				CreateLabel({
					Name = "ExpiredInfo",
					Size = UDim2.new(1, -10, 0, 14),
					Position = UDim2.new(0, 5, 0, 19),
					Text = expiredText,
					TextSize = 10,
					TextColor3 = Color3.fromRGB(120, 80, 80),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = itemFrame,
				})
			end
		end
	end

	-- Empty message
	if not hasValidItems and not hasExpiredItems then
		CreateLabel({
			Name = "Empty",
			Size = UDim2.new(1, 0, 0, 30),
			Text = "(Empty)",
			TextSize = 14,
			TextColor3 = Color3.fromRGB(150, 150, 150),
			Parent = InventoryScroll,
		})
	end
end

local function ShowNotification(text, color)
	NotificationLabel.Text = text
	if color == "green" then
		NotificationFrame.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
	elseif color == "red" then
		NotificationFrame.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
	elseif color == "blue" then
		NotificationFrame.BackgroundColor3 = Color3.fromRGB(30, 50, 80)
	else
		NotificationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	end
	NotificationFrame.Visible = true

	task.delay(4, function()
		NotificationFrame.Visible = false
	end)
end

local function CloseAllPanels()
	VillagerPanel.Visible = false
	MerchantPanel.Visible = false
	TentPanel.Visible = false
	InteractPanelOpen = false
end

-- Check if player has valid medicine
local function HasValidMedicine(medicineId)
	for _, item in ipairs(PlayerInventory.valid) do
		if item.medicineId == medicineId then
			return true
		end
	end
	return false
end

local function UpdateVillagerPanel(villagerIndex)
	local data = VillagerData[villagerIndex]
	if not data then
		VillagerPanel.Visible = false
		return
	end

	VillagerTitle.Text = data.DisplayName or ("Villager " .. villagerIndex)

	if not data.IsAlive then
		VillagerStatus.Text = "Status: DECEASED"
		VillagerStatus.TextColor3 = Color3.fromRGB(100, 100, 100)
		VillagerSickness.Text = ""
		VillagerNeeds.Text = ""
		VillagerHPFill.Size = UDim2.new(0, 0, 1, 0)
		VillagerHPFill.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		VillagerHPText.Text = "DEAD"
		VillagerCureBtn.Visible = false
	elseif data.Sickness then
		VillagerStatus.Text = "Status: SICK"
		VillagerStatus.TextColor3 = Color3.fromRGB(255, 150, 150)
		VillagerSickness.Text = "Sickness: " .. data.Sickness
		VillagerSickness.TextColor3 = Color3.fromRGB(255, 100, 100)
		VillagerNeeds.Text = "Needs: " .. (data.NeededMedicine or "Unknown")
		VillagerNeeds.TextColor3 = Color3.fromRGB(100, 200, 255)

		-- HP bar
		local hpPercent = data.HP / data.MaxHP
		VillagerHPFill.Size = UDim2.new(hpPercent, 0, 1, 0)
		VillagerHPText.Text = math.floor(data.HP) .. " / " .. data.MaxHP .. " HP"

		-- HP color
		if hpPercent > 0.66 then
			VillagerHPFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		elseif hpPercent > 0.33 then
			VillagerHPFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
		else
			VillagerHPFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		end

		-- Cure button
		local hasNeeded = data.NeededMedicineId and HasValidMedicine(data.NeededMedicineId)
		VillagerCureBtn.Visible = true
		VillagerCureBtn.BackgroundColor3 = hasNeeded and Color3.fromRGB(0, 150, 50) or Color3.fromRGB(80, 80, 80)
		VillagerCureBtn.Text = hasNeeded and "CURE" or "NO MEDICINE"
	else
		VillagerStatus.Text = "Status: HEALTHY"
		VillagerStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
		VillagerSickness.Text = ""
		VillagerNeeds.Text = ""
		VillagerHPFill.Size = UDim2.new(1, 0, 1, 0)
		VillagerHPFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		VillagerHPText.Text = data.MaxHP .. " / " .. data.MaxHP .. " HP"
		VillagerCureBtn.Visible = false
	end

	VillagerPanel.Visible = true
	InteractPanelOpen = true
end

local function UpdateMerchantPanel()
	-- Clear existing items
	for _, child in ipairs(MerchantScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Show sleep message if merchant is asleep
	MerchantSleepLabel.Visible = not MerchantAwake
	MerchantScroll.Visible = MerchantAwake

	if not MerchantAwake then
		MerchantPanel.Visible = true
		InteractPanelOpen = true
		return
	end

	-- Add merchant items
	for _, item in ipairs(MerchantStock) do
		local itemFrame = CreateFrame({
			Name = "Item_" .. item.id,
			Size = UDim2.new(1, 0, 0, 45),
			BackgroundColor3 = item.soldOut and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(40, 50, 40),
			Corner = 6,
			Parent = MerchantScroll,
		})

		CreateLabel({
			Name = "Name",
			Size = UDim2.new(0.45, 0, 0, 22),
			Position = UDim2.new(0, 10, 0, 3),
			Text = item.name,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = item.soldOut and Color3.fromRGB(120, 120, 120) or Color3.new(1, 1, 1),
			Parent = itemFrame,
		})

		CreateLabel({
			Name = "Cures",
			Size = UDim2.new(0.45, 0, 0, 16),
			Position = UDim2.new(0, 10, 0, 25),
			Text = "Cures: " .. item.cures,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = item.soldOut and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(180, 180, 180),
			Parent = itemFrame,
		})

		CreateLabel({
			Name = "Price",
			Size = UDim2.new(0.2, 0, 1, 0),
			Position = UDim2.new(0.45, 0, 0, 0),
			Text = "$" .. item.price,
			TextSize = 16,
			TextColor3 = item.soldOut and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(100, 255, 100),
			Parent = itemFrame,
		})

		if item.soldOut then
			CreateLabel({
				Name = "Status",
				Size = UDim2.new(0.25, -10, 1, 0),
				Position = UDim2.new(0.72, 0, 0, 0),
				Text = "SOLD OUT",
				TextSize = 12,
				TextColor3 = Color3.fromRGB(200, 100, 100),
				Parent = itemFrame,
			})
		else
			local canAfford = PlayerMoney >= item.price
			local buyBtn = CreateButton({
				Name = "BuyButton",
				Size = UDim2.new(0.22, -10, 0, 30),
				Position = UDim2.new(0.75, 0, 0.5, -15),
				BackgroundColor3 = canAfford and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(80, 80, 80),
				Text = "BUY",
				TextSize = 14,
				Parent = itemFrame,
			})

			buyBtn.MouseButton1Click:Connect(function()
				BuyMedicine:FireServer(item.id)
			end)
		end
	end

	MerchantPanel.Visible = true
	InteractPanelOpen = true
end

-- === BUTTON HANDLERS ===
local currentVillagerIndex = nil

VillagerCureBtn.MouseButton1Click:Connect(function()
	if not currentVillagerIndex then return end
	CureVillager:FireServer(currentVillagerIndex)
end)

VillagerCloseBtn.MouseButton1Click:Connect(function()
	CloseAllPanels()
end)

MerchantCloseBtn.MouseButton1Click:Connect(function()
	CloseAllPanels()
end)

TentSkipBtn.MouseButton1Click:Connect(function()
	SkipDay:FireServer()
	CloseAllPanels()
end)

TentCloseBtn.MouseButton1Click:Connect(function()
	CloseAllPanels()
end)

-- === SERVER EVENT HANDLERS ===
UpdatePlayer.OnClientEvent:Connect(function(data)
	if data.Money then PlayerMoney = data.Money end
	if data.Inventory then PlayerInventory = data.Inventory end
	if data.Day then CurrentDay = data.Day end
	UpdateTopBar()
	UpdateInventoryUI()

	-- Update panels if open
	if VillagerPanel.Visible and currentVillagerIndex then
		UpdateVillagerPanel(currentVillagerIndex)
	end
	if MerchantPanel.Visible then
		UpdateMerchantPanel()
	end
end)

UpdateVillagers.OnClientEvent:Connect(function(data)
	VillagerData = data
	if VillagerPanel.Visible and currentVillagerIndex then
		UpdateVillagerPanel(currentVillagerIndex)
	end
end)

UpdateMerchant.OnClientEvent:Connect(function(data)
	MerchantStock = data
	if MerchantPanel.Visible then
		UpdateMerchantPanel()
	end
end)

UpdatePrices.OnClientEvent:Connect(function(data)
	MedicinePrices = data
end)

UpdateTime.OnClientEvent:Connect(function(data)
	CurrentDay = data.day
	IsDay = data.isDay
	TimeRemaining = data.timeRemaining
	MerchantAwake = data.merchantAwake
	UpdateTopBar()

	-- Update merchant panel if open
	if MerchantPanel.Visible then
		UpdateMerchantPanel()
	end
end)

NewDay.OnClientEvent:Connect(function(data)
	CurrentDay = data.day
	local deathMsg = ""
	if data.deaths and data.deaths > 0 then
		deathMsg = " (" .. data.deaths .. " villager" .. (data.deaths > 1 and "s" or "") .. " died overnight)"
	end
	ShowNotification("Day " .. data.day .. " begins! Prices have changed!" .. deathMsg, "blue")
	UpdateTopBar()
end)

GameOver.OnClientEvent:Connect(function(data)
	IsGameOver = true
	GameOverMessage.Text = data.message or "All villagers have died!"
	GameOverStats.Text = "You survived " .. data.survivalDays .. " days"
	CloseAllPanels()
	GameOverPanel.Visible = true
end)

Notification.OnClientEvent:Connect(function(data)
	ShowNotification(data.text, data.color)
end)

-- === PROXIMITY DETECTION ===
local function GetCharacterPosition()
	local character = Player.Character
	if not character then return nil end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	return hrp.Position
end

local function FindClosestVillager()
	local playerPos = GetCharacterPosition()
	if not playerPos then return nil end

	local closest = nil
	local closestDist = VILLAGER_INTERACT_DISTANCE

	for i = 1, 8 do
		local villagerModel = workspace:FindFirstChild("Villager" .. i)
		if villagerModel then
			local villagerPart = villagerModel:FindFirstChild("HumanoidRootPart") or villagerModel.PrimaryPart or villagerModel:FindFirstChildWhichIsA("BasePart")
			if villagerPart then
				local dist = (villagerPart.Position - playerPos).Magnitude
				if dist < closestDist then
					closestDist = dist
					closest = i
				end
			end
		end
	end

	return closest
end

local function IsNearMerchant()
	local playerPos = GetCharacterPosition()
	if not playerPos then return false end

	local merchant = workspace:FindFirstChild("Merchant")
	if merchant then
		local merchantPart = merchant:FindFirstChild("HumanoidRootPart") or merchant.PrimaryPart or merchant:FindFirstChildWhichIsA("BasePart")
		if merchantPart then
			return (merchantPart.Position - playerPos).Magnitude < MERCHANT_INTERACT_DISTANCE
		end
	end
	return false
end

local function IsNearTent()
	local playerPos = GetCharacterPosition()
	if not playerPos then return false end

	local tent = workspace:FindFirstChild("Tent")
	if tent then
		local tentPart = tent.PrimaryPart or tent:FindFirstChildWhichIsA("BasePart")
		if tentPart then
			return (tentPart.Position - playerPos).Magnitude < TENT_INTERACT_DISTANCE
		end
	end
	return false
end

local function UpdateInteractPrompt()
	if IsGameOver or InteractPanelOpen then
		InteractPrompt.Visible = false
		CurrentInteractTarget = nil
		return
	end

	local closestVillager = FindClosestVillager()
	local nearMerchant = IsNearMerchant()
	local nearTent = IsNearTent()

	if closestVillager then
		local data = VillagerData[closestVillager]
		local name = data and data.DisplayName or ("Villager " .. closestVillager)
		InteractLabel.Text = "[E] Talk to " .. name
		InteractPrompt.Visible = true
		CurrentInteractTarget = { type = "villager", index = closestVillager }
	elseif nearMerchant then
		InteractLabel.Text = "[E] Talk to Merchant"
		InteractPrompt.Visible = true
		CurrentInteractTarget = { type = "merchant" }
	elseif nearTent then
		InteractLabel.Text = "[E] Rest at Tent"
		InteractPrompt.Visible = true
		CurrentInteractTarget = { type = "tent" }
	else
		InteractPrompt.Visible = false
		CurrentInteractTarget = nil
	end
end

-- === INPUT HANDLING ===
local function OnInteract()
	if IsGameOver then return end
	if InteractPanelOpen then return end
	if not CurrentInteractTarget then return end

	if CurrentInteractTarget.type == "villager" then
		currentVillagerIndex = CurrentInteractTarget.index
		-- Refresh villager data
		VillagerData = GetVillagerData:InvokeServer() or {}
		UpdateVillagerPanel(currentVillagerIndex)
	elseif CurrentInteractTarget.type == "merchant" then
		-- Refresh merchant stock
		MerchantStock = GetMerchantStock:InvokeServer() or {}
		UpdateMerchantPanel()
	elseif CurrentInteractTarget.type == "tent" then
		TentPanel.Visible = true
		InteractPanelOpen = true
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E then
		OnInteract()
	elseif input.KeyCode == Enum.KeyCode.Escape then
		if InteractPanelOpen then
			CloseAllPanels()
		end
	end
end)

-- === INITIALIZATION ===
local function Initialize()
	-- Get initial data from server
	local playerData = GetPlayerData:InvokeServer()
	if playerData then
		PlayerMoney = playerData.Money or 100
		PlayerInventory = playerData.Inventory or { valid = {}, expired = {} }
		CurrentDay = playerData.Day or 1
		IsDay = playerData.IsDay ~= false
		TimeRemaining = playerData.TimeRemaining or 300
	end

	VillagerData = GetVillagerData:InvokeServer() or {}
	MerchantStock = GetMerchantStock:InvokeServer() or {}
	MedicinePrices = GetPrices:InvokeServer() or {}

	UpdateTopBar()
	UpdateInventoryUI()

	-- Start proximity check loop
	RunService.Heartbeat:Connect(function()
		UpdateInteractPrompt()
	end)
end

Initialize()

print("GameClient ready!")
