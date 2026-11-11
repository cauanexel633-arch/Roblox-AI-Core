-- AIWeaponServer v2.0
-- Script: ServerScriptService/AIWeaponServer.server.lua
-- Configure the ROBLOX_AI_CORE_KEY Secret in Creator Dashboard/Studio.
-- Never place the OpenRouter key or Roblox backend key in a LocalScript.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local API_URL = "https://roblox-ai-core.vercel.app/v1/weapons/generate"
local SECRET_NAME = "ROBLOX_AI_CORE_KEY"
local GAME_ID = tostring(game.GameId)
local MIN_SECONDS_BETWEEN_REQUESTS = 15
local lastRequest = {}

local remote = ReplicatedStorage:FindFirstChild("GenerateWeapon")
if remote and not remote:IsA("RemoteFunction") then
    remote:Destroy()
    remote = nil
end
if not remote then
    remote = Instance.new("RemoteFunction")
    remote.Name = "GenerateWeapon"
    remote.Parent = ReplicatedStorage
end

local WeaponFactory = require(ServerScriptService:WaitForChild("WeaponFactory"))

local ALLOWED_TYPES = { sword = true, staff = true, bow = true, gauntlet = true }
local ALLOWED_ABILITIES = {
    slash = true, fire_burst = true, ice_bolt = true,
    dash_strike = true, poison_orb = true, chain_lightning = true,
}
local ALLOWED_RARITIES = { common = true, uncommon = true, rare = true, epic = true, legendary = true }
local ALLOWED_MATERIALS = { metal = true, obsidian = true, wood = true, crystal = true, stone = true }
local ALLOWED_SILHOUETTES = { slim = true, heavy = true, curved = true, double = true, ornate = true, segmented = true, organic = true }
local ALLOWED_PATTERNS = { plain = true, runic = true, serrated = true, flame = true, frost = true, lightning = true }
local ALLOWED_PARTICLES = { fire = true, ice = true, sparks = true, poison = true, arcane = true, lightning = true, none = true }
local ALLOWED_ANIMATIONS = { quick_slash = true, heavy_swing = true, thrust = true, cast = true, punch = true }
local ALLOWED_UI_THEMES = { inferno = true, frost = true, arcane = true, nature = true, storm = true, neutral = true }
local ALLOWED_ATTACK_STYLES = { melee = true, projectile = true, dash = true }

local function isColor(value)
    return typeof(value) == "string" and value:match("^#%x%x%x%x%x%x$") ~= nil
end

local function validateWeapon(weapon)
    if typeof(weapon) ~= "table" then return false end
    if not ALLOWED_TYPES[weapon.weapon_type] then return false end
    if not ALLOWED_ABILITIES[weapon.ability_id] then return false end
    if typeof(weapon.name) ~= "string" or #weapon.name < 2 or #weapon.name > 32 then return false end
    if typeof(weapon.damage) ~= "number" or weapon.damage < 5 or weapon.damage > 60 then return false end
    if typeof(weapon.cooldown) ~= "number" or weapon.cooldown < 0.8 or weapon.cooldown > 5 then return false end
    if typeof(weapon.range) ~= "number" or weapon.range < 6 or weapon.range > 30 then return false end
    if not isColor(weapon.color) then return false end
    if not ALLOWED_RARITIES[weapon.rarity] then return false end

    local visual = weapon.visual
    if visual ~= nil then
        if typeof(visual) ~= "table" then return false end
        if not ALLOWED_SILHOUETTES[visual.silhouette] then return false end
        if not ALLOWED_MATERIALS[visual.material] then return false end
        if not ALLOWED_PATTERNS[visual.pattern] then return false end
        if not ALLOWED_PARTICLES[visual.particle_style] then return false end
        if not ALLOWED_ANIMATIONS[visual.animation_style] then return false end
        if not ALLOWED_UI_THEMES[visual.ui_theme] then return false end
        if not isColor(visual.accent_color) then return false end
        if typeof(visual.detail_level) ~= "number" or visual.detail_level < 1 or visual.detail_level > 5 then return false end
    end

    local combat = weapon.combat
    if combat ~= nil then
        if typeof(combat) ~= "table" or not ALLOWED_ATTACK_STYLES[combat.attack_style] then return false end
        if typeof(combat.combo_count) ~= "number" or combat.combo_count < 1 or combat.combo_count > 4 then return false end
        if typeof(combat.effect_radius) ~= "number" or combat.effect_radius < 0 or combat.effect_radius > 20 then return false end
        if typeof(combat.knockback) ~= "number" or combat.knockback < 0 or combat.knockback > 40 then return false end
        if typeof(combat.ability_duration) ~= "number" or combat.ability_duration < 0.2 or combat.ability_duration > 8 then return false end
    end
    return true
end

remote.OnServerInvoke = function(player, prompt)
    if typeof(prompt) ~= "string" then
        return { ok = false, error = "Descrição inválida." }
    end
    prompt = string.sub(prompt, 1, 240)
    prompt = prompt:match("^%s*(.-)%s*$")
    if #prompt < 5 then
        return { ok = false, error = "Descreva melhor sua arma." }
    end

    local now = os.clock()
    if lastRequest[player.UserId] and now - lastRequest[player.UserId] < MIN_SECONDS_BETWEEN_REQUESTS then
        return { ok = false, error = "Aguarde antes de criar outra arma." }
    end
    lastRequest[player.UserId] = now

    local ok, result = pcall(function()
        local response = HttpService:RequestAsync({
            Url = API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["x-api-key"] = HttpService:GetSecret(SECRET_NAME),
            },
            Body = HttpService:JSONEncode({
                prompt = prompt,
                player_id = player.UserId,
                game_id = GAME_ID,
            }),
        })
        if not response.Success then
            error("Backend respondeu HTTP " .. tostring(response.StatusCode))
        end
        return HttpService:JSONDecode(response.Body)
    end)

    if not ok or typeof(result) ~= "table" or result.ok ~= true then
        warn("[Roblox AI Core] Falha na geração:", result)
        return { ok = false, error = "Não foi possível criar a arma agora." }
    end

    local weapon = result.weapon
    if not validateWeapon(weapon) then
        warn("[Roblox AI Core] Arma rejeitada pela validação do servidor.")
        return { ok = false, error = "A arma gerada não passou na validação." }
    end

    local buildOk, toolOrError = pcall(function()
        return WeaponFactory.Create(weapon)
    end)
    if not buildOk or not toolOrError then
        warn("[Roblox AI Core] Erro no WeaponFactory:", toolOrError)
        return { ok = false, error = "A arma foi projetada, mas não pôde ser construída." }
    end

    local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack")
    toolOrError.Parent = backpack

    return {
        ok = true,
        weapon = weapon,
        item_id = toolOrError:GetAttribute("ItemID"),
        model = result.model,
        request_id = result.request_id,
        design_references = result.design_references or {},
    }
end

Players.PlayerRemoving:Connect(function(player)
    lastRequest[player.UserId] = nil
end)

print("[Roblox AI Core] AIWeaponServer v2.0 iniciado.")
