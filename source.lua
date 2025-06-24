-- Version Check
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()

-- YOUR local version string
local localVersion = "Version.101"

-- Function to fetch the remote version
local function checkVersion()
	local success, response = pcall(function()
		return game:HttpGet("https://raw.githubusercontent.com/jessbeams/soul.cc/refs/heads/main/source.lua")
	end)

	if success and response then
		local remoteVersion = string.match(response, "Version%.[%d]+")
		if remoteVersion and remoteVersion ~= localVersion then
			LocalPlayer:Kick("🚫 Wait for new version.\n(Current: " .. localVersion .. " | Remote: " .. remoteVersion .. ")")
		elseif not remoteVersion then
			LocalPlayer:Kick("🚫 Version tag missing in remote script.")
		end
	else
		LocalPlayer:Kick("🚫 Failed to check version.")
	end
end

checkVersion()

-- === Silent Aim Core ===

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Filled = false
fovCircle.Thickness = 2
fovCircle.Radius = 120
fovCircle.NumSides = 64
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Transparency = 1

RunService.RenderStepped:Connect(function()
	fovCircle.Position = Vector2.new(mouse.X + 1, mouse.Y + 36)
end)

-- Silent Aim
local currentTargetDot = nil

local function isKnocked(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	local KO = char:FindFirstChild("K.O") or char:FindFirstChild("Knocked")
	if KO and KO:IsA("BoolValue") then return KO.Value end
	if hum and hum.Health <= 0 then return true end
	return false
end

local function hasLineOfSight(part)
	local origin = camera.CFrame.Position
	local direction = (part.Position - origin).Unit * 999
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.IgnoreWater = true
	local result = Workspace:Raycast(origin, direction, rayParams)
	if result then
		return part:IsDescendantOf(result.Instance:FindFirstAncestorOfClass("Model"))
	end
	return true
end

local function getPing()
	return 0.1 -- SWIFT: use average ping
end

local function shouldHit()
	return math.random() <= 0.7
end

local function getClosestPart()
	local closestPart, shortestDistance = nil, math.huge

	if currentTargetDot then
		currentTargetDot:Destroy()
		currentTargetDot = nil
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and not isKnocked(player.Character) then
			for _, part in ipairs(player.Character:GetChildren()) do
				if part:IsA("BasePart") then
					local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - fovCircle.Position).Magnitude
					if onScreen and dist < fovCircle.Radius and dist < shortestDistance and hasLineOfSight(part) then
						closestPart = part
						shortestDistance = dist
					end
				end
			end
		end
	end

	-- Green Dot Indicator
	if closestPart then
		local adornee = closestPart.Parent:FindFirstChild("Head") or closestPart
		local indicator = Instance.new("BillboardGui")
		indicator.Name = "SilentIndicator"
		indicator.AlwaysOnTop = true
		indicator.Size = UDim2.new(0, 6, 0, 6)
		indicator.StudsOffset = Vector3.new(0, 2.5, 0)
		indicator.Adornee = adornee:FindFirstAncestorOfClass("Model") or adornee
		indicator.Parent = adornee:FindFirstAncestorOfClass("Model") or adornee

		local dot = Instance.new("Frame", indicator)
		dot.Size = UDim2.new(1, 0, 1, 0)
		dot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		dot.BorderSizePixel = 0
		dot.BackgroundTransparency = 0
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

		currentTargetDot = indicator
	end

	return closestPart
end

-- Metatable override
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = function(t, k)
	if t == mouse and (k == "Target" or k == "Hit") then
		if shouldHit() then
			local target = getClosestPart()
			if target then
				local ping = getPing()
				local predictedPos = target.Position + target.Velocity * ping
				local predictedCFrame = CFrame.new(predictedPos)
				if k == "Target" then return target end
				if k == "Hit" then return predictedCFrame end
			end
		end
	end
	return oldIndex(t, k)
end

setreadonly(mt, true)
