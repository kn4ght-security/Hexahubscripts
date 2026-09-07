--[[
  Astroid Hub Loader
  Loads Library → ThemeManager → SaveManager → AstroidHub

  Usage (when files are hosted):
    loadstring(game:HttpGet("YOUR_URL/loader.lua"))()

  Or paste the three UI files + AstroidHub.lua into your executor workspace
  and run this after setting the paths below.
]]

-- ========== OPTION A: HttpGet (recommended once uploaded) ==========
local BASE = nil -- e.g. "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/"

-- ========== OPTION B: readfile from workspace (Synapse / some executors) ==========
local function tryRead(path)
  if isfile and isfile(path) then
    return readfile(path)
  end
  return nil
end

local function loadFrom(name, fallbackHttp)
  -- 1) already in getgenv
  if getgenv()[name] then
    return getgenv()[name]
  end

  -- 2) readfile local
  local localPaths = {
    "AstroidHub/" .. name .. ".lua",
    name .. ".lua",
    "workspace/" .. name .. ".lua",
  }
  for _, p in ipairs(localPaths) do
    local src = tryRead(p)
    if src then
      local fn, err = loadstring(src)
      if fn then
        local mod = fn()
        getgenv()[name] = mod
        return mod
      end
    end
  end

  -- 3) HttpGet if BASE set
  if BASE then
    local src = game:HttpGet(BASE .. name .. ".lua")
    local fn = loadstring(src)
    local mod = fn()
    getgenv()[name] = mod
    return mod
  end

  error("[Astroid] Could not load " .. name .. ".lua – host the files or put them next to the loader")
end

-- Load UI stack
local Library = loadFrom("Library")
local ThemeManager = loadFrom("ThemeManager")
local SaveManager = loadFrom("SaveManager")

getgenv().Library = Library
getgenv().ThemeManager = ThemeManager
getgenv().SaveManager = SaveManager

-- Load main hub
local hubSrc = tryRead("AstroidHub/AstroidHub.lua")
  or tryRead("AstroidHub.lua")
  or (BASE and game:HttpGet(BASE .. "AstroidHub.lua"))

if not hubSrc then
  error("[Astroid] Could not load AstroidHub.lua")
end

loadstring(hubSrc)()
