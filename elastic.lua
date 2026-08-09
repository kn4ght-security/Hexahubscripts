local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
-----------------------------------------------------------
-- [UI Library Load & Window Creation]
-----------------------------------------------------------
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo.."Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "Rivals Hub",
    Footer = "Rivals Core",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true
})

local Tabs = {
    ["Main"] = Window:AddTab("Main", "home"),
    ["ESP"] = Window:AddTab("ESP", "eye"),
    ["Visuals"] = Window:AddTab("Visuals", "image"),
    ["Character"] = Window:AddTab("Character", "user"),
    ["Misc"] = Window:AddTab("Misc", "globe"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings")
}

-----------------------------------------------------------
-- [Global Control Variables]
-----------------------------------------------------------
local auraEnabled = false
local projectileEnabled = false
local orbitEnabled = false 
local orbitStuds = 50000000 
local voidSpamEnabled = false
local voidSpamHeight = 50
local godModeEnabled = false

local espEnabled = false
local espBoxes = true
local espNames = true
local espHealth = true

local collectHealth = false 
local collectAmmo = false   

local rageFovEnabled = false 
local rageWallbangViewEnabled = false
local noRecoilEnabled = false
local noSpreadEnabled = false
local noMuzzleFlashEnabled = false
local attackCooldownValue = 100

-- Anti-Aim globals
local antiAimEnabled = false
local antiAimCustomYaw = 180
local antiAimCustomPitch = 90
local antiAimPitchType = "Hide Head"
local antiAimYawType = "Backwards"

local mobileFlyEnabled = false
local pcFlyEnabled = false
local flySpeedMobile = 50
local flySpeedPc = 50
local noclipEnabled = false
local noclipMode = "all walls"

local emoteHopEnabled = false
local emoteHopSpeed = 40
local currentEmoteTrack = nil
local emoteAnimationInstance = nil

local thirdPersonEnabled = false
local thirdPersonMode = "Right"

local deviceSpooferEnabled = false
local deviceSpooferMode = "VR"

-- Name/Level spoofing
local visualTargetName = ""
local visualTargetLevel = ""

local isMouseDown = false 
local isRightMouseDown = false 
local virtualGroundPos = Vector3.zero
local cameraOffset = Vector3.new(0, 2, 0)
local originalPosition = nil
local isSpecialPlace = (game.PlaceId == 129604661913557 or game.PlaceId == 71874690745115)
local currentTargetHitbox = nil
local currentTargetModel = nil 

-- ★ Auto Backstab toggle ★
local backstabEnabled = false

-----------------------------------------------------------
-- [Utility Functions]
-----------------------------------------------------------
local function chid_to_id(chid) return string.byte(chid or string.char(0)) end

local function toggleTableAttribute(attribute, value)
    for _, gcVal in pairs(getgc(true)) do
        if type(gcVal) == "table" and rawget(gcVal, attribute) then
            gcVal[attribute] = value
        end
    end
end

local function getClosestPlayer(referencePos)
    local closestPlayer = nil
    local shortestDistance = math.huge
    local myEnvAttr = LocalPlayer:GetAttribute("EnvironmentID")
    if not myEnvAttr then return nil end
    local myEnv = chid_to_id(myEnvAttr)
    local myTeam = chid_to_id(LocalPlayer:GetAttribute("TeamID"))

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player:GetAttribute("EnvironmentID") then
            local hEnv = chid_to_id(player:GetAttribute("EnvironmentID"))
            local hTeam = chid_to_id(player:GetAttribute("TeamID"))
            local valid = isSpecialPlace and (hEnv == myEnv) or (hEnv == myEnv and hTeam ~= myTeam)

            if valid then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character:FindFirstChild("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local distance = (Vector3.new(referencePos.X, 0, referencePos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function attack()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then tool:Activate()
    else
        local backpackTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
        if backpackTool and LocalPlayer.Character then backpackTool.Parent = LocalPlayer.Character end
    end
end

local function updateGodMode()
    local character = LocalPlayer.Character
    if not character then return end
    
    local ff = character:FindFirstChildOfClass("ForceField")
    if godModeEnabled then
        if not ff then
            local newFF = Instance.new("ForceField")
            newFF.Visible = true
            newFF.Parent = character
        end
    else
        if ff then
            ff:Destroy()
        end
    end
end

local function applyVisualNameSystem()
    if visualTargetName ~= "" then
        LocalPlayer.DisplayName = visualTargetName
        LocalPlayer.Name = visualTargetName
        
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.DisplayName = visualTargetName
            end
            
            for _, descendant in ipairs(LocalPlayer.Character:GetDescendants()) do
                if descendant:IsA("TextLabel") and (string.find(descendant.Text, "bomeRain1") or descendant.Text == LocalPlayer.Name) then
                    descendant.Text = visualTargetName
                end
            end
        end
    end

    if visualTargetLevel ~= "" then
        if LocalPlayer.Character then
            for _, descendant in ipairs(LocalPlayer.Character:GetDescendants()) do
                if descendant:IsA("TextLabel") then
                    if descendant.Text == "2" or descendant.Text == "Lv. 2" or descendant.Name == "Level" or descendant.Name == "LevelLabel" then
                        descendant.Text = visualTargetLevel
                    end
                end
            end
        end
    end
    
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, textLabel in ipairs(playerGui:GetDescendants()) do
            if textLabel:IsA("TextLabel") then
                if visualTargetName ~= "" and (textLabel.Text == "bomeRain1" or string.find(textLabel.Text, "bomeRain1")) then
                    textLabel.Text = string.gsub(textLabel.Text, "bomeRain1", visualTargetName)
                end
                
                if visualTargetLevel ~= "" then
                    if textLabel.Name == "Level" or textLabel.Name == "Rank" or textLabel.Text == "2" then
                        local isMyUi = false
                        local current = textLabel.Parent
                        for i = 1, 5 do
                            if not current then break end
                            if string.find(current.Name, "bomeRain1") or current:FindFirstChild("bomeRain1") or current.Name == "LocalPlayer" then
                                isMyUi = true
                                break
                            end
                            current = current.Parent
                        end
                        if isMyUi or textLabel.Text == "2" then
                            textLabel.Text = visualTargetLevel
                        end
                    end
                end
            end
        end
    end
end

-----------------------------------------------------------
-- [UI Components]
-----------------------------------------------------------

-- 1. Main Tab
local MainGroup = Tabs["Main"]:AddLeftGroupbox("Combat Perks")
MainGroup:AddToggle("AuraToggle", { Text = "Aura", Default = false, Callback = function(v) auraEnabled = v end })
MainGroup:AddToggle("ProjToggle", { Text = "Projectile wallbang (slingshot)", Default = false, Callback = function(v) projectileEnabled = v end })
MainGroup:AddToggle("GodModeToggle", { 
    Text = "God Mode (ForceField)", 
    Default = false, 
    Callback = function(v) 
        godModeEnabled = v 
        updateGodMode()
    end 
})
-- ★ Backstab toggle ★
MainGroup:AddToggle("BackstabToggle", {
    Text = "Auto Backstab (Aura style)",
    Default = false,
    Callback = function(v) backstabEnabled = v end
})

local OrbitGroup = Tabs["Main"]:AddRightGroupbox("Position Manipulation")
OrbitGroup:AddToggle("OrbitToggle", { Text = "Orbit", Default = false, Callback = function(v) orbitEnabled = v end })
OrbitGroup:AddSlider("OrbitStudsSlider", { Text = "Orbit Studs", Min = 5, Max = 50000000, Default = 50000000, Round = 0, Callback = function(v) orbitStuds = v end })
OrbitGroup:AddToggle("VoidSpamToggle", { Text = "VoidSpam", Default = false, Callback = function(v) voidSpamEnabled = v end })
OrbitGroup:AddSlider("VoidHeightSlider", { Text = "VoidSpam Height", Min = 50, Max = 50000000, Default = 50, Round = 0, Callback = function(v) voidSpamHeight = v end })

-- 2. ESP Tab
local EspGroup = Tabs["ESP"]:AddLeftGroupbox("Visual ESP")
EspGroup:AddToggle("EspActive", { Text = "Enable ESP", Default = false, Callback = function(v) espEnabled = v end })
EspGroup:AddToggle("EspBox", { Text = "Box", Default = true, Callback = function(v) espBoxes = v end })
EspGroup:AddToggle("EspName", { Text = "Name", Default = true, Callback = function(v) espNames = v end })
EspGroup:AddToggle("EspHealth", { Text = "Health Bar", Default = true, Callback = function(v) espHealth = v end })

-- 3. Visuals Tab
local VisualsGroup = Tabs["Visuals"]:AddLeftGroupbox("Item ESP / Collect")
VisualsGroup:AddToggle("ColHealth", { Text = "Arcade health pack (Health)", Default = false, Callback = function(v) collectHealth = v end })
VisualsGroup:AddToggle("ColAmmo", { Text = "Arcade ammo", Default = false, Callback = function(v) collectAmmo = v end })

-- 4. Character Tab
local CharGroup = Tabs["Character"]:AddLeftGroupbox("Rage Modifications")
CharGroup:AddToggle("RageFov", { Text = "Rage (FOV)", Default = false, Callback = function(v) rageFovEnabled = v end })
CharGroup:AddToggle("RageWallbang", { Text = "Rage (Wallbang View)", Default = false, Callback = function(v) rageWallbangViewEnabled = v end })

local WeaponGroup = Tabs["Character"]:AddLeftGroupbox("Weapon")
WeaponGroup:AddToggle("NoRecoilToggle", { 
    Text = "No Recoil", 
    Default = false, 
    Callback = function(v) 
        noRecoilEnabled = v 
        if v then pcall(function() toggleTableAttribute("ShootRecoil", 0) end) end
    end 
})
WeaponGroup:AddToggle("NoSpreadToggle", { 
    Text = "No Spread", 
    Default = false, 
    Callback = function(v) 
        noSpreadEnabled = v 
        if v then pcall(function() toggleTableAttribute("ShootSpread", 0) end) end
    end 
})
WeaponGroup:AddToggle("NoMuzzleFlashToggle", { 
    Text = "No Muzzle Flash", 
    Default = false, 
    Callback = function(v) 
        noMuzzleFlashEnabled = v 
        if v then pcall(function() toggleTableAttribute("ShootSpread", 0) end) end
    end 
})
WeaponGroup:AddSlider("AttackCooldownSlider", { Text = "Attack Cooldown :", Min = 0, Max = 100, Default = 100, Round = 0, Callback = function(v) attackCooldownValue = v end })

local AntiAimGroup = Tabs["Character"]:AddRightGroupbox("Anti-Aim")
AntiAimGroup:AddToggle("AntiAimToggle", { Text = "Enabled", Default = false, Callback = function(v) antiAimEnabled = v end })
AntiAimGroup:AddSlider("AntiAimYawSlider", { Text = "Custom Yaw Angle", Min = 0, Max = 360, Default = 180, Round = 0, Suffix = "°", Callback = function(v) antiAimCustomYaw = v end })
AntiAimGroup:AddSlider("AntiAimPitchSlider", { Text = "Custom Pitch Angle", Min = -90, Max = 90, Default = 90, Round = 0, Suffix = "°", Callback = function(v) antiAimCustomPitch = v end })
AntiAimGroup:AddDropdown("AntiAimPitchType", { Text = "Pitch Type", Values = {"Hide Head", "Custom", "Down", "Up"}, Default = "Hide Head", Callback = function(v) antiAimPitchType = v end })
AntiAimGroup:AddDropdown("AntiAimYawType", { Text = "Yaw Type", Values = {"Backwards", "Custom", "Jitter", "Spin"}, Default = "Backwards", Callback = function(v) antiAimYawType = v end })

-- 5. Misc Tab
local FlyGroup = Tabs["Misc"]:AddLeftGroupbox("Movement Control")
FlyGroup:AddToggle("MobFly", { Text = "Mobile fly (look direction)", Default = false, Callback = function(v) mobileFlyEnabled = v end })
FlyGroup:AddSlider("MobFlySpeed", { Text = "Mobile fly Speed", Min = 1, Max = 3000, Default = 50, Round = 0, Callback = function(v) flySpeedMobile = v end })
FlyGroup:AddToggle("PcFly", { Text = "PC fly (WASD free control)", Default = false, Callback = function(v) pcFlyEnabled = v end })
FlyGroup:AddSlider("PcFlySpeed", { Text = "PC fly Speed", Min = 1, Max = 10000, Default = 50, Round = 0, Callback = function(v) flySpeedPc = v end })
FlyGroup:AddToggle("NoclipActive", { Text = "Noclip", Default = false, Callback = function(v) noclipEnabled = v end })
FlyGroup:AddDropdown("NoclipMode", { Text = "Noclip mode", Values = {"all walls", "phong"}, Default = "all walls", Callback = function(v) noclipMode = v end })

local EmoteGroup = Tabs["Misc"]:AddRightGroupbox("Fun & Customization")
EmoteGroup:AddToggle("EmoteHop", { Text = "Emote Hop", Default = false, Callback = function(v) 
    emoteHopEnabled = v 
    if v and LocalPlayer.Character then playEmoteHop(LocalPlayer.Character) else stopEmoteHop() end
end })
EmoteGroup:AddSlider("EmoteSpeed", { Text = "Emote Speed", Min = 1, Max = 40, Default = 40, Round = 0, Callback = function(v) 
    emoteHopSpeed = v 
    if currentEmoteTrack and currentEmoteTrack.IsPlaying then currentEmoteTrack:AdjustSpeed(v) end
end })

EmoteGroup:AddToggle("ThirdPersonToggle", { Text = "Third person", Default = false, Callback = function(v) thirdPersonEnabled = v end })
EmoteGroup:AddDropdown("ThirdPersonMode", { Text = "Camera Mode", Values = {"Right", "Left", "Free Mouse Third Person"}, Default = "Right", Callback = function(v) thirdPersonMode = v end })

EmoteGroup:AddToggle("DeviceSpooferToggle", { Text = "Device Spoofer", Default = false, Callback = function(v) deviceSpooferEnabled = v end })
EmoteGroup:AddDropdown("DeviceSpooferMode", { Text = "Device Selection", Values = {"VR", "Touch", "Gamepad", "MouseKeyboard"}, Default = "VR", Callback = function(v) deviceSpooferEnabled = false task.wait(0.05) deviceSpooferMode = v deviceSpooferEnabled = Toggles.DeviceSpooferToggle.Value end })

EmoteGroup:AddButton("Skin Changer", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/thegop7y-ui/Unlock-all/refs/heads/main/Noks", true))()
end)

local PlayerGroup = Tabs["Misc"]:AddRightGroupbox("Player")
PlayerGroup:AddInput("VisualNameInput", {
    Text = "Name",
    Default = "",
    Placeholder = "Enter new name...",
    Callback = function(v)
        visualTargetName = v
    end
})

PlayerGroup:AddInput("VisualLevelInput", {
    Text = "Level",
    Default = "",
    Placeholder = "Enter new level...",
    Callback = function(v)
        visualTargetLevel = v
    end
})

-- 6. UI Settings Tab
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(v) Library.KeybindFrame.Visible = v end
})
MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("VodkaHub")
SaveManager:SetFolder("VodkaHub/configs")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

