local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

-- CONFIG
local FOV_RADIUS = 80
local aimlockKey = Enum.KeyCode.C
local aimlockColor = Color3.fromRGB(255, 0, 0)

local aimlockEnabled = false
local currentTarget = nil

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Radius = FOV_RADIUS
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Color = aimlockColor
fovCircle.Transparency = 1

-- Billboard UI Setup
local billboardGui = Instance.new("BillboardGui")
billboardGui.Size = UDim2.new(0, 200, 0, 70)
billboardGui.StudsOffset = Vector3.new(0, 3, 0)
billboardGui.AlwaysOnTop = true
billboardGui.Name = "AimlockUI"

local avatarImage = Instance.new("ImageLabel", billboardGui)
avatarImage.Position = UDim2.new(0, 0, 0, 0)
avatarImage.Size = UDim2.new(0, 60, 0, 60)
avatarImage.BackgroundTransparency = 1

local nameLabel = Instance.new("TextLabel", billboardGui)
nameLabel.Position = UDim2.new(0, 65, 0, 0)
nameLabel.Size = UDim2.new(0, 135, 0, 30)
nameLabel.BackgroundTransparency = 1
nameLabel.TextScaled = true
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

local healthLabel = Instance.new("TextLabel", billboardGui)
healthLabel.Position = UDim2.new(0, 65, 0, 50)
healthLabel.Size = UDim2.new(0, 135, 0, 20)
healthLabel.BackgroundTransparency = 1
healthLabel.TextScaled = true
healthLabel.Font = Enum.Font.Gotham
healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Health Bar Setup
local healthBarBackground = Instance.new("Frame", billboardGui)
healthBarBackground.Position = UDim2.new(0, 65, 0, 35)
healthBarBackground.Size = UDim2.new(0, 130, 0, 10)
healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
healthBarBackground.BorderSizePixel = 0

local healthBar = Instance.new("Frame", healthBarBackground)
healthBar.Size = UDim2.new(1, 0, 1, 0)
healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
healthBar.BorderSizePixel = 0

-- Update FOV Circle to follow mouse
RunService.RenderStepped:Connect(function()
	fovCircle.Position = Vector2.new(mouse.X + 1, mouse.Y + 36)
end)

-- Check if a character is knocked
local function isKnocked(character)
	local ko = character:FindFirstChild("K.O") or character:FindFirstChild("Knocked")
	return ko and ko:IsA("BoolValue") and ko.Value == true
end

-- Line-of-sight raycast check
local function hasLineOfSight(targetPart)
	local origin = camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {localPlayer.Character}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.IgnoreWater = true

	local result = Workspace:Raycast(origin, direction, rayParams)
	if result and result.Instance then
		return targetPart:IsDescendantOf(result.Instance:FindFirstAncestorOfClass("Model"))
	end
	return false
end

-- Find closest valid target within FOV and not knocked
local function getClosestTarget()
	local closestDistance = math.huge
	local target = nil

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
			local character = player.Character
			local head = character.Head

			if not isKnocked(character) then
				local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
				if onScreen then
					local distance = (Vector2.new(screenPos.X, screenPos.Y) - fovCircle.Position).Magnitude
					if distance < FOV_RADIUS and distance < closestDistance and hasLineOfSight(head) then
						closestDistance = distance
						target = head
					end
				end
			end
		end
	end

	return target
end

-- Toggle aimlock key
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == aimlockKey then
		aimlockEnabled = not aimlockEnabled
		print(aimlockEnabled and "Aimlock enabled" or "Aimlock disabled")

		if not aimlockEnabled then
			currentTarget = nil
			billboardGui.Parent = nil
		end
	end
end)

-- Main RenderStepped loop for aimlock behavior
RunService.RenderStepped:Connect(function()
	if aimlockEnabled then
		if not currentTarget or not currentTarget:IsDescendantOf(Workspace) then
			currentTarget = getClosestTarget()
		end

		if currentTarget then
			local character = currentTarget:FindFirstAncestorOfClass("Model")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if character and humanoid and not isKnocked(character) and humanoid.Health > 0 then
				-- Lock camera to target
				camera.CFrame = CFrame.new(camera.CFrame.Position, currentTarget.Position)

				-- UI Display
				if not billboardGui.Parent then
					billboardGui.Parent = currentTarget
				end

				local player = Players:GetPlayerFromCharacter(character)
				if player then
					nameLabel.Text = player.DisplayName
					avatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
				end

				local healthRatio = humanoid.Health / humanoid.MaxHealth
				healthBar.Size = UDim2.new(math.clamp(healthRatio, 0, 1), 0, 1, 0)

				if healthRatio > 0.6 then
					healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
				elseif healthRatio > 0.3 then
					healthBar.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
				else
					healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
				end

				healthLabel.Text = "Health: " .. math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
			else
				-- Target knocked or dead, stop aimlock
				currentTarget = nil
				billboardGui.Parent = nil
			end
		else
			-- No target in range
			billboardGui.Parent = nil
		end
	end
end)
