-- ixhook loader
-- made by kn4ght

local Loader = {}
Loader.Name = "ixhook"
Loader.Ver = "V3.1"
Loader.Author = "kn4ght"

-- script urls, keyed by game id
local scripts = {
	["6035872082"] = "https://api.jnkie.com/api/v1/luascripts/public/fc9ad4266f3a42035af480391751a6315f256ecd7f8332b52db96906224b3c7a/download", -- rivals
}

local gameNames = {
	["6035872082"] = "Rivals",
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local plr = Players.LocalPlayer
local pgui = plr:WaitForChild("PlayerGui")

Loader.UI = nil

local function corner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = obj
	return c
end

local function stroke(obj, col, th)
	local s = Instance.new("UIStroke")
	s.Color = col or Color3.fromRGB(100, 50, 255)
	s.Thickness = th or 1
	s.Transparency = 0.3
	s.Parent = obj
	return s
end

-- ==================== toast popups ====================
-- these pop from the right side, stack vertically

local toastGui

local function toast(title, text, icon, dur)
	spawn(function()
		local ok = pcall(function()
			if not toastGui or not toastGui.Parent then
				toastGui = Instance.new("ScreenGui")
				toastGui.Name = "ixhookToasts"
				toastGui.ResetOnSpawn = false
				toastGui.DisplayOrder = 200
				toastGui.IgnoreGuiInset = true
				toastGui.Parent = pgui

				local list = Instance.new("Frame")
				list.Name = "list"
				list.Size = UDim2.new(0, 300, 0, 400)
				list.Position = UDim2.new(1, -320, 0, 20)
				list.BackgroundTransparency = 1
				list.Parent = toastGui

				local layout = Instance.new("UIListLayout")
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Padding = UDim.new(0, 6)
				layout.Parent = list
			end

			local list = toastGui:FindFirstChild("list")
			if not list then return end

			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, 56)
			card.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
			card.BackgroundTransparency = 0.1
			card.BorderSizePixel = 0
			card.Position = UDim2.new(1, 40, 0, 0)
			card.Parent = list
			corner(card, 8)
			stroke(card)

			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(0, 3, 1, -12)
			bar.Position = UDim2.new(0, 0, 0, 6)
			bar.BackgroundColor3 = Color3.fromRGB(100, 50, 255)
			bar.BorderSizePixel = 0
			bar.Parent = card
			corner(bar, 3)

			local ic = Instance.new("TextLabel")
			ic.Size = UDim2.new(0, 34, 0, 34)
			ic.Position = UDim2.new(0, 8, 0, 11)
			ic.BackgroundTransparency = 1
			ic.Text = icon or "•"
			ic.TextSize = 20
			ic.Font = Enum.Font.GothamBold
			ic.TextColor3 = Color3.new(1, 1, 1)
			ic.Parent = card

			local t = Instance.new("TextLabel")
			t.Size = UDim2.new(1, -60, 0, 18)
			t.Position = UDim2.new(0, 48, 0, 8)
			t.BackgroundTransparency = 1
			t.Text = title or "ixhook"
			t.TextColor3 = Color3.new(1, 1, 1)
			t.TextSize = 14
			t.Font = Enum.Font.GothamBold
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Parent = card

			local d = Instance.new("TextLabel")
			d.Size = UDim2.new(1, -60, 0, 28)
			d.Position = UDim2.new(0, 48, 0, 24)
			d.BackgroundTransparency = 1
			d.Text = text or ""
			d.TextColor3 = Color3.fromRGB(190, 190, 210)
			d.TextSize = 12
			d.Font = Enum.Font.Gotham
			d.TextXAlignment = Enum.TextXAlignment.Left
			d.TextWrapped = true
			d.Parent = card

			TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, 0, 0, 0)
			}):Play()

			wait(dur or 4)

			TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1, 40, 0, 0),
				BackgroundTransparency = 1
			}):Play()
			wait(0.28)
			card:Destroy()
		end)
	end)
end

-- ==================== game id widget ====================
-- small box bottom right showing what game you're in