-----------------------------------------------------------
-- [Character Added Events]
-----------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function(character)
    if emoteHopEnabled then
        character:WaitForChild("Humanoid")
        task.wait(0.1)
        playEmoteHop(character)
    end
    
    if godModeEnabled then
        task.wait(0.1)
        updateGodMode()
    end
end)

-----------------------------------------------------------
-- [Physics-based Fly & Noclip Logic]
-----------------------------------------------------------
RunService.Stepped:Connect(function(deltaTime)
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar:FindFirstChild("Humanoid")
    if not myHrp then return end

    if noclipEnabled then
        if noclipMode == "all walls" then
            for _, part in pairs(myChar:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        elseif noclipMode == "phong" then
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {myChar}
            local groundRay = workspace:Raycast(myHrp.Position, Vector3.new(0, -6, 0), raycastParams)
            for _, part in pairs(myChar:GetDescendants()) do
                if part:IsA("BasePart") then
                    if groundRay and (part.Name == "HumanoidRootPart" or string.find(part.Name, "Leg") or string.find(part.Name, "Foot")) then
                        part.CanCollide = true
                    else
                        part.CanCollide = false
                    end
                end
            end
        end
    end

    if (mobileFlyEnabled or pcFlyEnabled) then
        if myHum then myHum.PlatformStand = true end
        local moveVelocity = Vector3.zero
        
        if mobileFlyEnabled then
            if myHum and myHum.MoveDirection.Magnitude > 0 then
                moveVelocity = Camera.CFrame.LookVector * flySpeedMobile
            end
        elseif pcFlyEnabled then
            local inputDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then inputDir = inputDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then inputDir = inputDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then inputDir = inputDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then inputDir = inputDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then inputDir = inputDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then inputDir = inputDir - Vector3.new(0, 1, 0) end
            
            if inputDir.Magnitude > 0 then
                moveVelocity = inputDir.Unit * flySpeedPc
            end
        end
        myHrp.AssemblyLinearVelocity = moveVelocity
        myHrp.AssemblyAngularVelocity = Vector3.zero
    else
        if myHum and myHum.PlatformStand then
            myHum.PlatformStand = false
            myHrp.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

-----------------------------------------------------------
-- [Emote Hop Animation Parser]
-----------------------------------------------------------
local function anim2track(asset_id)
    local success, objs = pcall(function() return game:GetObjects(asset_id) end)
    if success and objs and #objs > 0 then
         for i = 1, #objs do
            if objs[i]:IsA("Animation") then return objs[i].AnimationId end
        end
    end
    return asset_id
end

task.spawn(function()
    local animid = "92281817840531"
    if not string.find(animid, "rbxassetid://") then animid = "rbxassetid://" .. animid end
    animid = anim2track(animid)
    emoteAnimationInstance = Instance.new("Animation")
    emoteAnimationInstance.AnimationId = animid
end)

function playEmoteHop(character)
    if not emoteHopEnabled or not character or not emoteAnimationInstance then return end
    local Hum = character:FindFirstChildWhichIsA("Humanoid")
    if not Hum then return end

    if currentEmoteTrack then currentEmoteTrack:Stop() currentEmoteTrack = nil end
    for _, track in next, Hum:GetPlayingAnimationTracks() do track:Stop() end

    local animator = Hum:FindFirstChildOfClass("Animator") or Hum
    local trackSuccess, track = pcall(function() return animator:LoadAnimation(emoteAnimationInstance) end)

    if trackSuccess and track then
        currentEmoteTrack = track
        track.Priority = Enum.AnimationPriority.Action4
        track:Play()
        track:AdjustSpeed(emoteHopSpeed)
        
        local connection
        connection = track.Stopped:Connect(function()
            connection:Disconnect()
            if emoteHopEnabled and LocalPlayer.Character == character then playEmoteHop(character) end
        end)
    end
end

function stopEmoteHop()
    if currentEmoteTrack then currentEmoteTrack:Stop() currentEmoteTrack = nil end
end

-----------------------------------------------------------
-- [Input Detection]
-----------------------------------------------------------
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then isMouseDown = true
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then isMouseDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then isRightMouseDown = false end
end)

-----------------------------------------------------------
-- [Orbit Thread]
-----------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.01)
        if orbitEnabled then
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHrp then
                if not originalPosition then originalPosition = myHrp.Position end
                local randomDirection = Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100)).Unit
                myHrp.CFrame = CFrame.new(originalPosition + (randomDirection * orbitStuds))
            end
        else
            if originalPosition then originalPosition = nil end
        end
    end
