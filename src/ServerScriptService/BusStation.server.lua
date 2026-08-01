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

for _, name in ipairs({"BusStationAccessRoad", "BusStationAccessLeftPavement", "BusStationAccessRightPavement"}) do
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

-- Centre the imported station over its reserved area first.
local boxCFrame = station:GetBoundingBox()
local horizontalMove = Vector3.new(
	site.Position.X - boxCFrame.Position.X,
	0,
	site.Position.Z - boxCFrame.Position.Z
)
station:PivotTo(CFrame.new(horizontalMove) * station:GetPivot())

-- The model has hidden geometry below the usable roadway, so its bounding box
-- cannot be used for height. The large part named Base is the station roadway.
-- Align the TOP of that exact part with the top of the town roads (Y = 1).
local stationBase = station:FindFirstChild("Base", true)
if not stationBase or not stationBase:IsA("BasePart") then
	error("Bus station model is missing its roadway part named Base")
end

local roadSurfaceY = 1
local baseTopY = stationBase.Position.Y + stationBase.Size.Y / 2
local verticalMove = Vector3.new(0, roadSurfaceY - baseTopY, 0)
station:PivotTo(CFrame.new(verticalMove) * station:GetPivot())

-- Connect South Street to the actual front edge of the imported station.
local finalBoxCFrame, finalBoxSize = station:GetBoundingBox()
local stationFrontZ = finalBoxCFrame.Position.Z - finalBoxSize.Z / 2
local southStreetZ = 340
local accessLength = math.max(8, stationFrontZ - southStreetZ)
local accessCentreZ = southStreetZ + accessLength / 2
local accessX = finalBoxCFrame.Position.X

makePart(
	roads,
	"BusStationAccessRoad",
	Vector3.new(46, 1, accessLength + 4),
	Vector3.new(accessX, 0.5, accessCentreZ),
	Color3.fromRGB(48, 51, 56),
	Enum.Material.Asphalt
)

makePart(
	pavements,
	"BusStationAccessLeftPavement",
	Vector3.new(12, 1, accessLength + 4),
	Vector3.new(accessX - 29, 1, accessCentreZ),
	Color3.fromRGB(158, 158, 158),
	Enum.Material.Concrete
)

makePart(
	pavements,
	"BusStationAccessRightPavement",
	Vector3.new(12, 1, accessLength + 4),
	Vector3.new(accessX + 29, 1, accessCentreZ),
	Color3.fromRGB(158, 158, 158),
	Enum.Material.Concrete
)

site.Transparency = 1
site.CanCollide = false

print("HopeSkin Avenue bus station aligned by its true road surface")
