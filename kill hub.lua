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
-- PLAYER VARIABLES
-- ===============================
local SpeedEnabled = false
local SpeedValue = 16
local JumpPowerEnabled = false
local JumpPowerValue = 50
local DefaultWalkSpeed = 16
local DefaultJumpPower = 50
local PlayerSpeedConnection = nil
local SelectedPlayer = nil
local TweenToPlayerEnabled = false
local PlayerTweenSpeed = 200
local PlayerCurrentTween = nil

-- ===============================
-- FARM VARIABLES
-- ===============================
local AutoAttackEnabled = false
local AttackCooldown = 0.5
local AttackRange = 20
local LastAttackTime = 0
local AttackConnection = nil
local TweenToMobEnabled = false
local TweenSpeed = 200
local TweenOffset = 5
local CurrentTween = nil
local CurrentSlot = 0
local AutoQuestEnabled = false
local SelectedNPC = nil
local AutoAcceptQuestEnabled = false
local UseFugaSkill = false
local CurrentSkill = "Punch"

-- ===============================
-- RAID VARIABLES
-- ===============================
local RaidAutoAttackEnabled = false
local RaidAttackCooldown = 0.3
local RaidAttackRange = 50
local RaidLastAttackTime = 0
local RaidAttackConnection = nil
local RaidTweenToMobEnabled = false
local RaidTweenSpeed = 300
local RaidTweenOffset = 5
local RaidCurrentTween = nil
local RaidUseFugaSkill = false
local RaidCurrentSkill = "Punch"

-- ===============================
-- AUTO RETRY VARIABLES
-- ===============================
local HadMobsBefore = false
local IsRetrying = false

-- ===============================
-- AUTO EXECUTE ON TELEPORT SYSTEM
-- ===============================
local AutoExecuteOnTeleport = false
local SCRIPT_URL = "https://raw.githubusercontent.com/LeviMods64/uiLIB/refs/heads/main/kill%20hub.lua"

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

local function queueScriptForTeleport()
    if not QueueFunction then return false end
    if not AutoExecuteOnTeleport then return false end
    
    local scriptCode = [[
repeat task.wait() until game:IsLoaded()
task.wait(3)
pcall(function()
    loadstring(game:HttpGet("]] .. SCRIPT_URL .. [["))()
end)
]]
    
    pcall(function()
        QueueFunction(scriptCode)
    end)
    
    return true
end

LocalPlayer.OnTeleport:Connect(function(state, placeId, spawnName)
    if state == Enum.TeleportState.Started then
        if AutoExecuteOnTeleport then
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
    Raid = Window:AddTab({ Title = "Raid", Icon = "skull" }),
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
-- PLAYER FUNCTIONS
-- ===============================

local function getPlayerList()
    local playerList = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
    
    table.sort(playerList)
    return playerList
end

local function getPlayerCharacter(playerName)
    local success, result = pcall(function()
        local serverPlayers = Workspace.Characters.Server.Players:GetChildren()
        
        for _, char in pairs(serverPlayers) do
            if char.Name:find(playerName) then
                return char
            end
        end
        
        return nil
    end)
    
    return success and result or nil
end

local function applySpeed()
    pcall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = SpeedEnabled and SpeedValue or DefaultWalkSpeed
            end
        end
    end)
end

local function applyJumpPower()
    pcall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = JumpPowerEnabled and JumpPowerValue or DefaultJumpPower
                humanoid.UseJumpPower = true
            end
        end
    end)
end

