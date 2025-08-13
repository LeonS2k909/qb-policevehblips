Config = {}

-- How often the unit with lights ON sends its position (ms)
Config.UpdateInterval = 1500

-- Blip visuals
Config.Sprite = 56        -- Police car
Config.Color  = 3         -- Light blue
Config.Scale  = 0.9
Config.ShortRange = false

-- Text shown on the map. %s = player name or callsign if you add it.
Config.LabelTemplate = "Unit %s"

-- Optional: return a label string for this officer.
-- Replace with callsign lookup if you store it.
function Config.BuildUnitLabel(src, name)
    return string.format(Config.LabelTemplate, name or ("#" .. tostring(src)))
end
