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

-- Connect the station directly to South Street so buses can enter and leave.
local accessX = site.Position.X
local southStreetZ = 340
local stationEntranceZ = site.Position.Z - site.Size.Z / 2
local accessLength = stationEntranceZ - southStreetZ
local accessCentreZ = southStreetZ + accessLength / 2

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

-- The imported model contains geometry below its visible floor. Lowering the
-- bounding-box bottom by 3.5 studs puts the usable station roads at street level.
local boxCFrame, boxSize = station:GetBoundingBox()
local currentBottom = boxCFrame.Position.Y - boxSize.Y / 2
local desiredBottom = -2.7
local movement = Vector3.new(
	site.Position.X - boxCFrame.Position.X,
	desiredBottom - currentBottom,
	site.Position.Z - boxCFrame.Position.Z
)
station:PivotTo(CFrame.new(movement) * station:GetPivot())

site.Transparency = 1
site.CanCollide = false

print("HopeSkin Avenue bus station grounded with vehicle access")
