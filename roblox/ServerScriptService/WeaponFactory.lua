-- WeaponFactory v2.0
-- ModuleScript: ServerScriptService/WeaponFactory
-- Builds only from a strict, local allowlist. Never executes model-generated code.

local HttpService = game:GetService("HttpService")

local WeaponFactory = {}

local MATERIALS = {
    metal = Enum.Material.Metal,
    obsidian = Enum.Material.Slate,
    wood = Enum.Material.Wood,
    crystal = Enum.Material.Glass,
    stone = Enum.Material.Rock,
}

local RARITY = {
    common = Color3.fromRGB(190, 190, 190),
    uncommon = Color3.fromRGB(80, 220, 120),
    rare = Color3.fromRGB(70, 150, 255),
    epic = Color3.fromRGB(180, 90, 255),
    legendary = Color3.fromRGB(255, 180, 50),
}

local PARTICLES = {
    fire = Color3.fromRGB(255, 90, 25),
    ice = Color3.fromRGB(100, 210, 255),
    sparks = Color3.fromRGB(255, 220, 100),
    poison = Color3.fromRGB(100, 255, 90),
    arcane = Color3.fromRGB(190, 100, 255),
    lightning = Color3.fromRGB(120, 190, 255),
}

local function colorFromHex(hex, fallback)
    if typeof(hex) ~= "string" or not string.match(hex, "^#%x%x%x%x%x%x$") then
        return fallback
    end
    return Color3.fromRGB(
        tonumber(string.sub(hex, 2, 3), 16),
        tonumber(string.sub(hex, 4, 5), 16),
        tonumber(string.sub(hex, 6, 7), 16)
    )
end

local function part(tool, handle, name, size, offset, color, material, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = handle.CFrame * offset
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Anchored = false
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Massless = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if shape then p.Shape = shape end
    p.Parent = tool

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = p
    weld.Parent = p
    return p
end

local function addGlow(target, color)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = 1.6
    light.Range = 10
    light.Parent = target
end

local function addParticles(target, color)
    local attachment = Instance.new("Attachment")
    attachment.Parent = target

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "AIWeaponParticles"
    emitter.Color = ColorSequence.new(color)
    emitter.LightEmission = 0.75
    emitter.Rate = 10
    emitter.Lifetime = NumberRange.new(0.3, 0.7)
    emitter.Speed = NumberRange.new(0.4, 1.8)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.16),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment
end

local function buildSword(tool, handle, primary, accent, material)
    part(tool, handle, "Grip", Vector3.new(0.28, 1.05, 0.28),
        CFrame.new(0, -0.45, 0), Color3.fromRGB(65, 42, 30), Enum.Material.Wood)
    part(tool, handle, "Guard", Vector3.new(1.25, 0.16, 0.32),
        CFrame.new(0, 0.25, 0), accent, Enum.Material.Metal)
    local blade = part(tool, handle, "Blade", Vector3.new(0.62, 2.7, 0.15),
        CFrame.new(0, 1.65, 0), primary, material)
    local core = part(tool, handle, "BladeCore", Vector3.new(0.12, 2.35, 0.17),
        CFrame.new(0, 1.65, -0.09), accent, Enum.Material.Neon)
    addGlow(core, accent)
    local a0 = Instance.new("Attachment")
    a0.Position = Vector3.new(0, -1.25, 0)
    a0.Parent = blade
    local a1 = Instance.new("Attachment")
    a1.Position = Vector3.new(0, 1.25, 0)
    a1.Parent = blade
    local trail = Instance.new("Trail")
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Color = ColorSequence.new(primary, accent)
    trail.Lifetime = 0.22
    trail.Enabled = true
    trail.Parent = blade
end

local function buildStaff(tool, handle, primary, accent, material)
    part(tool, handle, "StaffBody", Vector3.new(0.28, 3.9, 0.28),
        CFrame.new(0, 0, 0), Color3.fromRGB(65, 42, 28), Enum.Material.Wood)
    local orb = part(tool, handle, "MagicCore", Vector3.new(0.82, 0.82, 0.82),
        CFrame.new(0, 2.0, 0), primary, Enum.Material.Neon, Enum.PartType.Ball)
    part(tool, handle, "OrbRing", Vector3.new(1.1, 0.14, 1.1),
        CFrame.new(0, 1.65, 0), accent, Enum.Material.Neon, Enum.PartType.Cylinder)
    addGlow(orb, primary)
    addParticles(orb, accent)
end

