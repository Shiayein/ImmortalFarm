-- source_gui_mobile.lua
-- Standalone, mobile-friendly GUI library inspired by "Tokyo Lib Source.lua", with no external dependencies.
-- Focus: simple window, sections, toggles, indicator, notifications. Touch-first sizing.
-- Usage:
--   local library = loadstring(readfile("source_gui_mobile.lua"))() -- or loadstring(game:HttpGet("<raw-url>"))()
--   library:init()
--   local win = library.NewWindow({ title = "ImmortalFarm", size = UDim2.new(0, 420, 0, 280), position = UDim2.new(0, 80, 0, 120) })
--   local tab = win:AddTab("Main")
--   local sec = tab:AddSection("Farm Controls", 1)
--   sec:AddToggle({ text = "Immortal Farm", state = false, callback = function(on) print("Farm:", on) end })
--   sec:AddToggle({ text = "Hack POV", state = false, callback = function(on) print("POV:", on) end })
--   local ind = library.NewIndicator({ title = "Immortal", enabled = true, position = UDim2.new(0, 12, 0, 240) })
--   local gains = ind:AddValue({ key = "Gains", value = "0" })
--   gains:SetValue("123")

local startupArgs = ({...})[1] or {}

if getgenv().library_mobile ~= nil then
    pcall(function() getgenv().library_mobile:Unload() end)
end

local function GS(s) return game:GetService(s) end
local TweenService = GS("TweenService")
local Players = GS("Players")
local UserInputService = GS("UserInputService")
local RunService = GS("RunService")

local function tween(o, props, t, style, dir)
    local info = TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    return TweenService:Create(o, info, props)
end

local function new(inst, props)
    local o = Instance.new(inst)
    for k,v in pairs(props or {}) do o[k] = v end
    return o
end

local function isTouch()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local ACCENT = Color3.fromRGB(0,0,255) -- #0000FF
local BG     = Color3.fromRGB(22,22,26)
local BG2    = Color3.fromRGB(16,16,20)
local STROKE = Color3.fromRGB(60,60,70)
local TEXT   = Color3.fromRGB(235,235,240)
local SUBTXT = Color3.fromRGB(170,170,180)

local library = {
    windows = {},
    options = {},
    indicators = {},
    connections = {},
    theme = {
        Accent = ACCENT,
        ["Main Background"] = BG,
        ["Secondary Background"] = BG2,
        ["Stroke"] = STROKE,
        ["Text"] = TEXT,
        ["Sub Text"] = SUBTXT,
    },
    cheatname = startupArgs.cheatname or "ImmortalFarm",
    gamename  = startupArgs.gamename  or "Da Hood",
    fileext   = startupArgs.fileext   or ".json",
    hasInit = false,
    open = true,
}

local function connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(library.connections, c)
    return c
end

function library:Unload()
    if self._gui then
        self._gui:Destroy()
    end
    for _,c in ipairs(self.connections) do pcall(function() c:Disconnect() end) end
    self.windows = {}
    self.indicators = {}
    getgenv().library_mobile = nil
end

function library:init()
    if self.hasInit then return end
    self.hasInit = true

    local sg = new("ScreenGui", { Name = "IF_MobileUI", IgnoreGuiInset = true, ResetOnSpawn = false })
    if syn and syn.protect_gui then pcall(function() syn.protect_gui(sg) end) end
    sg.Parent = game:GetService("CoreGui")
    self._gui = sg

    -- Open/Close button (always accessible on mobile)
    local btnSize = isTouch() and UDim2.new(0, 54, 0, 54) or UDim2.new(0, 40, 0, 40)
    local openBtn = new("TextButton", {
        Name = "OpenClose",
        Parent = sg,
        Position = UDim2.new(0, 10, 0, 10),
        Size = btnSize,
        BackgroundColor3 = BG2,
        Text = "UI",
        TextColor3 = TEXT,
        Font = Enum.Font.GothamBold,
        TextSize = isTouch() and 16 or 14,
        AutoButtonColor = false,
    })
    local openStroke = new("UIStroke", { Parent = openBtn, Color = STROKE, Thickness = 1 })
    new("UICorner", { Parent = openBtn, CornerRadius = UDim.new(0, 10) })

    openBtn.MouseButton1Click:Connect(function()
        self:SetOpen(not self.open)
    end)

    -- Draggable for the open button
    local dragging, dragStart, startPos
    openBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = openBtn.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    openBtn.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - dragStart
            openBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    self._openBtn = openBtn
    getgenv().library_mobile = self
