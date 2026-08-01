local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local island = Workspace:WaitForChild("HopeSkinIsland")
local reservedAreas = island:WaitForChild("ReservedAreas")
local roads = island:WaitForChild("Roads")
local pavements = island:WaitForChild("Pavements")
local site = reservedAreas:WaitForChild("BusStationSite")
local template = ServerStorage:WaitForChild("BusStation")

local existing = island:FindFirstChild("BusStation")
if existing then
	existing:Destroy()
end

-- Remove every road/pavement piece created by earlier bus-station layouts.
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
	"BusStationLeftConnector",
	"BusStationRightConnector",
	"WestRightPavementNorth",
	"WestRightPavementSouth",
	"HopeSkinLeftPavementNorth",
	"HopeSkinLeftPavementSouth",
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

-- Centre the station between West Road and HopeSkin Avenue.
local boxCFrame = station:GetBoundingBox()
station:PivotTo(
	CFrame.new(
		site.Position.X - boxCFrame.Position.X,
		0,
		site.Position.Z - boxCFrame.Position.Z
	) * station:GetPivot()
)

-- Align the actual bus-station roadway with the town road surface.
local stationBase = station:FindFirstChild("Base", true)
if not stationBase or not stationBase:IsA("BasePart") then
	error("Bus station model is missing its roadway part named Base")
end

local roadSurfaceY = 1
local baseTopY = stationBase.Position.Y + stationBase.Size.Y / 2
station:PivotTo(CFrame.new(0, roadSurfaceY - baseTopY, 0) * station:GetPivot())

local roadColour = Color3.fromRGB(48, 51, 56)
local pavementColour = Color3.fromRGB(158, 158, 158)

-- The two existing through-roads on either side of the station.
local leftRoadX = -360
local rightRoadX = 0
local leftRoadWidth = 38
local rightRoadWidth = 52

-- Put the connectors beside the station's own left/right exit arrows.
-- This is toward the front half of the station, not across its main frontage.
local connectorZ = stationBase.Position.Z - stationBase.Size.Z * 0.27
local connectorWidth = 44
local stationLeftEdge = stationBase.Position.X - stationBase.Size.X / 2
local stationRightEdge = stationBase.Position.X + stationBase.Size.X / 2
local leftRoadRightEdge = leftRoadX + leftRoadWidth / 2
local rightRoadLeftEdge = rightRoadX - rightRoadWidth / 2

local leftStartX = leftRoadRightEdge - 3
local leftEndX = stationLeftEdge + 5
local leftLength = math.max(8, leftEndX - leftStartX)
makePart(
	roads,
	"BusStationLeftConnector",
	Vector3.new(leftLength, 1, connectorWidth),
	Vector3.new((leftStartX + leftEndX) / 2, 0.5, connectorZ),
	roadColour,
	Enum.Material.Asphalt
)

local rightStartX = stationRightEdge - 5
local rightEndX = rightRoadLeftEdge + 3
local rightLength = math.max(8, rightEndX - rightStartX)
makePart(
	roads,
	"BusStationRightConnector",
	Vector3.new(rightLength, 1, connectorWidth),
	Vector3.new((rightStartX + rightEndX) / 2, 0.5, connectorZ),
	roadColour,
	Enum.Material.Asphalt
)

-- The original pavements were single 1,100-stud strips. Remove the two strips
-- that sit between the station and the roads, then rebuild them with a proper
-- gap so buses never have to climb over light-grey pavement.
local westInnerPavement = pavements:FindFirstChild("WestRightPavement")
if westInnerPavement then
	westInnerPavement:Destroy()
end

local hopeSkinInnerPavement = pavements:FindFirstChild("HopeSkinLeftPavement")
if hopeSkinInnerPavement then
	hopeSkinInnerPavement:Destroy()
end

local pavementMinZ = -550
local pavementMaxZ = 550
local gapPadding = 5
local gapStart = connectorZ - connectorWidth / 2 - gapPadding
local gapEnd = connectorZ + connectorWidth / 2 + gapPadding

local function makeVerticalPavementSegments(x, prefix)
	local southLength = gapStart - pavementMinZ
	if southLength > 0 then
		makePart(
			pavements,
			prefix .. "South",
			Vector3.new(14, 1, southLength),
			Vector3.new(x, 1, pavementMinZ + southLength / 2),
			pavementColour,
			Enum.Material.Concrete
		)
	end

	local northLength = pavementMaxZ - gapEnd
	if northLength > 0 then
		makePart(
			pavements,
			prefix .. "North",
			Vector3.new(14, 1, northLength),
			Vector3.new(x, 1, gapEnd + northLength / 2),
			pavementColour,
			Enum.Material.Concrete
		)
	end
end

-- These x positions match the original pavement generator in Main.server.lua.
makeVerticalPavementSegments(-333, "WestRightPavement")
makeVerticalPavementSegments(-34, "HopeSkinLeftPavement")

site.Transparency = 1
site.CanCollide = false

print("HopeSkin Avenue bus station connected directly to both side roads")
