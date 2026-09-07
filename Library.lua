local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');

-- Pick a parent: gethui() first, then CoreGui (only if we can actually parent
-- into it), then the LocalPlayer's PlayerGui as a last resort.
local CoreGui = (function()
	if gethui then
		local ok, hui = pcall(gethui);
		if ok and hui then return hui end
	end

	local ok, cg = pcall(function()
		local c = game:GetService('CoreGui');
		c = cloneref and cloneref(c) or c;

		local probe = Instance.new('ScreenGui');
		probe.Parent = c;
		probe:Destroy();

		return c;
	end);

	if ok and cg then return cg end

	local Player = game:GetService('Players').LocalPlayer;
	return Player:FindFirstChildOfClass('PlayerGui') or Player:WaitForChild('PlayerGui');
end)();
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = cloneref(LocalPlayer:GetMouse());

local ContextActionService = game:GetService('ContextActionService');
local GuiService = game:GetService('GuiService');

local ProtectGuiRaw = protectgui or (syn and syn.protect_gui) or (function() end);
local function ProtectGui(Gui)
	pcall(ProtectGuiRaw, Gui);
end

-- High DisplayOrder so the menu sits above the game's own UI. Order within the
-- set: window < drag outlines < cursor.
local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;
ScreenGui.DisplayOrder = 999;

-- Outline ScreenGui: holds the drag/resize preview outlines so they always
-- render above the window itself.
local OutlineGui = Instance.new('ScreenGui');
ProtectGui(OutlineGui);
OutlineGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
OutlineGui.Parent = CoreGui;
OutlineGui.DisplayOrder = 1000;

-- Cursor ScreenGui: the custom arrow always draws on top of the menu.
local CursorGui = Instance.new('ScreenGui');
ProtectGui(CursorGui);
CursorGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
CursorGui.Parent = CoreGui;
CursorGui.DisplayOrder = 1001;

-- Background blur + dim behind the menu (ueleak: BlurSize 15, black dim at 0.7),
-- tweened in/out with the menu.
local MenuBlur = Instance.new('BlurEffect');
MenuBlur.Size = 0;
MenuBlur.Enabled = false;
MenuBlur.Parent = game:GetService('Lighting');

-- Its own ScreenGui with IgnoreGuiInset so the dim covers the full viewport
-- (topbar strip included), sitting just under the menu.
local MenuDimGui = Instance.new('ScreenGui');
ProtectGui(MenuDimGui);
MenuDimGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
MenuDimGui.IgnoreGuiInset = true;
MenuDimGui.DisplayOrder = 997;
MenuDimGui.Parent = CoreGui;

local MenuDim = Instance.new('Frame');
MenuDim.BackgroundColor3 = Color3.new(0, 0, 0);
MenuDim.BackgroundTransparency = 1;
MenuDim.BorderSizePixel = 0;
MenuDim.Size = UDim2.fromScale(1, 1);
MenuDim.ZIndex = 0;
MenuDim.Visible = false;
MenuDim.Parent = MenuDimGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
	Registry = {};
	RegistryMap = {};

	HudRegistry = {};

	FontColor = Color3.fromRGB(255, 255, 255);       -- ffffff
	MainColor = Color3.fromRGB(24, 24, 24);          -- 181818
	BackgroundColor = Color3.fromRGB(20, 20, 20);    -- 141414
	AccentColor = Color3.fromRGB(71, 119, 182);      -- 4777b6
	OutlineColor = Color3.fromRGB(31, 31, 31);       -- 1f1f1f
	RiskColor = Color3.fromRGB(229, 0, 0),           -- e50000

	Black = Color3.new(0, 0, 0);
	Font = Enum.Font.RobotoMono,

	OpenedFrames = {};
	DependencyBoxes = {};

	KeypickerListVisible = true;
	KeypickerListMode = "All"; --[[
		{
			"Active",
			"Toggled",
			"All"
		};
	]]

	Signals = {};
	ScreenGui = ScreenGui;
	OutlineGui = OutlineGui;
	CursorGui = CursorGui;

	MenuBlur = MenuBlur;
	MenuDim = MenuDim;
	BackgroundBlur = true;      -- master switch for the blur + dim
	BlurSize = 15;              -- ueleak default
	DimTransparency = 0.7;      -- ueleak BackTransparency

	-- fork additions
	Events = {};
	Tabs = {};

	NotifyOnError = false;
	FlagCopying = false;

	IsDragging = false;
	CanDrag = true;
	CantDragForced = false;

	MinSize = Vector2.new(550, 300);

	IsMobile = (function()
		local Ok, Touch = pcall(function()
			return InputService.TouchEnabled and not InputService.KeyboardEnabled;
		end);
		return Ok and Touch or false;
	end)();

	NotificationStyle = {
		BarSide = 'Bottom'; -- Top / Left / Right / Bottom
		Transparency = 0.75;
		OverrideColor = nil; -- function() return Main, Accent, Outline, Font end
	};

	TotalTabs = 0;
	Visible = false;
	BlockInput = false;
	ToggleKeybind = nil;
};

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
	RainbowStep = RainbowStep + Delta

	if RainbowStep >= (1 / 60) then
		RainbowStep = 0

		Hue = Hue + (1 / 400);

		if Hue > 1 then
			Hue = 0;
		end;

		Library.CurrentRainbowHue = Hue;
		Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
	end
end))

local function GetPlayersString()
	local PlayerList = Players:GetPlayers();

	for i = 1, #PlayerList do
		PlayerList[i] = PlayerList[i].Name;
	end;

	table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

	return PlayerList;
end;

local function GetTeamsString()
	local TeamList = Teams:GetTeams();

	for i = 1, #TeamList do
		TeamList[i] = TeamList[i].Name;
	end;

	table.sort(TeamList, function(str1, str2) return str1 < str2 end);

	return TeamList;
end;

function Library:SafeCallback(f, ...)
	if (not f) then
		return;
	end;

	if not Library.NotifyOnError then
		return f(...);
	end;

	local success, event = pcall(f, ...);

	if not success then
		local _, i = event:find(":%d+: ");

		if not i then
			return Library:Notify(event);
		end;

		return Library:Notify(event:sub(i + 1), 3);
	end;
end;

function Library:AttemptSave()
	if Library.SaveManager then
		Library.SaveManager:Save();
	end;
end;

function Library:Create(Class, Properties)
	local _Instance = Class;

	if type(Class) == 'string' then
		_Instance = Instance.new(Class);
	end;

	for Property, Value in next, Properties do
		-- The fork guards every property write: one bad property (e.g. one
		-- removed by a Roblox update) must not kill the whole element.
		local Success = pcall(function()
			_Instance[Property] = Value;
		end);

		if not Success then
			warn(('Library:Create - failed to set %q'):format(tostring(Property)));
		end;
	end;

	return _Instance;
end;

function Library:ApplyTextStroke(Inst)
	Inst.TextStrokeTransparency = 1;

	Library:Create('UIStroke', {
		Color = Color3.new(0, 0, 0);
		Thickness = 1;
		LineJoinMode = Enum.LineJoinMode.Miter;
		Parent = Inst;
	});
end;

function Library:CreateLabel(Properties, IsHud)
	local _Instance = Library:Create('TextLabel', {
		BackgroundTransparency = 1;
		Font = Library.Font;
		TextColor3 = Library.FontColor;
		TextSize = 16;
		TextStrokeTransparency = 0;
	});

	Library:ApplyTextStroke(_Instance);

	Library:AddToRegistry(_Instance, {
		TextColor3 = 'FontColor';
	}, IsHud);

	return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff, IgnoreForced)
	Instance.Active = true;

	Instance.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			if IgnoreForced == true and Library.CantDragForced == true then
				return;
			end;

			local ObjPos = Vector2.new(
				Mouse.X - Instance.AbsolutePosition.X,
				Mouse.Y - Instance.AbsolutePosition.Y
			);

			if ObjPos.Y > (Cutoff or 40) then
				return;
			end;

			while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				Instance.Position = UDim2.new(
					0,
					Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
					0,
					Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
				);

				RenderStepped:Wait();
			end;
		end;
	end)
end;

-- Drags an accent-coloured outline instead of the window itself and only
-- commits the new position on release. Much lighter on large windows.
function Library:MakeDraggableOutline(Instance, Cutoff, IgnoreForced)
	Instance.Active = true;

	Instance.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			if IgnoreForced == true and Library.CantDragForced == true then
				return;
			end;

			local ObjPos = Vector2.new(
				Mouse.X - Instance.AbsolutePosition.X,
				Mouse.Y - Instance.AbsolutePosition.Y
			);

			if ObjPos.Y > (Cutoff or 40) then
				return;
			end;

			local Outline = Library:Create('Frame', {
				Parent = OutlineGui;
				AnchorPoint = Instance.AnchorPoint;
				BackgroundTransparency = 1;
				Size = Instance.Size;
				Position = Instance.Position;
			});

			local Stroke = Library:Create('UIStroke', {
				Parent = Outline;
				Color = Library.AccentColor or Color3.new(0, 0, 0);
			});

			Library.IsDragging = true;

			while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				Outline.Position = UDim2.new(
					0,
					Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
					0,
					Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
				);

				Stroke.Color = Library.AccentColor or Color3.new(0, 0, 0);

				RenderStepped:Wait();
			end;

			Instance.Position = Outline.Position;
			Outline:Destroy();

			Library.IsDragging = false;
		elseif Input.UserInputType == Enum.UserInputType.Touch then
			if IgnoreForced == true and Library.CantDragForced == true then
				return;
			end;

			local ObjPos = Vector2.new(
				Input.Position.X - Instance.AbsolutePosition.X,
				Input.Position.Y - Instance.AbsolutePosition.Y
			);

			if ObjPos.Y > (Cutoff or 40) then
				return;
			end;

			local Outline = Library:Create('Frame', {
				Parent = OutlineGui;
				AnchorPoint = Instance.AnchorPoint;
				BackgroundTransparency = 1;
				Size = Instance.Size;
				Position = Instance.Position;
			});

			local Stroke = Library:Create('UIStroke', {
				Parent = Outline;
				Color = Library.AccentColor or Color3.new(0, 0, 0);
			});

			Library.IsDragging = true;

			local Held = true;
			local Conn;

			Conn = Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Held = false;
				end;
			end);

			while Held do
				Outline.Position = UDim2.new(
					0,
					Input.Position.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
					0,
					Input.Position.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
				);

				Stroke.Color = Library.AccentColor or Color3.new(0, 0, 0);

				RenderStepped:Wait();
			end;

			Instance.Position = Outline.Position;

			if Conn then
				Conn:Disconnect();
			end;

			Outline:Destroy();

			Library.IsDragging = false;
		end;
	end)
end;

-- Lets a small handle (e.g. a topbar strip) drag a different, larger frame.
function Library:MakeDraggableUsingParent(Handle, Target, Cutoff, IgnoreForced)
	Handle.Active = true;

	if Library.IsMobile == false then
		Handle.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				if IgnoreForced == true and Library.CantDragForced == true then
					return;
				end;

				local ObjPos = Vector2.new(
					Mouse.X - Target.AbsolutePosition.X,
					Mouse.Y - Target.AbsolutePosition.Y
				);

				if ObjPos.Y > (Cutoff or 40) then
					return;
				end;

				while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					Target.Position = UDim2.new(
						0,
						Mouse.X - ObjPos.X + (Target.Size.X.Offset * Target.AnchorPoint.X),
						0,
						Mouse.Y - ObjPos.Y + (Target.Size.Y.Offset * Target.AnchorPoint.Y)
					);

					RenderStepped:Wait();
				end;
			end;
		end)
	else
		Library:MakeDraggable(Target, Cutoff, IgnoreForced);
	end;
end;

-- Bottom-right resize grip. Resizes an outline and commits on release.
-- MinSize defaults to Library.MinSize.
function Library:MakeResizable(Instance, MinSize)
	Instance.Active = true;

	local GripSize = 25;
	local GripTransparency = 0.5;

	local GripRegion = Library:Create('Frame', {
		SizeConstraint = Enum.SizeConstraint.RelativeXX;
		BackgroundColor3 = Color3.new(0, 0, 0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Size = UDim2.fromOffset(GripSize, GripSize);
		Position = UDim2.new(1, -GripSize, 1, -GripSize);
		Visible = true;
		ClipsDescendants = true;
		ZIndex = 1;
		Parent = Instance;
	});

	local Grip = Library:Create('ImageButton', {
		BackgroundColor3 = Library.AccentColor;
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Size = UDim2.new(2, 0, 2, 0);
		Position = UDim2.new(1, -30, 1, -30);
		ZIndex = 2;
		Parent = GripRegion;
	});

	local GripCorner = Library:Create('UICorner', {
		CornerRadius = UDim.new(0.5, 0);
		Parent = Grip;
	});

	Library:AddToRegistry(Grip, { BackgroundColor3 = 'AccentColor' });

	MinSize = MinSize or Library.MinSize;

	local DragOffset = nil;
	local Outline = nil;

	local Stroke = Library:Create('UIStroke', {
		Color = Library.AccentColor or Color3.new(0, 0, 0);
	});

	-- Track the accent colour so a theme change recolours the drag outline too.
	Library:AddToRegistry(Stroke, { Color = 'AccentColor' });

	local function Reset(Transparency)
		Grip.Position = UDim2.new();
		Grip.Size = UDim2.new(2, 0, 2, 0);
		Grip.Parent = GripRegion;
		Grip.BackgroundTransparency = Transparency;
		GripCorner.Parent = Grip;

		DragOffset = nil;

		if Outline then
			Stroke.Parent = nil;
			Instance.Size = Outline.Size;
			Outline:Destroy();
			Outline = nil;
		end;
	end;

	if Library.IsMobile ~= true then
		Grip.MouseButton1Down:Connect(function()
			if DragOffset then
				return;
			end;

			DragOffset = Vector2.new(
				Mouse.X - (Instance.AbsolutePosition.X + Instance.AbsoluteSize.X),
				Mouse.Y - (Instance.AbsolutePosition.Y + Instance.AbsoluteSize.Y)
			);

			Outline = Library:Create('Frame', {
				Parent = OutlineGui;
				AnchorPoint = Instance.AnchorPoint;
				BackgroundTransparency = 1;
				Size = Instance.Size;
				Position = Instance.Position;
			});

			Stroke.Parent = Outline;

			-- Blow the grip up to cover the screen so the cursor cannot escape it
			-- mid-drag; MouseMoved keeps firing for the whole gesture.
			Grip.BackgroundTransparency = 1;
			Grip.Size = UDim2.fromOffset(ScreenGui.AbsoluteSize.X, ScreenGui.AbsoluteSize.Y);
			Grip.Position = UDim2.new();
			GripCorner.Parent = nil;
			Grip.Parent = ScreenGui;
		end);

		Grip.MouseMoved:Connect(function()
			if not DragOffset then
				return;
			end;

			local Corner = Vector2.new(Mouse.X - DragOffset.X, Mouse.Y - DragOffset.Y);

			local NewSize = Vector2.new(
				math.clamp(Corner.X - Instance.AbsolutePosition.X, MinSize.X, math.huge),
				math.clamp(Corner.Y - Instance.AbsolutePosition.Y, MinSize.Y, math.huge)
			);

			Outline.Size = UDim2.fromOffset(NewSize.X, NewSize.Y);
		end);

		Grip.MouseButton1Up:Connect(function()
			Reset(GripTransparency);
		end);
	else
		Grip.InputBegan:Connect(function(Input)
			if Input.UserInputType ~= Enum.UserInputType.Touch or DragOffset then
				return;
			end;

			DragOffset = Vector2.new(
				Input.Position.X - (Instance.AbsolutePosition.X + Instance.AbsoluteSize.X),
				Input.Position.Y - (Instance.AbsolutePosition.Y + Instance.AbsoluteSize.Y)
			);

			Outline = Library:Create('Frame', {
				Parent = OutlineGui;
				AnchorPoint = Instance.AnchorPoint;
				BackgroundTransparency = 1;
				Size = Instance.Size;
				Position = Instance.Position;
			});

			Stroke.Parent = Outline;
		end);

		Grip.InputChanged:Connect(function(Input)
			if Input.UserInputType ~= Enum.UserInputType.Touch or not DragOffset then
				return;
			end;

			local Corner = Vector2.new(Input.Position.X - DragOffset.X, Input.Position.Y - DragOffset.Y);

			local NewSize = Vector2.new(
				math.clamp(Corner.X - Instance.AbsolutePosition.X, MinSize.X, math.huge),
				math.clamp(Corner.Y - Instance.AbsolutePosition.Y, MinSize.Y, math.huge)
			);

			Outline.Size = UDim2.fromOffset(NewSize.X, NewSize.Y);
		end);

		Grip.InputEnded:Connect(function(Input)
			if Input.UserInputType ~= Enum.UserInputType.Touch then
				return;
			end;

			Reset(GripTransparency);
		end);
	end;

	Reset(GripTransparency);
end;

function Library:AddToolTip(InfoStr, HoverInstance)
	local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14);
	local Tooltip = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,

		Size = UDim2.fromOffset(X + 5, Y + 4),
		ZIndex = 100,
		Parent = Library.ScreenGui,

		Visible = false,
	})

	local Label = Library:CreateLabel({
		Position = UDim2.fromOffset(3, 1),
		Size = UDim2.fromOffset(X, Y);
		TextSize = 14;
		Text = InfoStr,
		TextColor3 = Library.FontColor,
		TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = Tooltip.ZIndex + 1,

		Parent = Tooltip;
	});

	Library:AddToRegistry(Tooltip, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	});

	Library:AddToRegistry(Label, {
		TextColor3 = 'FontColor',
	});

	local IsHovering = false

	HoverInstance.MouseEnter:Connect(function()
		if Library:MouseIsOverOpenedFrame() then
			return
		end

		IsHovering = true

		Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
		Tooltip.Visible = true

		while IsHovering do
			RunService.Heartbeat:Wait()
			Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
		end
	end)

	HoverInstance.MouseLeave:Connect(function()
		IsHovering = false
		Tooltip.Visible = false
	end)

	-- Without this a tooltip shown at the moment the menu is toggled off would
	-- stay stuck on screen with nothing to hover off of.
	if Library.MainFrame then
		Library.MainFrame:GetPropertyChangedSignal('Visible'):Connect(function()
			if Library.MainFrame.Visible == false then
				IsHovering = false
				Tooltip.Visible = false
			end
		end)
	end
