
local HttpService = (cloneref or function(o) return o end)(game:GetService('HttpService'));

local SaveManager = {};

do
	SaveManager.Folder = '';
	SaveManager.Ignore = {};
	SaveManager.Library = nil;

	SaveManager.Parser = {
		Toggle = {
			Save = function(Idx, Object)
				return { type = 'Toggle', idx = Idx, value = Object.Value };
			end;
			Load = function(Idx, Data)
				if Toggles[Idx] then
					Toggles[Idx]:SetValue(Data.value);
				end;
			end;
		};
		Slider = {
			Save = function(Idx, Object)
				return { type = 'Slider', idx = Idx, value = tostring(Object.Value) };
			end;
			Load = function(Idx, Data)
				if Options[Idx] then
					Options[Idx]:SetValue(Data.value);
				end;
			end;
		};
		Dropdown = {
			Save = function(Idx, Object)
				return { type = 'Dropdown', idx = Idx, value = Object.Value, mutli = Object.Multi };
			end;
			Load = function(Idx, Data)
				if Options[Idx] then
					Options[Idx]:SetValue(Data.value);
				end;
			end;
		};
		ColorPicker = {
			Save = function(Idx, Object)
				return { type = 'ColorPicker', idx = Idx, value = Object.Value:ToHex(), transparency = Object.Transparency };
			end;
			Load = function(Idx, Data)
				if Options[Idx] then
					Options[Idx]:SetValueRGB(Color3.fromHex(Data.value), Data.transparency);
				end;
			end;
		};
		KeyPicker = {
			Save = function(Idx, Object)
				return { type = 'KeyPicker', idx = Idx, mode = Object.Mode, key = Object.Value };
			end;
			Load = function(Idx, Data)
				if Options[Idx] then
					Options[Idx]:SetValue({ Data.key, Data.mode });
				end;
			end;
		};
		Input = {
			Save = function(Idx, Object)
				return { type = 'Input', idx = Idx, text = Object.Value };
			end;
			Load = function(Idx, Data)
				if Options[Idx] and type(Data.text) == 'string' then
					Options[Idx]:SetValue(Data.text);
				end;
			end;
		};
	};

	function SaveManager:SetLibrary(Library)
		self.Library = Library;
	end;

	function SaveManager:SetFolder(Folder)
		self.Folder = Folder;
		self:BuildFolderTree();
	end;

	function SaveManager:BuildFolderTree()
		local Paths = {
			self.Folder,
			self.Folder .. '/settings',
			self.Folder .. '/themes',
		};

		for Index = 1, #Paths do
			local Path = Paths[Index];

			if not isfolder(Path) then
				makefolder(Path);
			end;
		end;
	end;

	function SaveManager:CheckFolderTree()
		if not isfolder(self.Folder) then
			self:BuildFolderTree();
			task.wait();
		end;
	end;

	function SaveManager:SetIgnoreIndexes(List)
		for _, Key in next, List do
			self.Ignore[Key] = true;
		end;
	end;

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({
			'ThemeManager_ThemeList',
			'ThemeManager_CustomThemeList',
			'ThemeManager_CustomThemeName',

			'VideoLink',
			'Brightness', 'Contrast', 'Saturation', 'BlurSize',

			'FontColor', 'RiskColor', 'MainColor', 'AccentColor',
			'BackgroundColor', 'OutlineColor',

			'ItemType',
			'SwordColor', 'SwordTransparency', 'SwordReflectance',
			'SwordMaterial', 'SwordSpeed',

			'BackColor', 'BackTransparency',
		});
	end;

	-- NoWrite: return the encoded config instead of writing it to disk.
	function SaveManager:Save(Name, NoWrite)
		if not Name then
			return false, 'no config file is selected';
		end;

		self:CheckFolderTree();

		local File = self.Folder .. '/settings/' .. Name .. '.json';
		local Data = { objects = {} };

		for Idx, Object in next, Toggles do
			if self.Ignore[Idx] then
				continue;
			end;

			table.insert(Data.objects, self.Parser[Object.Type].Save(Idx, Object));
		end;

		for Idx, Object in next, Options do
			if not self.Parser[Object.Type] then
				continue;
			end;

			if self.Ignore[Idx] then
				continue;
			end;

			table.insert(Data.objects, self.Parser[Object.Type].Save(Idx, Object));
		end;

		local Success, Encoded = pcall(HttpService.JSONEncode, HttpService, Data);

		if not Success then
			return false, 'failed to encode data';
		end;

		if not NoWrite then
			writefile(File, Encoded);
		end;

		return true, Encoded;
	end;

	-- Name may be a config name, or an already-decoded config table.
	function SaveManager:Load(Name)
		if not Name then
			return false, 'no config file is selected';
		end;

		if type(Name) == 'table' then
			for _, Object in next, Name.objects do
				if self.Parser[Object.type] then
					task.spawn(function()
						self.Parser[Object.type].Load(Object.idx, Object);
					end);
				end;
			end;

			return true;
		end;

		self:CheckFolderTree();

		local File = self.Folder .. '/settings/' .. Name .. '.json';

		if not isfile(File) then
			return false, 'invalid file';
		end;

		local Success, Decoded = pcall(HttpService.JSONDecode, HttpService, readfile(File));

		if not Success then
			return false, 'decode error';
		end;

		for _, Object in next, Decoded.objects do
			if self.Parser[Object.type] then
				task.spawn(function()
					self.Parser[Object.type].Load(Object.idx, Object);
				end);
			end;
		end;

		return true;
	end;

	function SaveManager:Delete(Name)
		if not Name then
			return false, 'no config file is selected';
		end;

		local File = self.Folder .. '/settings/' .. Name .. '.json';

		if not isfile(File) then
			return false, 'invalid file';
		end;

		local Success = pcall(delfile, File);

		if not Success then
			return false, 'delete file error';
		end;

		return true;
	end;

	function SaveManager:RefreshConfigList()
		local Files = listfiles(self.Folder .. '/settings');
		local List = {};

		for Index = 1, #Files do
			local Path = Files[Index];

			if Path:sub(-5) == '.json' then
				-- Walk back from the extension to the last separator to get the
				-- bare config name, without assuming a path separator.
				local Start = Path:find('.json', 1, true);
				local Finish = Start;
				local Char = Path:sub(Start, Start);

				while Char ~= '/' and Char ~= '\\' and Char ~= '' do
					Start = Start - 1;
					Char = Path:sub(Start, Start);
				end;

				if Char == '/' or Char == '\\' then
					table.insert(List, Path:sub(Start + 1, Finish - 1));
				end;
			end;
		end;

		return List;
	end;

	function SaveManager:SaveAutoloadConfig(Name)
		self:CheckFolderTree();
		writefile(self.Folder .. '/settings/autoload.txt', Name);
	end;

	function SaveManager:LoadAutoloadConfig()
		self:CheckFolderTree();

		if isfile(self.Folder .. '/settings/autoload.txt') then
			local Name = readfile(self.Folder .. '/settings/autoload.txt');
			local Success, Err = self:Load(Name);

			if not Success then
				return self.Library:Notify('Failed to load autoload config: ' .. Err);
			end;

			if not SILENT then
				self.Library:Notify(string.format('Auto loaded config %q', Name));
			end;
		end;
	end;

	-- Creates (or reuses) a dedicated lowercase 'settings' tab on the window and
	-- builds the config section there, so it never lands in the user's own tabs.
	function SaveManager:BuildConfigTab(Window)
		assert(self.Library, 'Must set SaveManager.Library first!');
		self:BuildConfigSection(Window:AddTab('settings'));
	end;

	function SaveManager:BuildConfigSection(Tab)
		assert(self.Library, 'Must set SaveManager.Library first!');

		local Section = Tab:AddRightGroupbox('Configuration');

		Section:AddInput('SaveManager_ConfigName', { Text = 'Config name' });
		Section:AddDropdown('SaveManager_ConfigList', { Text = 'Config list', Values = self:RefreshConfigList(), AllowNull = true });

		Section:AddDivider();

		Section:AddButton('Create config', function()
			local Name = Options.SaveManager_ConfigName.Value;

			if Name:gsub(' ', '') == '' then
				return self.Library:Notify('Invalid config name (empty)', 2);
			end;

			local Success, Err = self:Save(Name);

			if not Success then
				return self.Library:Notify('Failed to save config: ' .. Err);
			end;

			self.Library:Notify(string.format('Created config %q', Name));

			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList());
			Options.SaveManager_ConfigList:SetValue(nil);
		end):AddButton('Load config', function()
			local Name = Options.SaveManager_ConfigList.Value;

			local Success, Err = self:Load(Name);

			if not Success then
				return self.Library:Notify('Failed to load config: ' .. Err);
			end;

			self.Library:Notify(string.format('Loaded config %q', Name));
		end);

		Section:AddButton('Overwrite config', function()
			local Name = Options.SaveManager_ConfigList.Value;

			local Success, Err = self:Save(Name);

			if not Success then
				return self.Library:Notify('Failed to overwrite config: ' .. Err);
			end;

			self.Library:Notify(string.format('Overwrote config %q', Name));
		end):AddButton('Delete config', function()
			local Name = Options.SaveManager_ConfigList.Value;

			local Success, Err = self:Delete(Name);

			if not Success then
				return self.Library:Notify('Failed to delete config: ' .. Err);
			end;

			self.Library:Notify(string.format('Deleted config %q', Name));

			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList());
			Options.SaveManager_ConfigList:SetValue(nil);
		end);

		Section:AddButton('Refresh config list', function()
			Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList());
			Options.SaveManager_ConfigList:SetValue(nil);
		end);

		Section:AddButton('Set as autoload', function()
			local Name = Options.SaveManager_ConfigList.Value;

			if not Name then
				return self.Library:Notify('No config selected');
			end;

			self:SaveAutoloadConfig(Name);
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. Name);
			self.Library:Notify(string.format('Set %q to auto load', Name));
		end);

		SaveManager.AutoloadLabel = Section:AddLabel('Current autoload config: none', true);

		if isfile(self.Folder .. '/settings/autoload.txt') then
			local Name = readfile(self.Folder .. '/settings/autoload.txt');
			SaveManager.AutoloadLabel:SetText('Current autoload config: ' .. Name);
		end;

		self:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' });
	end;
end;

getgenv().SaveManager = SaveManager;

return SaveManager;
