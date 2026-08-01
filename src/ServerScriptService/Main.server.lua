local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local existing = Workspace:FindFirstChild("HopeSkinIsland")
if existing then
	existing:Destroy()
end

local island = Instance.new("Model")
island.Name = "HopeSkinIsland"
island.Parent = Workspace

local folders = {}
for _, name in ipairs({"Ground", "Roads", "Pavements", "Plots", "Markings", "ReservedAreas"}) do
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = island
	folders[name] = folder
end

local function part(parent, name, size, position, color, material, height)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	if height then
		p.Position = Vector3.new(position.X, height, position.Z)
	end
	return p
end

local grassColor = Color3.fromRGB(78, 146, 73)
local roadColor = Color3.fromRGB(48, 51, 56)
local pavementColor = Color3.fromRGB(158, 158, 158)
local lineColor = Color3.fromRGB(245, 221, 64)
local white = Color3.fromRGB(235, 235, 235)
local plotColor = Color3.fromRGB(104, 176, 94)

-- Large 1,200 x 1,200 stud island base.
part(folders.Ground, "IslandBase", Vector3.new(1200, 8, 1200), Vector3.new(0, -4, 0), grassColor, Enum.Material.Grass)

-- Main road grid: two major avenues and four cross streets.
local roads = {
	{name = "HopeSkinAvenue", size = Vector3.new(52, 1, 1100), pos = Vector3.new(0, 0.5, 0)},
	{name = "CentralBoulevard", size = Vector3.new(1100, 1, 52), pos = Vector3.new(0, 0.5, 0)},
	{name = "WestRoad", size = Vector3.new(38, 1, 1100), pos = Vector3.new(-360, 0.5, 0)},
	{name = "EastRoad", size = Vector3.new(38, 1, 1100), pos = Vector3.new(360, 0.5, 0)},
	{name = "NorthStreet", size = Vector3.new(1100, 1, 38), pos = Vector3.new(0, 0.5, -340)},
	{name = "SouthStreet", size = Vector3.new(1100, 1, 38), pos = Vector3.new(0, 0.5, 340)},
}

for _, road in ipairs(roads) do
	part(folders.Roads, road.name, road.size, road.pos, roadColor, Enum.Material.Asphalt)
end

-- Pavements run along both sides of every road.
local function addVerticalPavements(x, width, length, label)
	local offset = width / 2 + 8
	part(folders.Pavements, label .. "LeftPavement", Vector3.new(14, 1, length), Vector3.new(x - offset, 1, 0), pavementColor, Enum.Material.Concrete)
	part(folders.Pavements, label .. "RightPavement", Vector3.new(14, 1, length), Vector3.new(x + offset, 1, 0), pavementColor, Enum.Material.Concrete)
end

local function addHorizontalPavements(z, width, length, label)
	local offset = width / 2 + 8
	part(folders.Pavements, label .. "TopPavement", Vector3.new(length, 1, 14), Vector3.new(0, 1, z - offset), pavementColor, Enum.Material.Concrete)
	part(folders.Pavements, label .. "BottomPavement", Vector3.new(length, 1, 14), Vector3.new(0, 1, z + offset), pavementColor, Enum.Material.Concrete)
end

addVerticalPavements(0, 52, 1100, "HopeSkin")
addVerticalPavements(-360, 38, 1100, "West")
addVerticalPavements(360, 38, 1100, "East")
addHorizontalPavements(0, 52, 1100, "Central")
addHorizontalPavements(-340, 38, 1100, "North")
addHorizontalPavements(340, 38, 1100, "South")

-- Centre lines for the wider roads.
for z = -520, 520, 32 do
	part(folders.Markings, "AvenueLine", Vector3.new(1, 0.15, 16), Vector3.new(0, 1.08, z), lineColor, Enum.Material.Neon)
end
for x = -520, 520, 32 do
	part(folders.Markings, "BoulevardLine", Vector3.new(16, 0.15, 1), Vector3.new(x, 1.08, 0), lineColor, Enum.Material.Neon)
end

-- Zebra crossings around the central junction.
for i = -4, 4 do
	part(folders.Markings, "CrossingNorth", Vector3.new(3, 0.12, 14), Vector3.new(i * 6, 1.12, -42), white, Enum.Material.Neon)
	part(folders.Markings, "CrossingSouth", Vector3.new(3, 0.12, 14), Vector3.new(i * 6, 1.12, 42), white, Enum.Material.Neon)
	part(folders.Markings, "CrossingWest", Vector3.new(14, 0.12, 3), Vector3.new(-42, 1.12, i * 6), white, Enum.Material.Neon)
	part(folders.Markings, "CrossingEast", Vector3.new(14, 0.12, 3), Vector3.new(42, 1.12, i * 6), white, Enum.Material.Neon)
end

-- Large empty plots for prebuilt houses, shops and public buildings.
local plotData = {
	{-185, -180, 260, 250, "NorthWestHousing"},
	{185, -180, 260, 250, "NorthEastHousing"},
	{-185, 180, 260, 250, "SouthWestHousing"},
	{185, 180, 260, 250, "SouthEastHousing"},
	{-470, -170, 150, 280, "WestRetail"},
	{470, -170, 150, 280, "EastRetail"},
	{-470, 200, 150, 220, "WestCommunity"},
	{470, 200, 150, 220, "EastCommunity"},
	{-180, -470, 260, 150, "NorthExpansionWest"},
	{180, -470, 260, 150, "NorthExpansionEast"},
	{-180, 470, 260, 150, "SouthExpansionWest"},
	{180, 470, 260, 150, "SouthExpansionEast"},
}

for _, data in ipairs(plotData) do
	local plot = part(
		folders.Plots,
		data[5],
		Vector3.new(data[3], 0.6, data[4]),
		Vector3.new(data[1], 0.3, data[2]),
		plotColor,
		Enum.Material.Grass
	)
	plot:SetAttribute("ReservedForBuilding", true)
end

-- Reserved transport areas with enough room for imported models later.
local busStation = part(folders.ReservedAreas, "BusStationSite", Vector3.new(240, 0.8, 130), Vector3.new(-210, 0.4, 500), Color3.fromRGB(115, 115, 115), Enum.Material.Concrete)
busStation:SetAttribute("Purpose", "Bus Station")

local townCentre = part(folders.ReservedAreas, "TownCentreSite", Vector3.new(240, 0.8, 170), Vector3.new(210, 0.4, 500), Color3.fromRGB(125, 125, 125), Enum.Material.Concrete)
townCentre:SetAttribute("Purpose", "Town Centre / Shops")

local spawn = Instance.new("SpawnLocation")
spawn.Name = "TownSpawn"
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(-55, 2, 70)
spawn.Anchored = true
spawn.Neutral = true
spawn.Material = Enum.Material.Concrete
spawn.Color = Color3.fromRGB(85, 170, 255)
spawn.Parent = island

Lighting.ClockTime = 13.5
Lighting.Brightness = 2.5
Lighting.Ambient = Color3.fromRGB(140, 140, 140)
Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)

print("HopeSkin Avenue island generated")
