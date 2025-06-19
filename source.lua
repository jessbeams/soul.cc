-- Roblox Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Get key from Pastebin
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

-- UI Setup
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "KeySystem"
local blur = Instance.new("BlurEffect", game.Lighting)
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
box.Text = ""
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

-- "Copied!" popup
local copiedText = Instance.new("TextLabel", frame)
copiedText.Size = UDim2.new(1, 0, 0, 20)
copiedText.Position = UDim2.new(0, 0, 1, -15)
copiedText.Text = "Copied to clipboard!"
copiedText.TextColor3 = Color3.fromRGB(0, 255, 0)
copiedText.Font = Enum.Font.Gotham
copiedText.TextSize = 14
copiedText.TextTransparency = 1
copiedText.BackgroundTransparency = 1

-- Button Logic
getKey.MouseButton1Click:Connect(function()
	setclipboard("https://pastebin.com/raw/xk1wzKjP")
	copiedText.TextTransparency = 0
	task.delay(2, function()
		copiedText.TextTransparency = 1
	end)
end)

submit.MouseButton1Click:Connect(function()
	if not correctKey then
		LocalPlayer:Kick("Failed to get key.")
	elseif box.Text == correctKey then
		gui:Destroy()
		blur:Destroy()

		-- Load silent aim and log to Discord
		local camera = workspace.CurrentCamera
		local mouse = LocalPlayer:GetMouse()
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
			local req = syn and syn.request or request or http_request
			if req then
				req({
					Url = webhook,
					Method = "POST",
					Headers = {["Content-Type"] = "application/json"},
					Body = HttpService:JSONEncode(data)
				})
			end
		end)

		local Drawing = Drawing
		local fovCircle = Drawing.new("Circle")
		fovCircle.Visible = true
		fovCircle.Filled = false
		fovCircle.Thickness = 2
		fovCircle.Radius = 120
		fovCircle.NumSides = 64
		fovCircle.Color = Color3.fromRGB(0, 255, 0)
		fovCircle.Transparency = 1

		game:GetService("RunService").RenderStepped:Connect(function()
			fovCircle.Position = Vector2.new(mouse.X + 1, mouse.Y + 36)
		end)

		local function isKnocked(char)
			local hum = char:FindFirstChildOfClass("Humanoid")
			local KO = char:FindFirstChild("K.O") or char:FindFirstChild("Knocked")
			if KO and KO:IsA("BoolValue") then return KO.Value end
			if hum and hum.Health <= 0 then return true end
			return false
		end

		local function hasLineOfSight(part)
			local origin = camera.CFrame.Position
			local direction = (part.Position - origin)
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			rayParams.IgnoreWater = true
			local result = workspace:Raycast(origin, direction, rayParams)
			if result and result.Instance then
				return part:IsDescendantOf(result.Instance:FindFirstAncestorOfClass("Model"))
			end
			return false
		end

		local function getClosestPart()
			local closestPart, shortestDistance = nil, math.huge
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character and not isKnocked(player.Character) then
					for _, part in ipairs(player.Character:GetChildren()) do
						if part:IsA("BasePart") then
							local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
							if onScreen then
								local dist = (Vector2.new(screenPos.X, screenPos.Y) - fovCircle.Position).Magnitude
								if dist < fovCircle.Radius and dist < shortestDistance and hasLineOfSight(part) then
									closestPart = part
									shortestDistance = dist
								end
							end
						end
					end
				end
			end
			return closestPart
		end

		local mt = getrawmetatable(game)
		local oldIndex = mt.__index
		setreadonly(mt, false)

		mt.__index = function(t, k)
			if t == mouse and (k == "Target" or k == "Hit") then
				if math.random() < 0.25 then -- 25% chance to aim (75% miss)
					local target = getClosestPart()
					if target then
						if k == "Target" then return target end
						if k == "Hit" then return target.CFrame end
					end
				end
				return nil
			end
			return oldIndex(t, k)
		end

		setreadonly(mt, true)
	else
		LocalPlayer:Kick("❌ Invalid key.")
	end
end)
