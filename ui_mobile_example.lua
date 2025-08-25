-- ui_mobile_example.lua
-- Example using the refined square, checkbox-style mobile GUI.

local LIB_URL = "https://raw.githubusercontent.com/Shiayein/ImmortalFarm/main/source_gui_mobile.lua"

local library = loadstring(game:HttpGet(LIB_URL))()
library:init()

local Window = library.NewWindow({
    title = "ImmortalFarm",
    subtitle = "Da Hood",
})

local Tab = Window:AddTab("main")
local Section = Tab:AddSection("Farm Controls", 1)

Section:AddToggle({
    text = "Immortal Farm",
    state = false,
    callback = function(state)
        -- if state then StartFarm() else StopFarm() end
    end
})

Section:AddToggle({
    text = "Hack POV",
    state = false,
    callback = function(state)
        -- SetPOV(state)
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

local gainsIndicator = library.NewIndicator({
    title = "Immortal",
    enabled = true,
    position = UDim2.new(0, 12, 0, 240),
    clickToOpen = true, -- tapping this will reopen the GUI without duplicates
})
local gainsValue = gainsIndicator:AddValue({ key = "Gains", value = "0" })
-- gainsValue:SetValue("1234")
