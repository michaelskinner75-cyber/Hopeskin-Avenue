local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local island = Workspace:WaitForChild("HopeSkinIsland")
local trafficFolder = island:WaitForChild("BusTraffic")

-- Remove the earlier lightweight block passengers.
local oldFolder = island:FindFirstChild("StationPassengers")
if oldFolder then
	oldFolder:Destroy()
end

local passengerFolder = Instance.new("Folder")
passengerFolder.Name = "StationPassengersR15"
passengerFolder.Parent = island

local waitingPositions = {
	Vector3.new(-258, 1, 476),
	Vector3.new(-251, 1, 476),
	Vector3.new(-244, 1, 476),
	Vector3.new(-237, 1, 476),
	Vector3.new(-230, 1, 476),
	Vector3.new(-223, 1, 476),
}

local skinColours = {
	Color3.fromRGB(255, 219, 172),
	Color3.fromRGB(224, 172, 105),
	Color3.fromRGB(198, 134, 66),
	Color3.fromRGB(141, 85, 48),
	Color3.fromRGB(92, 60, 42),
}

local shirtColours = {
	Color3.fromRGB(44, 94, 164),
	Color3.fromRGB(181, 62, 62),
	Color3.fromRGB(52, 126, 78),
	Color3.fromRGB(122, 78, 154),
	Color3.fromRGB(210, 132, 46),
	Color3.fromRGB(68, 72, 82),
}

local function moveModelToGround(model, position, facingDirection)
	local direction = facingDirection or Vector3.new(0, 0, -1)
	if direction.Magnitude < 0.01 then
		direction = Vector3.new(0, 0, -1)
	end

	model:PivotTo(CFrame.lookAt(position, position + direction.Unit))
	local boxCFrame, boxSize = model:GetBoundingBox()
	local bottomY = boxCFrame.Position.Y - boxSize.Y / 2
	model:PivotTo(CFrame.new(0, position.Y - bottomY, 0) * model:GetPivot())
end

local function addSimpleHair(model, colour, styleIndex)
	local head = model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

	local hair = Instance.new("Part")
	hair.Name = "Hair"
	hair.Shape = Enum.PartType.Ball
	hair.Size = styleIndex % 2 == 0 and Vector3.new(1.75, 0.85, 1.65) or Vector3.new(1.65, 0.65, 1.55)
	hair.Color = colour
	hair.Material = Enum.Material.SmoothPlastic
	hair.CanCollide = false
	hair.Massless = true
	hair.Anchored = true
	hair.CFrame = head.CFrame * CFrame.new(0, 0.45, 0.02)
	hair.Parent = model
end

local function createPassenger(index, position)
	local description = Instance.new("HumanoidDescription")
	local skin = skinColours[(index - 1) % #skinColours + 1]
	local shirt = shirtColours[(index - 1) % #shirtColours + 1]
	local trousers = Color3.fromRGB(35 + (index * 13) % 45, 38, 50)

	description.HeadColor = skin
	description.LeftArmColor = skin
	description.RightArmColor = skin
	description.TorsoColor = shirt
	description.LeftLegColor = trousers
	description.RightLegColor = trousers
	description.HeightScale = 0.95 + ((index % 3) * 0.04)
	description.WidthScale = 0.9 + ((index % 2) * 0.08)
	description.HeadScale = 0.95
	description.BodyTypeScale = 0.35
	description.ProportionScale = 0.25

	local success, model = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	end)
	description:Destroy()

	if not success or not model then
		warn("Could not create R15 station passenger", index)
		return nil
	end

	model.Name = string.format("PassengerR15_%02d", index)
	model.Parent = passengerFolder

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.BreakJointsOnDeath = false
	end

	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.Massless = true
		end
	end

	local hairColour = Color3.fromRGB(28 + (index * 19) % 90, 20 + (index * 9) % 45, 14)
	addSimpleHair(model, hairColour, index)
	moveModelToGround(model, position, Vector3.new(0, 0, -1))
	return model
end

local passengers = {}
for index, position in ipairs(waitingPositions) do
	local passenger = createPassenger(index, position)
	if passenger then
		table.insert(passengers, passenger)
	end
end

local function setVisible(model, visible)
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Transparency = visible and 0 or 1
		elseif object:IsA("Decal") then
			object.Transparency = visible and 0 or 1
		end
	end
end

local function walkModel(model, destination, duration)
	if not model or not model.Parent then
		return
	end

	local startPosition = model:GetPivot().Position
	local movement = destination - startPosition
	local started = os.clock()

	while model.Parent and os.clock() - started < duration do
		local alpha = math.clamp((os.clock() - started) / duration, 0, 1)
		local position = startPosition:Lerp(destination, alpha)
		local direction = movement.Magnitude > 0.01 and movement.Unit or Vector3.new(0, 0, -1)
		moveModelToGround(model, position, direction)
		RunService.Heartbeat:Wait()
	end

	if model.Parent then
		moveModelToGround(model, destination, movement)
	end
end

local exchangeBusy = false
local lastBusNearStand = false
local cycleIndex = 1
local standPosition = Vector3.new(-230, 1, 515)

local function findBusAtStand()
	for _, bus in ipairs(trafficFolder:GetChildren()) do
		if bus:IsA("Model") then
			local position = bus:GetPivot().Position
			if (Vector3.new(position.X, 1, position.Z) - standPosition).Magnitude < 16 then
				return bus
			end
		end
	end
	return nil
end

local function exchangePassengers(bus)
	if exchangeBusy or #passengers < 4 then
		return
	end
	exchangeBusy = true

	local busPosition = bus:GetPivot().Position
	local doorPosition = Vector3.new(busPosition.X - 5, 1, busPosition.Z - 10)
	local alightArea = Vector3.new(-265, 1, 475)

	-- Two proper R15 passengers alight first.
	for offset = 1, 2 do
		local passenger = passengers[((cycleIndex + offset + 1) - 1) % #passengers + 1]
		setVisible(passenger, false)
		moveModelToGround(passenger, doorPosition + Vector3.new(offset * 1.8, 0, 0), Vector3.new(-1, 0, 0))
		setVisible(passenger, true)
		task.spawn(walkModel, passenger, alightArea + Vector3.new(offset * 5, 0, 0), 2.4)
	end

	task.wait(2.5)

	-- Two waiting passengers walk to the door and board.
	for offset = 0, 1 do
		local passenger = passengers[(cycleIndex + offset - 1) % #passengers + 1]
		task.spawn(function()
			walkModel(passenger, doorPosition + Vector3.new(offset * 1.6, 0, 0), 2.4)
			setVisible(passenger, false)
		end)
	end

	task.wait(2.7)
	cycleIndex = cycleIndex % #passengers + 1

	for index, passenger in ipairs(passengers) do
		if passenger.Parent then
			moveModelToGround(passenger, waitingPositions[index], Vector3.new(0, 0, -1))
			setVisible(passenger, true)
		end
	end

	exchangeBusy = false
end

RunService.Heartbeat:Connect(function()
	local bus = findBusAtStand()
	local nearStand = bus ~= nil
	if nearStand and not lastBusNearStand then
		task.spawn(exchangePassengers, bus)
	end
	lastBusNearStand = nearStand
end)

print("Full R15 station passengers loaded")
