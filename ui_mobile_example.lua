-- ui_mobile_example.lua
-- ImmortalFarm - UI only (mobile-friendly square GUI)
-- Controls the logic in main.lua via getgenv().IF

local IF = getgenv().IF or {}
getgenv().IF = IF

local LIB_URL = "https://raw.githubusercontent.com/Shiayein/ImmortalFarm/main/source_gui_mobile.lua"
local library = loadstring(game:HttpGet(LIB_URL))()
library:init()

local Window = library.NewWindow({ title = "ImmortalFarm", subtitle = "Da Hood" })
local Tab = Window:AddTab("main")
local Section = Tab:AddSection("Farm Controls", 1)

-- Indicator and value
local gainsIndicator = library.NewIndicator({
    title = "Immortal",
    enabled = true,
    position = UDim2.new(0, 12, 0, 240),
    clickToOpen = true, -- tap to reopen the GUI (no duplicates)
})
local gainsValue = gainsIndicator:AddValue({ key = "Gains", value = "0" })

-- Allow logic to update the UI gains
IF.SetGains = function(text)
    gainsValue:SetValue(tostring(text or "0"))
end

-- UI -> Logic
Section:AddToggle({
    text = "Immortal Farm",
    state = false,
    callback = function(on)
        if IF.StartFarm then IF.StartFarm(on) end
    end
})

Section:AddToggle({
    text = "Hack POV",
    state = false,
    callback = function(on)
        if IF.SetPOV then IF.SetPOV(on) end
    end
})

Section:AddKeybind({
    text = "Toggle UI Key",
    default = Enum.KeyCode.RightShift,
    onChanged = function(key)
        library:SetToggleKey(key)
        library:SendNotification("UI key set to: ".. key.Name, 2)
    end
})