end)

-----------------------------------------------------------
-- [ItemLibrary Weapon Data & Attack Cooldown Loop]
-----------------------------------------------------------
local originalCooldowns = {}
task.spawn(function()
    local Storage = game:GetService("ReplicatedStorage")
    local ItemLibrary = Storage:WaitForChild("Modules"):WaitForChild("ItemLibrary")
    local Items = require(ItemLibrary).Items

    for name, data in pairs(Items) do
        if typeof(data) == "table" then
            originalCooldowns[name] = {
                ShootCooldown = data.ShootCooldown or 0.1,
                ShootBurstCooldown = data.ShootBurstCooldown or 0.1
            }
        end
    end

    while true do
        task.wait(0.1)
        for name, data in pairs(Items) do
            if typeof(data) == "table" and originalCooldowns[name] then
                if attackCooldownValue == 100 then
                    data.ShootCooldown = originalCooldowns[name].ShootCooldown
                    data.ShootBurstCooldown = originalCooldowns[name].ShootBurstCooldown
                else
                    local ratio = attackCooldownValue / 100
                    local targetCooldown = 0.001 + (originalCooldowns[name].ShootCooldown - 0.001) * ratio
                    local targetBurst = 0.001 + (originalCooldowns[name].ShootBurstCooldown - 0.001) * ratio
                    
                    data.ShootCooldown = targetCooldown
                    data.ShootBurstCooldown = targetBurst
                end
            end
        end
    end
end)

