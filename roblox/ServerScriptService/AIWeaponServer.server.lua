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

local function validateWeapon(weapon)
    if typeof(weapon) ~= "table" then return false end
    if not ALLOWED_TYPES[weapon.weapon_type] then return false end
    if not ALLOWED_ABILITIES[weapon.ability_id] then return false end
    if typeof(weapon.name) ~= "string" or #weapon.name < 2 or #weapon.name > 32 then return false end
    if typeof(weapon.damage) ~= "number" or weapon.damage < 5 or weapon.damage > 60 then return false end
    if typeof(weapon.cooldown) ~= "number" or weapon.cooldown < 0.8 or weapon.cooldown > 5 then return false end
    if typeof(weapon.range) ~= "number" or weapon.range < 6 or weapon.range > 30 then return false end
    if typeof(weapon.color) ~= "string" or not weapon.color:match("^#%x%x%x%x%x%x$") then return false end
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
