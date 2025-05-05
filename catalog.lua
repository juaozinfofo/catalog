local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local CatalogModule
local success, err = pcall(function()
    CatalogModule = require(ReplicatedStorage:WaitForChild("CatalogModule", 5))
end)
if not success then
    Fluent:Notify({ Title = "Erro", Content = "Falha ao carregar CatalogModule: " .. tostring(err), Duration = 5 })
    return
end

local Window = Fluent:CreateWindow({
    Title = "Skin Stealer Pro+",
    SubTitle = "Edição Suprema",
    TabWidth = 160,
    Size = UDim2.fromOffset(610, 500),
    Acrylic = false,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Outfits", Icon = "shirt" }),
    PlayerMods = Window:AddTab({ Title = "Mods", Icon = "user" }),
    Likes = Window:AddTab({ Title = "Likes", Icon = "thumbs-up" }),
    Extras = Window:AddTab({ Title = "Extras", Icon = "sparkles" }),
    Settings = Window:AddTab({ Title = "Config", Icon = "settings" })
}

local Options = Fluent.Options

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("SkinStealerPro")
SaveManager:SetFolder("SkinStealerPro/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)

Fluent:Notify({
    Title = "⚠️ Aviso",
    Content = "Este script pode violar os Termos de Serviço do Roblox. Use por sua conta e risco!",
    Duration = 8
})

local playerNamesCache = {}
local function UpdatePlayerNames()
    playerNamesCache = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerNamesCache, player.Name)
        end
    end
    return playerNamesCache
end

local likeCooldown = false

Tabs.Main:AddParagraph({ Title = "Gerenciar Outfits", Content = "Selecione um jogador para visualizar ou copiar o outfit." })

local filterBox = Tabs.Main:AddInput("FiltroNome", {
    Title = "Filtrar Jogador",
    Default = "",
    Placeholder = "Digite parte do nome...",
    Numeric = false,
    Finished = true,
    Callback = function(value)
        local filtered = {}
        for _, name in ipairs(UpdatePlayerNames()) do
            if string.find(string.lower(name), string.lower(value)) then
                table.insert(filtered, name)
            end
        end
        Options.PlayerDropdown:SetValue(nil)
        Options.PlayerDropdown:SetValues(filtered)
    end
})

local Dropdown = Tabs.Main:AddDropdown("PlayerDropdown", {
    Title = "Selecionar Jogador",
    Values = UpdatePlayerNames(),
    Multi = false,
    Default = nil,
    Callback = function(value) end
})

Tabs.Main:AddButton({
    Title = "🔁 Atualizar Lista",
    Description = "Recarrega a lista de jogadores",
    Callback = function()
        Options.PlayerDropdown:SetValues(UpdatePlayerNames())
        Fluent:Notify({ Title = "Atualizado", Content = "Lista de jogadores recarregada!", Duration = 3 })
    end
})

Tabs.Main:AddButton({
    Title = "👁 Visualizar Outfit",
    Description = "Visualiza o outfit do jogador selecionado",
    Callback = function()
        local p = Players:FindFirstChild(Options.PlayerDropdown.Value)
        if p and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                local success, err = pcall(function()
                    ReplicatedStorage.ClientInspectHumanoidDescription:Fire({
                        HumanoidDescription = hum:GetAppliedDescription(),
                        Title = "[Preview] @" .. p.Name,
                        DisableWearButton = true
                    })
                end)
                if success then
                    Fluent:Notify({ Title = "🔍 Preview", Content = "Visualizando outfit de " .. p.Name, Duration = 4 })
                else
                    Fluent:Notify({ Title = "Erro", Content = "Falha ao visualizar: " .. tostring(err), Duration = 4 })
                end
            else
                Fluent:Notify({ Title = "Erro", Content = "Humanoid não encontrado!", Duration = 4 })
            end
        else
            Fluent:Notify({ Title = "Erro", Content = "Jogador ou personagem não encontrado!", Duration = 4 })
        end
    end
})

Tabs.Main:AddButton({
    Title = "🎭 Copiar Outfit",
    Description = "Copia o outfit do jogador selecionado",
    Callback = function()
        local p = Players:FindFirstChild(Options.PlayerDropdown.Value)
        if p and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                local desc = hum:GetAppliedDescription()
                local success, err = pcall(function()
                    ReplicatedStorage.CatalogGuiRemote:InvokeServer({
                        Action = "CreateAndWearHumanoidDescription",
                        Properties = CatalogModule:ToDictionary(desc),
                        RigType = hum.RigType
                    })
                end)
                if success then
                    Fluent:Notify({ Title = "✅ Sucesso", Content = "Outfit copiado de " .. p.Name, Duration = 4 })
                else
                    Fluent:Notify({ Title = "Erro", Content = "Falha ao copiar outfit: " .. tostring(err), Duration = 4 })
                end
            else
                Fluent:Notify({ Title = "Erro", Content = "Humanoid não encontrado!", Duration = 4 })
            end
        else
            Fluent:Notify({ Title = "Erro", Content = "Jogador ou personagem não encontrado!", Duration = 4 })
        end
    end
})

Tabs.Main:AddButton({
    Title = "🧼 Remover Acessórios",
    Description = "Remove todos os acessórios do seu personagem",
    Callback = function()
        local char = LocalPlayer.Character
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Accessory") or item:IsA("Part") then
                    item:Destroy()
                end
            end
            Fluent:Notify({ Title = "Limpo", Content = "Acessórios removidos!", Duration = 3 })
        else
            Fluent:Notify({ Title = "Erro", Content = "Personagem não encontrado!", Duration = 3 })
        end
    end
})

Tabs.Likes:AddButton({
    Title = "👍 Dar Like",
    Description = "Envia um like para o jogador selecionado",
    Callback = function()
        local p = Players:FindFirstChild(Options.PlayerDropdown.Value)
        if not p then
            Fluent:Notify({ Title = "Erro", Content = "Nenhum jogador selecionado!", Duration = 4 })
            return
        end
        if likeCooldown then
            Fluent:Notify({ Title = "Aguarde", Content = "Espere o cooldown de 5 segundos!", Duration = 4 })
            return
        end
        local success, err = pcall(function()
            local events = ReplicatedStorage:WaitForChild("Events", 5)
            local likeOutfitRemote = events:WaitForChild("LikeOutfit", 5)
            likeOutfitRemote:FireServer(p)
        end)
        if success then
            Fluent:Notify({ Title = "👍 Enviado", Content = "Like enviado para " .. p.Name, Duration = 4 })
            likeCooldown = true
            task.wait(5)
            likeCooldown = false
        else
            Fluent:Notify({ Title = "Erro", Content = "Falha ao enviar like: " .. tostring(err), Duration = 4 })
        end
    end
})

Tabs.Likes:AddButton({
    Title = "👍 Dar Like em Todos",
    Description = "Envia likes para todos os jogadores",
    Callback = function()
        Window:Dialog({
            Title = "Confirmar",
            Content = "Enviar like para todos os jogadores?",
            Buttons = {
                {
                    Title = "Sim",
                    Callback = function()
                        if likeCooldown then
                            Fluent:Notify({ Title = "Aguarde", Content = "Espere o cooldown de 5 segundos!", Duration = 4 })
                            return
                        end
                        local successCount = 0
                        local failureCount = 0
                        likeCooldown = true
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer then
                                local success, err = pcall(function()
                                    local events = ReplicatedStorage:WaitForChild("Events", 5)
                                    local likeOutfitRemote = events:WaitForChild("LikeOutfit", 5)
                                    likeOutfitRemote:FireServer(player)
                                end)
                                if success then
                                    successCount = successCount + 1
                                else
                                    failureCount = failureCount + 1
                                end
                                task.wait(0.1)
                            end
                        end
                        Fluent:Notify({
                            Title = "👍 Likes Enviados",
                            Content = string.format("Enviado para %d jogadores, %d falhas", successCount, failureCount),
                            Duration = 6
                        })
                        task.wait(5)
                        likeCooldown = false
                    end
                },
                {
                    Title = "Não",
                    Callback = function() end
                }
            }
        })
    end
})

Tabs.Extras:AddButton({
    Title = "🔄 Resetar Personagem",
    Description = "Recarrega seu personagem",
    Callback = function()
        Window:Dialog({
            Title = "Confirmar",
            Content = "Deseja resetar seu personagem?",
            Buttons = {
                { Title = "Sim", Callback = function() LocalPlayer:LoadCharacter() end },
                { Title = "Não", Callback = function() end }
            }
        })
    end
})

Tabs.Extras:AddDropdown("ThemeSwitch", {
    Title = "Tema da UI",
    Values = {"Amethyst", "Dark", "Light", "Aqua", "Jester"},
    Multi = false,
    Default = "Amethyst",
    Callback = function(theme)
        Window:SetTheme(theme)
        Fluent:Notify({ Title = "Tema", Content = "Tema alterado para " .. theme, Duration = 3 })
    end
})

Tabs.Extras:AddButton({
    Title = "Reentrar no Jogo",
    Description = "Volta ao jogo atual",
    Callback = function()
        Window:Dialog({
            Title = "Confirmar",
            Content = "Deseja reentrar no jogo?",
            Buttons = {
                { Title = "Sim", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end },
                { Title = "Não", Callback = function() end }
            }
        })
    end
})

Tabs.Settings:AddKeybind("Fechar UI", {
    Title = "Fechar UI",
    Mode = "Toggle",
    Default = "RightShift",
    Callback = function(value)
        if value then Fluent:Destroy() end
    end
})

local debounce = false
local function UpdateDropdown()
    if debounce then return end
    debounce = true
    Options.PlayerDropdown:SetValues(UpdatePlayerNames())
    task.wait(1)
    debounce = false
end

Players.PlayerAdded:Connect(UpdateDropdown)
Players.PlayerRemoving:Connect(UpdateDropdown)
SaveManager:LoadAutoloadConfig()

Fluent:Notify({ Title = "✅ Skin Stealer Pro+", Content = "Script carregado com sucesso!", Duration = 5 })