local function tweenToPlayer(playerName)
    if not playerName then return end
    
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then 
        -- Fallback para character normal
        localChar = LocalPlayer.Character
        if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
            return 
        end
    end
    
    local targetChar = getPlayerCharacter(playerName)
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then 
        -- Fallback para character normal do jogador alvo
        local targetPlayer = Players:FindFirstChild(playerName)
        if targetPlayer and targetPlayer.Character then
            targetChar = targetPlayer.Character
            if not targetChar:FindFirstChild("HumanoidRootPart") then
                return
            end
        else
            return
        end
    end
    
    local targetPos = targetChar.HumanoidRootPart.Position
    local currentPos = localChar.HumanoidRootPart.Position
    local distance = getDistance(currentPos, targetPos)
    
    if distance <= 5 then 
        Fluent:Notify({
            Title = "Tween to Player",
            Content = "Você já está perto de " .. playerName,
            Duration = 2
        })
        return 
    end
    
    if PlayerCurrentTween then
        PlayerCurrentTween:Cancel()
        PlayerCurrentTween = nil
    end
    
    local direction = (targetPos - currentPos).Unit
    local finalPosition = targetPos - (direction * 5)
    
    local targetCFrame = CFrame.new(finalPosition) * CFrame.Angles(0, math.atan2(-direction.X, -direction.Z), 0)
    
    local tweenTime = math.max(distance / PlayerTweenSpeed, 0.1)
    
    local tweenInfo = TweenInfo.new(
        tweenTime,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    
    PlayerCurrentTween = TweenService:Create(
        localChar.HumanoidRootPart,
        tweenInfo,
        {CFrame = targetCFrame}
    )
    
    PlayerCurrentTween:Play()
    
    Fluent:Notify({
        Title = "Tween to Player",
        Content = "Indo até " .. playerName .. " (" .. math.floor(distance) .. " studs)",
        Duration = 2
    })
end

-- ===============================
-- FUNÇÃO: VERIFICA SE É "Lv.1 Punching Bag"
-- ===============================
local function isPunchingBag(npc)
    if not npc then return false end
    
    local isImmortal = false
    pcall(function()
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        if hrp then
            local charDebug = hrp:FindFirstChild("CharDebug")
            if charDebug then
                local frame = charDebug:FindFirstChild("Frame")
                if frame then
                    local immortal = frame:FindFirstChild("Immortal")
                    if immortal and immortal:IsA("TextLabel") then
                        if immortal.Text == "Is Immortal: true" then
                            isImmortal = true
                        end
                    end
                end
            end
        end
    end)
    
    if isImmortal then
        return true
    end
    
    local isPunchingBagClient = false
    pcall(function()
        local clientFolder = Workspace.Characters.Client
        if clientFolder then
            for _, clientModel in pairs(clientFolder:GetChildren()) do
                if clientModel:IsA("Model") then
                    local billboard = clientModel:FindFirstChild("BillboardGui")
                    if billboard then
                        local frame = billboard:FindFirstChild("Frame")
                        if frame then
                            local children = frame:GetChildren()
                            
                            if children[8] then
                                local textLabel = children[8]:FindFirstChild("TextLabel")
                                if textLabel and textLabel:IsA("TextLabel") then
                                    if textLabel.Text == "Lv.1 Punching Bag" then
                                        local clientHRP = clientModel:FindFirstChild("HumanoidRootPart")
                                        local serverHRP = npc:FindFirstChild("HumanoidRootPart")
                                        
                                        if clientHRP and serverHRP then
                                            local dist = (clientHRP.Position - serverHRP.Position).Magnitude
                                            if dist < 10 then
                                                isPunchingBagClient = true
                                            end
                                        end
                                    end
                                end
                            end
                            
                            if not isPunchingBagClient then
                                for _, child in pairs(children) do
                                    pcall(function()
                                        local label = child:FindFirstChild("TextLabel")
                                        if label and label:IsA("TextLabel") then
                                            if label.Text == "Lv.1 Punching Bag" then
                                                local clientHRP = clientModel:FindFirstChild("HumanoidRootPart")
                                                local serverHRP = npc:FindFirstChild("HumanoidRootPart")
                                                
                                                if clientHRP and serverHRP then
                                                    local dist = (clientHRP.Position - serverHRP.Position).Magnitude
                                                    if dist < 10 then
                                                        isPunchingBagClient = true
                                                    end
                                                end
                                            end
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    
    if isPunchingBagClient then
        return true
    end
    
    return false
end

-- ===============================
-- FARM: GET NEAREST NPC (DISTÂNCIA INFINITA)
-- ===============================
local function getNearestNPC()
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local localPos = localChar.HumanoidRootPart.Position
    local nearestNPC = nil
    local shortestDistance = math.huge
    
    pcall(function()
        local npcsFolder = Workspace.Characters.Server.NPCs
        if not npcsFolder then return end
        
        for _, npc in pairs(npcsFolder:GetChildren()) do
            if npc:IsA("Model") and npc:FindFirstChild("Humanoid") then
                if isPunchingBag(npc) then
                    continue
                end
                
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
-- RAID: GET NEAREST ENEMY (DISTÂNCIA INFINITA)
-- ===============================
local function getRaidNearestEnemy()
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local localPos = localChar.HumanoidRootPart.Position
    local nearestEnemy = nil
    local shortestDistance = math.huge
    
    pcall(function()
        local npcsFolder = Workspace.Characters.Server.NPCs
        if npcsFolder then
            for _, npc in pairs(npcsFolder:GetChildren()) do
                if npc:IsA("Model") and npc:FindFirstChild("Humanoid") then
                    if isPunchingBag(npc) then
                        continue
                    end
                    
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
    
    if isPunchingBag(targetNPC) then return false end
    
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
    
    if isPunchingBag(targetNPC) then return false end
    
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
    
    if isPunchingBag(targetNPC) then return false end
    
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
    
    if isPunchingBag(targetNPC) then return false end
    
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
-- FARM: TWEEN TO MOB (DISTÂNCIA INFINITA)
-- ===============================

local function tweenToMob(targetNPC)
    if not TweenToMobEnabled then return end
    if not targetNPC then return end
    
    if isPunchingBag(targetNPC) then 
        return 
    end
    
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return end
    if not targetNPC:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPos = targetNPC.HumanoidRootPart.Position
    local currentPos = localChar.HumanoidRootPart.Position
    local distance = getDistance(currentPos, targetPos)
    
    if distance <= TweenOffset + 2 then return end
    
    if CurrentTween then
        CurrentTween:Cancel()
        CurrentTween = nil
    end
    
    local direction = (targetPos - currentPos).Unit
    local finalPosition = targetPos - (direction * TweenOffset)
    
    local targetCFrame = CFrame.new(finalPosition) * CFrame.Angles(0, math.atan2(-direction.X, -direction.Z), 0)
    
    local tweenTime = math.max(distance / TweenSpeed, 0.05)
    
    local tweenInfo = TweenInfo.new(
        tweenTime,
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
-- RAID: TWEEN TO MOB (DISTÂNCIA INFINITA)
-- ===============================

local function raidTweenToMob(targetNPC)
    if not RaidTweenToMobEnabled then return end
    if not targetNPC then return end
    
    if isPunchingBag(targetNPC) then 
        return 
    end
    
    local localChar = getLocalServerCharacter()
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return end
    if not targetNPC:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPos = targetNPC.HumanoidRootPart.Position
    local currentPos = localChar.HumanoidRootPart.Position
    local distance = getDistance(currentPos, targetPos)
    
    if distance <= RaidTweenOffset + 2 then return end
    
    if RaidCurrentTween then
        RaidCurrentTween:Cancel()
        RaidCurrentTween = nil
    end
    
    local direction = (targetPos - currentPos).Unit
    local finalPosition = targetPos - (direction * RaidTweenOffset)
    
    local targetCFrame = CFrame.new(finalPosition) * CFrame.Angles(0, math.atan2(-direction.X, -direction.Z), 0)
    
    local tweenTime = math.max(distance / RaidTweenSpeed, 0.05)
    
    local tweenInfo = TweenInfo.new(
        tweenTime,
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
    
    if targetNPC and not isPunchingBag(targetNPC) then
        if TweenToMobEnabled and distance > TweenOffset + 2 then
            tweenToMob(targetNPC)
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
-- RAID: AUTO ATTACK LOOP (COM AUTO RETRY)
-- ===============================

local function raidAutoAttack()
    if not RaidAutoAttackEnabled then return end
    
    local currentTime = tick()
    
    if currentTime - RaidLastAttackTime < RaidAttackCooldown then
        return
    end
    
    local targetEnemy, distance = getRaidNearestEnemy()
    
    if targetEnemy and not isPunchingBag(targetEnemy) then
        HadMobsBefore = true
        IsRetrying = false
        
        if RaidTweenToMobEnabled and distance > RaidTweenOffset + 2 then
            raidTweenToMob(targetEnemy)
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
    else
        if HadMobsBefore and not IsRetrying then
            IsRetrying = true
            HadMobsBefore = false
            
            Fluent:Notify({
                Title = "Raid Finalizada!",
                Content = "Reentrando em 5 segundos...",
                Duration = 5
            })
            
            task.spawn(function()
                task.wait(5)
                
                if RaidAutoAttackEnabled then
                    pcall(function()
                        game:GetService("ReplicatedStorage").NetworkComm.RaidsService.RetryRaid_Method:InvokeServer()
                    end)
                    
                    Fluent:Notify({
                        Title = "Auto Retry",
                        Content = "Reentrando na Raid!",
                        Duration = 2
                    })
                end
                
                IsRetrying = false
            end)
        end
    end
end



-- ===============================
-- FARM TAB UI
-- ===============================

local AutoAttackSection = Tabs.Farm:AddSection("Auto Attack")

local AutoAttackToggle = Tabs.Farm:AddToggle("AutoAttack", {
    Title = "Kill Aura",
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
    Default = false,
    Callback = function(Value)
        UseFugaSkill = Value
        CurrentSkill = Value and "Fuga" or "Punch"
    end
})

local CooldownSlider = Tabs.Farm:AddSlider("AttackCooldown", {
    Title = "Attack Cooldown",
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
    Default = false,
    Callback = function(Value)
        TweenToMobEnabled = Value
        
        if not Value and CurrentTween then
            CurrentTween:Cancel()
            CurrentTween = nil
        end
    end
})

local SpeedSliderFarm = Tabs.Farm:AddSlider("TweenSpeed", {
    Title = "Tween Speed",
    Default = 200,
    Min = 50,
    Max = 800,
    Rounding = 0,
    Callback = function(Value)
        TweenSpeed = Value
    end
})

local OffsetSlider = Tabs.Farm:AddSlider("TweenOffset", {
    Title = "Tween Offset",
    Default = 5,
    Min = 0,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        TweenOffset = Value
    end
})

local InventorySection = Tabs.Farm:AddSection("Inventory")

local SlotSlider = Tabs.Farm:AddSlider("InventorySlot", {
    Title = "Inventory Slot",
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
    Values = getNPCList(),
    Multi = false,
    Default = 1,
    Callback = function(Value)
        SelectedNPC = Value
    end
})

local AutoAcceptToggle = Tabs.Farm:AddToggle("AutoAcceptQuest", {
    Title = "Auto Quest",
    Default = false,
    Callback = function(Value)
        AutoAcceptQuestEnabled = Value
    end
})

-- ===============================
-- RAID TAB UI
-- ===============================

local RaidAttackSection = Tabs.Raid:AddSection("Raid Auto Attack")

local RaidAutoAttackToggle = Tabs.Raid:AddToggle("RaidAutoAttack", {
    Title = "Raid Kill Aura (Auto Retry)",
    Default = false,
    Callback = function(Value)
        RaidAutoAttackEnabled = Value
        HadMobsBefore = false
        IsRetrying = false
        
        if Value then
            if not RaidAttackConnection then
                RaidAttackConnection = RunService.Heartbeat:Connect(raidAutoAttack)
            end
            
            Fluent:Notify({
                Title = "Raid Kill Aura",
                Content = "Ativado!",
                Duration = 2
            })
        else
            if RaidCurrentTween then
                RaidCurrentTween:Cancel()
                RaidCurrentTween = nil
            end
            
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
    Default = false,
    Callback = function(Value)
        RaidUseFugaSkill = Value
        RaidCurrentSkill = Value and "Fuga" or "Punch"
    end
})

local RaidCooldownSlider = Tabs.Raid:AddSlider("RaidAttackCooldown", {
    Title = "Raid Attack Cooldown",
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
    Default = 50,
    Min = 5,
    Max = 500,
    Rounding = 0,
    Callback = function(Value)
        RaidAttackRange = Value
    end
})

local RaidMovementSection = Tabs.Raid:AddSection("Raid Movement")

local RaidTweenToggle = Tabs.Raid:AddToggle("RaidTweenToMob", {
    Title = "Raid Tween to Enemy",
    Default = false,
    Callback = function(Value)
        RaidTweenToMobEnabled = Value
        
        if not Value and RaidCurrentTween then
            RaidCurrentTween:Cancel()
            RaidCurrentTween = nil
        end
    end
})

local RaidSpeedSlider = Tabs.Raid:AddSlider("RaidTweenSpeed", {
    Title = "Raid Tween Speed",
    Default = 300,
    Min = 50,
    Max = 800,
    Rounding = 0,
    Callback = function(Value)
        RaidTweenSpeed = Value
    end
})

local RaidOffsetSlider = Tabs.Raid:AddSlider("RaidTweenOffset", {
    Title = "Raid Tween Offset",
    Default = 5,
    Min = 0,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        RaidTweenOffset = Value
    end
})

Tabs.Raid:AddParagraph({
    Title = "Raid Info",
    Content = "Auto Retry após 5 segundos"
})

-- ===============================
-- SETTINGS TAB
-- ===============================

local AutoExecSection = Tabs.Settings:AddSection("Auto Execute")

local AutoExecToggle = Tabs.Settings:AddToggle("AutoExecuteToggle", {
    Title = "Auto Execute on Teleport",
    Description = IsExecutorSupported 
        and "Reexecuta após teleport (Place/SubPlace)" 
        or "Executor não suporta: " .. ExecutorName,
    Default = false,
    Callback = function(Value)
        if not IsExecutorSupported then
            Fluent:Notify({
                Title = "Não Suportado",
                Content = "Seu executor não suporta queue_on_teleport!",
                Duration = 4
            })
            return
        end
        
        AutoExecuteOnTeleport = Value
        
        if Value then
            queueScriptForTeleport()
            Fluent:Notify({
                Title = "Auto Execute",
                Content = "Ativado!",
                Duration = 2
            })
        end
    end
})

Tabs.Settings:AddParagraph({
    Title = "Executor Info",
    Content = "Executor: " .. ExecutorName .. 
              "\nQueue: " .. (IsExecutorSupported and "Suportado" or "Não Suportado") ..
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
    Content = "Welcome",
    Duration = 4
})

print("[Kill Hub] Script carregado!")
print("[Kill Hub] Executor:", ExecutorName)
