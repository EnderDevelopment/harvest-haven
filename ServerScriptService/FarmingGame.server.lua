local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local farmingAction = ReplicatedStorage:FindFirstChild("FarmingAction")
if not farmingAction then
	farmingAction = Instance.new("RemoteEvent")
	farmingAction.Name = "FarmingAction"
	farmingAction.Parent = ReplicatedStorage
end

local SPOTS_PER_ROW = 4
local FARM_SPACING = 42
local SEED_BUNDLE_COST = 5
local SEEDS_PER_BUNDLE = 3
local STARTING_COINS = 100
local STARTING_SEEDS = 5

local TRACTORS = {
	Compact = {price = 100, speed = 16, color = Color3.fromRGB(65, 155, 75)},
	Utility = {price = 250, speed = 20, color = Color3.fromRGB(55, 105, 190)},
	HeavyDuty = {price = 500, speed = 24, color = Color3.fromRGB(190, 55, 45)},
}
local MAX_TRACTOR_UPGRADE = 5
local TRACTOR_UPGRADE_COST = 75
local SPEED_PER_UPGRADE = 2

local function updateTractorSpeed(player)
	local selected = player:FindFirstChild("SelectedTractor")
	local level = player:FindFirstChild("TractorUpgradeLevel")
	local speedValue = player:FindFirstChild("TractorSpeed")
	local data = selected and TRACTORS[selected.Value]
	if not data or not level or not speedValue then return end
	local speed = data.speed + level.Value * SPEED_PER_UPGRADE
	speedValue.Value = speed
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.WalkSpeed = speed end
end

local CROPS = {
	Wheat = {seedCost = 1, growSeconds = 20, reward = 12, color = Color3.fromRGB(235, 190, 65), size = Vector3.new(2.5, 3, 2.5), shape = Enum.PartType.Block},
	Carrot = {seedCost = 2, growSeconds = 35, reward = 24, color = Color3.fromRGB(235, 112, 45), size = Vector3.new(2, 2, 2), shape = Enum.PartType.Ball},
	Tomato = {seedCost = 3, growSeconds = 50, reward = 40, color = Color3.fromRGB(205, 55, 48), size = Vector3.new(2.2, 2.2, 2.2), shape = Enum.PartType.Ball},
	Pumpkin = {seedCost = 5, growSeconds = 75, reward = 70, color = Color3.fromRGB(235, 123, 38), size = Vector3.new(3.5, 2.8, 3.5), shape = Enum.PartType.Ball},
}

local cropNames = {}
for cropName in pairs(CROPS) do table.insert(cropNames, cropName) end
table.sort(cropNames)

local farmsFolder = Workspace:FindFirstChild("PlayerFarms") or Instance.new("Folder")
farmsFolder.Name = "PlayerFarms"
farmsFolder.Parent = Workspace

farmingAction.OnServerEvent:Connect(function(player, action, cropName)
	if action == "SelectCrop" then
		if typeof(cropName) == "string" and CROPS[cropName] then
			local selected = player:FindFirstChild("SelectedCrop")
			if selected then selected.Value = cropName end
		end
	elseif action == "BuySeeds" then
		local selected = player:FindFirstChild("SelectedCrop")
		local inventory = player:FindFirstChild("CropSeeds")
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		local seeds = selected and inventory and inventory:FindFirstChild(selected.Value)
		if coins and seeds and coins.Value >= SEED_BUNDLE_COST then
			coins.Value -= SEED_BUNDLE_COST
			seeds.Value += SEEDS_PER_BUNDLE
		end
	elseif action == "BuyTractor" then
		if typeof(cropName) ~= "string" or not TRACTORS[cropName] then return end
		local tractor = player:FindFirstChild("OwnedTractors")
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		local owned = tractor and tractor:FindFirstChild(cropName)
		if not coins or not owned or owned.Value then return end
		local data = TRACTORS[cropName]
		if coins.Value < data.price then return end
		coins.Value -= data.price
		owned.Value = true
		local selectedTractor = player:FindFirstChild("SelectedTractor")
		if selectedTractor then selectedTractor.Value = cropName end
	elseif action == "UpgradeTractor" then
		local level = player:FindFirstChild("TractorUpgradeLevel")
		local selectedTractor = player:FindFirstChild("SelectedTractor")
		local ownedFolder = player:FindFirstChild("OwnedTractors")
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		local owned = selectedTractor and ownedFolder and ownedFolder:FindFirstChild(selectedTractor.Value)
		if not level or not coins or not owned or not owned.Value or level.Value >= MAX_TRACTOR_UPGRADE then return end
		local cost = TRACTOR_UPGRADE_COST * (level.Value + 1)
		if coins.Value < cost then return end
		coins.Value -= cost
		level.Value += 1
		updateTractorSpeed(player)
	end
end)

