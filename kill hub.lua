-- ===============================
-- LIBRARIES
-- ===============================
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ===============================
-- SERVICES
-- ===============================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- ===============================
-- AUTO ATTACK VARIABLES
-- ===============================
local AutoAttackEnabled = false
local AttackCooldown = 0.5
local AttackRange = 20
local LastAttackTime = 0
local AttackConnection = nil
local TweenToMobEnabled = false
local TweenSpeed = 100
local CurrentTween = nil
local CurrentSlot = 0
local AutoQuestEnabled = false
local SelectedNPC = nil
local AutoAcceptQuestEnabled = false

-- ===============================
-- AUTO EXECUTE ON TELEPORT SYSTEM
-- ===============================
local AutoExecuteOnTeleport = false

-- ⚠️ IMPORTANTE: Coloque aqui a URL RAW do seu script!
local SCRIPT_URL = "COLE_AQUI_SUA_URL_DO_SCRIPT"
-- Exemplo: "https://raw.githubusercontent.com/seuuser/seurepo/main/script.lua"

-- Função para obter queue_on_teleport compatível
local function getQueueFunction()
    if syn and syn.queue_on_teleport then
        return syn.queue_on_teleport, "Synapse X"
    elseif queue_on_teleport then
        return queue_on_teleport, "Generic"
    elseif fluxus and fluxus.queue_on_teleport then
        return fluxus.queue_on_teleport, "Fluxus"
    elseif getgenv and getgenv().queue_on_teleport then
        return getgenv().queue_on_teleport, "GetGenv"
    elseif KRNL_LOADED and queue_on_teleport then
        return queue_on_teleport, "KRNL"
    end
    return nil, "Não Suportado"
end

local QueueFunction, ExecutorName = getQueueFunction()
local IsExecutorSupported = QueueFunction ~= nil

-- Função para fazer queue do script
local function queueScriptForTeleport()
    if not QueueFunction then
        warn("[AutoExecute] Executor não suporta queue_on_teleport!")
        return false
    end
    
    if not AutoExecuteOnTeleport then
        return false
    end
    
    local scriptCode = [[
-- ======================================
-- AUTO EXECUTE - Kill Hub
-- Executado automaticamente após teleport
-- ======================================

repeat task.wait() until game:IsLoaded()
task.wait(3) -- Espera o jogo carregar completamente

local success, err = pcall(function()
    loadstring(game:HttpGet("]] .. SCRIPT_URL .. [["))()
end)

if not success then
    warn("[AutoExecute] Erro: " .. tostring(err))
end
]]
    
    QueueFunction(scriptCode)
    print("[AutoExecute] Script em queue para próximo teleport!")
    return true
end

-- Detectar teleport
LocalPlayer.OnTeleport:Connect(function(state, placeId, spawnName)
    if state == Enum.TeleportState.Started then
        if AutoExecuteOnTeleport then
            print("[AutoExecute] Teleport detectado para PlaceId:", placeId)
            queueScriptForTeleport()
        end
    end
end)

-- ===============================
-- WINDOW SETUP
-- ===============================
local MarketplaceService = game:GetService("MarketplaceService")
local Player = Players.LocalPlayer
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
local DeveloperName = "papa_killll"

local UserTitle, UserSubtitle, UserColor

if Player.Name == DeveloperName then
    UserTitle = DeveloperName
    UserSubtitle = "Developer"
    UserColor = Color3.fromRGB(255, 85, 85)
else
    UserTitle = Player.DisplayName
    UserSubtitle = "User"
    UserColor = Color3.fromRGB(71, 123, 255)
end

local Window = Fluent:CreateWindow({
    Title = "Kill Hub",
    SubTitle = "| " .. GameName .. " | by MrJimex",
    Search = true,
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Arctic",
    MinimizeKey = Enum.KeyCode.LeftControl,
    UserInfo = true,
    UserInfoTop = true,
    UserInfoTitle = UserTitle,
    UserInfoSubtitle = UserSubtitle,
    UserInfoSubtitleColor = UserColor
})

local Minimizer = Fluent:CreateMinimizer({
    Icon = "",
    Size = UDim2.fromOffset(44, 44),
    Position = UDim2.new(0, 320, 0, 24),
    Acrylic = true,
    Corner = 10,
    Transparency = 1,
    Draggable = true,
    Visible = true
})

