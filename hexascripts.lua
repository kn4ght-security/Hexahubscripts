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
       local rs = game:GetService("ReplicatedStorage")
       local utility = require(rs.Modules.Utility)
       local plrs = game:GetService("Players")
       local uis = game:GetService("UserInputService")

       local me = plrs.LocalPlayer
       local oldRay = utility.Raycast

       -- CONFIG
       local MAX_DISTANCE = 150
       local MIN_DISTANCE = 5
       local FOV = 45 -- Default FOV

       -- Detect if on mobile
       local function isMobile()
           return uis.TouchEnabled and not uis.KeyboardEnabled and not uis.MouseEnabled
       end

       -- Adjust FOV for mobile (smaller, more focused)
       local function getFOV()
           if isMobile() then
               return 35 -- Smaller FOV for mobile to prevent snapping to targets outside view
           end
           return FOV
       end

       -- TEAM CHECK
       local function isSameTeam(player)
           if not player or player == me then
               return true
           end

           if me.Team and player.Team and me.Team == player.Team then
               return true
           end

           local myTeam = me:GetAttribute("TeamID") or me:GetAttribute("Team")
           local targetTeam = player:GetAttribute("TeamID") or player:GetAttribute("Team")

           if myTeam ~= nil and targetTeam ~= nil then
               return tostring(myTeam) == tostring(targetTeam)
           end

           return false
       end

       -- WALL / LINE-OF-SIGHT CHECK
       local function canSeeTarget(character, targetPart)
           local myCharacter = me.Character

           if not myCharacter or not targetPart then
               return false
           end

           local root = myCharacter:FindFirstChild("HumanoidRootPart")

           if not root then
               return false
           end

           local direction = targetPart.Position - root.Position

           if direction.Magnitude <= 0 then
               return false
           end

           local params = RaycastParams.new()
           params.FilterType = Enum.RaycastFilterType.Exclude
           params.FilterDescendantsInstances = {
               myCharacter
           }
           params.IgnoreWater = true

           local result = workspace:Raycast(
               root.Position,
               direction,
               params
           )

           if not result then
               return true
           end

           return result.Instance:IsDescendantOf(character)
       end

       -- Check if target is within FOV
       local function isInFOV(targetPosition)
           local camera = workspace.CurrentCamera
           if not camera then return false end
           
           -- Get vector from camera to target
           local vectorToTarget = (targetPosition - camera.CFrame.Position).Unit
           -- Get camera's look direction
           local cameraLook = camera.CFrame.LookVector
           
           -- Calculate angle between camera look direction and target
           local angle = math.acos(math.clamp(cameraLook:Dot(vectorToTarget), -1, 1))
           local degrees = math.deg(angle)
           
           return degrees <= getFOV()
       end

       -- FIND CLOSEST VISIBLE ENEMY
       local function getClosest()
           local char = me.Character

           if not char then
               return nil
           end

           local root = char:FindFirstChild("HumanoidRootPart")

           if not root then
               return nil
           end

           local closest = nil
           local closestDist = MAX_DISTANCE + 1
           local currentFOV = getFOV()

           for _, p in ipairs(plrs:GetPlayers()) do
               if p ~= me and p.Character and not isSameTeam(p) then

                   local character = p.Character
                   local theirRoot = character:FindFirstChild("HumanoidRootPart")
                   local head = character:FindFirstChild("Head")
                   local humanoid = character:FindFirstChildOfClass("Humanoid")

                   if theirRoot and head and humanoid and humanoid.Health > 0 then

                       local distance =
                           (root.Position - theirRoot.Position).Magnitude

                       -- Check FOV first for performance
                       if isInFOV(head.Position) then
                           if distance > MIN_DISTANCE
                               and distance < closestDist
                               and canSeeTarget(character, head) then

                               closestDist = distance
                               closest = p
                           end
                       end
                   end
               end
           end

           return closest
       end

       -- CUSTOM RAYCAST
       utility.Raycast = function(
           self,
           startPos,
           endPos,
           maxDist,
           filterList,
           filterType,
           debugMode
       )

           local target = getClosest()

           if not target
               or not target.Character
               or not target.Character:FindFirstChild("Head") then

               return oldRay(
                   self,
                   startPos,
                   endPos,
                   maxDist,
                   filterList,
                   filterType,
                   debugMode
               )
           end

           local head = target.Character.Head
           local pos = head.Position
           local direction = pos - startPos
           local distance = direction.Magnitude

           if distance > MAX_DISTANCE or distance <= 0 then
               return oldRay(
                   self,
                   startPos,
                   endPos,
                   maxDist,
                   filterList,
                   filterType,
                   debugMode
               )
           end

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
   end,  -- <-- CLOSED v2 callback
})      -- <-- CLOSED v2 button