local function gameWidget()
	local sg = Instance.new("ScreenGui")
	sg.Name = "ixhookGameWidget"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 30
	sg.IgnoreGuiInset = true
	sg.Parent = pgui

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 220, 0, 68)
	card.Position = UDim2.new(1, -240, 1, -90)
	card.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel = 0
	card.Parent = sg
	corner(card, 8)
	stroke(card)

	local head = Instance.new("TextLabel")
	head.Size = UDim2.new(1, -20, 0, 16)
	head.Position = UDim2.new(0, 10, 0, 6)
	head.BackgroundTransparency = 1
	head.Text = "GAME DETECTED"
	head.TextColor3 = Color3.fromRGB(150, 150, 200)
	head.TextSize = 10
	head.Font = Enum.Font.GothamBold
	head.TextXAlignment = Enum.TextXAlignment.Left
	head.Parent = card

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -20, 0, 18)
	nameLbl.Position = UDim2.new(0, 10, 0, 22)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = "..."
	nameLbl.TextColor3 = Color3.new(1, 1, 1)
	nameLbl.TextSize = 14
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = card

	local idLbl = Instance.new("TextLabel")
	idLbl.Size = UDim2.new(1, -20, 0, 14)
	idLbl.Position = UDim2.new(0, 10, 0, 40)
	idLbl.BackgroundTransparency = 1
	idLbl.Text = "ID: ..."
	idLbl.TextColor3 = Color3.fromRGB(160, 160, 190)
	idLbl.TextSize = 11
	idLbl.Font = Enum.Font.Gotham
	idLbl.TextXAlignment = Enum.TextXAlignment.Left
	idLbl.Parent = card

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 8, 0, 8)
	dot.Position = UDim2.new(1, -18, 0, 10)
	dot.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	dot.BorderSizePixel = 0
	dot.Parent = card
	corner(dot, 4)

	local function refresh()
		local id = tostring(game.GameId)
		idLbl.Text = "ID: " .. id
		local gn = gameNames[id]
		if gn then
			nameLbl.Text = gn
			nameLbl.TextColor3 = Color3.new(1, 1, 1)
			dot.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
		else
			nameLbl.Text = "Unsupported"
			nameLbl.TextColor3 = Color3.fromRGB(255, 90, 90)
			dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		end
	end

	refresh()

	-- keep checking in case game changes (edge case but whatever)
	spawn(function()
		while sg.Parent do
			wait(2)
			refresh()
		end
	end)
end

-- ==================== confirm dialog ====================
-- small yes/no popup

local function confirm(cb)
	local sg = Instance.new("ScreenGui")
	sg.Name = "ixhookConfirm"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 100
	sg.IgnoreGuiInset = true
	sg.Parent = pgui

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 360, 0, 170)
	card.Position = UDim2.new(0.5, -180, 0.5, -85)
	card.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
	card.BorderSizePixel = 0
	card.Parent = sg
	corner(card, 10)
	stroke(card)

	local ic = Instance.new("TextLabel")
	ic.Size = UDim2.new(0, 40, 0, 40)
	ic.Position = UDim2.new(0, 14, 0, 14)
	ic.BackgroundTransparency = 1
	ic.Text = "⚠️"
	ic.TextSize = 28
	ic.Font = Enum.Font.GothamBold
	ic.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 0, 22)
	title.Position = UDim2.new(0, 60, 0, 16)
	title.BackgroundTransparency = 1
	title.Text = "Run ixhook?"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -30, 0, 40)
	desc.Position = UDim2.new(0, 15, 0, 58)
	desc.BackgroundTransparency = 1
	desc.Text = "Execute the loader in this game?\nGame ID: " .. tostring(game.GameId)
	desc.TextColor3 = Color3.fromRGB(190, 190, 210)
	desc.TextSize = 12
	desc.Font = Enum.Font.Gotham
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.Parent = card

	local yes = Instance.new("TextButton")
	yes.Size = UDim2.new(0.45, -10, 0, 34)
	yes.Position = UDim2.new(0, 15, 1, -49)
	yes.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
	yes.BackgroundTransparency = 0.15
	yes.BorderSizePixel = 0
	yes.Text = "Yes"
	yes.TextColor3 = Color3.new(1, 1, 1)
	yes.TextSize = 14
	yes.Font = Enum.Font.GothamBold
	yes.Parent = card
	corner(yes, 6)

	local no = Instance.new("TextButton")
	no.Size = UDim2.new(0.45, -10, 0, 34)
	no.Position = UDim2.new(0.5, 5, 1, -49)
	no.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	no.BackgroundTransparency = 0.15
	no.BorderSizePixel = 0
	no.Text = "No"
	no.TextColor3 = Color3.new(1, 1, 1)
	no.TextSize = 14
	no.Font = Enum.Font.GothamBold
	no.Parent = card
	corner(no, 6)

	local function done(v)
		sg:Destroy()
		if cb then cb(v) end
	end

	yes.MouseButton1Click:Connect(function() done(true) end)
	no.MouseButton1Click:Connect(function() done(false) end)

	return sg
