local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local island = Workspace:WaitForChild("HopeSkinIsland")
local reservedAreas = island:WaitForChild("ReservedAreas")
local roads = island:WaitForChild("Roads")
local pavements = island:WaitForChild("Pavements")
local markings = island:WaitForChild("Markings")
local site = reservedAreas:WaitForChild("BusStationSite")
local template = ServerStorage:WaitForChild("BusStation")

local existing = island:FindFirstChild("BusStation")
if existing then
	existing:Destroy()
end

local generatedNames = {
	"BusStationAccessRoad",
	"BusStationAccessLeftPavement",
	"BusStationAccessRightPavement",
	"BusStationForecourt",
	"BusStationWestAccess",
	"BusStationEastAccess",
	"BusStationOuterLeftPavement",
	"BusStationOuterRightPavement",
	"BusStationFrontPavement",
	"BusStationWestArrow",
	"BusStationEastArrow",
}

for _, name in ipairs(generatedNames) do
	local old = island:FindFirstChild(name, true)
	if old then
		old:Destroy()
	end
end

local function makePart(parent, name, size, position, colour, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.Position = position
	object.Anchored = true
	object.CanCollide = true
	object.Color = colour
	object.Material = material
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local station = template:Clone()
station.Name = "BusStation"
station.Parent = island

for _, object in ipairs(station:GetDescendants()) do
	if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
		object:Destroy()
	elseif object:IsA("BasePart") then
		object.Anchored = true
	end
end

-- Centre the imported station over its reserved area.
local boxCFrame = station:GetBoundingBox()
local horizontalMove = Vector3.new(
	site.Position.X - boxCFrame.Position.X,
	0,
	site.Position.Z - boxCFrame.Position.Z
)
station:PivotTo(CFrame.new(horizontalMove) * station:GetPivot())

-- Align the station's real roadway surface with the town roads.
local stationBase = station:FindFirstChild("Base", true)
if not stationBase or not stationBase:IsA("BasePart") then
	error("Bus station model is missing its roadway part named Base")
end

local roadSurfaceY = 1
local baseTopY = stationBase.Position.Y + stationBase.Size.Y / 2
station:PivotTo(CFrame.new(0, roadSurfaceY - baseTopY, 0) * station:GetPivot())

-- Use the real station road dimensions rather than the overall model bounds.
local stationCentreX = stationBase.Position.X
local stationFrontZ = stationBase.Position.Z - stationBase.Size.Z / 2
local stationWidth = stationBase.Size.X

local roadColour = Color3.fromRGB(48, 51, 56)
local pavementColour = Color3.fromRGB(158, 158, 158)
local white = Color3.fromRGB(238, 238, 238)

-- A wide asphalt forecourt overlaps the station road slightly, hiding the join.
local forecourtDepth = 34
local forecourtWidth = math.max(120, stationWidth - 8)
local forecourtCentreZ = stationFrontZ - forecourtDepth / 2 + 3
makePart(
	roads,
	"BusStationForecourt",
	Vector3.new(forecourtWidth, 1, forecourtDepth),
	Vector3.new(stationCentreX, 0.5, forecourtCentreZ),
	roadColour,
	Enum.Material.Asphalt
)

-- Two separate access roads line up with the station's left and right vehicle exits.
local southStreetNorthEdge = 340 + 38 / 2
local forecourtSouthEdge = forecourtCentreZ - forecourtDepth / 2
local accessLength = math.max(8, forecourtSouthEdge - southStreetNorthEdge + 4)
local accessCentreZ = southStreetNorthEdge + accessLength / 2 - 2
local laneOffset = math.min(stationWidth * 0.32, 72)
local accessWidth = 34
local westX = stationCentreX - laneOffset
local eastX = stationCentreX + laneOffset

makePart(
	roads,
	"BusStationWestAccess",
	Vector3.new(accessWidth, 1, accessLength),
	Vector3.new(westX, 0.5, accessCentreZ),
	roadColour,
	Enum.Material.Asphalt
)

makePart(
	roads,
	"BusStationEastAccess",
	Vector3.new(accessWidth, 1, accessLength),
	Vector3.new(eastX, 0.5, accessCentreZ),
	roadColour,
	Enum.Material.Asphalt
)

-- Pavements frame the outside of the whole entrance instead of cutting across it.
local outerOffset = laneOffset + accessWidth / 2 + 7
makePart(
	pavements,
	"BusStationOuterLeftPavement",
	Vector3.new(14, 1, accessLength + forecourtDepth),
	Vector3.new(stationCentreX - outerOffset, 1, accessCentreZ + forecourtDepth / 2),
	pavementColour,
	Enum.Material.Concrete
)

makePart(
	pavements,
	"BusStationOuterRightPavement",
	Vector3.new(14, 1, accessLength + forecourtDepth),
	Vector3.new(stationCentreX + outerOffset, 1, accessCentreZ + forecourtDepth / 2),
	pavementColour,
	Enum.Material.Concrete
)

-- Small centre island gives the entrance a deliberate bus-station layout.
local islandWidth = math.max(18, (eastX - westX) - accessWidth)
makePart(
	pavements,
	"BusStationFrontPavement",
	Vector3.new(islandWidth, 1, math.max(10, accessLength - 8)),
	Vector3.new(stationCentreX, 1, accessCentreZ),
	pavementColour,
	Enum.Material.Concrete
)

-- Simple white lane arrows on each approach.
makePart(markings, "BusStationWestArrow", Vector3.new(2, 0.12, 13), Vector3.new(westX, 1.08, accessCentreZ), white, Enum.Material.Neon)
makePart(markings, "BusStationEastArrow", Vector3.new(2, 0.12, 13), Vector3.new(eastX, 1.08, accessCentreZ), white, Enum.Material.Neon)

site.Transparency = 1
site.CanCollide = false

print("HopeSkin Avenue bus station blended into the road network")
