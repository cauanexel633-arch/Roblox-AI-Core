-- Exemplo opcional para um LocalScript de interface.
-- Não coloque chamadas HTTP nem segredos no cliente.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GenerateWeapon = ReplicatedStorage:WaitForChild("GenerateWeapon")

local AIWeaponRemote = {}

function AIWeaponRemote.Generate(prompt)
    local ok, result = pcall(function()
        return GenerateWeapon:InvokeServer(prompt)
    end)
    if not ok then
        return { ok = false, error = "Falha de comunicação com o servidor." }
    end
    return result
end

return AIWeaponRemote
