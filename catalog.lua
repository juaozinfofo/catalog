-- Skin Stealer Pro+ Script
-- Original Author: https://github.com/juaozinfofo
-- Enhanced and fixed by Grok (xAI) to resolve tab rendering and Send Like issues
-- Last Updated: May 05, 2025

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CatalogModule = require(ReplicatedStorage:WaitForChild("CatalogModule"))
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- UI Window
local Window = Fluent:CreateWindow({
    Title = "Skin Stealer Pro+",
    SubTitle = "Edição Suprema",
    TabWidth = 160,
    Size = UDim2.fromOffset(610, 500),
    Acrylic = false,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Outfits", Icon = "shirt" }),
    PlayerMods = Window:AddTab({ Title = "Mods", Icon = "user" }),
    Extras = Window:AddTab({ Title = "Extras", Icon = "sparkles" }),
    Settings = Window:AddTab({ Title = "Config", Icon = "settings" }),
    SendLike = Window:AddTab({ Title = "Send Like", Icon = "heart" })
}

-- Setup Save + Interface
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("SkinStealerPro")
SaveManager:SetFolder("SkinStealerPro/configs")

-- Access Options
local Options = Fluent.Options

-- Debugging function to log element creation
local function logElement(tabName, elementType, title)
    print(string.format("Added %s to %s: %s", elementType, tabName, title))
end

-- Get player names
local function GetPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    return names
end

local Dropdown
local LastSelection = nil

-- Function to copy outfit
local function CopyOutfit(player)
    if not player or not player.Character then return end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local desc = hum:GetAppliedDescription()
    local success, err = pcall(function()
        ReplicatedStorage.CatalogGuiRemote:InvokeServer({
            Action = "CreateAndWearHumanoidDescription",
            Properties = CatalogModule:ToDictionary(desc),
            RigType = hum.RigType
        })
    end)
    if success then
        Fluent:Notify({ Title = "✅ Sucesso", Content = "Outfit copiado!", Duration = 4 })
    else
        Fluent:Notify({ Title = "Erro", Content = tostring(err), Duration = 4 })
    end
end

-- Function to view outfit
local function ViewOutfit(player)
    if not player or not player.Character then return end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    ReplicatedStorage.ClientInspectHumanoidDescription:Fire({
        HumanoidDescription = hum:GetAppliedDescription(),
        Title = "[Preview] @" .. player.Name,
        DisableWearButton = true
    })
    Fluent:Notify({ Title = "🔍 Preview", Content = "Visualizando outfit de " .. player.Name, Duration = 4 })
end

-- Function to send like
local function SendLike(targetPlayer)
    if not targetPlayer then
        Fluent:Notify({ Title = "Erro", Content = "Nenhum jogador selecionado!", Duration = 4 })
        return
    end

    local success, err = pcall(function()
        local events = game:GetService("ReplicatedStorage"):WaitForChild("Events", 5)
        local likeOutfitRemote = events:WaitForChild("LikeOutfit", 5)
        if not likeOutfitRemote then
            error("LikeOutfit remote not found")
        end

        likeOutfitRemote:FireServer(targetPlayer)
        Fluent:Notify({ Title = "👍 Enviado", Content = "Like enviado para " .. targetPlayer.Name, Duration = 4 })
    end)

    if not success then
        Fluent:Notify({ Title = "Erro", Content = "Falha ao enviar like: " .. tostring(err), Duration = 4 })
    end
end

-- Aba Main
local success, err = pcall(function()
    Tabs.Main:AddInput("FiltroNome", {
        Title = "Filtrar Jogador",
        Default = "",
        Placeholder = "Digite parte do nome...",
        Numeric = false,
        Finished = true,
        Callback = function(value)
            local filtered = {}
            for _, name in ipairs(GetPlayerNames()) do
                if string.find(string.lower(name), string.lower(value)) then
                    table.insert(filtered, name)
                end
            end
            Dropdown:SetValues(filtered)
        end
    })
    logElement("Main", "Input", "FiltroNome")

    Dropdown = Tabs.Main:AddDropdown("PlayerDropdown", {
        Title = "Selecionar Jogador",
        Values = GetPlayerNames(),
        Multi = false,
        Default = nil,
        Callback = function(value)
            LastSelection = value
            Options.PlayerDropdown:SetValue(value)
        end
    })
    logElement("Main", "Dropdown", "PlayerDropdown")

    Tabs.Main:AddButton({
        Title = "🔁 Atualizar Lista",
        Callback = function()
            Dropdown:SetValues(GetPlayerNames())
            Fluent:Notify({ Title = "Atualizado", Content = "Jogadores recarregados!", Duration = 3 })
        end
    })
    logElement("Main", "Button", "Atualizar Lista")

    Tabs.Main:AddButton({
        Title = "👁 Visualizar Outfit",
        Callback = function()
            local p = Players:FindFirstChild(Options.PlayerDropdown.Value or LastSelection)
            if p then ViewOutfit(p) end
        end
    })
    logElement("Main", "Button", "Visualizar Outfit")

    Tabs.Main:AddButton({
        Title = "🎭 Copiar Outfit",
        Callback = function()
            local p = Players:FindFirstChild(Options.PlayerDropdown.Value or LastSelection)
            if p then CopyOutfit(p) end
        end
    })
    logElement("Main", "Button", "Copiar Outfit")

    Tabs.Main:AddButton({
        Title = "🧼 Remover Acessórios",
        Callback = function()
            local char = LocalPlayer.Character
            if char then
                for _, item in ipairs(char:GetChildren()) do
                    if item:IsA("Accessory") then
                        item:Destroy()
                    end
                end
                Fluent:Notify({ Title = "Limpo", Content = "Acessórios removidos!", Duration = 3 })
            end
        end
    })
    logElement("Main", "Button", "Remover Acessórios")
end)
if not success then
    warn("Error in Main tab setup: " .. tostring(err))
end

-- Aba PlayerMods
success, err = pcall(function()
    Tabs.PlayerMods:AddParagraph({
        Title = "Modificações",
        Content = "Altere propriedades do seu personagem."
    })
    logElement("PlayerMods", "Paragraph", "Modificações")

    Tabs.PlayerMods:AddSlider("SpeedSlider", {
        Title = "Velocidade",
        Description = "Ajuste sua WalkSpeed",
        Min = 16,
        Max = 100,
        Default = 16,
        Callback = function(val)
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val end
        end
    })
    logElement("PlayerMods", "Slider", "SpeedSlider")

    Tabs.PlayerMods:AddToggle("InvisToggle", {
        Title = "Invisibilidade",
        Default = false,
        Callback = function(on)
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        part.Transparency = on and 0.7 or 0
                    end
                end
            end
        end
    })
    logElement("PlayerMods", "Toggle", "InvisToggle")
end)
if not success then
    warn("Error in PlayerMods tab setup: " .. tostring(err))
end

-- Aba Extras
success, err = pcall(function()
    Tabs.Extras:AddParagraph({
        Title = "Extras",
        Content = "Utilidades adicionais para o jogador."
    })
    logElement("Extras", "Paragraph", "Extras")

    Tabs.Extras:AddButton({
        Title = "🔄 Resetar Personagem",
        Callback = function()
            LocalPlayer:LoadCharacter()
        end
    })
    logElement("Extras", "Button", "Resetar Personagem")

    Tabs.Extras:AddDropdown("ThemeSwitch", {
        Title = "Tema da UI",
        Values = {"Amethyst", "Dark", "Light", "Aqua", "Jester"},
        Default = "Amethyst",
        Callback = function(theme)
            Window:SetTheme(theme)
        end
    })
    logElement("Extras", "Dropdown", "ThemeSwitch")

    Tabs.Extras:AddButton({
        Title = "Reentrar no Jogo",
        Callback = function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    })
    logElement("Extras", "Button", "Reentrar no Jogo")
end)
if not success then
    warn("Error in Extras tab setup: " .. tostring(err))
end

-- Aba Settings
success, err = pcall(function()
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)
    logElement("Settings", "Section", "Interface and Config")

    Tabs.Settings:AddKeybind("FecharUI", {
        Title = "Fechar com RightShift",
        Default = "RightShift",
        Mode = "Toggle",
        Callback = function(v)
            if v then Fluent:Destroy() end
        end
    })
    logElement("Settings", "Keybind", "FecharUI")
end)
if not success then
    warn("Error in Settings tab setup: " .. tostring(err))
