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

local BUS_COUNT = 6
local SPEED = 26
local ROAD_SURFACE_Y = 1
local STOP_TIME = 3
local BUS_FACING_OFFSET = math.rad(90)

-- Long town route using the north, central and south streets plus all three
-- north/south roads. It enters the bus station from the west and leaves east.
local waypoints = {
	-- Bus station, west to east.
	Vector3.new(-360, 0, 500),
	Vector3.new(-300, 0, 500),
	Vector3.new(-210, 0, 500),
	Vector3.new(-110, 0, 500),
	Vector3.new(0, 0, 500),

	-- HopeSkin Avenue south to South Street.
	Vector3.new(0, 0, 340),

	-- South Street east, then the full East Road north.
	Vector3.new(360, 0, 340),
	Vector3.new(360, 0, 0),
	Vector3.new(360, 0, -340),

	-- North Street across the whole town.
	Vector3.new(0, 0, -340),
	Vector3.new(-360, 0, -340),

	-- West Road south to Central Boulevard.
	Vector3.new(-360, 0, 0),

	-- Central Boulevard across the whole town and back to HopeSkin Avenue.
	Vector3.new(0, 0, 0),
	Vector3.new(360, 0, 0),
	Vector3.new(0, 0, 0),

	-- HopeSkin Avenue north and then south to cover its full length.
	Vector3.new(0, 0, -340),
	Vector3.new(0, 0, 0),
	Vector3.new(0, 0, 340),

	-- South Street across the whole town.
	Vector3.new(-360, 0, 340),

	-- West Road back to the station entrance.
	Vector3.new(-360, 0, 500),
}

local stopWaypointIndex = 3

local function cleanBus(bus)
	for _, object in ipairs(bus:GetDescendants()) do
		if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
			object:Destroy()
		elseif object:IsA("RemoteEvent") or object:IsA("RemoteFunction") then
			object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.Massless = true
		end
	end
end

local function placeOnRoad(bus, position, lookAt)
	local direction = lookAt - position
	if direction.Magnitude < 0.01 then
		direction = Vector3.new(0, 0, -1)
	end

	-- This imported bus is modelled with its front along its local X axis,
	-- so rotate it 90 degrees after looking towards the next waypoint.
	local facing = CFrame.lookAt(position, position + direction.Unit)
		* CFrame.Angles(0, BUS_FACING_OFFSET, 0)
	bus:PivotTo(facing)

	local boxCFrame, boxSize = bus:GetBoundingBox()
	local bottomY = boxCFrame.Position.Y - boxSize.Y / 2
	bus:PivotTo(CFrame.new(0, ROAD_SURFACE_Y - bottomY, 0) * bus:GetPivot())
end

local segments = {}
local totalLength = 0
for index = 1, #waypoints - 1 do
	local startPoint = waypoints[index]
	local endPoint = waypoints[index + 1]
	local length = (endPoint - startPoint).Magnitude
	segments[index] = {
		startPoint = startPoint,
		endPoint = endPoint,
		length = length,
		startDistance = totalLength,
	}
	totalLength += length
end

local function routePosition(distance)
	distance %= totalLength
	for index, segment in ipairs(segments) do
		if distance <= segment.startDistance + segment.length then
			local localDistance = distance - segment.startDistance
			local alpha = segment.length > 0 and localDistance / segment.length or 0
			return segment.startPoint:Lerp(segment.endPoint, alpha), segment.endPoint, index
		end
	end
	local finalSegment = segments[#segments]
	return finalSegment.endPoint, waypoints[1], #segments
end

local buses = {}
for index = 1, BUS_COUNT do
	local bus = template:Clone()
	bus.Name = string.format("Enviro400_%02d", index)
	bus.Parent = trafficFolder
	cleanBus(bus)

	local distance = totalLength * ((index - 1) / BUS_COUNT)
	local position, nextPoint = routePosition(distance)
	placeOnRoad(bus, position, nextPoint)

	buses[index] = {
		model = bus,
		distance = distance,
		pauseRemaining = 0,
		lastSegment = nil,
	}
end

RunService.Heartbeat:Connect(function(deltaTime)
	for _, data in ipairs(buses) do
		local bus = data.model
		if bus.Parent then
			if data.pauseRemaining > 0 then
				data.pauseRemaining = math.max(0, data.pauseRemaining - deltaTime)
			else
				data.distance = (data.distance + SPEED * deltaTime) % totalLength
			end

			local position, nextPoint, segmentIndex = routePosition(data.distance)
			placeOnRoad(bus, position, nextPoint)

			if segmentIndex == stopWaypointIndex and data.lastSegment ~= stopWaypointIndex then
				data.pauseRemaining = STOP_TIME
			end
			data.lastSegment = segmentIndex
		end
	end
end)

print("Six correctly oriented Enviro 400 buses routed across HopeSkin Avenue")
