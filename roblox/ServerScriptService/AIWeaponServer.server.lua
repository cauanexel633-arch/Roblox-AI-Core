-- Coloque este Script em ServerScriptService.
-- Crie um Secret chamado ROBLOX_AI_CORE_KEY no Creator Dashboard/Studio.
-- O Secret deve estar autorizado para o domínio HTTPS do seu backend.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local API_URL = "https://SEU-DOMINIO.com/v1/weapons/generate"
local SECRET_NAME = "ROBLOX_AI_CORE_KEY"
local GAME_ID = tostring(game.GameId)
local MIN_SECONDS_BETWEEN_REQUESTS = 15
local lastRequest = {}

local remote = ReplicatedStorage:FindFirstChild("GenerateWeapon")
if not remote then
    remote = Instance.new("RemoteFunction")
    remote.Name = "GenerateWeapon"
    remote.Parent = ReplicatedStorage
end

local WeaponFactory = require(ServerScriptService:WaitForChild("WeaponFactory"))

remote.OnServerInvoke = function(player, prompt)
    if typeof(prompt) ~= "string" then
        return { ok = false, error = "Descrição inválida." }
    end
    prompt = string.sub(prompt, 1, 240)
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
                ["x-api-key"] = HttpService:GetSecret(SECRET_NAME)
            },
            Body = HttpService:JSONEncode({
                prompt = prompt,
                player_id = player.UserId,
                game_id = GAME_ID
            })
        })

        if not response.Success then
            error("Backend respondeu HTTP " .. tostring(response.StatusCode))
        end
        return HttpService:JSONDecode(response.Body)
    end)

    if not ok or type(result) ~= "table" or result.ok ~= true or type(result.weapon) ~= "table" then
        warn("Roblox AI Core falhou:", result)
        return { ok = false, error = "Não foi possível criar a arma agora." }
    end

    -- Verificação final no servidor Roblox: nunca confie somente na IA/backend.
    local weapon = result.weapon
    local allowedTypes = { sword = true, staff = true, bow = true, gauntlet = true }
    local allowedAbilities = {
        slash = true, fire_burst = true, ice_bolt = true,
        dash_strike = true, poison_orb = true, chain_lightning = true
    }
    if not allowedTypes[weapon.weapon_type] or not allowedAbilities[weapon.ability_id] then
        return { ok = false, error = "A arma gerada não passou na validação." }
    end
    if typeof(weapon.damage) ~= "number" or weapon.damage < 5 or weapon.damage > 60 then
        return { ok = false, error = "Atributos da arma inválidos." }
    end

    local tool = WeaponFactory.Create(weapon)
    tool.Parent = player:WaitForChild("Backpack")

    return { ok = true, weapon = weapon }
end

Players.PlayerRemoving:Connect(function(player)
    lastRequest[player.UserId] = nil
end)