end

-- Condition (optional): while it returns false the highlight is suppressed,
-- so e.g. a disabled element never lights up under the cursor.
function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault, Condition)
	local function ApplyDefault()
		local Reg = Library.RegistryMap[Instance];

		for Property, ColorIdx in next, PropertiesDefault do
			Instance[Property] = Library[ColorIdx] or ColorIdx;

			if Reg and Reg.Properties[Property] then
				Reg.Properties[Property] = ColorIdx;
			end;
		end;
	end;

	local function ApplyHighlight()
		if Condition and not Condition() then
			ApplyDefault();
			return;
		end;

		local Reg = Library.RegistryMap[Instance];

		for Property, ColorIdx in next, Properties do
			Instance[Property] = Library[ColorIdx] or ColorIdx;

			if Reg and Reg.Properties[Property] then
				Reg.Properties[Property] = ColorIdx;
			end;
		end;
	end;

	HighlightInstance.MouseEnter:Connect(ApplyHighlight);
	HighlightInstance.MouseMoved:Connect(ApplyHighlight);
	HighlightInstance.MouseLeave:Connect(ApplyDefault);
end;

function Library:MouseIsOverOpenedFrame()
	for Frame, _ in next, Library.OpenedFrames do
		local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

		if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
			and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

			return true;
		end;
	end;
end;

function Library:IsMouseOverFrame(Frame)
	local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

	if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
		and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

		return true;
	end;
end;

function Library:UpdateDependencyBoxes()
	for _, Depbox in next, Library.DependencyBoxes do
		Depbox:Update();
	end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
	return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
	local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
	return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
	local H, S, V = Color3.toHSV(Color);
	return Color3.fromHSV(H, S, V / 1.5);
end;
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
	local Idx = #Library.Registry + 1;
	local Data = {
		Instance = Instance;
		Properties = Properties;
		Idx = Idx;
	};

	table.insert(Library.Registry, Data);
	Library.RegistryMap[Instance] = Data;

	if IsHud then
		table.insert(Library.HudRegistry, Data);
	end;
end;

function Library:RemoveFromRegistry(Instance)
	local Data = Library.RegistryMap[Instance];

	if Data then
		for Idx = #Library.Registry, 1, -1 do
			if Library.Registry[Idx] == Data then
				table.remove(Library.Registry, Idx);
			end;
		end;

		for Idx = #Library.HudRegistry, 1, -1 do
			if Library.HudRegistry[Idx] == Data then
				table.remove(Library.HudRegistry, Idx);
			end;
		end;

		Library.RegistryMap[Instance] = nil;
	end;
end;

function Library:UpdateColorsUsingRegistry()
	-- TODO: Could have an 'active' list of objects
	-- where the active list only contains Visible objects.

	-- IMPL: Could setup .Changed events on the AddToRegistry function
	-- that listens for the 'Visible' propert being changed.
	-- Visible: true => Add to active list, and call UpdateColors function
	-- Visible: false => Remove from active list.

	-- The above would be especially efficient for a rainbow menu color or live color-changing.

	for Idx, Object in next, Library.Registry do
		for Property, ColorIdx in next, Object.Properties do
			if type(ColorIdx) == 'string' then
				Object.Instance[Property] = Library[ColorIdx];
			elseif type(ColorIdx) == 'function' then
				Object.Instance[Property] = ColorIdx()
			end
		end;
	end;
end;

function Library:GiveSignal(Signal)
	-- Only used for signals not attached to library instances, as those should be cleaned up on object destruction by Roblox
	table.insert(Library.Signals, Signal)
end

function Library:Unload()
	-- Unload all of the signals
	for Idx = #Library.Signals, 1, -1 do
		local Connection = table.remove(Library.Signals, Idx)
		Connection:Disconnect()
	end

	-- Call our unload callback, maybe to undo some hooks etc
	if Library.OnUnload then
		Library.OnUnload()
	end

	ContextActionService:UnbindAction('Freeze');

	ScreenGui:Destroy()
	OutlineGui:Destroy()
	CursorGui:Destroy()
	MenuDimGui:Destroy()
	MenuBlur:Destroy()
end

function Library:OnUnload(Callback)
	Library.OnUnload = Callback
end

function Library:EnableFlagCopying(Bool)
	Library.FlagCopying = Bool;
end

function Library:IsVisible()
	return Library.Visible;
end

--// Event bus //--
-- Lets consumer code react to library state (currently 'VisibilityChanged')
-- without patching the library itself.

function Library:CreateEvent(Name)
	Library.Events[Name] = Instance.new('BindableEvent');
end

function Library:FireEvent(Name, ...)
	if Library.Events[Name] then
		Library.Events[Name]:Fire(...);
	end;
end

function Library:OnEvent(Name)
	if not Library.Events[Name] then
		Library:CreateEvent(Name);
	end;

	return Library.Events[Name].Event;
end

Library:CreateEvent('VisibilityChanged');

--// Global input binding //--
-- One InputBegan connection fans out to every listener, and only while the
-- menu is open. Used for the click-outside-to-close behaviour.

local InputBinds = {};

function Library:BindToInput(Key, Callback)
	InputBinds[Key] = InputBinds[Key] or {};
	table.insert(InputBinds[Key], Callback);
end

Library:GiveSignal(InputService.InputBegan:Connect(function(Input, ...)
	if not Library.Visible then
		return;
	end;

	local Callbacks = InputBinds[Input.KeyCode] or InputBinds[Input.UserInputType];

	if Callbacks then
		for _, Callback in pairs(Callbacks) do
			task.spawn(Callback, Input, ...);
		end;
	end;
end))

--// Context menus //--
-- Right-click menu anchored to the right of Anchor. Trigger defaults to the
-- anchor itself, but can be a larger hit region (e.g. a whole toggle row).

function Library:AddContextMenu(Anchor, Trigger)
	local ContextMenu = { Visible = false };

	ContextMenu.Options = {};

	ContextMenu.Container = Library:Create('ImageButton', {
		BorderColor3 = Color3.new();
		ZIndex = 14;
		Visible = false;
		Parent = ScreenGui;
		Image = '';
		Active = false;
		AutoButtonColor = false;
	});

	ContextMenu.Inner = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		BorderMode = Enum.BorderMode.Inset;
		Size = UDim2.fromScale(1, 1);
		ZIndex = 15;
		Parent = ContextMenu.Container;
	});

	Library:Create('UIListLayout', {
		Name = 'Layout';
		HorizontalAlignment = Enum.HorizontalAlignment.Left;
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = ContextMenu.Inner;
	});

	Library:Create('UIPadding', {
		Name = 'Padding';
		PaddingLeft = UDim.new(0, 0);
		Parent = ContextMenu.Inner;
	});

	local function UpdatePosition()
		ContextMenu.Container.Position = UDim2.fromOffset(
			(Anchor.AbsolutePosition.X + Anchor.AbsoluteSize.X) + 4,
			Anchor.AbsolutePosition.Y + 1
		);
	end;

	local function UpdateSize()
		local MenuWidth = 60;

		for _, Label in next, ContextMenu.Inner:GetChildren() do
			if Label:IsA('TextLabel') then
				MenuWidth = math.max(MenuWidth, Label.TextBounds.X);
			end;
		end;

		ContextMenu.Container.Size = UDim2.fromOffset(
			MenuWidth + 8,
			ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
		);
	end;

	local IsOpen = false;

	(Trigger or Anchor).InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
			return ContextMenu:Hide();
		elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
			return ContextMenu:Show();
		end;
	end);

	Library:BindToInput(Enum.UserInputType.MouseButton1, function()
		if IsOpen and not Library:IsMouseOverFrame(ContextMenu.Container) then
			ContextMenu:Hide();
		end;
	end);

	Library:BindToInput(Enum.UserInputType.MouseButton2, function()
		if IsOpen and not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(Anchor) then
			ContextMenu:Hide();
		end;
	end);

	Anchor:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdatePosition);

	task.spawn(UpdatePosition);
	task.spawn(UpdateSize);

	Library:AddToRegistry(ContextMenu.Inner, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'OutlineColor';
	});

	function ContextMenu:Show()
		UpdatePosition();
		UpdateSize();

		IsOpen = true;

		-- Close any open colour picker so the two never overlap.
		for Frame in next, Library.OpenedFrames do
			if Frame.Name == 'Color' then
				Frame.Visible = false;
				Library.OpenedFrames[Frame] = nil;
			end;
		end;

		self.Container.Visible = true;
		Library.OpenedFrames[ContextMenu.Container] = true;
	end;

	function ContextMenu:Hide()
		IsOpen = false;
		self.Container.Visible = false;

		-- Deferred so the click that closed the menu is not also treated as a
		-- click on whatever sits underneath it.
		task.wait();

		Library.OpenedFrames[ContextMenu.Container] = nil;
	end;

	function ContextMenu:AddOption(Str, Callback)
		if type(Callback) ~= 'function' then
			Callback = function() end;
		end;

		local Button = Library:CreateLabel({
			Active = false;
			Size = UDim2.new(1, 0, 0, 15);
			TextSize = 13;
			Text = Str;
			ZIndex = 16;
			Parent = self.Inner;
			TextXAlignment = Enum.TextXAlignment.Center;
		});

		Library:OnHighlight(Button, Button,
			{ TextColor3 = 'AccentColor' },
			{ TextColor3 = 'FontColor' }
		);

		Button.InputBegan:Connect(function(Input)
			if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return;
			end;

			Callback();
		end);

		table.insert(self.Options, Button);

		return Button;
	end;

	return ContextMenu;
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
	if Library.RegistryMap[Instance] then
		Library:RemoveFromRegistry(Instance);
	end;
end))

local BaseAddons = {};