end

function library:SetTheme(tbl)
    for k,v in pairs(tbl or {}) do
        self.theme[k] = v
    end
end

function library:SetOpen(state)
    self.open = state
    for _,w in ipairs(self.windows) do
        if w._root then w._root.Visible = state end
    end
end

function library:SendNotification(text, timeSec, color)
    local sg = self._gui
    if not sg then return end
    local holder = sg:FindFirstChild("NotifHolder") or new("Frame", {
        Name = "NotifHolder",
        Parent = sg,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.new(0, 300, 1, -20),
        BackgroundTransparency = 1,
    })
    local y = #holder:GetChildren() * 36
    local f = new("Frame", {
        Parent = holder, BackgroundColor3 = BG, Size = UDim2.new(0, 0, 0, 28),
        Position = UDim2.new(1, 0, 0, y), AnchorPoint = Vector2.new(1, 0)
    })
    new("UICorner", { Parent = f, CornerRadius = UDim.new(0, 6) })
    new("UIStroke", { Parent = f, Color = STROKE, Thickness = 1 })
    local bar = new("Frame", { Parent = f, BackgroundColor3 = color or ACCENT, Size = UDim2.new(0, 4, 1, 0) })
    new("UICorner", { Parent = bar, CornerRadius = UDim.new(0, 6) })
    local lbl = new("TextLabel", {
        Parent = f, BackgroundTransparency = 1, Text = tostring(text or ""),
        Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = TEXT,
        Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 8, 0, 0), TextXAlignment = Enum.TextXAlignment.Left
    })
    tween(f, { Size = UDim2.new(0, 260, 0, 28) }, 0.18):Play()
    task.delay(timeSec or 2, function()
        tween(f, { Size = UDim2.new(0, 0, 0, 28) }, 0.15):Play()
        task.delay(0.16, function() f:Destroy() end)
    end)
end

