local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local island = Workspace:WaitForChild("HopeSkinIsland")
local reservedAreas = island:WaitForChild("ReservedAreas")
local site = reservedAreas:WaitForChild("BusStationSite")
local template = ServerStorage:WaitForChild("BusStation")

local existing = island:FindFirstChild("BusStation")
if existing then
	existing:Destroy()
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

local siteTop = site.Position.Y + site.Size.Y / 2
local boxCFrame, boxSize = station:GetBoundingBox()
local currentBottom = boxCFrame.Position.Y - boxSize.Y / 2
local target = Vector3.new(site.Position.X, siteTop - currentBottom, site.Position.Z)
station:PivotTo(CFrame.new(target) * station:GetPivot())

site.Transparency = 1
site.CanCollide = false

print("HopeSkin Avenue bus station loaded")
