-- WeaponCreator v2.0
-- LocalScript: StarterPlayer/StarterPlayerScripts/WeaponCreator.client.lua
-- Creates a responsive in-game AI weapon creation panel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local generateRemote = ReplicatedStorage:WaitForChild("GenerateWeapon")

local gui = Instance.new("ScreenGui")
gui.Name = "RobloxAIWeaponCreator"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local openButton = Instance.new("TextButton")
openButton.Name = "OpenCreator"
openButton.AnchorPoint = Vector2.new(0, 1)
openButton.Position = UDim2.new(0, 18, 1, -18)
openButton.Size = UDim2.fromOffset(156, 46)
openButton.BackgroundColor3 = Color3.fromRGB(92, 70, 190)
openButton.Text = "✦ CRIAR ARMA IA"
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 13
openButton.Parent = gui
Instance.new("UICorner", openButton).CornerRadius = UDim.new(0, 12)

local panel = Instance.new("Frame")
panel.Name = "CreatorPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.9, 0, 0, 310)
panel.BackgroundColor3 = Color3.fromRGB(17, 20, 31)
panel.Visible = false
panel.Parent = gui
local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(440, 360)
sizeConstraint.MinSize = Vector2.new(280, 300)
sizeConstraint.Parent = panel
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(100, 85, 175)
outline.Transparency = 0.2
outline.Parent = panel

local heading = Instance.new("TextLabel")
heading.BackgroundTransparency = 1
heading.Position = UDim2.fromOffset(18, 14)
heading.Size = UDim2.new(1, -65, 0, 30)
heading.Font = Enum.Font.GothamBold
heading.Text = "ROBLOX AI CORE"
heading.TextColor3 = Color3.fromRGB(245, 245, 255)
heading.TextSize = 19
heading.TextXAlignment = Enum.TextXAlignment.Left
heading.Parent = panel

local close = Instance.new("TextButton")
close.Position = UDim2.new(1, -46, 0, 12)
close.Size = UDim2.fromOffset(32, 32)
close.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
close.Text = "×"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 22
close.Font = Enum.Font.GothamBold
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(18, 48)
subtitle.Size = UDim2.new(1, -36, 0, 24)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Descreva sua arma. A IA cria design, atributos e habilidade."
subtitle.TextColor3 = Color3.fromRGB(165, 175, 195)
subtitle.TextSize = 11
subtitle.TextWrapped = true
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = panel

local promptBox = Instance.new("TextBox")
promptBox.Position = UDim2.fromOffset(18, 82)
promptBox.Size = UDim2.new(1, -36, 0, 76)
promptBox.BackgroundColor3 = Color3.fromRGB(29, 34, 49)
promptBox.TextColor3 = Color3.fromRGB(245, 247, 255)
promptBox.PlaceholderColor3 = Color3.fromRGB(125, 135, 155)
promptBox.PlaceholderText = "Ex.: espada ancestral de fogo com explosão de dragão..."
promptBox.Text = ""
promptBox.ClearTextOnFocus = false
promptBox.MultiLine = true
promptBox.TextWrapped = true
promptBox.TextXAlignment = Enum.TextXAlignment.Left
promptBox.TextYAlignment = Enum.TextYAlignment.Top
promptBox.Font = Enum.Font.Gotham
promptBox.TextSize = 13
promptBox.Parent = panel
Instance.new("UICorner", promptBox).CornerRadius = UDim.new(0, 10)

local generate = Instance.new("TextButton")
generate.Position = UDim2.fromOffset(18, 168)
generate.Size = UDim2.new(1, -36, 0, 42)
generate.BackgroundColor3 = Color3.fromRGB(105, 80, 210)
generate.Text = "✦ GERAR ARMA"
generate.TextColor3 = Color3.new(1, 1, 1)
generate.Font = Enum.Font.GothamBold
generate.TextSize = 14
generate.Parent = panel
Instance.new("UICorner", generate).CornerRadius = UDim.new(0, 10)

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(18, 218)
status.Size = UDim2.new(1, -36, 0, 72)
status.Font = Enum.Font.Gotham
status.Text = "Sua arma será entregue diretamente ao inventário."
status.TextColor3 = Color3.fromRGB(175, 185, 205)
status.TextSize = 12
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = panel

local busy = false

openButton.Activated:Connect(function()
    panel.Visible = not panel.Visible
end)
close.Activated:Connect(function()
    panel.Visible = false
end)

generate.Activated:Connect(function()
    if busy then return end
    local prompt = string.sub(promptBox.Text, 1, 240)
    if #prompt < 5 then
        status.Text = "Descreva sua arma com pelo menos 5 caracteres."
        status.TextColor3 = Color3.fromRGB(255, 150, 120)
        return
    end

    busy = true
    generate.Text = "CRIANDO..."
    generate.BackgroundColor3 = Color3.fromRGB(65, 65, 100)
    status.Text = "A IA está pesquisando referências e projetando sua arma..."
    status.TextColor3 = Color3.fromRGB(185, 190, 220)

    local ok, result = pcall(function()
        return generateRemote:InvokeServer(prompt)
    end)

    if not ok then
        status.Text = "Falha de comunicação com o servidor. Tente novamente."
        status.TextColor3 = Color3.fromRGB(255, 130, 120)
    elseif not result or result.ok ~= true then
        status.Text = (result and result.error) or "Não foi possível gerar a arma."
        status.TextColor3 = Color3.fromRGB(255, 130, 120)
    else
        local weapon = result.weapon or {}
        local refs = result.design_references or {}
        status.Text = string.format(
            "✓ %s criada e adicionada ao inventário!\nTipo: %s  •  Raridade: %s  •  Dano: %s\nReferências visuais: %d",
            tostring(weapon.name or "Arma"),
            tostring(weapon.weapon_type or "—"),
            tostring(weapon.rarity or "—"),
            tostring(weapon.damage or "—"),
            #refs
        )
        status.TextColor3 = Color3.fromRGB(120, 235, 165)
        TweenService:Create(generate, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(40, 145, 100)
        }):Play()
    end

    busy = false
    generate.Text = "✦ GERAR ARMA"
    if not result or result.ok ~= true then
        generate.BackgroundColor3 = Color3.fromRGB(105, 80, 210)
    end
end)

print("[Roblox AI Core] WeaponCreator v2.0 iniciado.")