end

-- ==================== loading card ====================
-- little card that slides in from the right

local function loadCard()
	local sg = Instance.new("ScreenGui")
	sg.Name = "ixhookLoader"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 60
	sg.IgnoreGuiInset = true
	sg.Parent = pgui

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 300, 0, 120)
	card.Position = UDim2.new(1, 320, 0, 20)
	card.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
	card.BorderSizePixel = 0
	card.Parent = sg
	corner(card, 10)
	stroke(card)

	TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -320, 0, 20)
	}):Play()

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 20)
	title.Position = UDim2.new(0, 12, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = Loader.Name .. "  " .. Loader.Ver
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local gl = Instance.new("TextLabel")
	gl.Size = UDim2.new(1, -20, 0, 16)
	gl.Position = UDim2.new(0, 12, 0, 32)
	gl.BackgroundTransparency = 1
	gl.Text = "Game: " .. (gameNames[tostring(game.GameId)] or "Unknown")
	gl.TextColor3 = Color3.fromRGB(160, 160, 190)
	gl.TextSize = 11
	gl.Font = Enum.Font.Gotham
	gl.TextXAlignment = Enum.TextXAlignment.Left
	gl.Parent = card

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -24, 0, 8)
	barBg.Position = UDim2.new(0, 12, 0, 60)
	barBg.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
	barBg.BorderSizePixel = 0
	barBg.Parent = card
	corner(barBg, 4)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(100, 50, 255)
	fill.BorderSizePixel = 0
	fill.Parent = barBg
	corner(fill, 4)

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 50, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 255)),
	})
	grad.Parent = fill

	local st = Instance.new("TextLabel")
	st.Size = UDim2.new(1, -60, 0, 16)
	st.Position = UDim2.new(0, 12, 0, 76)
	st.BackgroundTransparency = 1
	st.Text = "Starting..."
	st.TextColor3 = Color3.fromRGB(200, 200, 220)
	st.TextSize = 11
	st.Font = Enum.Font.Gotham
	st.TextXAlignment = Enum.TextXAlignment.Left
	st.Parent = card

	local pct = Instance.new("TextLabel")
	pct.Size = UDim2.new(0, 50, 0, 16)
	pct.Position = UDim2.new(1, -62, 0, 76)
	pct.BackgroundTransparency = 1
	pct.Text = "0%"
	pct.TextColor3 = Color3.new(1, 1, 1)
	pct.TextSize = 11
	pct.Font = Enum.Font.GothamBold
	pct.TextXAlignment = Enum.TextXAlignment.Right
	pct.Parent = card

	return {
		gui = sg,
		card = card,
		fill = fill,
		pct = pct,
		status = st,
	}
end

-- ==================== error card ====================
-- for unsupported games

local function errorCard()
	local sg = Instance.new("ScreenGui")
	sg.Name = "ixhookErr"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 60
	sg.IgnoreGuiInset = true
	sg.Parent = pgui

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 300, 0, 140)
	card.Position = UDim2.new(1, -320, 0, 20)
	card.BackgroundColor3 = Color3.fromRGB(30, 22, 22)
	card.BorderSizePixel = 0
	card.Parent = sg
	corner(card, 10)
	stroke(card, Color3.fromRGB(255, 60, 60), 1)

	local ic = Instance.new("TextLabel")
	ic.Size = UDim2.new(0, 40, 0, 40)
	ic.Position = UDim2.new(0, 12, 0, 12)
	ic.BackgroundTransparency = 1
	ic.Text = "❌"
	ic.TextSize = 26
	ic.Font = Enum.Font.GothamBold
	ic.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 0, 20)
	title.Position = UDim2.new(0, 58, 0, 14)
	title.BackgroundTransparency = 1
	title.Text = "Unsupported Game"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, -24, 0, 36)
	msg.Position = UDim2.new(0, 12, 0, 58)
	msg.BackgroundTransparency = 1
	msg.Text = "This game (ID: " .. tostring(game.GameId) .. ") isn't supported yet."
	msg.TextColor3 = Color3.fromRGB(220, 180, 180)
	msg.TextSize = 11
	msg.Font = Enum.Font.Gotham
	msg.TextXAlignment = Enum.TextXAlignment.Left
	msg.TextWrapped = true
	msg.Parent = card

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -24, 0, 28)
	btn.Position = UDim2.new(0, 12, 1, -38)
	btn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	btn.BackgroundTransparency = 0.15
	btn.BorderSizePixel = 0
	btn.Text = "Close"
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.Parent = card
	corner(btn, 6)

	btn.MouseButton1Click:Connect(function()
		sg:Destroy()
	end)
