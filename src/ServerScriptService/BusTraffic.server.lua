local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local island = Workspace:WaitForChild("HopeSkinIsland")
local template = ServerStorage:WaitForChild("Enviro400")

local trafficFolder = island:FindFirstChild("BusTraffic")
if trafficFolder then
	trafficFolder:Destroy()
end
trafficFolder = Instance.new("Folder")
trafficFolder.Name = "BusTraffic"
trafficFolder.Parent = island

local passengerFolder = island:FindFirstChild("StationPassengers")
if passengerFolder then
	passengerFolder:Destroy()
end
passengerFolder = Instance.new("Folder")
passengerFolder.Name = "StationPassengers"
passengerFolder.Parent = island

local BUS_COUNT = 2
local SPEED = 26
local ROAD_SURFACE_Y = 1
local BUS_FACING_OFFSET = math.rad(90)
local STAND_STOP_TIME = 8

-- Correct station flow: enter from the right/east entrance, use a yellow stand,
-- reverse out, then leave through the left/west exit.
local route = {
	{position = Vector3.new(0, 0, 455)},
	{position = Vector3.new(-120, 0, 455)},
	{position = Vector3.new(-230, 0, 455)},
	{position = Vector3.new(-230, 0, 515), pause = STAND_STOP_TIME, exchange = true},
	{position = Vector3.new(-230, 0, 455), reverse = true},
	{position = Vector3.new(-285, 0, 455)},
	{position = Vector3.new(-360, 0, 455)},

	-- Continue around the wider town road network.
	{position = Vector3.new(-360, 0, 340)},
	{position = Vector3.new(-360, 0, 0)},
	{position = Vector3.new(-360, 0, -340)},
	{position = Vector3.new(0, 0, -340)},
	{position = Vector3.new(360, 0, -340)},
	{position = Vector3.new(360, 0, 0)},
	{position = Vector3.new(360, 0, 340)},
	{position = Vector3.new(0, 0, 340)},
	{position = Vector3.new(0, 0, 455)},
}

local function cleanBus(bus)
	for _, object in ipairs(bus:GetDescendants()) do
		if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript")
			or object:IsA("RemoteEvent") or object:IsA("RemoteFunction") then
			object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.Massless = true
		end
	end
end

local function placeOnRoad(bus, position, movementDirection, reversing)
	local direction = movementDirection
	if direction.Magnitude < 0.01 then
		direction = Vector3.new(0, 0, -1)
	end
	if reversing then
		direction = -direction
	end

	local facing = CFrame.lookAt(position, position + direction.Unit)
		* CFrame.Angles(0, BUS_FACING_OFFSET, 0)
	bus:PivotTo(facing)

	local boxCFrame, boxSize = bus:GetBoundingBox()
	local bottomY = boxCFrame.Position.Y - boxSize.Y / 2
	bus:PivotTo(CFrame.new(0, ROAD_SURFACE_Y - bottomY, 0) * bus:GetPivot())
end

local skinTones = {
	Color3.fromRGB(255, 219, 172),
	Color3.fromRGB(224, 172, 105),
	Color3.fromRGB(198, 134, 66),
	Color3.fromRGB(141, 85, 48),
	Color3.fromRGB(92, 60, 42),
}

local shirtColours = {
	Color3.fromRGB(40, 92, 156),
	Color3.fromRGB(180, 62, 62),
	Color3.fromRGB(54, 125, 79),
	Color3.fromRGB(112, 72, 142),
	Color3.fromRGB(205, 126, 45),
	Color3.fromRGB(65, 65, 72),
}