do
	local Funcs = {};

	function Funcs:AddColorPicker(Idx, Info)
		local ParentObj = self;
		local ToggleLabel = self.TextLabel;
		-- local Container = self.Container;

		assert(Info.Default, 'AddColorPicker: Missing default value.');

		local ColorPicker = {
			Idx = Idx;
			Value = Info.Default;
			Transparency = Info.Transparency or 0;
			Type = 'ColorPicker';
			Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
			HasTransparency = not not Info.Transparency;
			Callback = Info.Callback or function(Color) end;
		};

		function ColorPicker:SetHSVFromRGB(Color)
			local H, S, V = Color3.toHSV(Color);

			ColorPicker.Hue = H;
			ColorPicker.Sat = S;
			ColorPicker.Vib = V;
		end;

		ColorPicker:SetHSVFromRGB(ColorPicker.Value);

		local DisplayFrame = Library:Create('Frame', {
			BackgroundColor3 = ColorPicker.Value;
			BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(0, 28, 0, 14);
			ZIndex = 6;
			Parent = ToggleLabel;
		});

		-- Transparency image taken from https://github.com/matas3535/SplixPrivateDrawingLibrary/blob/main/Library.lua cus i'm lazy
		local CheckerFrame = Library:Create('ImageLabel', {
			BorderSizePixel = 0;
			Size = UDim2.new(0, 27, 0, 13);
			ZIndex = 5;
			Image = 'http://www.roblox.com/asset/?id=12977615774';
			Visible = not not Info.Transparency;
			Parent = DisplayFrame;
		});

		-- 1/16/23
		-- Rewrote this to be placed inside the Library ScreenGui
		-- There was some issue which caused RelativeOffset to be way off
		-- Thus the color picker would never show

		local PickerFrameOuter = Library:Create('Frame', {
			Name = 'Color';
			BackgroundColor3 = Color3.new(1, 1, 1);
			BorderColor3 = Color3.new(0, 0, 0);
			Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
			Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
			Visible = false;
			ZIndex = 15;
			Parent = ScreenGui,
		});

		DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
			PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
		end)

		local PickerFrameInner = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 16;
			Parent = PickerFrameOuter;
		});

		local Highlight = Library:Create('Frame', {
			BackgroundColor3 = Library.AccentColor;
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 0, 2);
			ZIndex = 17;
			Parent = PickerFrameInner;
		});

		local SatVibMapOuter = Library:Create('Frame', {
			BorderColor3 = Color3.new(0, 0, 0);
			Position = UDim2.new(0, 4, 0, 25);
			Size = UDim2.new(0, 200, 0, 200);
			ZIndex = 17;
			Parent = PickerFrameInner;
		});

		local SatVibMapInner = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 18;
			Parent = SatVibMapOuter;
		});

		local SatVibMap = Library:Create('ImageLabel', {
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 18;
			Image = 'rbxassetid://4155801252';
			Parent = SatVibMapInner;
		});

		local CursorOuter = Library:Create('ImageLabel', {
			AnchorPoint = Vector2.new(0.5, 0.5);
			Size = UDim2.new(0, 6, 0, 6);
			BackgroundTransparency = 1;
			Image = 'http://www.roblox.com/asset/?id=9619665977';
			ImageColor3 = Color3.new(0, 0, 0);
			ZIndex = 19;
			Parent = SatVibMap;
		});

		local CursorInner = Library:Create('ImageLabel', {
			Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
			Position = UDim2.new(0, 1, 0, 1);
			BackgroundTransparency = 1;
			Image = 'http://www.roblox.com/asset/?id=9619665977';
			ZIndex = 20;
			Parent = CursorOuter;
		})

		local HueSelectorOuter = Library:Create('Frame', {
			BorderColor3 = Color3.new(0, 0, 0);
			Position = UDim2.new(0, 208, 0, 25);
			Size = UDim2.new(0, 15, 0, 200);
			ZIndex = 17;
			Parent = PickerFrameInner;
		});

		local HueSelectorInner = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(1, 1, 1);
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 18;
			Parent = HueSelectorOuter;
		});

		local HueCursor = Library:Create('Frame', { 
			BackgroundColor3 = Color3.new(1, 1, 1);
			AnchorPoint = Vector2.new(0, 0.5);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, 0, 0, 1);
			ZIndex = 18;
			Parent = HueSelectorInner;
		});

		local HueBoxOuter = Library:Create('Frame', {
			BorderColor3 = Color3.new(0, 0, 0);
			Position = UDim2.fromOffset(4, 228),
			Size = UDim2.new(0.5, -6, 0, 20),
			ZIndex = 18,
			Parent = PickerFrameInner;
		});

		local HueBoxInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 18,
			Parent = HueBoxOuter;
		});

		Library:Create('UIGradient', {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
			});
			Rotation = 90;
			Parent = HueBoxInner;
		});

		local HueBox = Library:Create('TextBox', {
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 5, 0, 0);
			Size = UDim2.new(1, -5, 1, 0);
			Font = Library.Font;
			PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
			PlaceholderText = 'Hex color',
			Text = '#FFFFFF',
			TextColor3 = Library.FontColor;
			TextSize = 14;
			TextStrokeTransparency = 0;
			TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 20,
			Parent = HueBoxInner;
		});

		Library:ApplyTextStroke(HueBox);

		local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
			Position = UDim2.new(0.5, 2, 0, 228),
			Size = UDim2.new(0.5, -6, 0, 20),
			Parent = PickerFrameInner
		});

		local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
			Text = '255, 255, 255',
			PlaceholderText = 'RGB color',
			TextColor3 = Library.FontColor
		});

		local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;

		if Info.Transparency then 
			TransparencyBoxOuter = Library:Create('Frame', {
				BorderColor3 = Color3.new(0, 0, 0);
				Position = UDim2.fromOffset(4, 251);
				Size = UDim2.new(1, -8, 0, 15);
				ZIndex = 19;
				Parent = PickerFrameInner;
			});

			TransparencyBoxInner = Library:Create('Frame', {
				BackgroundColor3 = ColorPicker.Value;
				BorderColor3 = Library.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 1, 0);
				ZIndex = 19;
				Parent = TransparencyBoxOuter;
			});

			Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

			Library:Create('ImageLabel', {
				BackgroundTransparency = 1;
				Size = UDim2.new(1, 0, 1, 0);
				Image = 'http://www.roblox.com/asset/?id=12978095818';
				ZIndex = 20;
				Parent = TransparencyBoxInner;
			});

			TransparencyCursor = Library:Create('Frame', { 
				BackgroundColor3 = Color3.new(1, 1, 1);
				AnchorPoint = Vector2.new(0.5, 0);
				BorderColor3 = Color3.new(0, 0, 0);
				Size = UDim2.new(0, 1, 1, 0);
				ZIndex = 21;
				Parent = TransparencyBoxInner;
			});
		end;

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 0, 14);
			Position = UDim2.fromOffset(5, 5);
			TextXAlignment = Enum.TextXAlignment.Left;
			TextSize = 14;
			Text = ColorPicker.Title,--Info.Default;
			TextWrapped = false;
			ZIndex = 16;
			Parent = PickerFrameInner;
		});


		local ContextMenu = {}
		do
			ContextMenu.Options = {}
			ContextMenu.Container = Library:Create('Frame', {
				BorderColor3 = Color3.new(),
				ZIndex = 14,

				Visible = false,
				Parent = ScreenGui
			})

			ContextMenu.Inner = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Library.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.fromScale(1, 1);
				ZIndex = 15;
				Parent = ContextMenu.Container;
			});

			Library:Create('UIListLayout', {
				Name = 'Layout',
				FillDirection = Enum.FillDirection.Vertical;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Parent = ContextMenu.Inner;
			});

			Library:Create('UIPadding', {
				Name = 'Padding',
				PaddingLeft = UDim.new(0, 4),
				Parent = ContextMenu.Inner,
			});

			local function updateMenuPosition()
				ContextMenu.Container.Position = UDim2.fromOffset(
					(DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
					DisplayFrame.AbsolutePosition.Y + 1
				)
			end

			local function updateMenuSize()
				local menuWidth = 60
				for i, label in next, ContextMenu.Inner:GetChildren() do
					if label:IsA('TextLabel') then
						menuWidth = math.max(menuWidth, label.TextBounds.X)
					end
				end

				ContextMenu.Container.Size = UDim2.fromOffset(
					menuWidth + 8,
					ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
				)
			end

			DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
			ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

			task.spawn(updateMenuPosition)
			task.spawn(updateMenuSize)

			Library:AddToRegistry(ContextMenu.Inner, {
				BackgroundColor3 = 'BackgroundColor';
				BorderColor3 = 'OutlineColor';
			});

			function ContextMenu:Show()
				self.Container.Visible = true
			end

			function ContextMenu:Hide()
				self.Container.Visible = false
			end

			function ContextMenu:AddOption(Str, Callback)
				if type(Callback) ~= 'function' then
					Callback = function() end
				end

				local Button = Library:CreateLabel({
					Active = false;
					Size = UDim2.new(1, 0, 0, 15);
					TextSize = 13;
					Text = Str;
					ZIndex = 16;
					Parent = self.Inner;
					TextXAlignment = Enum.TextXAlignment.Left,
				});

				Library:OnHighlight(Button, Button, 
					{ TextColor3 = 'AccentColor' },
					{ TextColor3 = 'FontColor' }
				);

				Button.InputBegan:Connect(function(Input)
					if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
						return
					end

					Callback()
				end)
			end

			-- Every colour picker attached to the same toggle/label, in the order
			-- they were added. 'Make gradient' interpolates the middle ones
			-- between the first and last, which is how multi-stop chams/tracer
			-- colours get set up without picking each stop by hand.
			local function GetSiblingPickers()
				local Pickers = {};

				for _, Addon in next, (ParentObj.Addons or {}) do
					if Addon.Type == 'ColorPicker' then
						table.insert(Pickers, Addon);
					end;
				end;

				return Pickers;
			end;

			ContextMenu:AddOption('Make gradient', function()
				local Pickers = GetSiblingPickers();

				if #Pickers < 3 then
					ContextMenu:Hide();
					return Library:Notify('not enough colors for a gradient.', 2);
				end;

				local First, Last = Pickers[1].Value, Pickers[#Pickers].Value;

				for Index = 2, #Pickers - 1 do
					local Picker = Pickers[Index];
					Picker:SetValueRGB(First:Lerp(Last, Index / #Pickers), Picker.Transparency);
				end;

				Library:Notify('created gradient!', 2);
				ContextMenu:Hide();
			end)

			ContextMenu:AddOption('Match color', function()
				for _, Picker in next, GetSiblingPickers() do
					Picker:SetValueRGB(ColorPicker.Value, Picker.Transparency);
				end;

				Library:Notify('matched all colors!', 2);
				ContextMenu:Hide();
			end)

			ContextMenu:AddOption('Copy color', function()
				Library.ColorClipboard = ColorPicker
				Library:Notify('Copied color!', 2)
				ContextMenu:Hide();
			end)

			ContextMenu:AddOption('Paste color', function()
				if not Library.ColorClipboard then
					return Library:Notify('You have not copied a color!', 2)
				end

				ColorPicker:SetValueRGB(Library.ColorClipboard.Value, Library.ColorClipboard.Transparency)
				ContextMenu:Hide();
			end)


			ContextMenu:AddOption('Copy HEX', function()
				pcall(setclipboard, ColorPicker.Value:ToHex())
				Library:Notify('Copied hex code to clipboard!', 2)
			end)

			ContextMenu:AddOption('Copy RGB', function()
				pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
				Library:Notify('Copied RGB values to clipboard!', 2)
			end)

			if Library.FlagCopying then
				ContextMenu:AddOption('Copy Flag', function()
					pcall(setclipboard, ColorPicker.Idx);
					task.wait();
					Library:Notify('Copied flag to clipboard!', 2);
					ContextMenu:Hide();
				end)
			end
		end

		Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
		Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
		Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });

		Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
		Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
		Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
		Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });

		local SequenceTable = {};

		for Hue = 0, 1, 0.1 do
			table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
		end;

		local HueSelectorGradient = Library:Create('UIGradient', {
			Color = ColorSequence.new(SequenceTable);
			Rotation = 90;
			Parent = HueSelectorInner;
		});

		HueBox.FocusLost:Connect(function(enter)
			if enter then
				local success, result = pcall(Color3.fromHex, HueBox.Text)
				if success and typeof(result) == 'Color3' then
					ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
				end
			end

			ColorPicker:Display()
		end)

		RgbBox.FocusLost:Connect(function(enter)
			if enter then
				local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
				if r and g and b then
					ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
				end
			end

			ColorPicker:Display()
		end)

		function ColorPicker:Display()
			ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
			SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

			Library:Create(DisplayFrame, {
				BackgroundColor3 = ColorPicker.Value;
				BackgroundTransparency = ColorPicker.Transparency;
				BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
			});

			if TransparencyBoxInner then
				TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
				TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
			end;

			CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
			HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);

			HueBox.Text = '#' .. ColorPicker.Value:ToHex()
			RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

			Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
			Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
		end;

		function ColorPicker:OnChanged(Func)
			ColorPicker.Changed = Func;
			Func(ColorPicker.Value)
		end;

		function ColorPicker:Show()
			for Frame, Val in next, Library.OpenedFrames do
				if Frame.Name == 'Color' then
					Frame.Visible = false;
					Library.OpenedFrames[Frame] = nil;
				end;
			end;

			PickerFrameOuter.Visible = true;
			Library.OpenedFrames[PickerFrameOuter] = true;
		end;

		function ColorPicker:Hide()
			PickerFrameOuter.Visible = false;
			Library.OpenedFrames[PickerFrameOuter] = nil;
		end;

		function ColorPicker:SetValue(HSV, Transparency)
			local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);

			ColorPicker.Transparency = Transparency or 0;
			ColorPicker:SetHSVFromRGB(Color);
			ColorPicker:Display();
		end;

		function ColorPicker:SetValueRGB(Color, Transparency)
			ColorPicker.Transparency = Transparency or 0;
			ColorPicker:SetHSVFromRGB(Color);
			ColorPicker:Display();
		end;

		SatVibMap.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local MinX = SatVibMap.AbsolutePosition.X;
					local MaxX = MinX + SatVibMap.AbsoluteSize.X;
					local MouseX = math.clamp(Mouse.X, MinX, MaxX);

					local MinY = SatVibMap.AbsolutePosition.Y;
					local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
					local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

					ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
					ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
					ColorPicker:Display();

					RenderStepped:Wait();
				end;

				Library:AttemptSave();
			end;
		end);

		HueSelectorInner.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local MinY = HueSelectorInner.AbsolutePosition.Y;
					local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
					local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

					ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
					ColorPicker:Display();

					RenderStepped:Wait();
				end;

				Library:AttemptSave();
			end;
		end);

		DisplayFrame.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				if PickerFrameOuter.Visible then
					ColorPicker:Hide()
				else
					ContextMenu:Hide()
					ColorPicker:Show()
				end;
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
				ContextMenu:Show()
				ColorPicker:Hide()
			end
		end);

		if TransparencyBoxInner then
			TransparencyBoxInner.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
						local MinX = TransparencyBoxInner.AbsolutePosition.X;
						local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
						local MouseX = math.clamp(Mouse.X, MinX, MaxX);

						ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));

						ColorPicker:Display();

						RenderStepped:Wait();
					end;

					Library:AttemptSave();
				end;
			end);
		end;

		Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;

				if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
					or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

					ColorPicker:Hide();
				end;

				if not Library:IsMouseOverFrame(ContextMenu.Container) then
					ContextMenu:Hide()
				end
			end;

			if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
				if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
					ContextMenu:Hide()
				end
			end
		end))

		function ColorPicker:Remove()
			Options[Idx] = nil;

			local Pickers = ParentObj.Addons or {};
			local Index = table.find(Pickers, ColorPicker);

			if Index then
				table.remove(Pickers, Index);
			end;

			PickerFrameOuter:Destroy();
			DisplayFrame:Destroy();
			ContextMenu.Container:Destroy();
			table.clear(ColorPicker);
		end;

		ColorPicker:Display();
		ColorPicker.DisplayFrame = DisplayFrame

		ParentObj.Addons = ParentObj.Addons or {};
		table.insert(ParentObj.Addons, ColorPicker);

		Options[Idx] = ColorPicker;

		if (self.ToggleRegion) then
			self.ColorPickerCount += 1;
			if (self.ColorPickerCount > 2) then
				self.ToggleRegion.Size -= UDim2.new(0,32,0,0);
			end
		end
		return self;
	end;

	function Funcs:AddKeyPicker(Idx, Info)
		local ParentObj = self;
		local ToggleLabel = self.TextLabel;
		local Container = self.Container;

		assert(Info.Default, 'AddKeyPicker: Missing default value.');

		local KeyPicker = {
			Idx = Idx;
			Value = Info.Default;
			Toggled = false;
			Override = false;
			Connections = {};
			Mode = Info.Mode or 'Toggle'; -- Always, Toggle, Hold
			Type = 'KeyPicker';
			Callback = Info.Callback or function(Value) end;
			ChangedCallback = Info.ChangedCallback or function(New) end;
			NoUI = Info.NoUI;--Info.NoUI;
			SyncToggleState = Info.SyncToggleState or false;
			Parent = ParentObj;
		};

		if KeyPicker.SyncToggleState then
			Info.Modes = { 'Toggle' }
			Info.Mode = 'Toggle'
		end

		local PickOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(0, 28, 0, 15);
			ZIndex = 6;
			Parent = ToggleLabel;
		});

		local PickInner = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 7;
			Parent = PickOuter;
		});

		Library:AddToRegistry(PickInner, {
			BackgroundColor3 = 'BackgroundColor';
			BorderColor3 = 'OutlineColor';
		});

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 1, 0);
			TextSize = 13;
			Text = Info.Default;
			TextWrapped = true;
			ZIndex = 8;
			Parent = PickInner;
		});

		local ModeSelectOuter = Library:Create('Frame', {
			BorderColor3 = Color3.new(0, 0, 0);
			Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
			Size = UDim2.new(0, 60, 0, 45 + 2);
			Visible = false;
			ZIndex = 14;
			Parent = ScreenGui;
		});

		ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
			ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
		end);

		local ModeSelectInner = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 15;
			Parent = ModeSelectOuter;
		});

		Library:AddToRegistry(ModeSelectInner, {
			BackgroundColor3 = 'BackgroundColor';
			BorderColor3 = 'OutlineColor';
		});

		Library:Create('UIListLayout', {
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = ModeSelectInner;
		});

		local ContainerLabel = Library:CreateLabel({
			TextXAlignment = Enum.TextXAlignment.Left;
			Size = UDim2.new(1, 0, 0, 18);
			TextSize = 13;
			Visible = false;
			ZIndex = 110;
			Parent = Library.KeybindContainer;
		},  true);

		local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
		local ModeButtons = {};

		for Idx, Mode in next, Modes do
			local ModeButton = {};

			local Label = Library:CreateLabel({
				Active = false;
				Size = UDim2.new(1, 0, 0, 15);
				TextSize = 13;
				Text = Mode;
				ZIndex = 16;
				Parent = ModeSelectInner;
			});

			function ModeButton:Select()
				for _, Button in next, ModeButtons do
					Button:Deselect();
				end;

				KeyPicker.Mode = Mode;

				Label.TextColor3 = Library.AccentColor;
				Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

				ModeSelectOuter.Visible = false;
			end;

			function ModeButton:Deselect()
				KeyPicker.Mode = nil;

				Label.TextColor3 = Library.FontColor;
				Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
			end;

			Label.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					ModeButton:Select();
					Library:AttemptSave();
				end;
			end);

			if Mode == KeyPicker.Mode then
				ModeButton:Select();
			end;

			ModeButtons[Mode] = ModeButton;
		end;

		local update = function(State)
			-- The fork shows "Override" in the on-screen list while the picker is
			-- being forced active programmatically (any mode except Always).
			local ModeText = KeyPicker.Mode;
			if ModeText ~= 'Always' and KeyPicker.Override then
				ModeText = 'Override';
			end;

			ContainerLabel.Text = string.format('[%s] %s (%s)', KeyPicker.Value, Info.Text, ModeText);

			ContainerLabel.Visible = true;
			ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;

			Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';
		end;

		function KeyPicker:Update()
			if not KeyPicker.NoUI then
				local mode = Library.KeypickerListMode;
				local State = KeyPicker:GetState();

				if (mode == "Active" and KeyPicker.Parent.Type == "Toggle" and (not State or not KeyPicker.Parent.Value)) then
					ContainerLabel.Visible = false;
				elseif (mode == "Toggled" and KeyPicker.Parent.Type == "Toggle" and not KeyPicker.Parent.Value) then
					ContainerLabel.Visible = false;
				else
					update(State);
				end;
			else
				ContainerLabel.Visible = false;
			end;

			local YSize = 0
			local XSize = 0

			for _, Label in next, Library.KeybindContainer:GetChildren() do
				if Label:IsA('TextLabel') and Label.Visible then
					YSize = YSize + 18;
					if (Label.TextBounds.X > XSize) then
						XSize = Label.TextBounds.X
					end
				end;
			end;

			Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)

			Library.KeybindFrame.Visible = Library.KeypickerListVisible and (YSize ~= 0);
		end;

		-- Override forces the picker active for one cycle regardless of its key
		-- (used by features that need to arm themselves programmatically). It is
		-- cleared as soon as the real key takes over.
		function KeyPicker:OverrideState(State)
			if KeyPicker.Override == State then
				return;
			end;

			KeyPicker.Override = State;
			KeyPicker.Toggled = false;
			KeyPicker:Update();
		end;

		function KeyPicker:GetState()
			if KeyPicker.Mode == 'Always' then
				return true;
			end;

			local Key = KeyPicker.Value;

			-- '...' means "unbound"; treat it as permanently on rather than
			-- indexing Enum.KeyCode with a key that does not exist.
			if Key == '...' then
				return true;
			end;

			local State;

			if KeyPicker.Mode == 'Hold' then
				if Key == 'None' then
					return false;
				end;

				if Key == 'MB1' or Key == 'MB2' then
					State = Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
						or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
				else
					State = InputService:IsKeyDown(Enum.KeyCode[Key]);
				end;
			else
				State = KeyPicker.Toggled;
			end;

			if State and KeyPicker.Override then
				KeyPicker:OverrideState(false);
			end;

			return State or KeyPicker.Override;
		end;

		function KeyPicker:SetModePickerVisibility(Bool)
			ModeSelectOuter.Visible = Bool;
		end;

		function KeyPicker:GetModePickerVisibility()
			return ModeSelectOuter.Visible;
		end;

		function KeyPicker:SetupConnection(Connection)
			table.insert(KeyPicker.Connections, Connection);
			Library:GiveSignal(Connection);
		end;

		function KeyPicker:Remove()
			Options[Idx] = nil;

			for _, Connection in next, KeyPicker.Connections do
				Connection:Disconnect();
			end;

			table.clear(KeyPicker);

			PickOuter:Destroy();
			ContainerLabel:Destroy();
			ModeSelectOuter:Destroy();
		end;

		function KeyPicker:SetValue(Data)
			local Key, Mode = Data[1], Data[2];
			DisplayLabel.Text = Key;
			KeyPicker.Value = Key;
			ModeButtons[Mode]:Select();
			KeyPicker:Update();
		end;

		function KeyPicker:OnClick(Callback)
			KeyPicker.Clicked = Callback
		end

		function KeyPicker:OnChanged(Callback)
			KeyPicker.Changed = Callback
			Callback(KeyPicker.Value)
		end

		if ParentObj.Addons then
			table.insert(ParentObj.Addons, KeyPicker)
		end

		function KeyPicker:DoClick()
			if KeyPicker.Override then
				KeyPicker.Override = false;
				KeyPicker.Toggled = false;
			end;

			if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
				ParentObj:SetValue(not ParentObj.Value)
			end

			Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
			Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
		end

		local Picking = false;

		-- Pressing either of these while rebinding unbinds the key instead.
		local UnbindKeys = {
			[Enum.KeyCode.Escape] = true;
			[Enum.KeyCode.Backspace] = true;
		};

		PickOuter.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				Picking = true;

				DisplayLabel.Text = '';

				local Break;
				local Text = '';

				task.spawn(function()
					while (not Break) do
						if Text == '...' then
							Text = '';
						end;

						Text = Text .. '.';
						DisplayLabel.Text = Text;

						wait(0.4);
					end;
				end);

				wait(0.2);

				local Event;
				Event = InputService.InputBegan:Connect(function(Input)
					local Key;

					if Input.UserInputType == Enum.UserInputType.Keyboard then
						Key = UnbindKeys[Input.KeyCode] and "..." or Input.KeyCode.Name;
					elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Key = 'MB1';
					elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
						Key = 'MB2';
					end;

					Break = true;
					Picking = false;

					DisplayLabel.Text = Key;
					KeyPicker.Value = Key;

					Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
					Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

					Library:AttemptSave();

					Event:Disconnect();
				end);
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
				ModeSelectOuter.Visible = true;
			end;
		end);

		KeyPicker:SetupConnection(InputService.InputBegan:Connect(function(Input, Processed)
			if (not Picking and not Processed) then
				if KeyPicker.Mode == 'Toggle' then
					local Key = KeyPicker.Value;

					if Key == 'MB1' or Key == 'MB2' then
						if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
							or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 then
							KeyPicker.Toggled = not KeyPicker.Toggled
							KeyPicker:DoClick()
						end;
					elseif Input.UserInputType == Enum.UserInputType.Keyboard then
						if Input.KeyCode.Name == Key then
							KeyPicker.Toggled = not KeyPicker.Toggled;
							KeyPicker:DoClick()
						end;
					end;
				end;

				KeyPicker:Update();
			end;

			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;

				if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
					or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

					ModeSelectOuter.Visible = false;
				end;
			end;
		end))

		KeyPicker:SetupConnection(InputService.InputEnded:Connect(function(Input)
			if (not Picking) then
				KeyPicker:Update();
			end;
		end))

		if Library.FlagCopying then
			local ContextMenu = Library:AddContextMenu(PickOuter);

			ContextMenu:AddOption('Copy Flag', function()
				pcall(setclipboard, KeyPicker.Idx);
				task.wait();
				Library:Notify('Copied flag to clipboard!', 2);
				ContextMenu:Hide();
			end);
		end;

		KeyPicker:Update();

		Options[Idx] = KeyPicker;

		return self;
	end;

	BaseAddons.__index = Funcs;
	BaseAddons.__namecall = function(Table, Key, ...)
		return Funcs[Key](...);
	end;
