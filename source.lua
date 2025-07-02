--H Hello uWu

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()

local silentAimEnabled = true

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
	if silentAimEnabled then
		fovCircle.Position = Vector2.new(mouse.X + 1, mouse.Y + 36)
	end
end)

-- Knocked check (BodyEffects.K.O or Grabbed)
local function isKnocked(char)
	local bodyEffects = char:FindFirstChild("BodyEffects")
	if not bodyEffects then return false end

	local ko = bodyEffects:FindFirstChild("K.O")
	local grabbed = bodyEffects:FindFirstChild("Grabbed")

	return (ko and ko.Value) or (grabbed and grabbed.Value)
end

-- Wall check via raycast
local function hasLineOfSight(part)
	local origin = camera.CFrame.Position
	local direction = (part.Position - origin).Unit * 1000
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
	local ping = LocalPlayer:GetNetworkPing()
	return ping and ping / 1000 or 0.1
end

local currentTargetDot = nil

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
					if silentAimEnabled and onScreen and dist < fovCircle.Radius and dist < shortestDistance and hasLineOfSight(part) then
						closestPart = part
						shortestDistance = dist
					end
				end
			end
		end
	end

	if silentAimEnabled and closestPart then
		local adornee = closestPart.Parent:FindFirstChild("Head") or closestPart
		local indicator = Instance.new("BillboardGui")
		indicator.Name = "SilentIndicator"
		indicator.AlwaysOnTop = true
		indicator.Size = UDim2.new(0, 6, 0, 6)
		indicator.StudsOffset = Vector3.new(0, 2.5, 0)
		indicator.Adornee = adornee
		indicator.Parent = adornee

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

-- Metatable silent aim
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = function(t, k)
	if silentAimEnabled and t == mouse and (k == "Target" or k == "Hit") then
		local target = getClosestPart()
		if target then
			local ping = getPing()
			local predictedPos = target.Position + target.Velocity * ping
			local predictedCFrame = CFrame.new(predictedPos)
			if k == "Target" then return target end
			if k == "Hit" then return predictedCFrame end
		end
	end
	return oldIndex(t, k)
end

setreadonly(mt, true)

-- Toggle with F4
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.F4 and not gameProcessed then
		silentAimEnabled = not silentAimEnabled
		fovCircle.Visible = silentAimEnabled

		if not silentAimEnabled and currentTargetDot then
			currentTargetDot:Destroy()
			currentTargetDot = nil
		end
	end
end)
