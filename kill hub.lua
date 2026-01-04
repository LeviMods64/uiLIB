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
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer

-- ===============================
-- VARIABLES
-- ===============================
local AutoAttackEnabled = false
local AttackCooldown = 0.5
local AttackRange = 20
local LastAttackTime = 0
local AttackConnection
local TweenToMobEnabled = false
local TweenSpeed = 100
local CurrentTween
local CurrentSlot = 0
local SelectedNPC
local AutoAcceptQuestEnabled = false
local AutoExecuteOnTeleport = false

-- ===============================
-- WINDOW
-- ===============================
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
local DeveloperName = "papa_killll"

local UserTitle = LocalPlayer.DisplayName
local UserSubtitle = "User"
local UserColor = Color3.fromRGB(71,123,255)

if LocalPlayer.Name == DeveloperName then
    UserTitle = DeveloperName
    UserSubtitle = "Developer"
    UserColor = Color3.fromRGB(255,85,85)
end

local Window = Fluent:CreateWindow({
    Title = "Kill Hub",
    SubTitle = "| "..GameName.." | by MrJimex",
    TabWidth = 160,
    Size = UDim2.fromOffset(580,460),
    Acrylic = true,
    Theme = "Arctic",
    MinimizeKey = Enum.KeyCode.LeftControl,
    UserInfo = true,
    UserInfoTop = true,
    UserInfoTitle = UserTitle,
    UserInfoSubtitle = UserSubtitle,
    UserInfoSubtitleColor = UserColor
})

local Tabs = {
    Farm = Window:AddTab({Title="Farm",Icon="swords"}),
    Stats = Window:AddTab({Title="Status",Icon="server"}),
    Settings = Window:AddTab({Title="Settings",Icon="settings"})
}

-- ===============================
-- CORE FUNCTIONS
-- ===============================
local function getLocalServerCharacter()
    for _,c in pairs(Workspace.Characters.Server.Players:GetChildren()) do
        if c.Name:find(LocalPlayer.Name) then
            return c
        end
    end
end

local function getDistance(a,b)
    return (a-b).Magnitude
end

local function switchSlot(slot)
    pcall(function()
        ReplicatedStorage.NetworkComm.InventoryService.FocusItem_Method:InvokeServer(slot)
        CurrentSlot = slot
    end)
end

local function getNearestNPC()
    local char = getLocalServerCharacter()
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local nearest,dist = nil,AttackRange
    for _,npc in pairs(Workspace.Characters.Server.NPCs:GetChildren()) do
        if npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
            if SelectedNPC and npc.Name ~= SelectedNPC then continue end
            local d = getDistance(char.HumanoidRootPart.Position,npc.HumanoidRootPart.Position)
            if d < dist then
                dist = d
                nearest = npc
            end
        end
    end
    return nearest,dist
end

local function attackNPC(npc)
    local char = getLocalServerCharacter()
    if not char then return end

    ReplicatedStorage.NetworkComm.SkillService.StartSkilll_Method:InvokeServer(
        "Punch",char,Vector3.new(1,0,0),1,1
    )

    ReplicatedStorage.NetworkComm.CombatService.DamageCharacter_Method:InvokeServer({
        npc
    },true,{
        SkillID="Punch",
        Origin=char.HumanoidRootPart.CFrame,
        LocalCharacter=char
    })
end

local function autoAttack()
    if not AutoAttackEnabled then return end
    if tick()-LastAttackTime < AttackCooldown then return end

    local npc,dist = getNearestNPC()
    if npc then
        attackNPC(npc)
        LastAttackTime = tick()
    end
end

-- ===============================
-- FARM UI
-- ===============================
Tabs.Farm:AddToggle("AutoAttack",{
    Title="Kill Aura",
    Default=false,
    Callback=function(v)
        AutoAttackEnabled=v
        if v and not AttackConnection then
            AttackConnection = RunService.Heartbeat:Connect(autoAttack)
        end
    end
})

Tabs.Farm:AddSlider("Cooldown",{
    Title="Attack Cooldown",
    Min=0.1,Max=2,Default=0.5,
    Callback=function(v) AttackCooldown=v end
})

Tabs.Farm:AddSlider("Range",{
    Title="Attack Range",
    Min=5,Max=450,Default=20,
    Callback=function(v) AttackRange=v end
})

Tabs.Farm:AddSlider("Slot",{
    Title="Inventory Slot",
    Min=0,Max=5,Default=0,
    Callback=function(v) switchSlot(v) end
})

-- ===============================
-- STATUS
-- ===============================
local Status = Tabs.Stats:AddParagraph({
    Title="Status",
    Content="Idle"
})

task.spawn(function()
    while task.wait(1) do
        Status:SetDesc(
            "Kill Aura: "..(AutoAttackEnabled and "Enabled" or "Disabled")..
            "\nCooldown: "..AttackCooldown..
            "\nRange: "..AttackRange..
            "\nSlot: "..CurrentSlot
        )
    end
end)

-- ===============================
-- AUTO EXECUTE (FINAL)
-- ===============================
Tabs.Settings:AddToggle("AutoExecute",{
    Title="Auto Re-Execute on Teleport",
    Description="Reexecuta o script automaticamente ao teleportar",
    Default=false,
    Callback=function(v)
        AutoExecuteOnTeleport=v
        _G.AutoExecuteOnTeleport=v

        if v then
            queueonteleport([[
                task.wait(2)
                loadstring(game:HttpGet("https://github.com/LeviMods64/uiLIB/raw/refs/heads/main/kill%20hub.lua"))()
            ]])

            Fluent:Notify({
                Title="Auto Execute",
                Content="Script será reexecutado após teleport.",
                Duration=3
            })
        end
    end
})

-- ===============================
-- MANAGERS
-- ===============================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetFolder("KillHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- ===============================
-- FINAL
-- ===============================
Window:SelectTab(1)
Fluent:Notify({
    Title="Kill Hub",
    Content="Script Loaded Successfully!",
    Duration=3
})
SaveManager:LoadAutoloadConfig()
