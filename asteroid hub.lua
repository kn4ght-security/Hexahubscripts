-- ☄️ ASTEROID HUB FINAL (v2.16 – INSTANT AIMBOT NO DEADZONE)

repeat task.wait() until game:IsLoaded()

-------------------------------------------------
-- LOAD UI
-------------------------------------------------

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Asteroid Hub ",
    LoadingTitle = "Asteroid Hub",
    LoadingSubtitle = "Combat Enhancement Suite",
    ConfigurationSaving = { Enabled = false }
})

-------------------------------------------------
-- SERVICES
-------------------------------------------------

local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lplr = players.LocalPlayer
local camera = workspace.CurrentCamera

-------------------------------------------------
-- MODULES (with error handling)
-------------------------------------------------

local enums, fighter, Items, utility

pcall(function()
    enums = require(rs.Modules.EnumLibrary)
end)

pcall(function()
    fighter = require(lplr.PlayerScripts:WaitForChild("Controllers"):WaitForChild("FighterController"))
end)

pcall(function()
    Items = require(rs.Modules.ItemLibrary).Items
end)

-- For Silent Aim
pcall(function()
    utility = require(rs.Modules.Utility)
end)

-- CameraController for Instant Aimbot
local cameraController
pcall(function()
    local ctrl = lplr.PlayerScripts:WaitForChild("Controllers")
    cameraController = require(ctrl:WaitForChild("CameraController"))
end)

if not enums or not fighter or not Items then
    Rayfield:Notify({
        Title = "Error",
        Content = "Failed to load required modules. Rejoin and try again.",
        Duration = 10
    })
    return
end

-------------------------------------------------
-- TABS
-------------------------------------------------

local CombatTab = Window:CreateTab("☄️ Combat")
local TPacksTab = Window:CreateTab("🛰️ TP Packs")
local ControlsTab = Window:CreateTab("🎮 Controls")
local InfoTab = Window:CreateTab("📘 Info")

-------------------------------------------------
-- SETTINGS
-------------------------------------------------

local Settings = {
    Aim = false,
    InstantAimbot = false,
    SilentAim = false,
    SilentAimFOV = 60,
    RapidFire = false,
    VisibilityCheck = false,
    AutoCombo = false,
    TeleportUnder = false,
    TeleportFront = false,
    TeleportBehind = false,
    TeleportAbove = false,
    TeleportLeft = false,
    TeleportRight = false,
    TeleportOrbit = false,
    OrbitSpeed = 3,
    OrbitRadius = 6,
    FrontDistance = 3,
    BehindDistance = 3,
    SideDistance = 3,
    AboveDistance = 8,
    ComboSpeed = 0.12,
    UnderDistance = 6,
    FOV = 150,
    Ragebot = false,
    RagebotRadius = 4,
    RagebotSpeed = 0.05,
}

-------------------------------------------------
-- SPAWN POSITION
-------------------------------------------------

local spawnPos = nil

local function captureSpawn()
    local char = lplr.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            spawnPos = hrp.Position
        end
    end
end

captureSpawn()

if not spawnPos then
    lplr.CharacterAdded:Connect(function(char)
        if not spawnPos then
            task.wait(1)
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                spawnPos = hrp.Position
            end
        end
    end)
end

-------------------------------------------------
-- TEAM CHECK
-------------------------------------------------

local function sameTeam(player)
    if not player or player == lplr then
        return true
    end

    if lplr.Team and player.Team then
        if lplr.Team == player.Team then
            return true
        end
    end

    local myTeam = lplr:GetAttribute("TeamID")
    local targetTeam = player:GetAttribute("TeamID")
    
    if myTeam ~= nil and targetTeam ~= nil then
        if tostring(myTeam) == tostring(targetTeam) then
            return true
        end
    end

    local myTeamAttr = lplr:GetAttribute("Team")
    local targetTeamAttr = player:GetAttribute("Team")
    
    if myTeamAttr ~= nil and targetTeamAttr ~= nil then
        if tostring(myTeamAttr) == tostring(targetTeamAttr) then
            return true
        end
    end

    return false
end

-------------------------------------------------
-- VALID PLAYER
-------------------------------------------------

local function validPlayer(p)
    if p == lplr then return false end
    if sameTeam(p) then return false end

    local char = p.Character
    if not char then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")

    if not hum or hum.Health <= 0 then return false end
    if not head then return false end

    return true
end