-----------------------------------------------------------
-- [RenderStepped Loop – Weapon Mods & Name/Level]
-----------------------------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChild("Humanoid")
    
    if visualTargetName ~= "" or visualTargetLevel ~= "" then
        pcall(applyVisualNameSystem)
    end

    if godModeEnabled and myChar then
        local ff = myChar:FindFirstChildOfClass("ForceField")
        if not ff then
            updateGodMode()
        end
    end

    if noMuzzleFlashEnabled and myChar then
        local currentWeapon = myChar:FindFirstChildOfClass("Tool")
        if currentWeapon then
            for _, descendant in pairs(currentWeapon:GetDescendants()) do
                if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Fire") or descendant:IsA("SpotLight") or descendant:IsA("PointLight") then
                    if string.find(string.lower(descendant.Name), "muzzle") or string.find(string.lower(descendant.Name), "flash") or string.find(string.lower(descendant.Name), "smoke") then
                        descendant.Enabled = false
                    end
                end
            end
        end
    end

    if myChar and myHrp and (collectHealth or collectAmmo) then
        local needsHealth = myHum and myHum.Health < myHum.MaxHealth
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj.Name == "_drop" and obj:IsA("BasePart") then
                if (collectHealth and obj:FindFirstChild("Health") and needsHealth) or (collectAmmo and obj:FindFirstChild("Ammo")) then
                    if firetouchinterest then firetouchinterest(myHrp, obj, 0) firetouchinterest(myHrp, obj, 1) end
                end
            end
        end
    end

    if myHrp and rageWallbangViewEnabled then
        if virtualGroundPos == Vector3.zero or virtualGroundPos.Y > 2000000 then virtualGroundPos = Vector3.new(myHrp.Position.X, 10, myHrp.Position.Z) end
        local moveDirection = myHum and myHum.MoveDirection or Vector3.zero
        virtualGroundPos = virtualGroundPos + (moveDirection * (myHum and myHum.WalkSpeed or 16) * deltaTime)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {myChar}
        local rayResult = workspace:Raycast(virtualGroundPos + Vector3.new(0, 15, 0), Vector3.new(0, -30, 0), raycastParams)
        if rayResult then virtualGroundPos = Vector3.new(virtualGroundPos.X, rayResult.Position.Y, virtualGroundPos.Z) end
        Camera.CameraSubject = nil
        Camera.CFrame = CFrame.new(virtualGroundPos + cameraOffset) * Camera.CFrame.Rotation
    end