end;

local BaseGroupbox = {};

do
	local Funcs = {};

	-- Returns the spacer frame so callers can track it and destroy it along
	-- with their element in :Remove().
	function Funcs:AddBlank(Size)
		local Groupbox = self;
		local Container = Groupbox.Container;

		return Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, Size);
			ZIndex = 1;
			Parent = Container;
		});
	end;

	-- A raw sized container an element-less consumer can draw into (used for
	-- previews, image panels, embedded viewports and so on).
	function Funcs:AddContainer(Info)
		Info = Info or {};

		local Element = { Type = 'Container' };

		local Groupbox = self;
		local Container = Groupbox.Container;

		local Outer = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, -4, 0, Info.Size or 100);
			ZIndex = 5;
			Parent = Container;
		});

		local Inner = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = Outer;
		});

		Library:AddToRegistry(Inner, {
			BackgroundColor3 = 'BackgroundColor';
			BorderColor3 = 'OutlineColor';
		});

		function Element:SetSize(Y)
			Outer.Size = UDim2.new(1, -4, 0, Y);
			Groupbox:Resize();
		end;

		function Element:GetOuter()
			return Outer;
		end;

		function Element:GetInner()
			return Inner;
		end;

		function Element:GetSize()
			return Inner.AbsoluteSize;
		end;

		local Instances = {};
		table.insert(Instances, Groupbox:AddBlank(5));

		function Element:Remove()
			for _, Instance in next, Instances do
				Instance:Destroy();
			end;

			Outer:Destroy();
			table.clear(Element);
			Groupbox:Resize();
		end;

		Groupbox:Resize();

		return Element;
	end;

	function Funcs:AddLabel(Text, DoesWrap)
		local Label = {};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local TextLabel = Library:CreateLabel({
			Size = UDim2.new(1, -4, 0, 15);
			TextSize = 14;
			Text = Text;
			TextWrapped = DoesWrap or false,
			TextXAlignment = Enum.TextXAlignment.Left;
			RichText = true,
			ZIndex = 5;
			Parent = Container;
		});

		if DoesWrap then
			local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
			TextLabel.Size = UDim2.new(1, -4, 0, Y)
		else
			Library:Create('UIListLayout', {
				Padding = UDim.new(0, 4);
				FillDirection = Enum.FillDirection.Horizontal;
				HorizontalAlignment = Enum.HorizontalAlignment.Right;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Parent = TextLabel;
			});
		end

		Label.TextLabel = TextLabel;
		Label.Container = Container;

		function Label:SetText(Text)
			TextLabel.Text = Text

			if DoesWrap then
				local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
				TextLabel.Size = UDim2.new(1, -4, 0, Y)
			end

			Groupbox:Resize();
		end

		if (not DoesWrap) then
			setmetatable(Label, BaseAddons);
		end

		local Instances = {};
		table.insert(Instances, Groupbox:AddBlank(5));

		function Label:Remove()
			for _, Instance in next, Instances do
				Instance:Destroy();
			end;

			TextLabel:Destroy();
			table.clear(Label);
			Groupbox:Resize();
		end;

		Groupbox:Resize();

		return Label;
	end;

	function Funcs:AddButton(...)
		-- TODO: Eventually redo this
		local Button = {};
		local function ProcessButtonParams(Class, Obj, ...)
			local Props = select(1, ...)
			if type(Props) == 'table' then
				Obj.Text = Props.Text
				Obj.Func = Props.Func
				Obj.DoubleClick = Props.DoubleClick
				Obj.Tooltip = Props.Tooltip
			else
				Obj.Text = select(1, ...)
				Obj.Func = select(2, ...)
			end

			assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
		end

		ProcessButtonParams('Button', Button, ...)

		local Groupbox = self;
		local Container = Groupbox.Container;

		local function CreateBaseButton(Button)
			local Outer = Library:Create('Frame', {
				BackgroundColor3 = Color3.new(0, 0, 0);
				BorderColor3 = Color3.new(0, 0, 0);
				Size = UDim2.new(1, -4, 0, 20);
				ZIndex = 5;
			});

			local Inner = Library:Create('Frame', {
				BackgroundColor3 = Library.MainColor;
				BorderColor3 = Library.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 1, 0);
				ZIndex = 6;
				Parent = Outer;
			});

			local Label = Library:CreateLabel({
				Size = UDim2.new(1, 0, 1, 0);
				TextSize = 14;
				Text = Button.Text;
				ZIndex = 6;
				Parent = Inner;
			});

			Library:Create('UIGradient', {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
				});
				Rotation = 90;
				Parent = Inner;
			});

			Library:AddToRegistry(Outer, {
				BorderColor3 = 'Black';
			});

			Library:AddToRegistry(Inner, {
				BackgroundColor3 = 'MainColor';
				BorderColor3 = 'OutlineColor';
			});

			Library:OnHighlight(Outer, Outer,
				{ BorderColor3 = 'OutlineColor' },
				{ BorderColor3 = 'Black' }
			);

			return Outer, Inner, Label
		end

		local function InitEvents(Button)
			local function WaitForEvent(event, timeout, validator)
				local bindable = Instance.new('BindableEvent')
				local connection = event:Once(function(...)

					if type(validator) == 'function' and validator(...) then
						bindable:Fire(true)
					else
						bindable:Fire(false)
					end
				end)
				task.delay(timeout, function()
					connection:disconnect()
					bindable:Fire(false)
				end)
				return bindable.Event:Wait()
			end

			local function ValidateClick(Input)
				if Library:MouseIsOverOpenedFrame() then
					return false
				end

				if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return false
				end

				return true
			end

			Button.Outer.InputBegan:Connect(function(Input)
				if not ValidateClick(Input) then return end
				if Button.Locked then return end

				if Button.DoubleClick then
					Library:RemoveFromRegistry(Button.Label)
					Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })

					Button.Label.TextColor3 = Library.AccentColor
					Button.Label.Text = 'Are you sure?'
					Button.Locked = true

					local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

					Library:RemoveFromRegistry(Button.Label)
					Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })

					Button.Label.TextColor3 = Library.FontColor
					Button.Label.Text = Button.Text
					task.defer(rawset, Button, 'Locked', false)

					if clicked then
						Library:SafeCallback(Button.Func)
					end

					return
				end

				Library:SafeCallback(Button.Func);
			end)
		end

		Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
		Button.Outer.Parent = Container

		InitEvents(Button)

		function Button:AddTooltip(tooltip)
			if type(tooltip) == 'string' then
				Library:AddToolTip(tooltip, self.Outer)
			end
			return self
		end


		function Button:AddButton(...)
			local SubButton = {}

			ProcessButtonParams('SubButton', SubButton, ...)

			self.Outer.Size = UDim2.new(0.5, -2, 0, 20)

			SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

			SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
			SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
			SubButton.Outer.Parent = self.Outer

			function SubButton:AddTooltip(tooltip)
				if type(tooltip) == 'string' then
					Library:AddToolTip(tooltip, self.Outer)
				end
				return SubButton
			end

			if type(SubButton.Tooltip) == 'string' then
				SubButton:AddTooltip(SubButton.Tooltip)
			end

			InitEvents(SubButton)
			return SubButton
		end

		if type(Button.Tooltip) == 'string' then
			Button:AddTooltip(Button.Tooltip)
		end

		Groupbox:AddBlank(5);
		Groupbox:Resize();

		return Button;
	end;

	function Funcs:AddDivider()
		local Groupbox = self;
		local Container = self.Container

		local Divider = {
			Type = 'Divider',
		}

		Groupbox:AddBlank(2);
		local DividerOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, -4, 0, 5);
			ZIndex = 5;
			Parent = Container;
		});

		local DividerInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = DividerOuter;
		});

		Library:AddToRegistry(DividerOuter, {
			BorderColor3 = 'Black';
		});

		Library:AddToRegistry(DividerInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		Groupbox:AddBlank(9);
		Groupbox:Resize();
	end

	function Funcs:AddInput(Idx, Info)
		assert(Info.Text, 'AddInput: Missing `Text` string.')

		local Textbox = {
			Idx = Idx;
			Value = Info.Default or '';
			Numeric = Info.Numeric or false;
			Finished = Info.Finished or false;
			MaxLength = Info.MaxLength;
			Type = 'Input';
			Callback = Info.Callback or function(Value) end;
		};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local InputLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 0, 15);
			TextSize = 14;
			Text = Info.Text;
			TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 5;
			Parent = Container;
		});

		Groupbox:AddBlank(1);

		local TextBoxOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, -4, 0, 20);
			ZIndex = 5;
			Parent = Container;
		});

		local TextBoxInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = TextBoxOuter;
		});

		Library:AddToRegistry(TextBoxInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		Library:OnHighlight(TextBoxOuter, TextBoxOuter,
			{ BorderColor3 = 'OutlineColor' },
			{ BorderColor3 = 'Black' }
		);

		if type(Info.Tooltip) == 'string' then
			Library:AddToolTip(Info.Tooltip, TextBoxOuter)
		end

		Library:Create('UIGradient', {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
			});
			Rotation = 90;
			Parent = TextBoxInner;
		});

		local Container = Library:Create('Frame', {
			BackgroundTransparency = 1;
			ClipsDescendants = true;

			Position = UDim2.new(0, 5, 0, 0);
			Size = UDim2.new(1, -5, 1, 0);

			ZIndex = 7;
			Parent = TextBoxInner;
		})

		local Box = Library:Create('TextBox', {
			BackgroundTransparency = 1;

			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromScale(5, 1),

			Font = Library.Font;
			PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
			PlaceholderText = Info.Placeholder or '';

			ClearTextOnFocus = Info.Clear or false;
			Text = Info.Default or '';
			TextColor3 = Library.FontColor;
			TextSize = 14;
			TextStrokeTransparency = 0;
			TextXAlignment = Enum.TextXAlignment.Left;

			ZIndex = 7;
			Parent = Container;
		});

		Library:ApplyTextStroke(Box);

		function Textbox:SetValue(Text)
			if Info.MaxLength and #Text > Info.MaxLength then
				Text = Text:sub(1, Info.MaxLength);
			end;

			if Textbox.Numeric then
				if (not tonumber(Text)) and Text:len() > 0 then
					Text = Textbox.Value
				end
			end

			Textbox.Value = Text;
			Box.Text = Text;

			Library:SafeCallback(Textbox.Callback, Textbox.Value);
			Library:SafeCallback(Textbox.Changed, Textbox.Value);
		end;

		if Textbox.Finished then
			Box.FocusLost:Connect(function(enter)
				if not enter then return end

				Textbox:SetValue(Box.Text);
				Library:AttemptSave();
			end)
		else
			Box:GetPropertyChangedSignal('Text'):Connect(function()
				Textbox:SetValue(Box.Text);
				Library:AttemptSave();
			end);
		end

		-- https://devforum.roblox.com/t/how-to-make-textboxes-follow-current-cursor-position/1368429/6
		-- thank you nicemike40 :)

		local function Update()
			local PADDING = 2
			local reveal = Container.AbsoluteSize.X

			if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
				-- we aren't focused, or we fit so be normal
				Box.Position = UDim2.new(0, PADDING, 0, 0)
			else
				-- we are focused and don't fit, so adjust position
				local cursor = Box.CursorPosition
				if cursor ~= -1 then
					-- calculate pixel width of text from start to cursor
					local subtext = string.sub(Box.Text, 1, cursor-1)
					local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

					-- check if we're inside the box with the cursor
					local currentCursorPos = Box.Position.X.Offset + width

					-- adjust if necessary
					if currentCursorPos < PADDING then
						Box.Position = UDim2.fromOffset(PADDING-width, 0)
					elseif currentCursorPos > reveal - PADDING - 1 then
						Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
					end
				end
			end
		end

		task.spawn(Update)

		Box:GetPropertyChangedSignal('Text'):Connect(Update)
		Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
		Box.FocusLost:Connect(Update)
		Box.Focused:Connect(Update)

		Library:AddToRegistry(Box, {
			TextColor3 = 'FontColor';
		});

		function Textbox:OnChanged(Func)
			Textbox.Changed = Func;
			Func(Textbox.Value);
		end;

		if Library.FlagCopying then
			local ContextMenu = Library:AddContextMenu(TextBoxOuter);

			ContextMenu:AddOption('Copy Flag', function()
				pcall(setclipboard, Textbox.Idx);
				task.wait();
				Library:Notify('Copied flag to clipboard!', 2);
				ContextMenu:Hide();
			end);
		end;

		Textbox.Instances = {};
		table.insert(Textbox.Instances, Groupbox:AddBlank(5));

		function Textbox:Remove()
			for _, Instance in next, Textbox.Instances do
				Instance:Destroy();
			end;

			Options[Idx] = nil;
			TextBoxOuter:Destroy();
			InputLabel:Destroy();
			table.clear(Textbox);
			Groupbox:Resize();
		end;

		Groupbox:Resize();

		Options[Idx] = Textbox;

		return Textbox;
	end;

	function Funcs:AddToggle(Idx, Info)
		assert(Info.Text, 'AddInput: Missing `Text` string.')

		local Toggle = {
			Idx = Idx;
			Value = Info.Default or false;
			Type = 'Toggle';
			Visible = true;

			Callback = Info.Callback or function(Value) end;
			ChangedFuncs = {};
			Addons = {},
			Risky = Info.Risky,
		};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local ToggleOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(0, 13, 0, 13);
			ZIndex = 5;
			Parent = Container;
		});

		Library:AddToRegistry(ToggleOuter, {
			BorderColor3 = 'Black';
		});

		local ToggleInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = ToggleOuter;
		});

		Library:AddToRegistry(ToggleInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		local ToggleLabel = Library:CreateLabel({
			Size = UDim2.new(0, 216, 1, 0);
			Position = UDim2.new(1, 6, 0, 0);
			TextSize = 14;
			Text = Info.Text;
			TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 6;
			Parent = ToggleInner;
		});

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 4);
			FillDirection = Enum.FillDirection.Horizontal;
			HorizontalAlignment = Enum.HorizontalAlignment.Right;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = ToggleLabel;
		});

		local ToggleRegion = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(0, 170, 1, 0);
			ZIndex = 8;
			Parent = ToggleOuter;
		});

		Library:OnHighlight(ToggleRegion, ToggleOuter,
			{ BorderColor3 = 'OutlineColor' },
			{ BorderColor3 = 'Black' }
		);

		function Toggle:UpdateColors()
			Toggle:Display();
		end;

		if type(Info.Tooltip) == 'string' then
			Library:AddToolTip(Info.Tooltip, ToggleRegion)
		end

		function Toggle:Display()
			ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
			ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

			Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
			Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
		end;

		-- Unlike upstream, OnChanged stacks: several consumers can subscribe to
		-- the same toggle without clobbering each other's callback.
		function Toggle:OnChanged(Func)
			table.insert(Toggle.ChangedFuncs, Func);
			Func(Toggle.Value);
		end;

		function Toggle:SetValue(Bool)
			-- A KeyPicker synced to this toggle calls back into SetValue; without
			-- this guard the two bounce off each other.
			if Toggle.SettingValue then
				return;
			end;

			Toggle.SettingValue = true;

			Bool = (not not Bool);

			Toggle.Value = Bool;
			Toggle:Display();

			for _, Addon in next, Toggle.Addons do
				if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
					Addon.Toggled = Bool;
					Addon:Update();
				end;
			end

			Library:SafeCallback(Toggle.Callback, Toggle.Value);
			Library:SafeCallback(Toggle.Changed, Toggle.Value);

			for _, Func in next, Toggle.ChangedFuncs do
				Library:SafeCallback(Func, Toggle.Value);
			end;

			Library:UpdateDependencyBoxes();

			Toggle.SettingValue = false;
		end;

		function Toggle:SetVisible(Bool)
			Toggle.Visible = Bool;
			ToggleOuter.Visible = Bool;

			for _, Instance in next, Toggle.Instances do
				Instance.Visible = Bool;
			end;

			Groupbox:Resize();
		end;

		function Toggle:Remove()
			for _, Instance in next, Toggle.Instances do
				Instance:Destroy();
			end;

			Toggles[Idx] = nil;
			ToggleOuter:Destroy();
			table.clear(Toggle);
			Groupbox:Resize();
		end;

		ToggleRegion.InputBegan:Connect(function(Input)
			-- Ignore clicks that land while the window is being dragged.
			if Library.IsDragging then
				return;
			end;

			if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame())
				or Input.UserInputType == Enum.UserInputType.Touch then

				Toggle:SetValue(not Toggle.Value)
				Library:AttemptSave();
			end;
		end);

		if Library.FlagCopying then
			local ContextMenu = Library:AddContextMenu(ToggleOuter, ToggleRegion);

			ContextMenu:AddOption('Copy Flag', function()
				pcall(setclipboard, Toggle.Idx);
				task.wait();
				Library:Notify('Copied flag to clipboard!', 2);
				ContextMenu:Hide();
			end);
		end;

		if Toggle.Risky then
			Library:RemoveFromRegistry(ToggleLabel)
			ToggleLabel.TextColor3 = Library.RiskColor
			Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
		end

		Toggle:Display();

		Toggle.Instances = {};
		table.insert(Toggle.Instances, Groupbox:AddBlank(Info.BlankSize or 7));

		Groupbox:Resize();

		Toggle.ColorPickerCount = 0;
		Toggle.ToggleRegion = ToggleRegion;
		Toggle.TextLabel = ToggleLabel;
		Toggle.Container = Container;
		setmetatable(Toggle, BaseAddons);

		Toggles[Idx] = Toggle;

		Library:UpdateDependencyBoxes();

		return Toggle;
	end;

	function Funcs:AddSlider(Idx, Info, SliderParent)
		assert(Info.Default, 'AddSlider: Missing default value.');
		assert(Info.Text, 'AddSlider: Missing slider text.');
		assert(Info.Min, 'AddSlider: Missing minimum value.');
		assert(Info.Max, 'AddSlider: Missing maximum value.');
		assert(Info.Rounding, 'AddSlider: Missing rounding value.');

		local Slider = {
			Idx = Idx;
			Value = Info.Default;
			Min = Info.Min;
			Max = Info.Max;
			Rounding = Info.Rounding;
			Increment = Info.Increment;
			MaxSize = 232;--SliderParent and 232/2 - 3 or 232;
			Type = 'Slider';
			Callback = Info.Callback or function(Value) end;
			ChangedFuncs = {};
		};

		Slider.Parent = SliderParent;

		local Groupbox = self;
		local Container = SliderParent and SliderParent.Outer or Groupbox.Container;

		-- Like ueleak: no separate title label. The name lives inside the bar as
		-- "<text>: <value><suffix>".

		local SliderOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			--Position = UDim2.fromScale(Groupbox.SliderParent and .5 or 0,0);
			Size = UDim2.new(1,0,0,13);
			ZIndex = 5;
			Parent = Container;
		});

		Slider.Outer = SliderOuter;

		Library:AddToRegistry(SliderOuter, {
			BorderColor3 = 'Black';
		});

		local SliderInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = SliderOuter;
		});

		Library:AddToRegistry(SliderInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		local Fill = Library:Create('Frame', {
			BackgroundColor3 = Library.AccentColor;
			BorderColor3 = Library.AccentColorDark;
			Size = UDim2.new(0, 0, 1, 0);
			ZIndex = 7;
			Parent = SliderInner;
		});

		Library:AddToRegistry(Fill, {
			BackgroundColor3 = 'AccentColor';
			BorderColor3 = 'AccentColorDark';
		});

		local HideBorderRight = Library:Create('Frame', {
			BackgroundColor3 = Library.AccentColor;
			BorderSizePixel = 0;
			Position = UDim2.new(1, 0, 0, 0);
			Size = UDim2.new(0, 1, 1, 0);
			ZIndex = 8;
			Parent = Fill;
		});

		Library:AddToRegistry(HideBorderRight, {
			BackgroundColor3 = 'AccentColor';
		});

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 1, 0);
			TextSize = 14;
			Text = 'Infinite';
			ZIndex = 9;
			Parent = SliderInner;
		});

		Library:OnHighlight(SliderOuter, SliderOuter,
			{ BorderColor3 = 'AccentColor' },
			{ BorderColor3 = 'Black' }
		);

		if type(Info.Tooltip) == 'string' then
			Library:AddToolTip(Info.Tooltip, SliderOuter)
		end

		local get_count = function()
			local parent, count = Slider, 1;
			repeat
				parent = parent.Parent or nil;
				if (parent) then
					count += 1;
				end
			until not parent;
			return count;
		end;

		function Slider:UpdateColors()
			Fill.BackgroundColor3 = Library.AccentColor;
			Fill.BorderColor3 = Library.AccentColorDark;
		end;

		-- The fill is tweened rather than snapped; the previous tween is
		-- cancelled so a fast drag does not queue up a backlog of them.
		local FillTween = nil;

		function Slider:Display()
			local Suffix = Info.Suffix or '';

			DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix;

			local Alpha = Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, 1);

			if FillTween then
				FillTween:Cancel();
			end;

			FillTween = TweenService:Create(
				Fill,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(Alpha, 0, 1, 0) }
			);

			FillTween:Play();

			HideBorderRight.Visible = not (Alpha == 1 or Alpha == 0);
		end;

		function Slider:OnChanged(Func)
			table.insert(Slider.ChangedFuncs, Func);
			Func(Slider.Value);
		end;

		-- Increment (fork addition) snaps to arbitrary steps, e.g. 0.05.
		-- The %.10f round-trip strips the float noise that math.round leaves.
		local function Round(Value)
			if Slider.Increment then
				local Snapped = math.round(Value / Slider.Increment) * Slider.Increment;
				return tonumber(string.format('%.10f', Snapped));
			elseif Slider.Rounding == 0 then
				return math.floor(Value);
			end;

			return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
		end;

		function Slider:GetValueFromXOffset(X)
			return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max)) + 0;
		end;

		function Slider:SetValue(Str)
			local Num = tonumber(Str);

			if (not Num) then
				return;
			end;

			Num = math.clamp(Num, Slider.Min, Slider.Max);

			Slider.Value = Num;
			Slider:Display();

			Library:SafeCallback(Slider.Callback, Slider.Value);
			Library:SafeCallback(Slider.Changed, Slider.Value);

			for _, Func in next, Slider.ChangedFuncs do
				Library:SafeCallback(Func, Slider.Value);
			end;
		end;

		if (get_count() < 3) then
			function Slider:AddSlider(idx, info)
				Slider:Display();
				return Funcs.AddSlider(Groupbox, idx, info, Slider);
			end;
		end

		local function FireChanged(NewValue)
			Library:SafeCallback(Slider.Callback, Slider.Value);
			Library:SafeCallback(Slider.Changed, Slider.Value);

			for _, Func in next, Slider.ChangedFuncs do
				Library:SafeCallback(Func, NewValue);
			end;
		end;

		SliderInner.InputBegan:Connect(function(Input)
			if Library.IsDragging then
				return;
			end;

			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				local mPos = Mouse.X;
				local gPos = Fill.Size.X.Offset;
				local Diff = mPos - (Fill.AbsolutePosition.X + gPos);

				while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local nMPos = Mouse.X;
					local nX = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize);

					local nValue = Slider:GetValueFromXOffset(nX);
					local OldValue = Slider.Value;
					Slider.Value = nValue;

					Slider:Display();

					if nValue ~= OldValue then
						FireChanged(nValue);
					end;

					RenderStepped:Wait();
				end;

				Library:AttemptSave();
			end;

			if Input.UserInputType == Enum.UserInputType.Touch and not Library:MouseIsOverOpenedFrame() then
				local mPos = Input.Position.X;
				local gPos = Fill.Size.X.Offset;
				local Diff = mPos - (Fill.AbsolutePosition.X + gPos);

				local Held = true;
				local Conn;

				Conn = Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						Held = false;
					end;
				end);

				while Held do
					local nMPos = Input.Position.X;
					local nX = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize);

					local nValue = Slider:GetValueFromXOffset(nX);
					local OldValue = Slider.Value;
					Slider.Value = nValue;

					Slider:Display();

					if nValue ~= OldValue then
						FireChanged(nValue);
					end;

					RenderStepped:Wait();
				end;

				if Conn then
					Conn:Disconnect();
				end;

				Library:AttemptSave();
			end;
		end);

		if Library.FlagCopying then
			local ContextMenu = Library:AddContextMenu(SliderOuter);

			ContextMenu:AddOption('Copy Flag', function()
				pcall(setclipboard, Slider.Idx);
				task.wait();
				Library:Notify('Copied flag to clipboard!', 2);
				ContextMenu:Hide();
			end);
		end;

		Slider:Display();

		local size = get_count();
		local get_slider = function(count)
			local slider = Slider;
			for i=1,count-1 do
				slider = slider.Parent;
			end;
			return slider;
		end;

		local wanted_size = (Groupbox.Container.AbsoluteSize.X) / size;
		wanted_size += size - 2;

		local n_size = math.round(wanted_size);

		for i = size, 1, -1 do
			local slider = get_slider(i);
			slider.Outer.Size = UDim2.new(0, n_size - 3, 0, 13)
			slider.Outer.Position = UDim2.new(1, 2, 0, 0);
			slider.MaxSize = slider.Outer.AbsoluteSize.X - 2;

			slider:Display();
		end;

		if (n_size ~= wanted_size) then -- jank fix..
			local slider = get_slider(1);
			slider.Outer.Size = UDim2.new(0, n_size - (size + 1), 0, 13)
			slider.Outer.Position = UDim2.new(1, 2, 0, 0);
			slider.MaxSize = slider.Outer.AbsoluteSize.X - 2;

			slider:Display();
		end;

		Slider.Instances = {};

		if (not SliderParent) then
			table.insert(Slider.Instances, Groupbox:AddBlank(Info.BlankSize or 6));
			Groupbox:Resize();
		end;

		function Slider:Remove()
			for _, Instance in next, Slider.Instances do
				Instance:Destroy();
			end;

			Options[Idx] = nil;
			SliderOuter:Destroy();
			table.clear(Slider);
			Groupbox:Resize();
		end;

		Options[Idx] = Slider;

		return Slider;
	end;

	function Funcs:AddDropdown(Idx, Info)
		if Info.SpecialType == 'Player' then
			Info.Values = GetPlayersString();
			Info.AllowNull = true;
		elseif Info.SpecialType == 'Team' then
			Info.Values = GetTeamsString();
			Info.AllowNull = true;
		end;

		assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
		assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

		if (not Info.Text) then
			Info.Compact = true;
		end;

		local Dropdown = {
			Idx = Idx;
			Illegal = Info.Illegal;
			Values = Info.Values;
			Value = Info.Multi and {};
			Multi = Info.Multi;
			Type = 'Dropdown';
			SpecialType = Info.SpecialType; -- can be either 'Player' or 'Team'
			Callback = Info.Callback or function(Value) end;
		};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local RelativeOffset = 0;

		if not Info.Compact then
			local DropdownLabel = Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 10);
				TextSize = 14;
				Text = Info.Text;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Bottom;
				ZIndex = 5;
				Parent = Container;
			});

			Groupbox:AddBlank(3);
		end

		for _, Element in next, Container:GetChildren() do
			if not Element:IsA('UIListLayout') then
				RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
			end;
		end;

		local DropdownOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, -4, 0, 20);
			ZIndex = 5;
			Parent = Container;
		});

		Library:AddToRegistry(DropdownOuter, {
			BorderColor3 = 'Black';
		});

		local DropdownInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = DropdownOuter;
		});

		Library:AddToRegistry(DropdownInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		Library:Create('UIGradient', {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
			});
			Rotation = 90;
			Parent = DropdownInner;
		});

		local DropdownArrow = Library:CreateLabel({
			AnchorPoint = Vector2.new(0.5, 0.5);
			BackgroundTransparency = 1;
			Position = UDim2.new(1, -11, 0.5, 0);
			Size = UDim2.fromOffset(14, 14);
			Text = '>';
			TextSize = 14;
			Font = Enum.Font.GothamBold;
			ZIndex = 8;
			Parent = DropdownInner;
		});

		local DropdownArrowTween = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

		local ItemClip = Library:Create('Frame', {
			BackgroundTransparency = 1;
			ClipsDescendants = true;
			Position = UDim2.new(0, 5, 0, 0);
			Size = UDim2.new(1, -22, 1, 0);
			ZIndex = 7;
			Parent = DropdownInner;
		});

		local ItemList = Library:CreateLabel({
			Size = UDim2.new(1, 0, 1, 0);
			TextSize = 14;
			Text = '...';
			TextXAlignment = Enum.TextXAlignment.Left;
			TextTruncate = Enum.TextTruncate.AtEnd;
			ZIndex = 7;
			Parent = ItemClip;
		});

		Library:OnHighlight(DropdownOuter, DropdownOuter,
			{ BorderColor3 = 'OutlineColor' },
			{ BorderColor3 = 'Black' }
		);

		if type(Info.Tooltip) == 'string' then
			Library:AddToolTip(Info.Tooltip, DropdownOuter)
		end

		local MAX_DROPDOWN_ITEMS = 8;

		local ListOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			ZIndex = 20;
			Visible = false;
			Parent = ScreenGui;
		});

		local function RecalculateListPosition()
			ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1);
		end;

		-- The list hugs its content, clamped to MAX_DROPDOWN_ITEMS; past that the
		-- inner ScrollingFrame scrolls. With no explicit size the height is
		-- re-derived from the current value count so reopening never inflates it.
		local function RecalculateListSize(YSize)
			ListOuter.Size = UDim2.fromOffset(
				DropdownOuter.AbsoluteSize.X + 0.5,
				YSize or math.clamp(#Dropdown.Values * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1
			);
		end;

		RecalculateListPosition();
		RecalculateListSize();

		DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);

		local ListInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 21;
			Parent = ListOuter;
		});

		Library:AddToRegistry(ListInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		local Scrolling = Library:Create('ScrollingFrame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			CanvasSize = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 21;
			Parent = ListInner;

			TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
			BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

			-- A 3px bar is unusable with a finger.
			ScrollBarThickness = Library.IsMobile and 15 or 3,
			ScrollBarImageColor3 = Library.AccentColor,
		});

		Library:AddToRegistry(Scrolling, {
			ScrollBarImageColor3 = 'AccentColor'
		})

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 0);
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = Scrolling;
		});

		function Dropdown:Display()
			local Values = Dropdown.Values;
			local Str = '';

			if Info.Multi then
				for Idx, Value in next, Values do
					if Dropdown.Value[Value] then
						Str = Str .. Value .. ', ';
					end;
				end;

				Str = Str:sub(1, #Str - 2);
			else
				Str = Dropdown.Value or '';
			end;

			ItemList.Text = (Str == '' and '...' or Str);
		end;

		function Dropdown:GetActiveValues()
			if Info.Multi then
				local T = {};

				for Value, Bool in next, Dropdown.Value do
					table.insert(T, Value);
				end;

				return T;
			else
				return Dropdown.Value and 1 or 0;
			end;
		end;

		function Dropdown:BuildDropdownList()
			local Values = Dropdown.Values;
			local Buttons = {};

			for _, Element in next, Scrolling:GetChildren() do
				if not Element:IsA('UIListLayout') then
					Element:Destroy();
				end;
			end;

			local Count = 0;

			for Idx, Value in next, Values do
				local Table = {};

				Count = Count + 1;

				local Button = Library:Create('Frame', {
					BackgroundColor3 = Library.MainColor;
					BorderColor3 = Library.OutlineColor;
					BorderMode = Enum.BorderMode.Middle;
					Size = UDim2.new(1, -1, 0, 20);
					ZIndex = 23;
					Active = true,
					Parent = Scrolling;
				});

				Library:AddToRegistry(Button, {
					BackgroundColor3 = 'MainColor';
					BorderColor3 = 'OutlineColor';
				});

				local ButtonLabel = Library:CreateLabel({
					Active = false;
					Size = UDim2.new(1, -6, 1, 0);
					Position = UDim2.new(0, 6, 0, 0);
					TextSize = 14;
					Text = Value;
					TextXAlignment = Enum.TextXAlignment.Left;
					ZIndex = 25;
					Parent = Button;
				});

				Library:OnHighlight(Button, Button,
					{ BorderColor3 = 'OutlineColor', ZIndex = 24 },
					{ BorderColor3 = 'OutlineColor', ZIndex = 23 }
				);

				local Selected;

				if Info.Multi then
					Selected = Dropdown.Value[Value];
				else
					Selected = Dropdown.Value == Value;
				end;

				function Table:UpdateButton()
					if Info.Multi then
						Selected = Dropdown.Value[Value];
					else
						Selected = Dropdown.Value == Value;
					end;

					ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
					Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
				end;

				ButtonLabel.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1
						or Input.UserInputType == Enum.UserInputType.Touch then

						local Try = not Selected;

						if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
						else
							if Info.Multi then
								Selected = Try;

								if Selected then
									Dropdown.Value[Value] = true;
								else
									Dropdown.Value[Value] = nil;
								end;
							else
								Selected = Try;

								if Selected then
									Dropdown.Value = Value;
								else
									Dropdown.Value = nil;
								end;

								for _, OtherButton in next, Buttons do
									OtherButton:UpdateButton();
								end;
							end;

							Table:UpdateButton();
							Dropdown:Display();

							Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
							Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

							Library:AttemptSave();
						end;
					end;
				end);

				Table:UpdateButton();
				Dropdown:Display();

				Buttons[Button] = Table;
			end;

			Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);

			-- Toggle Visible so the ScrollingFrame re-reads its new CanvasSize.
			Scrolling.Visible = false;
			Scrolling.Visible = true;

			RecalculateListSize(math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1);
		end;

		function Dropdown:SetValues(NewValues)
			if NewValues then
				Dropdown.Values = NewValues;
			end;

			Dropdown:BuildDropdownList();
		end;

		function Dropdown:OpenDropdown()
			-- On touch, scrolling the list would otherwise drag the window.
			if Library.IsMobile then
				Library.CanDrag = false;
			end;

			ListOuter.Visible = true;
			Library.OpenedFrames[ListOuter] = true;
			TweenService:Create(DropdownArrow, DropdownArrowTween, { Rotation = 90 }):Play();

			RecalculateListSize();
		end;

		function Dropdown:CloseDropdown()
			if Library.IsMobile then
				Library.CanDrag = true;
			end;

			ListOuter.Visible = false;
			Library.OpenedFrames[ListOuter] = nil;
			TweenService:Create(DropdownArrow, DropdownArrowTween, { Rotation = 0 }):Play();
		end;

		function Dropdown:OnChanged(Func)
			Dropdown.Changed = Func;
			Func(Dropdown.Value);
		end;

		function Dropdown:SetValue(Val)
			if Dropdown.Multi then
				local nTable = {};

				for Value, Bool in next, Val do
					if Dropdown.Illegal or table.find(Dropdown.Values, Value) then
						nTable[Value] = true
					end;
				end;

				Dropdown.Value = nTable;
			else
				if (not Val) then
					Dropdown.Value = nil;
				elseif Dropdown.Illegal or table.find(Dropdown.Values, Val) then
					Dropdown.Value = Val;
				end;
			end;

			Dropdown:BuildDropdownList();

			Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
			Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
		end;

		DropdownOuter.InputBegan:Connect(function(Input)
			if Library.IsDragging then
				return;
			end;

			if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame())
				or Input.UserInputType == Enum.UserInputType.Touch then

				if ListOuter.Visible then
					Dropdown:CloseDropdown();
				else
					Dropdown:OpenDropdown();
				end;
			end;
		end);

		Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
			if Library.IsDragging then
				return;
			end;

			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

				if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
					or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

					Dropdown:CloseDropdown();
				end;
			end;
		end));

		if Library.FlagCopying then
			local ContextMenu = Library:AddContextMenu(DropdownOuter);

			ContextMenu:AddOption('Copy Flag', function()
				pcall(setclipboard, Dropdown.Idx);
				task.wait();
				Library:Notify('Copied flag to clipboard!', 2);
				ContextMenu:Hide();
			end);
		end;

		Dropdown:BuildDropdownList();
		Dropdown:Display();

		local Defaults = {}

		if type(Info.Default) == 'string' then
			local Idx = table.find(Dropdown.Values, Info.Default)
			if Idx then
				table.insert(Defaults, Idx)
			end
		elseif type(Info.Default) == 'table' then
			for _, Value in next, Info.Default do
				local Idx = table.find(Dropdown.Values, Value)
				if Idx then
					table.insert(Defaults, Idx)
				end
			end
		elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
			table.insert(Defaults, Info.Default)
		end

		if next(Defaults) then
			for i = 1, #Defaults do
				local Index = Defaults[i]
				if Info.Multi then
					Dropdown.Value[Dropdown.Values[Index]] = true
				else
					Dropdown.Value = Dropdown.Values[Index];
				end

				if (not Info.Multi) then break end
			end

			Dropdown:BuildDropdownList();
			Dropdown:Display();
		end

		Dropdown.Instances = {};
		table.insert(Dropdown.Instances, Groupbox:AddBlank(Info.BlankSize or 5));

		function Dropdown:Remove()
			for _, Instance in next, Dropdown.Instances do
				Instance:Destroy();
			end;

			Options[Idx] = nil;
			DropdownOuter:Destroy();
			ListOuter:Destroy();
			table.clear(Dropdown);
			Groupbox:Resize();
		end;

		Groupbox:Resize();

		Options[Idx] = Dropdown;

		return Dropdown;
	end;

	function Funcs:AddDependencyBox()
		local Depbox = {
			Dependencies = {};
		};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local Holder = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, 0);
			Visible = false;
			Parent = Container;
		});

		local Frame = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 1, 0);
			Visible = true;
			Parent = Holder;
		});

		local Layout = Library:Create('UIListLayout', {
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = Frame;
		});

		function Depbox:Resize()
			Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
			Groupbox:Resize();
		end;

		Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			Depbox:Resize();
		end);

		Holder:GetPropertyChangedSignal('Visible'):Connect(function()
			Depbox:Resize();
		end);

		-- The fork uses OR semantics: the box shows as soon as any one of its
		-- dependencies matches, which is what multi-mode sections need.
		function Depbox:Update()
			local Visible = false;

			for _, Dependency in next, Depbox.Dependencies do
				if Dependency[1].Value == Dependency[2] then
					Visible = true;
					break;
				end;
			end;

			Holder.Visible = Visible;
			Depbox:Resize();
		end;

		function Depbox:SetupDependencies(Dependencies)
			for _, Dependency in next, Dependencies do
				assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
				assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
				assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
			end;

			Depbox.Dependencies = Dependencies;
			Depbox:Update();
		end;

		function Depbox:Remove()
			local Index = table.find(Library.DependencyBoxes, Depbox);

			if Index then
				table.remove(Library.DependencyBoxes, Index);
			end;

			table.clear(Depbox);
			Holder:Destroy();
			Groupbox:Resize();
		end;

		Depbox.Container = Frame;

		setmetatable(Depbox, BaseGroupbox);

		table.insert(Library.DependencyBoxes, Depbox);

		return Depbox;
	end;

	BaseGroupbox.__index = Funcs;
	BaseGroupbox.__namecall = function(Table, Key, ...)
		return Funcs[Key](...);
	end;
