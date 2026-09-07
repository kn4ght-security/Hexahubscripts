

local HttpService = (cloneref or function(o) return o end)(game:GetService('HttpService'));

local ThemeManager = {};

do
	ThemeManager.Folder = '';
	ThemeManager.Library = nil;
	ThemeManager.DefaultTheme = 'Default';
	local function MakeTheme(FontColor, MainColor, AccentColor, BackgroundColor, OutlineColor, RiskColor)
		return { 1, {
			FontColor = FontColor;
			MainColor = MainColor;
			AccentColor = AccentColor;
			BackgroundColor = BackgroundColor;
			OutlineColor = OutlineColor;
			RiskColor = RiskColor;

			ItemType = 'Unnamed Enhancements';
			SwordColor = 'ffffff';
			SwordTransparency = '0';
			SwordReflectance = '0';
			SwordSpeed = '0.15';
			SwordMaterial = 'Neon';

			Contrast = '0';
			Saturation = '0';
			Brightness = '0';

			BackColor = '000000';
			BlurSize = '15';
			BackTransparency = '0.7';
		} };
	end;

	ThemeManager.BuiltInThemes = {
		['Default']      = MakeTheme('ffffff', '181818', '4777b6', '141414', '1f1f1f', 'e50000');
		['Tokyo Night']  = MakeTheme('ffffff', '191925', '6956cb', '15151e', '272727', 'fb5f5f');
		['Nord']         = MakeTheme('ffffff', '1c1e20', '9effc8', '1c1e20', '24282d', 'ff7a00');
		['Skeet']        = MakeTheme('ffffff', '131313', '81ff54', '151515', '2a2a2a', 'e50000');
		['Fatality']     = MakeTheme('ffffff', '181537', 'ca0756', '201c46', '39335a', 'e50000');
		['Neverlose']    = MakeTheme('ffffff', '0c1014', '01a3f1', '0c0f14', '191919', 'e50000');
		['Onetap']       = MakeTheme('ffffff', '1e1d22', 'faa614', '18181c', '313033', 'e50000');
		['Imgui']        = MakeTheme('ffffff', '151617', '406ba8', '151617', '242424', 'e50000');
		['Iniuria']      = MakeTheme('ffffff', '1e1d1e', 'c41275', '1e1d1e', '33252b', 'e50000');
		['Primordial']   = MakeTheme('ffffff', '181818', 'd7a6b0', '1f1f1f', '2a2a2a', 'e50000');
		['Monolith']     = MakeTheme('ffffff', '141115', 'c707bd', '171417', '272427', 'e50000');
		['V3rmillion']   = MakeTheme('ffffff', '202020', 'cd1818', '202020', '2a2a2a', 'e50000');
		['Dark']         = MakeTheme('ffffff', '0a0a0a', '5945ff', '0a0a0a', '171717', 'e50000');
	};

	ThemeManager.ThemeKeys = {
		'Contrast', 'Saturation', 'Brightness', 'BlurSize',
		'FontColor', 'RiskColor', 'MainColor', 'AccentColor',
		'BackgroundColor', 'OutlineColor',
		'SwordColor', 'ItemType',
		'BackTransparency', 'BackColor',
		'SwordTransparency', 'SwordReflectance', 'SwordMaterial', 'SwordSpeed',
	};

	function ThemeManager:SetLibrary(Library)
		self.Library = Library;
	end;

	function ThemeManager:SetFolder(Folder)
		self.Folder = Folder;
		self:BuildFolderTree();
	end;

	function ThemeManager:BuildFolderTree()
		local Paths = {};
		local Parts = self.Folder:split('/');

		for Index = 1, #Parts do
			Paths[#Paths + 1] = table.concat(Parts, '/', 1, Index);
		end;

		table.insert(Paths, self.Folder .. '/themes');

		for Index = 1, #Paths do
			local Path = Paths[Index];

			if not isfolder(Path) then
				makefolder(Path);
			end;
		end;
	end;

	function ThemeManager:ApplyTheme(Name)
		if not Name then
			return;
		end;

		local Custom = self:GetCustomTheme(Name);
		local BuiltIn = self.BuiltInThemes[Name];

		if not (Custom or BuiltIn) then
			return;
		end;

		if self.Library.InnerVideoBackground ~= nil then
			self.Library.InnerVideoBackground.Visible = false;
		end;

		local Data = Custom or BuiltIn[2];

		for Key, Value in next, Data do
			if Key:find('Color') then
				self.Library[Key] = Color3.fromHex(Value);

				if Options[Key] then
					Options[Key]:SetValueRGB(Color3.fromHex(Value));
				end;
			else
				self.Library[Key] = Value;

				if Options[Key] then
					Options[Key]:SetValue(Value);
				end;
			end;
		end;

		self:ThemeUpdate();
	end;

	-- Pulls the current picker values back into the library and repaints.
	function ThemeManager:ThemeUpdate()
		if self.Library.InnerVideoBackground ~= nil then
			self.Library.InnerVideoBackground.Visible = false;
		end;

		for _, Key in next, self.ThemeKeys do
			if Options and Options[Key] then
				self.Library[Key] = Options[Key].Value;
			end;
		end;

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry();
	end;

	function ThemeManager:LoadDefault()
		local Name = 'Default';
		local Saved = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt');

		-- Built-in themes go through the dropdown (so it shows the right entry);
		-- custom ones are applied directly, since they are not in that list.
		local IsBuiltIn = true;

		if Saved then
			if self.BuiltInThemes[Saved] then
				Name = Saved;
			elseif self:GetCustomTheme(Saved) then
				Name = Saved;
				IsBuiltIn = false;
			end;
		elseif self.BuiltInThemes[self.DefaultTheme] then
			Name = self.DefaultTheme;
		end;

		if IsBuiltIn then
			Options.ThemeManager_ThemeList:SetValue(Name);
		else
			self:ApplyTheme(Name);
		end;
	end;

	function ThemeManager:SaveDefault(Name)
		writefile(self.Folder .. '/themes/default.txt', Name);
	end;

	function ThemeManager:GetCustomTheme(File)
		if not File then
			return;
		end;

		local Path = self.Folder .. '/themes/' .. File;

		if not isfile(Path) then
			return nil;
		end;

		local Success, Decoded = pcall(HttpService.JSONDecode, HttpService, readfile(Path));

		if not Success then
			return nil;
		end;

		return Decoded;
	end;

	function ThemeManager:SaveCustomTheme(File)
		if not File or File:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid file name for theme (empty)', 3);
		end;

		local Data = {};

		for _, Key in next, self.ThemeKeys do
			if Options[Key] then
				if not Key:find('Color') then
					Data[Key] = Options[Key].Value;
				else
					Data[Key] = Options[Key].Value:ToHex();
				end;
			end;
		end;

		writefile(self.Folder .. '/themes/' .. File, HttpService:JSONEncode(Data));
	end;

	function ThemeManager:Delete(File)
		if not File then
			return false, 'no config file is selected';
		end;

		local Path = self.Folder .. '/themes/' .. File;

		if not isfile(Path) then
			return false, 'invalid file';
		end;

		local Success = pcall(delfile, Path);

		if not Success then
			return false, 'delete file error';
		end;

		return true;
	end;

	function ThemeManager:ReloadCustomThemes()
		local Files = listfiles(self.Folder .. '/themes');
		local List = {};

		for Index = 1, #Files do
			local Path = Files[Index];

			if Path:sub(-5) == '.json' then
				-- Walk back to the last separator; unlike the config list the
				-- extension is kept, because that is the on-disk theme name.
				local Start = Path:find('.json', 1, true);
				local Char = Path:sub(Start, Start);

				while Char ~= '/' and Char ~= '\\' and Char ~= '' do
					Start = Start - 1;
					Char = Path:sub(Start, Start);
				end;

				if Char == '/' or Char == '\\' then
					table.insert(List, Path:sub(Start + 1));
				end;
			end;
		end;

		return List;
	end;

	function ThemeManager:CreateGroupBox(Tab)
		assert(self.Library, 'Must set ThemeManager.Library first!');
		return Tab:AddLeftTabbox();
	end;

	function ThemeManager:ApplyToTab(Tab)
		assert(self.Library, 'Must set ThemeManager.Library first!');
		self:CreateThemeManager(self:CreateGroupBox(Tab));
	end;

	-- Creates (or reuses) a dedicated lowercase 'settings' tab on the window and
	-- builds the theme manager there, so it never lands in the user's own tabs.
	function ThemeManager:ApplyToWindow(Window)
		assert(self.Library, 'Must set ThemeManager.Library first!');
		self:ApplyToTab(Window:AddTab('settings'));
	end;

	function ThemeManager:ApplyToGroupbox(Groupbox)
		assert(self.Library, 'Must set ThemeManager.Library first!');
		self:CreateThemeManager(Groupbox);
	end;

	-- Accepts either a groupbox or a tabbox. CreateGroupBox hands back a tabbox
	-- (that is what the fork does), and a tabbox holds tabs rather than
	-- elements, so open a tab on it first.
	function ThemeManager:CreateThemeManager(Container)
		local Groupbox = Container;

		if type(Container.AddTab) == 'function' and type(Container.AddLabel) ~= 'function' then
			Groupbox = Container:AddTab('Themes');
		end;

		Groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor });
		Groupbox:AddLabel('Main color')      :AddColorPicker('MainColor',       { Default = self.Library.MainColor });
		Groupbox:AddLabel('Accent color')    :AddColorPicker('AccentColor',     { Default = self.Library.AccentColor });
		Groupbox:AddLabel('Outline color')   :AddColorPicker('OutlineColor',    { Default = self.Library.OutlineColor });
		Groupbox:AddLabel('Font color')      :AddColorPicker('FontColor',       { Default = self.Library.FontColor });
		Groupbox:AddLabel('Risk color')      :AddColorPicker('RiskColor',       { Default = self.Library.RiskColor });

		local ThemesArray = {};

		for Name in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name);
		end;

		table.sort(ThemesArray, function(A, B)
			return self.BuiltInThemes[A][1] < self.BuiltInThemes[B][1];
		end);

		Groupbox:AddDivider();

		Groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 });

		Groupbox:AddButton('Set as default', function()
			self:SaveDefault(Options.ThemeManager_ThemeList.Value);
			self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_ThemeList.Value));
		end);

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value);
		end);

		Groupbox:AddDivider();

		Groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' });
		Groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 });

		Groupbox:AddButton('Create theme', function()
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value);

			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes());
			Options.ThemeManager_CustomThemeList:SetValue(nil);
		end):AddButton('Load theme', function()
			self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value);
		end);

		Groupbox:AddButton('Overwrite theme', function()
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeList.Value);
		end):AddButton('Delete theme', function()
			local Name = Options.ThemeManager_CustomThemeList.Value;
			local Success, Err = self:Delete(Name);

			if not Success then
				return self.Library:Notify('Failed to delete theme: ' .. Err);
			end;

			self.Library:Notify(string.format('Deleted theme %q', Name));

			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes());
			Options.ThemeManager_CustomThemeList:SetValue(nil);
		end);

		Groupbox:AddButton('Refresh list', function()
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes());
			Options.ThemeManager_CustomThemeList:SetValue(nil);
		end);

		Groupbox:AddButton('Set as default', function()
			if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= '' then
				self:SaveDefault(Options.ThemeManager_CustomThemeList.Value);
				self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_CustomThemeList.Value));
			end;
		end);

		-- Repaint whenever any of the six colour pickers moves.
		for _, Key in next, { 'BackgroundColor', 'MainColor', 'AccentColor', 'OutlineColor', 'FontColor', 'RiskColor' } do
			if Options[Key] then
				Options[Key]:OnChanged(function()
					self:ThemeUpdate();
				end);
			end;
		end;

		self:LoadDefault();
	end;
end;

getgenv().ThemeManager = ThemeManager;

return ThemeManager;
