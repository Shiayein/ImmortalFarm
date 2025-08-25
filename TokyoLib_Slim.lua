-- TokyoLib_Slim.lua
-- Wrapper léger autour de Tokyo Lib Source
-- Force un seul thème (bleu #0000FF)

local base = loadstring(game:HttpGet("https://raw.githubusercontent.com/Shiayein/ImmortalFarm/main/Tokyo%20Lib%20Source.lua"))()

return function(opts)
    opts = opts or {}
    local library = base({
        cheatname = opts.cheatname or "ImmortalFarm",
        gamename  = opts.gamename  or "Da Hood",
        fileext   = opts.fileext   or ".json",
    })

    -- Thème unique bleu
    local IMMORTAL_THEME = {
        ['Main Background'] = Color3.fromRGB(22,22,26),
        ['Secondary Background'] = Color3.fromRGB(16,16,20),
        ['Tertiary Background'] = Color3.fromRGB(12,12,16),
        ['Stroke'] = Color3.fromRGB(60,60,70),
        ['Text'] = Color3.fromRGB(235,235,240),
        ['Sub Text'] = Color3.fromRGB(170,170,180),
        ['Accent'] = Color3.fromRGB(0,0,255), -- bleu
        ['Positive'] = Color3.fromRGB(60,200,120),
        ['Warning']  = Color3.fromRGB(240,160,60),
        ['Error']    = Color3.fromRGB(235,80,80),
        ['Shadow']   = Color3.fromRGB(0,0,0),
        ['Element Background'] = Color3.fromRGB(28,28,34),
        ['Slider Fill'] = Color3.fromRGB(0,0,255),
        ['Toggle On'] = Color3.fromRGB(0,0,255),
    }

    library.themes = { Immortal = IMMORTAL_THEME }
    library.activeTheme = "Immortal"
    library:SetTheme(IMMORTAL_THEME)

    return library
end
