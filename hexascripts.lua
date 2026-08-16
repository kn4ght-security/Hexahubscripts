local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
Rayfield:LoadConfiguration()

local Players = game:GetService("Players")
local lplr = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "hexa hub",
    Icon = "rewind",
    LoadingTitle = "loading modules | complete! enjoy the game",
    LoadingSubtitle = "made by hexahubscripts",
    ShowText = "Rayfield",
    Theme = "AmberGlow",

    ToggleUIKeybind = "K",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "kn4ghtrivals.lol"
    }
})

-------------------------------------------------
-- TEAM CHECK (UNIVERSAL - HANDLES STRING/NUMBER)
-------------------------------------------------

local function isSameTeam(player)
    if not player or player == lplr then
        return true
    end

    -- Method 1: Check Team property
    if lplr.Team and player.Team then
        if lplr.Team == player.Team then
            return true
        end
    end

    -- Method 2: Check TeamID attribute (handles string/number comparison)
    local myTeam = lplr:GetAttribute("TeamID")
    local targetTeam = player:GetAttribute("TeamID")
    
    if myTeam ~= nil and targetTeam ~= nil then
        if tostring(myTeam) == tostring(targetTeam) then
            return true
        end
    end

    -- Method 3: Check Team attribute (handles string/number comparison)
    local myTeamAttr = lplr:GetAttribute("Team")
    local targetTeamAttr = player:GetAttribute("Team")
    
    if myTeamAttr ~= nil and targetTeamAttr ~= nil then
        if tostring(myTeamAttr) == tostring(targetTeamAttr) then
            return true
        end
    end

    return false
end

local MainTab = Window:CreateTab("Main", 4483362458)
local DeviceSpooferTab = Window:CreateTab("Device Spoofer", "rewind")
local VisualsTab = Window:CreateTab("Visuals", "eye")
local UtilityTab = Window:CreateTab("Utility", "gear")

-------------------------------------------------
-- CONTROLS DROPDOWN (FIXED)
-------------------------------------------------

DeviceSpooferTab:CreateDropdown({
    Name = "Select Control Type",
    Options = {"Mobile", "PC", "Controller", "VR"},
    CurrentOption = {"PC"},
    Callback = function(option)
        local rs = game:GetService("ReplicatedStorage")
        local FighterRemote = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("Replication") and rs.Remotes.Replication:FindFirstChild("Fighter") and rs.Remotes.Replication.Fighter:FindFirstChild("SetControls")
        
        if not FighterRemote then
            Rayfield:Notify({
                Title = "Error",
                Content = "Could not find SetControls remote!",
                Duration = 3
            })
            return
        end

        local map = {
            Mobile = "Touch",
            PC = "MouseKeyboard",
            Controller = "Gamepad",
            VR = "VR"
        }
        
        FighterRemote:FireServer(map[option[1]])

        Rayfield:Notify({
            Title = "Controls Changed",
            Content = "Switched to " .. option[1],
            Duration = 3
        })
    end
})

local Section = DeviceSpooferTab:CreateSection("this can change your device")

Rayfield:Notify({
    Title = "kn4ght.lol",
    Content = "hello you enjoy the script?",
    Duration = 6.5,
    Image = 4483362458,
})

Rayfield:Notify({
   Title = "hexa.lol (alt bot)",
   Content = "thank you for executing this script!",
   Duration = 6.5,
   Image = "rewind",
})

-- Button: Ragebot
MainTab:CreateButton({
    Name = "execute ragebot (shoot it will hit the player)",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kn4ght-security/Rage/refs/heads/main/rage.lua.txt"))()
    end,
})

