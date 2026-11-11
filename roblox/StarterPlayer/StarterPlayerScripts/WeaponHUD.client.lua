-- WeaponHUD v2.0
-- LocalScript: StarterPlayer/StarterPlayerScripts/WeaponHUD.client.lua
-- Responsive HUD for desktop and touch devices.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local actionRemote = ReplicatedStorage:WaitForChild("WeaponAction")
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "RobloxAIWeaponHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "WeaponPanel"
panel.AnchorPoint = Vector2.new(1, 1)
panel.Position = UDim2.new(1, -18, 1, -18)
panel.Size = UDim2.fromOffset(270, 148)
panel.BackgroundColor3 = Color3.fromRGB(16, 19, 29)
panel.BackgroundTransparency = 0.08
panel.Visible = false
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(85, 105, 145)
stroke.Transparency = 0.25
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 10)
title.Size = UDim2.new(1, -28, 0, 28)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(245, 247, 255)
title.Text = "ARMA"
title.Parent = panel

local stats = Instance.new("TextLabel")
stats.BackgroundTransparency = 1
stats.Position = UDim2.fromOffset(14, 42)
stats.Size = UDim2.new(1, -28, 0, 32)
stats.Font = Enum.Font.Gotham
stats.TextSize = 12
stats.TextXAlignment = Enum.TextXAlignment.Left
stats.TextColor3 = Color3.fromRGB(180, 190, 210)
stats.Text = ""
stats.Parent = panel

local ability = Instance.new("TextButton")
ability.Name = "AbilityButton"
ability.AnchorPoint = Vector2.new(1, 1)
ability.Position = UDim2.new(1, -12, 1, -12)
ability.Size = UDim2.fromOffset(148, 44)
ability.BackgroundColor3 = Color3.fromRGB(125, 75, 220)
ability.TextColor3 = Color3.new(1, 1, 1)
ability.Font = Enum.Font.GothamBold
ability.TextSize = 13
ability.Text = "HABILIDADE  [Q]"
ability.AutoButtonColor = true
ability.Parent = panel

local abilityCorner = Instance.new("UICorner")
abilityCorner.CornerRadius = UDim.new(0, 10)
abilityCorner.Parent = ability

local attack = Instance.new("TextButton")
attack.Name = "AttackButton"
attack.AnchorPoint = Vector2.new(0, 1)
attack.Position = UDim2.new(0, 12, 1, -12)
attack.Size = UDim2.fromOffset(88, 44)
attack.BackgroundColor3 = Color3.fromRGB(38, 115, 190)
attack.TextColor3 = Color3.new(1, 1, 1)
attack.Font = Enum.Font.GothamBold
attack.TextSize = 13
attack.Text = "ATACAR"
attack.Parent = panel

local attackCorner = Instance.new("UICorner")
attackCorner.CornerRadius = UDim.new(0, 10)
attackCorner.Parent = attack

local equippedTool
local abilityBusy = false

local UI_THEMES = {
    inferno = Color3.fromRGB(220, 75, 45),
    frost = Color3.fromRGB(55, 155, 220),
    arcane = Color3.fromRGB(145, 85, 220),
    nature = Color3.fromRGB(55, 155, 105),
    storm = Color3.fromRGB(70, 115, 210),
    neutral = Color3.fromRGB(105, 80, 210),
}

local function refresh(tool)
    equippedTool = tool
    if not tool then
        panel.Visible = false
        return
    end

    local damage = tool:GetAttribute("Damage") or 0
    local cooldown = tool:GetAttribute("Cooldown") or 0
    local range = tool:GetAttribute("Range") or 0
    local rarity = tostring(tool:GetAttribute("Rarity") or "common"):upper()
    title.Text = tostring(tool.Name)
    stats.Text = string.format("%s  •  DANO %d  •  ALCANCE %d  •  %.1fs", rarity, damage, range, cooldown)
    panel.Visible = true
    panel.Size = UDim2.fromOffset(250, 140)
    TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Size = UDim2.fromOffset(270, 148)
    }):Play()
end

local function connectTool(tool)
    if not tool:IsA("Tool") or not tool:GetAttribute("ItemID") then return end
    tool.Equipped:Connect(function() refresh(tool) end)
    tool.Unequipped:Connect(function()
        if equippedTool == tool then refresh(nil) end
    end)
    if player.Character and tool.Parent == player.Character then
        refresh(tool)
    end
end

local function onCharacter(character)
    character.ChildAdded:Connect(connectTool)
    for _, child in ipairs(character:GetChildren()) do connectTool(child) end
    refresh(nil)
end

if player.Character then onCharacter(player.Character) end
player.CharacterAdded:Connect(onCharacter)

local function useAbility()
    if not equippedTool or abilityBusy then return end
    abilityBusy = true
    actionRemote:FireServer("Ability")

    local original = ability.Text
    local duration = math.clamp(equippedTool:GetAttribute("Cooldown") or 2, 0.8, 5)
    for remaining = math.ceil(duration), 1, -1 do
        ability.Text = "RECARGA " .. remaining .. "s"
        task.wait(1)
    end
    ability.Text = original
    abilityBusy = false
end

ability.Activated:Connect(useAbility)
attack.Activated:Connect(function()
    if equippedTool then equippedTool:Activate() end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q then useAbility() end
end)

print("[Roblox AI Core] WeaponHUD v2.0 iniciado.")
