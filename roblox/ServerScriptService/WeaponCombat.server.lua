-- WeaponCombat v2.0
-- Script: ServerScriptService/WeaponCombat.server.lua
-- All hit validation and damage are authoritative on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local actionRemote = ReplicatedStorage:FindFirstChild("WeaponAction")
if not actionRemote then
    actionRemote = Instance.new("RemoteEvent")
    actionRemote.Name = "WeaponAction"
    actionRemote.Parent = ReplicatedStorage
end

local lastUse = {}
local boundTools = {}

local function equippedTool(player)
    local character = player.Character
    if not character then return nil end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") and child:GetAttribute("ItemID") then
            return child
        end
    end
    return nil
end

local function cooldownReady(player, tool, action)
    local itemId = tool:GetAttribute("ItemID")
    if typeof(itemId) ~= "string" then return false end
    lastUse[player] = lastUse[player] or {}
    local key = itemId .. ":" .. action
    local now = os.clock()
    local required = tool:GetAttribute("Cooldown") or 2
    if action == "Attack" then required = math.max(0.35, required * 0.35) end
    local previous = lastUse[player][key] or 0
    if now - previous < required then return false end
    lastUse[player][key] = now
    return true
end

local function makeImpact(position, color, radius)
    local effect = Instance.new("Part")
    effect.Name = "AIWeaponImpact"
    effect.Shape = Enum.PartType.Ball
    effect.Anchored = true
    effect.CanCollide = false
    effect.CanTouch = false
    effect.CanQuery = false
    effect.Material = Enum.Material.Neon
    effect.Color = color
    effect.Transparency = 0.3
    effect.Size = Vector3.new(1, 1, 1)
    effect.CFrame = CFrame.new(position)
    effect.Parent = workspace

    local size = math.clamp(radius * 2, 2, 32)
    local tween = TweenService:Create(
        effect,
        TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = Vector3.new(size, size, size), Transparency = 1}
    )
    tween:Play()
    Debris:AddItem(effect, 0.4)
end

local function getColor(tool)
    local hex = tool:GetAttribute("PrimaryColor")
    if typeof(hex) ~= "string" or not hex:match("^#%x%x%x%x%x%x$") then
        return Color3.fromRGB(255, 170, 70)
    end
    return Color3.fromRGB(
        tonumber(hex:sub(2, 3), 16),
        tonumber(hex:sub(4, 5), 16),
        tonumber(hex:sub(6, 7), 16)
    )
end

local function perform(player, tool, action)
    if not tool or tool.Parent ~= player.Character then return end
    if not cooldownReady(player, tool, action) then return end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local ownHumanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not ownHumanoid or ownHumanoid.Health <= 0 then return end

    local range = math.clamp(tool:GetAttribute("Range") or 10, 6, 30)
    local damage = math.clamp(tool:GetAttribute("Damage") or 10, 5, 60)
    local abilityRadius = math.clamp(tool:GetAttribute("EffectRadius") or 8, 0, 20)
    local radius = action == "Ability" and math.max(abilityRadius, 4) or math.min(range * 0.55, 9)
    local center = root.Position + root.CFrame.LookVector * (action == "Ability" and math.min(range * 0.5, 12) or 4)
    local color = getColor(tool)

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}

    local found = workspace:GetPartBoundsInRadius(center, radius, params)
    local hitHumanoids = {}
    for _, part in ipairs(found) do
        local model = part:FindFirstAncestorOfClass("Model")
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        local targetRoot = model and model:FindFirstChild("HumanoidRootPart")
        if humanoid and targetRoot and humanoid.Health > 0 and not hitHumanoids[humanoid] then
            local distance = (targetRoot.Position - root.Position).Magnitude
            local facing = root.CFrame.LookVector:Dot((targetRoot.Position - root.Position).Unit)
            if distance <= range and (action == "Ability" or facing > -0.1) then
                hitHumanoids[humanoid] = true
                humanoid:TakeDamage(damage * (action == "Ability" and 1.5 or 1))
                local knockback = math.clamp(tool:GetAttribute("Knockback") or 0, 0, 40)
                if knockback > 0 then
                    targetRoot.AssemblyLinearVelocity += root.CFrame.LookVector * knockback
                end
            end
        end
    end

    makeImpact(center, color, radius)
end

local function bindTool(player, tool)
    if not tool:IsA("Tool") or not tool:GetAttribute("ItemID") or boundTools[tool] then return end
    boundTools[tool] = true
    tool.Activated:Connect(function()
        if tool.Parent == player.Character then
            perform(player, tool, "Attack")
        end
    end)
    tool.Destroying:Connect(function()
        boundTools[tool] = nil
    end)
end

local function watchPlayer(player)
    local backpack = player:WaitForChild("Backpack")
    backpack.ChildAdded:Connect(function(child) bindTool(player, child) end)
    for _, child in ipairs(backpack:GetChildren()) do bindTool(player, child) end

    player.CharacterAdded:Connect(function(character)
        character.ChildAdded:Connect(function(child) bindTool(player, child) end)
        for _, child in ipairs(character:GetChildren()) do bindTool(player, child) end
    end)
    if player.Character then
        player.Character.ChildAdded:Connect(function(child) bindTool(player, child) end)
    end
end

actionRemote.OnServerEvent:Connect(function(player, action)
    if action ~= "Ability" then return end
    local tool = equippedTool(player)
    if tool then perform(player, tool, "Ability") end
end)

Players.PlayerAdded:Connect(watchPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(watchPlayer, player) end
Players.PlayerRemoving:Connect(function(player)
    lastUse[player] = nil
end)

print("[Roblox AI Core] WeaponCombat v2.0 iniciado.")
