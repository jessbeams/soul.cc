-- Only allow in Da Hood
if game.PlaceId ~= 2788229376 then
    game:GetService("Players").LocalPlayer:Kick("This game is not supported.")
    return
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = localPlayer:GetMouse()

-- CONFIG
local FOV_RADIUS = 120

-- Draw FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Filled = false
fovCircle.Thickness = 2
fovCircle.Radius = FOV_RADIUS
fovCircle.NumSides = 64
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Transparency = 1

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(mouse.X + 1, mouse.Y + 36)
end)

-- Knocked check
local function isKnocked(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local KO = char:FindFirstChild("K.O") or char:FindFirstChild("Knocked")
    if KO and KO:IsA("BoolValue") then
        return KO.Value == true
    end
    if hum and hum.Health <= 0 then
        return true
    end
    return false
end

-- Line-of-sight check
local function hasLineOfSight(part)
    local origin = camera.CFrame.Position
    local direction = (part.Position - origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {localPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, rayParams)
    if result and result.Instance then
        return part:IsDescendantOf(result.Instance:FindFirstAncestorOfClass("Model"))
    end
    return false
end

-- Get closest body part to mouse within FOV
local function getClosestPart()
    local closestPart = nil
    local closestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local char = player.Character
            if not isKnocked(char) then
                for _, part in ipairs(char:GetChildren()) do
                    if part:IsA("BasePart") then
                        local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - fovCircle.Position).Magnitude
                            if dist < FOV_RADIUS and dist < closestDist and hasLineOfSight(part) then
                                closestPart = part
                                closestDist = dist
                            end
                        end
                    end
                end
            end
        end
    end

    return closestPart
end

-- Mouse override (silent aim)
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = function(t, k)
    if t == mouse and (k == "Target" or k == "Hit") then
        local target = getClosestPart()
        if target then
            if k == "Target" then
                return target
            elseif k == "Hit" then
                return target.CFrame
            end
        end
    end
    return oldIndex(t, k)
end

setreadonly(mt, true)