function library.NewIndicator(data)
    data = data or {}
    local selfLib = getgenv().library_mobile
    local sg = selfLib and selfLib._gui
    if not sg then return end
    local frame = new("Frame", {
        Parent = sg,
        BackgroundColor3 = BG,
        Size = UDim2.new(0, 200, 0, 40),
        Position = data.position or UDim2.new(0, 12, 0, 220),
        Visible = data.enabled == nil and true or data.enabled,
    })
    new("UICorner", { Parent = frame, CornerRadius = UDim.new(0, 8) })
    new("UIStroke", { Parent = frame, Color = STROKE, Thickness = 1 })
    local title = new("TextLabel", {
        Parent = frame, BackgroundTransparency = 1, Text = data.title or "Indicator",
        TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = 14, Size = UDim2.new(1, -10, 0, 18), Position = UDim2.new(0, 10, 0, 4),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local listHolder = new("Frame", { Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, -24), Position = UDim2.new(0, 10, 0, 22)})
    local layout = new("UIListLayout", { Parent = listHolder, FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 2) })

    local indicator = { _frame = frame, _holder = listHolder, values = {} }

    function indicator:SetEnabled(b) frame.Visible = b end
    function indicator:SetPosition(u) frame.Position = u end

    function indicator:AddValue(opt)
        opt = opt or {}
        local row = new("Frame", { Parent = listHolder, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16) })
        local k = new("TextLabel", {
            Parent = row, BackgroundTransparency = 1, Text = tostring(opt.key or ""),
            TextColor3 = SUBTXT, Font = Enum.Font.GothamSemibold, TextSize = 13,
            Size = UDim2.new(1, -80, 1, 0), TextXAlignment = Enum.TextXAlignment.Left
        })
        local v = new("TextLabel", {
            Parent = row, BackgroundTransparency = 1, Text = tostring(opt.value or ""),
            TextColor3 = SUBTXT, Font = Enum.Font.GothamSemibold, TextSize = 13,
            Size = UDim2.new(0, 70, 1, 0), Position = UDim2.new(1, -70, 0, 0), TextXAlignment = Enum.TextXAlignment.Right
        })
        local valObj = {
            _row = row, _k = k, _v = v,
            SetValue = function(self, str) v.Text = tostring(str) end,
            SetKey   = function(self, str) k.Text = tostring(str) end,
            Remove   = function(self) row:Destroy() end
        }
        table.insert(indicator.values, valObj)
        -- auto-resize frame based on content
        task.defer(function()
            frame.Size = UDim2.new(0, math.max(200, title.TextBounds.X + 40), 0, 24 + (#indicator.values * 18))
        end)
        return valObj
    end

    return indicator
end

function library.NewWindow(data)
    data = data or {}
    local selfLib = getgenv().library_mobile
    local sg = selfLib and selfLib._gui
    assert(sg, "[source_gui_mobile] library:init() must be called first")
    local root = new("Frame", {
        Parent = sg, BackgroundColor3 = BG, Size = data.size or UDim2.new(0, 420, 0, 280),
        Position = data.position or UDim2.new(0, 80, 0, 120), Visible = selfLib.open
    })
    new("UICorner", { Parent = root, CornerRadius = UDim.new(0, 10) })
    new("UIStroke", { Parent = root, Color = STROKE, Thickness = 1 })

    -- Title bar
    local top = new("Frame", { Parent = root, BackgroundColor3 = BG2, Size = UDim2.new(1, 0, 0, isTouch() and 44 or 36) })
    new("UICorner", { Parent = top, CornerRadius = UDim.new(0, 10) })
    local accent = new("Frame", { Parent = top, BackgroundColor3 = ACCENT, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2) })
    local title = new("TextLabel", {
        Parent = top, BackgroundTransparency = 1, Text = tostring(data.title or ""),
        Font = Enum.Font.GothamBold, TextSize = isTouch() and 16 or 14, TextColor3 = TEXT,
        Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 12, 0, 0), TextXAlignment = Enum.TextXAlignment.Left
    })
    local close = new("TextButton", {
        Parent = top, BackgroundTransparency = 1, Text = "×", Font = Enum.Font.GothamBold,
        TextSize = isTouch() and 20 or 18, TextColor3 = SUBTXT, Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1, -40, 0, 0)
    })
    close.MouseButton1Click:Connect(function() selfLib:SetOpen(false) end)

    -- Dragging
    do
        local dragging, dragStart, startPos
        top.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = i.Position
                startPos = root.Position
                i.Changed:Connect(function()
                    if i.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        top.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local delta = i.Position - dragStart
                root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- Body scroll
    local body = new("ScrollingFrame", {
        Parent = root, BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, -(top.Size.Y.Offset + 16)),
        Position = UDim2.new(0, 8, 0, top.Size.Y.Offset + 8), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarImageTransparency = 0.5
    })
    local bodyLayout = new("UIListLayout", { Parent = body, FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 8) })
    bodyLayout.Changed:Connect(function()
        body.CanvasSize = UDim2.new(0, 0, 0, bodyLayout.AbsoluteContentSize.Y + 16)
    end)

    local window = { _root = root, _body = body, tabs = {} }
    table.insert(library.windows, window)

    function window:SetOpen(b) root.Visible = b end

    function window:AddTab(label)
        local tab = { sections = {} }
        -- header label
        local header = new("TextLabel", {
            Parent = body, BackgroundTransparency = 1, Text = tostring(label or "Main"),
            TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = isTouch() and 15 or 14, Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Left
        })
        function tab:AddSection(name, _)
            local sec = {}
            local card = new("Frame", { Parent = body, BackgroundColor3 = BG2, Size = UDim2.new(1, 0, 0, 64) })
            new("UICorner", { Parent = card, CornerRadius = UDim.new(0, 8) })
            new("UIStroke", { Parent = card, Color = STROKE, Thickness = 1 })
            local title = new("TextLabel", { Parent = card, BackgroundTransparency = 1, Text = tostring(name or "Section"),
                TextColor3 = SUBTXT, Font = Enum.Font.GothamSemibold, TextSize = isTouch() and 14 or 13, Size = UDim2.new(1, -12, 0, 18), Position = UDim2.new(0, 12, 0, 8),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local list = new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, -12, 1, -30), Position = UDim2.new(0, 12, 0, 30) })
            local ll = new("UIListLayout", { Parent = list, FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 8) })
            card.Size = UDim2.new(1, 0, 0, 30 + ll.AbsoluteContentSize.Y + 12)
            ll.Changed:Connect(function()
                card.Size = UDim2.new(1, 0, 0, 30 + ll.AbsoluteContentSize.Y + 12)
            end)

            function sec:AddToggle(opt)
                opt = opt or {}
                local row = new("Frame", { Parent = list, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, isTouch() and 36 or 28) })
                local lbl = new("TextLabel", {
                    Parent = row, BackgroundTransparency = 1, Text = tostring(opt.text or "Toggle"),
                    TextColor3 = TEXT, Font = Enum.Font.GothamSemibold, TextSize = isTouch() and 15 or 13,
                    Size = UDim2.new(1, -80, 1, 0), TextXAlignment = Enum.TextXAlignment.Left
                })
                local btn = new("TextButton", {
                    Parent = row, BackgroundColor3 = Color3.fromRGB(40,40,48), Size = UDim2.new(0, isTouch() ? 68 : 58, 0, isTouch() and 28 or 22),
                    Position = UDim2.new(1, -(isTouch() and 72 or 62), 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                    Text = "", AutoButtonColor = false
                })
                new("UICorner", { Parent = btn, CornerRadius = UDim.new(0, isTouch() and 14 or 12) })
                new("UIStroke", { Parent = btn, Color = STROKE, Thickness = 1 })
                local knob = new("Frame", {
                    Parent = btn, BackgroundColor3 = Color3.fromRGB(180,180,190), Size = UDim2.new(0, isTouch() and 24 or 20, 0, isTouch() and 24 or 20),
                    Position = UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5)
                })
                new("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })

                local state = opt.state and true or false
                local function apply()
                    if state then
                        tween(btn, { BackgroundColor3 = ACCENT }, 0.12):Play()
                        tween(knob, { Position = UDim2.new(1, -(knob.Size.X.Offset + 2), 0.5, 0), BackgroundColor3 = Color3.fromRGB(255,255,255) }, 0.12):Play()
                    else
                        tween(btn, { BackgroundColor3 = Color3.fromRGB(40,40,48) }, 0.12):Play()
                        tween(knob, { Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = Color3.fromRGB(180,180,190) }, 0.12):Play()
                    end
                end
                apply()

                btn.MouseButton1Click:Connect(function()
                    state = not state
                    apply()
                    if typeof(opt.callback) == "function" then
                        task.spawn(opt.callback, state)
                    end
                end)

                local api = {
                    class = "toggle",
                    SetState = function(_, b) state = b and true or false; apply() end,
                    GetState = function() return state end,
                }
                return api
            end

            tab.sections[#tab.sections+1] = sec
            return sec
        end
        table.insert(window.tabs, tab)
        return tab
    end

    return window
end

return library