-------------------------------------------------
-- TARGET SYSTEM (cached for general use)
-------------------------------------------------

local targetCache = { head = nil, player = nil, timestamp = 0 }
local CACHE_DURATION = 0.1

local function getTarget()
    if tick() - targetCache.timestamp < CACHE_DURATION then
        if targetCache.head and targetCache.player and validPlayer(targetCache.player) then
            return targetCache.head
        end
    end

    local char = lplr.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local best, bestDist = nil, math.huge
    for _, p in ipairs(players:GetPlayers()) do
        if validPlayer(p) then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local d = (root.Position - head.Position).Magnitude
                if d < bestDist and d <= Settings.FOV then
                    bestDist = d
                    best = head
                end
            end
        end
    end

    targetCache.head = best
    targetCache.player = best and players:GetPlayerFromCharacter(best.Parent) or nil
    targetCache.timestamp = tick()
    return best
end

-------------------------------------------------
-- VISIBILITY CHECK
-------------------------------------------------

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

local function isVisible(targetPart)
    if not targetPart then return false end
    raycastParams.FilterDescendantsInstances = { lplr.Character }
    local result = workspace:Raycast(
        camera.CFrame.Position,
        targetPart.Position - camera.CFrame.Position,
        raycastParams
    )
    return result and result.Instance and result.Instance:IsDescendantOf(targetPart.Parent)
end

-------------------------------------------------
-- WALLBANG (for Ragebot)
-------------------------------------------------

local wallbangHeights = {0, 12, 16, 20, 24, 28, 32, 36, 40, 50, 60, 75, 90, 115, 130, 145, 160, 175, 190, 205, 220, 235, 250, 275}

local function wallbangShootPos(from, to, targetChar)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    params.FilterDescendantsInstances = {lplr.Character, targetChar}

    if not workspace:Raycast(from, to - from, params) then
        return from
    end

    for _, h in ipairs(wallbangHeights) do
        local p = from + Vector3.new(0, h, 0)
        if not workspace:Raycast(p, to - p, params) then
            return p
        end
    end

    return nil
end

local function wallbangData(pos, target)
    local t = target.Position
    local l = CFrame.lookAt(pos, t)
    local x, y, z = l:ToOrientation()
    local e = {
        [utf8.char(0)] = pos.X,
        [utf8.char(1)] = pos.Y,
        [utf8.char(2)] = pos.Z,
        [utf8.char(3)] = x,
        [utf8.char(4)] = y,
        [utf8.char(5)] = z
    }
    local o = target.CFrame:ToObjectSpace(CFrame.new(t))
    local a, b, c = o:ToOrientation()
    return {
        [utf8.char(1)] = {
            [utf8.char(0)] = e,
            [utf8.char(1)] = e,
            [utf8.char(2)] = target,
            [utf8.char(3)] = {
                [utf8.char(0)] = o.X,
                [utf8.char(1)] = o.Y,
                [utf8.char(2)] = o.Z,
                [utf8.char(3)] = a,
                [utf8.char(4)] = b,
                [utf8.char(5)] = c
            }
        }
    }
end

-------------------------------------------------
-- STANDARD AIM DATA BUILDER
-------------------------------------------------

local function buildData(pos, target)
    local predicted = target.Position + (target.Velocity * 0.04)
    local look = CFrame.lookAt(pos, predicted)
    local x, y, z = look:ToOrientation()

    local e = {
        [utf8.char(0)] = pos.X,
        [utf8.char(1)] = pos.Y,
        [utf8.char(2)] = pos.Z,
        [utf8.char(3)] = x,
        [utf8.char(4)] = y,
        [utf8.char(5)] = z
    }

    return {
        [utf8.char(1)] = {
            [utf8.char(0)] = e,
            [utf8.char(1)] = e,
            [utf8.char(2)] = target
        }
    }
end

-------------------------------------------------
-- SILENT AIM – override utility.Raycast
-------------------------------------------------

local originalRaycast = nil
if utility then
    originalRaycast = utility.Raycast
end

local silentTargetCache = { player = nil, time = 0 }
local silentVisCache = {}

local function isInFOV(startPos, lookDirection, targetPos, fovDeg)
    if not startPos or not lookDirection or not targetPos then return false end
    local toTarget = (targetPos - startPos).Unit
    local dot = lookDirection:Dot(toTarget)
    local angle = math.deg(math.acos(dot))
    return angle <= fovDeg / 2