-- Button: Silent Aim V3 (UPDATED)
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

       local cachedTarget = nil
       local cacheTime = 0
       local CACHE_DURATION = 0.1

       local MAX_DISTANCE = 150
       local MIN_DISTANCE = 5

       -- FOV settings (in degrees)
       local FOV = 60  -- Reduced FOV for mobile (not 360)
       local HALF_FOV = FOV / 2

       -- Use the universal team check
       local function isSameTeam(player)
           if not player or player == me then
               return true
           end

           if me.Team and player.Team then
               if me.Team == player.Team then
                   return true
               end
           end

           local myTeam = me:GetAttribute("TeamID") or me:GetAttribute("Team")
           local targetTeam = player:GetAttribute("TeamID") or player:GetAttribute("Team")
           
           if myTeam ~= nil and targetTeam ~= nil then
               if tostring(myTeam) == tostring(targetTeam) then
                   return true
               end
           end

           return false
       end

       -- Check if target is within FOV
       local function isInFOV(startPos, lookDirection, targetPos)
           if not startPos or not lookDirection or not targetPos then
               return false
           end
           
           local toTarget = (targetPos - startPos).Unit
           local dot = lookDirection:Dot(toTarget)
           local angle = math.deg(math.acos(dot))
           
           return angle <= HALF_FOV
       end

       local function getClosest()
           local now = tick()
           
           if cachedTarget and (now - cacheTime) < CACHE_DURATION then
               if cachedTarget.Character and cachedTarget.Character:FindFirstChild("Humanoid") and cachedTarget.Character.Humanoid.Health > 0 and not isSameTeam(cachedTarget) then
                   local char = me.Character
                   if char then
                       local root = char:FindFirstChild("HumanoidRootPart")
                       if root then
                           local theirRoot = cachedTarget.Character:FindFirstChild("HumanoidRootPart")
                           if theirRoot then
                               local d = (root.Position - theirRoot.Position).Magnitude
                               if d > MIN_DISTANCE and d < MAX_DISTANCE then
                                   return cachedTarget
                               end
                           end
                       end
                   end
                   cachedTarget = nil
               else
                   cachedTarget = nil
               end
           end
           
           local char = me.Character
           if not char then 
               cachedTarget = nil
               return nil 
           end
           
           local root = char:FindFirstChild("HumanoidRootPart")
           if not root then 
               cachedTarget = nil
               return nil 
           end
           
           -- Get camera for FOV calculation
           local camera = workspace.CurrentCamera
           if not camera then
               cachedTarget = nil
               return nil
           end
           
           local lookVector = camera.CFrame.LookVector
           local startPos = root.Position
           
           local closest = nil
           local closestDist = MAX_DISTANCE + 1
           
           for _, p in ipairs(plrs:GetPlayers()) do
               if p ~= me and p.Character then
                   local theirRoot = p.Character:FindFirstChild("HumanoidRootPart")
                   local humanoid = p.Character:FindFirstChild("Humanoid")
                   
                   -- ENEMY CHECK: Alive AND NOT same team
                   if theirRoot and humanoid and humanoid.Health > 0 and not isSameTeam(p) then
                       local d = (root.Position - theirRoot.Position).Magnitude
                       
                       if d > MIN_DISTANCE and d < closestDist then
                           -- Check if target is within FOV
                           if isInFOV(startPos, lookVector, theirRoot.Position) then
                               closestDist = d
                               closest = p
                           end
                       end
                   end
               end
           end
           
           cachedTarget = closest
           cacheTime = now
           return closest
       end

       local function isVisible(startPos, targetPos, targetCharacter)
           if not startPos or not targetPos or not targetCharacter then
               return false
           end
           
           local dist = (targetPos - startPos).Magnitude
           if dist < 2 then
               return true
           end
           
           if dist > MAX_DISTANCE then
               return false
           end
           
           local params = RaycastParams.new()
           params.FilterType = Enum.RaycastFilterType.Blacklist
           
           local filterList = {me.Character, targetCharacter}
           params.FilterDescendantsInstances = filterList
           params.IgnoreWater = true
           
           local direction = (targetPos - startPos).Unit
           local result = workspace:Raycast(startPos, direction * dist, params)
           
           if not result then
               return true
           end
           
           local hit = result.Instance
           if hit then
               local hitParent = hit.Parent
               if hit == targetCharacter or hit:IsDescendantOf(targetCharacter) then
                   return true
               end
               if hitParent and (hitParent == targetCharacter or hitParent:IsDescendantOf(targetCharacter)) then
                   return true
               end
           end
           
           return false
       end

       utility.Raycast = function(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
           if not startPos then
               return oldRay(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
           end
           
           local target = getClosest()
           
           if not target or not target.Character then
               return oldRay(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
           end
           
           local targetChar = target.Character
           if not targetChar or not targetChar.Parent then
               return oldRay(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
           end
           
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
           
           -- Check FOV for the target head
           local camera = workspace.CurrentCamera
           if camera then
               local lookVector = camera.CFrame.LookVector
               if not isInFOV(startPos, lookVector, headPos) then
                   -- Check if root is within FOV as fallback
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
           
           local visible = isVisible(startPos, aimPos, targetChar)
           
           if not visible then
               visible = isVisible(startPos, rootPos, targetChar)
               if visible then
                   aimPos = rootPos
               end
           end
           
           if not visible then
               return oldRay(self, startPos, endPos, maxDist, filterList, filterType, debugMode)
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
           cachedTarget = nil
           cacheTime = 0
       end)

       plrs.PlayerRemoving:Connect(function()
           cachedTarget = nil
           cacheTime = 0
       end)
   end,  -- <-- CLOSED v3 callback
})      -- <-- CLOSED v3 button

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

print("kn4ght hub loaded!")
print("kn4ght hub loaded!")