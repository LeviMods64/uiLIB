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
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- ===============================
-- FARM VARIABLES
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
local UseFugaSkill = false
local CurrentSkill = "Punch"

-- ===============================
-- RAID VARIABLES (SEPARADO)
-- ===============================
local RaidAutoAttackEnabled = false
local RaidAttackCooldown = 0.3
local RaidAttackRange = 50
local RaidLastAttackTime = 0
local RaidAttackConnection = nil
local RaidTweenToMobEnabled = false
local RaidTweenSpeed = 150
local RaidCurrentTween = nil
local RaidUseFugaSkill = false
local RaidCurrentSkill = "Punch"

-- ===============================
-- AUTO EXECUTE ON TELEPORT SYSTEM
-- ===============================
local AutoExecuteOnTeleport = false
local SCRIPT_URL = "https://raw.githubusercontent.com/LeviMods64/uiLIB/refs/heads/main/kill%20hub.lua"

-- Função para obter queue_on_teleport compatível
local function getQueueFunction()
    if syn and syn.queue_on_teleport then
        return syn.queue_on_teleport, "Synapse X"
    end
    
    if fluxus and fluxus.queue_on_teleport then
        return fluxus.queue_on_teleport, "Fluxus"
    end
    
    if delta and delta.queue_on_teleport then
        return delta.queue_on_teleport, "Delta"
    end
    
    if Hydrogen and Hydrogen.queue_on_teleport then
        return Hydrogen.queue_on_teleport, "Hydrogen"
    end
    
    if queue_on_teleport then
        return queue_on_teleport, "Generic"
    end
    
    if getgenv and getgenv().queue_on_teleport then
        return getgenv().queue_on_teleport, "Getgenv"
    end
    
    local executorName = "Não Suportado"
    pcall(function()
        if identifyexecutor then
            executorName = identifyexecutor()
        elseif getexecutorname then
            executorName = getexecutorname()
        end
    end)
    
    return nil, executorName
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
repeat task.wait() until game:IsLoaded()
task.wait(3)

local success, err = pcall(function()
    loadstring(game:HttpGet("]] .. SCRIPT_URL .. [["))()
end)

if not success then
    warn("[AutoExecute] Erro ao carregar: " .. tostring(err))
end
]]
    
    local success = pcall(function()
        QueueFunction(scriptCode)
    end)
    
    if success then
        print("[AutoExecute]  Script em queue para próximo teleport!")
    end
    
    return success
end