end)

-----------------------------------------------------------
-- [Heartbeat Loop – Anti-Aim, Aura, Backstab, VoidSpam, Rage]
-----------------------------------------------------------
local jitterState = false
local spinAngle = 0

RunService.Heartbeat:Connect(function()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChild("Humanoid")
    if not myHrp or (myHum and myHum.Health <= 0) or orbitEnabled then return end
    
    -- Anti-Aim (unchanged)
    if antiAimEnabled and not auraEnabled and not rageWallbangViewEnabled and not rageFovEnabled then
        local targetYaw = 0
        local targetPitch = 0
        
        if antiAimYawType == "Backwards" then
            targetYaw = math.rad(180)
        elseif antiAimYawType == "Custom" then
            targetYaw = math.rad(antiAimCustomYaw)
        elseif antiAimYawType == "Jitter" then
            jitterState = not jitterState
            targetYaw = jitterState and math.rad(45) or math.rad(-45)
        elseif antiAimYawType == "Spin" then
            spinAngle = (spinAngle + 15) % 360
            targetYaw = math.rad(spinAngle)
        end
        
        if antiAimPitchType == "Hide Head" then
            targetPitch = math.rad(-90)
        elseif antiAimPitchType == "Custom" then
            targetPitch = math.rad(antiAimCustomPitch)
        elseif antiAimPitchType == "Down" then
            targetPitch = math.rad(-85)
        elseif antiAimPitchType == "Up" then
            targetPitch = math.rad(85)
        end
        
        local camRot = Camera.CFrame.Rotation
        myHrp.CFrame = CFrame.new(myHrp.Position) * camRot * CFrame.Angles(0, targetYaw, 0)
        
        local upperTorso = myChar:FindFirstChild("UpperTorso") or myChar:FindFirstChild("Torso")
        local head = myChar:FindFirstChild("Head")
        if upperTorso and head then
            local neck = head:FindFirstChild("Neck") or (myChar:FindFirstChild("Toes") and upperTorso:FindFirstChild("Neck"))
            if neck and neck:IsA("Motor6D") then
                pcall(function() neck.Transform = CFrame.Angles(targetPitch, 0, 0) end)
            end
        end
    end

    -- VoidSpam
    if voidSpamEnabled then
        myHrp.CFrame = CFrame.new(myHrp.Position.X, voidSpamHeight, myHrp.Position.Z)
        return
    end
    
    -- Rage (FOV / Wallbang)
    if rageWallbangViewEnabled or rageFovEnabled then
        local refPos = (rageWallbangViewEnabled and virtualGroundPos ~= Vector3.zero) and virtualGroundPos or myHrp.Position
        local target = getClosestPlayer(refPos)
        if isMouseDown and target and target.Character then
            local targetHead = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HitboxHead") or target.Character:FindFirstChild("HitboxHeadSmall")
            if targetHead then
                myHrp.CFrame = CFrame.lookAt(targetHead.Position + Vector3.new(0, 0.5, 0), targetHead.Position)
                attack()
                return
            end
        end
        myHrp.CFrame = CFrame.new(myHrp.Position.X, 50000000, myHrp.Position.Z)
        return
    end
    
    -- ★ AURA (Normal) – now attacks only when right‑click is held ★
    if auraEnabled then
        local target = getClosestPlayer(myHrp.Position)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetHrp = target.Character.HumanoidRootPart
            local targetHum = target.Character:FindFirstChild("Humanoid")
            if targetHum and targetHum.Health > 0 then
                myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 3, 0)  -- teleport on top
                if isRightMouseDown then   -- << only attack when holding right click
                    attack()
                end
            else
                myHrp.CFrame = CFrame.new(myHrp.Position.X, 50000000, myHrp.Position.Z)
            end
        else
            myHrp.CFrame = CFrame.new(myHrp.Position.X, 50000000, myHrp.Position.Z)
        end
    end

    -- ★ AUTO BACKSTAB (separate toggle) – also respects right‑click ★
    if backstabEnabled then
        local target = getClosestPlayer(myHrp.Position)
        if target and target.Character then
            local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = target.Character:FindFirstChild("Humanoid")
            if targetHrp and targetHum and targetHum.Health > 0 then
                local behindPos = targetHrp.Position - targetHrp.CFrame.LookVector * 3
                myHrp.CFrame = CFrame.new(behindPos, targetHrp.Position)
                if isRightMouseDown then   -- only attack on right‑click
                    attack()
                end
            end
        end
    end
