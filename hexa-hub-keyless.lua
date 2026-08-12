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

local MainTab = Window:CreateTab("Main", 4483362458)
local DeviceSpooferTab = Window:CreateTab("Device Spoofer", "rewind")

-------------------------------------------------
-- CONTROLS DROPDOWN
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

-- Button: Fast Melee (unchanged)
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

    local meleeExceptions = {
        ["Sniper"] = true,
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
            local isMelee = data.AttackCooldown or data.SwingCooldown or data.MeleeCooldown or data.Cooldown
            local isGun = data.ShootSpread or data.ShootAccuracy or data.ShootRecoil or data.ShootCooldown
            
            if isMelee and not isGun then
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

    print("Fast Melee Only - Loaded!")
end
]])()
    end,
})

-- Button: Fast Firing (unchanged)
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

    for name, data in pairs(Items) do
        if typeof(data) == "table" then
            if data.AttackCooldown then data.AttackCooldown = 0.001 end
            if data.SwingCooldown then data.SwingCooldown = 0.001 end
            if data.MeleeCooldown then data.MeleeCooldown = 0.001 end
            if data.Cooldown then data.Cooldown = 0.001 end
            if data.RecoveryTime then data.RecoveryTime = 0.001 end
            if data.ResetTime then data.ResetTime = 0.001 end
        end
    end

    print("Fast Fire + Melee Loaded")
end
]])()
   end,
})

-- Button: Skin Changer V3 (unchanged)
MainTab:CreateButton({
   Name = "skin changer V3",
   Callback = function()
       print("Clicked!")
        loadstring(game:HttpGet("https://raw.githubusercontent.com/supporterlock-source/Skin-changer-V3-BETA/refs/heads/main/skin%20changer%20V3%20(BETA).lua"))()
   end,
})

-----------------------------------------------------------
-- ⚡ OPTIMIZED SILENT AIM V2 (FIXED)
-----------------------------------------------------------
MainTab:CreateButton({
   Name = "silent aim v2(FIXED)",
   Callback = function()
       print("clicked!")
       local rs = game:GetService("ReplicatedStorage")
       local utility = require(rs.Modules.Utility)
       local plrs = game:GetService("Players")
       local uis = game:GetService("UserInputService")
       local workspace = game:GetService("Workspace")

       local me = plrs.LocalPlayer
       local oldRay = utility.Raycast

       -- CONFIG
       local MAX_DISTANCE = 150
       local MIN_DISTANCE = 5
       local FOV = 45

       -- Caching for best target (recomputed only every 50ms)
       local targetCache = { player = nil, time = 0 }

       local function isMobile()
           return uis.TouchEnabled and not uis.KeyboardEnabled and not uis.MouseEnabled
       end

       local function getFOV()
           if isMobile() then return 35 end
           return FOV
       end

       -- Visibility cache: per character, valid for 50ms
       local visCache = {}
       local function isVisible(char, part)
           if not char or not part then return false end
           local key = char
           local now = tick()
           local entry = visCache[key]
           if entry and (now - entry.time) < 0.05 then
               return entry.visible
           end
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

       -- Find best target (cached)
       local function getBestTarget()
           local now = tick()
           if targetCache.player and (now - targetCache.time) < 0.05 then
               -- validate cached target
               local p = targetCache.player
               if p and p.Character and p.Character:FindFirstChild("Head") and not isSameTeam(p) then
                   local head = p.Character.Head
                   if isVisible(p.Character, head) then
                       return p
                   end
               end
           end
           -- scan
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
                       if head then
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

       -- Override raycast
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
   end,
})

