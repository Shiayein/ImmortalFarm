-- main.lua
-- ImmortalFarm — Logic only (NO UI here)
-- Keeps your original logic, removes legacy GUI, adds a tiny bridge for the external UI,
-- and auto-loads ui_mobile_example.lua (which itself uses source_gui_mobile.lua).

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Shared bridge (UI <-> Logic)
local IF = getgenv().IF or {}
getgenv().IF = IF
IF.SetGains = IF.SetGains or function() end -- will be set by the UI

-- State
local toolName = "Combat"
local autofarmOn = false
local hackPOVOn = false
local aimingATM = false
local isFarmingDHC = false
local currentRouteIndex = 0
local startCash = 0

-- Optional cleanup (same behavior as your file)
local function DeleteSeats()
	for _, seat in ipairs(workspace:GetDescendants()) do
		if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
			seat:Destroy()
		end
	end
end
pcall(DeleteSeats)

-- === Route (kept the same) ===
local route = {
	CFrame.new(583.81, 49.00, -276.92),
	CFrame.new(517.03, 48.00, -302.60),
	CFrame.new(577.56, 51.06, -468.30),
	CFrame.new(596.33, 51.06, -468.40),
	CFrame.new(94.64, 21.76, -521.39),
	CFrame.new(-219.89, 21.90, -787.59),
	CFrame.new(-401.05, 21.76, -589.96),
	CFrame.new(-252.39, 21.85, -409.80),
	CFrame.new(-450.92, 21.75, -332.39),
	CFrame.new(-477.04, 23.08, -291.44),
	CFrame.new(-476.88, 24.30, -283.40),
	CFrame.new(-476.42, 23.08, -275.40),
	CFrame.new(-621.39, 23.25, -288.20),
	CFrame.new(-630.13, 23.25, -282.76),
	CFrame.new(-796.76, 21.88, -657.81),
	CFrame.new(-856.37, 22.01, -660.45),
	CFrame.new(-939.68, 22.01, -663.71),
	CFrame.new(-939.39, 22.51, -656.50),
	CFrame.new(-806.90, 21.75, -287.09),
	CFrame.new(-951.59, 21.75, -164.95),
	CFrame.new(-941.35, 21.75, -165.24),
	CFrame.new(-870.75, 21.80, -87.96),
	CFrame.new(-861.74, 21.80, -87.96),
	CFrame.new(-611.79, 21.88 , 269.62),
	CFrame.new(-556.95, 21.88, 269.85),
	CFrame.new(-480.65, 21.86, -77.11),
	CFrame.new(-3.55, 21.76, -103.97),
}

-- Base helpers (same logic, no '+=')
local function getNextRoutePosition()
	currentRouteIndex = currentRouteIndex + 1
	if currentRouteIndex > #route then
		currentRouteIndex = 1
	end
	return route[currentRouteIndex]
end

local moneyDropName = "MoneyDrop"

local function getClosestDrop()
	local closest, minDist = nil, math.huge
	for _, obj in ipairs(workspace.Ignored.Drop:GetChildren()) do
		if obj:IsA("BasePart") and obj.Name == moneyDropName then
			local dist = (rootPart.Position - obj.Position).Magnitude
			if dist < 22 and dist < minDist then
				minDist = dist
				closest = obj
			end
		end
	end
	return closest
end

local function teleportAndClick(target)
	if target then
		rootPart.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
		local click = target:FindFirstChildOfClass("ClickDetector")
		if click then pcall(function() fireclickdetector(click) end) end
	end
end

local function punchUntilDHCDetected()
	local tool = backpack:FindFirstChild(toolName) or character:FindFirstChild(toolName)
	if tool and not tool.Parent:IsA("Model") then
		tool.Parent = character
		task.wait(0.1)
	end
	if not tool or not tool:IsA("Tool") then return end

	local detected = false
	local maxTries, tries = 30, 0
	while not detected and autofarmOn and tries < maxTries do
		tool:Activate(); task.wait(0.3)
		tool:Activate(); task.wait(0.4)
		if getClosestDrop() then detected = true end
		tries = tries + 1
	end
	tool.Parent = backpack
end

