-- ModuleScript em ServerScriptService. Cria um Tool visual com atributos validados.
-- O combate/efeitos das habilidades será implementado em uma próxima etapa.
local WeaponFactory = {}

local function colorFromHex(hex)
    if typeof(hex) ~= "string" or not string.match(hex, "^#%x%x%x%x%x%x$") then
        return Color3.fromRGB(180, 180, 200)
    end
    local r = tonumber(string.sub(hex, 2, 3), 16)
    local g = tonumber(string.sub(hex, 4, 5), 16)
    local b = tonumber(string.sub(hex, 6, 7), 16)
    return Color3.fromRGB(r, g, b)
end

function WeaponFactory.Create(spec)
    local tool = Instance.new("Tool")
    tool.Name = string.sub(tostring(spec.name or "Arma"), 1, 32)
    tool.ToolTip = string.sub(tostring(spec.description or "Arma criada por IA"), 1, 100)
    tool.RequiresHandle = true
    tool.CanBeDropped = false

    tool:SetAttribute("WeaponType", spec.weapon_type)
    tool:SetAttribute("Rarity", spec.rarity)
    tool:SetAttribute("AbilityId", spec.ability_id)
    tool:SetAttribute("Damage", math.clamp(tonumber(spec.damage) or 10, 5, 60))
    tool:SetAttribute("Cooldown", math.clamp(tonumber(spec.cooldown) or 2, 0.8, 5))
    tool:SetAttribute("Range", math.clamp(tonumber(spec.range) or 10, 6, 30))

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.35, 3, 0.35)
    handle.Material = Enum.Material.Neon
    handle.Color = colorFromHex(spec.color)
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = tool

    local light = Instance.new("PointLight")
    light.Color = handle.Color
    light.Range = 8
    light.Brightness = 0.8
    light.Parent = handle

    return tool
end

return WeaponFactory