-----------------------------------------------------------
-- ⚡ OPTIMIZED SILENT AIM V3 (UPDATED)
-----------------------------------------------------------
MainTab:CreateButton({
   Name = "silent aim V3(UPDATED)",
   Callback = function()
       print("Clicked!")
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

       -- Caches
       local targetCache = { player = nil, time = 0 }
       local visCache = {}

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
           if entry and (now - entry.time) < 0.05 then
               return entry.visible
           end
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
                   if isVisible(p.Character, head) then
                       return p
                   end
               end
           end
           -- scan
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
                       if head then
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

           -- FOV check
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

           -- Try head, fallback to root
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

       me.CharacterAdded:Connect(function()
           targetCache.player = nil
           targetCache.time = 0
           visCache = {}
       end)

       plrs.PlayerRemoving:Connect(function()
           targetCache.player = nil
           targetCache.time = 0
           visCache = {}
       end)
   end,
})

-- Button: No Spread (unchanged)
MainTab:CreateButton({
   Name = "no spread",
   Callback = function()
       print("Clicked!")
       local ReplicatedStorage = game:GetService("ReplicatedStorage")
       local ItemLibrary = require(ReplicatedStorage.Modules.ItemLibrary)

       local function setPerfect(tbl)
           for _, v in pairs(tbl) do
               if typeof(v) == "table" then
                   if v.ShootSpread then v.ShootSpread = 0 end
                   if v.ShootAccuracy then v.ShootAccuracy = 0 end
                   if v.ShootRecoil then v.ShootRecoil = 0 end
                   setPerfect(v)
               end
           end
       end

       setPerfect(ItemLibrary)
       print("✅ Fast Firing - No Recoil/Spread Loaded!")
   end,
})

-----------------------------------------------------------
-- ⚡ OPTIMIZED AIMBOT (INSTANT) – Throttled & Cached
-----------------------------------------------------------
local Button = MainTab:CreateButton({
   Name = "Enable aimbot",
   Callback = function()
       print("Aimbot (instant) loaded with caching & throttling")

       local player = game:GetService("Players").LocalPlayer
       repeat task.wait() until player and player.Character
       local ctrl = player.PlayerScripts:WaitForChild("Controllers", math.huge)
       local cc = require(ctrl:WaitForChild("CameraController", math.huge))

       local MAX_DISTANCE = 150
       local MIN_DISTANCE = 5
       local SCAN_INTERVAL = 0.1 -- seconds

       -- Caches
       local targetCache = { player = nil, time = 0 }
       local visCache = {}

       local function isEnemy(target)
           if target == player then return false end
           local char = target.Character
           if not char then return false end
           local hum = char:FindFirstChild("Humanoid")
           if not hum or hum.Health <= 0 then return false end
           return not isSameTeam(target)
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

       local function getClosestEnemy()
           local now = tick()
           if targetCache.player and (now - targetCache.time) < SCAN_INTERVAL then
               local p = targetCache.player
               if p and p.Character and p.Character:FindFirstChild("Head") and isEnemy(p) then
                   local head = p.Character.Head
                   if isVisible(p.Character, head) then
                       return p
                   end
               end
           end

           local char = player.Character
           if not char then return nil end
           local root = char:FindFirstChild("HumanoidRootPart")
           if not root then return nil end

           local best, bestDist = nil, MAX_DISTANCE + 1
           for _, plr in ipairs(Players:GetPlayers()) do
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
           targetCache.player = best
           targetCache.time = now
           return best
       end

       -- Run on Heartbeat with interval
       local elapsed = 0
       local connection
       connection = game:GetService("RunService").Heartbeat:Connect(function(delta)
           elapsed = elapsed + delta
           if elapsed >= SCAN_INTERVAL then
               elapsed = 0
               local target = getClosestEnemy()
               if target and target.Character then
                   local head = target.Character:FindFirstChild("Head")
                   if head then
                       local camera = workspace.CurrentCamera
                       if camera then
                           local targetCF = CFrame.lookAt(camera.CFrame.Position, head.Position)
                           local targetRotation = targetCF - targetCF.Position
                           cc:MimicRotation(targetRotation)
                       end
                   end
               end
           end
       end)

       player.CharacterAdded:Connect(function()
           targetCache.player = nil
           targetCache.time = 0
           visCache = {}
       end)

       Players.PlayerRemoving:Connect(function()
           targetCache.player = nil
           targetCache.time = 0
           visCache = {}
       end)

       -- cleanup when button pressed again? we'll just let it run.
       print("🚀 Instant aimbot with throttling loaded (scan every " .. SCAN_INTERVAL .. "s)")
   end,
})