local function makePart(name, size, color, position, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Position = position
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createDrivableTractor(player, origin)
	local model = Instance.new("Model")
	model.Name = "DrivableTractor"
	model.Parent = Workspace
	local startPosition = origin + Vector3.new(-11, 1.1, 7)
	local body = makePart("Body", Vector3.new(5, 1.5, 3), TRACTORS.Compact.color, startPosition, model)
	body.Anchored = false
	body:SetNetworkOwner(nil)
	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2, 0.6, 2)
	seat.CFrame = body.CFrame * CFrame.new(0, 1.25, 0)
	seat.Anchored = false
	seat.Parent = model
	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = body
	seatWeld.Part1 = seat
	seatWeld.Parent = body
	for _, offset in ipairs({Vector3.new(-1.8, -0.75, -1.25), Vector3.new(1.8, -0.75, -1.25), Vector3.new(-1.8, -0.75, 1.25), Vector3.new(1.8, -0.75, 1.25)}) do
		local wheel = makePart("Wheel", Vector3.new(1.3, 1.3, 1.3), Color3.fromRGB(35, 35, 35), startPosition + offset, model)
		wheel.Shape = Enum.PartType.Ball
		wheel.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = wheel
		weld.Parent = body
	end
	model.PrimaryPart = body
	local attachment = Instance.new("Attachment")
	attachment.Name = "DriveAttachment"
	attachment.Parent = body
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "DriveVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.MaxForce = 100000
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = body
	local turn = Instance.new("AngularVelocity")
	turn.Name = "DriveTurn"
	turn.Attachment0 = attachment
	turn.RelativeTo = Enum.ActuatorRelativeTo.World
	turn.MaxTorque = 100000
	turn.AngularVelocity = Vector3.zero
	turn.Parent = body
	local selected = player:WaitForChild("SelectedTractor")
	local function updateColor(name)
		local data = TRACTORS[name]
		if data then body.Color = data.color end
	end
	selected.Changed:Connect(updateColor)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = seat.Occupant
		if occupant and occupant.Parent == player.Character then
			pcall(function() body:SetNetworkOwner(player) end)
		else
			pcall(function() body:SetNetworkOwner(nil) end)
			velocity.VectorVelocity = Vector3.zero
			turn.AngularVelocity = Vector3.zero
		end
	end)
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not model.Parent then connection:Disconnect() return end
		local occupant = seat.Occupant
		if not occupant or occupant.Parent ~= player.Character then
			velocity.VectorVelocity = Vector3.zero
			turn.AngularVelocity = Vector3.zero
			return
		end
		local speed = player:FindFirstChild("TractorSpeed")
		local throttle = seat.ThrottleFloat
		velocity.VectorVelocity = body.CFrame.LookVector * (speed and speed.Value or TRACTORS.Compact.speed) * throttle
		turn.AngularVelocity = Vector3.new(0, -seat.SteerFloat * 1.8 * math.abs(throttle), 0)
	end)
	player.AncestryChanged:Connect(function(_, parent)
		if not parent and model.Parent then model:Destroy() end
	end)
end

local function addIntValue(name, value, parent)
	local item = Instance.new("IntValue")
	item.Name = name
	item.Value = value
	item.Parent = parent
	return item
end

