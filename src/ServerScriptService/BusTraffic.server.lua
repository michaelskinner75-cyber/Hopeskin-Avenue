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

local BUS_COUNT = 2
local SPEED = 26
local ROAD_SURFACE_Y = 1
local BUS_FACING_OFFSET = math.rad(90)

-- The station circulation road runs across the front of the yellow stands.
-- Each bus turns into a marked stand, pauses, then reverses back onto the
-- circulation road before continuing through the rest of the town.
local route = {
	{position = Vector3.new(-360, 0, 455)},
	{position = Vector3.new(-285, 0, 455)},
	{position = Vector3.new(-230, 0, 455)},
	{position = Vector3.new(-230, 0, 515), pause = 5}, -- drive into yellow stand
	{position = Vector3.new(-230, 0, 455), reverse = true}, -- reverse out
	{position = Vector3.new(-120, 0, 455)},
	{position = Vector3.new(0, 0, 455)},
	{position = Vector3.new(0, 0, 340)},
	{position = Vector3.new(360, 0, 340)},
	{position = Vector3.new(360, 0, 0)},
	{position = Vector3.new(360, 0, -340)},
	{position = Vector3.new(0, 0, -340)},
	{position = Vector3.new(-360, 0, -340)},
	{position = Vector3.new(-360, 0, 0)},
	{position = Vector3.new(0, 0, 0)},
	{position = Vector3.new(360, 0, 0)},
	{position = Vector3.new(0, 0, 0)},
	{position = Vector3.new(0, 0, -340)},
	{position = Vector3.new(0, 0, 0)},
	{position = Vector3.new(0, 0, 340)},
	{position = Vector3.new(-360, 0, 340)},
	{position = Vector3.new(-360, 0, 455)},
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
				local pause = segments[previousIndex].pause
				if pause and pause > 0 then
					data.pauseRemaining = pause
				end
			end
			data.lastSegment = segmentIndex
		end
	end
end)

print("Two Enviro 400 buses now enter a stand, pause and reverse out")