end)

-----------------------------------------------------------
-- [Projectile Wallbang]
-----------------------------------------------------------
task.spawn(function()
    while task.wait(0.01) do
        if not projectileEnabled then currentTargetHitbox = nil currentTargetModel = nil continue end
        local refPos = (rageWallbangViewEnabled and virtualGroundPos ~= Vector3.zero) and virtualGroundPos or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.zero)
        local target = getClosestPlayer(refPos)
        if target and target.Character then
            currentTargetModel = target.Character
            currentTargetHitbox = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HitboxHead") or target.Character:FindFirstChild("HitboxHeadSmall")
        else currentTargetHitbox = nil currentTargetModel = nil end
    end
end)

workspace.ChildAdded:Connect(function(v)
    if not projectileEnabled then return end
    if table.find({"CoreProjectile", "Slingshot", "Daggers", "Bow", "Paintball Gun"}, v.Name) then
        task.spawn(function()
            if currentTargetHitbox and currentTargetModel and v:IsA("BasePart") then
                for _, part in pairs(currentTargetModel:GetChildren()) do
                    if part:IsA("BasePart") and part ~= currentTargetHitbox then part.CanTouch = false end
                end
                v.CFrame = currentTargetHitbox.CFrame
                v.AssemblyLinearVelocity = Vector3.zero
                if firetouchinterest then firetouchinterest(currentTargetHitbox, v, 0) firetouchinterest(currentTargetHitbox, v, 1) end
                
                local start = tick()
                while v and v.Parent and (tick() - start) < 1.5 do
                    if currentTargetHitbox then
                        v.CFrame = currentTargetHitbox.CFrame
                        v.AssemblyLinearVelocity = Vector3.zero
                        firetouchinterest(currentTargetHitbox, v, 0)
                        firetouchinterest(currentTargetHitbox, v, 1)
                    end
                    task.wait()
                end
                if currentTargetModel then
                    for _, part in pairs(currentTargetModel:GetChildren()) do
                        if part:IsA("BasePart") then part.CanTouch = true end
                    end
                end
            end
        end)
    end
end)