end;

-- < Create other UI elements >
do
	-- The fork centres notifications on the lower half of the screen rather than
	-- stacking them down the top-left corner. An outer clipping frame holds the
	-- inner list; `Library.NotificationArea` is the inner list itself (matching
	-- the fork, where notifications are parented straight to it).
	local NotificationOuter = Library:Create('Frame', {
		BackgroundTransparency = 1;
		AnchorPoint = Vector2.new(0.5, 0);
		Position = UDim2.new(0.5, 0, 0.6, 39);
		Size = UDim2.new(0, 2560, 0, 200);
		ClipsDescendants = true;
		ZIndex = 100;
		Parent = ScreenGui;
	});

	Library.NotificationArea = Library:Create('Frame', {
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 0, 0, 1);
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 100;
		Parent = NotificationOuter;
	});

	Library:Create('UIListLayout', {
		Padding = UDim.new(0, 4);
		FillDirection = Enum.FillDirection.Vertical;
		HorizontalAlignment = Enum.HorizontalAlignment.Center;
		VerticalAlignment = Enum.VerticalAlignment.Top;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = Library.NotificationArea;
	});

	local WatermarkOuter = Library:Create('Frame', {
		BorderColor3 = Color3.new(0, 0, 0);
		Position = UDim2.new(0, 100, 0, -25);
		Size = UDim2.new(0, 213, 0, 20);
		ZIndex = 200;
		Visible = false;
		Parent = ScreenGui;
	});

	local WatermarkInner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.AccentColor;
		BorderMode = Enum.BorderMode.Inset;
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 201;
		Parent = WatermarkOuter;
	});

	Library:AddToRegistry(WatermarkInner, {
		BorderColor3 = 'AccentColor';
	});

	local InnerFrame = Library:Create('Frame', {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderSizePixel = 0;
		Position = UDim2.new(0, 1, 0, 1);
		Size = UDim2.new(1, -2, 1, -2);
		ZIndex = 202;
		Parent = WatermarkInner;
	});

	local Gradient = Library:Create('UIGradient', {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
			ColorSequenceKeypoint.new(1, Library.MainColor),
		});
		Rotation = -90;
		Parent = InnerFrame;
	});

	Library:AddToRegistry(Gradient, {
		Color = function()
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
				ColorSequenceKeypoint.new(1, Library.MainColor),
			});
		end
	});

	local WatermarkLabel = Library:CreateLabel({
		Position = UDim2.new(0, 5, 0, 0);
		Size = UDim2.new(1, -4, 1, 0);
		TextSize = 14;
		TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 203;
		Parent = InnerFrame;
	});

	Library.Watermark = WatermarkOuter;
	Library.WatermarkText = WatermarkLabel;
	Library:MakeDraggable(Library.Watermark);



	local KeybindOuter = Library:Create('Frame', {
		AnchorPoint = Vector2.new(0, 0.5);
		BorderColor3 = Color3.new(0, 0, 0);
		Position = UDim2.new(0, 10, 0.5, 0);
		Size = UDim2.new(0, 210, 0, 20);
		Visible = false;
		ZIndex = 100;
		Parent = ScreenGui;
	});

	local KeybindInner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.OutlineColor;
		BorderMode = Enum.BorderMode.Inset;
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 101;
		Parent = KeybindOuter;
	});

	Library:AddToRegistry(KeybindInner, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	}, true);

	local ColorFrame = Library:Create('Frame', {
		BackgroundColor3 = Library.AccentColor;
		BorderSizePixel = 0;
		Size = UDim2.new(1, 0, 0, 2);
		ZIndex = 102;
		Parent = KeybindInner;
	});

	Library:AddToRegistry(ColorFrame, {
		BackgroundColor3 = 'AccentColor';
	}, true);

	local KeybindLabel = Library:CreateLabel({
		Size = UDim2.new(1, 0, 0, 20);
		Position = UDim2.fromOffset(5, 2),
		TextXAlignment = Enum.TextXAlignment.Left,

		Text = 'Keybinds';
		ZIndex = 104;
		Parent = KeybindInner;
	});

	local KeybindContainer = Library:Create('Frame', {
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 1, -20);
		Position = UDim2.new(0, 0, 0, 20);
		ZIndex = 1;
		Parent = KeybindInner;
	});

	Library:Create('UIListLayout', {
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = KeybindContainer;
	});

	Library:Create('UIPadding', {
		PaddingLeft = UDim.new(0, 5),
		Parent = KeybindContainer,
	})

	Library.KeybindFrame = KeybindOuter;
	Library.KeybindContainer = KeybindContainer;
	Library:MakeDraggable(KeybindOuter);