local function bodyPart(parent, name, size, cframe, colour, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = colour
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

-- Stylised Roblox passengers with full bodies, clothing and hair rather than
-- simple stick figures. They are lightweight so the map still loads quickly.
local function createPassenger(index, position)
	local model = Instance.new("Model")
	model.Name = string.format("Passenger_%02d", index)
	model.Parent = passengerFolder

	local skin = skinTones[(index - 1) % #skinTones + 1]
	local shirt = shirtColours[(index - 1) % #shirtColours + 1]
	local trousers = Color3.fromRGB(35 + (index * 11) % 45, 38, 48)
	local hairColour = Color3.fromRGB(35 + (index * 19) % 90, 24 + (index * 7) % 45, 18)

	local root = bodyPart(model, "Root", Vector3.new(1.8, 2.1, 1.05), CFrame.new(0, 3.15, 0), shirt)
	bodyPart(model, "Head", Vector3.new(1.45, 1.45, 1.45), CFrame.new(0, 5.05, 0), skin, Enum.PartType.Ball)
	bodyPart(model, "Hair", Vector3.new(1.5, 0.45, 1.5), CFrame.new(0, 5.62, -0.03), hairColour)
	bodyPart(model, "LeftArm", Vector3.new(0.55, 2.05, 0.6), CFrame.new(-1.18, 3.18, 0), skin)
	bodyPart(model, "RightArm", Vector3.new(0.55, 2.05, 0.6), CFrame.new(1.18, 3.18, 0), skin)
	bodyPart(model, "LeftLeg", Vector3.new(0.72, 2.25, 0.78), CFrame.new(-0.48, 1.0, 0), trousers)
	bodyPart(model, "RightLeg", Vector3.new(0.72, 2.25, 0.78), CFrame.new(0.48, 1.0, 0), trousers)
	bodyPart(model, "LeftShoe", Vector3.new(0.78, 0.35, 1.05), CFrame.new(-0.48, -0.25, -0.12), Color3.fromRGB(25, 25, 28))
	bodyPart(model, "RightShoe", Vector3.new(0.78, 0.35, 1.05), CFrame.new(0.48, -0.25, -0.12), Color3.fromRGB(25, 25, 28))

	model.PrimaryPart = root
	model:PivotTo(CFrame.new(position))
	return model
end

local waitingPositions = {
	Vector3.new(-258, 1, 476),
	Vector3.new(-252, 1, 476),
	Vector3.new(-246, 1, 476),
	Vector3.new(-240, 1, 476),
	Vector3.new(-234, 1, 476),
	Vector3.new(-228, 1, 476),
}

local waitingPassengers = {}
for index, position in ipairs(waitingPositions) do
	waitingPassengers[index] = createPassenger(index, position)
end

local function setPassengerVisible(passenger, visible)
	for _, object in ipairs(passenger:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Transparency = visible and 0 or 1
		end
	end
end

local function walkPassenger(passenger, destination, duration)
	local start = passenger:GetPivot()
	local finishPosition = destination
	local startPosition = start.Position
	local direction = finishPosition - startPosition
	local startTime = os.clock()

	while passenger.Parent and os.clock() - startTime < duration do
		local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
		local position = startPosition:Lerp(finishPosition, alpha)
		local lookDirection = direction.Magnitude > 0.01 and direction.Unit or Vector3.new(0, 0, -1)
		passenger:PivotTo(CFrame.lookAt(position, position + lookDirection))
		RunService.Heartbeat:Wait()
	end

	if passenger.Parent then
		passenger:PivotTo(CFrame.new(finishPosition))
	end
end

local exchangeBusy = false
local nextPassengerIndex = 1

local function exchangePassengers(bus)
	if exchangeBusy then
		return
	end
	exchangeBusy = true

	local busPosition = bus:GetPivot().Position
	local doorPosition = Vector3.new(busPosition.X - 5, 1, busPosition.Z - 10)
	local pavementDestination = Vector3.new(-260, 1, 472)

	-- Two passengers alight first and walk onto the platform.
	for offset = 1, 2 do
		local passenger = waitingPassengers[((nextPassengerIndex + offset + 1) - 1) % #waitingPassengers + 1]
		setPassengerVisible(passenger, false)
		passenger:PivotTo(CFrame.new(doorPosition + Vector3.new(offset * 1.6, 0, 0)))
		setPassengerVisible(passenger, true)
		task.spawn(function()
			walkPassenger(passenger, pavementDestination + Vector3.new(offset * 5, 0, 0), 2.2)
		end)
	end

	task.wait(2.4)

	-- Two waiting passengers walk to the bus door and disappear inside.
	for offset = 0, 1 do
		local index = (nextPassengerIndex + offset - 1) % #waitingPassengers + 1
		local passenger = waitingPassengers[index]
		task.spawn(function()
			walkPassenger(passenger, doorPosition + Vector3.new(offset * 1.5, 0, 0), 2.2)
			setPassengerVisible(passenger, false)
		end)
	end

	nextPassengerIndex = (nextPassengerIndex + 2 - 1) % #waitingPassengers + 1
	task.wait(2.5)

	-- Re-form a visible waiting group for the next bus visit.
	for index, passenger in ipairs(waitingPassengers) do
		if passenger.Parent and passenger:GetPivot().Position.Z < 490 then
			passenger:PivotTo(CFrame.new(waitingPositions[index]))
			setPassengerVisible(passenger, true)
		end
	end

	exchangeBusy = false
end

local segments = {}
local totalLength = 0
for index = 1, #route do
	local nextIndex = index % #route + 1
	local startPoint = route[index].position
	local destination = route[nextIndex]
	local finishPoint = destination.position
	local length = (finishPoint - startPoint).Magnitude
	segments[index] = {
		startPoint = startPoint,
		endPoint = finishPoint,
		length = length,
		startDistance = totalLength,
		reverse = destination.reverse == true,
		pause = destination.pause or 0,
		exchange = destination.exchange == true,
	}
	totalLength += length
end

local function routePosition(distance)
	distance %= totalLength
	for index, segment in ipairs(segments) do
		if distance <= segment.startDistance + segment.length then
			local localDistance = distance - segment.startDistance
			local alpha = segment.length > 0 and localDistance / segment.length or 0
			local position = segment.startPoint:Lerp(segment.endPoint, alpha)
			return position, segment.endPoint - segment.startPoint, index, segment.reverse
		end
	end
	local segment = segments[#segments]
	return segment.endPoint, segment.endPoint - segment.startPoint, #segments, segment.reverse
end

local buses = {}
for index = 1, BUS_COUNT do
	local bus = template:Clone()
	bus.Name = string.format("Enviro400_%02d", index)
	bus.Parent = trafficFolder
	cleanBus(bus)

	local distance = totalLength * ((index - 1) / BUS_COUNT)
	local position, direction, _, reversing = routePosition(distance)
	placeOnRoad(bus, position, direction, reversing)

	buses[index] = {
		model = bus,
		distance = distance,
		pauseRemaining = 0,
		lastSegment = nil,
	}
end

RunService.Heartbeat:Connect(function(deltaTime)
	for _, data in ipairs(buses) do
		if data.model.Parent then
			if data.pauseRemaining > 0 then
				data.pauseRemaining = math.max(0, data.pauseRemaining - deltaTime)
			else
				data.distance = (data.distance + SPEED * deltaTime) % totalLength
			end

			local position, direction, segmentIndex, reversing = routePosition(data.distance)
			placeOnRoad(data.model, position, direction, reversing)

			if segmentIndex ~= data.lastSegment then
				local previousIndex = segmentIndex - 1
				if previousIndex < 1 then
					previousIndex = #segments
				end
				local previousSegment = segments[previousIndex]
				if previousSegment.pause and previousSegment.pause > 0 then
					data.pauseRemaining = previousSegment.pause
					if previousSegment.exchange then
						task.spawn(exchangePassengers, data.model)
					end
				end
			end
			data.lastSegment = segmentIndex
		end
	end
end)

print("Two buses now use the correct station entrance and exchange passengers")