-----------------------------------------------------------
-- [ESP System]
-----------------------------------------------------------
local cache = {}
local function createEsp(player)
    if cache[player] then return end
    local box = Drawing.new("Square") box.Thickness = 1 box.Filled = false box.Transparency = 1 box.Visible = false
    local name = Drawing.new("Text") name.Size = 13 name.Center = true name.Outline = true name.OutlineColor = Color3.fromRGB(0,0,0) name.Transparency = 1 name.Visible = false
    local healthBg = Drawing.new("Square") healthBg.Thickness = 1 healthBg.Filled = true healthBg.Color = Color3.fromRGB(0,0,0) healthBg.Transparency = 0.6 healthBg.Visible = false
    local healthBar = Drawing.new("Square") healthBar.Thickness = 1 healthBar.Filled = true healthBar.Transparency = 1 healthBar.Visible = false
    cache[player] = {Box = box, Name = name, HealthBg = healthBg, HealthBar = healthBar}
end

local function removeEsp(player)
    if cache[player] then
        cache[player].Box:Destroy() cache[player].Name:Destroy() cache[player].HealthBg:Destroy() cache[player].HealthBar:Destroy()
        cache[player] = nil
    end
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then createEsp(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createEsp(p) end end)
Players.PlayerRemoving:Connect(removeEsp)