local function findClosestATM()
	local closest, minDist = nil, math.huge
	for _, obj in ipairs(workspace.Cashiers:GetChildren()) do
		if obj.Name == "CA$HIER" and (obj:IsA("BasePart") or obj:IsA("Model")) then
			local pos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position) or obj.Position
			local dist = (pos - rootPart.Position).Magnitude
			if dist < minDist then
				minDist = dist
				closest = obj
			end
		end
	end
	return closest
end

-- Look toward ATM once per second while waiting
local LOOK_INTERVAL, timeSinceLastLook = 1.0, 0
RunService.Heartbeat:Connect(function(dt)
	timeSinceLastLook = timeSinceLastLook + dt
	if timeSinceLastLook < LOOK_INTERVAL then return end
	timeSinceLastLook = 0

	if autofarmOn and aimingATM and not isFarmingDHC then
		local atm = findClosestATM()
		if atm then
			local targetPos = atm:IsA("Model")
				and (atm.PrimaryPart and atm.PrimaryPart.Position or atm:GetModelCFrame().Position)
				or atm.Position
			local dir = (targetPos - rootPart.Position).Unit
			local lookDir = Vector3.new(dir.X, 0, dir.Z)
			if (rootPart.CFrame.LookVector - lookDir).Magnitude > 0.02 then
				rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookDir)
			end
		end
	end
end)

-- Blur for POV
local Lighting = game:GetService("Lighting")
local blur = Instance.new("BlurEffect")
blur.Size = 20
blur.Enabled = false
blur.Parent = Lighting

-- ========= Public API (called by the UI) =========
if not IF.StartFarm then
	function IF.StartFarm(on)
		autofarmOn = on and true or false
		aimingATM = autofarmOn

		-- Init gains on start
		local dataFolder = player:FindFirstChild("DataFolder")
		if autofarmOn and dataFolder then
			for _, v in ipairs(dataFolder:GetChildren()) do
				if v:IsA("ValueBase") and v.Name:lower():find("curr") then
					startCash = v.Value
					pcall(function() IF.SetGains("0") end)
					break
				end
			end
		end

		-- Stop POV when stopping farm
		if (not autofarmOn) and IF.SetPOV then
			IF.SetPOV(false)
		end
	end
end

if not IF.SetPOV then
	function IF.SetPOV(on)
		if on and not autofarmOn then return end -- don't enable POV if farm is off
		hackPOVOn = on and true or false
		blur.Enabled = hackPOVOn

		local cam = workspace.CurrentCamera
		if hackPOVOn then
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = CFrame.new(100, 60, -500) * CFrame.Angles(0, math.rad(45), 0)
		else
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = character:FindFirstChildOfClass("Humanoid")
		end
	end
end

-- Gains watcher -> notify UI
task.spawn(function()
	local dataFolder = player:WaitForChild("DataFolder", 5)
	if not dataFolder then return end
	for _, v in ipairs(dataFolder:GetChildren()) do
		if v:IsA("ValueBase") and v.Name:lower():find("curr") then
			v.Changed:Connect(function()
				local gain = v.Value - (startCash or 0)
				pcall(function() IF.SetGains(tostring(gain)) end)
			end)
		end
	end
end)

-- ========= Main farm loop (unchanged) =========
task.spawn(function()
	while true do
		if autofarmOn then
			local targetPos = getNextRoutePosition()
			rootPart.CFrame = targetPos
			task.wait(0.5)

			punchUntilDHCDetected()

			local noDropTime = 0
			while noDropTime < 1 do
				local drop = getClosestDrop()
				if drop then
					isFarmingDHC = true
					aimingATM = false
					teleportAndClick(drop)
					task.wait(0.5)
					noDropTime = 0
				else
					task.wait(0.5)
					noDropTime = noDropTime + 0.5
				end
			end

			isFarmingDHC = false
			aimingATM = true
		end
		task.wait(0.5)
	end
end)

-- ========= Auto-load the external UI (kept separate) =========
pcall(function()
	-- UI uses source_gui_mobile.lua internally; both stay separate, just linked.
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Shiayein/ImmortalFarm/main/ui_mobile_example.lua"))()
end)