local function selectedStatus(player)
	local selected = player:FindFirstChild("SelectedCrop")
	local inventory = player:FindFirstChild("CropSeeds")
	local seeds = selected and inventory and inventory:FindFirstChild(selected.Value)
	return selected and selected.Value or "Wheat", seeds and seeds.Value or 0
end

local function createFarm(player, index)
	local model = Instance.new("Model")
	model.Name = player.Name .. "Farm"
	model.Parent = farmsFolder
	local origin = Vector3.new((index - 1) * FARM_SPACING, 0, 0)
	local ground = makePart("FarmGround", Vector3.new(34, 1, 28), Color3.fromRGB(93, 160, 76), origin + Vector3.new(0, -0.5, 0), model)
	ground.Material = Enum.Material.Grass
	createDrivableTractor(player, origin)
	local sign = makePart("FarmSign", Vector3.new(8, 3, 0.5), Color3.fromRGB(111, 73, 43), origin + Vector3.new(0, 2, -13), model)
	local label = Instance.new("SurfaceGui")
	label.Face = Enum.NormalId.Front
	label.Parent = sign
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = player.DisplayName .. "'s Farm"
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Parent = label

	for row = 1, 2 do
		for column = 1, SPOTS_PER_ROW do
			local x = (column - 2.5) * 7
			local z = (row - 1.5) * 8
			local soil = makePart("CropPlot", Vector3.new(5.5, 0.6, 5.5), Color3.fromRGB(105, 70, 45), origin + Vector3.new(x, 0.3, z), model)
			soil.Material = Enum.Material.Ground
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Plant Wheat"
			prompt.ObjectText = "Empty Soil"
			prompt.HoldDuration = 0.4
			prompt.MaxActivationDistance = 10
			prompt.Parent = soil
			local spot = {crop = nil, growing = false, cropName = nil}

			prompt.Triggered:Connect(function(visitor)
				if visitor ~= player then return end
				local stats = player:FindFirstChild("leaderstats")
				local coins = stats and stats:FindFirstChild("Coins")
				local selected, seedCount = selectedStatus(player)
				local inventory = player:FindFirstChild("CropSeeds")
				local seeds = inventory and inventory:FindFirstChild(selected)
				if not coins or not seeds then return end

				if not spot.crop then
					local cropData = CROPS[selected]
					if not cropData or seedCount < cropData.seedCost then
						prompt.ObjectText = "Need " .. selected .. " seeds"
						task.delay(2, function()
							if prompt.Parent and not spot.crop then prompt.ObjectText = "Empty Soil" end
						end)
						return
					end
					seeds.Value -= cropData.seedCost
					local crop = makePart("GrowingCrop", Vector3.new(1, 1, 1), Color3.fromRGB(74, 160, 66), soil.Position + Vector3.new(0, 1, 0), model)
					crop.Shape = Enum.PartType.Ball
					spot.crop, spot.growing, spot.cropName = crop, true, selected
					prompt.ActionText = "Growing"
					prompt.ObjectText = selected .. " (" .. cropData.growSeconds .. "s)"
					task.delay(cropData.growSeconds, function()
						if not crop.Parent or not player.Parent then return end
						spot.growing = false
						crop.Size = cropData.size
						crop.Position = soil.Position + Vector3.new(0, 0.3 + cropData.size.Y / 2, 0)
						crop.Color, crop.Shape = cropData.color, cropData.shape
						prompt.ActionText = "Harvest (+" .. cropData.reward .. ")"
						prompt.ObjectText = "Ripe " .. selected
					end)
				elseif not spot.growing then
					local cropData = CROPS[spot.cropName]
					spot.crop:Destroy()
					spot.crop, spot.growing, spot.cropName = nil, false, nil
					coins.Value += cropData.reward
					prompt.ActionText = "Plant " .. selected
					prompt.ObjectText = "Empty Soil"
				end
			end)
		end
	end

	local shop = makePart("SeedShop", Vector3.new(5, 4, 3), Color3.fromRGB(62, 127, 190), origin + Vector3.new(13, 2, -8), model)
	shop.Material = Enum.Material.Wood
	local selectPrompt = Instance.new("ProximityPrompt")
	selectPrompt.ActionText = "Select Crop"
	selectPrompt.ObjectText = "Wheat"
	selectPrompt.HoldDuration = 0.3
	selectPrompt.MaxActivationDistance = 10
	selectPrompt.Parent = shop
	local shopPrompt = Instance.new("ProximityPrompt")
	shopPrompt.ActionText = "Buy 3 Wheat Seeds (5 Coins)"
	shopPrompt.ObjectText = "Seed Shop"
	shopPrompt.HoldDuration = 0.5
	shopPrompt.Parent = shop

	local dealership = makePart("TractorDealership", Vector3.new(7, 4, 4), Color3.fromRGB(190, 125, 45), origin + Vector3.new(12, 2, 1), model)
	dealership.Material = Enum.Material.Metal
	local tractorPrompt = Instance.new("ProximityPrompt")
	tractorPrompt.ActionText = "Browse tractors"
	tractorPrompt.ObjectText = "Tractor Dealership"
	tractorPrompt.HoldDuration = 0.3
	tractorPrompt.MaxActivationDistance = 10
	tractorPrompt.Parent = dealership
	local tractorIndex = 0
	tractorPrompt.Triggered:Connect(function(visitor)
		if visitor ~= player then return end
		local names = {"Compact", "Utility", "HeavyDuty"}
		tractorIndex = tractorIndex % #names + 1
		local tractorName = names[tractorIndex]
		local data = TRACTORS[tractorName]
		local ownedFolder = player:FindFirstChild("OwnedTractors")
		local owned = ownedFolder and ownedFolder:FindFirstChild(tractorName)
		if not owned then return end
		if owned.Value then
			player.SelectedTractor.Value = tractorName
			tractorPrompt.ActionText = "Selected " .. tractorName
		else
			local stats = player:FindFirstChild("leaderstats")
			local coins = stats and stats:FindFirstChild("Coins")
			if coins and coins.Value >= data.price then
				coins.Value -= data.price
				owned.Value = true
				player.SelectedTractor.Value = tractorName
				tractorPrompt.ActionText = "Purchased " .. tractorName
			else
				tractorPrompt.ActionText = tractorName .. " costs " .. data.price .. " coins"
			end
		end
		tractorPrompt.ObjectText = "Tractor Dealership"
	end)
	local display = Instance.new("Model")
	display.Name = "TractorDisplay"
	display.Parent = model
	local tractorBody = makePart("Body", Vector3.new(5, 1.5, 3), TRACTORS.Compact.color, origin + Vector3.new(12, 1.1, 7), display)
	local cabin = makePart("Cabin", Vector3.new(2, 2, 2.5), Color3.fromRGB(185, 220, 235), origin + Vector3.new(11, 2.8, 7), display)
	cabin.Transparency = 0.15
	for _, offset in ipairs({Vector3.new(9.5, 0.7, 5), Vector3.new(14.5, 0.7, 5), Vector3.new(9.5, 0.7, 9), Vector3.new(14.5, 0.7, 9)}) do
		local wheel = makePart("Wheel", Vector3.new(1.5, 1.5, 1.5), Color3.fromRGB(35, 35, 35), origin + offset, display)
		wheel.Shape = Enum.PartType.Cylinder
		wheel.Orientation = Vector3.new(0, 0, 90)
	end
	local selectedTractor = player:WaitForChild("SelectedTractor")
	selectedTractor.Changed:Connect(function(name)
		local data = TRACTORS[name]
		if data then
			tractorBody.Color = data.color
			updateTractorSpeed(player)
		end
	end)

	local upgradePrompt = Instance.new("ProximityPrompt")
	upgradePrompt.ActionText = "Upgrade Speed (75 Coins)"
	upgradePrompt.ObjectText = "Tractor Upgrade"
	upgradePrompt.HoldDuration = 0.5
	upgradePrompt.MaxActivationDistance = 10
	upgradePrompt.Parent = dealership
	upgradePrompt.Triggered:Connect(function(visitor)
		if visitor ~= player then return end
		local level = player:FindFirstChild("TractorUpgradeLevel")
		local ownedFolder = player:FindFirstChild("OwnedTractors")
		local selectedName = selectedTractor.Value
		local owned = ownedFolder and ownedFolder:FindFirstChild(selectedName)
		if not level or not owned or not owned.Value then
			upgradePrompt.ActionText = "Buy a tractor first"
			return
		end
		if level.Value >= MAX_TRACTOR_UPGRADE then
			upgradePrompt.ActionText = "Maximum speed reached"
			return
		end
		local cost = TRACTOR_UPGRADE_COST * (level.Value + 1)
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		if not coins or coins.Value < cost then
			upgradePrompt.ActionText = "Need " .. cost .. " coins"
			return
		end
		coins.Value -= cost
		level.Value += 1
		updateTractorSpeed(player)
		upgradePrompt.ActionText = "Speed upgraded to " .. player.TractorSpeed.Value
		task.delay(2, function()
			if upgradePrompt.Parent then upgradePrompt.ActionText = "Upgrade Speed (" .. (TRACTOR_UPGRADE_COST * (level.Value + 1)) .. " Coins)" end
		end)
	end)

	selectPrompt.Triggered:Connect(function(visitor)
		if visitor ~= player then return end
		local selected = player:FindFirstChild("SelectedCrop")
		local inventory = player:FindFirstChild("CropSeeds")
		if not selected or not inventory then return end
		local currentIndex = table.find(cropNames, selected.Value) or 1
		selected.Value = cropNames[currentIndex % #cropNames + 1]
		local newSelected, count = selectedStatus(player)
		selectPrompt.ObjectText = newSelected .. " Seeds: " .. count
		shopPrompt.ActionText = "Buy 3 " .. newSelected .. " Seeds (5 Coins)"
	end)

	shopPrompt.Triggered:Connect(function(visitor)
		if visitor ~= player then return end
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		local selected, _ = selectedStatus(player)
		local inventory = player:FindFirstChild("CropSeeds")
		local seeds = inventory and inventory:FindFirstChild(selected)
		if coins and seeds and coins.Value >= SEED_BUNDLE_COST then
			coins.Value -= SEED_BUNDLE_COST
			seeds.Value += SEEDS_PER_BUNDLE
			local currentSelected, count = selectedStatus(player)
			selectPrompt.ObjectText = currentSelected .. " Seeds: " .. count
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	addIntValue("Coins", STARTING_COINS, stats)
	local inventory = Instance.new("Folder")
	inventory.Name = "CropSeeds"
	inventory.Parent = player
	for cropName in pairs(CROPS) do addIntValue(cropName, cropName == "Wheat" and STARTING_SEEDS or 0, inventory) end
	local selected = Instance.new("StringValue")
	selected.Name = "SelectedCrop"
	local ownedTractors = Instance.new("Folder")
	ownedTractors.Name = "OwnedTractors"
	ownedTractors.Parent = player
	for tractorName in pairs(TRACTORS) do
		local owned = Instance.new("BoolValue")
		owned.Name = tractorName
		owned.Value = false
		owned.Parent = ownedTractors
	end
	local selectedTractor = Instance.new("StringValue")
	selectedTractor.Name = "SelectedTractor"
	selectedTractor.Value = ""
	selectedTractor.Parent = player
	local upgradeLevel = Instance.new("IntValue")
	upgradeLevel.Name = "TractorUpgradeLevel"
	upgradeLevel.Value = 0
	upgradeLevel.Parent = player
	local speedValue = Instance.new("NumberValue")
	speedValue.Name = "TractorSpeed"
	speedValue.Value = TRACTORS.Compact.speed
	speedValue.Parent = player
	local index = #Players:GetPlayers()
	createFarm(player, index)
	player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart")
		root.CFrame = CFrame.new((index - 1) * FARM_SPACING, 4, 10)
		local humanoid = character:WaitForChild("Humanoid")
		if selectedTractor.Value ~= "" then
			updateTractorSpeed(player)
		else
			humanoid.WalkSpeed = TRACTORS.Compact.speed
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local farm = farmsFolder:FindFirstChild(player.Name .. "Farm")
	if farm then farm:Destroy() end
end)
