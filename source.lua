-- Pre-setup
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()

-- === UI Key System ===
local correctKey = nil
pcall(function()
	local req = syn and syn.request or http_request or request
	if req then
		local res = req({
			Url = "https://pastebin.com/raw/xk1wzKjP",
			Method = "GET"
		})
		correctKey = res.Body and res.Body:gsub("\n", "")
	end
end)

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "KeySystem"
local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 10

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 400, 0, 230)
frame.Position = UDim2.new(0.5, -200, 0.5, -115)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "🔐 Welcome to Soul.cc"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.BackgroundTransparency = 1

local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(0.85, 0, 0, 35)
box.Position = UDim2.new(0.075, 0, 0.35, 0)
box.PlaceholderText = "Enter your key here..."
box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.Gotham
box.TextSize = 16
box.BorderSizePixel = 0
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

local submit = Instance.new("TextButton", frame)
submit.Size = UDim2.new(0.4, 0, 0, 35)
submit.Position = UDim2.new(0.3, 0, 0.6, 0)
submit.Text = "✅ Submit"
submit.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
submit.TextColor3 = Color3.new(1,1,1)
submit.Font = Enum.Font.GothamBold
submit.TextSize = 16
submit.BorderSizePixel = 0
Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 8)

local getKey = Instance.new("TextButton", frame)
getKey.Size = UDim2.new(0.85, 0, 0, 30)
getKey.Position = UDim2.new(0.075, 0, 0.82, 0)
getKey.Text = "🔑 Get Key"
getKey.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
getKey.TextColor3 = Color3.new(1,1,1)
getKey.Font = Enum.Font.Gotham
getKey.TextSize = 14
getKey.BorderSizePixel = 0
Instance.new("UICorner", getKey).CornerRadius = UDim.new(0, 6)

getKey.MouseButton1Click:Connect(function()
	setclipboard("https://pastebin.com/raw/xk1wzKjP")
end)

submit.MouseButton1Click:Connect(function()
	if not correctKey then
		LocalPlayer:Kick("Failed to get key.")
	elseif box.Text == correctKey then
		gui:Destroy()
		blur:Destroy()

		-- Logging
		local webhook = "https://discord.com/api/webhooks/1385113796963598356/px_zeWfFa2yDChxhrX1t1KR-yLy6_253oVRu0NAxNm8MifIs6WZK6WuRe2qGaN1nfpow"
		local executor = identifyexecutor and identifyexecutor() or "Unknown"
		local hwid = (syn and syn.gethwid and syn.gethwid()) or (gethwid and gethwid()) or "Unavailable"

		pcall(function()
			local data = {
				["embeds"] = {{
					["title"] = "💻 soul.cc executed",
					["color"] = 65280,
					["fields"] = {
						{["name"] = "User", ["value"] = LocalPlayer.Name, ["inline"] = true},
						{["name"] = "Executor", ["value"] = executor, ["inline"] = true},
						{["name"] = "HWID", ["value"] = "```" .. hwid .. "```", ["inline"] = false}
					}
				}}
			}
			local req = request or http_request or syn and syn.request
			if req then
				req({
					Url = webhook,
					Method = "POST",
					Headers = {["Content-Type"] = "application/json"},
					Body = HttpService:JSONEncode(data)
				})
			end
		end)

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
			local ping = LocalPlayer:GetNetworkPing()
			return ping and ping / 1000 or 0.1
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

			-- Add green dot indicator if a part is found
			if closestPart then
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

	else
		LocalPlayer:Kick("❌ Invalid key.")
	end
end)