-- Detectar teleport
LocalPlayer.OnTeleport:Connect(function(state, placeId, spawnName)
    if state == Enum.TeleportState.Started then
        if AutoExecuteOnTeleport then
            print("[AutoExecute]  Teleport detectado para PlaceId:", placeId)
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
    Raid = Window:AddTab({ Title = "Raid", Icon = "skull" }),  -- NOVA ABA
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
    local success, result = pcall(function()
        local serverPlayers = Workspace.Characters.Server.Players:GetChildren()
        
        for _, char in pairs(serverPlayers) do
            if char.Name:find(LocalPlayer.Name) or char.Name:find("Server") then
                return char
            end
        end
        
        return serverPlayers[1]
    end)
    
    return success and result or nil
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
    
    pcall(function()
        local npcFolder = ReplicatedStorage.Assets.Models.Characters.Humanoid.NPCs
        
        if npcFolder then
            for _, npc in pairs(npcFolder:GetChildren()) do
                if npc:IsA("Model") then
                    table.insert(npcList, npc.Name)
                end
            end
        end
    end)
    
    table.sort(npcList)
    return npcList
end

-- ===============================
-- FARM: GET NEAREST NPC
-- ===============================
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
    
    pcall(function()
        local npcsFolder = Workspace.Characters.Server.NPCs
        if not npcsFolder then return end
        
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
    end)
    
    return nearestNPC, shortestDistance
end

-- ===============================
-- RAID: GET NEAREST ENEMY (NPCs + Players/Bosses)
-- ===============================
local function getRaidNearestEnemy()
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local localPos = localChar.HumanoidRootPart.Position
    local nearestEnemy = nil
    local shortestDistance = math.huge
    
    if not RaidTweenToMobEnabled then
        shortestDistance = RaidAttackRange
    end
    
    pcall(function()
        -- Procurar em NPCs
        local npcsFolder = Workspace.Characters.Server.NPCs
        if npcsFolder then
            for _, npc in pairs(npcsFolder:GetChildren()) do
                if npc:IsA("Model") and npc:FindFirstChild("Humanoid") then
                    local humanoid = npc.Humanoid
                    
                    if humanoid.Health > 0 and npc:FindFirstChild("HumanoidRootPart") then
                        local distance = getDistance(localPos, npc.HumanoidRootPart.Position)
                        
                        if distance < shortestDistance then
                            shortestDistance = distance
                            nearestEnemy = npc
                        end
                    end
                end
            end
        end
        
        -- Procurar Bosses (se existir pasta)
        local bossesFolder = Workspace.Characters.Server:FindFirstChild("Bosses")
        if bossesFolder then
            for _, boss in pairs(bossesFolder:GetChildren()) do
                if boss:IsA("Model") and boss:FindFirstChild("Humanoid") then
                    local humanoid = boss.Humanoid
                    
                    if humanoid.Health > 0 and boss:FindFirstChild("HumanoidRootPart") then
                        local distance = getDistance(localPos, boss.HumanoidRootPart.Position)
                        
                        if distance < shortestDistance then
                            shortestDistance = distance
                            nearestEnemy = boss
                        end
                    end
                end
            end
        end
    end)
    
    return nearestEnemy, shortestDistance
end

-- ===============================
-- FARM: SKILL FUNCTIONS
-- ===============================

local function performStartSkill(targetNPC)
    local localChar = getLocalServerCharacter()
    if not localChar then return false end
    
    pcall(function()
        local skillName = UseFugaSkill and "Fuga" or "Punch"
        CurrentSkill = skillName
        
        local args = {
            [1] = skillName,
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
        local skillName = UseFugaSkill and "Fuga" or "Punch"
        CurrentSkill = skillName
        
        local args = {
            [1] = { [1] = targetNPC },
            [2] = true,
            [3] = {
                ["CanParry"] = false,
                ["OnCharacterHit"] = function() end,
                ["Origin"] = localChar.HumanoidRootPart.CFrame,
                ["LocalCharacter"] = localChar,
                ["WindowID"] = localChar.Name .. "_" .. skillName,
                ["Parries"] = {},
                ["SkillID"] = skillName
            }
        }
        ReplicatedStorage.NetworkComm.CombatService.DamageCharacter_Method:InvokeServer(unpack(args))
    end)
    
    return true
end

-- ===============================
-- RAID: SKILL FUNCTIONS
-- ===============================

local function raidPerformStartSkill(targetNPC)
    local localChar = getLocalServerCharacter()
    if not localChar then return false end
    
    pcall(function()
        local skillName = RaidUseFugaSkill and "Fuga" or "Punch"
        RaidCurrentSkill = skillName
        
        local args = {
            [1] = skillName,
            [2] = localChar,
            [3] = Vector3.new(0.918032169342041, 0, 0.3965059816837311),
            [4] = 1,
            [5] = 1
        }
        ReplicatedStorage.NetworkComm.SkillService.StartSkilll_Method:InvokeServer(unpack(args))
    end)
    
    return true
end

local function raidPerformDamage(targetNPC)
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return false end
    
    pcall(function()
        local skillName = RaidUseFugaSkill and "Fuga" or "Punch"
        RaidCurrentSkill = skillName
        
        local args = {
            [1] = { [1] = targetNPC },
            [2] = true,
            [3] = {
                ["CanParry"] = false,
                ["OnCharacterHit"] = function() end,
                ["Origin"] = localChar.HumanoidRootPart.CFrame,
                ["LocalCharacter"] = localChar,
                ["WindowID"] = localChar.Name .. "_" .. skillName,
                ["Parries"] = {},
                ["SkillID"] = skillName
            }
        }
        ReplicatedStorage.NetworkComm.CombatService.DamageCharacter_Method:InvokeServer(unpack(args))
    end)
    
    return true
end

-- ===============================
-- FARM: TWEEN TO MOB
-- ===============================

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
    
    CurrentTween = TweenService:Create(
        localChar.HumanoidRootPart,
        tweenInfo,
        {CFrame = targetCFrame}
    )
    
    CurrentTween:Play()
end

-- ===============================
-- RAID: TWEEN TO MOB
-- ===============================

local function raidTweenToMob(targetNPC)
    if not RaidTweenToMobEnabled then return end
    
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return end
    if not targetNPC or not targetNPC:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPos = targetNPC.HumanoidRootPart.Position
    local currentPos = localChar.HumanoidRootPart.Position
    local distance = getDistance(currentPos, targetPos)
    
    if distance <= RaidAttackRange * 0.8 then return end
    
    if RaidCurrentTween then
        RaidCurrentTween:Cancel()
    end
    
    local direction = (targetPos - currentPos).Unit
    local targetCFrame = CFrame.new(targetPos - (direction * (RaidAttackRange * 0.6)))
    
    local tweenInfo = TweenInfo.new(
        distance / RaidTweenSpeed,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    
    RaidCurrentTween = TweenService:Create(
        localChar.HumanoidRootPart,
        tweenInfo,
        {CFrame = targetCFrame}
    )
    
    RaidCurrentTween:Play()
end

-- ===============================
-- FARM: AUTO ATTACK LOOP
-- ===============================

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
-- RAID: AUTO ATTACK LOOP
-- ===============================

local function raidAutoAttack()
    if not RaidAutoAttackEnabled then return end
    
    local currentTime = tick()
    
    if currentTime - RaidLastAttackTime < RaidAttackCooldown then
        return
    end
    
    local targetEnemy, distance = getRaidNearestEnemy()
    
    if targetEnemy then
        if RaidTweenToMobEnabled and distance > RaidAttackRange * 0.8 then
            raidTweenToMob(targetEnemy)
            task.wait(0.1)
        end
        
        local localChar = getLocalServerCharacter()
        if localChar and localChar:FindFirstChild("HumanoidRootPart") then
            local currentDist = getDistance(
                localChar.HumanoidRootPart.Position,
                targetEnemy.HumanoidRootPart.Position
            )
            
            if currentDist <= RaidAttackRange then
                raidPerformStartSkill(targetEnemy)
                task.wait(0.05)
                raidPerformDamage(targetEnemy)
                
                RaidLastAttackTime = currentTime
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

local FugaToggle = Tabs.Farm:AddToggle("UseFuga", {
    Title = "Fuga Skill Aura (Need Shrine CT)",
    Description = "Troca de Punch para Fuga (mais dano)",
    Default = false,
    Callback = function(Value)
        UseFugaSkill = Value
        CurrentSkill = Value and "Fuga" or "Punch"
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
        
        if not Value and CurrentTween then
            CurrentTween:Cancel()
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
-- RAID TAB UI (NOVA ABA)
-- ===============================

local RaidAttackSection = Tabs.Raid:AddSection(" Raid Auto Attack")

local RaidAutoAttackToggle = Tabs.Raid:AddToggle("RaidAutoAttack", {
    Title = "Raid Kill Aura",
    Description = "Ataca automaticamente inimigos na Raid",
    Default = false,
    Callback = function(Value)
        RaidAutoAttackEnabled = Value
        
        if Value then
            if not RaidAttackConnection then
                RaidAttackConnection = RunService.Heartbeat:Connect(raidAutoAttack)
            end
            
            Fluent:Notify({
                Title = " Raid Kill Aura",
                Content = "Ativado! Atacando inimigos...",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Raid Kill Aura",
                Content = "Desativado!",
                Duration = 2
            })
        end
    end
})

local RaidFugaToggle = Tabs.Raid:AddToggle("RaidUseFuga", {
    Title = "Raid Fuga Skill (Need Shrine CT)",
    Description = "Usa Fuga ao invés de Punch na Raid",
    Default = false,
    Callback = function(Value)
        RaidUseFugaSkill = Value
        RaidCurrentSkill = Value and "Fuga" or "Punch"
        
        Fluent:Notify({
            Title = "Raid Skill",
            Content = "Usando: " .. RaidCurrentSkill,
            Duration = 2
        })
    end
})

local RaidCooldownSlider = Tabs.Raid:AddSlider("RaidAttackCooldown", {
    Title = "Raid Attack Cooldown",
    Description = "Tempo entre ataques na Raid (segundos)",
    Default = 0.3,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Callback = function(Value)
        RaidAttackCooldown = Value
    end
})

local RaidRangeSlider = Tabs.Raid:AddSlider("RaidAttackRange", {
    Title = "Raid Attack Range",
    Description = "Alcance do ataque na Raid (studs)",
    Default = 50,
    Min = 5,
    Max = 500,
    Rounding = 0,
    Callback = function(Value)
        RaidAttackRange = Value
    end
})

local RaidMovementSection = Tabs.Raid:AddSection(" Raid Movement")

local RaidTweenToggle = Tabs.Raid:AddToggle("RaidTweenToMob", {
    Title = "Raid Tween to Enemy",
    Description = "Move automaticamente até os inimigos na Raid",
    Default = false,
    Callback = function(Value)
        RaidTweenToMobEnabled = Value
        
        if Value then
            Fluent:Notify({
                Title = " Raid Tween",
                Content = "Ativado! Indo até os inimigos...",
                Duration = 2
            })
        else
            if RaidCurrentTween then
                RaidCurrentTween:Cancel()
            end
            
            Fluent:Notify({
                Title = "Raid Tween",
                Content = "Desativado!",
                Duration = 2
            })
        end
    end
})

local RaidSpeedSlider = Tabs.Raid:AddSlider("RaidTweenSpeed", {
    Title = "Raid Tween Speed",
    Description = "Velocidade de movimento na Raid (studs/s)",
    Default = 150,
    Min = 50,
    Max = 400,
    Rounding = 0,
    Callback = function(Value)
        RaidTweenSpeed = Value
    end
})

-- Info da Raid
Tabs.Raid:AddParagraph({
    Title = " Raid Info",
    Content = "Use esta aba para configurar o farm em Raids.\nAs configurações são separadas do Farm normal.\n\n Dica: Aumente o Range e Speed para Raids!"
})

-- ===============================
-- STATS TAB
-- ===============================

local bb = Tabs.Stats:AddParagraph({
    Title = "Status",
    Content = "Carregando..."
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
        local autoAcceptStatus = AutoAcceptQuestEnabled and "" or ""
        local autoExecuteStatus = AutoExecuteOnTeleport and "" or ""
        local tweenStatus = TweenToMobEnabled and "" or ""
        local skillName = UseFugaSkill and "Fuga " or "Punch "
        
        -- Raid Status
        local raidStatus = RaidAutoAttackEnabled and "" or ""
        local raidSkill = RaidUseFugaSkill and "Fuga " or "Punch "
        local raidTweenStatus = RaidTweenToMobEnabled and "" or ""

        local elapsedTime = math.floor(os.clock() - startTime)
        local minutes = math.floor(elapsedTime / 60)
        local seconds = elapsedTime % 60
        local formattedTime = string.format("%02d:%02d", minutes, seconds)

        local text

        if AutoAttackEnabled or RaidAutoAttackEnabled then
            local npc, dist = getNearestNPC()
            local raidEnemy, raidDist = getRaidNearestEnemy()

            text = string.format(
                " FARM \n" ..
                " Kill Aura: %s\n" ..
                " Target: %s\n" ..
                " Distance: %.1f studs\n" ..
                " Skill: %s\n" ..
                " Tween: %s\n" ..
                "\n RAID \n" ..
                " Raid Aura: %s\n" ..
                " Raid Target: %s\n" ..
                " Raid Distance: %.1f studs\n" ..
                " Raid Skill: %s\n" ..
                " Raid Tween: %s\n" ..
                "\n INFO \n" ..
                " Slot: %d\n" ..
                " Auto Quest: %s\n" ..
                " Auto Execute: %s\n" ..
                " Executor: %s\n" ..
                " Time: %s",
                AutoAttackEnabled and "" or "",
                npc and npc.Name or "Procurando...",
                dist or 0,
                skillName,
                tweenStatus,
                raidStatus,
                raidEnemy and raidEnemy.Name or "Procurando...",
                raidDist or 0,
                raidSkill,
                raidTweenStatus,
                slot,
                autoAcceptStatus,
                autoExecuteStatus,
                ExecutorName,
                formattedTime
            )
        else
            text = string.format(
                " FARM \n" ..
                " Kill Aura:  Disabled\n" ..
                " Skill: %s\n" ..
                "\n RAID \n" ..
                " Raid Aura:  Disabled\n" ..
                " Raid Skill: %s\n" ..
                "\n INFO \n" ..
                " Slot: %d\n" ..
                " Quest NPC: %s\n" ..
                " Auto Quest: %s\n" ..
                " Auto Execute: %s\n" ..
                " Executor: %s\n" ..
                " Time: %s",
                skillName,
                raidSkill,
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

local AutoExecSection = Tabs.Settings:AddSection("Auto Execute")

local AutoExecToggle = Tabs.Settings:AddToggle("AutoExecuteToggle", {
    Title = "Auto Execute on Teleport",
    Description = IsExecutorSupported 
        and " Reexecuta após teleport (Place/SubPlace)" 
        or " Executor não suporta: " .. ExecutorName,
    Default = false,
    Callback = function(Value)
        if not IsExecutorSupported then
            Fluent:Notify({
                Title = " Não Suportado",
                Content = "Seu executor (" .. ExecutorName .. ") não suporta queue_on_teleport!",
                Duration = 4
            })
            return
        end
        
        AutoExecuteOnTeleport = Value
        
        if Value then
            local success = queueScriptForTeleport()
            
            if success then
                Fluent:Notify({
                    Title = " Auto Execute",
                    Content = "Ativado! Script será recarregado após teleport.",
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

Tabs.Settings:AddParagraph({
    Title = " Executor Info",
    Content = "Executor: " .. ExecutorName .. 
              "\nQueue: " .. (IsExecutorSupported and " Suportado" or " Não Suportado") ..
              "\nPlaceId: " .. game.PlaceId
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
    Content = "Carregado com sucesso!\nExecutor: " .. ExecutorName,
    Duration = 4
})

print("[Kill Hub]  Script carregado!")
print("[Kill Hub] Executor:", ExecutorName)
print("[Kill Hub] Queue Suportado:", IsExecutorSupported)