-- Button: Fast Melee
MainTab:CreateButton({
    Name = "fast melee",
    Callback = function()
        print("Clicked!")
        loadstring([[
--!native
--!optimize 2

if game.GameId == 6035872082 then
    local Storage = game:GetService("ReplicatedStorage")
    local Items = require(Storage.Modules.ItemLibrary).Items

    -- ====================== FAST MELEE ONLY ======================
    -- No gun modifications, only melee
    
    local meleeExceptions = {
        ["Sniper"] = true,  -- Skip guns
        ["Crossbow"] = true,
        ["Bow"] = true,
        ["RPG"] = true,
        ["Pistol"] = true,
        ["Shotgun"] = true,
        ["Rifle"] = true,
        ["SMG"] = true,
        ["AR"] = true,
        ["Launcher"] = true,
    }

    for name, data in pairs(Items) do
        if typeof(data) == "table" then
            -- Only modify melee weapons (check for melee properties)
            local isMelee = data.AttackCooldown or data.SwingCooldown or data.MeleeCooldown or data.Cooldown
            
            -- Skip if it's a gun
            local isGun = data.ShootSpread or data.ShootAccuracy or data.ShootRecoil or data.ShootCooldown
            
            if isMelee and not isGun then
                -- Fast melee cooldowns
                if data.AttackCooldown then data.AttackCooldown = 0.001 end
                if data.SwingCooldown then data.SwingCooldown = 0.001 end
                if data.MeleeCooldown then data.MeleeCooldown = 0.001 end
                if data.Cooldown then data.Cooldown = 0.001 end
                if data.RecoveryTime then data.RecoveryTime = 0.001 end
                if data.ResetTime then data.ResetTime = 0.001 end
                if data.SwingTime then data.SwingTime = 0.05 end
                if data.HitboxDuration then data.HitboxDuration = 0.05 end
            end
        end
    end

    print("Fast Melee Only - Loaded! (Guns unchanged)")
    print("Made by flapparoblox and wrathscripts, enjoy :)")
end
]])()
    end,
})

-- Button: Fast Firing
MainTab:CreateButton({
   Name = "fast firing",
   Callback = function()
       print("Clicked!")
   loadstring([[
--!native
--!optimize 2

if game.GameId == 6035872082 then
    local Storage = game:GetService("ReplicatedStorage")
    local Items = require(Storage.Modules.ItemLibrary).Items

    -- ====================== FAST FIRE (Guns) ======================
    local gunExceptions = {
        ["Sniper"] = false,
        ["Crossbow"] = false,
        ["Bow"] = false,
        ["RPG"] = false,
    }

    for name, data in pairs(Items) do
        if typeof(data) == "table" and not gunExceptions[name] then
            if data.ShootSpread then data.ShootSpread = 0 end
            if data.ShootAccuracy then data.ShootAccuracy = 0 end
            if data.ShootRecoil then data.ShootRecoil = 0 end
            if data.ShootCooldown then data.ShootCooldown = 0.001 end
            if data.ShootBurstCooldown then data.ShootBurstCooldown = 0.001 end
        end
    end

    -- ====================== FAST MELEE ======================
    for name, data in pairs(Items) do
        if typeof(data) == "table" then
            -- Common melee cooldown properties in Rivals
            if data.AttackCooldown then data.AttackCooldown = 0.001 end
            if data.SwingCooldown then data.SwingCooldown = 0.001 end
            if data.MeleeCooldown then data.MeleeCooldown = 0.001 end
            if data.Cooldown then data.Cooldown = 0.001 end
            if data.RecoveryTime then data.RecoveryTime = 0.001 end
            if data.ResetTime then data.ResetTime = 0.001 end
        end
    end

    print("made by kn4ghtbypasser enjoy")
end
]])()
   end,
})

-- Button: Skin Changer V3
MainTab:CreateButton({
   Name = "skin changer V3",
   Callback = function()
       print("Clicked!")
        loadstring(game:HttpGet("https://raw.githubusercontent.com/supporterlock-source/Skin-changer-V3-BETA/refs/heads/main/skin%20changer%20V3%20(BETA).lua"))()
   end,
})