end;

--// Popouts //--
-- A standalone draggable window on its own ScreenGui that auto-sizes to its
-- contents. Groupbox element methods work on it via BaseGroupbox.

function Library:CreatePopout(Config)
	if type(Config.Title) ~= 'string' then
		Config.Title = 'No title';
	end;

	if typeof(Config.Position) ~= 'UDim2' then
		Config.Position = UDim2.fromOffset(175, 50);
	end;

	Config.Size = Config.Size or Vector2.new(200, 200);

	local PopoutGui = Instance.new('ScreenGui');
	ProtectGui(PopoutGui);
	PopoutGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
	PopoutGui.Parent = CoreGui;
	PopoutGui.DisplayOrder = (Config.ZIndex or 0) + 998;

	if Config.Center then
		Config.AnchorPoint = Vector2.new(0.5, 0.5);
		Config.Position = UDim2.fromScale(0.5, 0.5);
	end;

	local Popout = {};

	local Outer = Library:Create('Frame', {
		AnchorPoint = Config.AnchorPoint or Vector2.zero;
		BackgroundColor3 = Color3.new(0, 0, 0);
		BorderSizePixel = 0;
		Position = Config.Position;
		Size = UDim2.fromOffset(Config.Size.X, Config.Size.Y);
		Visible = Config.AutoShow or false;
		ZIndex = 1;
		Parent = PopoutGui;
	});

	if not Config.RemoveTopbar then
		Library:MakeDraggableOutline(Outer, 25);
	end;

	local Inner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.OutlineColor;
		BorderMode = Enum.BorderMode.Inset;
		Position = UDim2.new(0, 1, 0, 1);
		Size = UDim2.new(1, -2, 1, -2);
		ZIndex = 1;
		Parent = Outer;
	});

	Library:AddToRegistry(Inner, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	});

	if not Config.RemoveTopbar then
		Library:CreateLabel({
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 0, 25);
			Text = Config.Title or '';
			TextXAlignment = Enum.TextXAlignment.Center;
			ZIndex = 1;
			Font = Library.Font;
			Parent = Inner;
		});

		local VersionLabel = Library:Create('TextLabel', {
			BackgroundTransparency = 1;
			Font = Library.Font;
			TextColor3 = Library.AccentColor;
			TextSize = 16;
			TextStrokeTransparency = 0;
			Position = UDim2.new(0, -8, 0, 0);
			Size = UDim2.new(1, 0, 0, 25);
			Text = Config.Version or '';
			RichText = true;
			TextXAlignment = Enum.TextXAlignment.Right;
			ZIndex = 1;
			Parent = Inner;
		});

		Library:AddToRegistry(VersionLabel, { TextColor3 = 'AccentColor' });
	end;

	local TopOffset = Config.RemoveTopbar and 8 or 25;
	local HeightDelta = Config.RemoveTopbar and -16 or -33;

	local BodyOuter = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		Position = UDim2.new(0, 8, 0, TopOffset);
		Size = UDim2.new(1, -16, 1, HeightDelta);
		ZIndex = 1;
		Parent = Inner;
	});

	Library:AddToRegistry(BodyOuter, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'OutlineColor';
	});

	local BodyInner = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Color3.new(0, 0, 0);
		BorderMode = Enum.BorderMode.Inset;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 1;
		Parent = BodyOuter;
	});

	Library:AddToRegistry(BodyInner, { BackgroundColor3 = 'BackgroundColor' });

	local ContainerOuter = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		Position = UDim2.new(0, 8, 0, 8);
		Size = UDim2.new(1, -16, 1, -16);
		ZIndex = 2;
		Visible = true;
		Parent = BodyInner;
	});

	local Container = Library:Create('Frame', {
		BackgroundTransparency = 1;
		Parent = ContainerOuter;
		Size = UDim2.fromScale(1, 1);
		Position = UDim2.fromOffset(2, 2);
	});

	Library:Create('UIListLayout', {
		Padding = UDim.new(0, 0);
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		HorizontalAlignment = Enum.HorizontalAlignment.Left;
		Parent = Container;
	});

	Library:AddToRegistry(ContainerOuter, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'OutlineColor';
	});

	Popout.Holder = Outer;
	Popout.Container = Container;
	Popout.ScreenGui = PopoutGui;

	function Popout:Resize()
		local Height = 0;

		for _, Element in next, Container:GetChildren() do
			if (not Element:IsA('UIListLayout')) and Element.Visible then
				Height = Height + Element.AbsoluteSize.Y;
			end;
		end;

		Outer.Size = UDim2.fromOffset(
			Config.Size.X,
			16 + Height + (Container.AbsolutePosition.Y - Outer.AbsolutePosition.Y)
		);
	end;

	function Popout:Toggle()
		Outer.Visible = not Outer.Visible;
	end;

	function Popout:SetVisible(Bool)
		Outer.Visible = Bool;
	end;

	function Popout:GetSize()
		return Container.AbsoluteSize;
	end;

	function Popout:Remove()
		PopoutGui:Destroy();
		table.clear(Popout);
	end;

	Container:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
		task.wait();
		Popout:Resize();
	end);

	Popout:Resize();

	setmetatable(Popout, BaseGroupbox);

	return Popout;
end

function Library:SetWatermarkVisibility(Bool)
	Library.Watermark.Visible = Bool;
end;

function Library:SetWatermark(Text)
	local X, Y = Library:GetTextBounds(Text, Library.Font, 14);
	Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);
	Library:SetWatermarkVisibility(true)

	Library.WatermarkText.Text = Text;
