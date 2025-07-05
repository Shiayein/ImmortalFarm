-- ✅ Version optimisée du script complet avec même fonctionnalités
-- • Moins de freeze
-- • Moins de GetDescendants()
-- • Tick centralisé via Heartbeat
-- • Tous les éléments de GUI et logique conservés

-- === Protection chargement ===
if not _G.VerificationPassed then
    error("Main.lua doit être lancé via verification.lua")
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local toolName = "Combat"
local autofarmOn, hackPOVOn, aimingATM, isFarmingDHC = false, false, false, false
local startCash, currentRouteIndex = 0, 0

local route = { -- inchangé
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
}

local function getNextRoutePosition()
    currentRouteIndex += 1
    if currentRouteIndex > #route then currentRouteIndex = 1 end
    return route[currentRouteIndex]
end

-- === Caching des MoneyDrop & ATM ===
local moneyDrops, atms = {}, {}
local function scan(obj)
    if obj:IsA("BasePart") and obj.Name == "MoneyDrop" then moneyDrops[obj] = true end
    if obj.Name == "CA$HIER" then atms[obj] = true end
end
workspace.DescendantAdded:Connect(scan)
workspace.DescendantRemoving:Connect(function(o)
    moneyDrops[o], atms[o] = nil, nil
end)
for _,v in ipairs(workspace:GetDescendants()) do scan(v) end

-- === Fonctions de ciblage rapide ===
local function nearest(tbl, maxDist)
    local best, dist = nil, maxDist or math.huge
    for part in pairs(tbl) do
        if part:IsDescendantOf(workspace) and part:IsA("BasePart") then
            local d = (part.Position - rootPart.Position).Magnitude
            if d < dist then best, dist = part, d end
        end
    end
    return best
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
    if tool then tool.Parent = character wait(0.1) end
    if not tool or not tool:IsA("Tool") then return end

    for _ = 1, 30 do
        if not autofarmOn or nearest(moneyDrops, 22) then break end
        tool:Activate() wait(0.4) tool:Activate() wait(0.2)
    end
    tool.Parent = backpack
end

-- === UI ===
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local panel = Instance.new("Frame", gui)
panel.Size = UDim2.new(0, 220, 0, 140)
panel.Position = UDim2.new(0, -200, 0.1, 0)
panel.BackgroundColor3 = Color3.fromRGB(30,30,30)
panel.BorderSizePixel = 0

local toggleBtn = Instance.new("TextButton", panel)
toggleBtn.Size = UDim2.new(0, 30, 0, 60)
toggleBtn.Position = UDim2.new(1, 0, 0.5, -30)
toggleBtn.Text = "▶"
toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.SourceSansBold

toggleBtn.TextSize = 25
local panelOpen = false
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function togglePanel()
    local newPos = panelOpen and UDim2.new(0, -200, 0.1, 0) or UDim2.new(0, 0, 0.1, 0)
    TweenService:Create(panel, tweenInfo, {Position = newPos}):Play()
    toggleBtn.Text = panelOpen and "▶" or "◀"
    panelOpen = not panelOpen
end

toggleBtn.MouseButton1Click:Connect(togglePanel)

-- === Boutons ===
local farmBtn = Instance.new("TextButton", panel)
farmBtn.Size = UDim2.new(0, 180, 0, 40)
farmBtn.Position = UDim2.new(0, 20, 0, 20)
farmBtn.Text = "Immortal Farm"
farmBtn.Font = Enum.Font.SourceSansBold
farmBtn.TextSize = 22
farmBtn.BackgroundColor3 = Color3.fromRGB(15, 80, 15)
farmBtn.TextColor3 = Color3.new(1,1,1)

local counterLabel = Instance.new("TextLabel", panel)
counterLabel.Size = UDim2.new(0, 180, 0, 30)
counterLabel.Position = UDim2.new(0, 20, 0, 70)
counterLabel.BackgroundTransparency = 1
counterLabel.TextColor3 = Color3.fromRGB(255, 210, 50)
counterLabel.Font = Enum.Font.SourceSansBold
counterLabel.TextSize = 20
counterLabel.Visible = false

local hackBtn = Instance.new("TextButton", panel)
hackBtn.Size = UDim2.new(0, 180, 0, 40)
hackBtn.Position = UDim2.new(0, 20, 0, 105)
hackBtn.Text = "Hack POV"
hackBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
hackBtn.TextColor3 = Color3.new(1,1,1)
hackBtn.Font = Enum.Font.SourceSansBold
hackBtn.TextSize = 22

local blur = Instance.new("BlurEffect")
blur.Size = 20
blur.Enabled = false
blur.Parent = Lighting

farmBtn.MouseButton1Click:Connect(function()
    autofarmOn = not autofarmOn
    aimingATM = autofarmOn
    farmBtn.BackgroundColor3 = autofarmOn and Color3.fromRGB(180, 30, 30) or Color3.fromRGB(15, 80, 15)
    counterLabel.Visible = autofarmOn

    if not autofarmOn and hackPOVOn then
        hackPOVOn = false
        hackBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        workspace.CurrentCamera.BlurEffect.Enabled = false
        workspace.CurrentCamera.CameraSubject = character.Humanoid
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end
end)

hackBtn.MouseButton1Click:Connect(function()
    if not autofarmOn then return end
    hackPOVOn = not hackPOVOn
    hackBtn.BackgroundColor3 = hackPOVOn and Color3.fromRGB(180, 30, 30) or Color3.fromRGB(50, 50, 50)
    blur.Enabled = hackPOVOn

    local cam = workspace.CurrentCamera
    if hackPOVOn then
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = CFrame.new(100, 60, -500) * CFrame.Angles(0, math.rad(45), 0)
    else
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = character.Humanoid
    end
end)

-- === Cash Tracking ===
local dataFolder = player:WaitForChild("DataFolder", 5)
if dataFolder then
    for _, v in pairs(dataFolder:GetChildren()) do
        if v:IsA("ValueBase") and v.Name:lower():find("curr") then
            v.Changed:Connect(function()
                local gain = v.Value - startCash
                counterLabel.Text = "💵 Gagné : " .. tostring(gain)
            end)
        end
    end
end

-- === Boucle centrale optimisée ===
local t1, t2, t3 = 0, 0, 0
RunService.Heartbeat:Connect(function(dt)
    if not autofarmOn then return end

    t1 += dt t2 += dt t3 += dt

    if t1 > 0.5 then
        t1 = 0
        rootPart.CFrame = getNextRoutePosition()
        punchUntilDHCDetected()
    end

    if t2 > 0.3 then
        t2 = 0
        local drop = nearest(moneyDrops, 22)
        if drop then
            isFarmingDHC = true
            aimingATM = false
            teleportAndClick(drop)
        else
            isFarmingDHC = false
            aimingATM = true
        end
    end

    if aimingATM and t3 > 1.0 then
        t3 = 0
        local atm = nearest(atms)
        if atm then
            local dir = (atm.Position - rootPart.Position).Unit
            rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Vector3.new(dir.X,0,dir.Z))
        end
    end
end)