RunService.RenderStepped:Connect(function()
    for player, drawings in pairs(cache) do
        local box, name, healthBg, healthBar = drawings.Box, drawings.Name, drawings.HealthBg, drawings.HealthBar
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if espEnabled and hrp and hum and hum.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local myEnv = chid_to_id(LocalPlayer:GetAttribute("EnvironmentID"))
                local hEnv = chid_to_id(player:GetAttribute("EnvironmentID"))
                local myTeam = chid_to_id(LocalPlayer:GetAttribute("TeamID"))
                local hTeam = chid_to_id(player:GetAttribute("TeamID"))

                local color = Color3.fromRGB(255, 45, 45)
                if not isSpecialPlace and hEnv == myEnv and hTeam == myTeam then color = Color3.fromRGB(45, 255, 45) end

                local sizeX = 2000 / pos.Z
                local sizeY = 3000 / pos.Z
                local boxX = pos.X - sizeX / 2
                local boxY = pos.Y - sizeY / 2

                if espBoxes then box.Size = Vector2.new(sizeX, sizeY) box.Position = Vector2.new(boxX, boxY) box.Color = color box.Visible = true else box.Visible = false end
                if espNames then name.Text = player.Name name.Position = Vector2.new(pos.X, boxY - 15) name.Color = color name.Visible = true else name.Visible = false end

                if espHealth then
                    local healthRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    healthBg.Size = Vector2.new(4, sizeY) healthBg.Position = Vector2.new(boxX - 6, boxY) healthBg.Visible = true
                    local currentBarHeight = sizeY * healthRatio
                    healthBar.Size = Vector2.new(4, currentBarHeight) healthBar.Position = Vector2.new(boxX - 6, boxY + (sizeY - currentBarHeight)) healthBar.Color = Color3.fromHSV(healthRatio * 0.33, 1, 1) healthBar.Visible = true
                else healthBg.Visible = false healthBar.Visible = false end
            else box.Visible = false name.Visible = false healthBg.Visible = false healthBar.Visible = false end
        else box.Visible = false name.Visible = false healthBg.Visible = false healthBar.Visible = false end
    end
end)

-----------------------------------------------------------
-- [Third Person Camera]
-----------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    if thirdPersonEnabled and myHrp and not rageWallbangViewEnabled then
        Camera.CameraSubject = nil
        
        if thirdPersonMode == "Right" then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            local offset = Vector3.new(2.5, 2, 8)
            local targetCamPos = myHrp.CFrame:PointToWorldSpace(offset)
            Camera.CFrame = CFrame.lookAt(targetCamPos, myHrp.Position + myHrp.CFrame.LookVector * 10)
            
        elseif thirdPersonMode == "Left" then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            local offset = Vector3.new(-2.5, 2, 8)
            local targetCamPos = myHrp.CFrame:PointToWorldSpace(offset)
            Camera.CFrame = CFrame.lookAt(targetCamPos, myHrp.Position + myHrp.CFrame.LookVector * 10)
            
        elseif thirdPersonMode == "Free Mouse Third Person" then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            local offset = Vector3.new(0, 3, 10)
            local targetCamPos = myHrp.CFrame:PointToWorldSpace(offset)
            Camera.CFrame = CFrame.lookAt(targetCamPos, myHrp.Position)
        end
    elseif not thirdPersonEnabled and not rageWallbangViewEnabled and myChar and myChar:FindFirstChild("Humanoid") then
        if Camera.CameraSubject ~= myChar.Humanoid then
            Camera.CameraSubject = myChar.Humanoid
        end
    end
end)

-----------------------------------------------------------
-- [Device Spoofer Loop]
-----------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if deviceSpooferEnabled then
            local ReplicatedStorage = game:GetService('ReplicatedStorage')
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local replication = remotes and remotes:FindFirstChild("Replication")
            local fighter = replication and replication:FindFirstChild("Fighter")
            local setControls = fighter and fighter:FindFirstChild("SetControls")
            
            if setControls and setControls:IsA("RemoteEvent") then
                pcall(function()
                    if deviceSpooferMode == "VR" then
                        setControls:FireServer("VR")
                    elseif deviceSpooferMode == "Touch" then
                        setControls:FireServer("Touch")
                    elseif deviceSpooferMode == "Gamepad" then
                        setControls:FireServer("Gamepad")
                    elseif deviceSpooferMode == "MouseKeyboard" then
                        setControls:FireServer("MouseKeyboard")
                    end
                end)
            end
        end
    end
end)