-----------------------------------------------------------
-- ⚡ OPTIMIZED AIMBOT (0.3 SMOOTHING) – Throttled
-----------------------------------------------------------
local Button = MainTab:CreateButton({
   Name = "Enable aimbot 0.3 smoothing",
   Callback = function()
       print("Aimbot (smooth) loaded with caching & throttling")

       local player = game:GetService("Players").LocalPlayer
       repeat task.wait() until player and player.Character
       local ctrl = player.PlayerScripts:WaitForChild("Controllers", math.huge)
       local cc = require(ctrl:WaitForChild("CameraController", math.huge))

       local MAX_DISTANCE = 150
       local MIN_DISTANCE = 5
       local SMOOTHNESS = 0.3
       local SCAN_INTERVAL = 0.1

       local targetCache = { player = nil, time = 0 }
       local visCache = {}

       local function isEnemy(target)
           if target == player then return false end
           local char = target.Character
           if not char then return false end
           local hum = char:FindFirstChild("Humanoid")
           if not hum or hum.Health <= 0 then return false end
           return not isSameTeam(target)
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

       local function getClosestEnemy()
           local now = tick()
           if targetCache.player and (now - targetCache.time) < SCAN_INTERVAL then
               local p = targetCache.player
               if p and p.Character and p.Character:FindFirstChild("Head") and isEnemy(p) then
                   local head = p.Character.Head
                   if isVisible(p.Character, head) then
                       return p
                   end
               end
           end

           local char = player.Character
           if not char then return nil end
           local root = char:FindFirstChild("HumanoidRootPart")
           if not root then return nil end

           local best, bestDist = nil, MAX_DISTANCE + 1
           for _, plr in ipairs(Players:GetPlayers()) do
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
           targetCache.player = best
           targetCache.time = now
           return best
       end

       local elapsed = 0
       game:GetService("RunService").Heartbeat:Connect(function(delta)
           elapsed = elapsed + delta
           if elapsed >= SCAN_INTERVAL then
               elapsed = 0
               local target = getClosestEnemy()
               if target and target.Character then
                   local head = target.Character:FindFirstChild("Head")
                   if head then
                       local camera = workspace.CurrentCamera
                       if camera then
                           local targetCF = CFrame.lookAt(camera.CFrame.Position, head.Position)
                           local targetRotation = targetCF - targetCF.Position
                           local currentRotation = camera.CFrame - camera.CFrame.Position
                           local newRotation = currentRotation:Lerp(targetRotation, 1 - SMOOTHNESS)
                           cc:MimicRotation(newRotation)
                       end
                   end
               end
           end
       end)

       player.CharacterAdded:Connect(function()
           targetCache.player = nil
           targetCache.time = 0
           visCache = {}
       end)

       Players.PlayerRemoving:Connect(function()
           targetCache.player = nil
           targetCache.time = 0
           visCache = {}
       end)

       print("🚀 Smooth aimbot with throttling loaded (scan every " .. SCAN_INTERVAL .. "s)")
   end,
})

-- Button: Asteroid hub (unchanged)
local Button = MainTab:CreateButton({
   Name = "asteroid hub (backup)",
   Callback = function()
   loadstring(game:HttpGet("https://raw.githubusercontent.com/kn4ght-security/Hexahubscripts/refs/heads/main/asteroid.lua.txt"))()
   end,
})

print("kn4ght hub loaded!")
print("kn4ght hub loaded!")