end;

-- Where the accent bar sits for each NotificationStyle.BarSide value.
local NotificationBarPosition = {
	Top    = UDim2.new(0, -1, 0, 0);
	Left   = UDim2.new(0, -1, 0, -1);
	Right  = UDim2.new(1, -2, 0, -1);
	Bottom = UDim2.new(0, -1, 1, -2);
};

local NotificationBarSize = {
	Top    = UDim2.new(1, 3, 0, 2);
	Left   = UDim2.new(0, 3, 1, 2);
	Right  = UDim2.new(0, 3, 1, 2);
	Bottom = UDim2.new(1, 3, 0, 2);
};

-- Resolves the four colours a notification is drawn with. NotificationStyle
-- .OverrideColor lets a consumer theme notifications apart from the menu.
local function GetNotificationColors()
	local Override = Library.NotificationStyle.OverrideColor;

	if Override then
		return Override();
	end;

	return Library.MainColor, Library.AccentColor, Library.OutlineColor, Library.FontColor;
end

-- The fork builds one hidden template at load and clones it per notification.
-- Nothing here is added to the colour registry: a notification keeps whatever
-- GetNotificationColors handed it, so an OverrideColor palette is not stomped
-- by the next theme update.
local NotificationTemplate = (function()
	local Outer = Library:Create('Frame', {
		BorderColor3 = Color3.new(0, 0, 0);
		Position = UDim2.new(0, 100, 0, 10);
		ClipsDescendants = true;
		ZIndex = 100;
	});

	local Inner = Library:Create('Frame', {
		Name = 'inner';
		BorderMode = Enum.BorderMode.Inset;
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 101;
		Parent = Outer;
	});

	local Body = Library:Create('Frame', {
		Name = 'inner';
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderSizePixel = 0;
		Position = UDim2.new(0, 1, 0, 1);
		Size = UDim2.new(1, -2, 1, -2);
		ZIndex = 102;
		Parent = Inner;
	});

	Library:Create('UIGradient', {
		Rotation = -90;
		Parent = Body;
	});

	Library:CreateLabel({
		Name = 'label';
		Position = UDim2.new(0, 4, 0, 0);
		Size = UDim2.new(1, -4, 1, 0);
		TextXAlignment = Enum.TextXAlignment.Left;
		TextSize = 14;
		ZIndex = 103;
		Parent = Body;
	});

	Library:Create('Frame', {
		Name = 'bar';
		BorderSizePixel = 0;
		ZIndex = 104;
		Parent = Outer;
	});

	return Outer;
end)();

function Library:Notify(Text, Time)
	local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);

	YSize = YSize + 7

	local Style = Library.NotificationStyle;
	local Transparency = Style.Transparency or 0;
	local MainColor, AccentColor, OutlineColor, FontColor = GetNotificationColors();

	local NotifyOuter = NotificationTemplate:Clone();

	NotifyOuter.BackgroundColor3 = MainColor;
	NotifyOuter.BackgroundTransparency = Transparency;
	NotifyOuter.Size = UDim2.new(0, 0, 0, YSize);

	-- Randomised name, as in the fork; nothing depends on it.
	NotifyOuter.Name = string.char(256 - math.random(1, math.max(#Text % 256, 1)));

	local NotifyInner = NotifyOuter.inner;
	NotifyInner.BackgroundColor3 = MainColor;
	NotifyInner.BorderColor3 = OutlineColor;
	NotifyInner.BackgroundTransparency = Transparency;

	local Body = NotifyInner.inner;
	Body.BackgroundTransparency = Transparency;

	Body.UIGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Library:GetDarkerColor(MainColor));
		ColorSequenceKeypoint.new(1, MainColor);
	});

	local Label = Body.label;
	Label.Text = Text;
	Label.TextColor3 = FontColor;

	local BarSide = Style.BarSide or 'Left';

	local Bar = NotifyOuter.bar;
	Bar.BackgroundColor3 = AccentColor;
	Bar.Size = NotificationBarSize[BarSide] or UDim2.new(0, 3, 1, 2);
	Bar.Position = NotificationBarPosition[BarSide] or NotificationBarPosition.Left;

	NotifyOuter.Parent = Library.NotificationArea;

	pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), 'Out', 'Quad', 0.4, true);

	task.spawn(function()
		wait(Time or 5);

		pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true);

		wait(0.4);

		NotifyOuter:Destroy();
	end);
end;