local function buildBow(tool, handle, primary, accent, material)
    part(tool, handle, "BowGrip", Vector3.new(0.28, 1.1, 0.28),
        CFrame.new(0, 0, 0), Color3.fromRGB(70, 45, 25), Enum.Material.Wood)
    local segments = {
        {Vector3.new(0, 1.1, 0), Vector3.new(0.25, 1.0, 0.2), 18},
        {Vector3.new(0, 1.85, 0), Vector3.new(0.18, 0.8, 0.18), 35},
        {Vector3.new(0, 2.45, 0), Vector3.new(0.12, 0.5, 0.15), 55},
        {Vector3.new(0, -1.1, 0), Vector3.new(0.25, 1.0, 0.2), -18},
        {Vector3.new(0, -1.85, 0), Vector3.new(0.18, 0.8, 0.18), -35},
        {Vector3.new(0, -2.45, 0), Vector3.new(0.12, 0.5, 0.15), -55},
    }
    for i, item in ipairs(segments) do
        part(tool, handle, "BowLimb" .. i, item[2],
            CFrame.new(item[1]) * CFrame.Angles(0, 0, math.rad(item[3])),
            primary, material)
    end
    part(tool, handle, "BowString", Vector3.new(0.04, 4.9, 0.04),
        CFrame.new(0, 0, -0.08), accent, Enum.Material.Neon)
end

local function buildGauntlet(tool, handle, primary, accent, material)
    part(tool, handle, "GauntletBase", Vector3.new(1.0, 1.55, 1.0),
        CFrame.new(0, 0, 0), Color3.fromRGB(55, 55, 65), Enum.Material.Metal)
    part(tool, handle, "GauntletPlate", Vector3.new(1.12, 0.42, 1.12),
        CFrame.new(0, 0.72, 0), primary, material)
    local core = part(tool, handle, "GauntletCore", Vector3.new(0.5, 0.5, 0.5),
        CFrame.new(0, 0.12, -0.54), accent, Enum.Material.Neon, Enum.PartType.Ball)
    addGlow(core, accent)
    addParticles(core, primary)
end

local BUILDERS = {
    sword = buildSword,
    staff = buildStaff,
    bow = buildBow,
    gauntlet = buildGauntlet,
}

function WeaponFactory.Create(spec)
    assert(typeof(spec) == "table", "Weapon spec must be a table")

    local weaponType = string.lower(tostring(spec.weapon_type or "sword"))
    local builder = BUILDERS[weaponType]
    assert(builder, "Unsupported weapon type")

    local visual = typeof(spec.visual) == "table" and spec.visual or {}
    local combat = typeof(spec.combat) == "table" and spec.combat or {}
    local primary = colorFromHex(spec.color, Color3.fromRGB(180, 180, 200))
    local accent = colorFromHex(visual.accent_color, RARITY[string.lower(tostring(spec.rarity))] or RARITY.common)
    local material = MATERIALS[visual.material] or Enum.Material.Metal
    local particleColor = PARTICLES[visual.particle_style] or accent

    local tool = Instance.new("Tool")
    tool.Name = string.sub(tostring(spec.name or "AI Weapon"), 1, 32)
    tool.ToolTip = string.sub(tostring(spec.description or "Weapon generated by AI"), 1, 100)
    tool.RequiresHandle = true
    tool.CanBeDropped = false

    tool:SetAttribute("ItemID", HttpService:GenerateGUID(false))
    tool:SetAttribute("WeaponType", weaponType)
    tool:SetAttribute("Rarity", tostring(spec.rarity or "common"))
    tool:SetAttribute("AbilityId", tostring(spec.ability_id or "slash"))
    tool:SetAttribute("Damage", math.clamp(tonumber(spec.damage) or 10, 5, 60))
    tool:SetAttribute("Cooldown", math.clamp(tonumber(spec.cooldown) or 2, 0.8, 5))
    tool:SetAttribute("Range", math.clamp(tonumber(spec.range) or 10, 6, 30))
    tool:SetAttribute("AttackStyle", tostring(combat.attack_style or "melee"))
    tool:SetAttribute("EffectRadius", math.clamp(tonumber(combat.effect_radius) or 8, 0, 20))
    tool:SetAttribute("Knockback", math.clamp(tonumber(combat.knockback) or 0, 0, 40))
    tool:SetAttribute("AbilityDuration", math.clamp(tonumber(combat.ability_duration) or 1, 0.2, 8))
    tool:SetAttribute("PrimaryColor", spec.color or "#B4B4C8")
    tool:SetAttribute("AccentColor", visual.accent_color or "#FFD166")
    tool:SetAttribute("ParticleStyle", tostring(visual.particle_style or "sparks"))
    tool:SetAttribute("Description", tostring(spec.description or ""))

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.35, 0.35, 0.35)
    handle.Transparency = 1
    handle.CanCollide = false
    handle.CanTouch = false
    handle.CanQuery = false
    handle.Massless = true
    handle.Parent = tool

    builder(tool, handle, primary, particleColor, material)
    return tool
end

return WeaponFactory
