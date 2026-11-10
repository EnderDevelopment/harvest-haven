local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local farmingAction = ReplicatedStorage:WaitForChild("FarmingAction")
local cropNames = {"Wheat", "Carrot", "Tomato", "Pumpkin"}

local gui = Instance.new("ScreenGui")
gui.Name = "FarmingUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "CropPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -18, 0, 18)
panel.Size = UDim2.fromOffset(245, 285)
panel.BackgroundColor3 = Color3.fromRGB(41, 55, 40)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 34)
title.Position = UDim2.fromOffset(12, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "Crops & Seeds"
title.TextColor3 = Color3.fromRGB(245, 240, 220)
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local list = Instance.new("Frame")
list.Position = UDim2.fromOffset(12, 48)
list.Size = UDim2.new(1, -24, 0, 176)
list.BackgroundTransparency = 1
list.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local buttons = {}
for index, cropName in ipairs(cropNames) do
	local button = Instance.new("TextButton")
	button.Name = cropName .. "Button"
	button.LayoutOrder = index
	button.Size = UDim2.new(1, 0, 0, 38)
	button.BackgroundColor3 = Color3.fromRGB(75, 88, 67)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.TextColor3 = Color3.fromRGB(245, 240, 220)
	button.TextSize = 15
	button.AutoButtonColor = true
	button.Parent = list
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 7)
	buttonCorner.Parent = button
	buttons[cropName] = button
	button.Activated:Connect(function()
		farmingAction:FireServer("SelectCrop", cropName)
	end)
end

local buyButton = Instance.new("TextButton")
buyButton.Name = "BuySeedsButton"
buyButton.Position = UDim2.new(0, 12, 1, -49)
buyButton.Size = UDim2.new(1, -24, 0, 38)
buyButton.BackgroundColor3 = Color3.fromRGB(191, 130, 52)
buyButton.BorderSizePixel = 0
buyButton.Font = Enum.Font.GothamBold
buyButton.TextColor3 = Color3.fromRGB(255, 250, 230)
buyButton.TextSize = 15
buyButton.Parent = panel
local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 7)
buyCorner.Parent = buyButton
buyButton.Activated:Connect(function()
	farmingAction:FireServer("BuySeeds")
end)

local inventory = player:WaitForChild("CropSeeds")
local selected = player:WaitForChild("SelectedCrop")
local coins = player:WaitForChild("leaderstats"):WaitForChild("Coins")
local connections = {}

local function refresh()
	for _, cropName in ipairs(cropNames) do
		local seedValue = inventory:FindFirstChild(cropName)
		local count = seedValue and seedValue.Value or 0
		local button = buttons[cropName]
		local isSelected = selected.Value == cropName
		button.Text = (isSelected and "Selected  |  " or "") .. cropName .. " Seeds: " .. count
		button.BackgroundColor3 = isSelected and Color3.fromRGB(82, 132, 77) or Color3.fromRGB(75, 88, 67)
	end
	buyButton.Text = "Buy 3 " .. selected.Value .. " Seeds  |  5 Coins"
	buyButton.Active = coins.Value >= 5
	buyButton.BackgroundTransparency = coins.Value >= 5 and 0 or 0.4
end

for _, cropName in ipairs(cropNames) do
	local seedValue = inventory:WaitForChild(cropName)
	table.insert(connections, seedValue.Changed:Connect(refresh))
end
table.insert(connections, selected.Changed:Connect(refresh))
table.insert(connections, coins.Changed:Connect(refresh))
refresh()

local tractorPanel = Instance.new("Frame")
tractorPanel.Name = "TractorStats"
tractorPanel.AnchorPoint = Vector2.new(1, 0)
tractorPanel.Position = UDim2.new(1, -18, 0, 315)
tractorPanel.Size = UDim2.fromOffset(245, 105)
tractorPanel.BackgroundColor3 = Color3.fromRGB(41, 55, 40)
tractorPanel.BackgroundTransparency = 0.08
tractorPanel.BorderSizePixel = 0
tractorPanel.Parent = gui
local tractorCorner = Instance.new("UICorner")
tractorCorner.CornerRadius = UDim.new(0, 12)
tractorCorner.Parent = tractorPanel

local tractorLabel = Instance.new("TextLabel")
tractorLabel.Size = UDim2.new(1, -20, 1, -12)
tractorLabel.Position = UDim2.fromOffset(10, 6)
tractorLabel.BackgroundTransparency = 1
tractorLabel.Font = Enum.Font.GothamMedium
tractorLabel.TextColor3 = Color3.fromRGB(245, 240, 220)
tractorLabel.TextSize = 15
tractorLabel.TextXAlignment = Enum.TextXAlignment.Left
tractorLabel.TextYAlignment = Enum.TextYAlignment.Center
tractorLabel.TextWrapped = true
tractorLabel.Parent = tractorPanel

local selectedTractor = player:WaitForChild("SelectedTractor")
local upgradeLevel = player:WaitForChild("TractorUpgradeLevel")
local tractorSpeed = player:WaitForChild("TractorSpeed")
local MAX_UPGRADES = 5
local UPGRADE_BASE_COST = 75
local function refreshTractorStats()
	local nextCost = upgradeLevel.Value < MAX_UPGRADES and (UPGRADE_BASE_COST * (upgradeLevel.Value + 1)) or nil
	local tractorName = selectedTractor.Value ~= "" and selectedTractor.Value or "None"
	local upgradeText = nextCost and ("Next upgrade: " .. nextCost .. " coins") or "Speed upgrades maxed"
	tractorLabel.Text = "Tractor: " .. tractorName .. "\\nSpeed: " .. math.floor(tractorSpeed.Value) .. "\\nUpgrade level: " .. upgradeLevel.Value .. "/" .. MAX_UPGRADES .. "\\n" .. upgradeText
end

table.insert(connections, selectedTractor.Changed:Connect(refreshTractorStats))
table.insert(connections, upgradeLevel.Changed:Connect(refreshTractorStats))
table.insert(connections, tractorSpeed.Changed:Connect(refreshTractorStats))
refreshTractorStats()

gui.Destroying:Connect(function()
	for _, connection in ipairs(connections) do connection:Disconnect() end
end)