local Tabs = {
    Farm = Window:AddTab({ Title = "Farm", Icon = "swords" }),
    Stats = Window:AddTab({ Title = "Status", Icon = "server" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- ===============================
-- CORE FUNCTIONS
-- ===============================

function getNil(name, class)
    for _, v in pairs(getnilinstances()) do
        if v.ClassName == class and v.Name == name then
            return v
        end
    end
end

local function getLocalServerCharacter()
    local serverPlayers = Workspace.Characters.Server.Players:GetChildren()
    
    for _, char in pairs(serverPlayers) do
        if char.Name:find(LocalPlayer.Name) or char.Name:find("Server") then
            return char
        end
    end
    
    return serverPlayers[1]
end

local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function switchSlot(slotNumber)
    pcall(function()
        local Event = ReplicatedStorage.NetworkComm.InventoryService.FocusItem_Method
        Event:InvokeServer(slotNumber)
        CurrentSlot = slotNumber
    end)
end

local function acceptQuest(npcName)
    if not npcName then return false end
    
    pcall(function()
        local Event = ReplicatedStorage.NetworkComm.QuestService.AcceptQuest_Method
        Event:InvokeServer(npcName)
    end)
    
    return true
end

local function getNPCList()
    local npcList = {}
    local npcFolder = ReplicatedStorage.Assets.Models.Characters.Humanoid.NPCs
    
    if npcFolder then
        for _, npc in pairs(npcFolder:GetChildren()) do
            if npc:IsA("Model") then
                table.insert(npcList, npc.Name)
            end
        end
    end
    
    table.sort(npcList)
    return npcList
end

local function getNearestNPC()
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local localPos = localChar.HumanoidRootPart.Position
    local nearestNPC = nil
    local shortestDistance = math.huge
    
    if not TweenToMobEnabled then
        shortestDistance = AttackRange
    end
    
    local npcsFolder = Workspace.Characters.Server.NPCs
    if not npcsFolder then return nil end
    
    for _, npc in pairs(npcsFolder:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") then
            if AutoQuestEnabled and SelectedNPC and npc.Name ~= SelectedNPC then
                continue
            end
            
            local humanoid = npc.Humanoid
            
            if humanoid.Health > 0 and npc:FindFirstChild("HumanoidRootPart") then
                local distance = getDistance(localPos, npc.HumanoidRootPart.Position)
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestNPC = npc
                end
            end
        end
    end
    
    return nearestNPC, shortestDistance
end

local function performStartSkill(targetNPC)
    local localChar = getLocalServerCharacter()
    if not localChar then return false end
    
    pcall(function()
        local args = {
            [1] = "Punch",
            [2] = localChar,
            [3] = Vector3.new(0.918032169342041, 0, 0.3965059816837311),
            [4] = 1,
            [5] = 1
        }
        ReplicatedStorage.NetworkComm.SkillService.StartSkilll_Method:InvokeServer(unpack(args))
    end)
    
    return true
end

local function performDamage(targetNPC)
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return false end
    
    pcall(function()
        local args = {
            [1] = { [1] = targetNPC },
            [2] = true,
            [3] = {
                ["CanParry"] = false,
                ["OnCharacterHit"] = function() end,
                ["Origin"] = localChar.HumanoidRootPart.CFrame,
                ["LocalCharacter"] = localChar,
                ["WindowID"] = localChar.Name .. "_Punch",
                ["Parries"] = {},
                ["SkillID"] = "Punch"
            }
        }
        ReplicatedStorage.NetworkComm.CombatService.DamageCharacter_Method:InvokeServer(unpack(args))
    end)
    
    return true
end

local function tweenToMob(targetNPC)
    if not TweenToMobEnabled then return end
    
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return end
    if not targetNPC or not targetNPC:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPos = targetNPC.HumanoidRootPart.Position
    local currentPos = localChar.HumanoidRootPart.Position
    local distance = getDistance(currentPos, targetPos)
    
    if distance <= AttackRange * 0.8 then return end
    
    if CurrentTween then
        CurrentTween:Cancel()
    end
    
    local direction = (targetPos - currentPos).Unit
    local targetCFrame = CFrame.new(targetPos - (direction * (AttackRange * 0.6)))
    
    local tweenInfo = TweenInfo.new(
        distance / TweenSpeed,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    
    local TweenService = game:GetService("TweenService")
    CurrentTween = TweenService:Create(
        localChar.HumanoidRootPart,
        tweenInfo,
        {CFrame = targetCFrame}
    )
    
    CurrentTween:Play()
end

local function autoAttack()
    if not AutoAttackEnabled then return end
    
    local currentTime = tick()
    
    if AutoAcceptQuestEnabled and SelectedNPC then
        acceptQuest(SelectedNPC)
    end
    
    if currentTime - LastAttackTime < AttackCooldown then
        return
    end
    
    local targetNPC, distance = getNearestNPC()
    
    if targetNPC then
        if TweenToMobEnabled and distance > AttackRange * 0.8 then
            tweenToMob(targetNPC)
            task.wait(0.1)
        end
        
        local localChar = getLocalServerCharacter()
        if localChar and localChar:FindFirstChild("HumanoidRootPart") then
            local currentDist = getDistance(
                localChar.HumanoidRootPart.Position,
                targetNPC.HumanoidRootPart.Position
            )
            
            if currentDist <= AttackRange then
                performStartSkill(targetNPC)
                task.wait(0.05)
                performDamage(targetNPC)
                
                LastAttackTime = currentTime
            end
        end
    end
end

-- ===============================
-- FARM TAB UI
-- ===============================

local AutoAttackSection = Tabs.Farm:AddSection("Auto Attack")

local AutoAttackToggle = Tabs.Farm:AddToggle("AutoAttack", {
    Title = "Kill Aura",
    Description = "Ataca automaticamente NPCs próximos",
    Default = false,
    Callback = function(Value)
        AutoAttackEnabled = Value
        
        if Value then
            if not AttackConnection then
                AttackConnection = RunService.Heartbeat:Connect(autoAttack)
            end
        end
    end
})

local CooldownSlider = Tabs.Farm:AddSlider("AttackCooldown", {
    Title = "Attack Cooldown",
    Description = "Tempo entre ataques (segundos)",
    Default = 0.2,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Callback = function(Value)
        AttackCooldown = Value
    end
})

local RangeSlider = Tabs.Farm:AddSlider("AttackRange", {
    Title = "Attack Range",
    Description = "Alcance do ataque (studs)",
    Default = 20,
    Min = 5,
    Max = 450,
    Rounding = 0,
    Callback = function(Value)
        AttackRange = Value
    end
})

local MovementSection = Tabs.Farm:AddSection("Movement")

local TweenToggle = Tabs.Farm:AddToggle("TweenToMob", {
    Title = "Tween to Mob",
    Description = "Move automaticamente até os NPCs",
    Default = false,
    Callback = function(Value)
        TweenToMobEnabled = Value
        
        if Value then
            Fluent:Notify({
                Title = "Tween to Mob",
                Content = "Ativado! Seu personagem irá até os mobs.",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Tween to Mob",
                Content = "Desativado!",
                Duration = 2
            })
            
            if CurrentTween then
                CurrentTween:Cancel()
            end
        end
    end
})

local SpeedSlider = Tabs.Farm:AddSlider("TweenSpeed", {
    Title = "Tween Speed",
    Description = "Velocidade de movimento (studs/s)",
    Default = 100,
    Min = 50,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        TweenSpeed = Value
    end
})

local InventorySection = Tabs.Farm:AddSection("Inventory")

local SlotSlider = Tabs.Farm:AddSlider("InventorySlot", {
    Title = "Inventory Slot",
    Description = "",
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 0,
    Callback = function(Value)
        switchSlot(Value)
        Fluent:Notify({
            Title = "Slot Changed",
            Content = "Trocado para slot " .. Value,
            Duration = 1.5
        })
    end
})

local QuestSection = Tabs.Farm:AddSection("Auto Quest")

local NPCDropdown = Tabs.Farm:AddDropdown("SelectNPC", {
    Title = "Select Target Npc Quest",
    Description = "Escolha o NPC para farmar",
    Values = getNPCList(),
    Multi = false,
    Default = 1,
    Callback = function(Value)
        SelectedNPC = Value
        Fluent:Notify({
            Title = "NPC Selected",
            Content = "Alvo definido: " .. Value,
            Duration = 1.5
        })
    end
})

local AutoAcceptToggle = Tabs.Farm:AddToggle("AutoAcceptQuest", {
    Title = "Auto Quest",
    Description = "Aceita automaticamente a quest do NPC selecionado",
    Default = false,
    Callback = function(Value)
        AutoAcceptQuestEnabled = Value
    end
})

-- ===============================
-- STATS TAB
-- ===============================

local bb = Tabs.Stats:AddParagraph({
    Title = "Status",
    Content = "Farm pronto para uso. Ative o toggle acima para começar."
})

local lastText = ""
local startTime = os.clock()

task.spawn(function()
    while task.wait(1) do
        if not bb or not bb.SetDesc then
            break
        end

        local slot = CurrentSlot or 0
        local cooldown = AttackCooldown or 0
        local range = AttackRange or 0
        local questTarget = SelectedNPC or "N/A"

        local questStatus = AutoQuestEnabled and ("Enabled (" .. questTarget .. ")") or "Disabled"
        local autoAcceptStatus = AutoAcceptQuestEnabled and "Enabled" or "Disabled"
        local autoExecuteStatus = AutoExecuteOnTeleport and "Enabled ✅" or "Disabled ❌"

        local elapsedTime = math.floor(os.clock() - startTime)
        local minutes = math.floor(elapsedTime / 60)
        local seconds = elapsedTime % 60
        local formattedTime = string.format("%02d:%02d", minutes, seconds)

        local text

        if AutoAttackEnabled then
            local npc, dist = getNearestNPC()

            if npc then
                text = string.format(
                    "Kill Aura: Enabled\n" ..
                    "Target: %s\n" ..
                    "Distance: %.1f studs\n" ..
                    "Cooldown: %.1f s\n" ..
                    "Tween To Target: %s\n" ..
                    "Slot: %d\n" ..
                    "Quest Target: %s\n" ..
                    "Auto Accept Quest: %s\n" ..
                    "Auto Execute: %s\n" ..
                    "Executor: %s\n" ..
                    "Active Time: %s",
                    npc.Name,
                    dist or 0,
                    cooldown,
                    TweenToMobEnabled and "Enabled" or "Disabled",
                    slot,
                    questTarget,
                    autoAcceptStatus,
                    autoExecuteStatus,
                    ExecutorName,
                    formattedTime
                )
            else
                text = string.format(
                    "Kill Aura: Enabled\n" ..
                    "No NPC in range\n" ..
                    "Range: %.0f studs\n" ..
                    "Cooldown: %.1f s\n" ..
                    "Tween To Target: %s\n" ..
                    "Slot: %d\n" ..
                    "Quest Target: %s\n" ..
                    "Auto Accept Quest: %s\n" ..
                    "Auto Execute: %s\n" ..
                    "Executor: %s\n" ..
                    "Active Time: %s",
                    range,
                    cooldown,
                    TweenToMobEnabled and "Enabled" or "Disabled",
                    slot,
                    questTarget,
                    autoAcceptStatus,
                    autoExecuteStatus,
                    ExecutorName,
                    formattedTime
                )
            end
        else
            text = string.format(
                "Kill Aura: Disabled\n" ..
                "Current Slot: %d\n" ..
                "Quest Target: %s\n" ..
                "Auto Accept Quest: %s\n" ..
                "Auto Execute: %s\n" ..
                "Executor: %s\n" ..
                "Active Time: %s",
                slot,
                questTarget,
                autoAcceptStatus,
                autoExecuteStatus,
                ExecutorName,
                formattedTime
            )
        end

        if text ~= lastText then
            lastText = text
            bb:SetDesc(text)
        end
    end
end)

-- ===============================
-- SETTINGS TAB
-- ===============================

local AutoExecSection = Tabs.Settings:AddSection("Auto Execute on Teleport")

-- Toggle de Auto Execute
local AutoExecToggle = Tabs.Settings:AddToggle("AutoExecuteToggle", {
    Title = "Auto Execute on Teleport",
    Description = IsExecutorSupported 
        and "Reexecuta o script automaticamente após qualquer teleport" 
        or "⚠️ Seu executor não suporta queue_on_teleport!",
    Default = false,
    Callback = function(Value)
        if not IsExecutorSupported then
            Fluent:Notify({
                Title = "❌ Erro",
                Content = "Seu executor (" .. ExecutorName .. ") não suporta esta função!",
                Duration = 4
            })
            -- Desativa o toggle se não for suportado
            if AutoExecToggle and AutoExecToggle.SetValue then
                AutoExecToggle:SetValue(false)
            end
            return
        end
        
        AutoExecuteOnTeleport = Value
        
        if Value then
            -- Faz o queue imediatamente quando ativa
            local success = queueScriptForTeleport()
            
            if success then
                Fluent:Notify({
                    Title = "✅ Auto Execute Ativado",
                    Content = "O script será recarregado automaticamente após teleport!",
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "⚠️ Aviso",
                    Content = "Não foi possível fazer queue do script.",
                    Duration = 3
                })
            end
        else
            Fluent:Notify({
                Title = "Auto Execute",
                Content = "Desativado!",
                Duration = 2
            })
        end
    end
})

-- Input para URL do Script
Tabs.Settings:AddInput("ScriptURLInput", {
    Title = "Script URL",
    Description = "Cole a URL raw do seu script aqui",
    Default = SCRIPT_URL,
    Placeholder = "https://raw.githubusercontent.com/LeviMods64/uiLIB/refs/heads/main/kill%20hub.lua",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        if Value and Value ~= "" then
            SCRIPT_URL = Value
            
            -- Se auto execute estiver ativo, refaz o queue
            if AutoExecuteOnTeleport then
                queueScriptForTeleport()
            end
            
            Fluent:Notify({
                Title = "URL Salva",
                Content = "Script URL atualizada com sucesso!",
                Duration = 2
            })
        end
    end
})

-- Informações do Executor
Tabs.Settings:AddParagraph({
    Title = "📊 Informações do Executor",
    Content = "Executor Detectado: " .. ExecutorName .. 
              "\nQueue Suportado: " .. (IsExecutorSupported and "✅ Sim" or "❌ Não") ..
              "\nPlaceId Atual: " .. game.PlaceId
})

-- Botão para testar teleport queue
Tabs.Settings:AddButton({
    Title = "🔄 Testar Queue",
    Description = "Testa se o queue está funcionando corretamente",
    Callback = function()
        if not IsExecutorSupported then
            Fluent:Notify({
                Title = "❌ Não Suportado",
                Content = "Seu executor não suporta queue_on_teleport",
                Duration = 3
            })
            return
        end
        
        local success = queueScriptForTeleport()
        
        Fluent:Notify({
            Title = success and "✅ Sucesso" or "❌ Falha",
            Content = success 
                and "Queue funcionando! O script será executado após teleport." 
                or "Falha ao fazer queue do script.",
            Duration = 3
        })
    end
})

-- ===============================
-- MANAGERS LOAD
-- ===============================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("KillHub")
SaveManager:SetFolder("KillHub/JujutsuZero")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

SaveManager:LoadAutoloadConfig()

-- ===============================
-- NOTIFICAÇÃO INICIAL
-- ===============================
Fluent:Notify({
    Title = "Kill Hub",
    Content = "Script carregado com sucesso!\nExecutor: " .. ExecutorName,
    Duration = 4
})-- ===============================
-- LIBRARIES
-- ===============================
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ===============================
-- SERVICES
-- ===============================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- ===============================
-- AUTO ATTACK VARIABLES
-- ===============================
local AutoAttackEnabled = false
local AttackCooldown = 0.5
local AttackRange = 20
local LastAttackTime = 0
local AttackConnection = nil
local TweenToMobEnabled = false
local TweenSpeed = 100
local CurrentTween = nil
local CurrentSlot = 0
local AutoQuestEnabled = false
local SelectedNPC = nil
local AutoAcceptQuestEnabled = false

-- ===============================
-- AUTO EXECUTE ON TELEPORT SYSTEM
-- ===============================
local AutoExecuteOnTeleport = false

-- ⚠️ IMPORTANTE: Coloque aqui a URL RAW do seu script!
local SCRIPT_URL = "COLE_AQUI_SUA_URL_DO_SCRIPT"
-- Exemplo: "https://raw.githubusercontent.com/seuuser/seurepo/main/script.lua"

-- Função para obter queue_on_teleport compatível
local function getQueueFunction()
    if syn and syn.queue_on_teleport then
        return syn.queue_on_teleport, "Synapse X"
    elseif queue_on_teleport then
        return queue_on_teleport, "Generic"
    elseif fluxus and fluxus.queue_on_teleport then
        return fluxus.queue_on_teleport, "Fluxus"
    elseif getgenv and getgenv().queue_on_teleport then
        return getgenv().queue_on_teleport, "GetGenv"
    elseif KRNL_LOADED and queue_on_teleport then
        return queue_on_teleport, "KRNL"
    end
    return nil, "Não Suportado"
end

local QueueFunction, ExecutorName = getQueueFunction()
local IsExecutorSupported = QueueFunction ~= nil

-- Função para fazer queue do script
local function queueScriptForTeleport()
    if not QueueFunction then
        warn("[AutoExecute] Executor não suporta queue_on_teleport!")
        return false
    end
    
    if not AutoExecuteOnTeleport then
        return false
    end
    
    local scriptCode = [[
-- ======================================
-- AUTO EXECUTE - Kill Hub
-- Executado automaticamente após teleport
-- ======================================

repeat task.wait() until game:IsLoaded()
task.wait(3) -- Espera o jogo carregar completamente

local success, err = pcall(function()
    loadstring(game:HttpGet("]] .. SCRIPT_URL .. [["))()
end)

if not success then
    warn("[AutoExecute] Erro: " .. tostring(err))
end
]]
    
    QueueFunction(scriptCode)
    print("[AutoExecute] Script em queue para próximo teleport!")
    return true
end

-- Detectar teleport
LocalPlayer.OnTeleport:Connect(function(state, placeId, spawnName)
    if state == Enum.TeleportState.Started then
        if AutoExecuteOnTeleport then
            print("[AutoExecute] Teleport detectado para PlaceId:", placeId)
            queueScriptForTeleport()
        end
    end
end)

-- ===============================
-- WINDOW SETUP
-- ===============================
local MarketplaceService = game:GetService("MarketplaceService")
local Player = Players.LocalPlayer
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
local DeveloperName = "papa_killll"

local UserTitle, UserSubtitle, UserColor

if Player.Name == DeveloperName then
    UserTitle = DeveloperName
    UserSubtitle = "Developer"
    UserColor = Color3.fromRGB(255, 85, 85)
else
    UserTitle = Player.DisplayName
    UserSubtitle = "User"
    UserColor = Color3.fromRGB(71, 123, 255)
end

local Window = Fluent:CreateWindow({
    Title = "Kill Hub",
    SubTitle = "| " .. GameName .. " | by MrJimex",
    Search = true,
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Arctic",
    MinimizeKey = Enum.KeyCode.LeftControl,
    UserInfo = true,
    UserInfoTop = true,
    UserInfoTitle = UserTitle,
    UserInfoSubtitle = UserSubtitle,
    UserInfoSubtitleColor = UserColor
})

local Minimizer = Fluent:CreateMinimizer({
    Icon = "",
    Size = UDim2.fromOffset(44, 44),
    Position = UDim2.new(0, 320, 0, 24),
    Acrylic = true,
    Corner = 10,
    Transparency = 1,
    Draggable = true,
    Visible = true
})

local Tabs = {
    Farm = Window:AddTab({ Title = "Farm", Icon = "swords" }),
    Stats = Window:AddTab({ Title = "Status", Icon = "server" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- ===============================
-- CORE FUNCTIONS
-- ===============================

function getNil(name, class)
    for _, v in pairs(getnilinstances()) do
        if v.ClassName == class and v.Name == name then
            return v
        end
    end
end

local function getLocalServerCharacter()
    local serverPlayers = Workspace.Characters.Server.Players:GetChildren()
    
    for _, char in pairs(serverPlayers) do
        if char.Name:find(LocalPlayer.Name) or char.Name:find("Server") then
            return char
        end
    end
    
    return serverPlayers[1]
end

local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function switchSlot(slotNumber)
    pcall(function()
        local Event = ReplicatedStorage.NetworkComm.InventoryService.FocusItem_Method
        Event:InvokeServer(slotNumber)
        CurrentSlot = slotNumber
    end)
end

local function acceptQuest(npcName)
    if not npcName then return false end
    
    pcall(function()
        local Event = ReplicatedStorage.NetworkComm.QuestService.AcceptQuest_Method
        Event:InvokeServer(npcName)
    end)
    
    return true
end

local function getNPCList()
    local npcList = {}
    local npcFolder = ReplicatedStorage.Assets.Models.Characters.Humanoid.NPCs
    
    if npcFolder then
        for _, npc in pairs(npcFolder:GetChildren()) do
            if npc:IsA("Model") then
                table.insert(npcList, npc.Name)
            end
        end
    end
    
    table.sort(npcList)
    return npcList
end

local function getNearestNPC()
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local localPos = localChar.HumanoidRootPart.Position
    local nearestNPC = nil
    local shortestDistance = math.huge
    
    if not TweenToMobEnabled then
        shortestDistance = AttackRange
    end
    
    local npcsFolder = Workspace.Characters.Server.NPCs
    if not npcsFolder then return nil end
    
    for _, npc in pairs(npcsFolder:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") then
            if AutoQuestEnabled and SelectedNPC and npc.Name ~= SelectedNPC then
                continue
            end
            
            local humanoid = npc.Humanoid
            
            if humanoid.Health > 0 and npc:FindFirstChild("HumanoidRootPart") then
                local distance = getDistance(localPos, npc.HumanoidRootPart.Position)
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestNPC = npc
                end
            end
        end
    end
    
    return nearestNPC, shortestDistance
end

local function performStartSkill(targetNPC)
    local localChar = getLocalServerCharacter()
    if not localChar then return false end
    
    pcall(function()
        local args = {
            [1] = "Punch",
            [2] = localChar,
            [3] = Vector3.new(0.918032169342041, 0, 0.3965059816837311),
            [4] = 1,
            [5] = 1
        }
        ReplicatedStorage.NetworkComm.SkillService.StartSkilll_Method:InvokeServer(unpack(args))
    end)
    
    return true
end

local function performDamage(targetNPC)
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return false end
    
    pcall(function()
        local args = {
            [1] = { [1] = targetNPC },
            [2] = true,
            [3] = {
                ["CanParry"] = false,
                ["OnCharacterHit"] = function() end,
                ["Origin"] = localChar.HumanoidRootPart.CFrame,
                ["LocalCharacter"] = localChar,
                ["WindowID"] = localChar.Name .. "_Punch",
                ["Parries"] = {},
                ["SkillID"] = "Punch"
            }
        }
        ReplicatedStorage.NetworkComm.CombatService.DamageCharacter_Method:InvokeServer(unpack(args))
    end)
    
    return true
end

local function tweenToMob(targetNPC)
    if not TweenToMobEnabled then return end
    
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return end
    if not targetNPC or not targetNPC:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPos = targetNPC.HumanoidRootPart.Position
    local currentPos = localChar.HumanoidRootPart.Position
    local distance = getDistance(currentPos, targetPos)
    
    if distance <= AttackRange * 0.8 then return end
    
    if CurrentTween then
        CurrentTween:Cancel()
    end
    
    local direction = (targetPos - currentPos).Unit
    local targetCFrame = CFrame.new(targetPos - (direction * (AttackRange * 0.6)))
    
    local tweenInfo = TweenInfo.new(
        distance / TweenSpeed,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    
    local TweenService = game:GetService("TweenService")
    CurrentTween = TweenService:Create(
        localChar.HumanoidRootPart,
        tweenInfo,
        {CFrame = targetCFrame}
    )
    
    CurrentTween:Play()
end

local function autoAttack()
    if not AutoAttackEnabled then return end
    
    local currentTime = tick()
    
    if AutoAcceptQuestEnabled and SelectedNPC then
        acceptQuest(SelectedNPC)
    end
    
    if currentTime - LastAttackTime < AttackCooldown then
        return
    end
    
    local targetNPC, distance = getNearestNPC()
    
    if targetNPC then
        if TweenToMobEnabled and distance > AttackRange * 0.8 then
            tweenToMob(targetNPC)
            task.wait(0.1)
        end
        
        local localChar = getLocalServerCharacter()
        if localChar and localChar:FindFirstChild("HumanoidRootPart") then
            local currentDist = getDistance(
                localChar.HumanoidRootPart.Position,
                targetNPC.HumanoidRootPart.Position
            )
            
            if currentDist <= AttackRange then
                performStartSkill(targetNPC)
                task.wait(0.05)
                performDamage(targetNPC)
                
                LastAttackTime = currentTime
            end
        end
    end
end

-- ===============================
-- FARM TAB UI
-- ===============================

local AutoAttackSection = Tabs.Farm:AddSection("Auto Attack")

local AutoAttackToggle = Tabs.Farm:AddToggle("AutoAttack", {
    Title = "Kill Aura",
    Description = "Ataca automaticamente NPCs próximos",
    Default = false,
    Callback = function(Value)
        AutoAttackEnabled = Value
        
        if Value then
            if not AttackConnection then
                AttackConnection = RunService.Heartbeat:Connect(autoAttack)
            end
        end
    end
})

local CooldownSlider = Tabs.Farm:AddSlider("AttackCooldown", {
    Title = "Attack Cooldown",
    Description = "Tempo entre ataques (segundos)",
    Default = 0.2,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Callback = function(Value)
        AttackCooldown = Value
    end
})

local RangeSlider = Tabs.Farm:AddSlider("AttackRange", {
    Title = "Attack Range",
    Description = "Alcance do ataque (studs)",
    Default = 20,
    Min = 5,
    Max = 450,
    Rounding = 0,
    Callback = function(Value)
        AttackRange = Value
    end
})

local MovementSection = Tabs.Farm:AddSection("Movement")

local TweenToggle = Tabs.Farm:AddToggle("TweenToMob", {
    Title = "Tween to Mob",
    Description = "Move automaticamente até os NPCs",
    Default = false,
    Callback = function(Value)
        TweenToMobEnabled = Value
        
        if Value then
            Fluent:Notify({
                Title = "Tween to Mob",
                Content = "Ativado! Seu personagem irá até os mobs.",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Tween to Mob",
                Content = "Desativado!",
                Duration = 2
            })
            
            if CurrentTween then
                CurrentTween:Cancel()
            end
        end
    end
})

local SpeedSlider = Tabs.Farm:AddSlider("TweenSpeed", {
    Title = "Tween Speed",
    Description = "Velocidade de movimento (studs/s)",
    Default = 100,
    Min = 50,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        TweenSpeed = Value
    end
})

local InventorySection = Tabs.Farm:AddSection("Inventory")

local SlotSlider = Tabs.Farm:AddSlider("InventorySlot", {
    Title = "Inventory Slot",
    Description = "",
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 0,
    Callback = function(Value)
        switchSlot(Value)
        Fluent:Notify({
            Title = "Slot Changed",
            Content = "Trocado para slot " .. Value,
            Duration = 1.5
        })
    end
})

local QuestSection = Tabs.Farm:AddSection("Auto Quest")

local NPCDropdown = Tabs.Farm:AddDropdown("SelectNPC", {
    Title = "Select Target Npc Quest",
    Description = "Escolha o NPC para farmar",
    Values = getNPCList(),
    Multi = false,
    Default = 1,
    Callback = function(Value)
        SelectedNPC = Value
        Fluent:Notify({
            Title = "NPC Selected",
            Content = "Alvo definido: " .. Value,
            Duration = 1.5
        })
    end
})

local AutoAcceptToggle = Tabs.Farm:AddToggle("AutoAcceptQuest", {
    Title = "Auto Quest",
    Description = "Aceita automaticamente a quest do NPC selecionado",
    Default = false,
    Callback = function(Value)
        AutoAcceptQuestEnabled = Value
    end
})

-- ===============================
-- STATS TAB
-- ===============================

local bb = Tabs.Stats:AddParagraph({
    Title = "Status",
    Content = "Farm pronto para uso. Ative o toggle acima para começar."
})

local lastText = ""
local startTime = os.clock()

task.spawn(function()
    while task.wait(1) do
        if not bb or not bb.SetDesc then
            break
        end

        local slot = CurrentSlot or 0
        local cooldown = AttackCooldown or 0
        local range = AttackRange or 0
        local questTarget = SelectedNPC or "N/A"

        local questStatus = AutoQuestEnabled and ("Enabled (" .. questTarget .. ")") or "Disabled"
        local autoAcceptStatus = AutoAcceptQuestEnabled and "Enabled" or "Disabled"
        local autoExecuteStatus = AutoExecuteOnTeleport and "Enabled ✅" or "Disabled ❌"

        local elapsedTime = math.floor(os.clock() - startTime)
        local minutes = math.floor(elapsedTime / 60)
        local seconds = elapsedTime % 60
        local formattedTime = string.format("%02d:%02d", minutes, seconds)

        local text

        if AutoAttackEnabled then
            local npc, dist = getNearestNPC()

            if npc then
                text = string.format(
                    "Kill Aura: Enabled\n" ..
                    "Target: %s\n" ..
                    "Distance: %.1f studs\n" ..
                    "Cooldown: %.1f s\n" ..
                    "Tween To Target: %s\n" ..
                    "Slot: %d\n" ..
                    "Quest Target: %s\n" ..
                    "Auto Accept Quest: %s\n" ..
                    "Auto Execute: %s\n" ..
                    "Executor: %s\n" ..
                    "Active Time: %s",
                    npc.Name,
                    dist or 0,
                    cooldown,
                    TweenToMobEnabled and "Enabled" or "Disabled",
                    slot,
                    questTarget,
                    autoAcceptStatus,
                    autoExecuteStatus,
                    ExecutorName,
                    formattedTime
                )
            else
                text = string.format(
                    "Kill Aura: Enabled\n" ..
                    "No NPC in range\n" ..
                    "Range: %.0f studs\n" ..
                    "Cooldown: %.1f s\n" ..
                    "Tween To Target: %s\n" ..
                    "Slot: %d\n" ..
                    "Quest Target: %s\n" ..
                    "Auto Accept Quest: %s\n" ..
                    "Auto Execute: %s\n" ..
                    "Executor: %s\n" ..
                    "Active Time: %s",
                    range,
                    cooldown,
                    TweenToMobEnabled and "Enabled" or "Disabled",
                    slot,
                    questTarget,
                    autoAcceptStatus,
                    autoExecuteStatus,
                    ExecutorName,
                    formattedTime
                )
            end
        else
            text = string.format(
                "Kill Aura: Disabled\n" ..
                "Current Slot: %d\n" ..
                "Quest Target: %s\n" ..
                "Auto Accept Quest: %s\n" ..
                "Auto Execute: %s\n" ..
                "Executor: %s\n" ..
                "Active Time: %s",
                slot,
                questTarget,
                autoAcceptStatus,
                autoExecuteStatus,
                ExecutorName,
                formattedTime
            )
        end

        if text ~= lastText then
            lastText = text
            bb:SetDesc(text)
        end
    end
end)

-- ===============================
-- SETTINGS TAB
-- ===============================

local AutoExecSection = Tabs.Settings:AddSection("Auto Execute on Teleport")

-- Toggle de Auto Execute
local AutoExecToggle = Tabs.Settings:AddToggle("AutoExecuteToggle", {
    Title = "Auto Execute on Teleport",
    Description = IsExecutorSupported 
        and "Reexecuta o script automaticamente após qualquer teleport" 
        or "⚠️ Seu executor não suporta queue_on_teleport!",
    Default = false,
    Callback = function(Value)
        if not IsExecutorSupported then
            Fluent:Notify({
                Title = "❌ Erro",
                Content = "Seu executor (" .. ExecutorName .. ") não suporta esta função!",
                Duration = 4
            })
            -- Desativa o toggle se não for suportado
            if AutoExecToggle and AutoExecToggle.SetValue then
                AutoExecToggle:SetValue(false)
            end
            return
        end
        
        AutoExecuteOnTeleport = Value
        
        if Value then
            -- Faz o queue imediatamente quando ativa
            local success = queueScriptForTeleport()
            
            if success then
                Fluent:Notify({
                    Title = "✅ Auto Execute Ativado",
                    Content = "O script será recarregado automaticamente após teleport!",
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "⚠️ Aviso",
                    Content = "Não foi possível fazer queue do script.",
                    Duration = 3
                })
            end
        else
            Fluent:Notify({
                Title = "Auto Execute",
                Content = "Desativado!",
                Duration = 2
            })
        end
    end
})

-- Input para URL do Script
Tabs.Settings:AddInput("ScriptURLInput", {
    Title = "Script URL",
    Description = "Cole a URL raw do seu script aqui",
    Default = SCRIPT_URL,
    Placeholder = "https://raw.githubusercontent.com/LeviMods64/uiLIB/refs/heads/main/kill%20hub.lua",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        if Value and Value ~= "" then
            SCRIPT_URL = Value
            
            -- Se auto execute estiver ativo, refaz o queue
            if AutoExecuteOnTeleport then
                queueScriptForTeleport()
            end
            
            Fluent:Notify({
                Title = "URL Salva",
                Content = "Script URL atualizada com sucesso!",
                Duration = 2
            })
        end
    end
})

-- Informações do Executor
Tabs.Settings:AddParagraph({
    Title = "📊 Informações do Executor",
    Content = "Executor Detectado: " .. ExecutorName .. 
              "\nQueue Suportado: " .. (IsExecutorSupported and "✅ Sim" or "❌ Não") ..
              "\nPlaceId Atual: " .. game.PlaceId
})

-- Botão para testar teleport queue
Tabs.Settings:AddButton({
    Title = "🔄 Testar Queue",
    Description = "Testa se o queue está funcionando corretamente",
    Callback = function()
        if not IsExecutorSupported then
            Fluent:Notify({
                Title = "❌ Não Suportado",
                Content = "Seu executor não suporta queue_on_teleport",
                Duration = 3
            })
            return
        end
        
        local success = queueScriptForTeleport()
        
        Fluent:Notify({
            Title = success and "✅ Sucesso" or "❌ Falha",
            Content = success 
                and "Queue funcionando! O script será executado após teleport." 
                or "Falha ao fazer queue do script.",
            Duration = 3
        })
    end
})

-- ===============================
-- MANAGERS LOAD
-- ===============================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("KillHub")
SaveManager:SetFolder("KillHub/JujutsuZero")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

SaveManager:LoadAutoloadConfig()

-- ===============================
-- NOTIFICAÇÃO INICIAL
-- ===============================
Fluent:Notify({
    Title = "Kill Hub",
    Content = "Script carregado com sucesso!\nExecutor: " .. ExecutorName,
    Duration = 4
})