-- Button: Silent Aim V2 (FIXED)
MainTab:CreateButton({
   Name = "silent aim v2(FIXED)",
   Callback = function()
       print("clicked!")
-- ====================================================
-- SILENT AIM V2 – Standalone Test
-- Paste into console while in-game
-- ====================================================
local rs = game:GetService("ReplicatedStorage")
local utility = require(rs.Modules.Utility)
local plrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")
local me = plrs.LocalPlayer
local oldRay = utility.Raycast

local MAX_DISTANCE = 150
local MIN_DISTANCE = 5
local FOV = 45

local targetCache = { player = nil, time = 0 }
local visCache = {}

local function isSameTeam(player)
    if not player or player == me then return true end
    if me.Team and player.Team and me.Team == player.Team then return true end
    local myTeam = me:GetAttribute("TeamID")
    local targetTeam = player:GetAttribute("TeamID")
    if myTeam and targetTeam and tostring(myTeam) == tostring(targetTeam) then return true end
    local myTeamAttr = me:GetAttribute("Team")
    local targetTeamAttr = player:GetAttribute("Team")
    if myTeamAttr and targetTeamAttr and tostring(myTeamAttr) == tostring(targetTeamAttr) then return true end
    return false
end

local function isMobile()
    return uis.TouchEnabled and not uis.KeyboardEnabled and not uis.MouseEnabled
end

local function getFOV()
    return isMobile() and 35 or FOV
end

local function isVisible(char, part)
    if not char or not part then return false end
    local key = char
    local now = tick()
    local entry = visCache[key]
    if entry and (now - entry.time) < 0.05 then return entry.visible end
    local myChar = me.Character
    if not myChar then return false end
    local root = myChar:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local startPos = root.Position
    local targetPos = part.Position
    local direction = targetPos - startPos
    local dist = direction.Magnitude
    if dist < 1 then
        visCache[key] = { visible = true, time = now }
        return true
    end
    direction = direction.Unit
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { myChar }
    params.IgnoreWater = true
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
    visCache[key] = { visible = visible, time = now }
    return visible
end

local function isInFOV(targetPos)
    local camera = workspace.CurrentCamera
    if not camera then return false end
    local vectorToTarget = (targetPos - camera.CFrame.Position).Unit
    local cameraLook = camera.CFrame.LookVector
    local angle = math.acos(math.clamp(cameraLook:Dot(vectorToTarget), -1, 1))
    return math.deg(angle) <= getFOV()
end

local function getBestTarget()
    local now = tick()
    if targetCache.player and (now - targetCache.time) < 0.05 then
        local p = targetCache.player
        if p and p.Character and p.Character:FindFirstChild("Head") and not isSameTeam(p) then
            local head = p.Character.Head
            local humanoid = p.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and isVisible(p.Character, head) then
                return p
            end
        end
    end

    local myChar = me.Character
    if not myChar then return nil end
    local root = myChar:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local best, bestDist = nil, MAX_DISTANCE + 1
    for _, p in ipairs(plrs:GetPlayers()) do
        if p ~= me and not isSameTeam(p) then
            local char = p.Character
            if char then
                local head = char:FindFirstChild("Head")
                local humanoid = char:FindFirstChild("Humanoid")
                if head and humanoid and humanoid.Health > 0 then
                    local dist = (root.Position - head.Position).Magnitude
                    if dist > MIN_DISTANCE and dist < bestDist and isInFOV(head.Position) then
                        if isVisible(char, head) then
                            bestDist = dist
                            best = p
                        end
                    end
                end
            end
        end
    end
    targetCache.player = best
    targetCache.time = now
    return best
end

utility.Raycast = function(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    local target = getBestTarget()
    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            local pos = head.Position
            local direction = pos - startPos
            local distance = direction.Magnitude
            if distance <= MAX_DISTANCE and distance > 0 then
                direction = direction.Unit
                if maxDist and distance > maxDist then
                    distance = maxDist
                    pos = startPos + direction * maxDist
                end
                return {
                    Position = pos,
                    Distance = distance,
                    Instance = head,
                    Material = head.Material,
                    Normal = -direction
                }
            end
        end
    end
    return oldRay(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
end

print("✅ Silent Aim V2 loaded – now shoot to test (dead body check enabled)")
   end,
})

-- Button: Silent Aim V3 (UPDATED)
MainTab:CreateButton({
   Name = "silent aim V3(UPDATED)",
   Callback = function()
       print("Clicked!")
-- ====================================================
-- SILENT AIM V3 – Standalone Test
-- Paste into console while in-game
-- ====================================================
local rs = game:GetService("ReplicatedStorage")
local utility = require(rs.Modules.Utility)
local plrs = game:GetService("Players")
local workspace = game:GetService("Workspace")
local me = plrs.LocalPlayer
local oldRay = utility.Raycast

local MAX_DISTANCE = 150
local MIN_DISTANCE = 5
local FOV = 60
local HALF_FOV = FOV / 2

local targetCache = { player = nil, time = 0 }
local visCache = {}

local function isSameTeam(player)
    if not player or player == me then return true end
    if me.Team and player.Team and me.Team == player.Team then return true end
    local myTeam = me:GetAttribute("TeamID")
    local targetTeam = player:GetAttribute("TeamID")
    if myTeam and targetTeam and tostring(myTeam) == tostring(targetTeam) then return true end
    local myTeamAttr = me:GetAttribute("Team")
    local targetTeamAttr = player:GetAttribute("Team")
    if myTeamAttr and targetTeamAttr and tostring(myTeamAttr) == tostring(targetTeamAttr) then return true end
    return false
end

local function isInFOV(startPos, lookDirection, targetPos)
    if not startPos or not lookDirection or not targetPos then return false end
    local toTarget = (targetPos - startPos).Unit
    local dot = lookDirection:Dot(toTarget)
    local angle = math.deg(math.acos(dot))
    return angle <= HALF_FOV
end

local function isVisible(char, part)
    if not char or not part then return false end
    local key = char
    local now = tick()
    local entry = visCache[key]
    if entry and (now - entry.time) < 0.05 then return entry.visible end
    local myChar = me.Character
    if not myChar then return false end
    local root = myChar:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local startPos = root.Position
    local targetPos = part.Position
    local dist = (targetPos - startPos).Magnitude
    if dist < 1 then
        visCache[key] = { visible = true, time = now }
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
    visCache[key] = { visible = visible, time = now }
    return visible
end

local function getBestTarget()
    local now = tick()
    if targetCache.player and (now - targetCache.time) < 0.05 then
        local p = targetCache.player
        if p and p.Character and p.Character:FindFirstChild("Head") and not isSameTeam(p) then
            local head = p.Character.Head
            local humanoid = p.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and isVisible(p.Character, head) then
                return p
            end
        end
    end

    local myChar = me.Character
    if not myChar then return nil end
    local root = myChar:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local lookVector = camera.CFrame.LookVector
    local startPos = root.Position

    local best, bestDist = nil, MAX_DISTANCE + 1
    for _, p in ipairs(plrs:GetPlayers()) do
        if p ~= me and not isSameTeam(p) then
            local char = p.Character
            if char then
                local head = char:FindFirstChild("Head")
                local humanoid = char:FindFirstChild("Humanoid")
                if head and humanoid and humanoid.Health > 0 then
                    local dist = (root.Position - head.Position).Magnitude
                    if dist > MIN_DISTANCE and dist < bestDist and isInFOV(startPos, lookVector, head.Position) then
                        if isVisible(char, head) then
                            bestDist = dist
                            best = p
                        end
                    end
                end
            end
        end
    end
    targetCache.player = best
    targetCache.time = now
    return best
end

utility.Raycast = function(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    if not startPos then
        return oldRay(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    end
    local target = getBestTarget()
    if not target or not target.Character then
        return oldRay(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    end

    local targetChar = target.Character
    local targetHead = targetChar:FindFirstChild("Head")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHead or not targetRoot then
        return oldRay(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    end

    local headPos = targetHead.Position
    local rootPos = targetRoot.Position
    local distToHead = (headPos - startPos).Magnitude

    if distToHead > MAX_DISTANCE then
        return oldRay(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    end

    local camera = workspace.CurrentCamera
    if camera then
        local lookVector = camera.CFrame.LookVector
        if not isInFOV(startPos, lookVector, headPos) then
            if not isInFOV(startPos, lookVector, rootPos) then
                return oldRay(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
            end
        end
    end

    local effectiveMaxDist = math.min(maxDist or 1000, MAX_DISTANCE)
    if distToHead > effectiveMaxDist then
        return oldRay(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
    end

    local aimPos = headPos
    if not isVisible(targetChar, targetHead) then
        if isVisible(targetChar, targetRoot) then
            aimPos = rootPos
        else
            return oldRay(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
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

print("✅ Silent Aim V3 loaded – now shoot to test (dead body check enabled)")
   end,
})

-- Button: No Spread
MainTab:CreateButton({
   Name = "no spread",
   Callback = function()
       print("Clicked!")
       -- FAST FIRING (NO RECOIL/SPREAD)
       local ReplicatedStorage = game:GetService("ReplicatedStorage")
       local ItemLibrary = require(ReplicatedStorage.Modules.ItemLibrary)

       local function setPerfect(tbl)
           for _, v in pairs(tbl) do
               if typeof(v) == "table" then
                   if v.ShootSpread then 
                       v.ShootSpread = 0 
                   end
                   if v.ShootAccuracy then 
                       v.ShootAccuracy = 0 
                   end
                   if v.ShootRecoil then 
                       v.ShootRecoil = 0 
                   end
                   setPerfect(v)
               end
           end
       end

       setPerfect(ItemLibrary)
       print("✅ Fast Firing - No Recoil/Spread Loaded!")
   end,  -- <-- CLOSED callback
})      -- <-- CLOSED button

local Button = MainTab:CreateButton({
   Name = "Enable aimbot",
   Callback = function()
   -- INSTANT AIMBOT – Throttled scanning, but aim updates every frame
local player = game:GetService("Players").LocalPlayer

repeat task.wait() until player and player.Character
local ctrl = player.PlayerScripts:WaitForChild("Controllers", math.huge)
local cc = require(ctrl:WaitForChild("CameraController", math.huge))

local MAX_DISTANCE = 150
local MIN_DISTANCE = 5
local DEADZONE_ANGLE = 0.5
local SCAN_INTERVAL = 0.1          -- how often we search for a new target

-- Caches
local currentTarget = nil          -- player object we're aiming at
local lastScanTime = 0
local currentAim = nil             -- last applied rotation (for deadzone)
local visCache = {}

-- Team check
local function isEnemy(target)
    if target == player then return false end
    local char = target.Character
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    local myTeam = player.Team or player:GetAttribute("Team") or player:GetAttribute("TeamID")
    local theirTeam = target.Team or target:GetAttribute("Team") or target:GetAttribute("TeamID")
    if myTeam and theirTeam then
        return myTeam ~= theirTeam
    end
    return true
end

-- Visibility (cached for 50ms)
local function isVisible(char, part)
    if not char or not part then return false end
    local key = char
    local now = tick()
    local entry = visCache[key]
    if entry and (now - entry.time) < 0.05 then
        return entry.visible
    end

    local camera = workspace.CurrentCamera
    if not camera then return false end
    local startPos = camera.CFrame.Position
    local targetPos = part.Position
    local direction = targetPos - startPos
    local dist = direction.Magnitude
    if dist < 1 then
        visCache[key] = { visible = true, time = now }
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { player.Character, char }
    params.IgnoreWater = true

    local result = workspace:Raycast(startPos, direction.Unit * dist, params)
    local visible = false
    if not result then
        visible = true
    else
        local hit = result.Instance
        if hit and (hit == part or hit:IsDescendantOf(char)) then
            visible = true
        end
    end
    visCache[key] = { visible = visible, time = now }
    return visible
end

-- Scan for the best target (runs every SCAN_INTERVAL)
local function scanForTarget()
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local best, bestDist = nil, MAX_DISTANCE + 1
    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
        if isEnemy(plr) then
            local tChar = plr.Character
            if tChar then
                local head = tChar:FindFirstChild("Head")
                if head then
                    local dist = (root.Position - head.Position).Magnitude
                    if dist > MIN_DISTANCE and dist < bestDist then
                        if isVisible(tChar, head) then
                            bestDist = dist
                            best = plr
                        end
                    end
                end
            end
        end
    end
    return best
end

-- Angle between two CFrames (forward vectors)
local function angleBetween(cf1, cf2)
    local _, _, _, _, _, _, _, _, _, r31, r32, r33 = cf1:components()
    local _, _, _, _, _, _, _, _, _, s31, s32, s33 = cf2:components()
    local dot = r31*s31 + r32*s32 + r33*s33
    return math.deg(math.acos(math.clamp(dot, -1, 1)))
end

-- Main loop – runs every frame
game:GetService("RunService").Heartbeat:Connect(function()
    local camera = workspace.CurrentCamera
    if not camera then return end

    -- Update target periodically
    local now = tick()
    if now - lastScanTime >= SCAN_INTERVAL then
        lastScanTime = now
        currentTarget = scanForTarget()
        -- If we lost target, clear visCache to avoid stale entries
        if not currentTarget then
            visCache = {}
        end
    end

    if currentTarget and currentTarget.Character then
        local head = currentTarget.Character:FindFirstChild("Head")
        if head then
            local desiredCF = CFrame.lookAt(camera.CFrame.Position, head.Position)
            local desiredRotation = desiredCF - desiredCF.Position

            -- Deadzone check: only snap if we moved more than DEADZONE_ANGLE
            if not currentAim or angleBetween(currentAim, desiredRotation) > DEADZONE_ANGLE then
                currentAim = desiredRotation
                cc:MimicRotation(desiredRotation)
            else
                -- Stay stable – keep current aim
                cc:MimicRotation(currentAim)
            end
        end
    else
        currentAim = nil   -- no target, reset
    end
end)

-- Cleanup on respawn
player.CharacterAdded:Connect(function()
    currentTarget = nil
    currentAim = nil
    visCache = {}
end)

game:GetService("Players").PlayerRemoving:Connect(function()
    currentTarget = nil
    currentAim = nil
    visCache = {}
end)

print("🚀 Instant aimbot (fixed) – scanning every " .. SCAN_INTERVAL .. "s, updating every frame")
end})

local Button = MainTab:CreateButton({
   Name = "Enable aimbot 0.3 smoothing",
   Callback = function()
    -- SMOOTHING AIMBOT – Throttled scanning, smooth aim every frame
local player = game:GetService("Players").LocalPlayer

repeat task.wait() until player and player.Character
local ctrl = player.PlayerScripts:WaitForChild("Controllers", math.huge)
local cc = require(ctrl:WaitForChild("CameraController", math.huge))

local MAX_DISTANCE = 150
local MIN_DISTANCE = 5
local SMOOTHNESS = 0.3
local DEADZONE_ANGLE = 0.5
local SCAN_INTERVAL = 0.1

local currentTarget = nil
local lastScanTime = 0
local currentAim = nil
local visCache = {}

local function isEnemy(target)
    if target == player then return false end
    local char = target.Character
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    local myTeam = player.Team or player:GetAttribute("Team") or player:GetAttribute("TeamID")
    local theirTeam = target.Team or target:GetAttribute("Team") or target:GetAttribute("TeamID")
    if myTeam and theirTeam then
        return myTeam ~= theirTeam
    end
    return true
end

local function isVisible(char, part)
    if not char or not part then return false end
    local key = char
    local now = tick()
    local entry = visCache[key]
    if entry and (now - entry.time) < 0.05 then
        return entry.visible
    end

    local camera = workspace.CurrentCamera
    if not camera then return false end
    local startPos = camera.CFrame.Position
    local targetPos = part.Position
    local direction = targetPos - startPos
    local dist = direction.Magnitude
    if dist < 1 then
        visCache[key] = { visible = true, time = now }
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { player.Character, char }
    params.IgnoreWater = true

    local result = workspace:Raycast(startPos, direction.Unit * dist, params)
    local visible = false
    if not result then
        visible = true
    else
        local hit = result.Instance
        if hit and (hit == part or hit:IsDescendantOf(char)) then
            visible = true
        end
    end
    visCache[key] = { visible = visible, time = now }
    return visible
end

local function scanForTarget()
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local best, bestDist = nil, MAX_DISTANCE + 1
    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
        if isEnemy(plr) then
            local tChar = plr.Character
            if tChar then
                local head = tChar:FindFirstChild("Head")
                if head then
                    local dist = (root.Position - head.Position).Magnitude
                    if dist > MIN_DISTANCE and dist < bestDist then
                        if isVisible(tChar, head) then
                            bestDist = dist
                            best = plr
                        end
                    end
                end
            end
        end
    end
    return best
end

local function angleBetween(cf1, cf2)
    local _, _, _, _, _, _, _, _, _, r31, r32, r33 = cf1:components()
    local _, _, _, _, _, _, _, _, _, s31, s32, s33 = cf2:components()
    local dot = r31*s31 + r32*s32 + r33*s33
    return math.deg(math.acos(math.clamp(dot, -1, 1)))
end

game:GetService("RunService").Heartbeat:Connect(function()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local now = tick()
    if now - lastScanTime >= SCAN_INTERVAL then
        lastScanTime = now
        currentTarget = scanForTarget()
        if not currentTarget then
            visCache = {}
        end
    end

    if currentTarget and currentTarget.Character then
        local head = currentTarget.Character:FindFirstChild("Head")
        if head then
            local desiredCF = CFrame.lookAt(camera.CFrame.Position, head.Position)
            local desiredRotation = desiredCF - desiredCF.Position

            -- Deadzone check
            if not currentAim or angleBetween(currentAim, desiredRotation) > DEADZONE_ANGLE then
                currentAim = desiredRotation
                -- Smoothly interpolate from current camera rotation to desired
                local currentRotation = camera.CFrame - camera.CFrame.Position
                local newRotation = currentRotation:Lerp(desiredRotation, 1 - SMOOTHNESS)
                cc:MimicRotation(newRotation)
            else
                -- Keep stable
                cc:MimicRotation(currentAim)
            end
        end
    else
        currentAim = nil
    end
end)

player.CharacterAdded:Connect(function()
    currentTarget = nil
    currentAim = nil
    visCache = {}
end)

game:GetService("Players").PlayerRemoving:Connect(function()
    currentTarget = nil
    currentAim = nil
    visCache = {}
end)

print("🚀 Smooth aimbot (fixed) – scanning every " .. SCAN_INTERVAL .. "s, smoothing every frame")
end})

local Button = MainTab:CreateButton({
   Name = "asteroid hub (backup)",
   Callback = function()
   loadstring(game:HttpGet("https://raw.githubusercontent.com/kn4ght-security/Hexahubscripts/refs/heads/main/asteroid.lua.txt"))()
   end,
})

local Button = VisualsTab:CreateButton({
   Name = "Esp",
   Callback = function()
   local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local MAX_DISTANCE = 250
local UPDATE_INTERVAL = 0.2

local cache = {}

local function removePlayer(player)
    local highlight = cache[player]

    if highlight then
        highlight:Destroy()
        cache[player] = nil
    end
end

local function createESP(player, character)
    if player == LocalPlayer then
        return
    end

    removePlayer(player)

    if not character then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "CachedESP"

    -- Blue ESP
    highlight.FillColor = Color3.fromRGB(0, 120, 255)
    highlight.OutlineColor = Color3.fromRGB(0, 200, 255)

    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0

    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character

    cache[player] = highlight
end

local function updateESP(player)
    local highlight = cache[player]

    if not highlight then
        return
    end

    local character = player.Character
    local myCharacter = LocalPlayer.Character

    if not character or not myCharacter then
        highlight.Enabled = false
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")

    if not root or not myRoot then
        highlight.Enabled = false
        return
    end

    local distance = (root.Position - myRoot.Position).Magnitude

    highlight.Enabled = distance <= MAX_DISTANCE
end

local function setupPlayer(player)
    if player == LocalPlayer then
        return
    end

    if player.Character then
        createESP(player, player.Character)
    end

    player.CharacterAdded:Connect(function(character)
        task.wait(0.1)

        if player.Parent then
            createESP(player, character)
        end
    end)

    player.CharacterRemoving:Connect(function()
        local highlight = cache[player]

        if highlight then
            highlight.Enabled = false
        end
    end)
end

-- Existing players
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

-- New players
Players.PlayerAdded:Connect(setupPlayer)

-- Cleanup
Players.PlayerRemoving:Connect(removePlayer)

-- Distance updater
task.spawn(function()
    while task.wait(UPDATE_INTERVAL) do
        for player in pairs(cache) do
            updateESP(player)
        end
    end
end)
   end,
})

local Button = UtilityTab:CreateButton({
   Name = "infinite jump",
   Callback = function()
   local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local enabled = true

local jumping = false

local function jump()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and humanoid.Health > 0 then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

UserInputService.JumpRequest:Connect(function()
    if not enabled then
        return
    end

    -- Jump immediately
    jump()

    -- Continue while JumpRequest keeps firing
    if jumping then
        return
    end

    jumping = true

    task.spawn(function()
        while jumping and enabled do
            jump()
            task.wait(0.12)
        end
    end)

    task.delay(0.2, function()
        jumping = false
    end)
end)
   end,
})

print("kn4ght hub loaded!")
print("kn4ght hub loaded!")