end

-- ==================== progress helpers ====================

function Loader:UpdateProgress(p, txt)
	if not self.UI then return end
	p = math.clamp(p, 0, 100)
	self.UI.fill.Size = UDim2.new(p / 100, 0, 1, 0)
	self.UI.pct.Text = math.floor(p) .. "%"
	if txt then self.UI.status.Text = txt end
end

function Loader:AnimateProgress(from, to, dur, txt)
	from = math.clamp(from, 0, 100)
	to = math.clamp(to, 0, 100)
	local t0 = tick()
	while tick() - t0 < dur do
		if not self.UI then return end
		local p = (tick() - t0) / dur
		-- ease in-out quad
		local e
		if p < 0.5 then
			e = 2 * p * p
		else
			e = 1 - math.pow(-2 * p + 2, 2) / 2
		end
		self:UpdateProgress(from + (to - from) * e, txt)
		wait()
	end
	self:UpdateProgress(to, txt)
end

function Loader:DestroyLoader()
	if not self.UI then return end
	local ui = self.UI
	self.UI = nil

	TweenService:Create(ui.card, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(1, 320, 0, 20),
		BackgroundTransparency = 1
	}):Play()

	wait(0.38)
	if ui.gui then ui.gui:Destroy() end
end

function Loader:Finish()
	if not self.UI then return end
	self:AnimateProgress(85, 100, 0.5, "Done!")

	local gn = gameNames[tostring(game.GameId)] or "Unknown"
	toast("Loaded", "ixhook ready in " .. gn, "✅", 4)

	wait(0.3)
	self:DestroyLoader()
	self:LoadMainScript()
end

function Loader:LoadMainScript()
	local ok, err = pcall(function()
		local id = tostring(game.GameId)
		local url = scripts[id]
		if not url then
			warn("[ixhook] no script for " .. id)
			toast("Unsupported", "No script for this game.", "❌", 4)
			return
		end
		loadstring(game:HttpGet(url))()
		print("[ixhook] loaded main script")
	end)
	if not ok then
		warn("[ixhook] error: " .. tostring(err))
		toast("Error", tostring(err), "❌", 6)
	end
end

-- ==================== go ====================

function Loader:Start()
	print("[ixhook] starting " .. Loader.Name .. " " .. Loader.Ver .. " | id=" .. tostring(game.GameId))

	gameWidget()

	confirm(function(yes)
		if not yes then
			toast("Cancelled", "Script cancelled.", "❌", 3)
			return
		end

		if not gameNames[tostring(game.GameId)] then
			toast("Unsupported", "Game ID " .. tostring(game.GameId) .. " not supported.", "❌", 5)
			errorCard()
			return
		end

		local gn = gameNames[tostring(game.GameId)]
		toast("Detected", gn .. " (" .. tostring(game.GameId) .. ")", "✅", 3)

		self.UI = loadCard()

		local steps = {
			{10, "Loading UI..."},
			{25, "Initializing modules..."},
			{40, "Connecting services..."},
			{55, "Verifying deps..."},
			{70, "Preparing features..."},
			{85, "Finalizing..."},
		}

		local cur = 0
		for _, s in ipairs(steps) do
			local d = 0.35 + math.random() * 0.25
			self:AnimateProgress(cur, s[1], d, s[2])
			cur = s[1]
			wait(0.08)
		end

		self:Finish()
	end)
end

Loader:Start()