function Library:CreateWindow(...)
	local Arguments = { ... }
	local Config = { AnchorPoint = Vector2.zero }

	if type(...) == 'table' then
		Config = ...;
	else
		Config.Title = Arguments[1]
		Config.AutoShow = Arguments[2] or false;
	end

	if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
	if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 8 end -- fork spaces tab buttons 8px apart
	if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end

	if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
	if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 650) end

	if Config.Center then
		-- ueleak centres via a top-left anchor and a half-size scale offset, so
		-- the bottom-right resize grip only moves the right/bottom edges.
		Config.AnchorPoint = Vector2.zero
		Config.Position = UDim2.new(0.5, -Config.Size.X.Offset / 2, 0.5, -Config.Size.Y.Offset / 2)
	end

	local Window = {
		Tabs = {};
	};

	local Outer = Library:Create('Frame', {
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor3 = Color3.new(0, 0, 0);
		BorderSizePixel = 0;
		Position = Config.Position,
		Size = Config.Size,
		Visible = false;
		ZIndex = 1;
		Parent = ScreenGui;
	});

	Library.MainFrame = Outer;

	-- The fork drags an outline rather than the live window, and adds a
	-- bottom-right resize grip.
	if Config.NoOutlineDrag then
		Library:MakeDraggable(Outer, 25, true);
	else
		Library:MakeDraggableOutline(Outer, 25, true);
	end;

	if Config.Resizable ~= false then
		Library:MakeResizable(Outer, Config.MinSize);
	end;

	-- ueleak's inner frame is offset only on X and keeps the full Outer size, so
	-- its inset border lands flush with the Outer edge on the right/bottom and
	-- the resize grip does not poke past the outline.
	local Inner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.OutlineColor;
		BorderMode = Enum.BorderMode.Inset;
		Position = UDim2.new(0, 1, 0, 0);
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 1;
		Parent = Outer;
	});

	Library:AddToRegistry(Inner, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	});

	local WindowLabel = Library:CreateLabel({
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(1, 0, 0, 25);
		Text = Config.Title or '';
		TextSize = 18; -- fork uses 18 for the window title (upstream/default is 16)
		TextXAlignment = Enum.TextXAlignment.Center;
		ZIndex = 1;
		Parent = Inner;
	});

	-- Optional title-bar icon (top-right). Config.Icon = asset id, getcustomasset path, or URL.
	if Config.Icon then
		local IconImage = Library:Create('ImageLabel', {
			BackgroundTransparency = 1;
			Image = tostring(Config.Icon);
			Size = UDim2.fromOffset(20, 20);
			Position = UDim2.new(1, -28, 0, 2.5);
			ZIndex = 2;
			Parent = Inner;
		});
		Window.TitleIcon = IconImage;
	end;

	-- The fork draws the version in the accent colour with a text stroke (same
	-- treatment as CreatePopout), not the white FontColor that CreateLabel gives.
	local VersionLabel = Library:Create('TextLabel', {
		BackgroundTransparency = 1;
		Font = Library.Font;
		TextColor3 = Library.AccentColor;
		TextSize = 16;
		TextStrokeTransparency = 0;
		Position = UDim2.new(0, -8, 0, 0);
		Size = UDim2.new(1, Config.Icon and -32 or 0, 0, 25);
		Text = Config.Version or '';
		RichText = true;
		TextXAlignment = Enum.TextXAlignment.Right;
		ZIndex = 1;
		Parent = Inner;
	});

	Library:AddToRegistry(VersionLabel, {
		TextColor3 = 'AccentColor';
	});

	local MainSectionOuter = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		Position = UDim2.new(0, 8, 0, 25);
		Size = UDim2.new(1, -16, 1, -33);
		ZIndex = 1;
		Parent = Inner;
	});

	Library:AddToRegistry(MainSectionOuter, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'OutlineColor';
	});

	local MainSectionInner = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Color3.new(0, 0, 0);
		BorderMode = Enum.BorderMode.Inset;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 1;
		Parent = MainSectionOuter;
	});

	Library:AddToRegistry(MainSectionInner, {
		BackgroundColor3 = 'BackgroundColor';
	});

	-- The fork's tab strip is a horizontally scrolling frame (hidden scrollbar,
	-- auto canvas) so a hub with many tabs scrolls instead of overflowing. The
	-- 1px border boxes the strip like ueleak.
	local TabArea = Library:Create('ScrollingFrame', {
		BackgroundTransparency = 1;
		BorderColor3 = Library.OutlineColor;
		BorderSizePixel = 1;
		Position = UDim2.new(0, 0, 0, 4);
		Size = UDim2.new(1, -10, 0, 29);
		CanvasSize = UDim2.new();
		AutomaticCanvasSize = Enum.AutomaticSize.XY;
		ScrollBarThickness = 0;
		ScrollingDirection = Enum.ScrollingDirection.X;
		ZIndex = 1;
		Parent = MainSectionInner;
	});

	Library:AddToRegistry(TabArea, {
		BorderColor3 = 'OutlineColor';
	});

	-- ueleak insets the tabs with a 0-size leading/trailing spacer frame + the
	-- list's 8px inter-item padding; the equivalent here is 8px side padding,
	-- which lines the first tab up with the content column below.
	Library:Create('UIPadding', {
		PaddingTop = UDim.new(0, 1);
		PaddingLeft = UDim.new(0, 8);
		PaddingRight = UDim.new(0, 8);
		Parent = TabArea;
	});

	local TabListLayout = Library:Create('UIListLayout', {
		Padding = UDim.new(0, Config.TabPadding);
		FillDirection = Enum.FillDirection.Horizontal;
		VerticalAlignment = Enum.VerticalAlignment.Center;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = TabArea;
	});

	-- ueleak's content box is an outer 2px OutlineColor frame with a 1px black
	-- inner frame over it; the per-tab TabFrames live in the inner one.
	local TabContainer = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.OutlineColor;
		BorderSizePixel = 2;
		Position = UDim2.new(0, 8, 0, 38);
		Size = UDim2.new(1, -16, 1, -47);
		ZIndex = 1;
		Parent = MainSectionInner;
	});

	Library:AddToRegistry(TabContainer, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	});

	local TabContainerInner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Color3.new(0, 0, 0);
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 2;
		Parent = TabContainer;
	});

	Library:AddToRegistry(TabContainerInner, {
		BackgroundColor3 = 'MainColor';
	});

	function Window:SetWindowTitle(Title)
		WindowLabel.Text = Title;
	end;

	function Window:AddTab(Name)
		-- Reuse an existing tab with the same name (lets the theme/config
		-- managers share a single 'settings' tab instead of each making one).
		if Window.Tabs[Name] then
			return Window.Tabs[Name];
		end;

		local Tab = {
			Groupboxes = {};
			Tabboxes = {};
		};

		local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16);

		-- ueleak tab button: 0.75 of the strip height (sits up with a gap below),
		-- 2px OutlineColor border, a full-cover frame carrying a 1px black stroke,
		-- and the accent line. Active = accent shown + MainColor fill + white
		-- label; inactive = accent hidden + BackgroundColor fill + dimmed label.
		local TabButton = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderSizePixel = 2;
			Size = UDim2.new(0, TabButtonWidth + 8 + 4, 0.75, 0);
			ZIndex = 1;
			Parent = TabArea;
		});

		Library:AddToRegistry(TabButton, {
			BackgroundColor3 = 'BackgroundColor';
			BorderColor3 = 'OutlineColor';
		});

		local TabButtonBorder = Library:Create('Frame', {
			BackgroundTransparency = 1;
			BorderColor3 = Library.OutlineColor;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 2;
			Parent = TabButton;
		});

		Library:Create('UIStroke', {
			Color = Color3.new(0, 0, 0);
			Parent = TabButtonBorder;
		});

		Library:AddToRegistry(TabButtonBorder, {
			BorderColor3 = 'OutlineColor';
		});

		-- Accent line along the top edge of the active tab.
		local TabAccent = Library:Create('Frame', {
			BackgroundColor3 = Library.AccentColor;
			BorderSizePixel = 0;
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 0, 1);
			Visible = false;
			ZIndex = 104;
			Parent = TabButton;
		});

		Library:AddToRegistry(TabAccent, {
			BackgroundColor3 = 'AccentColor';
		});

		local TabButtonLabel = Library:CreateLabel({
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 1, -1);
			Text = Name;
			TextXAlignment = Enum.TextXAlignment.Center;
			ZIndex = 1;
			Parent = TabButton;
		});

		local TabFrame = Library:Create('Frame', {
			Name = 'TabFrame',
			BackgroundTransparency = 1;
			BorderColor3 = Library.OutlineColor;
			BorderSizePixel = 1;
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 1, 0);
			Visible = false;
			ZIndex = 2;
			Parent = TabContainerInner;
		});

		Library:AddToRegistry(TabFrame, {
			BorderColor3 = 'OutlineColor';
		});

		-- Optional banner above both columns, e.g. "this game patched X".
		-- Hidden until Tab:UpdateWarningBox({ Visible = true, ... }).
		local WarningBox = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Position = UDim2.new(0, 7, 0, 7);
			Size = UDim2.new(1, -10, 0, 10);
			Visible = false;
			ZIndex = 3;
			Parent = TabFrame;
		});

		Library:AddToRegistry(WarningBox, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		local WarningBoxContainer = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 2, 0, 2);
			Size = UDim2.new(1, -4, 1, -4);
			ZIndex = 3;
			Parent = WarningBox;
		});

		Library:Create('UIListLayout', {
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = WarningBoxContainer;
		});

		local WarningBoxTitle = Library:CreateLabel({
			Size = UDim2.new(1, -4, 0, 18);
			TextSize = 14;
			Text = '';
			TextXAlignment = Enum.TextXAlignment.Center;
			ZIndex = 4;
			Parent = WarningBoxContainer;
		});

		local WarningBoxText = Library:CreateLabel({
			Size = UDim2.new(1, -4, 0, 15);
			TextSize = 14;
			Text = '';
			TextWrapped = true;
			RichText = true;
			TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 4;
			Parent = WarningBoxContainer;
		});

		local LeftSide = Library:Create('ScrollingFrame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
			Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2);
			CanvasSize = UDim2.new(0, 0, 0, 0);
			BottomImage = '';
			TopImage = '';
			ScrollBarThickness = 0;
			ZIndex = 2;
			Parent = TabFrame;
		});

		local RightSide = Library:Create('ScrollingFrame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
			Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2);
			CanvasSize = UDim2.new(0, 0, 0, 0);
			BottomImage = '';
			TopImage = '';
			ScrollBarThickness = 0;
			ZIndex = 2;
			Parent = TabFrame;
		});

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 8);
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
			Parent = LeftSide;
		});

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 8);
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
			Parent = RightSide;
		});

		for _, Side in next, { LeftSide, RightSide } do
			Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
				Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y);
			end);
		end;

		if Library.IsMobile then
			-- Scrolling a column with a finger must not also drag the window.
			-- CanDrag is released again shortly after scrolling settles.
			local LastScroll = { Left = tick(), Right = tick() };

			local function GuardScroll(Key)
				return function()
					Library.CanDrag = false;

					local Stamp = tick();
					LastScroll[Key] = Stamp;

					task.wait(0.15);

					if LastScroll[Key] == Stamp then
						Library.CanDrag = true;
					end;
				end;
			end;

			LeftSide:GetPropertyChangedSignal('CanvasPosition'):Connect(GuardScroll('Left'));
			RightSide:GetPropertyChangedSignal('CanvasPosition'):Connect(GuardScroll('Right'));
		end;

		-- Lays the two columns out beneath the warning box, if it is showing.
		function Tab:Resize()
			if WarningBox.Visible == true then
				local Height = 10;

				for _, Element in next, WarningBoxContainer:GetChildren() do
					if (not Element:IsA('UIListLayout')) and Element.Visible then
						Height = Height + Element.Size.Y.Offset;
					end;
				end;

				WarningBox.Size = UDim2.new(1, -10, 0, Height);

				Height = Height + 10;

				LeftSide.Position = UDim2.new(0, 7, 0, 7 + Height);
				LeftSide.Size = UDim2.new(0.5, -10, 1, -14 - Height);
				RightSide.Position = UDim2.new(0.5, 5, 0, 7 + Height);
				RightSide.Size = UDim2.new(0.5, -10, 1, -14 - Height);
			else
				LeftSide.Position = UDim2.new(0, 7, 0, 7);
				LeftSide.Size = UDim2.new(0.5, -10, 1, -14);
				RightSide.Position = UDim2.new(0.5, 5, 0, 7);
				RightSide.Size = UDim2.new(0.5, -10, 1, -14);
			end;
		end;

		-- Info: { Visible = bool, Title = string, Text = string }
		function Tab:UpdateWarningBox(Info)
			if typeof(Info.Visible) == 'boolean' then
				WarningBox.Visible = Info.Visible;
				Tab:Resize();
			end;

			if typeof(Info.Title) == 'string' then
				WarningBoxTitle.Text = Info.Title;
			end;

			if typeof(Info.Text) == 'string' then
				WarningBoxText.Text = Info.Text;

				local Y = select(2, Library:GetTextBounds(
					Info.Text, Library.Font, 14,
					Vector2.new(WarningBoxContainer.AbsoluteSize.X, math.huge)
				));

				WarningBoxText.Size = UDim2.new(1, -4, 0, Y);
				Tab:Resize();
			end;
		end;

		function Tab:GetSides()
			return { Left = LeftSide; Right = RightSide; };
		end;

		WarningBox:GetPropertyChangedSignal('Visible'):Connect(function()
			Tab:Resize();
		end);

		Tab:Resize();

		function Tab:ShowTab()
			for _, Tab in next, Window.Tabs do
				Tab:HideTab();
			end;

			TabButton.BackgroundColor3 = Library.MainColor;
			Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
			TabButtonLabel.TextColor3 = Library.FontColor;
			TabAccent.Visible = true;
			TabFrame.Visible = true;

			Library.ActiveTab = Name;

			Tab:Resize();
		end;

		function Tab:HideTab()
			TabButton.BackgroundColor3 = Library.BackgroundColor;
			Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
			TabButtonLabel.TextColor3 = Library:GetDarkerColor(Library.FontColor);
			TabAccent.Visible = false;
			TabFrame.Visible = false;
		end;

		function Tab:SetLayoutOrder(Position)
			TabButton.LayoutOrder = Position;
			TabListLayout:ApplyLayout();
		end;

		function Tab:Remove()
			Window.Tabs[Name] = nil;
			Library.TotalTabs = math.max(Library.TotalTabs - 1, 0);

			table.clear(Tab);

			TabFrame:Destroy();
			TabButton:Destroy();
		end;

		function Tab:AddGroupbox(Info)
			local Groupbox = {};

			local BoxOuter = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Library.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 0, 507 + 2);
				ZIndex = 2;
				Parent = Info.Side == 1 and LeftSide or RightSide;
			});

			Library:AddToRegistry(BoxOuter, {
				BackgroundColor3 = 'BackgroundColor';
				BorderColor3 = 'OutlineColor';
			});

			local BoxInner = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Color3.new(0, 0, 0);
				-- BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, -2, 1, -2);
				Position = UDim2.new(0, 1, 0, 1);
				ZIndex = 4;
				Parent = BoxOuter;
			});

			Library:AddToRegistry(BoxInner, {
				BackgroundColor3 = 'BackgroundColor';
			});

			local Highlight = Library:Create('Frame', {
				BackgroundColor3 = Library.AccentColor;
				BorderSizePixel = 0;
				Size = UDim2.new(1, 0, 0, 2);
				ZIndex = 5;
				Parent = BoxInner;
			});

			Library:AddToRegistry(Highlight, {
				BackgroundColor3 = 'AccentColor';
			});

			local GroupboxLabel = Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 18);
				Position = UDim2.new(0, 4, 0, 2);
				TextSize = 14;
				Text = Info.Name;
				TextXAlignment = Enum.TextXAlignment.Center;
				ZIndex = 5;
				Parent = BoxInner;
			});

			local Container = Library:Create('Frame', {
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 4, 0, 20);
				Size = UDim2.new(1, -4, 1, -20);
				ZIndex = 1;
				Parent = BoxInner;
			});

			Library:Create('UIListLayout', {
				FillDirection = Enum.FillDirection.Vertical;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Parent = Container;
			});

			function Groupbox:Resize()
				local Size = 0;

				for _, Element in next, Groupbox.Container:GetChildren() do
					if (not Element:IsA('UIListLayout')) and Element.Visible then
						Size = Size + Element.Size.Y.Offset;
					end;
				end;

				BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
			end;

			local Groupboxes = Tab.Groupboxes;
			function Groupbox:Remove()
				table.clear(self);
				BoxOuter:Destroy();
				Groupboxes[Info.Name] = nil;
			end;

			Groupbox.Container = Container;
			setmetatable(Groupbox, BaseGroupbox);

			Groupbox:AddBlank(3);
			Groupbox:Resize();

			Groupboxes[Info.Name] = Groupbox;

			return Groupbox;
		end;

		function Tab:AddLeftGroupbox(Name)
			return self:AddGroupbox({ Side = 1; Name = Name; });
		end;

		function Tab:AddRightGroupbox(Name)
			return self:AddGroupbox({ Side = 2; Name = Name; });
		end;

		function Tab:AddTabbox(Info)
			local Tabbox = {
				Tabs = {};
			};

			local BoxOuter = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Library.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 0, 0);
				ZIndex = 2;
				Parent = Info.Side == 1 and LeftSide or RightSide;
			});

			Library:AddToRegistry(BoxOuter, {
				BackgroundColor3 = 'BackgroundColor';
				BorderColor3 = 'OutlineColor';
			});

			local BoxInner = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Color3.new(0, 0, 0);
				-- BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, -2, 1, -2);
				Position = UDim2.new(0, 1, 0, 1);
				ZIndex = 4;
				Parent = BoxOuter;
			});

			Library:AddToRegistry(BoxInner, {
				BackgroundColor3 = 'BackgroundColor';
			});

			-- ueleak's tabbox has no accent bar; the button row itself carries a
			-- 1px OutlineColor border.
			local TabboxButtons = Library:Create('Frame', {
				BackgroundTransparency = 1;
				BorderColor3 = Library.OutlineColor;
				BorderSizePixel = 1;
				Position = UDim2.new(0, 0, 0, 0);
				Size = UDim2.new(1, 0, 0, 18);
				ZIndex = 5;
				Parent = BoxInner;
			});

			Library:AddToRegistry(TabboxButtons, {
				BorderColor3 = 'OutlineColor';
			});

			Library:Create('UIListLayout', {
				FillDirection = Enum.FillDirection.Horizontal;
				HorizontalAlignment = Enum.HorizontalAlignment.Left;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Parent = TabboxButtons;
			});

			local Tabboxes = Tab.Tabboxes;
			function Tabbox:Remove()
				BoxOuter:Destroy();
				table.clear(Tabbox);
				Tabboxes[Info.Name or ''] = nil;
			end;

			function Tabbox:AddTab(Name)
				local Tab = {};

				local Button = Library:Create('Frame', {
					BackgroundColor3 = Library.MainColor;
					BorderColor3 = Color3.new(0, 0, 0);
					Size = UDim2.new(0.5, 0, 1, 0);
					ZIndex = 6;
					Parent = TabboxButtons;
				});

				Library:AddToRegistry(Button, {
					BackgroundColor3 = 'MainColor';
				});

				local ButtonLabel = Library:CreateLabel({
					Size = UDim2.new(1, 0, 1, 0);
					TextSize = 14;
					Text = Name;
					TextXAlignment = Enum.TextXAlignment.Center;
					ZIndex = 7;
					Parent = Button;
				});

				-- 1px accent line along the top of the selected tab, same as the
				-- window tabs.
				local TabAccent = Library:Create('Frame', {
					BackgroundColor3 = Library.AccentColor;
					BorderSizePixel = 0;
					Position = UDim2.new(0, 0, 0, 0);
					Size = UDim2.new(1, 0, 0, 1);
					Visible = false;
					ZIndex = 10;
					Parent = Button;
				});

				Library:AddToRegistry(TabAccent, {
					BackgroundColor3 = 'AccentColor';
				});

				local Block = Library:Create('Frame', {
					BackgroundColor3 = Library.BackgroundColor;
					BorderSizePixel = 0;
					Position = UDim2.new(0, 0, 1, 0);
					Size = UDim2.new(1, 0, 0, 1);
					Visible = false;
					ZIndex = 9;
					Parent = Button;
				});

				Library:AddToRegistry(Block, {
					BackgroundColor3 = 'BackgroundColor';
				});

				local Container = Library:Create('Frame', {
					BackgroundTransparency = 1;
					BorderColor3 = Library.OutlineColor;
					BorderSizePixel = 1;
					Position = UDim2.new(0, 4, 0, 20);
					Size = UDim2.new(1, -4, 1, -20);
					ZIndex = 1;
					Visible = false;
					Parent = BoxInner;
				});

				Library:AddToRegistry(Container, {
					BorderColor3 = 'OutlineColor';
				});

				Library:Create('UIListLayout', {
					FillDirection = Enum.FillDirection.Vertical;
					SortOrder = Enum.SortOrder.LayoutOrder;
					Parent = Container;
				});

				function Tab:Show()
					for _, Tab in next, Tabbox.Tabs do
						Tab:Hide();
					end;

					Container.Visible = true;
					Block.Visible = true;
					TabAccent.Visible = true;

					Button.BackgroundColor3 = Library.BackgroundColor;
					Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

					Tab:Resize();
				end;

				function Tab:Hide()
					Container.Visible = false;
					Block.Visible = false;
					TabAccent.Visible = false;

					Button.BackgroundColor3 = Library.MainColor;
					Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
				end;

				function Tab:Resize()
					local TabCount = 0;

					for _, Tab in next, Tabbox.Tabs do
						TabCount = TabCount + 1;
					end;

					for _, Button in next, TabboxButtons:GetChildren() do
						if not Button:IsA('UIListLayout') then
							Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
						end;
					end;

					if (not Container.Visible) then
						return;
					end;

					local Size = 0;

					for _, Element in next, Tab.Container:GetChildren() do
						if (not Element:IsA('UIListLayout')) and Element.Visible then
							Size = Size + Element.Size.Y.Offset;
						end;
					end;

					BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
				end;

				Button.InputBegan:Connect(function(Input)
					if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame())
						or Input.UserInputType == Enum.UserInputType.Touch then
						Tab:Show();
						Tab:Resize();
					end;
				end);

				Tab.Container = Container;
				Tabbox.Tabs[Name] = Tab;

				setmetatable(Tab, BaseGroupbox);

				Tab:AddBlank(3);
				Tab:Resize();

				-- Show first tab (number is 2 cus of the UIListLayout that also sits in that instance)
				if #TabboxButtons:GetChildren() == 2 then
					Tab:Show();
				end;

				return Tab;
			end;

			Tabboxes[Info.Name or ''] = Tabbox;

			return Tabbox;
		end;

		function Tab:AddLeftTabbox(Name)
			return self:AddTabbox({ Name = Name, Side = 1; });
		end;

		function Tab:AddRightTabbox(Name)
			return self:AddTabbox({ Name = Name, Side = 2; });
		end;

		function Tab:Remove()
			table.clear(Tab);
			TabFrame:Destroy();
			TabButton:Destroy();
			Window.Tabs[Name] = nil;
		end;

		TabButton.InputBegan:Connect(function(Input)
			if Library.IsDragging then
				return;
			end;

			if (Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame())
				or Input.UserInputType == Enum.UserInputType.Touch then

				Tab:ShowTab();
			end;
		end);

		Library.TotalTabs = Library.TotalTabs + 1;

		-- The first tab added shows by default; the rest render in the hidden
		-- (inactive) state.
		if #TabContainerInner:GetChildren() == 1 then
			Tab:ShowTab();
		else
			Tab:HideTab();
		end;

		Window.Tabs[Name] = Tab;
		return Tab;
	end;

	local ModalElement = Library:Create('TextButton', {
		BackgroundTransparency = 1;
		Size = UDim2.new(0, 0, 0, 0);
		Visible = true;
		Text = '';
		Modal = false;
		Parent = Library:Create("ScreenGui", {
			Parent = CoreGui;
		});
	});

	local TransparencyCache = {};
	local Toggled = false;
	local Fading = false;

	function Library:Toggle()
		if Fading then
			return;
		end;

		local FadeTime = Config.MenuFadeTime;
		Fading = true;
		Toggled = (not Toggled);

		Library.Visible = Toggled;
		Library:FireEvent('VisibilityChanged', Toggled);

		ModalElement.Modal = Toggled;

		-- Background blur + dim, faded with the menu.
		if Library.BackgroundBlur then
			if Toggled then
				MenuBlur.Enabled = true;
				MenuDim.Visible = true;
			end;

			TweenService:Create(MenuBlur, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), {
				Size = Toggled and Library.BlurSize or 0;
			}):Play();

			TweenService:Create(MenuDim, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), {
				BackgroundTransparency = Toggled and Library.DimTransparency or 1;
			}):Play();
		end;

		-- Anything floating (dropdown lists, mode pickers, colour pickers) is
		-- parented to the ScreenGui rather than the window, so it would survive
		-- the fade and hang around on screen. Close it all explicitly.
		for _, Element in next, Options do
			task.spawn(function()
				if Element.Type == 'Dropdown' then
					Element:CloseDropdown();
				elseif Element.Type == 'KeyPicker' then
					Element:SetModePickerVisibility(false);
				elseif Element.Type == 'ColorPicker' then
					Element:Hide();
				end;
			end);
		end;

		-- BlockInput sinks the default player actions (movement, jump, ...) so
		-- typing into the menu does not also drive the character.
		if Toggled and Library.BlockInput then
			ContextActionService:BindAction(
				'Freeze',
				function()
					return Enum.ContextActionResult.Sink;
				end,
				false,
				table.unpack(Enum.PlayerActions:GetEnumItems())
			);
		else
			ContextActionService:UnbindAction('Freeze');
		end;

		if Toggled then
			-- A bit scuffed, but if we're going from not toggled -> toggled we want to show the frame immediately so that the fade is visible.
			Outer.Visible = true;
			local guiservice = game:GetService("GuiService");
			task.spawn(function()
				-- TODO: add cursor fade?
				local State = InputService.MouseIconEnabled;
				--local Cursor = Drawing.new('Triangle');
				--Cursor.Thickness = 1;
				--Cursor.Filled = true;
				--Cursor.Visible = true;

				--local CursorOutline = Drawing.new('Triangle');
				--CursorOutline.Thickness = 1;
				--CursorOutline.Filled = false;
				--CursorOutline.Color = Color3.new(0, 0, 0);
				--CursorOutline.Visible = true;

				local Cursor = Instance.new("ImageLabel", CursorGui);
				Cursor.Image = "http://www.roblox.com/asset/?id=4292970642";
				Cursor.BackgroundTransparency = 1;
				Cursor.ZIndex = 100;

				local CursorOutline = Instance.new("ImageLabel", CursorGui);
				CursorOutline.Image = "http://www.roblox.com/asset/?id=4292970642";
				CursorOutline.ImageColor3 = Color3.new();
				CursorOutline.BackgroundTransparency = 1;
				CursorOutline.ZIndex = 99;

				Cursor.Size, CursorOutline.Size = UDim2.fromOffset(17, 17),  UDim2.fromOffset(19, 19);
				Cursor.Rotation, CursorOutline.Rotation = -45, -45;
				while Toggled and ScreenGui.Parent do
					InputService.MouseIconEnabled = false;

					local mPos = InputService:GetMouseLocation();
					local udim = UDim2.fromOffset(mPos.X, mPos.Y - guiservice:GetGuiInset().Y - 1);

					Cursor.ImageColor3 = Library.AccentColor;
					Cursor.Position, CursorOutline.Position = udim, udim - UDim2.fromOffset(1, 1);

					--Cursor.PointA = Vector2.new(mPos.X, mPos.Y);
					--Cursor.PointB = Vector2.new(mPos.X + 16, mPos.Y + 6);
					--Cursor.PointC = Vector2.new(mPos.X + 6, mPos.Y + 16);

					--CursorOutline.PointA = Cursor.PointA;
					--CursorOutline.PointB = Cursor.PointB;
					--CursorOutline.PointC = Cursor.PointC;

					RenderStepped:Wait();
				end;

				InputService.MouseIconEnabled = State;

				Cursor:Destroy();
				CursorOutline:Destroy();
			end);
		end;

		for _, Desc in next, Outer:GetDescendants() do
			local Properties = {};

			if Desc:IsA('ImageLabel') then
				table.insert(Properties, 'ImageTransparency');
				table.insert(Properties, 'BackgroundTransparency');
			elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
				table.insert(Properties, 'TextTransparency');
			elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
				table.insert(Properties, 'BackgroundTransparency');
			elseif Desc:IsA('UIStroke') then
				table.insert(Properties, 'Transparency');
			end;

			local Cache = TransparencyCache[Desc];

			if (not Cache) then
				Cache = {};
				TransparencyCache[Desc] = Cache;
			end;

			for _, Prop in next, Properties do
				if not Cache[Prop] then
					Cache[Prop] = Desc[Prop];
				end;

				if Cache[Prop] == 1 then
					continue;
				end;

				TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), { [Prop] = Toggled and Cache[Prop] or 1 }):Play();
			end;
		end;

		task.wait(FadeTime);

		Outer.Visible = Toggled;

		if not Toggled then
			MenuBlur.Enabled = false;
			MenuDim.Visible = false;
		end;

		Fading = false;
	end

	function Library:SetVisible(Bool)
		if Bool ~= Toggled then
			Library:Toggle();
		end;
	end;

	Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
		if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
			if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
				task.spawn(Library.Toggle)
			end
		elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.Insert and (not Processed)) then
			task.spawn(Library.Toggle)
		end
	end))

	if Config.AutoShow then task.spawn(Library.Toggle) end

	Window.Holder = Outer;

	return Window;
end;

local function OnPlayerChange()
	local PlayerList = GetPlayersString();

	for _, Value in next, Options do
		if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
			Value:SetValues(PlayerList);
		end;
	end;
end;

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

getgenv().Library = Library
return Library