end

local function silentIsVisible(char, part)
    if not char or not part then return false end
    local key = char
    local now = tick()
    local entry = silentVisCache[key]
    if entry and (now - entry.time) < 0.05 then return entry.visible end

    local myChar = lplr.Character
    if not myChar then return false end
    local root = myChar:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local startPos = root.Position
    local targetPos = part.Position
    local dist = (targetPos - startPos).Magnitude
    if dist < 1 then
        silentVisCache[key] = { visible = true, time = now }
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { myChar, char }
    params.IgnoreWater = true

    local direction = (targetPos - startPos).Unit
    local result = workspace:Raycast(startPos, direction * dist, params)
    local visible = false
    if not result then
        visible = true
    else
        local hit = result.Instance
        if hit and (hit == part or hit:IsDescendantOf(char)) then
            visible = true
        end
    end
    silentVisCache[key] = { visible = visible, time = now }
    return visible
end

local function getSilentTarget(fovDeg)
    local now = tick()
    if silentTargetCache.player and (now - silentTargetCache.time) < 0.05 then
        local p = silentTargetCache.player
        if p and p.Character and p.Character:FindFirstChild("Head") and not sameTeam(p) then
            local head = p.Character.Head
            local humanoid = p.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and silentIsVisible(p.Character, head) then
                return p
            end
        end
    end

    local myChar = lplr.Character
    if not myChar then return nil end
    local root = myChar:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local lookVector = cam.CFrame.LookVector
    local startPos = root.Position

    local best, bestDist = nil, 1e9
    for _, p in ipairs(players:GetPlayers()) do
        if p ~= lplr and not sameTeam(p) then
            local char = p.Character
            if char then
                local head = char:FindFirstChild("Head")
                local humanoid = char:FindFirstChild("Humanoid")
                if head and humanoid and humanoid.Health > 0 then
                    local dist = (root.Position - head.Position).Magnitude
                    if dist > 5 and dist < bestDist and isInFOV(startPos, lookVector, head.Position, fovDeg) then
                        if silentIsVisible(char, head) then
                            bestDist = dist
                            best = p
                        end
                    end
                end
            end
        end
    end
    silentTargetCache.player = best
    silentTargetCache.time = now
    return best
end

