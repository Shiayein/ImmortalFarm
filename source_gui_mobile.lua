-- source_gui_mobile.lua
-- Standalone, mobile-friendly GUI library (no external deps).
-- English only. Square theme. Blue accent (#0000FF).
-- Features:
--   - Window with draggable title bar (sinks camera input while dragging)
--   - Global Open/Close button (always on screen)
--   - Keyboard toggle key (default RightShift), rebindable via API and a keybind control
--   - Tabs -> Sections -> Checkbox-style Toggles
--   - Indicator panel + notifications
-- API (minimal):
--   library:init()
--   library:SetOpen(bool)
--   library:SetToggleKey(Enum.KeyCode)
--   library.NewWindow({title,size,position,subtitle,gameTagColor})
--   window:AddTab(name) -> tab
--   tab:AddSection(title, col) -> section
--   section:AddToggle({text,state,callback}) -> toggleApi
--   section:AddKeybind({text,default,onChanged}) -> keybindApi
--   library.NewIndicator({title,enabled,position}) -> indicator
--   indicator:AddValue({key,value}) -> valueApi (valueApi:SetValue("..."))

local startupArgs = ({...})[1] or {}

if getgenv().library_mobile ~= nil then
    pcall(function() getgenv().library_mobile:Unload() end)
end

local function GS(s) return game:GetService(s) end
local TweenService = GS("TweenService")
local UserInputService = GS("UserInputService")
local ContextActionService = GS("ContextActionService")

local function tween(o, props, t, style, dir)
    local info = TweenInfo.new(t or 0.16, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
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

-- Colors
local ACCENT = Color3.fromRGB(0,0,255) -- #0000FF
local BG     = Color3.fromRGB(22,22,26)
local BG2    = Color3.fromRGB(16,16,20)
local BG3    = Color3.fromRGB(12,12,16)
local STROKE = Color3.fromRGB(60,60,70)
local TEXT   = Color3.fromRGB(235,235,240)
local SUBTXT = Color3.fromRGB(170,170,180)
local RED    = Color3.fromRGB(220,80,80)

local library = {
    windows = {},
    indicators = {},
    connections = {},
    cheatname = startupArgs.cheatname or "ImmortalFarm",
    gamename  = startupArgs.gamename  or "Da Hood",
    fileext   = startupArgs.fileext   or ".json",
    hasInit = false,
    open = true,
    toggleKey = Enum.KeyCode.RightShift,
}

local function connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(library.connections, c)
    return c
end

local function sinkDragInputs(bind)
    if bind then
        ContextActionService:BindAction("IF_UI_DragSink", function() return Enum.ContextActionResult.Sink end, false,
            Enum.UserInputType.Touch, Enum.UserInputType.MouseMovement, Enum.UserInputType.MouseButton1)
    else
        ContextActionService:UnbindAction("IF_UI_DragSink")
    end
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

    -- Keyboard toggle
    connect(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == self.toggleKey then
            self:SetOpen(not self.open)
        end
    end)

    -- Open/Close button (draggable, square)
    local btnW = isTouch() and 56 or 44
    local btnH = isTouch() and 56 or 44
    local openBtn = new("TextButton", {
        Name = "IF_OpenClose",
        Parent = sg,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(0, btnW, 0, btnH),
        BackgroundColor3 = BG2,
        Text = "UI",
        TextColor3 = TEXT,
        Font = Enum.Font.GothamBold,
        TextSize = isTouch() and 16 or 14,
        AutoButtonColor = false,
    })
    new("UIStroke", { Parent = openBtn, Color = STROKE, Thickness = 1 })

    openBtn.MouseButton1Click:Connect(function()
        self:SetOpen(not self.open)
    end)

    -- Drag logic + sink camera while dragging
    local dragging, dragStart, startPos
    openBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = openBtn.Position
            sinkDragInputs(true)
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    sinkDragInputs(false)
                end
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

function library:SetOpen(state)
    self.open = state
    for _,w in ipairs(self.windows) do
        if w._root then w._root.Visible = state end
    end
end

function library:SetToggleKey(keycode)
    self.toggleKey = keycode
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
    new("UIStroke", { Parent = f, Color = STROKE, Thickness = 1 })
    new("Frame", { Parent = f, BackgroundColor3 = color or ACCENT, Size = UDim2.new(0, 4, 1, 0) })
    new("TextLabel", {
        Parent = f, BackgroundTransparency = 1, Text = tostring(text or ""),
        Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = TEXT,
        Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 8, 0, 0), TextXAlignment = Enum.TextXAlignment.Left
    })
    tween(f, { Size = UDim2.new(0, 280, 0, 28) }, 0.16):Play()
    task.delay(timeSec or 2, function()
        tween(f, { Size = UDim2.new(0, 0, 0, 28) }, 0.14):Play()
        task.delay(0.15, function() f:Destroy() end)
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
        Size = UDim2.new(0, 220, 0, 46),
        Position = data.position or UDim2.new(0, 12, 0, 220),
        Visible = data.enabled == nil and true or data.enabled,
    })
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
        task.defer(function()
            frame.Size = UDim2.new(0, math.max(220, title.TextBounds.X + 40), 0, 28 + (#indicator.values * 18))
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
        Parent = sg, BackgroundColor3 = BG, Size = data.size or UDim2.new(0, 560, 0, 420),
        Position = data.position or UDim2.new(0, 120, 0, 120), Visible = selfLib.open
    })
    new("UIStroke", { Parent = root, Color = STROKE, Thickness = 1 })

    -- Title bar (square)
    local topH = isTouch() and 46 or 40
    local top = new("Frame", { Parent = root, BackgroundColor3 = BG2, Size = UDim2.new(1, 0, 0, topH) })
    new("Frame", { Parent = top, BackgroundColor3 = ACCENT, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2) })

    local mainTitle = new("TextLabel", {
        Parent = top, BackgroundTransparency = 1,
        Text = tostring(data.title or "ImmortalFarm") .. " - https://discord.gg/qzE7xvkzAZ",
        Font = Enum.Font.GothamBold, TextSize = isTouch() and 16 or 14, TextColor3 = TEXT,
        Size = UDim2.new(1, -160, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left
    })
    local gameTag = new("TextLabel", {
        Parent = top, BackgroundTransparency = 1, Text = tostring(data.subtitle or "Da Hood"),
        Font = Enum.Font.GothamBold, TextSize = isTouch() and 14 or 13, TextColor3 = data.gameTagColor or RED,
        Size = UDim2.new(0, 120, 1, 0), Position = UDim2.new(1, -160, 0, 0), TextXAlignment = Enum.TextXAlignment.Right
    })
    local close = new("TextButton", {
        Parent = top, BackgroundTransparency = 1, Text = "X", Font = Enum.Font.GothamBold,
        TextSize = isTouch() and 18 or 16, TextColor3 = SUBTXT, Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1, -40, 0, 0)
    })
    close.MouseButton1Click:Connect(function() selfLib:SetOpen(false) end)

    -- Dragging + sink camera
    do
        local dragging, dragStart, startPos
        top.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = i.Position
                startPos = root.Position
                sinkDragInputs(true)
                i.Changed:Connect(function()
                    if i.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        sinkDragInputs(false)
                    end
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
        Parent = root, BackgroundColor3 = BG3, Size = UDim2.new(1, -16, 1, -(topH + 16)),
        Position = UDim2.new(0, 8, 0, topH + 8), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarImageTransparency = 0.5
    })
    new("UIStroke", { Parent = body, Color = STROKE, Thickness = 1 })
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
        new("TextLabel", {
            Parent = body, BackgroundTransparency = 1, Text = tostring(label or "Main"),
            TextColor3 = TEXT, Font = Enum.Font.GothamBold, TextSize = isTouch() and 15 or 14, Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Left
        })
        function tab:AddSection(name, _)
            local sec = {}
            local card = new("Frame", { Parent = body, BackgroundColor3 = BG2, Size = UDim2.new(1, 0, 0, 64) })
            new("UIStroke", { Parent = card, Color = STROKE, Thickness = 1 })
            new("TextLabel", { Parent = card, BackgroundTransparency = 1, Text = tostring(name or "Section"),
                TextColor3 = SUBTXT, Font = Enum.Font.GothamSemibold, TextSize = isTouch() and 14 or 13, Size = UDim2.new(1, -12, 0, 18), Position = UDim2.new(0, 12, 0, 8),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local list = new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, -12, 1, -30), Position = UDim2.new(0, 12, 0, 30) })
            local ll = new("UIListLayout", { Parent = list, FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 8) })

            local function resize()
                card.Size = UDim2.new(1, 0, 0, 30 + ll.AbsoluteContentSize.Y + 12)
            end
            resize()
            ll.Changed:Connect(resize)

            function sec:AddToggle(opt)
                opt = opt or {}
                local rowH = isTouch() and 36 or 28
                local row = new("Frame", { Parent = list, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, rowH) })
                local lbl = new("TextLabel", {
                    Parent = row, BackgroundTransparency = 1, Text = tostring(opt.text or "Toggle"),
                    TextColor3 = TEXT, Font = Enum.Font.GothamSemibold, TextSize = isTouch() and 15 or 13,
                    Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Left
                })

                local boxSize = isTouch() and 22 or 18
                local box = new("Frame", {
                    Parent = row, BackgroundColor3 = BG3, Size = UDim2.new(0, boxSize, 0, boxSize),
                    Position = UDim2.new(1, -(boxSize), 0.5, 0), AnchorPoint = Vector2.new(1, 0.5)
                })
                new("UIStroke", { Parent = box, Color = STROKE, Thickness = 1 })

                local fill = new("Frame", {
                    Parent = box, BackgroundColor3 = ACCENT, Size = UDim2.new(1, -6, 1, -6),
                    Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false
                })

                local state = opt.state and true or false
                local function apply()
                    fill.Visible = state
                end
                apply()

                local function toggleNow()
                    state = not state
                    apply()
                    if typeof(opt.callback) == "function" then
                        task.spawn(opt.callback, state)
                    end
                end

                -- Touch/Click handlers
                box.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        toggleNow()
                    end
                end)
                lbl.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        toggleNow()
                    end
                end)

                local api = {
                    class = "toggle",
                    SetState = function(_, b) state = b and true or false; apply() end,
                    GetState = function() return state end,
                }
                return api
            end

            function sec:AddKeybind(opt)
                opt = opt or {}
                local rowH = isTouch() and 36 or 28
                local row = new("Frame", { Parent = list, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, rowH) })
                new("TextLabel", {
                    Parent = row, BackgroundTransparency = 1, Text = tostring(opt.text or "Keybind"),
                    TextColor3 = TEXT, Font = Enum.Font.GothamSemibold, TextSize = isTouch() and 15 or 13,
                    Size = UDim2.new(1, -120, 1, 0), TextXAlignment = Enum.TextXAlignment.Left
                })
                local btn = new("TextButton", {
                    Parent = row, BackgroundColor3 = BG3, Size = UDim2.new(0, 110, 0, isTouch() and 28 or 24),
                    Position = UDim2.new(1, -112, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                    Text = (opt.default and opt.default.Name) or "RightShift", TextColor3 = TEXT,
                    Font = Enum.Font.GothamSemibold, TextSize = isTouch() and 14 or 12, AutoButtonColor = false
                })
                new("UIStroke", { Parent = btn, Color = STROKE, Thickness = 1 })

                local current = opt.default or Enum.KeyCode.RightShift
                local listening = false
                btn.MouseButton1Click:Connect(function()
                    listening = true
                    btn.Text = "Press..."
                end)

                local conn; conn = UserInputService.InputBegan:Connect(function(input, gpe)
                    if not listening then return end
                    if input.KeyCode ~= Enum.KeyCode.Unknown then
                        current = input.KeyCode
                        btn.Text = current.Name
                        listening = false
                        if typeof(opt.onChanged) == "function" then
                            pcall(opt.onChanged, current)
                        end
                    end
                end)

                local api = {
                    Get = function() return current end,
                    Set = function(_, key) current = key; btn.Text = key.Name end
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