end

-- Aba SendLike
success, err = pcall(function()
    Tabs.SendLike:AddParagraph({
        Title = "Like System",
        Content = "Envie curtidas para outros jogadores!"
    })
    logElement("SendLike", "Paragraph", "Like System")

    local sendLikeDropdown = Tabs.SendLike:AddDropdown("SendLikeDropdown", {
        Title = "Selecionar Jogador",
        Values = GetPlayerNames(),
        Multi = false,
        Default = nil,
        Callback = function(value)
            LastSelection = value
            Options.SendLikeDropdown:SetValue(value)
        end
    })
    logElement("SendLike", "Dropdown", "SendLikeDropdown")

    Tabs.SendLike:AddButton({
        Title = "Enviar Like para Selecionado",
        Callback = function()
            local p = Players:FindFirstChild(Options.SendLikeDropdown.Value or LastSelection)
            if p then
                SendLike(p)
            else
                Fluent:Notify({ Title = "Erro", Content = "Jogador não encontrado!", Duration = 4 })
            end
        end
    })
    logElement("SendLike", "Button", "Enviar Like para Selecionado")

    Tabs.SendLike:AddButton({
        Title = "Enviar Like para Todos",
        Callback = function()
            local sentCount = 0
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    SendLike(player)
                    sentCount = sentCount + 1
                end
            end
            if sentCount > 0 then
                Fluent:Notify({ Title = "👍 Enviado", Content = "Likes enviados para " .. sentCount .. " jogadores!", Duration = 4 })
            else
                Fluent:Notify({ Title = "Erro", Content = "Nenhum jogador disponível!", Duration = 4 })
            end
        end
    })
    logElement("SendLike", "Button", "Enviar Like para Todos")

    Tabs.SendLike:AddButton({
        Title = "Enviar Like para Aleatório",
        Callback = function()
            local players = GetPlayerNames()
            if #players > 0 then
                local randomPlayer = Players:FindFirstChild(players[math.random(1, #players)])
                if randomPlayer then
                    SendLike(randomPlayer)
                else
                    Fluent:Notify({ Title = "Erro", Content = "Jogador não encontrado!", Duration = 4 })
                end
            else
                Fluent:Notify({ Title = "Erro", Content = "Nenhum jogador disponível!", Duration = 4 })
            end
        end
    })
    logElement("SendLike", "Button", "Enviar Like para Aleatório")
end)
if not success then
    warn("Error in SendLike tab setup: " .. tostring(err))
end

-- Force refresh of all tabs
local function refreshTabs()
    for i = 1, #Tabs do
        Window:SelectTab(i)
    end
    Window:SelectTab(1) -- Return to Main tab
end
task.spawn(function()
    wait(1) -- Wait for UI to initialize
    refreshTabs()
end)

-- Update dropdowns dynamically
Players.PlayerAdded:Connect(function()
    local names = GetPlayerNames()
    if Dropdown then
        Dropdown:SetValues(names)
    end
    if Options.SendLikeDropdown then
        Options.SendLikeDropdown:SetValues(names)
    end
end)

Players.PlayerRemoving:Connect(function()
    local names = GetPlayerNames()
    if Dropdown then
        Dropdown:SetValues(names)
    end
    if Options.SendLikeDropdown then
        Options.SendLikeDropdown:SetValues(names)
    end
end)

-- Config Init
SaveManager:LoadAutoloadConfig()

-- Ensure initial tab selection
Window:SelectTab(1)

Fluent:Notify({
    Title = "✅ Skin Stealer Pro+",
    Content = "Pronto para clonar com estilo!",
    Duration = 5
})