local function silentRaycast(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    if not startPos then
        return originalRaycast(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    end

    if not Settings.SilentAim then
        return originalRaycast(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    end

    local target = getSilentTarget(Settings.SilentAimFOV)
    if not target or not target.Character then
        return originalRaycast(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    end

    local targetChar = target.Character
    local targetHead = targetChar:FindFirstChild("Head")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHead or not targetRoot then
        return originalRaycast(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    end

    local headPos = targetHead.Position
    local rootPos = targetRoot.Position
    local distToHead = (headPos - startPos).Magnitude

    local MAX_DIST = 150
    if distToHead > MAX_DIST then
        return originalRaycast(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    end

    local cam = workspace.CurrentCamera
    if cam then
        local lookVector = cam.CFrame.LookVector
        if not isInFOV(startPos, lookVector, headPos, Settings.SilentAimFOV) then
            if not isInFOV(startPos, lookVector, rootPos, Settings.SilentAimFOV) then
                return originalRaycast(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
            end
        end
    end

    local effectiveMaxDist = math.min(maxDist or 1000, MAX_DIST)
    if distToHead > effectiveMaxDist then
        return originalRaycast(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    end

    local aimPos = headPos
    if Settings.VisibilityCheck and not silentIsVisible(targetChar, targetHead) then
        if silentIsVisible(targetChar, targetRoot) then
            aimPos = rootPos
        else
            return originalRaycast(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
        end
    end

    local dir = (aimPos - startPos).Unit
    local dist = (aimPos - startPos).Magnitude
    if dist > effectiveMaxDist then
        dist = effectiveMaxDist
        aimPos = startPos + dir * effectiveMaxDist
    end

    return {
        Position = aimPos,
        Distance = dist,
        Instance = targetHead,
        Material = targetHead.Material,
        Normal = -dir
    }
end

local function updateSilentAim()
    if not utility then return end
    if Settings.SilentAim then
        utility.Raycast = silentRaycast
    else
        utility.Raycast = originalRaycast or utility.Raycast
    end
end

if utility and originalRaycast then
    utility.Raycast = originalRaycast
end

-------------------------------------------------
-- COMBAT TAB UI
-------------------------------------------------

CombatTab:CreateToggle({
    Name = "Enable Aim",
    Callback = function(v) Settings.Aim = v end
})

CombatTab:CreateToggle({
    Name = "Instant Aimbot",
    Callback = function(v) Settings.InstantAimbot = v end
})

CombatTab:CreateToggle({
    Name = "Silent Aim",
    Callback = function(v)
        Settings.SilentAim = v
        updateSilentAim()
    end
})

CombatTab:CreateSlider({
    Name = "Silent Aim FOV (degrees)",
    Range = {10, 120},
    Increment = 1,
    CurrentValue = 60,
    Callback = function(v) Settings.SilentAimFOV = v end
})

CombatTab:CreateToggle({
    Name = "Rapid Fire",
    Callback = function(v) Settings.RapidFire = v end
})

CombatTab:CreateToggle({
    Name = "Visibility Check",
    Callback = function(v) Settings.VisibilityCheck = v end
})

CombatTab:CreateToggle({
    Name = "Auto Kill Combo",
    Callback = function(v) Settings.AutoCombo = v end
})

CombatTab:CreateToggle({
    Name = "Teleport Under Enemy",
    Callback = function(v) Settings.TeleportUnder = v end
})

CombatTab:CreateToggle({
    Name = "Ragebot",
    Callback = function(v) Settings.Ragebot = v end
})

CombatTab:CreateSlider({
    Name = "Ragebot Radius",
    Range = {2, 10},
    Increment = 0.5,
    CurrentValue = 4,
    Callback = function(v) Settings.RagebotRadius = v end
})

CombatTab:CreateSlider({
    Name = "Ragebot Speed (Teleport Interval)",
    Range = {0.02, 0.2},
    Increment = 0.01,
    CurrentValue = 0.05,
    Callback = function(v) Settings.RagebotSpeed = v end
})

CombatTab:CreateSlider({
    Name = "Combo Speed",
    Range = {0.05, 0.5},
    Increment = 0.05,
    CurrentValue = 0.12,
    Callback = function(v) Settings.ComboSpeed = v end
})

CombatTab:CreateSlider({
    Name = "Aim FOV (Range)",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 150,
    Callback = function(v) Settings.FOV = v end
})

-------------------------------------------------
-- TP PACKS TAB
-------------------------------------------------

TPacksTab:CreateToggle({
    Name = "Teleport Front",
    Callback = function(v) Settings.TeleportFront = v end
})

TPacksTab:CreateToggle({
    Name = "Teleport Behind",
    Callback = function(v) Settings.TeleportBehind = v end
})

TPacksTab:CreateToggle({
    Name = "Teleport Above",
    Callback = function(v) Settings.TeleportAbove = v end
})

TPacksTab:CreateToggle({
    Name = "Teleport Left",
    Callback = function(v) Settings.TeleportLeft = v end
})

TPacksTab:CreateToggle({
    Name = "Teleport Right",
    Callback = function(v) Settings.TeleportRight = v end
})

TPacksTab:CreateToggle({
    Name = "Orbit Enemy",
    Callback = function(v) Settings.TeleportOrbit = v end
})

TPacksTab:CreateSlider({
    Name = "Orbit Speed",
    Range = {0.5, 10},
    Increment = 0.5,
    CurrentValue = 3,
    Callback = function(v) Settings.OrbitSpeed = v end
})

TPacksTab:CreateSlider({
    Name = "Orbit Radius",
    Range = {2, 15},
    Increment = 0.5,
    CurrentValue = 6,
    Callback = function(v) Settings.OrbitRadius = v end
})

TPacksTab:CreateSlider({
    Name = "Front Distance",
    Range = {1, 20},
    Increment = 0.5,
    CurrentValue = 3,
    Callback = function(v) Settings.FrontDistance = v end
})

TPacksTab:CreateSlider({
    Name = "Behind Distance",
    Range = {1, 20},
    Increment = 0.5,
    CurrentValue = 3,
    Callback = function(v) Settings.BehindDistance = v end
})

TPacksTab:CreateSlider({
    Name = "Side Distance",
    Range = {1, 20},
    Increment = 0.5,
    CurrentValue = 3,
    Callback = function(v) Settings.SideDistance = v end
})

TPacksTab:CreateSlider({
    Name = "Above Distance",
    Range = {1, 30},
    Increment = 0.5,
    CurrentValue = 8,
    Callback = function(v) Settings.AboveDistance = v end
})

TPacksTab:CreateSlider({
    Name = "Under Distance",
    Range = {1, 20},
    Increment = 0.5,
    CurrentValue = 6,
    Callback = function(v) Settings.UnderDistance = v end
})

-------------------------------------------------
-- GLOBAL TRACKING (for spawn return)
-------------------------------------------------

local currentTargetPlayer = nil
local engagedPlayer = nil

local function setCurrentTarget(head)
    if head and head.Parent then
        currentTargetPlayer = players:GetPlayerFromCharacter(head.Parent)
    else
        currentTargetPlayer = nil
    end
end

local function setEngaged(head)
    if head and head.Parent then
        engagedPlayer = players:GetPlayerFromCharacter(head.Parent)
    end
end

-------------------------------------------------
-- ORBIT / TP PACKS ENGINE
-------------------------------------------------

local orbitTick = 0
local ragebotLastTeleport = 0

RunService.RenderStepped:Connect(function()
    local char = lplr.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local target = getTarget()
    if not target then return end

    setCurrentTarget(target)

    local enemyHRP = target.Parent:FindFirstChild("HumanoidRootPart")
    if not enemyHRP then return end

    if Settings.Ragebot then
        if tick() - ragebotLastTeleport >= Settings.RagebotSpeed then
            ragebotLastTeleport = tick()
            local angle = math.random() * 2 * math.pi
            local radiusVariation = 0.5 + math.random() * 0.5
            local radius = Settings.RagebotRadius * radiusVariation
            local x = math.cos(angle) * radius
            local z = math.sin(angle) * radius
            local pos = Vector3.new(enemyHRP.Position.X + x, enemyHRP.Position.Y, enemyHRP.Position.Z + z)
            hrp.CFrame = CFrame.new(pos, enemyHRP.Position)
        end
        return
    end

    if Settings.TeleportOrbit then
        orbitTick = orbitTick + Settings.OrbitSpeed * 0.05
        local x = math.cos(orbitTick) * Settings.OrbitRadius
        local z = math.sin(orbitTick) * Settings.OrbitRadius
        local pos = Vector3.new(enemyHRP.Position.X + x, enemyHRP.Position.Y, enemyHRP.Position.Z + z)
        hrp.CFrame = CFrame.new(pos, enemyHRP.Position)

    elseif Settings.TeleportFront then
        local pos = enemyHRP.Position + enemyHRP.CFrame.LookVector * Settings.BehindDistance
        hrp.CFrame = CFrame.new(pos, enemyHRP.Position)

    elseif Settings.TeleportBehind then
        local pos = enemyHRP.Position + enemyHRP.CFrame.LookVector * -Settings.FrontDistance
        hrp.CFrame = CFrame.new(pos, enemyHRP.Position)

    elseif Settings.TeleportAbove then
        local pos = Vector3.new(enemyHRP.Position.X, enemyHRP.Position.Y + Settings.AboveDistance, enemyHRP.Position.Z)
        hrp.CFrame = CFrame.new(pos, enemyHRP.Position)

    elseif Settings.TeleportLeft then
        local pos = enemyHRP.Position + enemyHRP.CFrame.RightVector * Settings.SideDistance
        hrp.CFrame = CFrame.new(pos, enemyHRP.Position)

    elseif Settings.TeleportRight then
        local pos = enemyHRP.Position + enemyHRP.CFrame.RightVector * -Settings.SideDistance
        hrp.CFrame = CFrame.new(pos, enemyHRP.Position)
    end
end)

-------------------------------------------------
-- AUTO COMBO LOOP
-------------------------------------------------

local comboIndex = 1
local lastSwitch = 0

RunService.RenderStepped:Connect(function()
    if not Settings.AutoCombo or Settings.Ragebot then return end

    local char = lplr.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local target = getTarget()
    if not target then return end

    setCurrentTarget(target)

    local enemyHRP = target.Parent:FindFirstChild("HumanoidRootPart")
    if not enemyHRP then return end

    if tick() - lastSwitch > Settings.ComboSpeed then
        comboIndex = (comboIndex % 5) + 1
        lastSwitch = tick()
    end

    local enemyY = enemyHRP.Position.Y
    local positions = {
        Vector3.new(enemyHRP.Position.X, enemyY, enemyHRP.Position.Z - Settings.FrontDistance),
        Vector3.new(enemyHRP.Position.X, enemyY, enemyHRP.Position.Z + Settings.BehindDistance),
        Vector3.new(enemyHRP.Position.X - Settings.SideDistance, enemyY, enemyHRP.Position.Z),
        Vector3.new(enemyHRP.Position.X + Settings.SideDistance, enemyY, enemyHRP.Position.Z),
        Vector3.new(enemyHRP.Position.X, enemyY + Settings.AboveDistance, enemyHRP.Position.Z),
    }

    local pos = positions[comboIndex]
    hrp.CFrame = CFrame.new(pos, enemyHRP.Position)
end)

-------------------------------------------------
-- TELEPORT UNDER LOOP
-------------------------------------------------

RunService.Heartbeat:Connect(function()
    if not Settings.TeleportUnder or Settings.AutoCombo or Settings.Ragebot then return end

    local char = lplr.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local target = getTarget()
    if not target then return end

    setCurrentTarget(target)

    local enemyHRP = target.Parent:FindFirstChild("HumanoidRootPart")
    if not enemyHRP then return end

    local pos = enemyHRP.Position + Vector3.new(0, -Settings.UnderDistance, 0)
    hrp.CFrame = CFrame.new(pos, enemyHRP.Position)
end)

-------------------------------------------------
-- NEW INSTANT AIMBOT – no deadzone, re-snaps every frame
-------------------------------------------------

local instantAimCache = { target = nil, time = 0 }
local INSTANT_AIM_CACHE_DURATION = 0.15

local function instantAimIsEnemy(target)
    if target == lplr then return false end
    local char = target.Character
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    -- Use sameTeam function we already have (it returns true if same team)
    return not sameTeam(target)
end

local function instantAimIsVisible(targetChar, targetPart)
    if not targetPart then return false end
    local cam = workspace.CurrentCamera
    if not cam then return false end

    local startPos = cam.CFrame.Position
    local direction = (targetPart.Position - startPos).Unit
    local distance = (targetPart.Position - startPos).Magnitude
    if distance < 1 then return true end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { lplr.Character, targetChar }
    params.IgnoreWater = true

    local result = workspace:Raycast(startPos, direction * distance, params)
    if not result then return true end
    local hit = result.Instance
    if hit == targetPart or hit:IsDescendantOf(targetChar) then
        return true
    end
    return false
end

local function instantAimValidateTarget(target)
    if not target then return false end
    local char = target.Character
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not instantAimIsEnemy(target) then return false end

    local head = char:FindFirstChild("Head")
    if not head then return false end

    local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local dist = (root.Position - head.Position).Magnitude
    if dist > Settings.FOV or dist < 5 then return false end  -- respect FOV slider

    if not instantAimIsVisible(char, head) then return false end
    return true
end

local function getInstantAimTarget()
    local now = tick()
    if instantAimCache.target and (now - instantAimCache.time) < INSTANT_AIM_CACHE_DURATION then
        if instantAimValidateTarget(instantAimCache.target) then
            return instantAimCache.target
        else
            instantAimCache.target = nil
        end
    end

    local char = lplr.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local closest, closestDist = nil, Settings.FOV + 1
    for _, plr in ipairs(players:GetPlayers()) do
        if instantAimIsEnemy(plr) then
            local tChar = plr.Character
            if tChar then
                local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                local head = tChar:FindFirstChild("Head")
                if tRoot and head then
                    local dist = (root.Position - head.Position).Magnitude
                    if dist < closestDist and dist > 5 and instantAimIsVisible(tChar, head) then
                        closestDist = dist
                        closest = plr
                    end
                end
            end
        end
    end

    instantAimCache.target = closest
    instantAimCache.time = now
    return closest
end

RunService.RenderStepped:Connect(function()
    if not Settings.InstantAimbot then return end
    if not cameraController then return end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local target = getInstantAimTarget()
    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            local targetCF = CFrame.lookAt(cam.CFrame.Position, head.Position)
            local targetRotation = targetCF - targetCF.Position
            cameraController:MimicRotation(targetRotation)
        end
    end
end)

-------------------------------------------------
-- AIM LOOP (shooting)
-------------------------------------------------

task.spawn(function()
    while task.wait(0.05) do
        if not Settings.Aim then continue end

        local f = fighter.LocalFighter
        if not f then continue end

        local i = f.EquippedItem
        if not i or not i.Info then continue end

        if (i:Get("Ammo") or 0) <= 0 then continue end

        if Settings.RapidFire then
            for _, d in pairs(Items) do
                if typeof(d) == "table" and d.ShootCooldown then
                    d.ShootCooldown = 0.05
                end
            end
        end

        local t = getTarget()
        if not t then continue end

        if Settings.Ragebot then
            local sp = wallbangShootPos(camera.CFrame.Position, t.Position, t.Parent)
            if not sp then continue end
            local oid = i:Get("ObjectID")
            local se = enums:ToEnum("StartShooting")
            if oid and se then
                local data = wallbangData(sp, t)
                rs.Remotes.Replication.Fighter.UseItem:FireServer(oid, se, data, nil)
                setEngaged(t)
            end
            setCurrentTarget(t)
            continue
        end

        if Settings.VisibilityCheck and not isVisible(t) then continue end

        -- Only move camera if Instant Aimbot is OFF (Instant Aimbot handles camera itself)
        if not Settings.InstantAimbot then
            camera.CFrame = CFrame.new(camera.CFrame.Position, t.Position)
        end

        setCurrentTarget(t)

        local oid = i:Get("ObjectID")
        local se = enums:ToEnum("StartShooting")

        if oid and se then
            local data = buildData(camera.CFrame.Position, t)
            rs.Remotes.Replication.Fighter.UseItem:FireServer(oid, se, data, nil)
            setEngaged(t)
        end
    end
end)

-------------------------------------------------
-- RETURN TO SPAWN ON KILL
-------------------------------------------------

task.spawn(function()
    while task.wait(0.5) do
        if not spawnPos then continue end
        if not engagedPlayer then continue end

        if not validPlayer(engagedPlayer) then
            local char = lplr.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(spawnPos)
                    Rayfield:Notify({
                        Title = "Returned to Spawn",
                        Content = "Engaged enemy eliminated, teleported back.",
                        Duration = 3
                    })
                end
            end
            engagedPlayer = nil
        end
    end
end)

-------------------------------------------------
-- CONTROLS TAB
-------------------------------------------------

local function SetControl(controlType)
    local FighterRemote = rs.Remotes.Replication.Fighter.SetControls
    if not FighterRemote then return end

    FighterRemote:FireServer(controlType)
    Rayfield:Notify({
        Title = "Controls Changed",
        Content = "Switched to " .. controlType,
        Duration = 3
    })
end

ControlsTab:CreateDropdown({
    Name = "Select Control Type",
    Options = { "Mobile", "PC", "Controller", "VR" },
    CurrentOption = { "PC" },
    Callback = function(option)
        local map = {
            Mobile = "Touch",
            PC = "MouseKeyboard",
            Controller = "Gamepad",
            VR = "VR"
        }
        SetControl(map[option[1]])
    end
})

-------------------------------------------------
-- INFO TAB
-------------------------------------------------

InfoTab:CreateParagraph({
    Title = "Asteroid Hub ☄️",
    Content = [[
Developer: rblxrivalsscript
Controller: asteroidhubOwner

Recommended setup:
- Enable Aim (for shooting)
- Enable Instant Aimbot (hard re-snap each frame)
- Enable Silent Aim (hits without aiming)
- Enable Rapid Fire
- Enable Ragebot (optional – random strafe + wallbang)
]]
})

InfoTab:CreateParagraph({
    Title = "Script Log (v2.16)",
    Content = [[
✅ Universal team check (string/number safe)
✅ FOV slider (range in studs)
✅ Silent Aim with separate FOV (angle)
✅ Instant Aimbot updated – no deadzone, re-snaps every frame
✅ Ragebot uses random strafe + wallbang
✅ TP packs swapped: Front↔Behind, Left↔Right
✅ Teleport Under fixed – directly below enemy
✅ Target caching (0.1s)
✅ Spawn return only after you shoot someone
✅ Clean & stable
✅ Discord invite updated
]]
})

InfoTab:CreateButton({
    Name = "Join Support Discord",
    Callback = function()
        setclipboard("https://discord.gg/rKEJtwEMUd")
        Rayfield:Notify({
            Title = "Discord Copied",
            Content = "Invite copied to clipboard",
            Duration = 4
        })
    end
})

Rayfield:Notify({
    Title = "Asteroid Hub ☄️",
    Content = "Loaded Successfully (v2.16 – New Instant Aimbot)",
    Duration = 5
})