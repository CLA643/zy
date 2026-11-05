-- // ===== 补丁0：Bypass indexInstance detector =====
do
    -- 1. 篡改 indexInstance 检测表（基于以往反作弊特征）
    for _, obj in pairs(getgc(true)) do
        if type(obj) == "table" then
            local success, val = pcall(rawget, obj, "indexInstance")
            if success and val then
                -- 如果这是个检测表，直接把里面的逻辑废掉
                pcall(function()
                    if type(val) == "table" and val[1] == "kick" then
                        val[2] = function() return false end
                    elseif type(val) == "function" then
                        pcall(hookfunction, val, function() return false end)
                    end
                end)
            end
        end
    end

    -- 2. 拦截 Namecall 和 Index，防止反作弊看到非法的实例访问
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index
    
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        -- 拦截可能存在扫描的调用
        if method == "Kick" or method == "FindFirstChild" or method == "GetChildren" then
            -- 如果反作弊试图通过 Stack 查，尝试欺骗它
            local trace = debug.traceback()
            if trace:find("AntiCheat") or trace:find("Detector") or trace:find("Hyperion") then
                return false or {}
            end
        end
        return oldNamecall(self, ...)
    end)

    mt.__index = newcclosure(function(self, key)
        -- 如果有反作弊读取特定关键字，直接拦截返回 nil
        if key == "indexInstance" then
            return nil 
        end
        return oldIndex(self, key)
    end)
    
    setreadonly(mt, true)
end

if not game:IsLoaded() then
	repeat
		game.Loaded:Wait()
	until game:IsLoaded()
end

-- //#region bypasses
	-- mem bypass
	local Stats = game:GetService("Stats")
	local Memory = Stats:GetTotalMemoryUsageMb()

	local oldStats
	oldStats = hookmetamethod(Stats, "__namecall", function(self, ...)
		local trace = debug.traceback()
		local meth = getnamecallmethod()

		if meth == "GetTotalMemoryUsageMb" then
			--rconsoleprint("Memory Flag attempt " .. trace .. "\n")
			return Memory + math.random(-2, 2)
		end

		return oldStats(self, ...)
	end)
	--
	do --// full client bypass
		if not LPH_OBFUSCATED then
			LPH_JIT = function(Function)
				return Function
			end
			LPH_JIT_MAX = function(Function)
				return Function
			end
			LPH_NO_VIRTUALIZE = function(Function)
				return Function
			end
			LPH_NO_UPVALUES = function(Function)
				return function(...)
					return Function(...)
				end
			end
			LPH_ENCSTR = function(String)
				return String
			end
			LPH_ENCNUM = function(Number)
				return Number
			end
			LPH_CRASH = function()
				return --rconsoleprint("DEBUG: CLIENT CALLED CRASH")
			end
			--
			LRM_IsUserPremium = true
			LRM_LinkedDiscordID = "szneo"
			LRM_ScriptName = "ScriptName"
			LRM_TotalExecutions = 0
			LRM_SecondsLeft = 999999
			LRM_UserNote = "UserNote"

			if not getgenv then
				getgenv = function()
					return _G
				end
			end

			if not cloneref then
				cloneref = function(Reference)
					return Reference
				end
			end

			if not loadfile then
				loadfile = function(...)
					return ...
				end
			end

			if not readfile then
				readfile = function(...)
					return ...
				end
			end

			if not request then
				request = function(...)
					return ...
				end
			end

			if not clonefunction then
				clonefunction = function(f)
					return f
				end
			end

			if not newcclosure then
				newcclosure = function(...)
					return ...
				end
			end

			if not hookfunction then
				hookfunction = function() end
			end

			if not getrenv then
				getrenv = function()
					return {}
				end
			end
		end

		local Start = tick()
		local Executor = identifyexecutor()

		-- print = function(str)
		-- 	--rconsoleprint(str .. "\n")
		-- end

		local HttpService = game:GetService("HttpService")

		local GarbageCollection = getgc(true)
		local LocalPlayer = game:GetService("Players").LocalPlayer

		local Character = LocalPlayer.Character
		local Humanoid = Character:FindFirstChild("Humanoid")

		local passed1 = false
		local passed2 = false

		local Whitelist = {
			{ 2, "Highlight", "Highlight", false },
			{ 1 },
			{ { 1 }, 0 },
			{ "2", "" },
		}

		local IsTableWhitelisted = function(Table)
			if not Table then
				return false
			end

			for WhitelistIndex, WhitelistEntry in ipairs(Whitelist) do
				local IsMatch = false

				if type(WhitelistEntry) == "table" then
					if #WhitelistEntry == #Table then
						IsMatch = true
						for EntryIndex, EntryValue in ipairs(WhitelistEntry) do
							if type(EntryValue) == "table" then
								if type(Table[EntryIndex]) ~= "table" or #EntryValue ~= #Table[EntryIndex] then
									IsMatch = false
									break
								end
								for SubIndex, SubValue in ipairs(EntryValue) do
									if Table[EntryIndex][SubIndex] ~= SubValue then
										IsMatch = false
										break
									end
								end
								if not IsMatch then
									break
								end
							else
								if Table[EntryIndex] ~= EntryValue then
									IsMatch = false
									break
								end
							end
						end
					end
				else
					if #Table == 1 and Table[1] == WhitelistEntry then
						IsMatch = true
					end
				end

				if IsMatch then
					return true
				end
			end

			return false
		end

		for _, Table in GarbageCollection do
			if type(Table) ~= "table" then
				continue
			end

			if rawget(Table, 2) == Character and rawget(Table, 0) == Humanoid then
				local Table1 = rawget(Table, 7)
				local Table2 = rawget(Table, 10)

				Table1[2] = nil
				Table2[2] = nil

				local Expected1
				local Expected2

				setmetatable(Table1, {
					__index = function()
						if IsTableWhitelisted(Expected1) then
							--rconsoleprint("Sanity Check Attempt #1 \n")
							return Expected1
						else
							--rconsoleprint("Index Attempt #1 \n")
						end
					end,
					__newindex = function(_, _, Value)
						Expected1 = Value

						--rconsoleprint("Ban Attempt #1: " .. HttpService:JSONEncode(Value).."\n")
					end,
				})

				setmetatable(Table2, {
					__index = function()
						if IsTableWhitelisted(Expected2) then
							--rconsoleprint("Sanity Check Attempt #2 \n")
							return Expected2
						else
							--rconsoleprint("Index Attempt #2 \n")
						end
					end,
					__newindex = function(_, _, Value)
						Expected2 = Value

						--rconsoleprint("Ban Attempt #2: " .. HttpService:JSONEncode(Value).."\n")
					end,
				})
				passed1 = true
				--rconsoleprint("Loaded Part 1 \n")
			end
		end

		for _, Table in GarbageCollection do
			if type(Table) ~= "table" then
				continue
			end

			if typeof(rawget(Table, 1)) == "Instance" and rawget(Table, 1).Name == "Remotes" then
				local Table1 = rawget(Table, 4)

				local Expected1

				setmetatable(Table1, {
					__index = function()
						if IsTableWhitelisted(Expected1) then
							--rconsoleprint("Sanity Check Attempt #3 \n")
							return Expected1
						else
							--rconsoleprint("Index Attempt #3 \n")
						end
					end,
					__newindex = function(_, _, Value)
						Expected1 = Value

						--rconsoleprint("Ban Attempt #3: " .. HttpService:JSONEncode(Value).."\n")
					end,
				})
				passed2 = true
				--rconsoleprint("Loaded Part 2 \n")
			end
		end

		-- if (not passed1) and (not passed2) then
	    --  LocalPlayer:Kick("YOUR EXECUTER IS ASS")
	    -- end

	end

	-- // anti gameplay paused
	do
		spawn(function()
			while true do
				pcall(function()
					local player = game.Players.LocalPlayer
					if player then
						player.GameplayPaused = false
					end
				end)
				wait(0.1)
			end
		end)
	end
-- //#endregion

-- // Libraries
local cloneref = cloneref or function(...) return ...; end
local gethui = gethui or function() return cloneref(game:GetService("CoreGui")); end

-- //#region variables
	local run_service = game:GetService("RunService")
	local players = game:GetService("Players")
	local local_player = players.LocalPlayer
	local plr = game.Players.LocalPlayer
	local char = plr.Character or plr.CharacterAdded:Wait()
	local hum = char:FindFirstChildOfClass("Humanoid")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	local OriginalName = LocalPlayer.Name
	local SpoofedName = "InsanityPastedSloptic_User"
	local SpoofName = false
	local SpoofColor = Color3.new(1, 1, 1)
	local updateDebounce = false
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	local inputservice = game:GetService('UserInputService')
	local tweenservice = game:GetService('TweenService')
	local camera = workspace.CurrentCamera
	local camera = workspace.CurrentCamera
	local localPlayer = game:GetService("Players").LocalPlayer
	local default_fov = camera.FieldOfView
	local Lighting = game:GetService("Lighting")
	local RunService = game:GetService("RunService")
	local runservice = game:GetService('RunService')
	local uis = cloneref(game:GetService("UserInputService"))
	local players = cloneref(game:GetService("Players"))
	local ws = cloneref(game:GetService("Workspace"))
	local http_service = cloneref(game:GetService("HttpService"))
	local gui_service = cloneref(game:GetService("GuiService"))
	local lighting = cloneref(game:GetService("Lighting"))
	local run = cloneref(game:GetService("RunService"))
	local stats = cloneref(game:GetService("Stats"))
	local coregui = cloneref(game:GetService("CoreGui"))
	local debris = cloneref(game:GetService("Debris"))
	local tween_service = cloneref(game:GetService("TweenService"))
	local sound_service = cloneref(game:GetService("SoundService"))
	local starter_gui = cloneref(game:GetService("StarterGui"))
	local rs = cloneref(game:GetService("ReplicatedStorage"))
	local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))

	local vec2 = Vector2.new
	local vec3 = Vector3.new
	local dim2 = UDim2.new
	local dim = UDim.new 
	local rect = Rect.new
	local cfr = CFrame.new
	local empty_cfr = cfr()
	local point_object_space = empty_cfr.PointToObjectSpace
	local angle = CFrame.Angles
	local dim_offset = UDim2.fromOffset

	local color = Color3.new
	local hsv = Color3.fromHSV
	local rgb = Color3.fromRGB
	local hex = Color3.fromHex
	local rgbseq = ColorSequence.new
	local rgbkey = ColorSequenceKeypoint.new
	local numseq = NumberSequence.new
	local numkey = NumberSequenceKeypoint.new

	local camera = ws.CurrentCamera
	local lp = players.LocalPlayer 
	local mouse = lp:GetMouse() 
	local gui_offset = gui_service:GetGuiInset().Y

	local max = math.max 
	local floor = math.floor 
	local min = math.min 
	local abs = math.abs 
	local noise = math.noise
	local rad = math.rad 
	local random = math.random 
	local pow = math.pow 
	local sin = math.sin 
	local pi = math.pi 
	local tan = math.tan 
	local atan2 = math.atan2 
	local cos = math.cos 
	local round = math.round;
	local clamp = math.clamp; 
	local ceil = math.ceil; 
	local sqrt = math.sqrt;
	local acos = math.acos; 

	local insert = table.insert 
	local find = table.find 
	local remove = table.remove
	local concat = table.concat
-- //#endregion

LPH_NO_VIRTUALIZE(function()
	-- //#region ui src
	-- // fuckass ui </3
	-- // library init
		library = {
			directory = "InsanityPastedSloptic",
			folders = {
				"/fonts",
				"/configs",
				"/images"
			},
			flags = {},
			config_flags = {},
			visible_flags = {}, 
			guis = {}, 
			connections = {},   
			notifications = {},
			playerlist_data = {},

			current_tab, 
			current_element_open, 
			dock_button_holder,  
			old_config; 
			font, 
			keybind_list,
			binds = {}, 
			
			copied_flag; 
			is_rainbow;

			instances = {}; 
			drawings = {};

			display_orders = 0; 
		}

		local flags = library.flags
		local config_flags = library.config_flags

		themes = {
			preset = {
				["outline"] = hex("#0A0A0A"), -- // 
				["inline"] = hex("#2D2D2D"), -- //
				["accent"] = hex("#54a095"), -- //
				["high_contrast"] = hex("#141414"),
				["low_contrast"] = hex("#1E1E1E"),
				["text"] = hex("#B4B4B4"),
				["text_outline"] = rgb(0, 0, 0),
				["glow"] = hex("#54a095"), 
			},

			utility = {
				["outline"] = {
					["BackgroundColor3"] = {}, 	
					["Color"] = {}, 
				},
				["inline"] = {
					["BackgroundColor3"] = {}, 	
					["ImageColor3"] = {},
				},
				["accent"] = {
					["BackgroundColor3"] = {}, 	
					["TextColor3"] = {}, 
					["ImageColor3"] = {}, 
					["ScrollBarImageColor3"] = {} 
				},
				["contrast"] = {
					["Color"] = {}, 	
				},
				["text"] = {
					["TextColor3"] = {}, 	
				},
				["text_outline"] = {
					["Color"] = {}, 	
				},
				["glow"] = {
					["ImageColor3"] = {}, 	
				}, 
				["high_contrast"] = {
					["BackgroundColor3"] = {},
				},
				["low_contrast"] = {
					["BackgroundColor3"] = {},
				}
			}, 

			find = {
				["Frame"] = "BackgroundColor3", 
				["TextLabel"] = "TextColor3", 
				["UIGradient"] = "Color",
				["UIStroke"] = "Color",
				["ImageLabel"] = "ImageColor3",
				["TextButton"] = "BackgroundColor3", 
				["ScrollingFrame"] = "ScrollBarImageColor3"
			}
		}

		local keys = {
			[Enum.KeyCode.LeftShift] = "LS",
			[Enum.KeyCode.RightShift] = "RS",
			[Enum.KeyCode.LeftControl] = "LC",
			[Enum.KeyCode.RightControl] = "RC",
			[Enum.KeyCode.Insert] = "INS",
			[Enum.KeyCode.Backspace] = "BS",
			[Enum.KeyCode.Return] = "Ent",
			[Enum.KeyCode.LeftAlt] = "LA",
			[Enum.KeyCode.RightAlt] = "RA",
			[Enum.KeyCode.CapsLock] = "CAPS",
			[Enum.KeyCode.One] = "1",
			[Enum.KeyCode.Two] = "2",
			[Enum.KeyCode.Three] = "3",
			[Enum.KeyCode.Four] = "4",
			[Enum.KeyCode.Five] = "5",
			[Enum.KeyCode.Six] = "6",
			[Enum.KeyCode.Seven] = "7",
			[Enum.KeyCode.Eight] = "8",
			[Enum.KeyCode.Nine] = "9",
			[Enum.KeyCode.Zero] = "0",
			[Enum.KeyCode.KeypadOne] = "Num1",
			[Enum.KeyCode.KeypadTwo] = "Num2",
			[Enum.KeyCode.KeypadThree] = "Num3",
			[Enum.KeyCode.KeypadFour] = "Num4",
			[Enum.KeyCode.KeypadFive] = "Num5",
			[Enum.KeyCode.KeypadSix] = "Num6",
			[Enum.KeyCode.KeypadSeven] = "Num7",
			[Enum.KeyCode.KeypadEight] = "Num8",
			[Enum.KeyCode.KeypadNine] = "Num9",
			[Enum.KeyCode.KeypadZero] = "Num0",
			[Enum.KeyCode.Minus] = "-",
			[Enum.KeyCode.Equals] = "=",
			[Enum.KeyCode.Tilde] = "~",
			[Enum.KeyCode.LeftBracket] = "[",
			[Enum.KeyCode.RightBracket] = "]",
			[Enum.KeyCode.RightParenthesis] = ")",
			[Enum.KeyCode.LeftParenthesis] = "(",
			[Enum.KeyCode.Semicolon] = ",",
			[Enum.KeyCode.Quote] = "'",
			[Enum.KeyCode.BackSlash] = "\\",
			[Enum.KeyCode.Comma] = ",",
			[Enum.KeyCode.Period] = ".",
			[Enum.KeyCode.Slash] = "/",
			[Enum.KeyCode.Asterisk] = "*",
			[Enum.KeyCode.Plus] = "+",
			[Enum.KeyCode.Period] = ".",
			[Enum.KeyCode.Backquote] = "`",
			[Enum.UserInputType.MouseButton1] = "MB1",
			[Enum.UserInputType.MouseButton2] = "MB2",
			[Enum.UserInputType.MouseButton3] = "MB3",
			[Enum.KeyCode.Escape] = "ESC",
			[Enum.KeyCode.Space] = "SPC",
		}
			
		library.__index = library

		for _, path in next, library.folders do 
			makefolder(library.directory .. path)
		end 

		writefile("ffff.ttf", game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/fs-tahoma-8px.ttf"))

		local tahoma = {
			name = "SmallestPixel7",
			faces = {
				{
					name = "Regular",
					weight = 400,
					style = "normal",
					assetId = getcustomasset("ffff.ttf")
				}
			}
		}

		writefile("dddd.ttf", http_service:JSONEncode(tahoma))

		library.font = Font.new(getcustomasset("dddd.ttf"), Enum.FontWeight.Regular)

		local config_holder 
	-- // 

	-- // library functions 
		-- // misc functions
			function library:hoverify(hover, parent) 
				local hover_instance = library:create("Frame", {
					Parent = parent,
					BackgroundTransparency = 1,
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, 0, 1, 0),
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.accent,
					ZIndex = 1;
				}) library:apply_theme(hover_instance, "accent", "BackgroundColor3") 

				hover.MouseEnter:Connect(function()
					library:tween(hover_instance, {
						BackgroundTransparency = 0, 
					}) 
				end)
				
				hover.MouseLeave:Connect(function()
					library:tween(hover_instance, {
						BackgroundTransparency = 1, 
					}) 
				end)

				return hover_instance;
			end 

			function library:hovering(Object)
				if type(Object) == "table" then 
					local Pass = false;

					for _,obj in Object do 
						if library:hovering(obj) then 
							Pass = true
							return Pass
						end 
					end 
				else 
					local y_cond = Object.AbsolutePosition.Y <= mouse.Y and mouse.Y <= Object.AbsolutePosition.Y + Object.AbsoluteSize.Y
					local x_cond = Object.AbsolutePosition.X <= mouse.X and mouse.X <= Object.AbsolutePosition.X + Object.AbsoluteSize.X
					
					return (y_cond and x_cond)
				end 
			end  

			function library:make_resizable(frame) 
				local Frame = Instance.new("TextButton")
				Frame.Position = dim2(1, -10, 1, -10)
				Frame.BorderColor3 = rgb(0, 0, 0)
				Frame.Size = dim2(0, 10, 0, 10)
				Frame.BorderSizePixel = 0
				Frame.BackgroundColor3 = rgb(255, 255, 255)
				Frame.Parent = frame
				Frame.BackgroundTransparency = 1 
				Frame.Text = ""

				local resizing = false 
				local start_size 
				local start 
				local og_size = frame.Size  

				Frame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						resizing = true
						start = input.Position
						start_size = frame.Size
					end
				end)

				Frame.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						resizing = false
					end
				end)

				library:connection(uis.InputChanged, function(input, game_event) 
					if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
						local viewport_x = camera.ViewportSize.X
						local viewport_y = camera.ViewportSize.Y

						local current_size = dim2(
							start_size.X.Scale,
							math.clamp(
								start_size.X.Offset + (input.Position.X - start.X),
								og_size.X.Offset,
								viewport_x
							),
							start_size.Y.Scale,
							math.clamp(
								start_size.Y.Offset + (input.Position.Y - start.Y),
								og_size.Y.Offset,
								viewport_y
							)
						)
						frame.Size = current_size
					end
				end)
			end

			function library:draggify(frame)
				local dragging = false 
				local start_size = frame.Position
				local start 

				frame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						start = input.Position
						start_size = frame.Position

						if library.current_element_open then 
							library.current_element_open.set_visible(false)
							library.current_element_open.open = false 
							library.current_element_open = nil 
						end 

						if frame.Parent:IsA("ScreenGui") and frame.Parent.DisplayOrder ~= 999999 then 
							library.display_orders += 1 -- // shit code
							frame.Parent.DisplayOrder = library.display_orders
						end   
					end
				end)

				frame.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
					end
				end)

				library:connection(uis.InputChanged, function(input, game_event) 
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						local viewport_x = camera.ViewportSize.X
						local viewport_y = camera.ViewportSize.Y

						local current_position = dim2(
							0,
							clamp(
								start_size.X.Offset + (input.Position.X - start.X),
								0,
								viewport_x - frame.Size.X.Offset
							),
							0,
							clamp(
								start_size.Y.Offset + (input.Position.Y - start.Y),
								0,
								viewport_y - frame.Size.Y.Offset
							)
						)

						frame.Position = current_position
					end
				end)
			end

			function library:new_drawing(class, properties)
				local ins = Drawing.new(class)

				for _, v in next, properties do 
					ins[_] = v
				end 

				insert(library.drawings, ins)

				return ins 
			end 
			
			function library:new_item(class, properties) 
				local ins = Instance.new(class)

				for _, v in next, properties do 
					ins[_] = v
				end 

				insert(library.instances, ins)

				return ins 
			end 

			function library:convert_enum(enum)
				local enum_parts = {}
			
				for part in string.gmatch(enum, "[%w_]+") do
					insert(enum_parts, part)
				end
			
				local enum_table = Enum
				for i = 2, #enum_parts do
					local enum_item = enum_table[enum_parts[i]]
			
					enum_table = enum_item
				end
			
				return enum_table
			end

			function library:tween(obj, properties) 
				local tween = tween_service:Create(obj, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), properties):Play()
					
				return tween
			end 

			function library:config_list_update() 
				if not config_holder then return end 
			
				local list = {}
			
				for idx, file in next, listfiles(library.directory .. "/configs") do
					local name = string.sub(file:gsub(library.directory .. "/configs\\", ""):gsub(library.directory .. "\\configs\\", ""), 1, -5)
					list[#list + 1] = name
				end
				
				config_holder.refresh_options(list)
			end 

			function library:get_config()
				local Config = {}
			
				for _, v in flags do
					if type(v) == "table" and v.key then
						Config[_] = {active = v.active, mode = v.mode, key = tostring(v.key)}
					elseif type(v) == "table" and v["Transparency"] and v["Color"] then
						Config[_] = {Transparency = v["Transparency"], Color = v["Color"]:ToHex()}
					else
						Config[_] = v
					end
				end 
				
				return http_service:JSONEncode(Config)
			end

			function library:load_config(config_json) 
				local config = http_service:JSONDecode(config_json)
			
				for _, v in next, config do 
					local function_set = library.config_flags[_]
					
					if function_set then 
						if type(v) == "table" and v["Transparency"] and v["Color"] then
							function_set(hex(v["Color"]), v["Transparency"])
						elseif type(v) == "table" and v["active"] then 
							function_set(v)
						else 
							function_set(v)
						end
					end 
				end 
			end 
			
			function library:round(number, float) 
				local multiplier = 1 / (float or 1)

				return floor(number * multiplier + 0.5) / multiplier
			end 

			function library:apply_theme(instance, theme, property) 
				insert(themes.utility[theme][property], instance)
			end

			function library:update_theme(theme, color)
				for _, property in next, themes.utility[theme] do 

					for m, object in next, property do 
						if object[_] == themes.preset[theme] or object.ClassName == "UIGradient" then
							object[_] = color 
						end
					end 
				end 

				themes.preset[theme] = color 
			end 

			function library:connection(signal, callback)
				local connection = signal:Connect(callback)
				
				insert(library.connections, connection)

				return connection 
			end

			function library:apply_stroke(parent) 
				local stroke = library:create("UIStroke", {
					Parent = parent,
					Color = themes.preset.text_outline, 
					LineJoinMode = Enum.LineJoinMode.Miter
				}) 
				
				library:apply_theme(stroke, "text_outline", "Color")
			end

			function library:create(instance, options)
				local ins = Instance.new(instance) 
				
				for prop, value in next, options do 
					ins[prop] = value
				end
				
				if instance == "TextLabel" or instance == "TextButton" or instance == "TextBox" then 	
					library:apply_theme(ins, "text", "TextColor3")
					library:apply_stroke(ins)
				elseif instance == "ScreenGui" then 
					insert(library.guis, ins)
				end
				
				return ins 
			end
		-- // 

		-- // elements 
			local tooltip_sgui = library:create("ScreenGui", {
				Enabled = true,
				Parent = gethui(),
				Name = "",
				DisplayOrder = 500, 
			})

			function library:tool_tip(options) 
				local cfg = {
					name = options.name or "hi", 
					path = options.path or nil, 
				}

				if cfg.path then 
					local watermark_outline = library:create("Frame", {
						Parent = tooltip_sgui,
						Name = "",
						Size = dim2(0, 0, 0, 22),
						Position = dim2(0, 500, 0, 300),
						BorderColor3 = rgb(0, 0, 0),
						BorderSizePixel = 0,
						Visible = false,
						AutomaticSize = Enum.AutomaticSize.X,
						BackgroundColor3 = themes.preset.outline
					})
					
					local watermark_inline = library:create("Frame", {
						Parent = watermark_outline,
						Name = "",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					})
					
					local watermark_background = library:create("Frame", {
						Parent = watermark_inline,
						Name = "",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = watermark_background,
						Name = "",
						Color = rgbseq{rgbkey(0, rgb(41, 41, 55)), rgbkey(1, rgb(35, 35, 47))}
					}); library:apply_theme(UIGradient, "contrast", "Color")
					
					local text = library:create("TextLabel", {
						Parent = watermark_background,
						Name = "",
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = " " .. cfg.name .. " ",
						Size = dim2(0, 0, 1, 0),
						BackgroundTransparency = 1,
						Position = dim2(0, 0, 0, -1),
						BorderSizePixel = 0,
						AutomaticSize = Enum.AutomaticSize.X,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local UIStroke = library:create("UIStroke", {
						Parent = text,
						Name = "",
						LineJoinMode = Enum.LineJoinMode.Miter
					})

					cfg.path.MouseEnter:Connect(function()
						watermark_outline.Visible = true 
					end)   

					cfg.path.MouseLeave:Connect(function()
						watermark_outline.Visible = false 
					end)

					library:connection(uis.InputChanged, function(input)
						if watermark_outline.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
							watermark_outline.Position = dim_offset(input.Position.X + 10, input.Position.Y + 10)
						end
					end)
				end 
				
				return cfg
			end 

			function library:panel(options) 
				local cfg = {
					name = options.text or options.name or "Window", 
					size = options.size or dim2(0, 530, 0, 590),
					position = options.position or dim2(0, 500, 0, 500),
					anchor_point = options.anchor_point or vec2(0, 0),

					-- // button
					image = options.image or "rbxassetid://79856374238119",
					open = options.open or true,

					-- // ignore
					items = {},
				}
				
				local items = cfg.items do 
					-- // Panel
						items.sgui = library:create("ScreenGui", {
							Enabled = true,
							Parent = gethui(),
							Name = "" 
						})
						
						items.main_holder = library:create("Frame", {
							Parent = items.sgui,
							Name = "",
							AnchorPoint = vec2(cfg.anchor_point.X, cfg.anchor_point.Y),
							Position = cfg.position,
							Active = true, 
							BorderColor3 = rgb(0, 0, 0),
							Size = cfg.size,
							BorderSizePixel = 0,
							BackgroundColor3 = themes.preset.outline
						})
						library:draggify(items.main_holder)
						library:make_resizable(items.main_holder)

						local Close = library:create( "TextButton" , {
							Parent = items.main_holder;
							FontFace = library.font;
							Name = "\0";
							AnchorPoint = vec2(1, 0);
							Active = false;
							BorderColor3 = rgb(0, 0, 0);
							Text = "X";
							Size = dim2(0, 0, 0, 0);
							Selectable = false;
							Position = dim2(1, -7, 0, 5);
							BorderSizePixel = 0;
							BackgroundTransparency = 1;
							TextXAlignment = Enum.TextXAlignment.Right;
							AutomaticSize = Enum.AutomaticSize.XY;
							TextColor3 = themes.preset.text;
							TextSize = 12;
							ZIndex = 100;
							BackgroundColor3 = rgb(255, 255, 255)
						});

						library:create( "UIStroke" , {
							Parent = Close
						});         
						
						Close.MouseButton1Click:Connect(function()
							items.sgui.Enabled = false;
						end)

						-- //library:apply_theme(main_holder, "outline", "BackgroundColor3") 
						
						items.window_inline = library:create("Frame", {
							Parent = items.main_holder,
							Name = "",
							Position = dim2(0, 1, 0, 1),
							BorderColor3 = rgb(0, 0, 0),
							Size = dim2(1, -2, 1, -2),
							BorderSizePixel = 0,
							BackgroundColor3 = themes.preset.accent
						})
						
						library:apply_theme(items.window_inline, "accent", "BackgroundColor3") 
						
						items.window_holder = library:create("Frame", {
							Parent = items.window_inline,
							Name = "",
							Position = dim2(0, 1, 0, 1),
							BorderColor3 = themes.preset.outline,
							Size = dim2(1, -2, 1, -2),
							BorderSizePixel = 0,
							BackgroundColor3 = rgb(255, 255, 255)
						})
									
						items.UIGradient = library:create("UIGradient", {
							Parent = items.window_holder,
							Name = "",
							Rotation = 90,
							Color = rgbseq{
							rgbkey(0, rgb(41, 41, 55)),
							rgbkey(1, rgb(35, 35, 47))
						}
						})
			
						library:apply_theme(items.UIGradient, "contrast", "Color") 
						
						items.text = library:create("TextLabel", {
							Parent = items.window_holder,
							Name = "",
							FontFace = library.font,
							TextColor3 = themes.preset.accent,
							BorderColor3 = rgb(0, 0, 0),
							Text = cfg.name,
							BackgroundTransparency = 1,
							Position = dim2(0, 2, 0, 4),
							BorderSizePixel = 0,
							AutomaticSize = Enum.AutomaticSize.XY,
							TextSize = 12,
							BackgroundColor3 = rgb(255, 255, 255)
						}) library:apply_theme(items.text, "accent", "TextColor3")
						
						items.UIStroke = library:create("UIStroke", {
							Parent = items.text,
							Name = "",
							LineJoinMode = Enum.LineJoinMode.Miter
						})
						
						items.UIPadding = library:create("UIPadding", {
							Parent = items.window_holder,
							Name = "",
							PaddingBottom = dim(0, 4),
							PaddingRight = dim(0, 4),
							PaddingLeft = dim(0, 4)
						})
						
						items.outline = library:create("Frame", {
							Parent = items.window_holder,
							Name = "",
							Position = dim2(0, 0, 0, 18),
							BorderColor3 = rgb(0, 0, 0),
							Size = dim2(1, 0, 1, -18),
							BorderSizePixel = 0,
							BackgroundColor3 = themes.preset.inline
						})
						
						library:apply_theme(items.outline, "inline", "BackgroundColor3") 
						
						items.inline = library:create("Frame", {
							Parent = items.outline,
							Name = "",
							Position = dim2(0, 1, 0, 1),
							BorderColor3 = rgb(0, 0, 0),
							Size = dim2(1, -2, 1, -2),
							BorderSizePixel = 0,
							BackgroundColor3 = themes.preset.outline
						})
						
						library:apply_theme(items.inline, "outline", "BackgroundColor3") 
						
						items.holder = library:create("Frame", {
							Parent = items.inline,
							Name = "",
							Position = dim2(0, 1, 0, 1),
							BorderColor3 = rgb(0, 0, 0),
							Size = dim2(1, -2, 1, -2),
							BorderSizePixel = 0,
							BackgroundColor3 = rgb(255, 255, 255)
						})
						
						items.UIGradient = library:create("UIGradient", {
							Parent = items.holder,
							Name = "",
							Rotation = 90,
							Color = rgbseq{
								rgbkey(0, rgb(41, 41, 55)),
								rgbkey(1, rgb(35, 35, 47))
							}
						})
						
						library:apply_theme(items.UIGradient, "contrast", "Color") 
						
						items.UIPadding = library:create("UIPadding", {
							Parent = items.holder,
							Name = "",
							PaddingTop = dim(0, 5),
							PaddingBottom = dim(0, 5),
							PaddingRight = dim(0, 5),
							PaddingLeft = dim(0, 5)
						})
						
						items.glow = library:create("ImageLabel", {
							Parent = items.main_holder,
							Name = "",
							ImageColor3 = themes.preset.glow,
							ScaleType = Enum.ScaleType.Slice,
							BorderColor3 = rgb(0, 0, 0),
							BackgroundColor3 = rgb(255, 255, 255),
							Visible = true,
							Image = "http://www.roblox.com/asset/?id=18245826428",
							BackgroundTransparency = 1,
							ImageTransparency = 0.8, 
							Position = dim2(0, -20, 0, -20),
							Size = dim2(1, 40, 1, 40),
							ZIndex = 2,
							BorderSizePixel = 0,
							SliceCenter = rect(vec2(21, 21), vec2(79, 79))
						}) library:apply_theme(items.glow, "glow", "ImageColor3") 
					-- // 
					
					-- // Button
						items.button = library:create("TextButton", {
							Parent = library.dock_holder,
							Name = "",
							TextColor3 = rgb(0, 0, 0),
							BorderColor3 = rgb(0, 0, 0),
							Text = "",
							Size = dim2(0, 25, 0, 25),
							BorderSizePixel = 0,
							TextSize = 14,
							BackgroundColor3 = themes.preset.inline
						})
						
						local button_inline = library:create("Frame", {
							Parent = items.button,
							Name = "",
							Position = dim2(0, 1, 0, 1),
							BorderColor3 = rgb(0, 0, 0),
							Size = dim2(1, -2, 1, -2),
							BorderSizePixel = 0,
							BackgroundColor3 = themes.preset.outline
						}) library:apply_theme(button_inline, "outline", "BackgroundColor3") 
						
						local button_inline = library:create("Frame", {
							Parent = button_inline,
							Name = "",
							Position = dim2(0, 1, 0, 1),
							BorderColor3 = rgb(0, 0, 0),
							Size = dim2(1, -2, 1, -2),
							BorderSizePixel = 0,
							BackgroundColor3 = rgb(255, 255, 255)
						}) library:apply_theme(button_inline, "inline", "BackgroundColor3")
						
						local UIGradient = library:create("UIGradient", {
							Parent = button_inline,
							Name = "",
							Rotation = 90,
							Color = rgbseq{
								rgbkey(0, rgb(35, 35, 47)),
								rgbkey(1, rgb(41, 41, 55))
							}
						}) library:apply_theme(UIGradient, "contrast", "Color") 
						
						items.Icon = library:create("ImageLabel", {
							Parent = button_inline,
							Name = "",
							ImageColor3 = themes.preset.accent,
							Image = cfg.image,
							BackgroundTransparency = 1,
							BorderColor3 = rgb(0, 0, 0),
							Size = dim2(1, 0, 1, 0),
							BorderSizePixel = 0,
							BackgroundColor3 = rgb(255, 255, 255)
						}) library:apply_theme(items.Icon, "accent", "ImageColor3") library:apply_theme(items.Icon, "inline", "ImageColor3") 
						
						local UIPadding = library:create("UIPadding", {
							Parent = button_inline,
							Name = "",
							PaddingTop = dim(0, 4),
							PaddingBottom = dim(0, 4),
							PaddingRight = dim(0, 4),
							PaddingLeft = dim(0, 4)
						})
					-- // 

					library:tool_tip({name = cfg.name, path = items.button})
				end 

				items.sgui:GetPropertyChangedSignal("Enabled"):Connect(function()
					items.Icon.ImageColor3 = items.sgui.Enabled and themes.preset.accent or themes.preset.inline
				end)

				items.button.MouseButton1Click:Connect(function()
					items.sgui.Enabled = not items.sgui.Enabled
				end)
				
				return setmetatable(cfg, library)
			end 

			local sgui = library:create("ScreenGui", {
				Enabled = true,
				Parent = gethui(),
				Name = "",
				DisplayOrder = 999999, 
			})

			local notif_holder = library:create("ScreenGui", {
				Parent = gethui(),
				Name = "",
				IgnoreGuiInset = true, 
				DisplayOrder = 999999, 
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			})

			function library:fold_elements(origin, elements)
				for _, x in next, elements do 
					local flag = library.visible_flags[x]

					if flag then    
						flag(flags[origin])
					end     
				end 
			end 

			function library:indicator() 
				local cfg = {
					items = {};
				}

				local items = cfg.items; do 
					items.Window = library:create( "Frame" , {
						Parent = sgui;
						Name = "\0";
						Position = dim2(0, 400, 0, 500);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(0, 322, 0, 147);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});	library:apply_theme(items.Window, "outline", "BackgroundColor3"); library:draggify(items.Window)
					
					items.InfoTitle = library:create( "TextLabel" , {
						FontFace = library.font;
						TextColor3 = themes.preset.text;
						BorderColor3 = rgb(0, 0, 0);
						Text = "Indicators";
						Parent = items.Window;
						Name = "\0";
						Size = dim2(1, 0, 0, 0);
						Position = dim2(0, 7, 0, 5);
						BackgroundTransparency = 1;
						TextXAlignment = Enum.TextXAlignment.Left;
						BorderSizePixel = 0;
						ZIndex = 5;
						AutomaticSize = Enum.AutomaticSize.Y;
						TextSize = 12;
					}); 

					items.Accent = library:create( "Frame" , {
						Parent = items.Window;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.accent
					});	library:apply_theme(items.Accent, "accent", "BackgroundColor3")
					
					items.Background = library:create( "Frame" , {
						Parent = items.Accent;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.high_contrast
					});	library:apply_theme(items.Background, "high_contrast", "BackgroundColor3")
					
					items.Inline = library:create( "Frame" , {
						Parent = items.Background;
						Name = "\0";
						Position = dim2(0, 4, 0, 18);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -8, 1, -22);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});	library:apply_theme(items.Inline, "outline", "BackgroundColor3")
					
					items.Outline = library:create( "Frame" , {
						Parent = items.Inline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline
					});	library:apply_theme(items.Outline, "inline", "BackgroundColor3")
					
					items.LowContrast = library:create( "Frame" , {
						Parent = items.Outline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast
					});	library:apply_theme(items.LowContrast, "low_contrast", "BackgroundColor3")
					
					items.Inline = library:create( "Frame" , {
						Parent = items.LowContrast;
						Name = "\0";
						Position = dim2(0, 4, 0, 4);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -8, 1, -8);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline
					});	library:apply_theme(items.Inline, "inline", "BackgroundColor3")
					
					items.Outline = library:create( "Frame" , {
						Parent = items.Inline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});	library:apply_theme(items.Outline, "outline", "BackgroundColor3")
					
					items.LowContrast = library:create( "Frame" , {
						Parent = items.Outline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast
					});	library:apply_theme(items.LowContrast, "low_contrast", "BackgroundColor3"); local image_holder = items.LowContrast;
					
					items.Inline = library:create( "Frame" , {
						Parent = items.LowContrast;
						Name = "\0";
						Position = dim2(0, 4, 0, 4);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -8, 1, -8);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline
					});	library:apply_theme(items.Inline, "inline", "BackgroundColor3")
					
					items.Outline = library:create( "Frame" , {
						Parent = items.Inline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});	library:apply_theme(items.Outline, "outline", "BackgroundColor3")
					
					items.LowContrast = library:create( "Frame" , {
						Parent = items.Outline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast
					});	library:apply_theme(items.LowContrast, "low_contrast", "BackgroundColor3")

					items.InfoTitle = library:create( "TextLabel" , {
						FontFace = library.font;
						TextColor3 = themes.preset.text;
						BorderColor3 = rgb(0, 0, 0);
						Text = "Info";
						Parent = items.Outline;
						Name = "\0";
						Size = dim2(1, 0, 0, 0);
						Position = dim2(0, 7, 0, 5);
						BackgroundTransparency = 1;
						TextXAlignment = Enum.TextXAlignment.Left;
						BorderSizePixel = 0;
						ZIndex = 5;
						AutomaticSize = Enum.AutomaticSize.Y;
						TextSize = 12;
					});

					library:create( "UIStroke" , {
						Parent = items.InfoTitle
					});
					
					items.Accent = library:create( "Frame" , {
						Name = "\0";
						Parent = items.LowContrast;
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, 0, 0, 2);
						BackgroundColor3 = themes.preset.accent;
						BorderSizePixel = 0;
					});	library:apply_theme(items.Accent, "accent", "BackgroundColor3");
					
					items.Shadow = library:create( "Frame" , {
						AnchorPoint = vec2(0, 1);
						Parent = items.Accent;
						Name = "\0";
						Position = dim2(0, 0, 1, 0);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, 0, 0, 1);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.accent;
					}); library:apply_theme(items.Shadow, "accent", "BackgroundColor3");
					
					library:create( "UIGradient" , {
						Rotation = 90;
						Parent = items.Shadow;
						Color = rgbseq{rgbkey(0, rgb(150, 150, 150)), rgbkey(1, rgb(150, 150, 150))}
					});
					
					items.holder = library:create( "Frame" , {
						Parent = items.LowContrast;
						Name = "\0";
						Position = dim2(0, 76, 0, 21);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -80, 0, 0);
						BorderSizePixel = 0;
					});	

					library:create("UIListLayout", {
						Parent = items.holder,
						Padding = dim(0, 4),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder
					})

					items.Inline = library:create( "Frame" , {
						Parent = image_holder;
						Name = "\0";
						Position = dim2(0, 10, 0, 28);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(0, 68, 0, 67);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});	library:apply_theme(items.Inline, "outline", "BackgroundColor3")
					
					items.Outline = library:create( "Frame" , {
						Parent = items.Inline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline
					});	library:apply_theme(items.Outline, "inline", "BackgroundColor3")
					
					items.LowContrast = library:create( "Frame" , {
						Parent = items.Outline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast
					});	library:apply_theme(items.LowContrast, "low_contrast", "BackgroundColor3")

					items.Profile = library:create( "ImageLabel" , {
						BorderColor3 = rgb(0, 0, 0);
						Parent = items.LowContrast;
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						BackgroundTransparency = 1;
						Name = "\0";
						Size = dim2(1, 0, 1, 0);
						BorderSizePixel = 0;
					});	

					local section = setmetatable(items, library)
					items.label = section:label({name = "Player: "})
					items.slider = section:slider({name = "Health", custom = rgb(0, 255, 0), min = 0, max = 100, default = 50, input = true})
					
					library:create( "UIStroke" , {
						Parent = items.InfoTitle
					});            
				end

				function cfg.set_visible(bool)
					items.Window.Visible = bool
				end 

				function cfg.change_health(int)
					items.slider.set(int)
				end

				function cfg.change_profile(player)
					items.label.set(string.format("Player: %s (%s)", player.Name, player.DisplayName))
					items.Profile.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=".. player.UserId .."&width=420&height=420&format=png"
				end 

				return setmetatable(cfg, library)
			end     

			function library:window(properties)
				local window = {opened = true}            
				local opened = {}
				local dock_outline;
				local blur = library:create( "BlurEffect" , {
					Parent = lighting;
					Enabled = true;
					Size = 15
				});    

				library.cache = library:create("ScreenGui", {
					Enabled = false,
					Parent = gethui(),
					Name = "" 
				})

				function window.set_menu_visibility(bool) 
					window.opened = bool 
					
					if bool then 
						for _,gui in opened do 
							gui.Enabled = true 
							opened = {}
						end 
					else
						for _,gui in library.guis do 
							if gui.Enabled then 
								gui.Enabled = false
								table.insert(opened, gui)
							end
						end
					end

					library:tween(blur, {Size = bool and (flags["Blur Size"] or 15) or 0})

					dock_outline.Visible = bool;

					sgui.Enabled = true
					notif_holder.Enabled = true
					tooltip_sgui.Enabled = true
					library.cache.Enabled = false

					for _,tooltip in tooltip_sgui:GetChildren() do 
						tooltip.Visible = false;
					end 

					if library.current_element_open then 
						library.current_element_open.set_visible(false)
						library.current_element_open.open = false 
						library.current_element_open = nil 
					end
				end 

				-- // dock init
					dock_outline = library:create("Frame", {
						Parent = sgui,
						Name = "",
						Visible = true,
						BorderColor3 = rgb(0, 0, 0),
						AnchorPoint = vec2(0.5, 0),
						Position = dim2(0.5, 0, 0, 20),
						Size = dim2(0, 157, 0, 39),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					}); 

					library:apply_theme(dock_outline, "outline", "BackgroundColor3"); 
					dock_outline.Position = dim2(0, dock_outline.AbsolutePosition.X, 0, dock_outline.AbsolutePosition.Y); 
					dock_outline.AnchorPoint = vec2(0, 0); 
					library:draggify(dock_outline);

					local dock_inline = library:create("Frame", {
						Parent = dock_outline,
						Name = "",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					}) library:apply_theme(dock_inline, "inline", "BackgroundColor3") 
					
					local dock_holder = library:create("Frame", {
						Parent = dock_inline,
						Name = "",
						Size = dim2(1, -2, 1, -2),
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = themes.preset.outline,
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					}) library:apply_theme(dock_holder, "outline", "BackgroundColor3") 
					
					local accent = library:create("Frame", {
						Parent = dock_holder,
						Name = "",
						Size = dim2(1, 0, 0, 2),
						BorderColor3 = rgb(0, 0, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.accent
					}) library:apply_theme(accent, "accent", "BackgroundColor3") 
					
					local UIGradient = library:create("UIGradient", {
						Parent = accent,
						Name = "",
						Rotation = 90,
						Color = rgbseq{
						rgbkey(0, rgb(255, 255, 255)),
						rgbkey(1, rgb(167, 167, 167))
					}
					})
					
					local button_holder = library:create("Frame", {
						Parent = dock_holder,
						Name = "",
						BackgroundTransparency = 1,
						Size = dim2(1, 0, 1, 0),
						BorderColor3 = rgb(0, 0, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					}) library.dock_holder = button_holder;
					
					local UIListLayout = library:create("UIListLayout", {
						Parent = button_holder,
						Name = "",
						Padding = dim(0, 5),
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder
					})
					
					local UIPadding = library:create("UIPadding", {
						Parent = button_holder,
						Name = "",
						PaddingTop = dim(0, 6),
						PaddingBottom = dim(0, 4),
						PaddingRight = dim(0, 4),
						PaddingLeft = dim(0, 4)
					})
							
					local UIGradient = library:create("UIGradient", {
						Parent = dock_holder,
						Name = "",
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(41, 41, 55)),
							rgbkey(1, rgb(35, 35, 47))
						}
					}) library:apply_theme(UIGradient, "contrast", "Color") 
				-- // 

				-- // keybind list
					local outline = library:create("Frame", {
						Parent = sgui,
						Name = "",
						Visible = false, 
						Active = true,
						Draggable = true, 
						Position = dim2(0, 50, 0, 200),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(0, 182, 0, 25),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					})
					library:apply_theme(outline, "outline", "BackgroundColor3") 
					library:draggify(outline)
					library:make_resizable(outline)
					library.keybind_list_frame = outline 
					
					local inline = library:create("Frame", {
						Parent = outline,
						Name = "",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					})
					library:apply_theme(inline, "inline", "BackgroundColor3")

					local background = library:create("Frame", {
						Parent = inline,
						Name = "",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = background,
						Name = "",
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, themes.preset.high_contrast),
							rgbkey(1, themes.preset.low_contrast)
						}
					})
					library:apply_theme(UIGradient, "contrast", "Color") 
					
					local bg = library:create("Frame", {
						Parent = background,
						Name = "a",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 0, 2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.accent
					}); library:apply_theme(bg, "accent", "BackgroundColor3")
					
					
					library:create("UIGradient", {
						Parent = bg,
						Name = "",
						Enabled = true, 
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(255, 255, 255)),
							rgbkey(1, rgb(167, 167, 167))
						}
					})
					
					local text = library:create("TextLabel", {
						Parent = background,
						Name = "",
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "Keybinds",
						BackgroundTransparency = 1,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Size = dim2(1, 0, 1, 0),
						BorderSizePixel = 0,
						TextSize = 12,
						BackgroundColor3 = themes.preset.text
					}, "text")
					
					local UIStroke = library:create("UIStroke", {
						Parent = text,
						Name = "",
						LineJoinMode = Enum.LineJoinMode.Miter
					})
					
					local text_holder = library:create("Frame", {
						Parent = background,
						Name = "",
						Position = dim2(0, -2, 1, 1),
						Size = dim2(1, 4, 0, 0),
						BorderColor3 = rgb(0, 0, 0),
						BorderSizePixel = 0,
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundColor3 = themes.preset.outline
					})
					library:apply_theme(text_holder, "outline", "BackgroundColor3")

					local inline = library:create("Frame", {
						Parent = text_holder,
						Name = "",
						Size = dim2(1, -2, 1, -2),
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						BorderSizePixel = 0,
						-- //AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundColor3 = themes.preset.inline
					})
					library:apply_theme(inline, "inline", "BackgroundColor3")
					
					local background = library:create("Frame", {
						Parent = inline,
						Name = "",
						Size = dim2(1, -2, 1, -2),
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						BorderSizePixel = 0,
						-- //AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					library.keybind_list = background
					
					local UIGradient = library:create("UIGradient", {
						Parent = background,
						Name = "",
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, themes.preset.high_contrast),
							rgbkey(1, themes.preset.low_contrast)
						}
					})
					library:apply_theme(UIGradient, "contrast", "Color") 
					
					library:create("UIListLayout", {
						Parent = background,
						Name = "",
						Padding = dim(0, -1),
						SortOrder = Enum.SortOrder.LayoutOrder
					})
					
					library:create("UIPadding", {
						Parent = background,
						Name = "",
						PaddingBottom = dim(0, 4),
						PaddingLeft = dim(0, 5)
					})
				-- //  

				-- // main window
					local main_window = library:panel({
						name = properties and properties.name or "InsanityPastedSloptic | ", 
						size = dim2(0, 604, 0, 628),
						position = dim2(0, (camera.ViewportSize.X / 2) - 302 - 96, 0, (camera.ViewportSize.Y / 2) - 421 - 12),
						image = "rbxassetid://98823308062942",
					})

					local items = main_window.items

					window["tab_holder"] = library:create("Frame", {
						Parent = items.holder,
						Name = " ",
						BackgroundTransparency = 1,
						Size = dim2(1, 0, 0, 22),
						BorderColor3 = rgb(0, 0, 0),
						ZIndex = 5,
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})

					library:create("UIListLayout", {
						Parent = window["tab_holder"],
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalFlex = Enum.UIFlexAlignment.Fill,
						Padding = dim(0, 2),
						SortOrder = Enum.SortOrder.LayoutOrder
					})

					local section_holder = library:create("Frame", {
						Parent = items.holder,
						Name = " ",
						BackgroundTransparency = 1,
						Position = dim2(0, -1, 0, 19),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 1, -22),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					window["section_holder"] = section_holder

					local outline = library:create("Frame", {
						Parent = section_holder,
						Name = "\0",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 1, 2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					})
					
					library:apply_theme(outline, "outline", "BackgroundColor3") 

					local inline = library:create("Frame", {
						Parent = outline,
						Name = "\0",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					})
					
					library:apply_theme(inline, "inline", "BackgroundColor3") 

					local background = library:create("Frame", {
						Parent = inline,
						Name = "\0",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})

					library.section_holder = background

					library:create("UIPadding", {
						Parent = background,
						PaddingTop = dim(0, 4),
						PaddingBottom = dim(0, 4),
						PaddingRight = dim(0, 4),
						PaddingLeft = dim(0, 4)
					})

					local UIGradient = library:create("UIGradient", {
						Parent = background,
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(41, 41, 55)),
							rgbkey(1, rgb(35, 35, 47))
						}
					})
					
					library:apply_theme(UIGradient, "contrast", "Color") 
					library:make_resizable(items.main_holder) 
				-- // 

				-- // theming 
					local style = library:panel({
						name = "Style", 
						anchor_point = vec2(0, 0),
						size = dim2(0, 394, 0, 464),
						position = dim2(0, main_window.items.main_holder.AbsolutePosition.X + main_window.items.main_holder.AbsoluteSize.X + 2, 0, main_window.items.main_holder.AbsolutePosition.Y),
						image = "rbxassetid://115194686863276",
					})

					local watermark = library:watermark({default = os.date('InsanityPastedSloptic |  - %b %d %Y - %H:%M:%S')})  

					task.spawn(function()
						while task.wait(1) do 
							watermark.change_text(os.date('InsanityPastedSloptic - Fallen Survival - v1 - %b %d %Y - %H:%M:%S'))
						end 
					end) 

					local items = style.items

					local column = setmetatable(items, library):column() 
					local section = column:section({name = "Theme"})
					section:label({name = "Accent"})
					:colorpicker({name = "Accent", color = themes.preset.accent, flag = "accent", callback = function(color, alpha)
						library:update_theme("accent", color)
					end, flag = "Accent"})
					section:label({name = "Contrast"})
					:colorpicker({name = "Low", color = themes.preset.low_contrast, flag = "low_contrast", callback = function(color)
						if (flags["high_contrast"] and flags["low_contrast"]) then 
							library:update_theme("contrast", rgbseq{
								rgbkey(0, flags["low_contrast"].Color),
								rgbkey(1, flags["high_contrast"].Color)
							})
						end 

						library:update_theme("low_contrast", flags["low_contrast"].Color)
					end})
					:colorpicker({name = "High", color = themes.preset.high_contrast, flag = "high_contrast", callback = function(color)
						library:update_theme("contrast", rgbseq{
							rgbkey(0, flags["low_contrast"].Color),
							rgbkey(1, flags["high_contrast"].Color)
						})

						library:update_theme("high_contrast", flags["high_contrast"].Color)
					end})
					section:label({name = "Inline"})
					:colorpicker({name = "Inline", color = themes.preset.inline, callback = function(color, alpha)
						library:update_theme("inline", color)
					end, flag = "Inline"})
					section:label({name = "Outline"})
					:colorpicker({name = "Outline", color = themes.preset.outline, callback = function(color, alpha)
						library:update_theme("outline", color)
					end, flag = "Outline"})
					section:label({name = "Text Color"})
					:colorpicker({name = "Main", color = themes.preset.text, callback = function(color, alpha)
						library:update_theme("text", color)
					end, flag = "Main"})
					:colorpicker({name = "Outline", color = themes.preset.text_outline, callback = function(color, alpha)
						library:update_theme("text_outline", color)
					end, flag = "Outline"})
					section:label({name = "Glow"})
					:colorpicker({name = "Glow", color = themes.preset.glow, callback = function(color, alpha)
						library:update_theme("glow", color)
					end, flag = "Glow"})
					section:slider({name = "Blur Size", flag = "Blur Size", min = 0, max = 56, default = 0, interval = 1, callback = function(int)
						if window.opened then 
							blur.Size = int
						end
					end})
					local section = column:section({name = "Other"})
					section:label({name = "UI Bind"})
					:keybind({callback = window.set_menu_visibility, key = Enum.KeyCode.Insert})
					section:toggle({name = "Keybind List", flag = "keybind_list", default = true, callback = function(bool)
						library.keybind_list_frame.Visible = bool
					end})
					section:toggle({name = "Watermark", flag = "watermark", default = true, callback = function(bool)
						watermark.set_visible(bool)
					end})
					section:button_holder({})
					section:button({name = "Copy JobId", callback = function()
						setclipboard(game.JobId)
					end})
					section:button_holder({})
					section:button({name = "Copy GameID", callback = function()
						setclipboard(game.GameId)
					end})
					section:button_holder({})
					section:button({name = "Copy Join Script", callback = function()
						setclipboard('game:GetService("TeleportService"):TeleportToPlaceInstance(' .. game.PlaceId .. ', "' .. game.JobId .. '", game.Players.LocalPlayer)')
					end})
					section:button_holder({})
					section:button({name = "Rejoin", callback = function()
						game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
					end})
					section:button_holder({})
					section:button({name = "Join New Server", callback = function()
						local apiRequest = game:GetService("HttpService"):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
						local data = apiRequest.data[random(1, #apiRequest.data)]
							
						if data.playing <= flags["max_players"] then 
							game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, data.id)
						end 
					end})
					section:slider({name = "Max Players", flag = "max_players", min = 0, max = 40, default = 15, interval = 1})
				-- // 

				-- // cfg holder
					local holder = library:panel({
						name = "Configurations", 
						size = dim2(0, 324, 0, 410),
						position = dim2(0, items.main_holder.AbsolutePosition.X + items.main_holder.AbsoluteSize.X + 2, 0, items.main_holder.AbsolutePosition.Y),
						image = "rbxassetid://105199726008012",
					}) 

					local items = holder.items

					getgenv().load_config = function(name)
						library:load_config(readfile(library.directory .. "/configs/" .. name .. ".cfg"))
					end 

					local column = setmetatable(items, library):column() 
					local section = column:section({name = "Options"})
						config_holder = section:list({flag = "config_name_list"})
						section:textbox({flag = "config_name_text_box"})
						section:button_holder({})
						section:button({name = "Create", callback = function()
							writefile(library.directory .. "/configs/" .. flags["config_name_text_box"] .. ".cfg", library:get_config())
							library:config_list_update()
						end})
						section:button({name = "Delete", callback = function()
							delfile(library.directory .. "/configs/" .. flags["config_name_list"] .. ".cfg")
							library:config_list_update()
						end})
						section:button_holder({})
						section:button({name = "Load", callback = function()
							library:load_config(readfile(library.directory .. "/configs/" .. flags["config_name_list"] .. ".cfg"))
							library:notification({text = "Loaded Config: " .. flags["config_name_list"], time = 3})
						end})
						section:button({name = "Save", callback = function()
							writefile(library.directory .. "/configs/" .. flags["config_name_list"] .. ".cfg", library:get_config())
							library:config_list_update()
							library:notification({text = "Saved Config: " .. flags["config_name_list"], time = 3})
						end})
						section:button_holder({})
						section:button({name = "Refresh Configs", callback = function()
							library:config_list_update()
						end})
						section:button_holder({})
						section:button({name = "Unload Config", callback = function()
							library:load_config(library.old_config)
						end})
						section:button({name = "Unload Menu", callback = function()
							library:load_config(library.old_config)

							for _, gui in library.guis do 
								gui:Destroy() 
							end 

							for _, connection in library.connections do 
								connection:Disconnect() 
							end
						end})
				-- // 
						
				-- // esp preview
					local holder = library:panel({
						name = "Skins", 
						anchor_point = vec2(0, 0),
						size = dim2(0, 529, 0, 344),
						position = dim2(0, main_window.items.main_holder.AbsolutePosition.X - 531, 0, main_window.items.main_holder.AbsolutePosition.Y + 447),
						image = "rbxassetid://90868297569632",
					})  

					local items = holder.items
					
					local column = setmetatable(items, library):column() 
					window.esp_section = column:section({name = "Main"})
				-- //  

				-- // playerlist 
					local holder = library:panel({
						name = "Playerlist", 
						anchor_point = vec2(0, 0),
						size = dim2(0, 529, 0, 445),
						position = dim2(0, main_window.items.main_holder.AbsolutePosition.X - 531, 0, main_window.items.main_holder.AbsolutePosition.Y),
						image = "rbxassetid://107070078834415",
					})  
					
					local items = holder.items

					local column = setmetatable(items, library):column() 
					local section = column:section({name = "Playerlist"})
					local playerlist = section:playerlist({})
					section:dropdown({name = "Priority", items = {"Enemy", "Priority", "Neutral", "Friendly"}, default = "Neutral", flag = "PLAYERLIST_DROPDOWN", callback = function(text)
						library.prioritize(text)
					end})
				-- //  

				return setmetatable(window, library)
			end

			function library:indicator(options) 
				local cfg = {
					items = {};
					name = options.name or "";
				}

				local items = cfg.items; do 
					items.Window = library:create( "Frame" , {
						Parent = sgui;
						Name = "\0";
						Position = dim2(0, 400, 0, 500);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(0, 382, 0, 167);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});	library:apply_theme(items.Window, "outline", "BackgroundColor3"); library:draggify(items.Window)
					
					library:make_resizable(items.Window)

					items.InfoTitle = library:create( "TextLabel" , {
						FontFace = library.font;
						TextColor3 = themes.preset.text;
						BorderColor3 = rgb(0, 0, 0);
						Text = cfg.name;
						Parent = items.Window;
						Name = "\0";
						Size = dim2(1, 0, 0, 0);
						Position = dim2(0, 7, 0, 5);
						BackgroundTransparency = 1;
						TextXAlignment = Enum.TextXAlignment.Left;
						BorderSizePixel = 0;
						ZIndex = 5;
						AutomaticSize = Enum.AutomaticSize.Y;
						TextSize = 12;
					}); 

					items.Accent = library:create( "Frame" , {
						Parent = items.Window;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.accent
					});	library:apply_theme(items.Accent, "accent", "BackgroundColor3")
					
					items.Background = library:create( "Frame" , {
						Parent = items.Accent;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.high_contrast
					});	library:apply_theme(items.Background, "high_contrast", "BackgroundColor3")
					
					items.Inline = library:create( "Frame" , {
						Parent = items.Background;
						Name = "\0";
						Position = dim2(0, 4, 0, 18);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -8, 1, -22);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});	library:apply_theme(items.Inline, "outline", "BackgroundColor3")
					
					items.Outline = library:create( "Frame" , {
						Parent = items.Inline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline
					});	library:apply_theme(items.Outline, "inline", "BackgroundColor3")
					
					items.LowContrast = library:create( "Frame" , {
						Parent = items.Outline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast
					});	library:apply_theme(items.LowContrast, "low_contrast", "BackgroundColor3")
					
					items.Inline = library:create( "Frame" , {
						Parent = items.LowContrast;
						Name = "\0";
						Position = dim2(0, 4, 0, 4);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -8, 1, -8);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline
					});	library:apply_theme(items.Inline, "inline", "BackgroundColor3")
					
					items.Outline = library:create( "Frame" , {
						Parent = items.Inline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});	library:apply_theme(items.Outline, "outline", "BackgroundColor3")
					
					items.LowContrast = library:create( "Frame" , {
						Parent = items.Outline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast
					});	library:apply_theme(items.LowContrast, "low_contrast", "BackgroundColor3"); local image_holder = items.LowContrast;
					
					items.Inline = library:create( "Frame" , {
						Parent = items.LowContrast;
						Name = "\0";
						Position = dim2(0, 4, 0, 4);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -8, 1, -8);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline
					});	library:apply_theme(items.Inline, "inline", "BackgroundColor3")
					
					items.Outline = library:create( "Frame" , {
						Parent = items.Inline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});	library:apply_theme(items.Outline, "outline", "BackgroundColor3")
					
					items.LowContrast = library:create( "Frame" , {
						Parent = items.Outline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast
					});	library:apply_theme(items.LowContrast, "low_contrast", "BackgroundColor3")

					items.InfoTitle = library:create( "TextLabel" , {
						FontFace = library.font;
						TextColor3 = themes.preset.text;
						BorderColor3 = rgb(0, 0, 0);
						Text = "Info";
						Parent = items.Outline;
						Name = "\0";
						Size = dim2(1, 0, 0, 0);
						Position = dim2(0, 7, 0, 5);
						BackgroundTransparency = 1;
						TextXAlignment = Enum.TextXAlignment.Left;
						BorderSizePixel = 0;
						ZIndex = 5;
						AutomaticSize = Enum.AutomaticSize.Y;
						TextSize = 12;
					});

					library:create( "UIStroke" , {
						Parent = items.InfoTitle
					});
					
					items.Accent = library:create( "Frame" , {
						Name = "\0";
						Parent = items.LowContrast;
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, 0, 0, 2);
						BackgroundColor3 = themes.preset.accent;
						BorderSizePixel = 0;
					});	library:apply_theme(items.Accent, "accent", "BackgroundColor3");
					
					items.Shadow = library:create( "Frame" , {
						AnchorPoint = vec2(0, 1);
						Parent = items.Accent;
						Name = "\0";
						Position = dim2(0, 0, 1, 0);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, 0, 0, 1);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.accent;
					}); library:apply_theme(items.Shadow, "accent", "BackgroundColor3");
					
					library:create( "UIGradient" , {
						Rotation = 90;
						Parent = items.Shadow;
						Color = rgbseq{rgbkey(0, rgb(150, 150, 150)), rgbkey(1, rgb(150, 150, 150))}
					});
					
					items.holder = library:create( "Frame" , {
						Parent = items.LowContrast;
						Name = "\0";
						Position = dim2(0, 76, 0, 21);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -80, 0, 0);
						BorderSizePixel = 0;
					});	

					library:create("UIListLayout", {
						Parent = items.holder,
						Padding = dim(0, 4),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder
					})

					items.Inline = library:create( "Frame" , {
						Parent = image_holder;
						Name = "\0";
						Position = dim2(0, 10, 0, 28);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(0, 68, 0, 67);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});	library:apply_theme(items.Inline, "outline", "BackgroundColor3")
					
					items.Outline = library:create( "Frame" , {
						Parent = items.Inline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline
					});	library:apply_theme(items.Outline, "inline", "BackgroundColor3")
					
					items.LowContrast = library:create( "Frame" , {
						Parent = items.Outline;
						Name = "\0";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast
					});	library:apply_theme(items.LowContrast, "low_contrast", "BackgroundColor3")

					items.Profile = library:create( "ImageLabel" , {
						BorderColor3 = rgb(0, 0, 0);
						Parent = items.LowContrast;
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						BackgroundTransparency = 1;
						Name = "\0";
						Size = dim2(1, 0, 1, 0);
						BorderSizePixel = 0;
					});	

					local section = setmetatable(items, library)
					items.label = section:label({name = "Player: \nDistance: \nVisible "})

					items.slider = section:slider({name = "Health", custom = rgb(0, 255, 0), min = 0, max = 100, default = 50, input = true})
					
					library:create( "UIStroke" , {
						Parent = items.InfoTitle
					});            
				end

				function cfg.set_visible(bool)
					items.Window.Visible = bool
				end 

				function cfg.change_health(int)
					items.slider.set(int)
				end

				function cfg.change_profile(player, dist, vis, f)
						items.label.set(string.format(
							"Player: %s (%s)\nDistance: %sm\nVisible: %s",
							player.Name,
							player.DisplayName,
							tostring(dist),
							tostring(vis),
							tostring(f)
						))
					items.Profile.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=".. player.UserId .."&width=420&height=420&format=png"
				end 

				return setmetatable(cfg, library)
			end     

			--[[ function library:belt(options) 
				local cfg = {
					items = {};
					name = options.name or "";
				}

				local items = cfg.items; do 
					items.Window = library:create("Frame", {
						Parent = sgui;
						Name = "MainWindow";
						Position = dim2(0, 400, 0, 650);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(0, 246, 0, 97);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});  
					library:apply_theme(items.Window, "outline", "BackgroundColor3"); 
					library:draggify(items.Window)
					library:make_resizable(items.Window)

					items.InfoTitle = library:create("TextLabel", {
						FontFace = library.font;
						TextColor3 = themes.preset.text;
						BorderColor3 = rgb(0, 0, 0);
						Text = cfg.name;
						Parent = items.Window;
						Name = "TitleLabel";
						Size = dim2(1, 0, 0, 0);
						Position = dim2(0, 7, 0, 5);
						BackgroundTransparency = 1;
						TextXAlignment = Enum.TextXAlignment.Left;
						BorderSizePixel = 0;
						ZIndex = 5;
						AutomaticSize = Enum.AutomaticSize.Y;
						TextSize = 12;
					}); 

					items.Accent = library:create("Frame", {
						Parent = items.Window;
						Name = "AccentFrame";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.accent
					});  
					library:apply_theme(items.Accent, "accent", "BackgroundColor3")
					
					items.Background = library:create("Frame", {
						Parent = items.Accent;
						Name = "BackgroundFrame";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.high_contrast
					});  
					library:apply_theme(items.Background, "high_contrast", "BackgroundColor3")
					
					items.InlineOuter = library:create("Frame", {
						Parent = items.Background;
						Name = "InlineOuter";
						Position = dim2(0, 4, 0, 18);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -8, 1, -22);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});  
					library:apply_theme(items.InlineOuter, "outline", "BackgroundColor3")
					
					items.OutlineOuter = library:create("Frame", {
						Parent = items.InlineOuter;
						Name = "OutlineOuter";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline
					});  
					library:apply_theme(items.OutlineOuter, "inline", "BackgroundColor3")
					
					items.LowContrastOuter = library:create("Frame", {
						Parent = items.OutlineOuter;
						Name = "LowContrastOuter";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast
					});  
					library:apply_theme(items.LowContrastOuter, "low_contrast", "BackgroundColor3")
					
					items.InlineInner = library:create("Frame", {
						Parent = items.LowContrastOuter;
						Name = "InlineInner";
						Position = dim2(0, 4, 0, 4);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -8, 1, -8);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline
					});  
					library:apply_theme(items.InlineInner, "inline", "BackgroundColor3")
					
					items.OutlineInner = library:create("Frame", {
						Parent = items.InlineInner;
						Name = "OutlineInner";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});  
					library:apply_theme(items.OutlineInner, "outline", "BackgroundColor3")
					
					items.LowContrastInner = library:create("Frame", {
						Parent = items.OutlineInner;
						Name = "LowContrastInner";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast
					});  
					library:apply_theme(items.LowContrastInner, "low_contrast", "BackgroundColor3"); 
					local image_holder = items.LowContrastInner;

					-- Create the holder
					items.BeltIconHolder = library:create("Frame", {
						Parent = items.LowContrastInner;
						Name = "Holder";
						Position = dim2(0.5, 0, 0.5, 0);
						AnchorPoint = Vector2.new(0.5, 0.5);
						Size = dim2(0.9, 0, 0.9, 0);
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundTransparency = 1
					})

					items.BeltListLayout = library:create("UIListLayout", {
						Parent = items.BeltIconHolder;
						FillDirection = Enum.FillDirection.Horizontal;
						HorizontalAlignment = Enum.HorizontalAlignment.Center;
						VerticalAlignment = Enum.VerticalAlignment.Center;
						SortOrder = Enum.SortOrder.LayoutOrder;
						Padding = UDim.new(0, 5);
					})

					items.ImageFrame1 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame1";
						Size = dim2(0.3, 0, 1, 0); 
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame1, "outline", "BackgroundColor3")

					items.OutlineFrame1 = library:create("Frame", {
						Parent = items.ImageFrame1;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.OutlineFrame1, "inline", "BackgroundColor3")

					items.LowContrastFrame1 = library:create("Frame", {
						Parent = items.OutlineFrame1;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.LowContrastFrame1, "low_contrast", "BackgroundColor3")

					items.Profile1 = library:create("ImageLabel", {
						Parent = items.LowContrastFrame1;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})

					items.ImageFrame2 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame2";
						Size = dim2(0.3, 0, 1, 0);
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame2, "outline", "BackgroundColor3")

					items.OutlineFrame2 = library:create("Frame", {
						Parent = items.ImageFrame2;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.OutlineFrame2, "inline", "BackgroundColor3")

					items.LowContrastFrame2 = library:create("Frame", {
						Parent = items.OutlineFrame2;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.LowContrastFrame2, "low_contrast", "BackgroundColor3")

					items.Profile2 = library:create("ImageLabel", {
						Parent = items.LowContrastFrame2;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})

					items.ImageFrame3 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame3";
						Size = dim2(0.3, 0, 1, 0);
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame3, "outline", "BackgroundColor3")

					items.OutlineFrame3 = library:create("Frame", {
						Parent = items.ImageFrame3;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.OutlineFrame3, "inline", "BackgroundColor3")

					items.LowContrastFrame3 = library:create("Frame", {
						Parent = items.OutlineFrame3;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.LowContrastFrame3, "low_contrast", "BackgroundColor3")

					items.Profile3 = library:create("ImageLabel", {
						Parent = items.LowContrastFrame3;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})

					items.ImageFrame4 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame4";
						Size = dim2(0.3, 0, 1, 0); 
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame4, "outline", "BackgroundColor3")

					items.ImageFrame4 = library:create("Frame", {
						Parent = items.ImageFrame4;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.ImageFrame4, "inline", "BackgroundColor3")

					items.ImageFrame4 = library:create("Frame", {
						Parent = items.ImageFrame4;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.ImageFrame4, "low_contrast", "BackgroundColor3")

					items.Profile4 = library:create("ImageLabel", {
						Parent = items.ImageFrame4;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})

					items.ImageFrame5 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame5";
						Size = dim2(0.3, 0, 1, 0); 
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame5, "outline", "BackgroundColor3")

					items.ImageFrame5 = library:create("Frame", {
						Parent = items.ImageFrame5;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.ImageFrame5, "inline", "BackgroundColor3")

					items.ImageFrame5 = library:create("Frame", {
						Parent = items.ImageFrame5;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.ImageFrame5, "low_contrast", "BackgroundColor3")

					items.Profile5 = library:create("ImageLabel", {
						Parent = items.ImageFrame5;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})

					items.ImageFrame6 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame6";
						Size = dim2(0.3, 0, 1, 0); 
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame6, "outline", "BackgroundColor3")

					items.ImageFrame6 = library:create("Frame", {
						Parent = items.ImageFrame6;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.ImageFrame6, "inline", "BackgroundColor3")

					items.ImageFrame6 = library:create("Frame", {
						Parent = items.ImageFrame6;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.ImageFrame6, "low_contrast", "BackgroundColor3")

					items.Profile6 = library:create("ImageLabel", {
						Parent = items.ImageFrame6;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})
				end

				function cfg.set_visible(bool)
					items.Window.Visible = bool
				end 

				function cfg.update_images(i1, i2, i3, i4, i5, i6) -- // belt / inventory 
					items.Profile6.Image = "rbxassetid://"..i1
				end

				function cfg.update_size(size)
					if size == "vertical" then
						items.BeltListLayout.FillDirection = Enum.FillDirection.Vertical
						items.BeltListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
						items.BeltListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
						items.BeltListLayout.Padding = UDim.new(0, 5)

						items.ImageFrame1.Size = UDim2.new(1, 0, 0.3, 0)
						items.ImageFrame2.Size = UDim2.new(1, 0, 0.3, 0)
						items.ImageFrame3.Size = UDim2.new(1, 0, 0.3, 0)
					elseif size == "horizontal" then
						items.BeltListLayout.FillDirection = Enum.FillDirection.Horizontal
						items.BeltListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
						items.BeltListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
						items.BeltListLayout.Padding = UDim.new(0, 5)

						items.ImageFrame1.Size = UDim2.new(0.3, 0, 1, 0)
						items.ImageFrame2.Size = UDim2.new(0.3, 0, 1, 0)
						items.ImageFrame3.Size = UDim2.new(0.3, 0, 1, 0)
					end
				end
				
				return setmetatable(cfg, library)
			end 

			function library:armor(options) 
				local cfg = {
					items = {};
					name = options.name or "";
				}

				local items = cfg.items; do 
					items.Window = library:create("Frame", {
						Parent = sgui;
						Name = "MainWindow";
						Position = dim2(0, 400, 0, 750);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(0, 446, 0, 97);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});  
					library:apply_theme(items.Window, "outline", "BackgroundColor3"); 
					library:draggify(items.Window)
					library:make_resizable(items.Window)

					items.InfoTitle = library:create("TextLabel", {
						FontFace = library.font;
						TextColor3 = themes.preset.text;
						BorderColor3 = rgb(0, 0, 0);
						Text = cfg.name;
						Parent = items.Window;
						Name = "TitleLabel";
						Size = dim2(1, 0, 0, 0);
						Position = dim2(0, 7, 0, 5);
						BackgroundTransparency = 1;
						TextXAlignment = Enum.TextXAlignment.Left;
						BorderSizePixel = 0;
						ZIndex = 5;
						AutomaticSize = Enum.AutomaticSize.Y;
						TextSize = 12;
					}); 

					items.Accent = library:create("Frame", {
						Parent = items.Window;
						Name = "AccentFrame";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.accent
					});  
					library:apply_theme(items.Accent, "accent", "BackgroundColor3")
					
					items.Background = library:create("Frame", {
						Parent = items.Accent;
						Name = "BackgroundFrame";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.high_contrast
					});  
					library:apply_theme(items.Background, "high_contrast", "BackgroundColor3")
					
					items.InlineOuter = library:create("Frame", {
						Parent = items.Background;
						Name = "InlineOuter";
						Position = dim2(0, 4, 0, 18);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -8, 1, -22);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});  
					library:apply_theme(items.InlineOuter, "outline", "BackgroundColor3")
					
					items.OutlineOuter = library:create("Frame", {
						Parent = items.InlineOuter;
						Name = "OutlineOuter";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline
					});  
					library:apply_theme(items.OutlineOuter, "inline", "BackgroundColor3")
					
					items.LowContrastOuter = library:create("Frame", {
						Parent = items.OutlineOuter;
						Name = "LowContrastOuter";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast
					});  
					library:apply_theme(items.LowContrastOuter, "low_contrast", "BackgroundColor3")
					
					items.InlineInner = library:create("Frame", {
						Parent = items.LowContrastOuter;
						Name = "InlineInner";
						Position = dim2(0, 4, 0, 4);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -8, 1, -8);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline
					});  
					library:apply_theme(items.InlineInner, "inline", "BackgroundColor3")
					
					items.OutlineInner = library:create("Frame", {
						Parent = items.InlineInner;
						Name = "OutlineInner";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline
					});  
					library:apply_theme(items.OutlineInner, "outline", "BackgroundColor3")
					
					items.LowContrastInner = library:create("Frame", {
						Parent = items.OutlineInner;
						Name = "LowContrastInner";
						Position = dim2(0, 1, 0, 1);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast
					});  
					library:apply_theme(items.LowContrastInner, "low_contrast", "BackgroundColor3"); 
					local image_holder = items.LowContrastInner;

					-- Create the holder
					items.BeltIconHolder = library:create("Frame", {
						Parent = items.LowContrastInner;
						Name = "Holder";
						Position = dim2(0.5, 0, 0.5, 0);
						AnchorPoint = Vector2.new(0.5, 0.5);
						Size = dim2(0.9, 0, 0.9, 0);
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundTransparency = 1
					})

					items.BeltListLayout = library:create("UIListLayout", {
						Parent = items.BeltIconHolder;
						FillDirection = Enum.FillDirection.Horizontal;
						HorizontalAlignment = Enum.HorizontalAlignment.Center;
						VerticalAlignment = Enum.VerticalAlignment.Center;
						SortOrder = Enum.SortOrder.LayoutOrder;
						Padding = UDim.new(0, 5); 
					})

					items.ImageFrame1 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame1";
						Size = dim2(0.11, 0, 1, 0);
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame1, "outline", "BackgroundColor3")

					items.OutlineFrame1 = library:create("Frame", {
						Parent = items.ImageFrame1;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.OutlineFrame1, "inline", "BackgroundColor3")

					items.LowContrastFrame1 = library:create("Frame", {
						Parent = items.OutlineFrame1;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.LowContrastFrame1, "low_contrast", "BackgroundColor3")

					items.Profile1 = library:create("ImageLabel", {
						Parent = items.LowContrastFrame1;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})

					items.ImageFrame2 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame2";
						Size = dim2(0.11, 0, 1, 0);
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame2, "outline", "BackgroundColor3")

					items.OutlineFrame2 = library:create("Frame", {
						Parent = items.ImageFrame2;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.OutlineFrame2, "inline", "BackgroundColor3")

					items.LowContrastFrame2 = library:create("Frame", {
						Parent = items.OutlineFrame2;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.LowContrastFrame2, "low_contrast", "BackgroundColor3")

					items.Profile2 = library:create("ImageLabel", {
						Parent = items.LowContrastFrame2;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})

					items.ImageFrame3 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame3";
						Size = dim2(0.11, 0, 1, 0);
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame3, "outline", "BackgroundColor3")

					items.OutlineFrame3 = library:create("Frame", {
						Parent = items.ImageFrame3;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.OutlineFrame3, "inline", "BackgroundColor3")

					items.LowContrastFrame3 = library:create("Frame", {
						Parent = items.OutlineFrame3;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.LowContrastFrame3, "low_contrast", "BackgroundColor3")

					items.Profile3 = library:create("ImageLabel", {
						Parent = items.LowContrastFrame3;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})

					items.ImageFrame4 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame4";
						Size = dim2(0.11, 0, 1, 0);
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame4, "outline", "BackgroundColor3")

					items.OutlineFrame4 = library:create("Frame", {
						Parent = items.ImageFrame4;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.OutlineFrame4, "inline", "BackgroundColor3")

					items.LowContrastFrame4 = library:create("Frame", {
						Parent = items.OutlineFrame4;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.LowContrastFrame4, "low_contrast", "BackgroundColor3")

					items.Profile4 = library:create("ImageLabel", {
						Parent = items.LowContrastFrame4;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})

					items.ImageFrame5 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame5";
						Size = dim2(0.11, 0, 1, 0);
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame5, "outline", "BackgroundColor3")

					items.OutlineFrame5 = library:create("Frame", {
						Parent = items.ImageFrame5;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.OutlineFrame5, "inline", "BackgroundColor3")

					items.LowContrastFrame5 = library:create("Frame", {
						Parent = items.OutlineFrame5;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.LowContrastFrame5, "low_contrast", "BackgroundColor3")

					items.Profile5 = library:create("ImageLabel", {
						Parent = items.LowContrastFrame5;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})

					items.ImageFrame6 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame6";
						Size = dim2(0.11, 0, 1, 0);
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame6, "outline", "BackgroundColor3")

					items.OutlineFrame6 = library:create("Frame", {
						Parent = items.ImageFrame6;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.OutlineFrame6, "inline", "BackgroundColor3")

					items.LowContrastFrame6 = library:create("Frame", {
						Parent = items.OutlineFrame6;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.LowContrastFrame6, "low_contrast", "BackgroundColor3")

					items.Profile6 = library:create("ImageLabel", {
						Parent = items.LowContrastFrame6;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})

					items.ImageFrame7 = library:create("Frame", {
						Parent = items.BeltIconHolder;
						Name = "ImageFrame7";
						Size = dim2(0.11, 0, 1, 0);
						BorderColor3 = rgb(0, 0, 0);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.outline;
					})
					library:apply_theme(items.ImageFrame7, "outline", "BackgroundColor3")

					items.OutlineFrame7 = library:create("Frame", {
						Parent = items.ImageFrame7;
						Name = "OutlineFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.inline;
					})
					library:apply_theme(items.OutlineFrame7, "inline", "BackgroundColor3")

					items.LowContrastFrame7 = library:create("Frame", {
						Parent = items.OutlineFrame7;
						Name = "LowContrastFrame";
						Position = dim2(0, 1, 0, 1);
						Size = dim2(1, -2, 1, -2);
						BorderSizePixel = 0;
						BackgroundColor3 = themes.preset.low_contrast;
					})
					library:apply_theme(items.LowContrastFrame7, "low_contrast", "BackgroundColor3")

					items.Profile7 = library:create("ImageLabel", {
						Parent = items.LowContrastFrame7;
						Name = "ProfileImage";
						Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
						Size = dim2(1, 0, 1, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						BorderColor3 = rgb(0,0,0);
					})
				end

				function cfg.set_visible(bool)
					items.Window.Visible = bool
				end 

				function cfg.update_images(icon1, icon2, icon3, icon4, icon5, icon6, icon7) -- // armor 
					items.Profile1.Image = icon1 or ""
					items.Profile2.Image = icon2 or ""
					items.Profile3.Image = icon3 or ""
					items.Profile4.Image = icon4 or ""
					items.Profile5.Image = icon5 or ""
					items.Profile6.Image = icon6 or ""
					items.Profile7.Image = icon7 or ""
				end

				function cfg.update_size(size)
					local sz = size == "horizontal" and UDim2.new(0.11,0,1,0) or UDim2.new(1,0,0.11,0)
					local fillDir = size == "horizontal" and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
					items.BeltListLayout.FillDirection = fillDir
					items.BeltListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
					items.BeltListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
					items.BeltListLayout.Padding = UDim.new(0,5)

					items.ImageFrame1.Size = sz
					items.ImageFrame2.Size = sz
					items.ImageFrame3.Size = sz
					items.ImageFrame4.Size = sz
					items.ImageFrame5.Size = sz
					items.ImageFrame6.Size = sz
					items.ImageFrame7.Size = sz
					items.ImageFrame8.Size = sz
				end
				
				return setmetatable(cfg, library)
			end  ]]

			function library:watermark(options) 
				local cfg = {
					default = options.text or options.default or os.date('drain.lol | %b %d %Y | %H:%M')
				}

				local watermark_outline = library:create("Frame", {
					Parent = sgui,
					Name = "",
					BorderColor3 = rgb(0, 0, 0),
					AnchorPoint = vec2(1, 1),
					Position = dim2(1, -20, 0, 20),
					Size = dim2(0, 0, 0, 24),
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundColor3 = themes.preset.outline
				}) library:apply_theme(watermark_outline, "outline", "BackgroundColor3") 
				watermark_outline.Position = dim_offset(watermark_outline.AbsolutePosition.X, watermark_outline.AbsolutePosition.Y)
				library:draggify(watermark_outline)

				local watermark_inline = library:create("Frame", {
					Parent = watermark_outline,
					Name = "",
					Position = dim2(0, 1, 0, 1),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, -2, 1, -2),
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.inline
				}) library:apply_theme(watermark_inline, "inline", "BackgroundColor3") 
				
				local watermark_background = library:create("Frame", {
					Parent = watermark_inline,
					Name = "",
					Position = dim2(0, 1, 0, 1),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, -2, 1, -2),
					BorderSizePixel = 0,
					BackgroundColor3 = rgb(255, 255, 255)
				})
				
				local UIGradient = library:create("UIGradient", {
					Parent = watermark_background,
					Name = "",
					Rotation = 90,
					Color = rgbseq{
						rgbkey(0, rgb(41, 41, 55)),
						rgbkey(1, rgb(35, 35, 47))
					}
				}) library:apply_theme(UIGradient, "contrast", "Color") 
				
				local text = library:create("TextLabel", {
					Parent = watermark_background,
					Name = "",
					FontFace = library.font,
					TextColor3 = themes.preset.text,
					BorderColor3 = rgb(0, 0, 0),
					Text = "  drain.lol | Beta | Aug 29 2024 | 07:29:00  ",
					Size = dim2(0, 0, 1, 0),
					BackgroundTransparency = 1,
					Position = dim2(0, -1, 0, 1),
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.X,
					TextSize = 12,
					BackgroundColor3 = rgb(255, 255, 255)
				})
				
				library:create("UIStroke", {
					Parent = text,
					Name = "",
					LineJoinMode = Enum.LineJoinMode.Miter
				})
				
				local accent = library:create("Frame", {
					Parent = watermark_outline,
					Name = "",
					Position = dim2(0, 2, 0, 2),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, -4, 0, 2),
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.accent
				}) library:apply_theme(accent, "accent", "BackgroundColor3") 
				
				local UIGradient = library:create("UIGradient", {
					Parent = accent,
					Name = "",
					Rotation = 90,
					Color = rgbseq{
						rgbkey(0, rgb(255, 255, 255)),
						rgbkey(1, rgb(167, 167, 167))
					}
				})
				
				function cfg.change_text(input)
					text.Text = "  ".. input .."  "
				end 

				function cfg.set_visible(bool) 
					watermark_outline.Visible = bool
				end 


				cfg.change_text(cfg.default)

				return cfg 

			end 

			function library:refresh_notifications()  	
				for _, notif in next, library.notifications do 
					tween_service:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Position = dim2(0, 20, 0, 72 + (_ * 28))}):Play()
				end     
			end

			function library:notification(properties)
				local cfg = {
					time = properties.time or 5,
					text = properties.text or properties.name or "Notification",
					flashing = false, 
				}
			
				-- // Instances
					local watermark_outline = library:create("Frame", {
						Parent = notif_holder,
						Name = "",
						Size = UDim2.new(0, 0, 0, 24),
						BorderColor3 = rgb(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.new(0, 20, 0, 72 + (#library.notifications * 28)),
						AutomaticSize = Enum.AutomaticSize.X,
						BackgroundColor3 = themes.preset.outline,
						AnchorPoint = Vector2.new(1, 0)
					})
				
					local watermark_inline = library:create("Frame", {
						Parent = watermark_outline,
						Name = "",
						Position = UDim2.new(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = UDim2.new(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					})

					local watermark_background = library:create("Frame", {
						Parent = watermark_inline,
						Name = "",
						Position = UDim2.new(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = UDim2.new(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
			
					local UIGradient = library:create("UIGradient", {
						Parent = watermark_background,
						Name = "",
						Color = ColorSequence.new{
							rgbkey(0, themes.preset.high_contrast),
							rgbkey(1, themes.preset.low_contrast)
						}
					})
			
					local text = library:create("TextLabel", {
						Parent = watermark_background,
						Name = "",
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "  " .. cfg.text .. "  ",
						Size = UDim2.new(0, 0, 1, 0),
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 0, 0, -1),
						BorderSizePixel = 0,
						AutomaticSize = Enum.AutomaticSize.X,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
			
					local accent = library:create("Frame", {
						Parent = watermark_outline,
						Name = "",
						Position = UDim2.new(0, 2, 0, 2),
						BorderColor3 = rgb(0, 0, 0),
						Size = UDim2.new(0, 1, 1, -4),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.accent
					})

					library:apply_theme(accent, "accent", "BackgroundColor3")
			
					local UIGradient = library:create("UIGradient", {
						Parent = accent,
						Name = "",
						Rotation = 90,
						Color = ColorSequence.new{
							rgbkey(0, rgb(255, 255, 255)),
							rgbkey(1, rgb(167, 167, 167))
						}
					})
					
					local accent_bottom = library:create("Frame", {
						Parent = watermark_outline,
						Name = "",
						Position = UDim2.new(0, 2, 1, -3),
						BorderColor3 = rgb(0, 0, 0),
						Size = UDim2.new(0, -4, 0, 1),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.accent
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = accent,
						Name = "",
						Rotation = 90,
						Color = ColorSequence.new{
							rgbkey(0, rgb(255, 255, 255)),
							rgbkey(1, rgb(167, 167, 167))
						}
					})

					local index = #library.notifications + 1
					library.notifications[index] =watermark_outline

					library:refresh_notifications()

					tween_service:Create(watermark_outline, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {AnchorPoint = Vector2.new(0, 0)}):Play()
					
					tween_service:Create(accent_bottom, TweenInfo.new(cfg.time, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(1, -4, 0, 1)}):Play()
				-- //
				
				task.spawn(function()
					task.wait(cfg.time)

					library.notifications[index] = nil

					tween_service:Create(watermark_outline, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1}):Play()
					
					for _, v in next, watermark_outline:GetDescendants() do 
						if v:IsA("TextLabel") then 
							tween_service:Create(v, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {TextTransparency = 1}):Play()
						elseif v:IsA("Frame") then 
							tween_service:Create(v, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundTransparency = 1}):Play()
						elseif v:IsA("ImageLabel") then
							tween_service:Create(v, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
						elseif v:IsA("UIStroke") then 
							tween_service:Create(v, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Transparency = 1}):Play()
						end 
					end 

					task.wait(1)

					watermark_outline:Destroy()
				end)    
			end 

			function library:tab(options)	
				local cfg = {
					name = options.name or "tab", 
					enabled = false, 
				}
				
				-- // button instances
					local tab_holder = library:create("TextButton", {
						Parent = self.tab_holder,
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "",
						Name = "\0",
						BorderSizePixel = 0,
						Size = dim2(0, 0, 1, -2),
						ZIndex = 5,
						TextSize = 12,
						BackgroundColor3 = themes.preset.outline,
						AutoButtonColor = false
					}) library:apply_theme(tab_holder, "outline", "BackgroundColor3") 

					local inline = library:create("Frame", {
						Parent = tab_holder,
						Size = dim2(1, -2, 1, 0),
						Name = "\0",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						ZIndex = 5,
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					}) library:apply_theme(inline, "inline", "BackgroundColor3") 

					local background = library:create("Frame", {
						Parent = inline,
						Size = dim2(1, -2, 1, -1),
						Name = "\0",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						ZIndex = 5,
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})

					local UIGradient = library:create("UIGradient", {
						Parent = background,
						Rotation = 90,
						Color = rgbseq{rgbkey(0, rgb(41, 41, 55)), rgbkey(1, rgb(35, 35, 47))}
					}) library:apply_theme(UIGradient, "contrast", "Color") 

					local text = library:create("TextLabel", {
						Parent = background,
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = cfg.name,
						Name = "\0",
						BackgroundTransparency = 1,
						Size = dim2(1, 0, 1, 0),
						BorderSizePixel = 0,
						AutomaticSize = Enum.AutomaticSize.X,
						TextSize = 12,
						ZIndex = 5,
						BackgroundColor3 = rgb(255, 255, 255)
					}, "text")
					library:apply_theme(text, "accent", "TextColor3")
				-- // 

				-- // section instances 
					local section_holder = library:create("Frame", {
						Parent = library.section_holder,
						BackgroundTransparency = 1,
						Name = "\0",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 1, 0),
						BorderSizePixel = 0,
						Visible = false,
						BackgroundColor3 = rgb(255, 255, 255)
					})
				
					cfg["holder"] = section_holder

					library:create("UIListLayout", {
						Parent = section_holder,
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalFlex = Enum.UIFlexAlignment.Fill,
						Padding = dim(0, 4),
						SortOrder = Enum.SortOrder.LayoutOrder
					})
				-- // 

				function cfg.open_tab()
					if library.current_tab and library.current_tab[1] ~= background then 
						local button = library.current_tab[1]
						button.Size = dim2(1, -2, 1, -1)
						button:FindFirstChildOfClass("UIGradient").Rotation = 90
						button:FindFirstChildOfClass("TextLabel").TextColor3 = themes.preset.text
							
						library.current_tab[2].Visible = false
						
						library.current_tab = nil
					end
					
					library.current_tab = {
						background, section_holder
					}
					
					local button = library.current_tab[1] 
					button.Size = dim2(1, -2, 1, 0) -- // ENABLED
					button:FindFirstChildOfClass("UIGradient").Rotation = -90
					button:FindFirstChildOfClass("TextLabel").TextColor3 = themes.preset.accent 

					library.current_tab[2].Visible = true 

					if library.current_element_open and library.current_element_open ~= cfg then 
						library.current_element_open.set_visible(false)
						library.current_element_open.open = false 
						library.current_element_open = nil 
					end
				end
				
				tab_holder.MouseButton1Click:Connect(cfg.open_tab)
				
				return setmetatable(cfg, library) 
			end

			function library:column(path) 
				local cfg = {}
				
				local holder = path or self.holder
				
				local column = library:create("Frame", {
					Parent = holder,
					BackgroundTransparency = 1,
					Name = "\0",
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, 0, 1, 0),
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.inline
				}) library:apply_theme(column, "inline", "BackgroundColor3") 
				
				library:create("UIListLayout", {
					Parent = column,
					Padding = dim(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalFlex = Enum.UIFlexAlignment.Fill
				})
				
				cfg["holder"] = column

				return setmetatable(cfg, library) 
			end

			function library:multi_section(options)
				local cfg = {
					names = options.names or {"First", "Second", "Third"}, 
					sections = {},
				}

				local section = library:create("Frame", {
					Parent = self.holder,
					Name = "",
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, 0, 1, 0),
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.inline
				}) library:apply_theme(section, "inline", "BackgroundColor3")
				
				local inline = library:create("Frame", {
					Parent = section,
					Name = "",
					Position = dim2(0, 1, 0, 1),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, -2, 1, -2),
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.outline
				}) library:apply_theme(inline, "outline", "BackgroundColor3") 
				
				local __background = library:create("Frame", {
					Parent = inline,
					Name = "",
					ClipsDescendants = true,
					Position = dim2(0, 1, 0, 1),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, -2, 1, -2),
					BorderSizePixel = 0,
					ZIndex = 1,
					BackgroundColor3 = rgb(255, 255, 255)
				})
				
				local accent = library:create("Frame", {
					Parent = __background,
					Name = "",
					Size = dim2(1, 0, 0, 2),
					BorderColor3 = rgb(0, 0, 0),
					ZIndex = 3,
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.accent
				}) library:apply_theme(accent, "accent", "BackgroundColor3")
				
				local UIGradient = library:create("UIGradient", {
					Parent = accent,
					Name = "",
					Rotation = 90,
					Color = rgbseq{rgbkey(0, rgb(255, 255, 255)), rgbkey(1, rgb(167, 167, 167))}
				}) 
				
				local UIGradient = library:create("UIGradient", {
					Parent = __background,
					Name = "",
					Rotation = 90,
					Color = rgbseq{rgbkey(0, rgb(41, 41, 55)), rgbkey(1, rgb(35, 35, 47))}
				}) library:apply_theme(UIGradient, "contrast", "Color") 
				
				local tab_holder = library:create("Frame", {
					Parent = __background,
					Name = "",
					ClipsDescendants = true,
					BackgroundTransparency = 1,
					Position = dim2(0, -1, 0, 0),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, 2, 0, 21),
					BorderSizePixel = 0,
					BackgroundColor3 = rgb(255, 255, 255)
				}) 
				
				library:create("UIListLayout", {
					Parent = tab_holder,
					Name = "",
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					Padding = dim(0, -3),
					SortOrder = Enum.SortOrder.LayoutOrder
				})
				
				for _, tab in next, cfg.names do 
					local multi = {
						open = false, 
					} 

					-- // Tab
						local tabb = library:create("TextButton", {
							Parent = tab_holder,
							Name = "",
							AutoButtonColor = false,
							FontFace = library.font,
							TextColor3 = themes.preset.text,
							BorderColor3 = rgb(0, 0, 0),
							Text = "",
							BorderSizePixel = 0,
							Size = dim2(0, 0, 1, 0),
							ZIndex = 1,
							TextSize = 12,
							BackgroundColor3 = themes.preset.outline
						}) library:apply_theme(tabb, "outline", "BackgroundColor3") 
						
						local background = library:create("Frame", {
							Parent = tabb,
							Name = "",
							Size = dim2(1, 0, 1, -2),
							Position = dim2(0, 1, 0, 1),
							BorderColor3 = rgb(0, 0, 0),
							ZIndex = 1,
							BorderSizePixel = 0,
							BackgroundColor3 = rgb(255, 255, 255)
						})
						
						local UIGradient = library:create("UIGradient", {
							Parent = background,
							Name = "",
							Rotation = 90,
							Color = rgbseq{rgbkey(0, rgb(41, 41, 55)), rgbkey(1, rgb(35, 35, 47))}
						}) library:apply_theme(UIGradient, "contrast", "Color")
						
						local text = library:create("TextLabel", {
							Parent = background,
							Name = "",
							FontFace = library.font,
							TextColor3 = themes.preset.text,
							BorderColor3 = rgb(0, 0, 0),
							Text = tab,
							BackgroundTransparency = 1,
							Size = dim2(1, 0, 1, 0),
							BorderSizePixel = 0,
							AutomaticSize = Enum.AutomaticSize.X,
							TextSize = 12,
							BackgroundColor3 = rgb(255, 255, 255)
						}) library:apply_theme(text, "accent", "TextColor3")
						
						local UIStroke = library:create("UIStroke", {
							Parent = text,
							Name = "",
							LineJoinMode = Enum.LineJoinMode.Miter
						})
					-- // 

					-- // Element Handler
						local ScrollingFrame = library:create("ScrollingFrame", {
							Parent = __background,
							Name = "",
							ScrollBarImageColor3 = themes.preset.accent,
							Active = true,
							MidImage = "rbxassetid://103468666327206",
							TopImage = "rbxassetid://103468666327206",
							BottomImage = "rbxassetid://103468666327206",
							AutomaticCanvasSize = Enum.AutomaticSize.Y,
							ScrollBarThickness = 2,
							Size = dim2(1, 0, 1, -20),
							Visible = false, 
							BackgroundTransparency = 1,
							Position = dim2(0, 0, 0, 24),
							BackgroundColor3 = rgb(255, 255, 255),
							BorderColor3 = rgb(0, 0, 0),
							BorderSizePixel = 0,
							ScrollBarThickness = 2,
							CanvasSize = dim2(0, 0, 0, 0)
						}) library:apply_theme(ScrollingFrame, "accent", "ScrollBarImageColor3") 
						
						local elements = library:create("Frame", {
							Parent = ScrollingFrame,
							Name = "",
							BorderColor3 = rgb(0, 0, 0),
							Size = dim2(1, 0, 0, 0),
							BorderSizePixel = 0,
							BackgroundColor3 = rgb(255, 255, 255)
						}) multi.holder = elements
						
						local UIListLayout = library:create("UIListLayout", {
							Parent = elements,
							Name = "",
							SortOrder = Enum.SortOrder.LayoutOrder,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							Padding = dim(0, 4)
						})
						
						local UIPadding = library:create("UIPadding", {
							Parent = ScrollingFrame,
							Name = "",
							PaddingBottom = dim(0, 60)
						})
					-- //
					
					function multi:open_tab(bool) 
						ScrollingFrame.Visible = bool 
						UIGradient.Rotation = bool and -90 or 90
						tabb.Size = dim2(0, 0, 1, bool and 1 or 0)
						text.TextColor3 = bool and themes.preset.accent or themes.preset.text
					end

					library:connection(tabb.MouseButton1Click, function()
						for _, multi_s in next, cfg.sections do 
							multi_s:open_tab(false)
						end

						if library.current_element_open then 
							library.current_element_open.set_visible(false)
							library.current_element_open.open = false 
							library.current_element_open = nil 
						end

						multi:open_tab(true) 
					end)

					cfg.sections[#cfg.sections + 1] = setmetatable(multi, library)
				end 

				cfg.sections[1]:open_tab(true)

				return unpack(cfg.sections)
			end 

			function library:section(options)
				local cfg = {
					name = options.name or "Section", 
				}
				
				local section = library:create("Frame", {
					Parent = self.holder,
					Name = "\0",
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, 0, 1, 0),
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.inline
				}) library:apply_theme(section, "inline", "BackgroundColor3") 

				local inline = library:create("Frame", {
					Parent = section,
					Name = "\0",
					Position = dim2(0, 1, 0, 1),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, -2, 1, -2),
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.outline
				}) library:apply_theme(inline, "outline", "BackgroundColor3") 

				local background = library:create("Frame", {
					Parent = inline,
					Name = "\0",
					Position = dim2(0, 1, 0, 1),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, -2, 1, -2),
					BorderSizePixel = 0,
					BackgroundColor3 = rgb(255, 255, 255)
				})

				local text = library:create("TextLabel", {
					Parent = background,
					FontFace = library.font,
					TextColor3 = themes.preset.text,
					BorderColor3 = rgb(0, 0, 0),
					Text = cfg.name,
					Name = "\0",
					BackgroundTransparency = 1,
					Position = dim2(0, 6, 0, 4),
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.XY,
					TextSize = 12,
					BackgroundColor3 = rgb(255, 255, 255)
				})

				library:create("UIStroke", {
					Parent = text,
					LineJoinMode = Enum.LineJoinMode.Miter
				})

				local accent = library:create("Frame", {
					Parent = background,
					Name = "\0",
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, 0, 0, 2),
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.accent
				}) library:apply_theme(accent, "accent", "BackgroundColor3") 

				local UIGradient = library:create("UIGradient", {
					Parent = accent,
					Rotation = 90,
					Color = rgbseq{
						rgbkey(0, rgb(255, 255, 255)),
						rgbkey(1, rgb(167, 167, 167))
					}
				})

				local UIGradient = library:create("UIGradient", {
					Parent = background,
					Rotation = 90,
					Color = rgbseq{
						rgbkey(0, rgb(41, 41, 55)),
						rgbkey(1, rgb(35, 35, 47))
					}
				}) library:apply_theme(UIGradient, "contrast", "Color") 

				local ScrollingFrame = library:create("ScrollingFrame", {
					Parent = background,
					ScrollBarImageColor3 = themes.preset.accent,
					Active = true,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 2,
					MidImage = "rbxassetid://103468666327206",
					TopImage = "rbxassetid://103468666327206",
					BottomImage = "rbxassetid://103468666327206",
					Size = dim2(1, 0, 1, -20),
					BackgroundTransparency = 1,
					Position = dim2(0, 0, 0, 20),
					BackgroundColor3 = rgb(255, 255, 255),
					BorderColor3 = rgb(0, 0, 0),
					BorderSizePixel = 0,
					CanvasSize = dim2(0, 0, 0, 0)
				}) library:apply_theme(ScrollingFrame, "accent", "ScrollBarImageColor3") 

				ScrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
					if library.current_element_open then 
						library.current_element_open.set_visible(false)
						library.current_element_open.open = false 
						library.current_element_open = nil
					end
				end) 

				local elements = library:create("Frame", {
					Parent = ScrollingFrame,
					Name = "\0",
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, 0, 0, 0),
					BorderSizePixel = 0,
					BackgroundColor3 = rgb(255, 255, 255)
				})
				cfg.holder = elements 

				library:create("UIListLayout", {
					Parent = elements,
					Padding = dim(0, 4),
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder
				})

				library:create("UIPadding", {
					Parent = ScrollingFrame,
					PaddingBottom = dim(0, 10)
				})

				return setmetatable(cfg, library)
			end

			function library:slider(options)
				local cfg = {
					name = options.name or nil,
					suffix = options.suffix or "",
					flag = options.flag or tostring(2^789),
					callback = options.callback or function() end, 
					visible = options.visible or true, 
					input_disabled = options.input or false,
					custom_color = options.custom or nil; 

					min = options.min or options.minimum or 0,
					max = options.max or options.maximum or 100,
					intervals = options.interval or options.decimal or 1,
					default = options.default or 10,

					dragging = false,
					value = options.default or 10, 
				} 

				-- // instances 
					local slider_REAL = library:create("TextLabel", {
						Parent = self.holder, 
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "",
						Name = "slider",
						ZIndex = 1,
						Size = dim2(1, -8, 0, 12),
						BorderSizePixel = 0,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local TEXT_LABEL; 
					if cfg.name then 
						local left_components = library:create("Frame", {
							Parent = slider_REAL,
							Name = "left_components",
							BackgroundTransparency = 1,
							Position = dim2(0, 2, 0, -1),
							BorderColor3 = rgb(0, 0, 0),
							Size = dim2(0, 0, 0, 14),
							BorderSizePixel = 0,
							BackgroundColor3 = rgb(255, 255, 255)
						})
						
						TEXT_LABEL = library:create("TextLabel", {
							Parent = left_components,
							FontFace = library.font,
							TextColor3 = themes.preset.text,
							BorderColor3 = rgb(0, 0, 0),
							Text = cfg.name,
							Name = "text",
							BackgroundTransparency = 1,
							Size = dim2(0, 0, 1, -1),
							BorderSizePixel = 0,
							AutomaticSize = Enum.AutomaticSize.X,
							TextSize = 12,
							BackgroundColor3 = rgb(255, 255, 255)
						}, "text")

						library:create("UIListLayout", {
							Parent = left_components,
							Padding = dim(0, 5),
							Name = "_",
							FillDirection = Enum.FillDirection.Horizontal
						})
					end 
					
					local bottom_components = library:create("Frame", {
						Parent = slider_REAL,
						Name = "bottom_components",
						Position = dim2(0, 0, 0, cfg.name and 15 or 0),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 0, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local slider = library:create("TextButton", {
						Parent = bottom_components,
						Name = "slider",
						Position = dim2(0, 0, 0, 2),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -1, 1, 12),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline,
						Text = "",
						AutoButtonColor = false,
					}) library:apply_theme(slider, "outline", "BackgroundColor3") 

					if not cfg.input_disabled then 
						library:hoverify(slider_REAL, slider)
					end

					local inline = library:create("Frame", {
						Parent = slider,
						Name = "inline",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						ZIndex = 1;
						BackgroundColor3 = themes.preset.inline
					}) library:apply_theme(inline, "inline", "BackgroundColor3") 

					local background = library:create("Frame", {
						Parent = inline,
						Name = "background",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
					}) 
					
					local contrast = library:create("Frame", {
						Parent = background,
						Name = "contrast",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 1, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local slidertext = library:create("TextLabel", {
						Parent = contrast,
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "12.50/100.00",
						Name = "text",
						BackgroundTransparency = 1,
						Position = dim2(0, 0, 0, -1),
						Size = dim2(1, 0, 1, 0),
						BorderSizePixel = 0,
						TextSize = 12,
						ZIndex = 2,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local fill = library:create("Frame", {
						Parent = contrast,
						Name = "fill",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 1, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = cfg.custom_color or themes.preset.accent
					}) if not cfg.custom_color then library:apply_theme(fill, "accent", "BackgroundColor3") end; 
					
					local UIGradient = library:create("UIGradient", {
						Parent = fill,
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(255, 255, 255)),
							rgbkey(1, rgb(167, 167, 167))
						}
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = contrast,
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(41, 41, 55)),
							rgbkey(1, rgb(35, 35, 47))
						}
					}); library:apply_theme(UIGradient, "contrast", "Color")
					
					local UIGradient = library:create("UIGradient", {
						Parent = background,
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(255, 255, 255)),
							rgbkey(1, rgb(167, 167, 167))
						}
					})
					
					library:create("UIListLayout", {
						Parent = bottom_components,
						Padding = dim(0, 10),
						Name = "_",
						SortOrder = Enum.SortOrder.LayoutOrder
					})
				-- //  

				function cfg.set(value)
					if type(value) == "userdata" then 
						return 
					end

					cfg.value = math.clamp(library:round(value, cfg.intervals), cfg.min, cfg.max)

					fill.Size = dim2((cfg.value - cfg.min) / (cfg.max - cfg.min), 0, 1, 0)
					slidertext.Text = tostring(cfg.value) .. cfg.suffix .. "/" .. tostring(cfg.max) .. cfg.suffix
					flags[cfg.flag] = cfg.value

					cfg.callback(flags[cfg.flag])
				end

				function cfg.set_element_visible(bool)
					slider_REAL.Visible = bool 

					if TEXT_LABEL then 
						TEXT_LABEL.Visible = bool 
					end 
				end

				if not cfg.input_disabled then 
					library:connection(uis.InputChanged, function(input)
						if cfg.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then 
							local size_x = (input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X
							local value = ((cfg.max - cfg.min) * size_x) + cfg.min
							cfg.set(value)
						end
					end)

					library:connection(uis.InputEnded, function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							cfg.dragging = false 
						end 
					end)

					slider.MouseButton1Down:Connect(function()
						cfg.dragging = true
					end)
				end

				if cfg.tooltip then 
					library:tool_tip({name = cfg.tooltip, path = slider_REAL})
				end

				cfg.set(cfg.default)
				cfg.set_element_visible(cfg.visible)
						
				config_flags[cfg.flag] = cfg.set

				library.config_flags[cfg.flag] = cfg.set
				library.visible_flags[cfg.flag] = cfg.set_element_visible

				return setmetatable(cfg, library) 
			end 

			function library:toggle(options)
				local cfg = {
					enabled = options.enabled or nil,
					name = options.name or "Toggle",
					flag = options.flag or tostring(random(1,9999999)),
					callback = options.callback or function() end,
					default = options.default or false,
					colorpicker = options.color or nil,
					visible = options.visible or true,
					tooltip = options.tooltip or nil,
				}

				-- // instances
					local toggle_holder = library:create("TextButton", {
						Parent = self.holder,
						FontFace = library.font,
						TextColor3 = rgb(151, 151, 151),
						BorderColor3 = rgb(0, 0, 0),
						Text = "",
						Name = "toggle",
						ZIndex = 1,
						Size = dim2(1, -8, 0, 12),
						BorderSizePixel = 0,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local right_components = library:create("Frame", {
						Parent = toggle_holder,
						Name = "right_components",
						Position = dim2(1, -1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(0, 0, 0, 12),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					cfg["right_holder"] = right_components
				
					local list = library:create("UIListLayout", {
						Parent = right_components,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
						Padding = dim(0, 4),
						Name = "list",
						SortOrder = Enum.SortOrder.LayoutOrder
					})
				
					library:create("UIPadding", {
						Parent = toggle_holder
					})
				
					local left_components = library:create("Frame", {
						Parent = toggle_holder,
						Name = "left_components",
						BackgroundTransparency = 1,
						Position = dim2(0, 0, 0, 0),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(0, 0, 0, 14),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local text = library:create("TextLabel", {
						Parent = left_components,
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = cfg.name,
						Name = "text",
						BackgroundTransparency = 1,
						Size = dim2(0, 0, 1, -1),
						BorderSizePixel = 0,
						AutomaticSize = Enum.AutomaticSize.X,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
				
					library:create("UIStroke", {
						Parent = text,
						LineJoinMode = Enum.LineJoinMode.Miter
					})
				
					library:create("UIListLayout", {
						Parent = left_components,
						Padding = dim(0, 5),
						Name = "_",
						FillDirection = Enum.FillDirection.Horizontal
					})
				
					local toggle = library:create("TextButton", {
						Parent = left_components,
						Name = "!toggle",
						Text = "",
						AutoButtonColor = false,
						Position = dim2(0, 0, 0, 2),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(0, 14, 0, 14),
						BorderSizePixel = 0,
						ZIndex = 1, 
						BackgroundColor3 = themes.preset.outline
					}) library:apply_theme(toggle, "outline", "BackgroundColor3") 
					library:apply_theme(toggle, "accent", "BackgroundColor3") 

					local inline = library:create("Frame", {
						Parent = toggle,
						Name = "inline",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						ZIndex = 2;
						BackgroundColor3 = themes.preset.inline
					}) library:apply_theme(inline, "inline", "BackgroundColor3") 
				
					local accent = library:create("Frame", {
						Parent = inline,
						BackgroundTransparency = 1;
						ZIndex = 3;
						Name = "background",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.accent
					})
					library:apply_theme(accent, "accent", "BackgroundColor3") 

					local UIGradient = library:create("UIGradient", {
						Parent = accent,
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(255, 255, 255)),
							rgbkey(1, rgb(167, 167, 167))
						}
					})

					local background = library:create("Frame", {
						Parent = inline,
						ZIndex = 2;
						Name = "background",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					library:apply_theme(background, "accent", "BackgroundColor3") 

					local UIGradient = library:create("UIGradient", {
						Parent = background,
						Rotation = 90,
						Name = "_",
						Color = rgbseq{
							rgbkey(0, rgb(41, 41, 55)),
							rgbkey(1, rgb(35, 35, 47))
						}
					}) library:apply_theme(UIGradient, "contrast", "Color") 
				-- //  

				library:hoverify(toggle_holder, toggle)

				function cfg.set(bool)
					library:tween(accent, {BackgroundTransparency = bool and 0 or 1})
					flags[cfg.flag] = bool
					
					cfg.callback(bool)
				end

				function cfg.set_element_visible(bool)
					toggle_holder.Visible = bool 
				end 
			
				library:connection(toggle_holder.MouseButton1Click, function()
					cfg.enabled = not cfg.enabled
			
					cfg.set(cfg.enabled)
				end)

				library:connection(toggle.MouseButton1Click, function()
					cfg.enabled = not cfg.enabled
			
					cfg.set(cfg.enabled)
				end)

				if cfg.tooltip then 
					library:tool_tip({name = cfg.tooltip, path = toggle_holder})
				end

				cfg.set(cfg.default)
				
				cfg.set_element_visible(cfg.visible)
				
				library.config_flags[cfg.flag] = cfg.set
				library.visible_flags[cfg.flag] = cfg.set_element_visible

				return setmetatable(cfg, library)
			end
			
			function library:colorpicker(options)
				local parent = self.right_holder
				
				local cfg = {
					name = options.name or "Color", 
					flag = options.flag or tostring(2^789),
					color = options.color or color(1, 1, 1), -- // Default to white color if not provided
					alpha = options.alpha or 1,
					callback = options.callback or function() end,
					right_holder = self.right_holder,
				}

				local dragging_sat = false 
				local dragging_hue = false 
				local dragging_alpha = false 

				local h, s, v = cfg.color:ToHSV() 
				local a = cfg.alpha 
				
				-- // colorpicker button 
					local colorpicker_button = library:create("TextButton", {
						Parent = parent,
						Name = "outline",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(0, 24, 0, 14),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline,
						Text = "",
						AutoButtonColor = false,
					}) library:apply_theme(colorpicker_button, "outline", "BackgroundColor3") 
				
					local inline = library:create("Frame", {
						Parent = colorpicker_button,
						Name = "inline",
						ZIndex = 2;
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					}) library:apply_theme(inline, "inline", "BackgroundColor3") 
				
					local handler = library:create("Frame", {
						Parent = inline,
						Name = "handler",
						ZIndex = 2;
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(250, 165, 27)
					})

					library:hoverify(colorpicker_button, colorpicker_button)
				
					local UIGradient = library:create("UIGradient", {
						Parent = handler,
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(255, 255, 255)),
							rgbkey(1, rgb(167, 167, 167))
						}
					})
				-- // 

				-- // colorpicker instances
					local colorpicker_holder = library:create("Frame", {
						Parent = sgui,
						Name = "colorpicker",
						Position = dim2(0, colorpicker_button.AbsolutePosition.X + 1, 0, colorpicker_button.AbsolutePosition.Y + 17),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(0, 190, 0, 210),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline,
						Visible = false,
						ZIndex = 1
					}) library:apply_theme(colorpicker_holder, "outline", "BackgroundColor3") 

					library:make_resizable(colorpicker_holder)
					
					local window_inline = library:create("Frame", {
						Parent = colorpicker_holder,
						Name = "window_inline",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.accent
					}) library:apply_theme(window_inline, "accent", "BackgroundColor3") 
					
					local window_holder = library:create("Frame", {
						Parent = window_inline,
						Name = "window_holder",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = themes.preset.outline,
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})

					local UIGradient = library:create("UIGradient", {
						Parent = window_holder,
						Rotation = 90,
						Name = "_",
						Color = rgbseq{
						rgbkey(0, rgb(41, 41, 55)),
						rgbkey(1, rgb(35, 35, 47))
					}
					}) library:apply_theme(UIGradient, "contrast", "Color") 
					
					local text = library:create("TextLabel", {
						Parent = window_holder,
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = cfg.name,
						Name = "text",
						BackgroundTransparency = 1,
						Position = dim2(0, 2, 0, 4),
						BorderSizePixel = 0,
						AutomaticSize = Enum.AutomaticSize.XY,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					library:create("UIStroke", {
						Parent = text,
						LineJoinMode = Enum.LineJoinMode.Miter
					})
					
					library:create("UIPadding", {
						Parent = window_holder,
						Name = "_",
						PaddingBottom = dim(0, 4),
						PaddingRight = dim(0, 4),
						PaddingLeft = dim(0, 4)
					})
					
					local main_holder = library:create("Frame", {
						Parent = window_holder,
						Name = "main_holder",
						Position = dim2(0, 0, 0, 20),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 1, -40),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					}) library:apply_theme(main_holder, "inline", "BackgroundColor3") 
					
					cfg.holder = library:create( "Frame" , {
						Parent = colorpicker_holder;
						Name = "\0";
						Position = dim2(0, 6, 1, -21);
						BorderColor3 = rgb(0, 0, 0);
						Size = dim2(1, -120, 0, 0);
						BorderSizePixel = 0;
					});
					
					local RainbowToggle = setmetatable(cfg, library):toggle({name = "Rainbow", flag = cfg.flag .. "_RAINBOW_FLAG"})

					cfg.holder = library:create( "Frame" , {
						Parent = colorpicker_holder;
						Name = "\0";
						Position = dim2(1, 2, 1, -23);
						BorderColor3 = rgb(0, 0, 0);
						AnchorPoint = vec2(1, 0);
						Size = dim2(1, -80, 0, 0);
						BorderSizePixel = 0;
					});
					
					local section = setmetatable(cfg, library)
					section:button_holder({})
					section:button({name = "Copy", callback = function()
						library.copied_flag = flags[cfg.flag]
						library.is_rainbow = flags[cfg.flag .. "_RAINBOW_FLAG"] or false
					end})
					section:button({name = "Paste", callback = function()
						RainbowToggle.set(library.is_rainbow)
						cfg.set(library.copied_flag.Color, library.copied_flag.Transparency)
					end})

					local main_holder_inline = library:create("Frame", {
						Parent = main_holder,
						Name = "main_holder_inline",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					}) library:apply_theme(main_holder_inline, "outline", "BackgroundColor3") 
					
					local main_holder_background = library:create("Frame", {
						Parent = main_holder_inline,
						Name = "main_holder_background",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = main_holder_background,
						Rotation = 90,
						Name = "_",
						Color = rgbseq{
							rgbkey(0, rgb(41, 41, 55)),
							rgbkey(1, rgb(35, 35, 47))
						}
					}) library:apply_theme(UIGradient, "contrast", "Color") 
					
					library:create("UIPadding", {
						Parent = main_holder_background,
						PaddingTop = dim(0, 4),
						Name = "_",
						PaddingBottom = dim(0, 4),
						PaddingRight = dim(0, 4),
						PaddingLeft = dim(0, 4)
					})
					
					local alpha = library:create("TextButton", {
						Parent = main_holder_background,
						AnchorPoint = vec2(0, 0.5),
						Name = "alpha",
						Position = dim2(0, 0, 1, -8),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -20, 0, 14),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline,
						Text = "",
						AutoButtonColor = false,
					}) library:apply_theme(alpha, "inline", "BackgroundColor3") 
					
					local outline = library:create("Frame", {
						Parent = alpha,
						Name = "outline",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					}) library:apply_theme(outline, "outline", "BackgroundColor3") 
					
					local alpha_drag = library:create("Frame", {
						Parent = outline,
						Name = "alpha_drag",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(0, 221, 255)
					})
					
					local alphaind = library:create("ImageLabel", {
						Parent = alpha_drag,
						ScaleType = Enum.ScaleType.Tile,
						BorderColor3 = rgb(0, 0, 0),
						Image = "rbxassetid://18274452449",
						BackgroundTransparency = 1,
						Name = "alphaind",
						Size = dim2(1, 0, 1, 0),
						TileSize = dim2(0, 6, 0, 6),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = alphaind,
						Transparency = numseq{
							numkey(0, 0),
							numkey(1, 1)
						}
					})
					
					local alpha_picker = library:create("Frame", {
						Parent = alpha_drag,
						Name = "alpha_picker",
						BorderMode = Enum.BorderMode.Inset,
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(0, 4, 1, 0),
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local hue = library:create("TextButton", {
						Parent = main_holder_background,
						AnchorPoint = vec2(1, 0),
						Name = "hue",
						Position = dim2(1, -1, 0, 0),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(0, 14, 1, -20),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline,
						Text = "",
						AutoButtonColor = false
					})
					
					local outline = library:create("Frame", {
						Parent = hue,
						Name = "outline",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					})
					
					local Frame = library:create("Frame", {
						Parent = outline,
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = Frame,
						Rotation = 270,
						Color = rgbseq{
							rgbkey(0, rgb(255, 0, 0)),
							rgbkey(0.17000000178813934, rgb(255, 255, 0)),
							rgbkey(0.33000001311302185, rgb(0, 255, 0)),
							rgbkey(0.5, rgb(0, 255, 255)),
							rgbkey(0.6700000166893005, rgb(0, 0, 255)),
							rgbkey(0.8299999833106995, rgb(255, 0, 255)),
							rgbkey(1, rgb(255, 0, 0))
						}
					}) 
					
					local hue_picker = library:create("Frame", {
						Parent = Frame,
						Name = "hue_picker",
						BorderMode = Enum.BorderMode.Inset,
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 0, 4),
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local visualize = library:create("Frame", {
						Parent = main_holder_background,
						AnchorPoint = vec2(1, 1),
						Name = "visualize",
						Position = dim2(1, -1, 1, -1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(0, 14, 0, 14),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					}) library:apply_theme(visualize, "inline", "BackgroundColor3") 
					
					local outline = library:create("Frame", {
						Parent = visualize,
						Size = dim2(1, -2, 1, -2),
						Name = "outline",
						Active = true,
						BorderColor3 = rgb(0, 0, 0),
						Position = dim2(0, 1, 0, 1),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					}) library:apply_theme(outline, "outline", "BackgroundColor3") 
					
					local visualize = library:create("Frame", {
						Parent = outline,
						Size = dim2(1, -2, 1, -2),
						Name = "visualize",
						Active = true,
						BorderColor3 = rgb(0, 0, 0),
						Position = dim2(0, 1, 0, 1),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(0, 221, 255)
					})
					
					local satval_picker = library:create("Frame", {
						Parent = main_holder_background,
						Name = "satval_picker",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -20, 1, -20),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					}) library:apply_theme(satval_picker, "inline", "BackgroundColor3") 
					
					local outline = library:create("Frame", {
						Parent = satval_picker,
						Name = "outline",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					}) library:apply_theme(outline, "outline", "BackgroundColor3") 
					
					local colorpicker = library:create("Frame", {
						Parent = outline,
						Name = "colorpicker",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(0, 221, 255)
					})
					
					local sat = library:create("TextButton", {
						Parent = colorpicker,
						Name = "sat",
						Size = dim2(1, 0, 1, 0),
						BorderColor3 = rgb(0, 0, 0),
						ZIndex = 2,
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255),
						Text = "",
						AutoButtonColor = false,
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = sat,
						Rotation = 270,
						Transparency = numseq{
							numkey(0, 0),
							numkey(1, 1)
						},
						Color = rgbseq{
							rgbkey(0, rgb(0, 0, 0)),
							rgbkey(1, rgb(0, 0, 0))
						}
					})
					
					local val = library:create("TextButton", {
						Parent = colorpicker,
						Name = "val",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 1, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255),
						Text = "",
						AutoButtonColor = false,
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = val,
						Transparency = numseq{
							numkey(0, 0),
							numkey(1, 1)
						}
					})
					
					local satval_picker_REAL = library:create("Frame", {
						Parent = colorpicker,
						Name = "satval_picker_REAL",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(0, 2, 0, 2),
						BorderSizePixel = 1,
						BackgroundColor3 = rgb(255, 255, 255),
						ZIndex = 3, 
					})
				-- // 
					
				function cfg.set_visible(bool)
					colorpicker_holder.Visible = bool

					if bool then 
						if library.current_element_open and library.current_element_open ~= cfg then 
							library.current_element_open.set_visible(false)
							library.current_element_open.open = false 
						end

						library.current_element_open = cfg
						colorpicker_holder.Position = dim2(0, colorpicker_button.AbsolutePosition.X + 1, 0, colorpicker_button.AbsolutePosition.Y + 17)
					end
				end 

				colorpicker_button.MouseButton1Click:Connect(function()		
					cfg.open = not cfg.open

					cfg.set_visible(cfg.open) 
				end)

				function cfg.set(color, alpha)
					if color then 
						h, s, v = color:ToHSV()
					end 
				
					if alpha then 
						a = alpha
					end 
				
					local hsv_position = Color3.fromHSV(h, s, v)
					local Color = Color3.fromHSV(h, s, v)
					
					local value = 1 - h
					local offset = (value < 1) and 0 or -4
					hue_picker.Position = dim2(0, 0, value, offset)

					local offset = (a < 1) and 0 or -4
					alpha_picker.Position = dim2(a, offset, 0, 0)

					alpha_drag.BackgroundColor3 = Color3.fromHSV(h, s, v)
					
					visualize.BackgroundColor3 = Color
					handler.BackgroundColor3 = Color 

					colorpicker.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
					
					cfg.color = Color
					cfg.alpha = a
					
					local s_offset = (s < 1) and 0 or -3
					local v_offset = (1 - v < 1) and 0 or -3
					satval_picker_REAL.Position = dim2(s, s_offset, 1 - v, v_offset)

					flags[cfg.flag] = {} 
					flags[cfg.flag]["Color"] = Color
					flags[cfg.flag]["Transparency"] = a
				
					cfg.callback(Color, a)
				end

				function cfg.update_color() 
					local mouse = uis:GetMouseLocation() 

					if dragging_sat then	
						s = math.clamp((vec2(mouse.X, mouse.Y - gui_offset) - val.AbsolutePosition).X / val.AbsoluteSize.X, 0, 1)
						v = 1 - math.clamp((vec2(mouse.X, mouse.Y - gui_offset) - sat.AbsolutePosition).Y / sat.AbsoluteSize.Y, 0, 1)
					elseif dragging_hue then 
						h = math.clamp(1 - (vec2(mouse.X, mouse.Y - gui_offset) - hue.AbsolutePosition).Y / hue.AbsoluteSize.Y, 0, 1)
					elseif dragging_alpha then 
						a = math.clamp((vec2(mouse.X, mouse.Y - gui_offset) - alpha.AbsolutePosition).X / alpha.AbsoluteSize.X, 0, 1)
					end

					cfg.set(nil, nil)
				end
				
				alpha.MouseButton1Down:Connect(function()
					dragging_alpha = true 
				end)

				hue.MouseButton1Down:Connect(function()
					dragging_hue = true 
				end)

				sat.MouseButton1Down:Connect(function()
					dragging_sat = true  
				end)

				uis.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging_sat = false
						dragging_hue = false
						dragging_alpha = false 
					end
				end)

				uis.InputChanged:Connect(function(input)
					if (dragging_sat or dragging_hue or dragging_alpha) and input.UserInputType == Enum.UserInputType.MouseMovement then
						cfg.update_color() 
					end
				end)	

				task.spawn(function()
					while true do 
						task.wait()
						if flags[cfg.flag .. "_RAINBOW_FLAG"] then 
							cfg.set(
								hsv(math.abs(math.sin(tick())), 
								s, 
								v
							), a) 
						end     
					end     
				end)

				cfg.set(cfg.color, cfg.alpha)

				library.config_flags[cfg.flag] = cfg.set
			
				return setmetatable(cfg, library) 
			end

			function library:keybind(options)
				local parent = self.right_holder

				local cfg = {
					flag = options.flag or "SET ME A FLAG NOWWW!!!!",
					callback = options.callback or function() end,
					open = false,
					binding = nil, 
					name = options.name or nil, 
					ignore_key = options.ignore or false, 

					key = options.key or nil, 
					mode = options.mode or "toggle",
					active = options.default or false, 

					hold_instances = {},
				}

				flags[cfg.flag] = {} 
				
				local KEYBIND_ELEMENT;
				if cfg.name then 
					KEYBIND_ELEMENT = library:create("TextLabel", {
						Parent = library.keybind_list,
						Name = "",
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "[ Hold ]  Fly - X",
						Size = dim2(1, -5, 0, 18),
						Visible = false, 
						Position = dim2(0, 5, 0, -1),
						BorderSizePixel = 0,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextSize = 12,
						BackgroundColor3 = themes.preset.text
					}, "text")
				end 

				local element_outline = library:create("TextButton", {
					Parent = parent,
					Name = "",
					BorderColor3 = rgb(0, 0, 0),
					Text = "", 
					Size = dim2(0, 24, 0, 14),
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundColor3 = themes.preset.outline
				}) library:apply_theme(element_outline, "outline", "BackgroundColor3")

				library:create("UIPadding", {
					Parent = element_outline,
					PaddingRight = dim(0, 2),
				})

				local instance = library:hoverify(element_outline, element_outline)
				instance.Size = dim2(1, 2, 1, 0)

				local inline = library:create("Frame", {
					Parent = element_outline,
					Name = "",
					Position = dim2(0, 1, 0, 1),
					BorderColor3 = rgb(0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.X,
					Size = dim2(1, -2, 1, -2),
					ZIndex = 2;
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.inline
				}) library:apply_theme(inline, "inline", "BackgroundColor3") 

				library:create("UIPadding", {
					Parent = inline,
					PaddingRight = dim(0, 2),
				})
				
				local handler = library:create("Frame", {
					Parent = inline,
					Name = "",
					ZIndex = 2;
					Position = dim2(0, 1, 0, 1),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, -2, 1, -2),
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundColor3 = rgb(255, 255, 255)
				})

				local UIGradient = library:create("UIGradient", {
					Parent = handler,
					Name = "",
					Rotation = 90,
					Color = rgbseq{
						rgbkey(0, rgb(41, 41, 55)),
						rgbkey(1, rgb(35, 35, 47))
					}
				}); library:apply_theme(UIGradient, "contrast", "Color") 
				
				local key_text = library:create("TextLabel", {
					Parent = handler,
					Name = "",
					FontFace = library.font,
					TextColor3 = themes.preset.text,
					BorderColor3 = rgb(0, 0, 0),
					ZIndex = 2;
					Text = "b",
					Size = dim2(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Position = dim2(0, 0, 0, -2),
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.XY,
					TextSize = 12,
					BackgroundColor3 = rgb(255, 255, 255)
				})

				library:create("UIPadding", {
					Parent = key_text,
					PaddingLeft = dim(0, 3),
					PaddingRight = dim(0, 2),
				})
				
				-- // mode selector
					local keybind_selector = library:create("Frame", {
						Parent = sgui,
						Name = "",
						Position = dim2(0, element_outline.AbsolutePosition.X + 1, 0, element_outline.AbsolutePosition.Y + 17),
						BorderColor3 = rgb(255, 255, 255),
						BorderSizePixel = 2,
						Visible = false, 
						AutomaticSize = Enum.AutomaticSize.XY,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					library:create("UIListLayout", {
						Parent = keybind_selector,
						Name = "",
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalFlex = Enum.UIFlexAlignment.Fill,
						Padding = dim(0, 2)
					})
					
					local hold_button = library:create("TextButton", {
						Parent = keybind_selector,
						Name = "",
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "hold",
						BackgroundTransparency = 1,
						AutomaticSize = Enum.AutomaticSize.XY,
						BorderSizePixel = 0,
						ZIndex = 2,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					library:create("UIStroke", {
						Parent = hold_button,
						Name = "",
						LineJoinMode = Enum.LineJoinMode.Miter
					})
					
					library:create("UIPadding", {
						Parent = keybind_selector,
						Name = "",
						PaddingTop = dim(0, 3),
						PaddingBottom = dim(0, 5),
						PaddingRight = dim(0, 5),
						PaddingLeft = dim(0, 5)
					})
					
					local toggle_button = library:create("TextButton", {
						Parent = keybind_selector,
						Name = "",
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "toggle",
						BackgroundTransparency = 1,
						AutomaticSize = Enum.AutomaticSize.XY,
						BorderSizePixel = 0,
						ZIndex = 2,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					library:create("UIStroke", {
						Parent = toggle_button,
						Name = "",
						LineJoinMode = Enum.LineJoinMode.Miter
					})
					
					local always_button = library:create("TextButton", {
						Parent = keybind_selector,
						Name = "",
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "always",
						BackgroundTransparency = 1,
						AutomaticSize = Enum.AutomaticSize.XY,
						BorderSizePixel = 0,
						ZIndex = 2,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					library:create("UIStroke", {
						Parent = always_button,
						Name = "",
						LineJoinMode = Enum.LineJoinMode.Miter
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = keybind_selector,
						Name = "",
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(41, 41, 55)),
							rgbkey(1, rgb(35, 35, 47))
						}
					}); library:apply_theme(UIGradient, "contrast", "Color")
					
					local UIStroke = library:create("UIStroke", {
						Parent = keybind_selector,
						Name = "",
						Color = themes.preset.inline,
						LineJoinMode = Enum.LineJoinMode.Miter,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					})
				-- // 

				-- // init 
					function cfg.set_visible(bool)
						keybind_selector.Visible = bool
						keybind_selector.Position = dim2(0, element_outline.AbsolutePosition.X + 1, 0, element_outline.AbsolutePosition.Y + 17)

						if bool then 
							if library.current_element_open and library.current_element_open ~= cfg then 
								library.current_element_open.set_visible(false)
								library.current_element_open.open = false 
							end

							library.current_element_open = cfg 
						end
					end 

					function cfg.set_mode(mode) 
						cfg.mode = mode 

						if mode == "always" then
							cfg.set(true)
						elseif mode == "hold" then
							cfg.set(false)
						end

						flags[cfg.flag]["mode"] = mode
					end 

					function cfg.set(input)
						if type(input) == "boolean" then 
							local __cached = input 

							if cfg.mode == "always" then 
								__cached = true 
							end 

							cfg.active = __cached 
							flags[cfg.flag]["active"] = __cached 
							cfg.callback(__cached)
						elseif tostring(input):find("Enum") then 
							input = input.Name == "Escape" and "none" or input
							
							cfg.key = input or "none"	

							local _text = keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")
							local _text2 = (tostring(_text):gsub("KeyCode.", ""):gsub("UserInputType.", "")) or "none"
							cfg.key_name = _text2

							flags[cfg.flag]["mode"] = cfg.mode 
							flags[cfg.flag]["key"] = cfg.key 

							key_text.Text = string.lower(_text2)

							cfg.callback(cfg.active or false)
						elseif find({"toggle", "hold", "always"}, input) then 
							cfg.set_mode(input)

							if input == "always" then 
								cfg.active = true 
							end 

							cfg.callback(cfg.active or false)
						elseif type(input) == "table" then 
							input.key = type(input.key) == "string" and input.key ~= "none" and library:convert_enum(input.key) or input.key

							input.key = input.key == Enum.KeyCode.Escape and "none" or input.key
							cfg.key = input.key or "none"
							
							cfg.mode = input.mode or "toggle"

							if input.active then
								cfg.active = input.active
							end

							local text = tostring(cfg.key) ~= "Enums" and (keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")) or nil
							local __text = text and (tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", ""))
							
							key_text.Text = string.lower(__text) or "none"
							cfg.key_name = __text
						end 

						flags[cfg.flag] = {
							mode = cfg.mode,
							key = cfg.key, 
							active = cfg.active
						}
						
						if cfg.name then 
							KEYBIND_ELEMENT.Visible = cfg.active

							library:tween(KEYBIND_ELEMENT, {
								TextTransparency = cfg.active and 0 or 1, 
							}) 

							library:tween(KEYBIND_ELEMENT:FindFirstChildOfClass("UIStroke"), {
								Transparency = cfg.active and 0 or 1, 
							}) 
							
							local text = tostring(cfg.key) ~= "Enums" and (keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")) or nil
							local __text = text and (tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", ""))

							if cfg.name then 
								KEYBIND_ELEMENT.Text = "[ " .. string.upper(string.sub(cfg.mode, 1, 1)) .. string.sub(cfg.mode, 2) .. " ] " .. cfg.name .. " - " .. __text
							end
						end
					end


					-- // ok bro its 30 april2025.. what is this code from october 2024 💀💀
					hold_button.MouseButton1Click:Connect(function()
						cfg.set_mode("hold") 
						cfg.set_visible(false)
						cfg.open = false 
					end) 

					toggle_button.MouseButton1Click:Connect(function()
						cfg.set_mode("toggle") 
						cfg.set_visible(false)
						cfg.open = false 
					end) 

					always_button.MouseButton1Click:Connect(function()
						cfg.set_mode("always") 
						cfg.set_visible(false)
						cfg.open = false 
					end) 
					
					element_outline.MouseButton2Click:Connect(function()
						cfg.open = not cfg.open 

						cfg.set_visible(cfg.open)
					end)

					element_outline.MouseButton1Down:Connect(function()
						task.wait()
						key_text.Text = "none"	

						if cfg.binding then return end 

						cfg.binding = library:connection(uis.InputBegan, function(input, game_event)  
							local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType

							cfg.set(selected_key)

							cfg.binding:Disconnect() 
							cfg.binding = nil
						end)
					end)

					library:connection(uis.InputBegan, function(input, game_event) 
						local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType

						if not game_event then 
							if selected_key == cfg.key then 
								if cfg.mode == "toggle" then 
									cfg.active = not cfg.active
									cfg.set(cfg.active)
								elseif cfg.mode == "hold" then 
									cfg.set(true)
								end
							end
						end
					end)

					library:connection(uis.InputEnded, function(input, game_event) 
						if game_event then 
							return 
						end 

						local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
			
						if selected_key == cfg.key then
							if cfg.mode == "hold" then 
								cfg.set(false)
							end
						end
					end)
			
					cfg.set({mode = cfg.mode, active = cfg.active, key = cfg.key})
			
					library.config_flags[cfg.flag] = cfg.set
				-- // 
				
				library.config_flags[cfg.flag] = cfg.set

				return setmetatable(cfg, library) 
			end 

			function library:dropdown(options)
				local parent = self.holder 

				local cfg = {
					name = options.name or nil,
					flag = options.flag or tostring(random(1,9999999)),

					items = options.items or {"1", "2", "3"},
					callback = options.callback or function() end,
					multi = options.multi or false, 
					visible = options.visible or true,

					open = false, 
					option_instances = {}, 
					multi_items = {}, 
					scrolling = options.scrolling or false, 
					ignore = options.ignore or nil,
				}

				cfg.default = options.default or (cfg.multi and {cfg.items[1]}) or cfg.items[1] or nil

				-- // dropdown elements
					local dropdown_REAL = library:create("TextLabel", {
						Parent = parent,
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "",
						Name = "dropdown",
						ZIndex = 2,
						Size = dim2(1, -8, 0, 12),
						BorderSizePixel = 0,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})

					local main_text      
					if cfg.name then 
						local left_components = library:create("Frame", {
							Parent = dropdown_REAL,
							Name = "left_components",
							BackgroundTransparency = 1,
							Position = dim2(0, 2, 0, -1),
							BorderColor3 = rgb(0, 0, 0),
							Size = dim2(0, 0, 0, 14),
							BorderSizePixel = 0,
							BackgroundColor3 = rgb(255, 255, 255)
						})

						main_text = library:create("TextLabel", {
							Parent = left_components,
							FontFace = library.font,
							TextColor3 = themes.preset.text,
							BorderColor3 = rgb(0, 0, 0),
							Text = cfg.name,
							Name = "text",
							BackgroundTransparency = 1,
							Size = dim2(0, 0, 1, -1),
							BorderSizePixel = 0,
							AutomaticSize = Enum.AutomaticSize.X,
							TextSize = 12,
							BackgroundColor3 = rgb(255, 255, 255)
						})
						
						library:create("UIStroke", {
							Parent = main_text,
							LineJoinMode = Enum.LineJoinMode.Miter
						})
						
						library:create("UIListLayout", {
							Parent = left_components,
							Padding = dim(0, 5),
							Name = "_",
							FillDirection = Enum.FillDirection.Horizontal
						})

						local right_components = library:create("Frame", {
							Parent = dropdown_REAL,
							Name = "right_components",
							Position = dim2(1, -1, 0, 1),
							BorderColor3 = rgb(0, 0, 0),
							Size = dim2(0, 0, 0, 12),
							BorderSizePixel = 0,
							BackgroundColor3 = rgb(255, 255, 255)
						})
						cfg["right_holder"] = right_components
			
						local list = library:create("UIListLayout", {
							Parent = right_components,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalAlignment = Enum.HorizontalAlignment.Right,
							Padding = dim(0, 4),
							Name = "list",
							SortOrder = Enum.SortOrder.LayoutOrder
						})
					end 

					local bottom_components = library:create("Frame", {
						Parent = dropdown_REAL,
						Name = "bottom_components",
						Position = dim2(0, 0, 0, cfg.name and 15 or 0),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 26, 0, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local dropdown = library:create("TextButton", {
						Parent = bottom_components,
						Name = "dropdown",
						Position = dim2(0, 0, 0, 2),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -27, 1, 18),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline,
						Text = "",
						AutoButtonColor = false, 
					}) library:apply_theme(dropdown, "outline", "BackgroundColor3") 
					
					library:hoverify(dropdown_REAL, dropdown)

					local inline = library:create("Frame", {
						Parent = dropdown,
						Name = "inline",
						ZIndex = 2;
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					}) library:apply_theme(inline, "inline", "BackgroundColor3") 
					
					local background = library:create("Frame", {
						Parent = inline,
						Name = "background",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						ZIndex = 2;
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.accent
					}) library:apply_theme(background, "accent", "BackgroundColor3") 
					
					local contrast = library:create("Frame", {
						Parent = background,
						Name = "contrast",
						ZIndex = 2;
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 1, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})

					local plus = library:create("TextLabel", {
						Parent = contrast,
						TextWrapped = true,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						ZIndex = 2;
						Text = "+",
						Name = "plus",
						Size = dim2(1, -4, 1, 0),
						Position = dim2(0, 0, 0, -1),
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Right,
						FontFace = library.font,
						TextTruncate = Enum.TextTruncate.AtEnd,
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					library:create("UIStroke", {
						Parent = plus,
						LineJoinMode = Enum.LineJoinMode.Miter
					})
					
					local text = library:create("TextLabel", {
						Parent = contrast,
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						ZIndex = 2;
						BorderColor3 = rgb(0, 0, 0),
						Text = "aa",
						Name = "text",
						Size = dim2(1, -4, 1, 0),
						Position = dim2(0, 4, 0, -1),
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						BorderSizePixel = 0,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					library:create("UIStroke", {
						Parent = text,
						LineJoinMode = Enum.LineJoinMode.Miter
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = contrast,
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(41, 41, 55)),
							rgbkey(1, rgb(35, 35, 47))
						}
					}) library:apply_theme(UIGradient, "contrast", "Color") 
					
					local UIGradient = library:create("UIGradient", {
						Parent = background,
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(255, 255, 255)),
							rgbkey(1, rgb(167, 167, 167))
						}
					}) library:apply_theme(UIGradient, "contrast", "Color") 
					
					library:create("UIListLayout", {
						Parent = bottom_components,
						Padding = dim(0, 10),
						Name = "_",
						SortOrder = Enum.SortOrder.LayoutOrder
					})     
				-- //

				-- // dropdown holder
					local dropdown_holder = library:create("Frame", {
						Parent = sgui,
						BorderColor3 = rgb(0, 0, 0),
						Name = "dropdown_holder",
						BackgroundTransparency = 1,
						Position = dim2(0, dropdown.AbsolutePosition.X + 1, 0, dropdown.AbsolutePosition.Y + 22),
						Size = dim2(0, dropdown.AbsoluteSize.X, 0, cfg.scrolling and 180 or 0),
						BorderSizePixel = 0,
						AutomaticSize = cfg.scrolling and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
						BackgroundColor3 = themes.preset.outline,
						Visible = false
					})
					
					local inline = library:create("Frame", {
						Parent = dropdown_holder,
						Size = dim2(1, -2, 1, 2),
						Name = "inline",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						ZIndex = 2,
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					}) library:apply_theme(inline, "inline", "BackgroundColor3") 
					
					local background; 
					if not cfg.scrolling then 
						background = library:create("Frame", {
							Parent = inline,
							BorderColor3 = rgb(0, 0, 0),
							Name = "background",
							BackgroundTransparency = 1,
							Position = dim2(0, 1, 0, 1),
							Size = dim2(1, -2, 1, 1),
							ZIndex = 2,
							BorderSizePixel = 0,
							BackgroundColor3 = themes.preset.accent
						})
						library:apply_theme(background, "accent", "BackgroundColor3") 
					else 
						background = library:create("ScrollingFrame", {
							Parent = inline,
							BorderColor3 = rgb(0, 0, 0),
							Name = "background",
							BackgroundTransparency = 1,
							MidImage = "rbxassetid://103468666327206",
							TopImage = "rbxassetid://103468666327206",
							BottomImage = "rbxassetid://103468666327206",
							Position = dim2(0, 1, 0, 1),
							Size = dim2(1, -2, 1, 1),
							ZIndex = 2,
							BorderSizePixel = 0,
							BackgroundColor3 = themes.preset.accent,
							CanvasSize = dim2(0, 0, 0, 0),
							AutomaticCanvasSize = Enum.AutomaticSize.Y,
							ScrollBarThickness = 2,
							ScrollBarImageColor3 = themes.preset.accent
						})
						library:apply_theme(background, "accent", "BackgroundColor3") 
						library:apply_theme(background, "accent", "ScrollBarImageColor3") 
					end 
					
					local contrast = library:create("Frame", {
						Parent = background,
						Name = "contrast",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 1, -3),
						BorderSizePixel = 0,
						ZIndex = 2, 
						BackgroundColor3 = rgb(255, 255, 255),
						AutomaticSize = cfg.scrolling and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
					}); 

					library:create("UIPadding", {
						Parent = contrast,
						PaddingTop = dim(0, 2),
						PaddingBottom = dim(0, 2),
						PaddingRight = dim(0, 0),
						PaddingLeft = dim(0, 4)
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = contrast,
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(41, 41, 55)),
							rgbkey(1, rgb(35, 35, 47))
						}
					}) library:apply_theme(UIGradient, "contrast", "Color") 
				
					library:create("UIListLayout", {
						Parent = contrast,
						Padding = dim(0, 5),
						SortOrder = Enum.SortOrder.LayoutOrder
					}) library:apply_theme(UIGradient, "contrast", "Color") 
					
					local UIGradient = library:create("UIGradient", {
						Parent = background,
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(255, 255, 255)),
							rgbkey(1, rgb(167, 167, 167))
						}
					}) library:apply_theme(UIGradient, "contrast", "Color") 
					
					local stroke = library:create("UIStroke", {
						Parent = inline,
						Color = themes.preset.outline,
						LineJoinMode = Enum.LineJoinMode.Miter
					}) library:apply_theme(stroke, "outline", "Color") 
				-- // 
					
				function cfg.set_element_visible(bool)
					dropdown_REAL.Visible = bool 

					if main_text then 
						main_text.Visible = bool
					end 
				end 

				function cfg.set_visible(bool) 
					library.current_element_open = cfg.ignore or cfg

					dropdown_holder.Visible = bool

					plus.Text = bool and "-" or "+"
					plus.TextSize = bool and 12 or 8

					if bool then 
						if library.current_element_open and library.current_element_open ~= cfg and not cfg.ignore then 
							library.current_element_open.set_visible(false)
							library.current_element_open.open = false 
						end

						dropdown_holder.Size = dim2(0, dropdown.AbsoluteSize.X, 0, dropdown_holder.Size.Y.Offset)
						dropdown_holder.Position = dim2(0, dropdown.AbsolutePosition.X + 1, 0, dropdown.AbsolutePosition.Y + 22)                    
					end
				end

				function cfg.set(value) 
					local selected = {}

					local is_table = type(value) == "table"

					for _,v in next, cfg.option_instances do 
						if v.Text == value or (is_table and find(value, v.Text)) then 
							insert(selected, v.Text)
							cfg.multi_items = selected
							v.TextColor3 = themes.preset.accent
						else 
							v.TextColor3 = themes.preset.text
						end
					end

					text.Text = is_table and concat(selected, ", ") or selected[1] or "nun"
					flags[cfg.flag] = is_table and selected or selected[1]
					cfg.callback(flags[cfg.flag]) 
				end
				
				function cfg:refresh_options(refreshed_list) 
					for _, v in next, cfg.option_instances do 
						v:Destroy() 
					end

					cfg.option_instances = {} 

					for i,v in next, refreshed_list do 
						local TextButton = library:create("TextButton", {
							Parent = contrast,
							FontFace = library.font,
							TextColor3 = themes.preset.text,
							BorderColor3 = rgb(0, 0, 0),
							Size = dim2(1, 0, 0, 0),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							TextWrapped = true,
							AutomaticSize = Enum.AutomaticSize.Y,
							TextSize = 12,
							TextXAlignment = Enum.TextXAlignment.Left,
							ZIndex = 2, 
							Text = v,
							BackgroundColor3 = rgb(255, 255, 255)
						}) library:apply_theme(TextButton, "accent", "TextColor3") 
						
						library:create("UIStroke", {
							Parent = TextButton,
							LineJoinMode = Enum.LineJoinMode.Miter
						})

						insert(cfg.option_instances, TextButton)

						TextButton.MouseButton1Down:Connect(function()
							if cfg.multi then 
								local selected_index = find(cfg.multi_items, TextButton.Text)

								if selected_index then 
									remove(cfg.multi_items, selected_index)
								else
									insert(cfg.multi_items, TextButton.Text)
								end

								cfg.set(cfg.multi_items) 				
							else 
								cfg.set_visible(false)
								cfg.open = false 

								cfg.set(TextButton.Text)
							end
						end)
					end
				end

				dropdown.MouseButton1Click:Connect(function()
					cfg.open = not cfg.open 

					cfg.set_visible(cfg.open)
				end)

				cfg:refresh_options(cfg.items) 

				cfg.set(cfg.default)
				
				library.config_flags[cfg.flag] = cfg.set
				library.visible_flags[cfg.flag] = cfg.set_element_visible

				cfg.set_element_visible(cfg.visible)

				return setmetatable(cfg, library)
			end 

			function library:list(options)
				local cfg = {
					callback = options and options.callback or function() end, 

					scale = options.size or 232, 
					items = options.items or {"1", "2", "3"}, 
					-- // order = options.order or 1, 
					placeholdertext = options.placeholder or options.placeholdertext or "search here...",
					visible = options.visible or true,

					option_instances = {}, 
					current_instance = nil, 
					flag = options.flag or "SET A FLAG U NIGGER", 

				} 

				-- // instances 
					local list_holder = library:create("TextLabel", {
						Parent = self.holder,
						Name = "",
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "",
						ZIndex = 2,
						Size = dim2(1, -8, 0, 12),
						BorderSizePixel = 0,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local UIPadding = library:create("UIPadding", {
						Parent = list_holder,
						Name = "",
						PaddingLeft = dim(0, 1)
					})
					
					local UIStroke = library:create("UIStroke", {
						Parent = list_holder,
						Name = ""
					})
					
					local bottom_components = library:create("Frame", {
						Parent = list_holder,
						Name = "",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 26, 0, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					library:create("UIListLayout", {
						Parent = bottom_components,
						Name = "",
						Padding = dim(0, 10),
						SortOrder = Enum.SortOrder.LayoutOrder
					})
					
					local list = library:create("Frame", {
						Parent = bottom_components,
						Name = "",
						Position = dim2(0, 0, 0, 2),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -27, 1, cfg.scale),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					}) library:apply_theme(main_holder, "outline", "BackgroundColor3") 
					
					local inline = library:create("Frame", {
						Parent = list,
						Name = "",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					}) library:apply_theme(inline, "inline", "BackgroundColor3") 
					
					local background = library:create("Frame", {
						Parent = inline,
						Name = "",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.accent
					}) library:apply_theme(background, "accent", "BackgroundColor3") 
					
					local UIGradient = library:create("UIGradient", {
						Parent = background,
						Name = "",
						Rotation = 90,
						Color = rgbseq{
						rgbkey(0, rgb(255, 255, 255)),
						rgbkey(1, rgb(167, 167, 167))
					}
					}) library:apply_theme(UIGradient, "contrast", "Color") 
					
					local contrast = library:create("Frame", {
						Parent = background,
						Name = "",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 1, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = contrast,
						Name = "",
						Rotation = 90,
						Color = rgbseq{
						rgbkey(0, rgb(41, 41, 55)),
						rgbkey(1, rgb(35, 35, 47))
					}
					}) library:apply_theme(UIGradient, "contrast", "Color") 
					
					local ScrollingFrame = library:create("ScrollingFrame", {
						Parent = contrast,
						Name = "",
						ScrollBarImageColor3 = themes.preset.accent,
						Active = true,
						MidImage = "rbxassetid://103468666327206",
						TopImage = "rbxassetid://103468666327206",
						BottomImage = "rbxassetid://103468666327206",
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						ScrollBarThickness = 2,
						BackgroundTransparency = 1,
						Size = dim2(1, 0, 1, 0),
						BackgroundColor3 = rgb(255, 255, 255),
						BorderColor3 = rgb(0, 0, 0),
						BorderSizePixel = 0,
						CanvasSize = dim2(0, 0, 0, 0)
					}) library:apply_theme(ScrollingFrame, "accent", "ScrollBarImageColor3") 
					
					local UIPadding = library:create("UIPadding", {
						Parent = ScrollingFrame,
						Name = "",
						PaddingBottom = dim(0, 4),
						PaddingTop = dim(0, 4)
					})
					
					local UIListLayout = library:create("UIListLayout", {
						Parent = ScrollingFrame,
						Name = "",
						Padding = dim(0, 4),
						SortOrder = Enum.SortOrder.LayoutOrder
					})
				-- //  

				function cfg.render_option(text) 
					local TextButton = library:create("TextButton", {
						Parent = ScrollingFrame,
						Name = "",
						Text = tostring(text),
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						BackgroundTransparency = 1,
						Size = dim2(1, 0, 0, 0),
						BorderSizePixel = 0,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})

					library:apply_theme(TextButton, "accent", "TextColor3") 

					local UIStroke = library:create("UIStroke", {
						Parent = TextButton,
						Name = ""
					})

					return TextButton 
				end 

				function cfg.set_element_visible(bool)
					list_holder.Visible = bool 
				end

				function cfg.refresh_options(options) 
					if type(options) == "function" then 
						return 
					end 

					for _, v in next, cfg.option_instances do 
						v:Destroy() 
					end 

					for _, option in next, options do 
						local button = cfg.render_option(option) 

						insert(cfg.option_instances, button)

						button.MouseButton1Click:Connect(function()
							if cfg.current_instance and cfg.current_instance ~= button then 
								cfg.current_instance.TextColor3 = themes.preset.text 
							end 

							cfg.current_instance = button 
							button.TextColor3 = themes.preset.accent 

							flags[cfg.flag] = button.text
							
							cfg.callback(button.text)
						end)
					end 
				end     

				function cfg.filter_options(text)
					for _, v in next, cfg.option_instances do 
						if string.find(v.Text, text) then 
							v.Visible = true 
						else 
							v.Visible = false
						end
					end
				end 

				function cfg.set(value)
					for _, buttons in next, cfg.option_instances do 
						if buttons.Text == value then 
							buttons.TextColor3 = themes.preset.accent 
						else 
							buttons.TextColor3 = themes.preset.text 
						end 
					end 

					flags[cfg.flag] = value
					cfg.callback(value)
				end 

				cfg.refresh_options(cfg.items) 
				cfg.set_element_visible(cfg.visible)

				library.visible_flags[cfg.flag] = cfg.set_element_visible
				library.config_flags[cfg.flag] = cfg.set

				return setmetatable(cfg, library)
			end 

			function library:textbox(options)
				local cfg = {
					placeholder = options.placeholder or options.placeholdertext or options.holder or options.holdertext or "type here...",
					default = options.default,
					flag = options.flag or "SET ME NIGGA",
					callback = options.callback or function() end,
					visible = options.visible or true,
				}
				
				-- // instances 
					local textbox_holder = library:create("TextLabel", {
						Parent = self.holder,
						Name = "",
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "",
						ZIndex = 2,
						Size = dim2(1, -8, 0, 12),
						BorderSizePixel = 0,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					library:create("UIPadding", {
						Parent = textbox_holder,
						Name = "",
						PaddingLeft = dim(0, 1)
					})
					
					library:create("UIStroke", {
						Parent = textbox_holder,
						Name = ""
					})
					
					local button = library:create("Frame", {
						Parent = textbox_holder,
						Name = "",
						Position = dim2(0, 0, 0, 2),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -27, 0, 18),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					})
					library:hoverify(textbox_holder, button)
					
					library:apply_theme(button, "outline", "BackgroundColor3") 
					
					local inline = library:create("Frame", {
						Parent = button,
						Name = "",
						Position = dim2(0, 1, 0, 1),
						ZIndex = 2;
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					})
					
					library:apply_theme(inline, "inline", "BackgroundColor3") 
					
					local background = library:create("Frame", {
						Parent = inline,
						Name = "",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						ZIndex = 2;
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.accent
					})
					
					library:apply_theme(background, "accent", "BackgroundColor3") 
					
					local TextBox = library:create("TextBox", {
						Parent = background,
						Name = "",
						CursorPosition = -1,
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "", 
						Size = dim2(1, 0, 1, 0),
						BorderSizePixel = 0,
						TextWrapped = true,
						BackgroundTransparency = 1,
						TextTruncate = Enum.TextTruncate.SplitWord,
						PlaceholderText = "Type here...",
						ClearTextOnFocus = false,
						ZIndex = 3;
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					library:create("UIStroke", {
						Parent = TextBox,
						Name = ""
					})
					
					local TextButton = library:create("TextButton", {
						Parent = background,
						Name = "",
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
						TextColor3 = rgb(0, 0, 0),
						BorderColor3 = rgb(0, 0, 0),
						Text = "",
						AutoButtonColor = false,
						Size = dim2(1, 0, 1, 0),
						BorderSizePixel = 0,
						TextSize = 14,
						ZIndex = 2;
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = TextButton,
						Name = "",
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(41, 41, 55)),
							rgbkey(1, rgb(35, 35, 47))
						}
					})
					
					library:apply_theme(UIGradient, "contrast", "Color") 
					
					library:create("UIListLayout", {
						Parent = textbox_holder,
						Name = "",
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalFlex = Enum.UIFlexAlignment.Fill,
						Padding = dim(0, 4),
						SortOrder = Enum.SortOrder.LayoutOrder
					})
						
					TextBox:GetPropertyChangedSignal("Text"):Connect(function()
						flags[cfg.flag] = TextBox.text
						cfg.callback(TextBox.text)
					end)
				-- // 

				function cfg.set_element_visible(bool)
					textbox_holder.Visible = bool 
				end

				function cfg.set(text) 
					flags[cfg.flag] = text
					TextBox.Text = text
					cfg.callback(text)
				end 

				if cfg.default then 
					cfg.set(cfg.default) 
				end 

				cfg.set_element_visible(cfg.visible)

				library.config_flags[cfg.flag] = cfg.set
				library.visible_flags[cfg.flag] = cfg.set_element_visible

				return setmetatable(cfg, library) 
			end 

			function library:button_holder(options) 
				local cfg = {
					flag = options.flag or "hi", 
					visible = options.visible or true,
				}

				local button_holder = library:create("TextLabel", {
					Parent = self.holder,
					Name = "",
					FontFace = library.font,
					TextColor3 = themes.preset.text,
					BorderColor3 = rgb(0, 0, 0),
					Text = "",
					ZIndex = 2,
					Size = dim2(1, -8, 0, 12),
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutomaticSize = Enum.AutomaticSize.Y,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextSize = 12,
					BackgroundColor3 = rgb(255, 255, 255), 
				})

				self.current_holder = button_holder

				-- // instances 
					library:create("UIStroke", {
						Parent = button_holder,
						Name = ""
					})
					
					library:create("UIListLayout", {
						Parent = button_holder,
						Name = "",
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalFlex = Enum.UIFlexAlignment.Fill,
						Padding = dim(0, 5),
						SortOrder = Enum.SortOrder.LayoutOrder
					})
				-- // 
				
				function cfg.set_element_visible(bool)
					button_holder.Visible = bool 
				end

				cfg.set_element_visible(cfg.visible)

				library.visible_flags[cfg.flag] = cfg.set_element_visible

				return setmetatable(cfg, library)
			end 

			function library:button(options)
				local cfg = {
					callback = options.callback or function() end, 
					name = options.text or options.name or "Button",
				}   

				local button = library:create("TextButton", {
					Parent = self.current_holder,
					Name = "",
					Position = dim2(0, 0, 0, 2),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, -27, 0, 18),
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.outline,
					Text = ""
				})

				library:hoverify(button, button)
				
				library:apply_theme(button, "outline", "BackgroundColor3") 
				
				local inline = library:create("Frame", {
					Parent = button,
					Name = "",
					ZIndex = 2;
					Position = dim2(0, 1, 0, 1),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, -2, 1, -2),
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.inline
				})
				
				library:apply_theme(inline, "inline", "BackgroundColor3") 
				
				local background = library:create("Frame", {
					Parent = inline,
					Name = "",
					ZIndex = 2;
					Position = dim2(0, 1, 0, 1),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, -2, 1, -2),
					BorderSizePixel = 0,
					BackgroundColor3 = themes.preset.accent
				})
				
				library:apply_theme(background, "accent", "BackgroundColor3") 
				
				local _UIGradient = library:create("UIGradient", {
					Parent = background,
					Name = "",
					Rotation = 90,
					Color = rgbseq{
						rgbkey(0, rgb(255, 255, 255)),
						rgbkey(1, rgb(167, 167, 167))
					}
				})
				
				library:apply_theme(_UIGradient, "contrast", "Color") 
				
				local contrast = library:create("Frame", {
					Parent = background,
					Name = "",
					ZIndex = 2;
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(1, 0, 1, 0),
					BorderSizePixel = 0,
					BackgroundColor3 = rgb(255, 255, 255)
				})
				
				local UIGradient = library:create("UIGradient", {
					Parent = contrast,
					Name = "",
					Rotation = 90,
					Color = rgbseq{
						rgbkey(0, rgb(41, 41, 55)),
						rgbkey(1, rgb(35, 35, 47))
					}
				})
				
				library:apply_theme(UIGradient, "contrast", "Color") 
				
				local text = library:create("TextLabel", {
					Parent = contrast,
					Name = "",
					TextWrapped = true,
					ZIndex = 2;
					TextColor3 = themes.preset.text,
					BorderColor3 = rgb(0, 0, 0),
					Text = cfg.name,
					Size = dim2(1, -4, 1, 0),
					Position = dim2(0, 4, 0, -1),
					BackgroundTransparency = 1,
					TextTruncate = Enum.TextTruncate.AtEnd,
					BorderSizePixel = 0,
					FontFace = library.font,
					TextSize = 12,
					BackgroundColor3 = rgb(255, 255, 255)
				})
				
				local UIStroke = library:create("UIStroke", {
					Parent = text,
					Name = "",
					LineJoinMode = Enum.LineJoinMode.Miter
				})

				button.MouseButton1Click:Connect(function()
					cfg.callback() 
				end)

				return setmetatable(cfg, library)
			end 

			function library:label(options)
				local cfg = {name = options.text or options.name or "Label"}

				local dropdown = library:create("TextLabel", {
					Parent = self.holder,
					Name = "",
					FontFace = library.font,
					TextColor3 = themes.preset.text,
					BorderColor3 = rgb(0, 0, 0),
					Text = "",
					ZIndex = 2,
					Size = dim2(1, -8, 0, 12),
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutomaticSize = Enum.AutomaticSize.Y,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextSize = 12,
					BackgroundColor3 = rgb(255, 255, 255)
				})
				
				local UIStroke = library:create("UIStroke", {
					Parent = dropdown,
					Name = ""
				})
				
				local left_components = library:create("Frame", {
					Parent = dropdown,
					Name = "",
					BackgroundTransparency = 1,
					Position = dim2(0, 2, 0, -1),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(0, 0, 0, 14),
					BorderSizePixel = 0,
					BackgroundColor3 = rgb(255, 255, 255)
				})
				
				local TextLabel = library:create("TextLabel", {
					Parent = left_components,
					Name = "",
					FontFace = library.font,
					TextColor3 = themes.preset.text,
					BorderColor3 = rgb(0, 0, 0),
					Text = cfg.name,
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.Y,
					TextSize = 12,
					BackgroundColor3 = rgb(255, 255, 255)
				})

				local right_components = library:create("Frame", {
					Parent = dropdown,
					Name = "right_components",
					Position = dim2(1, -1, 0, 1),
					BorderColor3 = rgb(0, 0, 0),
					Size = dim2(0, 0, 0, 12),
					BorderSizePixel = 0,
					BackgroundColor3 = rgb(255, 255, 255)
				}) cfg.right_holder = right_components

				local list = library:create("UIListLayout", {
					Parent = right_components,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = dim(0, 4),
					Name = "list",
					SortOrder = Enum.SortOrder.LayoutOrder
				})
				
				local UIStroke = library:create("UIStroke", {
					Parent = TextLabel,
					Name = ""
				})

				function cfg.set(text) 
					TextLabel.Text = text 
				end 
							
				return setmetatable(cfg, library)   
			end 

			function library:playerlist(options) 
				local cfg = {
					callback = options.callback or function() end, 

					labels = {
						name,
						display, 
						uid, 
					}
				}

				local selected_button; 

				local patterns = {
					["Priority"] = rgb(255, 255, 0),
					["Enemy"] = rgb(255, 0, 0),
					["Neutral"] = themes.preset.text,
					["Friendly"] = rgb(0, 255, 255)
				}

				-- // elements 
					local playerlist_holder = library:create("TextLabel", {
						Parent = self.holder,
						Name = "",
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "",
						ZIndex = 2,
						Size = dim2(1, -8, 0, 12),
						BorderSizePixel = 0,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local UIPadding = library:create("UIPadding", {
						Parent = playerlist_holder,
						Name = "",
						PaddingBottom = dim(0, -2),
						PaddingLeft = dim(0, 1)
					})
					
					local UIStroke = library:create("UIStroke", {
						Parent = playerlist_holder,
						Name = ""
					})
					
					local bottom_components = library:create("Frame", {
						Parent = playerlist_holder,
						Name = "",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 26, 0, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					library:create("UIListLayout", {
						Parent = bottom_components,
						Name = "",
						Padding = dim(0, 10),
						SortOrder = Enum.SortOrder.LayoutOrder
					})
					
					local list = library:create("Frame", {
						Parent = bottom_components,
						Name = "",
						Position = dim2(0, 0, 0, 2),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -27, 1, 232),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					}) library:apply_theme(list, "outline", "BackgroundColor3") 
					
					local inline = library:create("Frame", {
						Parent = list,
						Name = "",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.inline
					}) library:apply_theme(inline, "inline", "BackgroundColor3") 
					
					local background = library:create("Frame", {
						Parent = inline,
						Name = "",
						Position = dim2(0, 1, 0, 1),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, -2, 1, -2),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.accent
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = background,
						Name = "",
						Rotation = 90,
						Color = rgbseq{
							rgbkey(0, rgb(255, 255, 255)),
							rgbkey(1, rgb(167, 167, 167))
						}
					}); library:apply_theme(UIGradient, "contrast", "Color") 
					
					local contrast = library:create("Frame", {
						Parent = background,
						Name = "",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 1, 0),
						BorderSizePixel = 0,
						BackgroundColor3 = rgb(255, 255, 255)
					})
					
					local UIGradient = library:create("UIGradient", {
						Parent = contrast,
						Name = "",
						Rotation = 90,
						Color = rgbseq{
						rgbkey(0, rgb(41, 41, 55)),
						rgbkey(1, rgb(35, 35, 47))
					}
					}); library:apply_theme(UIGradient, "contrast", "Color") 
					
					local ScrollingFrame = library:create("ScrollingFrame", {
						Parent = contrast,
						Name = "",
						ScrollBarImageColor3 = themes.preset.accent,
						Active = true,
						MidImage = "rbxassetid://103468666327206",
						TopImage = "rbxassetid://103468666327206",
						BottomImage = "rbxassetid://103468666327206",
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						ScrollBarThickness = 2,
						BackgroundTransparency = 1,
						Size = dim2(1, 0, 1, 0),
						BackgroundColor3 = rgb(255, 255, 255),
						BorderColor3 = rgb(0, 0, 0),
						BorderSizePixel = 0,
						CanvasSize = dim2(0, 0, 0, 0)
					}) library:apply_theme(ScrollingFrame, "accent", "ScrollBarImageColor3") 
					
					local UIPadding = library:create("UIPadding", {
						Parent = ScrollingFrame,
						Name = "",
						PaddingTop = dim(0, 4),
						PaddingBottom = dim(0, 4),
						PaddingRight = dim(0, 4),
						PaddingLeft = dim(0, 4)
					})
					
					local UIListLayout = library:create("UIListLayout", {
						Parent = ScrollingFrame,
						Name = "",
						Padding = dim(0, 4),
						SortOrder = Enum.SortOrder.LayoutOrder
					})
				-- // 

				function cfg.create_player(player) 
					library.playerlist_data[tostring(player)] = {}
					local path = library.playerlist_data[tostring(player)]
					
					local TextButton = library:create("TextButton", {
						Parent = ScrollingFrame,
						Name = "",
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = "",
						BackgroundTransparency = 1,
						Size = dim2(1, 0, 0, 0),
						BorderSizePixel = 0,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})

					local player_name = library:create("TextLabel", {
						Parent = TextButton,
						FontFace = library.font,
						TextColor3 = themes.preset.text,
						BorderColor3 = rgb(0, 0, 0),
						Text = tostring(player),
						BorderSizePixel = 0,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextSize = 12,
						LayoutOrder = -100, 
						BackgroundColor3 = rgb(255, 255, 255)
					})
					library:apply_theme(player_name, "text", "TextColor3") 
					library:apply_theme(player_name, "accent", "TextColor3") 
									
					-- // local TextLabel = library:create("TextLabel", {
					-- //     Parent = TextButton,
					-- //     Name = "",
					-- //     FontFace = library.font,
					-- //     TextColor3 = themes.preset.text,
					-- //     BorderColor3 = rgb(0, 0, 0),
					-- //     Text = "None",
					-- //     BackgroundTransparency = 1,
					-- //     TextXAlignment = Enum.TextXAlignment.Left,
					-- //     BorderSizePixel = 0,
					-- //     AutomaticSize = Enum.AutomaticSize.Y,
					-- //     TextSize = 12,
					-- //     BackgroundColor3 = rgb(255, 255, 255)
					-- // })
									
					-- // local Frame = library:create("Frame", {
					-- //     Parent = TextLabel,
					-- //     Name = "",
					-- //     Position = dim2(0, -10, 0, 0),
					-- //     BorderColor3 = rgb(0, 0, 0),
					-- //     Size = dim2(0, 1, 0, 12),
					-- //     BorderSizePixel = 0,
					-- //     BackgroundColor3 = themes.preset.outline
					-- // }) library:apply_theme(main_holder, "outline", "BackgroundColor3") 
					
					local priority_text = library:create("TextLabel", {
						Parent = TextButton,
						Name = "",
						FontFace = library.font,
						TextColor3 = tostring(player) ~= lp.Name and themes.preset.text or rgb(0, 0, 255),
						BorderColor3 = rgb(0, 0, 0),
						Text = tostring(player) ~= lp.Name and "Neutral" or "LocalPlayer",
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						BorderSizePixel = 0,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextSize = 12,
						BackgroundColor3 = rgb(255, 255, 255)
					})

					local Frame = library:create("Frame", {
						Parent = priority_text,
						Name = "",
						Position = dim2(0, -10, 0, 0),
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(0, 1, 0, 12),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					}) library:apply_theme(main_holder, "outline", "BackgroundColor3") 
					
					local UIListLayout = library:create("UIListLayout", {
						Parent = TextButton,
						Name = "",
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalFlex = Enum.UIFlexAlignment.Fill,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalFlex = Enum.UIFlexAlignment.Fill
					})
					
					local UIPadding = library:create("UIPadding", {
						Parent = TextButton,
						Name = "",
						PaddingRight = dim(0, 2),
						PaddingLeft = dim(0, 2)
					})

					local line = library:create("Frame", {
						Parent = ScrollingFrame,
						Name = "",
						BorderColor3 = rgb(0, 0, 0),
						Size = dim2(1, 0, 0, 1),
						BorderSizePixel = 0,
						BackgroundColor3 = themes.preset.outline
					}) library:apply_theme(main_holder, "outline", "BackgroundColor3") 

					path.instance = TextButton 
					path.line = line 
					path.priority = "Neutral"
					path.priority_text = priority_text
					-- // library.selected_player = players[tostring(player)]
					
					TextButton.MouseButton1Click:Connect(function()
						if player_name == lp.Name then 
							return 
						end 

						if selected_button then 
							selected_button.TextColor3 = themes.preset.text 
							selected_button = nil 
						end     

						selected_button = player_name 
						player_name.TextColor3 = themes.preset.accent 

						library.selected_player = player_name.Text
						library.config_flags["PLAYERLIST_DROPDOWN"](path.priority_text.Text)

						if cfg.labels.name then 
							cfg.labels.name.set("User: " .. player_name.Text)
							cfg.labels.display.set("DisplayName: " .. players[player_name.Text].DisplayName)
							cfg.labels.uid.set("User Id: " .. players[player_name.Text].UserId)
						end
					end)

					return path 
				end 

				function cfg.search(text)
					for _, player in next, players:GetPlayers() do 
						local name = tostring(player)
						local path = library.playerlist_data[name]

						if path then 
							local sanity = string.lower(name):match(string.lower(text)) and true or false
							path.instance.Visible = sanity
							path.line.Visible = sanity
						end 
					end 
				end 

				function cfg.remove_player(player) 
					local path = library.playerlist_data[tostring(player)]
					path.instance:Destroy() 
					path.line:Destroy() 
					path = nil 
				end 

				function library.prioritize(text) 
					if not library.selected_player then 
						return 
					end 

					local path = library.playerlist_data[library.selected_player]
					path.priority_text.Text = text
					path.priority_text.TextColor3 = patterns[text]
					path.priority = text
				end 

				function library.get_priority(player) 
					local path = library.playerlist_data[tostring(player)]

					if path then 
						return path.priority
					end 
				end 

				players.PlayerAdded:Connect(cfg.create_player)
				players.PlayerRemoving:Connect(cfg.remove_player)
				
				for _, player in players:GetPlayers() do 
					local player_object = cfg.create_player(player.Name)
					insert(library.playerlist_data, player_object)
				end 

				self:textbox({name = "Search", callback = function(txt)
					cfg.search(txt)
				end})
				cfg.labels.name = self:label({name = "Name: ??"})
				cfg.labels.display = self:label({name = "Display Name: ??"})
				cfg.labels.uid = self:label({name = "User Id: ??"})

				return setmetatable(cfg, library)
			end 
		-- // 
	-- // 
	-- //#endregion
end)()

local Tween = loadstring(game:HttpGet("https://raw.githubusercontent.com/JuixyV2/utils/main/tween.lua", true))();
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer.Character

if not LPH_OBFUSCATED then
    LPH_JIT = function(...) return ... end
    LPH_JIT_MAX = function(...) return ... end
    LPH_JIT_ULTRA = function(...) return ... end
    LPH_NO_VIRTUALIZE = function(...) return ... end
    LPH_NO_UPVALUES = function(f) return(function(...) return f(...) end) end
    LPH_ENCSTR = function(...) return ... end
    LPH_STRENC = function(...) return ... end
    LPH_HOOK_FIX = function(...) return ... end
    LPH_CRASH = function() return print(debug.traceback()) end
end;

local flags = library.flags
local target_indicator = library:indicator({name = "target viewer"}) 
--[[ local belt_indicator = library:belt({name = "belt viewer"})
local armor_indicator = library:armor({name = "armor viewer"}) ]]

local cheat = {} do 
    do -- // tables
        cheat.connections = {}
        cheat.modules_unpacked = {}
        cheat.drawings = {}
        cheat.friendlies = {}
		cheat.tracers = {}
		cheat.hitmarkers = {}
		cheat.hitdamages = {}
		cheat.effects = {}
		cheat.freecam = nil
		cheat.shouldshoot = false
		cheat.stored_parts = {
			DamagePart = {},
			TouchCollision = {},
			Collision = {}
		}
		cheat.allowed_structures = {
			"Doorway", "Floor", "Triangle Floor", "Foundation", "Triangle Foundation", 
			"Wall", "Wall Frame", "Window", "Half Wall", "Low Wall", 
			"External Wooden Wall", "External Wooden Gate", 
			"External Stone Wall", "External Stone Gate"
		}
        cheat.hitboxes = {
            "Head",
            "UpperTorso",
            "LowerTorso",
            "HumanoidRootPart",
            "LeftUpperArm",
            "LeftLowerArm",
            "LeftHand",
            "RightUpperArm",
            "RightLowerArm",
            "RightHand",
            "LeftUpperLeg",
            "LeftLowerLeg",
            "LeftFoot",
            "RightUpperLeg",
            "RightLowerLeg",
            "RightFoot"
        }
		cheat.manipOffsets = {
			Vector3.new( 3, 0, 0), Vector3.new(-3, 0, 0),
			Vector3.new( 6, 0, 0), Vector3.new(-6, 0, 0),
			Vector3.new( 4, 0, 0), Vector3.new(-4, 0, 0),

			Vector3.new( 3, 2, 0), Vector3.new(-3, 2, 0),
			Vector3.new( 6, 2, 0), Vector3.new(-6, 2, 0),
			Vector3.new( 4, 2, 0), Vector3.new(-4, 2, 0),

			Vector3.new( 0.2, 3.9, 0),
			Vector3.new( 1.8, 4.1, 1),
			Vector3.new( 2.1, 4.4, 1.1),
			Vector3.new( 0.15, 5.2, 0.1),
			Vector3.new(-1.8, 5.4,-0.2),
			Vector3.new(-2.3, 6.0,-0.4),
			Vector3.new( 0.1, 6.0, 0.0),

			Vector3.new( 7, 0, 0), Vector3.new(-7, 0, 0),
			Vector3.new( 7, 2, 0), Vector3.new(-7, 2, 0),

			Vector3.new( 0.1, 7.5, 0.0),
			Vector3.new( 0.1, 8.0, 0.0),
		}
		cheat.hit_sounds = {
			Neverlose = "rbxassetid://8726881116",
			Bameware       = "rbxassetid://3124331820",
			Bell           = "rbxassetid://6534947240",
			Bubble         = "rbxassetid://6534947588",
			Skeet          = "rbxassetid://5633695679",
			Gamesense      = "rbxassetid://4817809188",
			Rust           = "rbxassetid://1255040462",
			TF2            = "rbxassetid://2868331684",
			["Among Us"]   = "rbxassetid://5700183626",
			minecraft      = "rbxassetid://4018616850",
			["CS:GO"]      = "rbxassetid://6937353691",
			Osu            = "rbxassetid://7149255551",
			["TF2 Critical"]= "rbxassetid://296102734",
			Bat            = "rbxassetid://3333907347",
			["Call of Duty"]= "rbxassetid://5952120301",
			Pop            = "rbxassetid://198598793",
			Bruh           = "rbxassetid://4275842574",
			Bamboo         = "rbxassetid://3769434519",
			["Old Fatality"]= "rbxassetid://6607142036",
			Mario          = "rbxassetid://2815207981",
			Steve          = "rbxassetid://4965083997"
		}
		cheat.hitsound_settings = {
			head = {
				enabled = false,
				volume = 2,
				selection = "Rust"
			},
			body = {
				enabled = false,
				volume = 2,
				selection = "Rust"
			}
		}
		cheat.viewmodel = {
			local_chams = {
				enabled = false,
				transparency = 0,
				material = "ForceField",
				color = Color3.fromRGB(255, 0, 0),
			},
			weapon_chams = {
				enabled = false,
				transparency = 0,
				material = "ForceField",
				color = Color3.fromRGB(255, 0, 0),
			},
			local_highlights = {
				enabled = false,
				inlineColor = Color3.fromRGB(230, 128, 128),
				outlineColor = Color3.fromRGB(230, 128, 128),
				fillTransparency = 0.5,
				outlineTransparency = 0,
			},
			weapon_highlights = {
				enabled = false,
				inlineColor = Color3.fromRGB(230, 128, 128),
				outlineColor = Color3.fromRGB(230, 128, 128),
				fillTransparency = 0.5,
				outlineTransparency = 0,
			},
		}
		cheat.bullet_tracer_textures = {
			["default"] = "rbxassetid://446111271",
			["beam"] = "rbxassetid://7151777149",
			["ion beam"] = "rbxassetid://2950987173",
			["lightning"] = "rbxassetid://7151778302",
			["pulsing"] = "rbxassetid://11226108137",
			["dna"] = "rbxassetid://6511613786",
		}
		cheat.field_of_view = {
			enabled = false,
			zoom = false,
			amount = 120,
			zoom_amount = 30,
			zoom_check = false
		}
		cheat.crosshair = {
			enabled = false,
			refreshrate = 0,
			mode = 'mouse',
			position = Vector2.new(0, 0),
			width = 1.5,
			length = 10,
			radius = 11,
			color = Color3.fromRGB(84,160,149),
			spin = false,
			spin_speed = 150,
			spin_max = 340,
			spin_style = Enum.EasingStyle.Circular,
			resize = false,
			resize_speed = 150,
			resize_min = 5,
			resize_max = 22,
		}
        Tween.EasingStyle = {
            [Enum.EasingStyle.Linear] = {
                [Enum.EasingDirection.In] = function(Delta)
                    return Delta
                end,
        
                [Enum.EasingDirection.Out] = function(Delta)
                    return Delta
                end,
        
                [Enum.EasingDirection.InOut] = function(Delta)
                    return Delta
                end
            },
            [Enum.EasingStyle.Cubic] = {
                [Enum.EasingDirection.In] = function(Delta)
                    return Delta^3
                end,
        
                [Enum.EasingDirection.Out] = function(Delta)
                    return (Delta - 1)^3 + 1
                end,
        
                [Enum.EasingDirection.InOut] = function(Delta)
                    if Delta <= 0.5 then
                        return (4 * Delta)^3
                    else
                        return (4 * (Delta - 1))^3 + 1
                    end
                end
            },
            [Enum.EasingStyle.Quad] = {
                [Enum.EasingDirection.In] = function(Delta)
                    return Delta^2
                end,
        
                [Enum.EasingDirection.Out] = function(Delta)
                    return -(Delta - 1)^2 + 1
                end,
        
                [Enum.EasingDirection.InOut] = function(Delta)
                    if Delta <= 0.5 then
                        return (2 * Delta)^2
                    else
                        return (-2 * (Delta - 1))^2 + 1
                    end
                end
            },
            [Enum.EasingStyle.Quart] = {
                [Enum.EasingDirection.In] = function(Delta)
                    return Delta^4
                end,
        
                [Enum.EasingDirection.Out] = function(Delta)
                    return -(Delta - 1)^4 + 1
                end,
        
                [Enum.EasingDirection.InOut] = function(Delta)
                    if Delta <= 0.5 then
                        return (8 * Delta)^4
                    else
                        return (-8 * (Delta - 1))^4 + 1
                    end
                end
            },
            [Enum.EasingStyle.Quint] = {
                [Enum.EasingDirection.In] = function(Delta)
                    return Delta^5
                end,
                [Enum.EasingDirection.Out] = function(Delta)
                    return (Delta - 1)^5 + 1
                end,
                [Enum.EasingDirection.InOut] = function(Delta)
                    if Delta <= 0.5 then
                        return (16 * Delta)^5
                    else
                        return (16 * (Delta - 1))^5 + 1
                    end
                end
            },
            [Enum.EasingStyle.Sine] = {
                [Enum.EasingDirection.In] = function(Delta)
                    return math.sin(math.pi / 2 * Delta - math.pi / 2)
                end,
        
                [Enum.EasingDirection.Out] = function(Delta)
                    return math.sin(math.pi / 2 * Delta)
                end,
        
                [Enum.EasingDirection.InOut] = function(Delta)
                    return 0.5 * math.sin(math.pi * Delta - math.pi / 2) + 0.5
                end
            },
            [Enum.EasingStyle.Exponential] = {
                [Enum.EasingDirection.In] = function(Delta)
                    return 2^(10 * Delta - 10) - 0.001
                end,
                [Enum.EasingDirection.Out] = function(Delta)
                    return 1.001 * -2^(-10 * Delta) + 1
                end,
                [Enum.EasingDirection.InOut] = function(Delta)
                    if Delta <= 0.5 then
                        return 0.5 * 2^(20 * Delta - 10) - 0.0005
                    else
                        return 0.50025 * -2^(-20 * Delta + 10) + 1
                    end
                end
            },
            [Enum.EasingStyle.Back] = {
                [Enum.EasingDirection.In] = function(Delta)
                    return Delta^2 * (Delta * (1.70158 + 1) - 1.70158)
                end,
                [Enum.EasingDirection.Out] = function(Delta)
                    return (Delta - 1)^2 * ((Delta - 1) * (1.70158 + 1) + 1.70158) + 1
                end,
                [Enum.EasingDirection.InOut] = function(Delta)
                    if Delta <= 0.5 then
                        return (2 * Delta * Delta) * ((2 * Delta) * (2.5949095 + 1) - 2.5949095)
                    else
                        return 0.5 * ((Delta * 2) - 2)^2 * ((Delta * 2 - 2) * (2.5949095 + 1) + 2.5949095) + 1
                    end
                end
            },
            [Enum.EasingStyle.Bounce] = {
                [Enum.EasingDirection.In] = function(Delta)
                    if Delta <= 0.25 / 2.75 then
                        return -7.5625 * (1 - Delta - 2.625 / 2.75)^2 + 0.015625
                    elseif Delta <= 0.75 / 2.75 then
                        return -7.5625 * (1 - Delta - 2.25 / 2.75)^2 + 0.0625
                    elseif Delta <= 1.75 / 2.75 then
                        return -7.5625 * (1 - Delta - 1.5 / 2.75)^2 + 0.25
                    else
                        return 1 - 7.5625 * (1 - Delta)^2
                    end
                end,
                [Enum.EasingDirection.Out] = function(Delta)
                    if Delta <= 1 / 2.75 then
                        return 7.5625 * (Delta * Delta)
                    elseif Delta <= 2 / 2.75 then
                        return 7.5625 * (Delta - 1.5 / 2.75)^2 + 0.75
                    elseif Delta <= 2.5 / 2.75 then
                        return 7.5625 * (Delta - 2.25 / 2.75)^2 + 0.9375
                    else
                        return 7.5625 * (Delta - 2.625 / 2.75)^2 + 0.984375
                    end
                end,
                [Enum.EasingDirection.InOut] = function(Delta)
                    if Delta <= 0.125 / 2.75 then
                        return 0.5 * (-7.5625 * (1 - Delta * 2 - 2.625 / 2.75)^2 + 0.015625)
                    elseif Delta <= 0.375 / 2.75 then
                        return 0.5 * (-7.5625 * (1 - Delta * 2 - 2.25 / 2.75)^2 + 0.0625)
                    elseif Delta <= 0.875 / 2.75 then
                        return 0.5 * (-7.5625 * (1 - Delta * 2 - 1.5 / 2.75)^2 + 0.25)
                    elseif Delta <= 0.5 then
                        return 0.5 * (1 - 7.5625 * (1 - Delta * 2)^2)
                    elseif Delta <= 1.875 / 2.75 then
                        return 0.5 + 3.78125 * (2 * Delta - 1)^2
                    elseif Delta <= 2.375 / 2.75 then
                        return 3.78125 * (2 * Delta - 4.25 / 2.75)^2 + 0.875
                    elseif Delta <= 2.625 / 2.75 then
                        return 3.78125 * (2 * Delta - 5 / 2.75)^2 + 0.96875
                    else
                        return 3.78125 * (2 * Delta - 5.375 / 2.75)^2 + 0.9921875
                    end
                end
            },
            [Enum.EasingStyle.Elastic] = {
                [Enum.EasingDirection.In] = function(Delta)
                    return -2^(10 * (Delta - 1)) * math.sin(math.pi * 2 * (Delta - 1 - 0.3 / 4) / 0.3)
                end,
        
                [Enum.EasingDirection.Out] = function(Delta)
                    return 2^(-10 * Delta) * math.sin(math.pi * 2 * (Delta - 0.3 / 4) / 0.3) + 1
                end,
        
                [Enum.EasingDirection.InOut] = function(Delta)
                    if Delta <= 0.5 then
                        return -0.5 * 2^(20 * Delta - 10) * math.sin(math.pi * 2 * (Delta * 2 - 1.1125) / 0.45)
                    else
                        return 0.5 * 2^(-20 * Delta + 10) * math.sin(math.pi * 2 * (Delta * 2 - 1.1125) / 0.45) + 1
                    end
                end
            },
            [Enum.EasingStyle.Circular] = {
                [Enum.EasingDirection.In] = function(Delta)
                    return -math.sqrt(1 - Delta^2) + 1
                end,
        
                [Enum.EasingDirection.Out] = function(Delta)
                    return math.sqrt(-(Delta - 1)^2 + 1)
                end,
        
                [Enum.EasingDirection.InOut] = function(Delta)
                    if Delta <= 0.5 then
                        return -math.sqrt(-Delta^2 + 0.25) + 0.5
                    else
                        return math.sqrt(-(Delta - 1)^2 + 0.25) + 0.5
                    end
                end
            }
        } 
    end

	do -- // szneos needed dependcy API Call Keys keycode Distributables X86 X64 Free AIO download (i need these funcs ima just put them here)

		local params = RaycastParams.new();
		params.IgnoreWater = true;
		params.FilterType = Enum.RaycastFilterType.Exclude;
		local zero = Vector3.zero

		szneo = {}; do
			szneo.bullet_tracer = function(origin_position, end_position, color,color2, lifetime, ignore_list)
				if (not lp) or (not cheat.LocalRoot) then
					return;
				end

				params.FilterDescendantsInstances = {ignore_list};

				local raycast = workspace:Raycast(origin_position, (end_position - origin_position).Unit * 1000, params);
				end_position = (raycast and raycast.Position) or end_position;
				
				local origin_part = Instance.new("Part", workspace); do
					origin_part.Name = "CelestialOrientation";
					origin_part.Size = zero;
					origin_part.Transparency = 1;

					origin_part.CanQuery = false;
					origin_part.CanTouch = false;
					origin_part.CanCollide = false;

					origin_part.Anchored = true;
					origin_part.CFrame = CFrame.new(origin_position);
				end

				local end_part = Instance.new("Part", workspace); do
					end_part.Size = zero;
					end_part.Transparency = 1;

					end_part.CanCollide = false;
					end_part.CanQuery = false;
					end_part.CanTouch = false;

					end_part.Anchored = true;
					end_part.CFrame = CFrame.new(end_position);
				end

				local origin_attachment = Instance.new("Attachment", origin_part); 
				origin_attachment.Name = "SoundAttachment";

				local end_attachment = Instance.new("Attachment", end_part);
				end_attachment.Name = "SoundAttachment";

				local beam = Instance.new("Beam", origin_part); do
					local width = 1;

					beam.Name = "SoundAttachment";
					beam.Enabled = true;
					beam.Width0 = width;
					beam.Width1 = width;
					beam.Attachment0 = origin_attachment;
					beam.Attachment1 = end_attachment;
					beam.Texture = cheat.bullet_tracer_textures[flags["bullet tracer style"]] or "rbxassetid://446111271";
					beam.FaceCamera = true;
					beam.LightEmission = 0;
					beam.LightInfluence = 0;
					beam.Color = ColorSequence.new{
						ColorSequenceKeypoint.new(0,color),
						ColorSequenceKeypoint.new(1,color2)	
					}
				end
			
				task.delay(lifetime, function()

					local fade_out = tween_service:Create(beam, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Width0 = 0, Width1 = 0});
					fade_out:Play();

					task.wait(lifetime / 3);

					origin_part:Destroy();
					end_part:Destroy();
				end)
			end

			szneo.DeepCopy = LPH_NO_VIRTUALIZE(function(Table)
				local Copy = {}
				for k, v in pairs(Table) do
					if type(v) == 'table' then
						Copy[k] = szneo.DeepCopy(v)
					else
						Copy[k] = v
					end
				end
				return Copy
			end);

			szneo.ViewModelFunc = function(Vstate,x,y,z)
				local ToolInfo = require(game:GetService("ReplicatedStorage").Modules.ToolInfo)
				local backup = szneo.DeepCopy(ToolInfo)

				for i,v in ipairs(ToolInfo) do
					if v.Offsets and v.Offsets.Local then
						if Vstate then
							v.Offsets.Local = backup[i].Offsets.Local * CFrame.new(
							x,
							y,
							z
						)
					else
						v.Offsets.Local = backup[i].Offsets.Local
					end
					end
				end

			end

			szneo.CanWeHitThisPosP100 = function(orig, dest)
				if not dest then return false end

				local targetPos
				if typeof(dest) == "Instance" and dest:IsA("BasePart") then
					targetPos = dest.Position
				elseif typeof(dest) == "CFrame" then
					targetPos = dest.Position
				elseif typeof(dest) == "Vector3" then
					targetPos = dest
				else
					warn("Unsupported dest type:", typeof(dest))
					return false
				end

				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
				raycastParams.FilterDescendantsInstances = {
					camera,
					workspace:FindFirstChild("VFX"),
					workspace:FindFirstChild("RocketFactoryPinkCardInvisWalls")
				}

				local direction = (targetPos - orig).Unit * ((targetPos - orig).Magnitude + 10)
				local ray = workspace:Raycast(orig, direction, raycastParams)

				if ray and ray.Instance and typeof(dest) == "Instance" and ray.Instance:IsDescendantOf(dest.Parent) then
					return true
				end

				return false
			end

			szneo.CheckManipPoints = function(origi, desti)
				for i, offset in ipairs(cheat.manipOffsets) do
					local newPos = origi * offset
					if szneo.CanWeHitThisPosP100(newPos, desti) then
						print("we up maniping these ngas")
						return newPos
					end
				end
				return nil
			end

			szneo.FindVisiblePosition = LPH_NO_VIRTUALIZE(function(Origin, Destination)
				local OriginalDestination = Destination
				if typeof(Origin) ~= "Vector3" then
					Origin = Origin.Position
				end

				local CameraCFrame = camera.CFrame
				local isvis = false

				local ManipulationOffsets = {
					CameraCFrame * CFrame.new(3, 0, 0),
					CameraCFrame * CFrame.new(-3, 0, 0),
					CameraCFrame * CFrame.new(-6, 0, 0),
					CameraCFrame * CFrame.new(6, 0, 0),
					CameraCFrame * CFrame.new(3, 2, 0),
					CameraCFrame * CFrame.new(-3, 2, 0),
					CameraCFrame * CFrame.new(-6, 2, 0),
					CameraCFrame * CFrame.new(6, 2, 0),
					CameraCFrame * CFrame.new(4, 0, 0),
					CameraCFrame * CFrame.new(-4, 2, 0),
					CameraCFrame * CFrame.new(-4, 0, 0),
					CameraCFrame * CFrame.new(4, 2, 0),
					CameraCFrame * CFrame.new(7, 0, 0),
					CameraCFrame * CFrame.new(-7, 2, 0),
					CameraCFrame * CFrame.new(-7, 0, 0),
					CameraCFrame * CFrame.new(7, 2, 0),
					CameraCFrame * CFrame.new(0.2, 3.9, 0),
					CameraCFrame * CFrame.new(1.8, 4.1, 1),
					CameraCFrame * CFrame.new(2.1, 4.4, 1.1),
					CameraCFrame * CFrame.new(0.15, 5.2, 0.1),
					CameraCFrame * CFrame.new(-1.8, 5.4, -0.2),
					CameraCFrame * CFrame.new(-2.3, 6.35, -0.4),
					CameraCFrame * CFrame.new(0.1, 7.5, 0),
					CameraCFrame * CFrame.new(0.1, 8, 0),
					CameraCFrame * CFrame.new(0.1, 8, 0),
					CameraCFrame * CFrame.new(0, -2, 0),
					CameraCFrame * CFrame.new(1.5, -3, 0.5),-- Wallbang
					CameraCFrame * CFrame.new(-2, -5, -1),  -- Wallbang
					CameraCFrame * CFrame.new(0.5, -6.5, 0),-- Wallbang
					CameraCFrame * CFrame.new(-1, -10, 1),   -- Wallbang
				}

				for _, offset in ManipulationOffsets do
					local newOrigin = offset.Position

					if szneo.CanWeHitThisPosP100(newOrigin, Destination) then
						isvis = true
						return newOrigin,isvis
					end
				end

				return nil
			end)

			szneo.FindHitScanPosition = LPH_NO_VIRTUALIZE(function(Origin, Destination)
                local OriginalDestination = Destination

                -- Fix: If Origin is not a Vector3, try to get its Position (assuming it's a part or similar)
                if typeof(Origin) ~= "Vector3" then
                    if Origin and Origin.Position then
                        Origin = Origin.Position
                    else
                        warn("Invalid Origin provided to FindHitScanPosition")
                        return nil
                    end
                end

                local CameraCFrame = camera.CFrame
                local isvis = false

                local vectors = { -- prefer small
                    Vector3.new(1 / 2, 0, 0), -- small right
                    Vector3.new(-1 / 2, 0, 0), -- small left
                    Vector3.new(0, 0, 1 / 2), -- small forward
                    Vector3.new(0, 0, -1 / 2), -- small backward
                    Vector3.new(0, 1 / 2, 0), -- small up
                    Vector3.new(0, -1 / 2, 0), -- small down

                    Vector3.new(1 / 2, 1 / 2, 0), -- small right up
                    Vector3.new(1 / 2, -1 / 2, 0), -- small right down
                    Vector3.new(-1 / 2, 1 / 2, 0), -- small left up
                    Vector3.new(-1 / 2, -1 / 2, 0), -- small left down
                    Vector3.new(0, 1 / 2, 1 / 2), -- small forward up
                    Vector3.new(0, -1 / 2, 1 / 2), -- small forward down
                    Vector3.new(0, 1 / 2, -1 / 2), -- small backward up
                    Vector3.new(0, -1 / 2, -1 / 2), -- small backward down

                    Vector3.new(1, 0, 0), -- big right
                    Vector3.new(-1, 0, 0), -- big left
                    Vector3.new(0, 0, 1), -- big forward
                    Vector3.new(0, 0, -1), -- big backward
                    Vector3.new(0, 1, 0), -- big up
                    Vector3.new(0, -1, 0), -- big down
                }

                for _, offset in ipairs(vectors) do
                    -- Fix: just add the offset to Origin (no .Position)
                    local newOrigin = Origin + offset

                    if szneo.CanWeHitThisPosP100(newOrigin, Destination) then
                        isvis = true
                        return newOrigin, isvis
                    end
                end

                return nil
            end)

			szneo.Hit_Notification = function(name,part,dist,health,weapon)
				local strings = {}
				if not flags["hit notifications"] then 
					return
				end
				print(name,part,dist,health,weapon)

				--if flags["hit notifications"] and flags["hit notifications options"] == "Name" then
					table.insert(strings,"Hit "..tostring(name))
				--end

				--if flags["hit notifications"] and flags["hit notifications options"] == "Distance" then
					table.insert(strings," from "..tostring(dist).."s")
				--end

				--if flags["hit notifications"] and flags["hit notifications options"] == "Weapon" then
					table.insert(strings," using "..tostring(weapon))
				--end

				--if flags["hit notifications"] and flags["hit notifications options"] == "Health" then
					table.insert(strings," their new Health is "..tostring(health))
				--end

				if #strings == 0 then
					return 
				end
				local final = table.concat(strings,"")
				task.spawn(function()
					setthreadidentity(8)
					library:notification(final,4)
					setthreadidentity(3)
				end)
			end

			szneo.GetArmourIcons = function(char) 
				if char then 
					return 
				end
				local icons = {};
				local items_table = cheat.modules_unpacked.Items

				for index,child in ipairs(char:GetChildren()) do
					if child and child.Name then
						local armorNumber, skinName = child.Name:match("Armor_(%d+)/(.*)");
						if armorNumber then
							local key = tonumber(armorNumber);
							if key then
								local item = items_table[key]
								if item and item.Type == "Armor" and item.Image then
									print("V1")
									if type(item.Image) == "table" then
										print("V2")
										if skinName and item.Image[skinName] then
											print("V3")
											table.insert(icons, item.Image[skinName]);
										elseif item.Image.Default then
											print("V4")
											table.insert(icons, item.Image.Default);
										end
									elseif type(item.Image) == "string" then
										print("v5")
										table.insert(icons, item.Image);
									end
								end
							end
						end
					end
				end;
				print(#icons)
				if #icons > 0 then return icons end;
				return nil;
			end;

			szneo.bullet_tracer2 = function(origin_position, end_position, color, lifetime, ignore_list)
				if (not lp) or (not cheat.LocalRoot) then
					return;
				end

				params.FilterDescendantsInstances = {ignore_list};

				local raycast = workspace:Raycast(origin_position, (end_position - origin_position).Unit * 1000, params);
				end_position = (raycast and raycast.Position) or end_position;
				
				local origin_part = Instance.new("Part", workspace); do
					origin_part.Name = "CelestialOrientation";
					origin_part.Size = zero;
					origin_part.Transparency = 1;

					origin_part.CanQuery = false;
					origin_part.CanTouch = false;
					origin_part.CanCollide = false;

					origin_part.Anchored = true;
					origin_part.CFrame = CFrame.new(origin_position);
				end

				local end_part = Instance.new("Part", workspace); do
					end_part.Size = zero;
					end_part.Transparency = 1;

					end_part.CanCollide = false;
					end_part.CanQuery = false;
					end_part.CanTouch = false;

					end_part.Anchored = true;
					end_part.CFrame = CFrame.new(end_position);
				end

				local origin_attachment = Instance.new("Attachment", origin_part); 
				origin_attachment.Name = "SoundAttachment";

				local end_attachment = Instance.new("Attachment", end_part);
				end_attachment.Name = "SoundAttachment";

				local beam = Instance.new("Beam", origin_part); do
					local width = 1;

					beam.Name = "SoundAttachment";
					beam.Enabled = true;
					beam.Width0 = width;
					beam.Width1 = width;
					beam.Attachment0 = origin_attachment;
					beam.Attachment1 = end_attachment;
					beam.Texture = cheat.bullet_tracer_textures[flags["bullet tracer style"]] or "rbxassetid://446111271";
					beam.FaceCamera = true;
					beam.LightEmission = 0;
					beam.LightInfluence = 0;
					beam.Color = ColorSequence.new(color)
				end
			
				task.delay(lifetime, function()

					local fade_out = tween_service:Create(beam, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Width0 = 0, Width1 = 0});
					fade_out:Play();

					task.wait(lifetime / 3);

					origin_part.Destroy(origin_part);
					end_part.Destroy(end_part);
				end)
			end

			szneo.hitmarker = function(end_pos, color, lifetime)
				local end_pos_part = Instance.new("Part"); do
					end_pos_part.Anchored = true;
					end_pos_part.Transparency = 1;
					end_pos_part.CanCollide = false;
					end_pos_part.Size = Vector3.zero;
					end_pos_part.CFrame = CFrame.new(end_pos);
					end_pos_part.Parent = workspace;
				end

				local billboard = Instance.new("BillboardGui", end_pos_part); do
					billboard.Size = UDim2.new(0, 230, 0, 230);
					billboard.AlwaysOnTop = true;
					billboard.Adornee = end_pos_part;
					billboard.Parent = end_pos_part;
				end

				local image = Instance.new("ImageLabel", billboard); do
					image.BackgroundTransparency = 1;
					image.Image = "rbxassetid://49170947";
					image.Size = UDim2.new(0, 250, 0, 250);
					image.Visible = true;
					image.ImageTransparency = 0;
					image.ImageColor3 = color;
				end

				task.delay(lifetime, function()
					local fade_out = tween_service:Create(image, TweenInfo.new(1), { ImageTransparency = 1 });
					fade_out:Play();
				
					local connection; connection = fade_out.Completed:Connect(function()
						image:Destroy();
					
						if (billboard) then
							billboard:Destroy();
						end

						if (end_pos_part) then
							end_pos_part:Destroy();
						end
						
						connection:Disconnect();
					end)
				end)
			end
		end
	end

    do -- // client
        cheat.player = game.Players.LocalPlayer
        cheat.camera = game.Workspace.CurrentCamera
        cheat.mouse = cheat.player:GetMouse()
        cheat.coregui = game:GetService("CoreGui")
        cheat.players = game.Players
		cheat.fov = camera.FieldOfView
		if cheat.player and cheat.player.Character and cheat.player.Character:FindFirstChild("HumanoidRootPart") then
            cheat.Local_char = cheat.player.Character
			cheat.LocalRoot = cheat.player.Character:FindFirstChild("HumanoidRootPart")
		end

        -- // other
        cheat.target = nil
		cheat.last_hit_part = nil
		
		-- // main sgui
		cheat.sgui = Instance.new("ScreenGui")
		cheat.sgui.Name = "9391203j312i3kashd9q312093ajsdokake219183213h"
		cheat.sgui.Parent = gethui()
		cheat.sgui.DisplayOrder = -1
		cheat.sgui.IgnoreGuiInset = true
    end

    do -- // functions
        function cheat:connect(signal, callback)
            local connection = signal:Connect(callback)
            table.insert(cheat.connections, connection)
            return connection
        end

        function cheat:create(Class, Properties)
            local _Instance = typeof(Class) == 'string' and Instance.new(Class) or Class
            for Property, Value in pairs(Properties) do
                _Instance[Property] = Value
            end
            return _Instance
        end     

        function cheat:get_target()
            local current_target = nil
            local maximum_distance = flags["combat maximum distance"] 

            if flags["combat target"] and table.find(flags["combat target"], "players") then
                for i,v in pairs(game.Players:GetPlayers()) do
                    if v == cheat.player then continue end
                    if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                        local position, on_screen = cheat.camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
                        if not on_screen then continue end
                        local distance

                        if flags["combat target type"] == "closest to mouse" then
                            distance = (Vector2.new(position.X, position.Y - game.GuiService:GetGuiInset().Y) - Vector2.new(cheat.mouse.X, cheat.mouse.Y)).Magnitude
                        elseif flags["combat target type"] == "closest to screen center" then
                            local viewport_size = cheat.camera.ViewportSize
                            local screen_center = Vector2.new(viewport_size.X / 2, viewport_size.Y / 2)
                            distance = (Vector2.new(position.X, position.Y) - screen_center).Magnitude
                        end

                        local humanoid = v.Character:FindFirstChild("Humanoid")
                        
                        -- // fov check
                        if flags["drawings fov"] and distance > flags["drawings fov radius"] then continue end

                        -- // distance check
                        if distance > maximum_distance then continue end

                        -- // health check
                        if flags["combat conditions"] and table.find(flags["combat conditions"], "health") and humanoid and humanoid.Health <= flags["combat minimum health"] then continue end

                        -- // visible check
                        if flags["combat conditions"] and table.find(flags["combat conditions"], "visible") and not visible then continue end

                        -- // invisible check
                        if flags["combat conditions"] and table.find(flags["combat conditions"], "invisible") and v.Character:FindFirstChild("Head") and v.Character:FindFirstChild("Head").Transparency == 1 then continue end

                        -- // team check
                        if flags["combat conditions"] and table.find(flags["combat conditions"], "team") and cheat.friendlies and table.find(cheat.friendlies, v) then continue end

                        -- // ✅ Found a new target
                        current_target = v
                        maximum_distance = distance
                    end
                end
            end
            if current_target ~= cheat.target then
                if current_target and flags["combat notify target"] then
                    library:notification({
                        text = "targeting " .. current_target.Name,
                        time = 5
                    })
                end
                cheat.target = current_target
            end

            return current_target
        end

        function cheat:pass_through(from, target, params, ignoreTable)
            params.FilterDescendantsInstances = ignoreTable
            local Result = workspace:Raycast(from, (target.Position - from).unit * 10000, params)
            if Result then
                local Instance = Result.Instance
                if Instance:IsDescendantOf(target.Parent) then
                    return true
                elseif Instance.CanCollide == false or Instance.Transparency == 1 then
                    if Instance.Name ~= "Head" and Instance.Name ~= "HumanoidRootPart" then
                        table.insert(ignoreTable, Instance)
                        cheat:pass_through(Result.Position, target, params, ignoreTable)
                    end
                end
            end
        end

        local Players = game:GetService("Players");
        local Camera = workspace.CurrentCamera;
        local LocalPlayer = Players.LocalPlayer;
        cheat.Mouse = LocalPlayer:GetMouse()

        -- // funcs

        function cheat:ValidateRay(Args, RayMethod)
            local Matches = 0
            if #Args < RayMethod.ArgCountRequired then
                return false
            end
            for Pos, Argument in next, Args do
                if typeof(Argument) == RayMethod.Args[Pos] then
                    Matches = Matches + 1
                end
            end
            return Matches >= RayMethod.ArgCountRequired
        end

        function cheat:resolveDirection(origin,destination)
            return (destination - origin).Unit * 1000
        end


		function cheat:make_target_effect(c)
			if not flags["targeting effects"] then
				for _, inst in ipairs(cheat.effects) do
					if inst then inst:Destroy() end
				end
				table.clear(cheat.effects)
				cheat.currentTarget = nil
				return
			end

			if c == cheat.currentTarget then
				return
			end

			for _, inst in ipairs(cheat.effects) do
				if inst then inst:Destroy() end
			end
			table.clear(cheat.effects)

			cheat.currentTarget = c
			if not c then return end

			local torso = c:FindFirstChild("LowerTorso") or c:FindFirstChild("HumanoidRootPart")
			if not torso then return end

			-- // Healing_Wave_2
			local Healing_Wave_2 = Instance.new("ParticleEmitter")
			Healing_Wave_2.Brightness = 10
			Healing_Wave_2.Color = ColorSequence.new(flags["targeting effects color"].Color)
			Healing_Wave_2.Lifetime = NumberRange.new(1)
			Healing_Wave_2.LightEmission = 1
			Healing_Wave_2.LockedToPart = true
			Healing_Wave_2.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
			Healing_Wave_2.Rate = flags["targeting effects rate"]
			Healing_Wave_2.RotSpeed = NumberRange.new(100, 300)
			Healing_Wave_2.Rotation = NumberRange.new(-180, 180)
			Healing_Wave_2.Size = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 3.125),
				NumberSequenceKeypoint.new(0.417, 1.375),
				NumberSequenceKeypoint.new(1, 0.938)
			}
			Healing_Wave_2.Speed = NumberRange.new(3, 5)
			Healing_Wave_2.SpreadAngle = Vector2.new(10, -10)
			Healing_Wave_2.Texture = "rbxassetid://8047796070"
			Healing_Wave_2.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.225, 0.031),
				NumberSequenceKeypoint.new(0.629, 0.256),
				NumberSequenceKeypoint.new(0.837, 0.912),
				NumberSequenceKeypoint.new(1, 1)
			}
			Healing_Wave_2.Name = "target effect 1"
			Healing_Wave_2.Parent = torso

			-- // Healing_Wave_1
			local Healing_Wave_1 = Instance.new("ParticleEmitter")
			Healing_Wave_1.Brightness = 10
			Healing_Wave_1.Color = ColorSequence.new(flags["targeting effects color"].Color)
			Healing_Wave_1.Lifetime = NumberRange.new(1)
			Healing_Wave_1.LightEmission = 0.4
			Healing_Wave_1.LockedToPart = true
			Healing_Wave_1.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
			Healing_Wave_1.Rate = flags["targeting effects rate"]
			Healing_Wave_1.RotSpeed = NumberRange.new(200, 400)
			Healing_Wave_1.Rotation = NumberRange.new(-180, 180)
			Healing_Wave_1.Size = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 3.062),
				NumberSequenceKeypoint.new(0.642, 2),
				NumberSequenceKeypoint.new(1, 0.75)
			}
			Healing_Wave_1.Speed = NumberRange.new(3, 6)
			Healing_Wave_1.SpreadAngle = Vector2.new(10, -10)
			Healing_Wave_1.Texture = "rbxassetid://8047533775"
			Healing_Wave_1.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.170, 0.700),
				NumberSequenceKeypoint.new(0.225, 0.031),
				NumberSequenceKeypoint.new(0.285, 0),
				NumberSequenceKeypoint.new(0.702, 0),
				NumberSequenceKeypoint.new(0.837, 0.912),
				NumberSequenceKeypoint.new(1, 1)
			}
			Healing_Wave_1.Name = "target effect 2"
			Healing_Wave_1.Parent = torso

			table.insert(cheat.effects, Healing_Wave_1)
			table.insert(cheat.effects, Healing_Wave_2)
		end
    end

    do -- // drawings
        local screen_center = cheat.camera.ViewportSize / 2; 
        local drawings_gui = cheat:create("ScreenGui", {Name = "\n", Parent = gethui(), DisplayOrder = -1, IgnoreGuiInset = true});

        do -- // fov
            cheat.drawings.silent_fov_circle = cheat:create("Frame", {Parent = drawings_gui, BackgroundTransparency = 1, ZIndex = 9999, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(0, 500, 0, 500), Position = UDim2.new(0, screen_center.X, 0, screen_center.Y), Visible = false, AnchorPoint = Vector2.new(0.5, 0.5)})
            cheat.drawings.silent_fov_circle_corner = cheat:create("UICorner", {Parent = cheat.drawings.silent_fov_circle, CornerRadius = UDim.new(1, 9999999)})
            cheat.drawings.silent_fov_circle_stroke = cheat:create("UIStroke", {Parent = cheat.drawings.silent_fov_circle, Color = Color3.new(1,1,1), Thickness = 3})
            cheat.drawings.silent_fov_circle_gradient = cheat:create("UIGradient", {Parent = cheat.drawings.silent_fov_circle_stroke, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))}})

			cheat.drawings.silent_fov_circle_fill = cheat:create("Frame", {Parent = drawings_gui, BackgroundTransparency = 0,  BackgroundColor3 = Color3.new(1,1,1), ZIndex = 9997, Size = UDim2.new(0, 500, 0, 500), Position = UDim2.new(0, screen_center.X, 0, screen_center.Y), Visible = false, AnchorPoint = Vector2.new(0.5, 0.5)})
			cheat.drawings.silent_fov_circle_fill_corner = cheat:create("UICorner", { Parent = cheat.drawings.silent_fov_circle_fill, CornerRadius = UDim.new(1, 9999999)})
			cheat.drawings.silent_fov_circle_fill_gradient = cheat:create("UIGradient", {Parent = cheat.drawings.silent_fov_circle_fill, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))}, Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}})

            cheat.drawings.silent_fov_circle_outline = cheat:create("Frame", {Parent = drawings_gui, BackgroundTransparency = 1, ZIndex = 9998, BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(0, 500, 0, 500), Position = UDim2.new(0, screen_center.X, 0, screen_center.Y), Visible = false, AnchorPoint = Vector2.new(0.5, 0.5)})
            cheat.drawings.silent_fov_circle_corner_outline = cheat:create("UICorner", {Parent = cheat.drawings.silent_fov_circle_outline, CornerRadius = UDim.new(1, 9999999)})
            cheat.drawings.silent_fov_circle_stroke_outline = cheat:create("UIStroke", {Parent = cheat.drawings.silent_fov_circle_outline, Color = Color3.new(0,0,0), Thickness = 5})
        end
		do -- indicator texts
			cheat.drawings.Manip_Indicator = cheat:create("TextLabel", {
				Parent = drawings_gui,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.new(0.446004331, 0, 0.741935492, 0),
				Size = UDim2.new(0, 200, 0, 50),
				Font = Enum.Font.SourceSans,
				Text = "Manipulating !",
				Visible = false,
				TextColor3 = Color3.fromRGB(255, 26, 213),
				TextSize = 14
			})
			cheat.drawings.Manip_Indicator_Stroke = cheat:create("UIStroke", {Parent = cheat.drawings.Manip_Indicator})
		end
        do -- // snapline
        	cheat.drawings.silent_snapline_outline = Drawing.new("Line")
            cheat.drawings.silent_snapline_outline.Visible = false
            cheat.drawings.silent_snapline_outline.Thickness = 5
            cheat.drawings.silent_snapline_outline.Color = Color3.new(0,0,0)
            cheat.drawings.silent_snapline_outline.Transparency = 1

            cheat.drawings.silent_snapline = Drawing.new("Line")
            cheat.drawings.silent_snapline.Visible = false
            cheat.drawings.silent_snapline.Thickness = 3
            cheat.drawings.silent_snapline.Color = Color3.new(1, 1, 1)
            cheat.drawings.silent_snapline.Transparency = 1
        end
    end

    do -- // functionality	
        do -- // connections
			do -- // renderstepped
				cheat:connect(game:GetService("RunService").RenderStepped, LPH_NO_VIRTUALIZE(function(time)
					cheat.target = cheat:get_target()
					
					local screen_center = cheat.camera.ViewportSize / 2

					do -- // playerlist
						local new_friendlies = {}

						for _, player in ipairs(game.Players:GetPlayers()) do
							if library and library.get_priority then
								local prio = library.get_priority(player)

								if prio == "Friendly" then
									table.insert(new_friendlies, player)
								end
							end
						end

						cheat.friendlies = new_friendlies
					end

					do -- // target effects
						cheat:make_target_effect(cheat.target and cheat.target.Character or nil)
					end

					do -- freecam
						
					end

					do -- // target shit
						if flags["targeting show target info"] and cheat.target and cheat.target.Character and cheat.target.Character:FindFirstChild("HumanoidRootPart") then
							local distance = (cheat.camera.CFrame.Position - cheat.target.Character.HumanoidRootPart.Position).Magnitude / 3.5714285714
							local is_friendly = cheat.friendlies and table.find(cheat.friendlies, cheat.target) ~= nil or false
							
							if target_indicator then
								target_indicator.set_visible(true)

								target_indicator.change_profile(
									cheat.target,
									tostring(math.floor(distance)),
									is_friendly
								)

								if cheat.target.Character:FindFirstChild("Humanoid") then
									target_indicator.change_health(cheat.target.Character.Humanoid.Health)
								end
							end
						elseif target_indicator then
							target_indicator.set_visible(false)
						end

						--[[ if flags["targeting show target belt"] and cheat.target then
							belt_indicator.set_visible(flags["targeting show target belt"])
							--local icoTable = szneo.GetArmourIcons(cheat.target.Character)
							--belt_indicator.update_images(icoTable[1],icoTable[2],icoTable[3],icoTable[4],icoTable[5],icoTable[6],icoTable[7])
						else
							belt_indicator.set_visible(false)
							belt_indicator.update_images("", "", "", "", "", "")
						end

						if flags["targeting show target armor"] and cheat.target then
							armor_indicator.set_visible(flags["targeting show target armor"])
							local icoTable = szneo.GetArmourIcons(cheat.target.Character)
							armor_indicator.update_images(
								icoTable[1], icoTable[2], icoTable[3],
								icoTable[4], icoTable[5], icoTable[6],
								icoTable[7]
							)
						else
							armor_indicator.set_visible(false)
							armor_indicator.update_images("", "", "", "", "", "", "")
						end

						if flags["targeting show target armor"] and cheat.target then
							armor_indicator.set_visible(flags["targeting show target armor"])
							armor_indicator.update_images()
						else
							armor_indicator.set_visible(false)
							armor_indicator.update_images("", "", "","", "", "", "")
						end ]]
					end   

					do -- // fov and snapline shit
						do -- // fov 
							local fov_radius = flags["drawings fov radius"] or 100

							if flags["drawings fov size"] == "dynamic" and cheat.fov then
								local difference = (cheat.fov / cheat.camera.FieldOfView)
								fov_radius = fov_radius * difference
							end

							-- // main circle
							if cheat.drawings and cheat.drawings.silent_fov_circle then
								cheat.drawings.silent_fov_circle.Visible = flags["drawings fov"] or false
								cheat.drawings.silent_fov_circle.Size = UDim2.new(0, fov_radius * 2, 0, fov_radius * 2)
								cheat.drawings.silent_fov_circle.Position = UDim2.new(0.5, -fov_radius, 0.5, -fov_radius)
								
								if cheat.drawings.silent_fov_circle_gradient and flags["drawings fov color one"] and flags["drawings fov color two"] then
									cheat.drawings.silent_fov_circle_gradient.Color = ColorSequence.new{
										ColorSequenceKeypoint.new(0, flags["drawings fov color one"].Color), 
										ColorSequenceKeypoint.new(1, flags["drawings fov color two"].Color)
									}
								end
							end

							-- // fill
							if cheat.drawings and cheat.drawings.silent_fov_circle_fill then
								cheat.drawings.silent_fov_circle_fill.Visible = (flags["drawings fov fill"] and flags["drawings fov"]) or false
								cheat.drawings.silent_fov_circle_fill.Size = UDim2.new(0, fov_radius * 2, 0, fov_radius * 2)
								cheat.drawings.silent_fov_circle_fill.Position = UDim2.new(0.5, -fov_radius, 0.5, -fov_radius)
								
								if cheat.drawings.silent_fov_circle_fill_gradient and flags["drawings fov fill color one"] and flags["drawings fov fill color two"] then
									cheat.drawings.silent_fov_circle_fill_gradient.Color = ColorSequence.new{
										ColorSequenceKeypoint.new(0, flags["drawings fov fill color one"].Color), 
										ColorSequenceKeypoint.new(1, flags["drawings fov fill color two"].Color)
									}
									cheat.drawings.silent_fov_circle_fill_gradient.Transparency = NumberSequence.new{
										NumberSequenceKeypoint.new(0, flags["drawings fov fill color one"].Transparency), 
										NumberSequenceKeypoint.new(1, flags["drawings fov fill color two"].Transparency)
									}
								end
							end

							-- // outline
							if cheat.drawings and cheat.drawings.silent_fov_circle_outline then
								cheat.drawings.silent_fov_circle_outline.Visible = flags["drawings fov"] or false
								cheat.drawings.silent_fov_circle_outline.Size = UDim2.new(0, (fov_radius * 2) - 2, 0, (fov_radius * 2) - 2)
								cheat.drawings.silent_fov_circle_outline.Position = UDim2.new(0.5, -(fov_radius - 1), 0.5, -(fov_radius - 1))
							end

							do -- // sizing and geometry
								if cheat.drawings then
									if cheat.drawings.silent_fov_circle_corner then
										cheat.drawings.silent_fov_circle_corner.CornerRadius = UDim.new(0, flags["drawings fov sides"] or 100)
									end
									if cheat.drawings.silent_fov_circle_fill_corner then
										cheat.drawings.silent_fov_circle_fill_corner.CornerRadius = UDim.new(0, flags["drawings fov sides"] or 100)
									end
									if cheat.drawings.silent_fov_circle_corner_outline then
										cheat.drawings.silent_fov_circle_corner_outline.CornerRadius = UDim.new(0, flags["drawings fov sides"] or 100)
									end

									if cheat.drawings.silent_fov_circle_stroke then
										cheat.drawings.silent_fov_circle_stroke.Thickness = flags["drawings fov thickness"] or 1
									end
									if cheat.drawings.silent_fov_circle_stroke_outline then
										cheat.drawings.silent_fov_circle_stroke_outline.Thickness = (flags["drawings fov thickness"] or 1) + 2
									end
								end
							end

							do -- // positioning						
								if flags["drawings fov position"] == "center" then
									local pos = UDim2.new(0, screen_center.X, 0, screen_center.Y)
									if cheat.drawings then
										if cheat.drawings.silent_fov_circle then
											cheat.drawings.silent_fov_circle.Position = pos
										end
										if cheat.drawings.silent_fov_circle_outline then
											cheat.drawings.silent_fov_circle_outline.Position = pos
										end
										if cheat.drawings.silent_fov_circle_fill then
											cheat.drawings.silent_fov_circle_fill.Position = pos
										end
									end

								elseif flags["drawings fov position"] == "mouse" then
									local mouse_x, mouse_y = cheat.mouse.X or 0, (cheat.mouse.Y or 0) + game:GetService("GuiService"):GetGuiInset().Y
									local pos = UDim2.new(0, mouse_x, 0, mouse_y)
									if cheat.drawings then
										if cheat.drawings.silent_fov_circle then
											cheat.drawings.silent_fov_circle.Position = pos
										end
										if cheat.drawings.silent_fov_circle_outline then
											cheat.drawings.silent_fov_circle_outline.Position = pos
										end
										if cheat.drawings.silent_fov_circle_fill then
											cheat.drawings.silent_fov_circle_fill.Position = pos
										end
									end

								elseif flags["drawings fov position"] == "barrel" then
									local barrel = cheat:get_barrel_pos()
									if barrel then
										local target = barrel.Position + barrel.CFrame.LookVector * 1000
										local screenPos, onScreen = cheat.camera:WorldToViewportPoint(target)
										if onScreen then
											local pos = UDim2.new(0, screenPos.X, 0, screenPos.Y - 58)
											if cheat.drawings then
												if cheat.drawings.silent_fov_circle then
													cheat.drawings.silent_fov_circle.Position = pos
												end
												if cheat.drawings.silent_fov_circle_outline then
													cheat.drawings.silent_fov_circle_outline.Position = pos
												end
												if cheat.drawings.silent_fov_circle_fill then
													cheat.drawings.silent_fov_circle_fill.Position = pos
												end
											end
										end
									else
										local fallback_pos = UDim2.new(0, screen_center.X, 0, screen_center.Y)
										if cheat.drawings then
											if cheat.drawings.silent_fov_circle then
												cheat.drawings.silent_fov_circle.Position = fallback_pos
											end
											if cheat.drawings.silent_fov_circle_outline then
												cheat.drawings.silent_fov_circle_outline.Position = fallback_pos
											end
											if cheat.drawings.silent_fov_circle_fill then
												cheat.drawings.silent_fov_circle_fill.Position = fallback_pos
											end
										end
									end
								end
							end

							do -- // animations
								local rot = 0
								local time = tick()

								if flags["fov animation"] then
									if Tween and Tween.EasingStyle and flags["fov animation easing style"] and flags["fov animation easing direction"] then
										local style = Tween.EasingStyle[Enum.EasingStyle[flags["fov animation easing style"]]][Enum.EasingDirection[flags["fov animation easing direction"]]](math.cos(math.pi / 2 * tick() - math.pi / 2))
										rot = style * (flags["fov animation speed"] or 1)
									else
										rot = math.cos(time) * (flags["fov animation speed"] or 1)
									end
								else
									rot = math.cos(time) * (flags["fov animation speed"] or 1)
								end

								if flags["fov animation"] and flags["fov animation elements"] and cheat.drawings then
									if table.find(flags["fov animation elements"], "circle") and cheat.drawings.silent_fov_circle_gradient then
										cheat.drawings.silent_fov_circle_gradient.Rotation = rot
									end
									if table.find(flags["fov animation elements"], "fill") and cheat.drawings.silent_fov_circle_fill_gradient then
										cheat.drawings.silent_fov_circle_fill_gradient.Rotation = rot
									end
								end
							end
						end

						do -- // snapline
							local silent_visible = (cheat.target ~= nil) and flags["drawings fireport line"]
							
							if cheat.drawings then
								if cheat.drawings.silent_snapline then
									cheat.drawings.silent_snapline.Visible = silent_visible
								end
								if cheat.drawings.silent_snapline_outline then
									cheat.drawings.silent_snapline_outline.Visible = silent_visible
								end
							end

							if silent_visible and cheat.target and cheat.target.Character and flags["combat hitboxes"] then
								local hitbox_part = cheat.target.Character:FindFirstChild(flags["combat hitboxes"])
								if hitbox_part then
									local hitbox_screen_pos, hitbox_visible = cheat.camera:WorldToViewportPoint(hitbox_part.Position)

									if hitbox_visible and cheat.drawings then
										local from_pos
										if flags["drawings fov position"] == "center" then
											from_pos = Vector2.new(screen_center.X, screen_center.Y)
										elseif flags["drawings fov position"] == "mouse" then
											local mouse_x, mouse_y = cheat.mouse.X or 0, (cheat.mouse.Y or 0) + game:GetService("GuiService"):GetGuiInset().Y
											from_pos = Vector2.new(mouse_x, mouse_y)
										elseif flags["drawings fov position"] == "barrel" then
											local barrel = cheat:get_barrel_pos()
											if barrel then
												local target = barrel.Position + barrel.CFrame.LookVector * 1000
												local screenPos, onScreen = cheat.camera:WorldToViewportPoint(target)
												if onScreen then
													from_pos = Vector2.new(screenPos.X, screenPos.Y - 58)
												end
											end
										end

										from_pos = from_pos or Vector2.new(screen_center.X, screen_center.Y)

										if cheat.drawings.silent_snapline then
											cheat.drawings.silent_snapline.Thickness = flags["drawings fireport line thickness"] or 1
											cheat.drawings.silent_snapline.From = from_pos
											cheat.drawings.silent_snapline.To = Vector2.new(hitbox_screen_pos.X, hitbox_screen_pos.Y)
											if flags["drawings fireport line color one"] then
												cheat.drawings.silent_snapline.Color = flags["drawings fireport line color one"].Color
											end
										end

										if cheat.drawings.silent_snapline_outline then
											cheat.drawings.silent_snapline_outline.Thickness = (flags["drawings fireport line thickness"] or 1) + 2
											cheat.drawings.silent_snapline_outline.From = from_pos
											cheat.drawings.silent_snapline_outline.To = Vector2.new(hitbox_screen_pos.X, hitbox_screen_pos.Y)
										end
									else
										if cheat.drawings then
											if cheat.drawings.silent_snapline then
												cheat.drawings.silent_snapline.Visible = false
											end
											if cheat.drawings.silent_snapline_outline then
												cheat.drawings.silent_snapline_outline.Visible = false
											end
										end
									end
								end
							end
						end
					end
				end))
			end
		end

        do -- // hooks
			do -- // debug
				local gc = getgc(true); do
                for _, object in gc do
                    if (typeof(object) == "function" and islclosure(object)) then
                        local info = debug.getinfo(object);
    
                        if (not info) then
                            continue;
                        end
    
                        if (info.name == "CheckCameraDistance") then
                            hookfunction(object, LPH_NO_UPVALUES(function()
                                return false;
                            end))
                        end
                    end
                end
			end
			end
            do -- // hookfunction
                do -- // camera hook
					local metatable = getrawmetatable(camera); local old_newindex = nil; old_newindex = hookfunction(metatable.__newindex, LPH_NO_UPVALUES(function(self, index, value)
						local user_input_service = game:GetService("UserInputService")

						if (index == "CFrame") and flags["combat mode"] == "aimbot" then
							local bind = flags["aimbot bind"]
							local bind_active = bind.active
							local bind_key = bind.key

							local pressed = false
							if bind_key == Enum.UserInputType.MouseButton1
							or bind_key == Enum.UserInputType.MouseButton2
							or bind_key == Enum.UserInputType.MouseButton3 then
								pressed = user_input_service:IsMouseButtonPressed(bind_key)
							else
								pressed = user_input_service:IsKeyDown(bind_key)
							end

							if library.flags["combat enabled"] and bind_active and pressed then
								if cheat.target then
									local target_part

									target_part = cheat.target.Character[flags["combat hitboxes"]]

									if target_part then
										local currentCFrame = value
										local targetCFrame = CFrame.new(value.Position, target_part.Position)

										local smoothness = 1 - ((library.flags["combat smoothing"] or 0) / 100)
										smoothness = math.clamp(smoothness, 0, 1)

										value = currentCFrame:Lerp(targetCFrame, smoothness)
										cheat.last_hit_part = target_part
									end
								end
							end
						end

						return old_newindex(self, index, value)
					end))
                end
            end
        end

		-- // random shit features
		do
			do -- // cframe speed
				local RunService = game:GetService("RunService")
				local UserInputService = game:GetService("UserInputService")

				RunService.RenderStepped:Connect(function()
					if not flags["omni sprint"] then return end

					local character = lp.Character
					if not character or not character:FindFirstChild("HumanoidRootPart") then return end

					local root = character.HumanoidRootPart
					local dir = Vector3.zero
					local look = camera.CFrame.LookVector

					local movement_keys = {
						[Enum.KeyCode.W] = Vector3.new(look.X, 0, look.Z),
						[Enum.KeyCode.S] = Vector3.new(-look.X, 0, -look.Z),
						[Enum.KeyCode.A] = Vector3.new(look.Z, 0, -look.X),
						[Enum.KeyCode.D] = Vector3.new(-look.Z, 0, look.X),
					}

					for key, vector in pairs(movement_keys) do
						if UserInputService:IsKeyDown(key) then
							dir += vector
						end
					end

					if dir.Magnitude > 0 then
						dir = dir.Unit
						local speed = flags["omni sprint speed"] or 50
						root.AssemblyLinearVelocity = dir * speed + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
					end
				end)
			end
			do -- // name spoof etc
				function updateTeamListNames()
					if updateDebounce then return end
					updateDebounce = true
					
					local main = PlayerGui:FindFirstChild("Main")
					local team = main and main:FindFirstChild("Team")
					local teamList = team and team:FindFirstChild("TeamList")

					if teamList and teamList.Visible then
						for _, label in ipairs(teamList:GetChildren()) do
							if label:IsA("TextLabel") then
								if SpoofName then
									if label.Text == OriginalName or label.Text == SpoofedName then
										label.Text = SpoofedName
										label.TextColor3 = SpoofColor
									end
								else
									if label.Text == SpoofedName then
										label.Text = OriginalName
										label.TextColor3 = Color3.new(1, 1, 1)
									end
								end
							end
						end
					end
					
					updateDebounce = false
				end
			end
			do -- // spiderman
				local RunService = game:GetService("RunService")
				local Players = game:GetService("Players")
				local LocalPlayer = Players.LocalPlayer
				local DesyncTypes = {}

				RunService.Heartbeat:Connect(function()
					local character = LocalPlayer.Character
					local hrp = character and character:FindFirstChild("HumanoidRootPart")

					if flags["spiderman"] and hrp then
						hrp.Velocity = Vector3.new(hrp.Velocity.X, flags["spiderman_speed"] or 10, hrp.Velocity.Z)
					end

					if flags["infflight"] and hrp then
						DesyncTypes[1] = hrp.CFrame
						DesyncTypes[2] = hrp.AssemblyLinearVelocity

						hrp.AssemblyLinearVelocity = Vector3.new(1, -1, 1) * 16384
						RunService.RenderStepped:Wait()

						hrp.CFrame = DesyncTypes[1]
						hrp.AssemblyLinearVelocity = DesyncTypes[2]
					else
						DesyncTypes = {}
					end
				end)

				local originalIndex
				originalIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
					if flags["infflight"] and not checkcaller() and key == "CFrame" then
						local character = LocalPlayer.Character
						local hrp = character and character:FindFirstChild("HumanoidRootPart")
						local humanoid = character and character:FindFirstChild("Humanoid")
						local head = character and character:FindFirstChild("Head")

						if hrp and humanoid and humanoid.Health > 0 then
							if self == hrp then
								return DesyncTypes[1] or hrp.CFrame
							elseif self == head then
								return (DesyncTypes[1] and (DesyncTypes[1] + Vector3.new(0, hrp.Size.Y / 2 + 0.5, 0))) or head.CFrame
							end
						end
					end
					return originalIndex(self, key)
				end))
			end
			do -- // bhop
				local UserInputService = game:GetService("UserInputService")
				local Players = game:GetService("Players")
				local player = Players.LocalPlayer
				local character = player.Character or player.CharacterAdded:Wait()
				local humanoid = character:WaitForChild("Humanoid")
				local function setupBunnyhop(character)
					local humanoid = character:WaitForChild("Humanoid")

					RunService.RenderStepped:Connect(function()
						if flags["Bunnyhop"]
							and humanoid
							and humanoid.Parent -- check it still exists
							and humanoid.FloorMaterial ~= Enum.Material.Air
							and UserInputService:IsKeyDown(Enum.KeyCode.Space) then

							humanoid.Jump = true
						end
					end)
				end

				--// Setup for current character
				if player.Character then
					setupBunnyhop(player.Character)
				end

				--// Re-setup when respawning
				player.CharacterAdded:Connect(function(character)
					setupBunnyhop(character)
				end)
			end
		end
    end

	local esp_success, esp_library = pcall(function()
		return loadstring(game.HttpGet(game, "https://pastefy.app/NKUSEEPG/raw"))();
	end)

	if (not esp_success) then
		return lp:Kick("[ InsanityPastedSloptic ] Failure to load esp. Contact us in the InsanityPastedSloptic discord.");
	end

	esp_library.Load();

    cheat.ui = {}; do 
        cheat.ui.window = library:window({name = os.date('InsanityPastedSloptic - %b %d %Y'), size = UDim2.new(0, 750, 0, 782)})

        cheat.ui.tabs = {}; do 
            cheat.ui.tabs.combat = cheat.ui.window:tab({name = "combat"}) cheat.ui.tabs.combat.open_tab() 
            cheat.ui.tabs.visuals = cheat.ui.window:tab({name = "visuals"})
            cheat.ui.tabs.misc = cheat.ui.window:tab({name = "miscellaneous"})
        end

        do -- // ui start
            -- // combat
            local combat_column_one = cheat.ui.tabs.combat:column()
            local combat_column_two = cheat.ui.tabs.combat:column()
            -- // visuals
            local viauls_column_one = cheat.ui.tabs.visuals:column()
            local viauls_column_two = cheat.ui.tabs.visuals:column()
			-- // misc
			local misc_column_one = cheat.ui.tabs.misc:column()
            local misc_column_two = cheat.ui.tabs.misc:column()
            do -- // combat
                local main, drawings = combat_column_one:multi_section({names = {"main", "drawings"}});
                do -- // combat main and drawings
                    do -- // main
                        main:toggle({flag = "combat enabled", name = "enabled", default = false, tooltip = "keybind is for aimbot", callback = function(v) end})
							:keybind({flag = "aimbot bind", name = "aimbot bind", ignore_key = false, key = Enum.UserInputType.MouseButton2, mode = "hold"})
						main:slider({flag = "silent_aim_hitchance", name = "Silent Aim Hitchance", min = 0, max = 100, default = 67, interval = 0.1, callback = function(v) end})
						main:toggle({flag = "manipulation", name = "manipulation", default = false, callback = function(v) end})
							:colorpicker({flag = "manipulation color", name = "color", color = Color3.fromRGB(84,160,149), callback = function(v) end})
						main:toggle({flag = "TeleportBullet", name = "Teleport to bullet", default = false, callback = function(v) end})
						--[[ main:toggle({flag = "Hitscan", name = "Hit Scan", default = false, callback = function(v) end})
							:colorpicker({flag = "Hitscan color", name = "color", color = Color3.fromRGB(84,160,149), callback = function(v) end})
						main:toggle({flag = "wall bang", name = "wall bang", default = false, callback = function(v) end})
							:colorpicker({flag = "wall bang color", name = "color", color = Color3.fromRGB(84,160,149), callback = function(v) end}) ]]
                        main:toggle({flag = "combat auto shoot", name = "auto manipulate", tooltip = "autoshoot will only work with manipulation", default = false, callback = function(v) end})
                            :keybind({flag = "auto shoot bind", name = "autoshoot bind", ignore_key = false, key = nil, mode = "toggle"})
						main:dropdown({flag = "combat target", name = "target", items = {"players", "ai"}, multi = true, default = {"players"}, callback = function(v) end})
						main:dropdown({flag = "combat target type", name = "target type", items = {"closest to mouse", "closest to screen center"}, multi = false, default = "closest to mouse", callback = function(v) end})
                        main:dropdown({flag = "combat mode", name = "mode", items = {"silent", "aimbot"}, multi = false, default = "silent", callback = function(v) end})
                        main:slider({flag = "combat smoothing", name = "smoothing (%)", min = 0, max = 100, default = 0, interval = 1, callback = function(v) end})
                        main:dropdown({flag = "combat hitboxes", name = "hitbox", items = cheat.hitboxes, multi = false, default = "Head", callback = function(v) end})
                        main:dropdown({flag = "combat conditions", name = "conditions", items = {"visible", "health", "team", "invisible"}, multi = true, default = {""}, callback = function(v) end})
                        main:slider({flag = "combat maximum distance", name = "maximum distance (m)", min = 0, max = 10000, default = 1000, interval = 1, callback = function(v) end})
                    end 

                    do -- // drawings
                        drawings:toggle({flag = "drawings fov", name = "draw field of view circle", default = false, callback = function(v) end})
                            :colorpicker({flag = "drawings fov color one", name = "color one", color = Color3.fromRGB(0, 0, 0), callback = function(v) end})
                            :colorpicker({flag = "drawings fov color two", name = "color two", color = Color3.fromRGB(84,160,149), callback = function(v) end})
						drawings:toggle({flag = "drawings fov fill", name = "fill field of view circle", default = false, callback = function(v) end})
						 	:colorpicker({flag = "drawings fov fill color one", name = "color one", color = Color3.fromRGB(0, 0, 0), callback = function(v) end})
                            :colorpicker({flag = "drawings fov fill color two", name = "color two", color = Color3.fromRGB(84,160,149), callback = function(v) end})
						drawings:slider({flag = "drawings fov radius", name = "radius", min = 0, max = 1000, default = 300, interval = 1, callback = function(v) end})
						drawings:slider({flag = "drawings fov thickness", name = "thickness", min = 1, max = 10, default = 1, interval = 1, callback = function(v) end})
						drawings:slider({flag = "drawings fov sides", name = "sides", min = 0, max = 360, default = 360, interval = 1, callback = function(v) end})
						drawings:dropdown({flag = "drawings fov size", name = "field of view size", items = {"normal", "dynamic"}, default = "normal", callback = function(v) end})
						drawings:dropdown({flag = "drawings fov position", name = "field of view position", items = {"center", "mouse", "barrel"}, default = "mouse", callback = function(v) end})
						drawings:toggle({flag = "fov animation", name = "animate field of view circle", default = false, callback = function(v) end})
						drawings:dropdown({flag = "fov animation elements", name = "elements", items = {"circle", "fill"}, multi = true, default = {""}, callback = function(v) end})
						drawings:dropdown({flag = "fov animation easing style", name = "easing style", items = {"Linear","Sine","Back","Bounce","Circular","Cubic","Elastic","Exponential","Quadratic","Quart","Quint"}, default = "Linear", callback = function(v) end})
                        drawings:dropdown({flag = "fov animation easing direction", name = "easing directions", items = {"In","Out","InOut"}, default = "In", callback = function(v) end})
                        drawings:slider({flag = "fov animation speed", name = "animation speed", min = 0, max = 1000, default = 100, interval = 1, callback = function(v) end})
						drawings:toggle({flag = "drawings fireport line", name = "draw fireport line", default = false, callback = function(v) end})
                            :colorpicker({flag = "drawings fireport line color one", name = "color one", color = Color3.fromRGB(84,160,149), callback = function(v) end})
						drawings:slider({flag = "drawings fireport line thickness", name = "thickness", min = 1, max = 10, default = 1, interval = 1, callback = function(v) end})
						drawings:dropdown({flag = "drawings fireport line position", name = "fireport line position", items = {"center", "mouse", "barrel"}, default = "mouse", callback = function(v) end})
					end
                end
				--
				local projectile = combat_column_one:section({name = "projectile"})
				do
					do -- // projectile mods
						local utility = {
							services = { 
								players = cloneref(game:GetService("Players")),
								workspace = cloneref(game:GetService("Workspace")),
								userinputservice = cloneref(game:GetService("UserInputService")),
								runservice = cloneref(game:GetService("RunService")),
								httpservice = cloneref(game:GetService("HttpService")),
								coregui = cloneref(game:GetService("CoreGui")),
								lighting = cloneref(game:GetService("Lighting")),
								guiservice = cloneref(game:GetService("GuiService")),
								replicatedstorage = cloneref(game:GetService("ReplicatedStorage")),
								networkclient = cloneref(game:GetService("NetworkClient"))
							}
						}
						
						local weapon_modifications = {
							no_recoil = false,
							no_spread = false,
							old_vm_mults = {},
						}

						local toolInfo = require(game:GetService("ReplicatedStorage").Modules.ToolInfo)
						local function forEachTool(callback)
							for _, v in pairs(toolInfo) do
								if type(v) == "table" then
									callback(v)
								end
							end
						end
						local cache_equip_speed = {}
						local cache_melee_speed = {}
						local instantAimSpeed = {}
						local old_gun_vm = {}
						local originalRecoilValues = {}
						local originalSpreadValues = {}
						local current_boost = 50
						local cache_rpm = {}

						local function applyRecoil()
							for _, v in pairs(require(utility.services.replicatedstorage.Modules.ToolInfo)) do
								if type(v) == "table" and v.Recoil and type(v.Recoil.Camera) == "table" then
									if weapon_modifications.no_recoil then
										if not originalRecoilValues[v] then
											originalRecoilValues[v] = v.Recoil.Camera.FinishStart
										end
										v.Recoil.Camera.FinishStart = 0
									else
										if originalRecoilValues[v] then
											v.Recoil.Camera.FinishStart = originalRecoilValues[v]
										end
									end
								end
							end
						end              
						
						local function applySpread()
							for i, v in pairs(require(game.ReplicatedStorage.Modules.ToolInfo)) do
								if type(v) == "table" then
									if weapon_modifications.no_spread and v.Spread then
										if not originalSpreadValues[v] then
											originalSpreadValues[v] = {
												hip = v.Spread.Hip and table.clone(v.Spread.Hip),
												shooting = v.Spread.Shooting and table.clone(v.Spread.Shooting),
												aiming = v.Spread.Aiming and table.clone(v.Spread.Aiming)
											}
										end
										
										if type(v.Spread.Hip) == "table" then
											v.Spread.Hip.Moving = 0
											v.Spread.Hip.ShootingExtra = 0
											v.Spread.Hip.Idle = 0
										end
										
										if type(v.Spread.Shooting) == "table" then
											v.Spread.Shooting.DecayEnd = 0
											v.Spread.Shooting.DecayStart = 0
										end
										
										if type(v.Spread.Aiming) == "table" then
											v.Spread.Aiming.Moving = 0
											v.Spread.Aiming.ShootingExtra = 0
											v.Spread.Aiming.Idle = 0
										end
									else
										if originalSpreadValues[v] then
											if originalSpreadValues[v].hip then
												v.Spread.Hip = originalSpreadValues[v].hip
											end
											if originalSpreadValues[v].shooting then
												v.Spread.Shooting = originalSpreadValues[v].shooting
											end
											if originalSpreadValues[v].aiming then
												v.Spread.Aiming = originalSpreadValues[v].aiming
											end
										end
									end
								end
							end       
						end
						projectile:toggle({flag = "No Recoil", name = "No Recoil", default = false, callback = function(value)	weapon_modifications.no_recoil = value applyRecoil() end})
						projectile:toggle({flag = "No Spread", name = "No Spread", default = false, callback = function(value) weapon_modifications.no_spread = value applySpread() end})
						projectile:toggle({flag = "No Bob", name = "No Bob", default = false, callback = function(value) 
							local getgc = getgc or function() return {} end
                            weapon_modifications.old_vm_mults = weapon_modifications.old_vm_mults or {}

                            if value then
                                for _, tbl in pairs(getgc(true)) do
                                    if type(tbl) == "table" then
                                        local vm_movement_mults = rawget(tbl, "VMMovementMults")
                                        if vm_movement_mults then
                                            if not weapon_modifications.old_vm_mults[vm_movement_mults] then
                                                weapon_modifications.old_vm_mults[vm_movement_mults] = {}
                                            end

                                            for i, v in pairs(vm_movement_mults) do
                                                if weapon_modifications.old_vm_mults[vm_movement_mults][i] == nil then
                                                    weapon_modifications.old_vm_mults[vm_movement_mults][i] = v
                                                end
                                                vm_movement_mults[i] = 0
                                            end
                                        end
                                    end
                                end
                            else
                                for vm_mults, savedValues in pairs(weapon_modifications.old_vm_mults) do
                                    for i, v in pairs(savedValues) do
                                        vm_mults[i] = v
                                    end
                                end
                                weapon_modifications.old_vm_mults = {}
                            end
						end})
						projectile:toggle({flag = "No Shoot Animation", name = "No Shoot Animation", default = false, callback = function(value)
							if value then
                                for _, tbl in pairs(getgc(true)) do
                                    if type(tbl) ~= 'table' then
                                        continue
                                    end

                                    local vm_tbl = rawget(tbl, 'VM')

                                    if vm_tbl and type(vm_tbl) == 'table' then
                                        local pos_tbl = rawget(vm_tbl, 'Pos')
                                        local rot_tbl = rawget(vm_tbl, 'Rot')

                                        if pos_tbl then
                                            if not old_gun_vm[pos_tbl] then
                                                old_gun_vm[pos_tbl] = {}
                                                for i, v in pairs(pos_tbl) do
                                                    old_gun_vm[pos_tbl][i] = v
                                                end
                                            end
                                            for i, _ in pairs(pos_tbl) do
                                                pos_tbl[i] = 0
                                            end
                                        end

                                        if rot_tbl then
                                            if not old_gun_vm[rot_tbl] then
                                                old_gun_vm[rot_tbl] = {}
                                                for i, v in pairs(rot_tbl) do
                                                    old_gun_vm[rot_tbl][i] = v
                                                end
                                            end
                                            for i, _ in pairs(rot_tbl) do
                                                rot_tbl[i] = 0
                                            end
                                        end
                                    end
                                end
                            else
                                for tbl, data in pairs(old_gun_vm) do
                                    for i, v in pairs(data) do
                                        tbl[i] = v
                                    end
                                end
                                old_gun_vm = {}
                            end
						end})
						projectile:toggle({flag = "Fast Equip", name = "Fast Equip", default = false, callback = function(value)
							local toolInfo = require(utility.services.replicatedstorage.Modules.ToolInfo)
                            for _, v in pairs(toolInfo) do
                                if type(v) == "table" and v.Weapon then
                                    if value then
                                        cache_equip_speed[v] = v.Weapon.EquipAnimSpeed
                                        v.Weapon.EquipAnimSpeed = 5
                                    else
                                        if cache_equip_speed[v] then
                                            v.Weapon.EquipAnimSpeed = cache_equip_speed[v]
                                            cache_equip_speed[v] = nil
                                        end
                                    end
                                end
                            end
						end})
						projectile:toggle({flag = "Instant Aim", name = "Instant Aim", default = false, callback = function(value)
							local toolInfo = require(utility.services.replicatedstorage.Modules.ToolInfo)
                            for _, v in pairs(toolInfo) do
                                if type(v) == "table" and v.Weapon and v.Weapon.AimDownSpeed then
                                    if value then
                                        instantAimSpeed[v] = v.Weapon.AimDownSpeed.In
                                        v.Weapon.AimDownSpeed.In = 0
                                    else
                                        if instantAimSpeed[v] then
                                            v.Weapon.AimDownSpeed.In = instantAimSpeed[v]
                                            instantAimSpeed[v] = nil
                                        end
                                    end
                                end
                            end
						end})
						projectile:toggle({flag = "Fast Swing", name = "Fast Swing", default = false, callback = function(value)
							local toolInfo = require(utility.services.replicatedstorage.Modules.ToolInfo)
                            for _, v in pairs(toolInfo) do
                                if type(v) == "table" and v.Weapon then
                                    if value then
                                        cache_melee_speed[v] = v.Weapon.Cooldown
                                        v.Weapon.Cooldown = 1.10
                                    else
                                        if cache_melee_speed[v] then
                                            v.Weapon.Cooldown = cache_melee_speed[v]
                                            cache_melee_speed[v] = nil
                                        end
                                    end
                                end
                            end
						end})
						projectile:toggle({flag = "No Drop", name = "No Drop", default = false, callback = function(value)
							local toolInfo = require(utility.services.replicatedstorage.Modules.ToolInfo)
                            for _, weaponData in pairs(toolInfo) do
                                if type(weaponData) == "table" and weaponData.Weapon and weaponData.Weapon.Bullet then
                                    local bullet = weaponData.Weapon.Bullet
                                    if state then
                                        if not bullet_gravity_cache[weaponData] then
                                            bullet_gravity_cache[weaponData] = bullet.Gravity or 0
                                            bullet.Gravity = 0
                                        end
                                    else
                                        if bullet_gravity_cache[weaponData] then
                                            bullet.Gravity = bullet_gravity_cache[weaponData]
                                            bullet_gravity_cache[weaponData] = nil
                                        end
                                    end
                                end
                            end
						end})

						projectile:toggle({flag = "RPM", name = "RPM", default = false, callback = function(value)
							getgenv().RPM = value
                            local toolInfo = require(utility.services.replicatedstorage.Modules.ToolInfo)
                            if not value then
                                for _, v in pairs(toolInfo) do
                                    if type(v) == "table" and v.Weapon then
                                        if cache_rpm[v] then
                                            v.Weapon.RPM = cache_rpm[v]
                                            cache_rpm[v] = nil
                                        end
                                    end
                                end
                            else
                                for _, v in pairs(toolInfo) do
                                    if type(v) == "table" and v.Weapon then
                                        cache_rpm[v] = v.Weapon.RPM
                                        v.Weapon.RPM = current_boost * 10
                                    end
                                end
                            end
						end})

						projectile:slider({flag = "RPM AMOUNT", name = "amount", min = 0, max = 100, default = 50, interval = 1, callback = function(value)
							current_boost = value
                            if getgenv().RPM then
                                local toolInfo = require(utility.services.replicatedstorage.Modules.ToolInfo)
                                for _, v in pairs(toolInfo) do
                                    if type(v) == "table" and v.Weapon then
                                        if not cache_rpm[v] then
                                            cache_rpm[v] = v.Weapon.RPM
                                        end
                                        v.Weapon.RPM = value * 10
                                    end
                                end
                            end
						end})

						projectile:toggle({flag = "instant_bullet", name = "instant bullet", default = false, callback = function(value) end})
						projectile:dropdown({flag = "instant_bullet_methods", name = "method", items = {"Speed", "Teleport"}, default = "Speed", callback = function(v) end})
						projectile:toggle({flag = "instant loot", name = "instant loot", default = false, callback = function(v) end}) -- this is in vanity
					end
				end
				--
                local visuals, sounds = combat_column_two:multi_section({names = {"visuals", "sounds"}})
                do -- // weapon mods and visuals
                    do -- // visuals
						local colors = visuals:toggle({flag = "bullet tracer", name = "bullet tracers", default = false, callback = function(v) end})
						    colors:colorpicker({flag = "bullet tracer color", name = "color", color = Color3.fromRGB(84,160,149), callback = function(v) end})
							colors:colorpicker({flag = "bullet tracer color2", name = "color", color = Color3.fromRGB(172, 47, 255), callback = function(v) end})
                        visuals:slider({flag = "bullet tracer life", name = "lifetime (s)", min = 0, max = 5, default = 2, interval = 1, callback = function(v) end})
                        visuals:dropdown({flag = "bullet tracer style", name = "style", items = {"default", "beam", "ion beam", "lightning", "pulsing", "dna"}, default = "default", callback = function(v) end})
						visuals:toggle({flag = "hit marker", name = "hit markers", default = false, callback = function(v) end})
						    :colorpicker({flag = "hit marker color", name = "color", color = Color3.fromRGB(84,160,149), callback = function(v) end})
                        visuals:slider({flag = "hit marker life", name = "lifetime (s)", min = 0, max = 5, default = 2, interval = 1, callback = function(v) end})
						--[[ visuals:toggle({flag = "hit notifications", name = "hit notifications", default = false, callback = function(v) end})
						visuals:dropdown({flag = "hit notifications options", name = "options", items = {"Name","Part","Distance","New Health"}, default = "", callback = function(v) print(v) end}) ]]
                    end

					do -- // sounds ( you may wanna use childadded? you arent consta checking if theres a new child for the hitsounds that yu cahnge the ids of!!! )
						local function get_keys(tbl)
							local keys = {}
							for k in pairs(tbl) do
								table.insert(keys, k)
							end
							table.sort(keys)
							return keys
						end
						sounds:toggle({flag = "hit sounds", name = "head hit sound", default = false, callback = function(Value)
							cheat.hitsound_settings.head.enabled = Value
							local s = game:GetService("SoundService"):FindFirstChild("HitHead")
							if s then
								if Value then
									s.SoundId = cheat.hit_sounds[cheat.hitsound_settings.head.selection]
									s.Volume = cheat.hitsound_settings.head.volume
								else
									s.SoundId = "rbxassetid://988593556"
									s.Volume = 0.8
								end
							end
						end})
						sounds:dropdown({flag = "hit sounds sound head", name = "head shot sound", items = get_keys(cheat.hit_sounds), default = "Rust", callback = function(Value)	
							cheat.hitsound_settings.head.selection = Value
							local s = game:GetService("SoundService"):FindFirstChild("HitHead")
							if s then
								if cheat.hitsound_settings.head.enabled then
									s.SoundId = cheat.hit_sounds[Value]
									s:Play()
								else
									s.SoundId = "rbxassetid://988593556"
									s.Volume = 0.8
								end
							end
						end})
                        sounds:slider({flag = "hit sound volume head", name = "volume (db)", min = 0, max = 10, default = 5, interval = 1, callback = function(Value)
							cheat.hitsound_settings.head.volume = Value
							local s = game:GetService("SoundService"):FindFirstChild("HitHead")
							if s and cheat.hitsound_settings.head.enabled then
								s.Volume = Value
							end
						end})
						-- //
						sounds:toggle({flag = "hit sounds body", name = "body hit sound", default = false, callback = function(Value)
							cheat.hitsound_settings.body.enabled = Value
							local s = game:GetService("SoundService"):FindFirstChild("Hit")
							if s then
								if Value then
									s.SoundId = cheat.hit_sounds[cheat.hitsound_settings.body.selection]
									s.Volume = cheat.hitsound_settings.body.volume
								else
									s.SoundId = "rbxassetid://160432334"
									s.Volume = 0.6
								end
							end
						end})
						sounds:dropdown({flag = "bodyshot sound body", name = "body shot sound", items = get_keys(cheat.hit_sounds), default = "Rust", callback = function(Value) 
							cheat.hitsound_settings.body.selection = Value
							local s = game:GetService("SoundService"):FindFirstChild("Hit")
							if s then
								if cheat.hitsound_settings.body.enabled then
									s.SoundId = cheat.hit_sounds[Value]
									s:Play()
								else
									s.SoundId = "rbxassetid://160432334"
									s.Volume = 0.6
								end
							end
						end})
						sounds:slider({flag = "hit sound volume head", name = "volume (db)", min = 0, max = 10, default = 5, interval = 1, callback = function(Value)
							cheat.hitsound_settings.body.volume = Value
							local s = game:GetService("SoundService"):FindFirstChild("Hit")
							if s and cheat.hitsound_settings.body.enabled then
								s.Volume = Value
							end
						end})
					end
				end
				--
				local targeting = combat_column_two:section({name = "targeting"})
				do 
					targeting:toggle({flag = "targeting show target info", name = "show target info", default = false, callback = function(v) end})
					--[[ targeting:toggle({flag = "targeting show target belt", name = "show target belt", default = false, callback = function(v) end})
					targeting:toggle({flag = "targeting show target armor", name = "show target armor", default = false, callback = function(v) end}) ]]
					targeting:toggle({flag = "combat notify target", name = "target notify", default = false, callback = function(v) end})
					targeting:toggle({flag = "targeting effects", name = "target effects", tooltip = "shows an effect around the targeted player", default = false, callback = function(v) end})
						:colorpicker({flag = "targeting effects color", name = "color", color = Color3.fromRGB(84,160,149), callback = function(v) end})
					targeting:slider({flag = "targeting effects rate", name = "rate", min = 0, max = 20, default = 20, interval = 1, callback = function(v) end})
				end
            end
			-- // visuals
			do
				local enemies = viauls_column_one:column():section({name = "Visuals"})
				local world = viauls_column_one:column():section({name = "Environment"})
				local View_Model, Camera_Mods = viauls_column_two:multi_section({names = {"View Model", "Camera"}})
				local Crosshair = viauls_column_two:column():section({name = "Crosshair"})
				-- // esp
				do
					local team_settings = esp_library.team_settings;
					
					enemies:toggle({flag = "esp_enemy_enabled", name = "enabled", default = false, callback = function(Value) team_settings.enemy.enabled = Value end})
					enemies:toggle({flag = "esp_enemy_box_enabled", name = "box", default = false, callback = function(Value) team_settings.enemy.box = Value end})
						:colorpicker({flag = "esp_enemy_box_color", name = "color", color = Color3.fromRGB(255, 255, 255), callback = function(Value) team_settings.enemy.box_color = Value end})
					
					enemies:toggle({flag = "esp_enemy_healthbar_enabled", name = "healthbar", default = false, callback = function(Value) team_settings.enemy.health_bar = Value end})
						:colorpicker({flag = "esp_enemy_healthbar_color", name = "color", color = Color3.fromRGB(60, 195, 0), callback = function(Value) team_settings.enemy.health_bar_color = Value end})
					
					enemies:toggle({flag = "esp_enemy_healthtext_enabled", name = "health text", default = false, callback = function(Value) team_settings.enemy.health_text = Value end})
						:colorpicker({flag = "esp_enemy_healthtext_color", name = "color", color = Color3.fromRGB(60, 195, 0), callback = function(Value) team_settings.enemy.health_text_color = Value end})
					
					enemies:toggle({flag = "esp_enemy_name_enabled", name = "name", default = false, callback = function(Value) team_settings.enemy.name_text = Value end})
						:colorpicker({flag = "esp_enemy_name_color", name = "color", color = Color3.fromRGB(255, 255, 255), callback = function(Value) team_settings.enemy.name_text_color = Value end})
					
					enemies:toggle({flag = "esp_enemy_weapon_enabled", name = "weapon", default = false, callback = function(Value) team_settings.enemy.weapon_text = Value end})
						:colorpicker({flag = "esp_enemy_weapon_color", name = "color", color = Color3.fromRGB(255, 255, 255), callback = function(Value) team_settings.enemy.weapon_text_color = Value end})
					
					enemies:toggle({flag = "esp_enemy_distance_enabled", name = "distance", default = false, callback = function(Value) team_settings.enemy.dist_text = Value end})
						:colorpicker({flag = "esp_enemy_distance_color", name = "color", color = Color3.fromRGB(255, 255, 255), callback = function(Value) end})
					
					enemies:toggle({flag = "esp_enemy_healthbar_dynamic", name = "dynamic healthbar", default = false, callback = function(Value) team_settings.enemy.dynamic_color = Value end})
					
					enemies:dropdown({flag = "esp_enemy_box_type", name = "box type", items = {"box", "corner"}, multi = false, default = "box", callback = function(Value) team_settings.enemy.box_type = Value end})

					enemies:toggle({flag = "limit_distance", name = "limit distance", default = false, callback = function(Value) esp_library.shared_settings.limit_distance = Value end})

					enemies:slider({flag = "max_distance", name = "max distance", min = 0, max = 10000, default = 0, interval = 1, callback = function(Value) esp_library.shared_settings.max_distance = Value end})
				end

				-- // view model
				do
					local armsHighlights = {}
					local weaponHighlights = {}

					View_Model:toggle({flag = "ViewModelPos", name = "View Model Position", default = false, callback = function(Value) szneo.ViewModelFunc(Value,flags["ViewModelPosX"],flags["ViewModelPosY"],flags["ViewModelPosZ"]) end})
					View_Model:slider({flag = "ViewModelPosX", name = "View Model Position X", min = -5, max = 5, default = 0, interval = 0.1, callback = function(Value) szneo.ViewModelFunc(flags["ViewModelPos"],Value,flags["ViewModelPosY"],flags["ViewModelPosZ"]) end})
					View_Model:slider({flag = "ViewModelPosY", name = "View Model Position Y", min = -5, max = 5, default = 0, interval = 0.1, callback = function(Value) szneo.ViewModelFunc(flags["ViewModelPos"],flags["ViewModelPosX"],Value,flags["ViewModelPosZ"]) end})
					View_Model:slider({flag = "ViewModelPosZ", name = "View Model Position Z", min = -5, max = 5, default = 0, interval = 0.1, callback = function(Value) szneo.ViewModelFunc(flags["ViewModelPos"],flags["ViewModelPosX"],flags["ViewModelPosY"],Value) end})

					View_Model:toggle({flag = "ViewmodelArms", name = "Arms", default = false, callback = function(Value) cheat.viewmodel.local_chams.enabled = Value end})
						:colorpicker({flag = "ViewmodelArmsColor", name = "color", color = Color3.fromRGB(84,160,149), callback = function(Value) cheat.viewmodel.local_chams.color = Value end})
					View_Model:slider({flag = "ViewmodelArmsTrans", name = "Transparency", min = 0, max = 100, default = 0, interval = 1, callback = function(Value) cheat.viewmodel.local_chams.transparency = Value / 100 end})
					View_Model:dropdown({flag = "ViewmodelArmsMaterial", name = "Material", items = {"ForceField", "Neon", "CrackedLava", "Glass", "SmoothPlastic"}, multi = false, default = "ForceField", callback = function(Value) cheat.viewmodel.local_chams.material = Enum.Material[Value] or Enum.Material.Plastic end})
					
					View_Model:toggle({flag = "ViewmodelWeapon", name = "Weapon", default = false, callback = function(Value) cheat.viewmodel.weapon_chams.enabled = Value end})
						:colorpicker({flag = "ViewmodelWeaponsColor", name = "color", color = Color3.fromRGB(84,160,149), callback = function(Value) cheat.viewmodel.weapon_chams.color = Value end})
					View_Model:slider({flag = "ViewmodelWeaponTrans", name = "Transparency", min = 0, max = 100, default = 0, interval = 1, callback = function(Value) cheat.viewmodel.weapon_chams.transparency = Value / 100 end})
					View_Model:dropdown({flag = "ViewmodelWeaponMaterial", name = "Material", items = {"ForceField", "Neon", "CrackedLava", "Glass", "SmoothPlastic"}, multi = false, default = "ForceField", callback = function(Value) cheat.viewmodel.weapon_chams.material = Enum.Material[Value] or Enum.Material.Plastic end})
					
					local highlightsamrs = View_Model:toggle({flag = "ArmsHighlights", name = "Arms Highlights", default = false, callback = function(Value) 
						cheat.viewmodel.local_highlights.enabled = Value
						if not Value then
							for part, highlight in pairs(armsHighlights) do
								if highlight then
									highlight:Destroy()
								end
							end
							armsHighlights = {}
						end
					end})
					
					highlightsamrs:colorpicker({flag = "armsinline", name = "inline", color = Color3.fromRGB(84,160,149), callback = function(Value)
						cheat.viewmodel.local_highlights.inlineColor = Value
						for part, highlight in pairs(armsHighlights) do
							if highlight then
								highlight.FillColor = Value
							end
						end
					end})
					
					highlightsamrs:colorpicker({flag = "armsoutline", name = "outline", color = Color3.fromRGB(84,160,149), callback = function(Value)
						cheat.viewmodel.local_highlights.outlineColor = Value
						for part, highlight in pairs(armsHighlights) do
							if highlight then
								highlight.OutlineColor = Value
							end
						end
					end})
					
					View_Model:slider({flag = "armsinlinetrans", name = "Inline Transparency", min = 0, max = 100, default = 0, interval = 1, callback = function(Value)
						cheat.viewmodel.local_highlights.fillTransparency = Value / 100
						for part, highlight in pairs(armsHighlights) do
							if highlight then
								highlight.FillTransparency = Value / 100
							end
						end
					end})
					
					View_Model:slider({flag = "armsoutlinetrans", name = "Outline Transparency", min = 0, max = 100, default = 0, interval = 1, callback = function(Value)
						cheat.viewmodel.local_highlights.outlineTransparency = Value / 100
						for part, highlight in pairs(armsHighlights) do
							if highlight then
								highlight.OutlineTransparency = Value / 100
							end
						end
					end})
					
					local highlightsweapon = View_Model:toggle({flag = "WeaponHighlights", name = "Weapon Highlights", default = false, callback = function(Value) 
						cheat.viewmodel.weapon_highlights.enabled = Value
						if not Value then
							for part, highlight in pairs(weaponHighlights) do
								if highlight then
									highlight:Destroy()
								end
							end
							weaponHighlights = {}
						end
					end})
					
					highlightsweapon:colorpicker({flag = "weaponinline", name = "inline", color = Color3.fromRGB(84,160,149), callback = function(Value)
						cheat.viewmodel.weapon_highlights.inlineColor = Value
						for part, highlight in pairs(weaponHighlights) do
							if highlight then
								highlight.FillColor = Value
							end
						end
					end})
					
					highlightsweapon:colorpicker({flag = "weaponoutline", name = "outline", color = Color3.fromRGB(84,160,149), callback = function(Value)
						cheat.viewmodel.weapon_highlights.outlineColor = Value
						for part, highlight in pairs(weaponHighlights) do
							if highlight then
								highlight.OutlineColor = Value
							end
						end
					end})
					
					View_Model:slider({flag = "weaponinlinetrans", name = "Inline Transparency", min = 0, max = 100, default = 0, interval = 1, callback = function(Value)
						cheat.viewmodel.weapon_highlights.fillTransparency = Value / 100
						for part, highlight in pairs(weaponHighlights) do
							if highlight then
								highlight.FillTransparency = Value / 100
							end
						end
					end})
					
					View_Model:slider({flag = "weaponoutlinetrans", name = "Outline Transparency", min = 0, max = 100, default = 0, interval = 1, callback = function(Value)
						cheat.viewmodel.weapon_highlights.outlineTransparency = Value / 100
						for part, highlight in pairs(weaponHighlights) do
							if highlight then
								highlight.OutlineTransparency = Value / 100
							end
						end
					end})
					
					local originalAppearanceCache = {}
					
					local function cacheOriginal(part)
						if not originalAppearanceCache[part] then
							originalAppearanceCache[part] = {
								Material = part.Material,
								Color = part.Color,
								Transparency = part.Transparency,
								TextureID = part:IsA("MeshPart") and part.TextureID or nil
							}
						end
					end

					local function applyChamToPart(part, chamSettings)
						cacheOriginal(part)
						part.Material = chamSettings.material
						part.Color = chamSettings.color
						part.Transparency = chamSettings.transparency
						if part:IsA("MeshPart") then
							if chamSettings.material == Enum.Material.ForceField then
								part.TextureID = "rbxassetid://5843010904"
							else
								part.TextureID = ""
							end
						end
					end

					local function restoreOriginalPart(part)
						local cached = originalAppearanceCache[part]
						if cached then
							part.Material = cached.Material
							part.Color = cached.Color
							part.Transparency = cached.Transparency
							if part:IsA("MeshPart") and cached.TextureID then
								part.TextureID = cached.TextureID
							end
							originalAppearanceCache[part] = nil
						end
					end

					local function applyHighlightToPart(part, highlightSettings, highlightsTable)
						if not part:IsA("BasePart") or part.Transparency == 1 then return end
						
						local highlight = highlightsTable[part]
						if not highlight then
							highlight = Instance.new("Highlight")
							highlight.Adornee = part
							highlight.Parent = part
							highlightsTable[part] = highlight
						end
						
						highlight.FillColor = highlightSettings.inlineColor
						highlight.FillTransparency = highlightSettings.fillTransparency
						highlight.OutlineColor = highlightSettings.outlineColor
						highlight.OutlineTransparency = highlightSettings.outlineTransparency
						highlight.Enabled = true
						
						return highlight
					end

					local function removeHighlightFromPart(part, highlightsTable)
						local highlight = highlightsTable[part]
						if highlight then
							highlight:Destroy()
							highlightsTable[part] = nil
						end
					end

					RunService.RenderStepped:Connect(function()
						local vfx = workspace:FindFirstChild("VFX")
						if not vfx then return end
						
						local vms = vfx:FindFirstChild("VMs")
						if not vms then return end
						
						for _, v in ipairs(vms:GetChildren()) do
							if v:IsA("Model") then
								local arms = v:FindFirstChild("Arms")
								local weapon = v:FindFirstChild("Weapon")

								if arms then
									for _, part in ipairs(arms:GetDescendants()) do
										if part:IsA("BasePart") and part.Transparency ~= 1 then
											if cheat.viewmodel.local_chams.enabled then
												applyChamToPart(part, cheat.viewmodel.local_chams)
											else
												restoreOriginalPart(part)
											end
											
											if cheat.viewmodel.local_highlights.enabled then
												applyHighlightToPart(part, cheat.viewmodel.local_highlights, armsHighlights)
											else
												removeHighlightFromPart(part, armsHighlights)
											end
										end
									end
								end

								if weapon then
									for _, part in ipairs(weapon:GetDescendants()) do
										if part:IsA("BasePart") and part.Transparency ~= 1 then
											if cheat.viewmodel.weapon_chams.enabled then
												applyChamToPart(part, cheat.viewmodel.weapon_chams)
											else
												restoreOriginalPart(part)
											end
											
											if cheat.viewmodel.weapon_highlights and cheat.viewmodel.weapon_highlights.enabled then
												applyHighlightToPart(part, cheat.viewmodel.weapon_highlights, weaponHighlights)
											else
												removeHighlightFromPart(part, weaponHighlights)
											end
										end
									end
								end
							end
						end
					end)
				end

				-- // camera
				do
					-- // camera fov
					do
						do
							Camera_Mods:toggle({flag = "field_of_view", name = "field of view", default = false, callback = function(v) end})
							Camera_Mods:slider({flag = "fov_changer_value", name = "amount", min = 70, max = 120, default = 90, interval = 1, callback = function(v) end})
							Camera_Mods:label({name = "Zoom"}):keybind({flag = "fov_zoom", name = "zoom", ignore_key = false, mode = "hold", callback = function(v) 
								flags["fov_zoom_active"] = v 
							end})
							Camera_Mods:slider({flag = "fov_zoom_amount", name = "amount", min = 10, max = 70, default = 30, interval = 1, callback = function(v) end})
						end
						
						game:GetService("RunService").RenderStepped:Connect(function()
							if flags["field_of_view"] then
								local camera = workspace.CurrentCamera
								if camera then
									if flags["fov_zoom_active"] then
										camera.FieldOfView = flags["fov_zoom_amount"]
									else
										camera.FieldOfView = flags["fov_changer_value"]
									end
								end
							end
						end)
						
						local oldFOv 
						oldFOv = hookmetamethod(game, "__newindex", newcclosure(function(instance, prop, value)
							if instance.Name == "Camera" and prop == "FieldOfView" and flags["field_of_view"] then
								if flags["fov_zoom_active"] then
									value = flags["fov_zoom_amount"]
								else
									value = flags["fov_changer_value"]
								end
							end
							return oldFOv(instance, prop, value)
						end))
					end
					-- // thirdperson
					do
						local camera = workspace.CurrentCamera
						local mt = getrawmetatable(game)
						local oldIndex = mt.__index
						local oldNewIndex = mt.__newindex
						local hooked = false
						local offset = Vector3.new(0, -2.3, -12)

						local function enableThirdPerson(enabled)
							setreadonly(mt, false)
							if enabled then
								mt.__index = function(t, k)
									if t == camera and k == "CFrame" then
										return oldIndex(t, k) * CFrame.new(offset)
									end
									return oldIndex(t, k)
								end

								mt.__newindex = function(t, k, v)
									if t == camera and k == "CFrame" then
										return oldNewIndex(t, k, v * CFrame.new(-offset))
									end
									return oldNewIndex(t, k, v)
								end

								hooked = true
							else
								mt.__index = oldIndex
								mt.__newindex = oldNewIndex
								hooked = false
							end
							setreadonly(mt, true)
						end

						Camera_Mods:toggle({name = "Third Person", flag = "ThirdPersontoggle", default = false, callback = function(enabled) enableThirdPerson(enabled) end})
							:keybind({name = "Third Person", key = Enum.KeyCode.J, callback = function(state) library.config_flags["ThirdPersontoggle"](state) end})

						Camera_Mods:slider({name = "Distance", min = 0, max = 20, default = 12, interval = 1, flag = "Distanceslider", callback = function(value) offset = Vector3.new(offset.X, offset.Y, -value) end})
					end
				end

				-- // environment
				do
					local Lighting = game:GetService("Lighting")
					local RunService = game:GetService("RunService")
					
					local worldmods = {
						brightnessEnabled = false,
						Brightness = 2,
						ambientEnabled = false,
						Ambient = Color3.fromRGB(128,128,128),
						outdoorAmbientEnabled = false,
						OutdoorAmbient = Color3.fromRGB(200,200,200),
						timeEnabled = false,
						Time = 12,
						exposureEnabled = false,
						Exposure = 0,
						shadowSoftnessEnabled = false,
						ShadowSoftness = 0.2,
						colorShiftEnabled = false,
						ColorShiftTop = Color3.fromRGB(255,200,200),
						ColorShiftBottom = Color3.fromRGB(200,200,255),
						techEnabled = false,
						Technology = Enum.Technology.Compatibility,
						shadowEnabled = false,
						GlobalShadows = true,
						skyEnabled = false,
						Sky = {
							SkyboxBk="",SkyboxDn="",SkyboxFt="",SkyboxLf="",SkyboxRt="",SkyboxUp="",
							SunAngularSize=21,MoonAngularSize=11,StarCount=3000
						}
					}

					local originalValues = {
						Brightness = Lighting.Brightness,
						Ambient = Lighting.Ambient,
						OutdoorAmbient = Lighting.OutdoorAmbient,
						ClockTime = Lighting.ClockTime,
						ExposureCompensation = Lighting.ExposureCompensation,
						ShadowSoftness = Lighting.ShadowSoftness,
						ColorShift_Top = Lighting.ColorShift_Top,
						ColorShift_Bottom = Lighting.ColorShift_Bottom,
						GlobalShadows = Lighting.GlobalShadows
					}

					local function applyWorldMods()
						if worldmods.brightnessEnabled then 
							Lighting.Brightness = worldmods.Brightness 
						else
							Lighting.Brightness = originalValues.Brightness
						end

						if worldmods.ambientEnabled then 
							Lighting.Ambient = worldmods.Ambient 
						else
							Lighting.Ambient = originalValues.Ambient
						end

						if worldmods.outdoorAmbientEnabled then 
							Lighting.OutdoorAmbient = worldmods.OutdoorAmbient 
						else
							Lighting.OutdoorAmbient = originalValues.OutdoorAmbient
						end

						if worldmods.timeEnabled then 
							Lighting.ClockTime = worldmods.Time 
						else
							Lighting.ClockTime = originalValues.ClockTime
						end

						if worldmods.exposureEnabled then 
							Lighting.ExposureCompensation = worldmods.Exposure 
						else
							Lighting.ExposureCompensation = originalValues.ExposureCompensation
						end

						if worldmods.shadowSoftnessEnabled then 
							Lighting.ShadowSoftness = worldmods.ShadowSoftness 
						else
							Lighting.ShadowSoftness = originalValues.ShadowSoftness
						end

						if worldmods.colorShiftEnabled then 
							Lighting.ColorShift_Top = worldmods.ColorShiftTop
							Lighting.ColorShift_Bottom = worldmods.ColorShiftBottom
						else
							Lighting.ColorShift_Top = originalValues.ColorShift_Top
							Lighting.ColorShift_Bottom = originalValues.ColorShift_Bottom
						end

						if worldmods.techEnabled then
							settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
							Lighting.Technology = worldmods.Technology
						else
							Lighting.Technology = Enum.Technology.Compatibility
						end

						if worldmods.shadowEnabled then 
							Lighting.GlobalShadows = worldmods.GlobalShadows 
						else
							Lighting.GlobalShadows = originalValues.GlobalShadows
						end

						local sky = Lighting:FindFirstChildOfClass("Sky")
						if worldmods.skyEnabled then
							if not sky then
								sky = Instance.new("Sky", Lighting)
							end
							sky.SkyboxBk = worldmods.Sky.SkyboxBk
							sky.SkyboxDn = worldmods.Sky.SkyboxDn
							sky.SkyboxFt = worldmods.Sky.SkyboxFt
							sky.SkyboxLf = worldmods.Sky.SkyboxLf
							sky.SkyboxRt = worldmods.Sky.SkyboxRt
							sky.SkyboxUp = worldmods.Sky.SkyboxUp
							sky.SunAngularSize = worldmods.Sky.SunAngularSize
							sky.MoonAngularSize = worldmods.Sky.MoonAngularSize
							sky.StarCount = worldmods.Sky.StarCount
						else
							if sky then
								sky:Destroy()
							end
						end
					end

					RunService.Heartbeat:Connect(function()
						if worldmods.brightnessEnabled and Lighting.Brightness ~= worldmods.Brightness then
							Lighting.Brightness = worldmods.Brightness
						end
						
						if worldmods.ambientEnabled and Lighting.Ambient ~= worldmods.Ambient then
							Lighting.Ambient = worldmods.Ambient
						end
						
						if worldmods.outdoorAmbientEnabled and Lighting.OutdoorAmbient ~= worldmods.OutdoorAmbient then
							Lighting.OutdoorAmbient = worldmods.OutdoorAmbient
						end
						
						if worldmods.timeEnabled and Lighting.ClockTime ~= worldmods.Time then
							Lighting.ClockTime = worldmods.Time
						end
						
						if worldmods.exposureEnabled and Lighting.ExposureCompensation ~= worldmods.Exposure then
							Lighting.ExposureCompensation = worldmods.Exposure
						end
						
						if worldmods.shadowSoftnessEnabled and Lighting.ShadowSoftness ~= worldmods.ShadowSoftness then
							Lighting.ShadowSoftness = worldmods.ShadowSoftness
						end
						
						if worldmods.colorShiftEnabled and (Lighting.ColorShift_Top ~= worldmods.ColorShiftTop or Lighting.ColorShift_Bottom ~= worldmods.ColorShiftBottom) then
							Lighting.ColorShift_Top = worldmods.ColorShiftTop
							Lighting.ColorShift_Bottom = worldmods.ColorShiftBottom
						end
						
						if worldmods.shadowEnabled and Lighting.GlobalShadows ~= worldmods.GlobalShadows then
							Lighting.GlobalShadows = worldmods.GlobalShadows
						end
						
						if worldmods.skyEnabled then
							local sky = Lighting:FindFirstChildOfClass("Sky")
							if not sky then
								sky = Instance.new("Sky", Lighting)
							end
							if sky.SunAngularSize ~= worldmods.Sky.SunAngularSize then
								sky.SunAngularSize = worldmods.Sky.SunAngularSize
							end
							if sky.MoonAngularSize ~= worldmods.Sky.MoonAngularSize then
								sky.MoonAngularSize = worldmods.Sky.MoonAngularSize
							end
							if sky.StarCount ~= worldmods.Sky.StarCount then
								sky.StarCount = worldmods.Sky.StarCount
							end
						end
					end)

					world:toggle({flag = "No Grass", name = "No Grass", default = false, callback = function(state) 
						sethiddenproperty(workspace:FindFirstChildOfClass("Terrain"), "Decoration", not state) 
					end})
					
					world:toggle({name="Brightness",flag="world_brightness_toggle",default=false,callback=function(v) 
						worldmods.brightnessEnabled=v 
						applyWorldMods()
					end})
					world:slider({name="Brightness Value",min=0,max=10,default=worldmods.Brightness,interval=0.1,flag="world_brightness_val",callback=function(v) worldmods.Brightness=v applyWorldMods() end})

					world:toggle({name="Ambient",flag="world_ambient_toggle",default=false,callback=function(v) worldmods.ambientEnabled=v applyWorldMods() end})
					:colorpicker({name="Ambient Color",flag="world_ambient_color",color=worldmods.Ambient,callback=function(v) worldmods.Ambient=v applyWorldMods() end})

					world:toggle({name="Outdoor Ambient",flag="world_outdoor_ambient_toggle",default=false,callback=function(v) worldmods.outdoorAmbientEnabled=v applyWorldMods() end})
					:colorpicker({name="Outdoor Ambient Color",flag="world_outdoor_color",color=worldmods.OutdoorAmbient,callback=function(v) worldmods.OutdoorAmbient=v applyWorldMods() end})

					world:toggle({name="Clock Time",flag="world_time_toggle",default=false,callback=function(v) worldmods.timeEnabled=v applyWorldMods() end})
					world:slider({name="Time Value",min=0,max=24,default=worldmods.Time,interval=1,suffix="h",flag="world_time_val",callback=function(v) worldmods.Time=v applyWorldMods() end})

					world:toggle({name="Exposure",flag="world_exposure_toggle",default=false,callback=function(v) worldmods.exposureEnabled=v applyWorldMods() end})
					world:slider({name="Exposure Value",min=-2,max=2,default=worldmods.Exposure,interval=0.1,flag="world_exposure_val",callback=function(v) worldmods.Exposure=v applyWorldMods() end})

					world:toggle({name="Shadow Softness",flag="world_shadow_toggle",default=false,callback=function(v) worldmods.shadowSoftnessEnabled=v applyWorldMods() end})
					world:slider({name="Shadow Softness Value",min=0,max=1,default=worldmods.ShadowSoftness,interval=0.05,flag="world_shadow_val",callback=function(v) worldmods.ShadowSoftness=v applyWorldMods() end})

					world:toggle({name="ColorShift",flag="world_colorshift_toggle",default=false,callback=function(v) worldmods.colorShiftEnabled=v applyWorldMods() end})
					:colorpicker({name="Top Color",flag="world_colorshift_top",color=worldmods.ColorShiftTop,callback=function(v) worldmods.ColorShiftTop=v applyWorldMods() end})
					:colorpicker({name="Bottom Color",flag="world_colorshift_bottom",color=worldmods.ColorShiftBottom,callback=function(v) worldmods.ColorShiftBottom=v applyWorldMods() end})

					world:toggle({name="Global Shadows",flag="world_shadow_toggle2",default=false,callback=function(v) worldmods.shadowEnabled=v applyWorldMods() end})

					world:toggle({name="Sky",flag="world_sky_toggle",default=false,callback=function(v) worldmods.skyEnabled=v applyWorldMods() end})
					world:slider({name="Sun Size",min=0,max=30,default=worldmods.Sky.SunAngularSize,interval=1,flag="world_sky_sun",callback=function(v) worldmods.Sky.SunAngularSize=v applyWorldMods() end})
					world:slider({name="Moon Size",min=0,max=30,default=worldmods.Sky.MoonAngularSize,interval=1,flag="world_sky_moon",callback=function(v) worldmods.Sky.MoonAngularSize=v applyWorldMods() end})
					world:slider({name="Stars",min=0,max=6000,default=worldmods.Sky.StarCount,interval=100,flag="world_sky_stars",callback=function(v) worldmods.Sky.StarCount=v applyWorldMods() end})
				end

				-- // crosshair
				do
					Crosshair:toggle({name = "Enabled", flag = "crosshair_enabled", default = cheat.crosshair.enabled, callback = function(v) cheat.crosshair.enabled = v end})
						:colorpicker({name = "Color", flag = "CrosshairColor", color = cheat.crosshair.color, callback = function(v) cheat.crosshair.color = v end})

					Crosshair:dropdown({name = "Mode", flag = "crosshair_mode", items = { 'center', 'mouse', 'target' }, default = cheat.crosshair.mode, callback = function(v) cheat.crosshair.mode = v end})

					Crosshair:slider({name = "Refresh Rate (s)", min = 0, max = 1, default = cheat.crosshair.refreshrate, interval = 0.01, flag = "crosshair_refreshrate", callback = function(v) cheat.crosshair.refreshrate = v end})

					Crosshair:slider({name = "Line Width", min = 1, max = 5, default = cheat.crosshair.width, interval = 1, flag = "crosshair_width", callback = function(v) cheat.crosshair.width = v end})

					Crosshair:slider({name = "Line Length", min = 5, max = 30, default = cheat.crosshair.length, interval = 1, flag = "crosshair_length", callback = function(v) cheat.crosshair.length = v end})

					Crosshair:slider({name = "Circle Radius", min = 0, max = 50, default = cheat.crosshair.radius, interval = 1, flag = "crosshair_radius", callback = function(v) cheat.crosshair.radius = v end})

					Crosshair:toggle({name = "Spin", flag = "crosshair_spin", default = cheat.crosshair.spin, callback = function(v) cheat.crosshair.spin = v end})

					Crosshair:slider({name = "Speed", min = 50, max = 500, default = cheat.crosshair.spin_speed, interval = 1, flag = "crosshair_spin_speed", callback = function(v) cheat.crosshair.spin_speed = v end})

					Crosshair:slider({name = "max Angle", min = 90, max = 360, default = cheat.crosshair.spin_max, interval = 1, flag = "crosshair_spin_max", callback = function(v) cheat.crosshair.spin_max = v end})

					Crosshair:dropdown({name = "Style", flag = "crosshair_spin_style", items = { 'Linear', 'Circular', 'Sine', 'Back', 'Bounce', 'Elastic', 'Exponential', 'Quad', 'Quart', 'Quint' }, default = 'Circular', callback = function(v) cheat.crosshair.spin_style = Enum.EasingStyle[v] end})

					Crosshair:toggle({name = "Resize", flag = "crosshair_resize", default = cheat.crosshair.resize, callback = function(v) cheat.crosshair.resize = v end})

					Crosshair:slider({name = "Speed", min = 50, max = 500, default = cheat.crosshair.resize_speed, interval = 1, flag = "crosshair_resize_speed", callback = function(v) cheat.crosshair.resize_speed = v end})

					Crosshair:slider({name = "min", min = 1, max = 20, default = cheat.crosshair.resize_min, interval = 1, flag = "crosshair_resize_min", callback = function(v) cheat.crosshair.resize_min = v end})

					Crosshair:slider({name = "max", min = 10, max = 40, default = cheat.crosshair.resize_max, interval = 1, flag = "crosshair_resize_max", callback = function(v) cheat.crosshair.resize_max = v end})

					local old; old = hookfunction(Drawing.new, LPH_NO_UPVALUES(function(class, properties)
						local drawing = old(class)
						for i, v in next, properties or {} do
							drawing[i] = v
						end
						return drawing
					end))

					local function getSnapOriginScreenPos()
						if cheat.crosshair.mode == "mouse" then
							local mousePos = inputservice:GetMouseLocation()
							return Vector2.new(mousePos.X, mousePos.Y), true
						elseif cheat.crosshair.mode == "center" then
							return camera.ViewportSize / 2, true
						elseif cheat.crosshair.mode == "target" then
							if cheat and cheat.target and cheat.target.Character and cheat.target.Character:FindFirstChild("HumanoidRootPart") then
								local targetPos = camera:WorldToViewportPoint(cheat.target.Character.HumanoidRootPart.Position)
								return Vector2.new(targetPos.X, targetPos.Y), targetPos.Z > 0
							else
								local mousePos = inputservice:GetMouseLocation()
								return Vector2.new(mousePos.X, mousePos.Y), true
							end
						end
						return camera.ViewportSize / 2, true
					end

					local last_render = 0
					local drawings = {
						crosshair = {},
						text = {
							Drawing.new('Text', {Size = 16, Font = 2, Outline = true, Text = ' ', Color = Color3.fromRGB(255, 255, 255)}),
							Drawing.new('Text', {Size = 16, Font = 2, Outline = true, Text = " ", Color = Color3.fromRGB(255, 255, 255)})
						}
					}
					for idx = 1, 4 do
						drawings.crosshair[idx] = Drawing.new('Line')
						drawings.crosshair[idx + 4] = Drawing.new('Line')
					end

					local function solve(angle, radius)
						return Vector2.new(
							math.sin(math.rad(angle)) * radius,
							math.cos(math.rad(angle)) * radius
						)
					end

					runservice.PostSimulation:Connect(function()
						local _tick = tick()
						if _tick - last_render > cheat.crosshair.refreshrate then
							last_render = _tick

							local screenPos, onScreen = getSnapOriginScreenPos()
							local position = screenPos

							local text_1, text_2 = drawings.text[1], drawings.text[2]
							text_1.Visible = cheat.crosshair.enabled
							text_2.Visible = cheat.crosshair.enabled

							if cheat.crosshair.enabled and onScreen then
								local text_x = text_1.TextBounds.X + text_2.TextBounds.X
								text_1.Position = position + Vector2.new(-text_x / 2, cheat.crosshair.radius + (cheat.crosshair.resize and cheat.crosshair.resize_max or cheat.crosshair.length) + 15)
								text_2.Position = text_1.Position + Vector2.new(text_1.TextBounds.X)
								text_2.Color = cheat.crosshair.color

								for idx = 1, 4 do
									local outline = drawings.crosshair[idx]
									local inline = drawings.crosshair[idx + 4]

									local angle = (idx - 1) * 90
									local length = cheat.crosshair.length

									if cheat.crosshair.spin then
										local spin_angle = -_tick * cheat.crosshair.spin_speed % cheat.crosshair.spin_max
										angle = angle + tweenservice:GetValue(spin_angle / 360, cheat.crosshair.spin_style, Enum.EasingDirection.InOut) * 360
									end

									if cheat.crosshair.resize then
										local resize_length = tick() * cheat.crosshair.resize_speed % 180
										length = cheat.crosshair.resize_min + math.sin(math.rad(resize_length)) * cheat.crosshair.resize_max
									end

									inline.Visible = true
									inline.Color = cheat.crosshair.color
									inline.From = position + solve(angle, cheat.crosshair.radius)
									inline.To = position + solve(angle, cheat.crosshair.radius + length)
									inline.Thickness = cheat.crosshair.width

									outline.Visible = true
									outline.Color = Color3.new(0, 0, 0)
									outline.From = position + solve(angle, cheat.crosshair.radius - 1)
									outline.To = position + solve(angle, cheat.crosshair.radius + length + 1)
									outline.Thickness = cheat.crosshair.width + 1.5
								end
							else
								for i = 1, 8 do
									drawings.crosshair[i].Visible = false
								end
							end
						end
					end)
				end
			end
			-- // misc
			do
				local movement = misc_column_one:column():section({name = "movement"})
				local AntiAim, UI = misc_column_one:multi_section({names = {"Anti Aim", "UI"}})
				local exploits = misc_column_two:column():section({name = "exploits"})
				do
					do -- // spiderman
						movement:toggle({flag = "spiderman", name = "spiderman", default = false, callback = function(v) end})
							:keybind({flag = "spidermankey", name = "spiderman", ignore_key = false, mode = "hold", callback = function(state) library.config_flags["spiderman"](state) end})
						movement:slider({flag = "spiderman speed", name = "speed", min = 1, max = 20, default = 10, interval = 1, callback = function(v) end})
						movement:toggle({flag = "infflight", name = "no lag back", default = false, callback = function(v) end})
					end
					--
					do -- // always grounded
						movement:toggle({flag = "always grounded", name = "always grounded", default = false, callback = function(v) end})
					end
					--
					do -- // omni sprint
						movement:toggle({flag = "omni sprint", name = "omni sprint", default = false, callback = function(v) end})
						movement:slider({flag = "omni sprint speed", name = "speed", min = 1, max = 35, default = 20, interval = 1, callback = function(v) end})
					end
					--
					movement:toggle({flag = "Bunnyhop", name = "bunny hop", default = false, callback = function(v) end})
				end
				-- // exploits
				do
					do -- // sound spam
						local Players = game:GetService("Players")
						local RunService = game:GetService("RunService")
						local ReplicatedStorage = game:GetService("ReplicatedStorage")

						local LocalPlayer = Players.LocalPlayer
						local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
						local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

						LocalPlayer.CharacterAdded:Connect(function(char)
							Character = char
							HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
						end)
						exploits:toggle({flag = "sound spam", name = "sound spam", default = false, callback = function(enabled)
							_G.soundSpam = enabled
							if enabled then
								task.spawn(function()
									while _G.soundSpam do
										if HumanoidRootPart then
											for _, sound in ipairs(HumanoidRootPart:GetChildren()) do
												if sound:IsA("Sound") then
													ReplicatedStorage.PlaySound:FireServer(sound, "Play")
												end
											end
										end
										task.wait(0.2)
									end
								end)
							else
								if HumanoidRootPart then
									for _, sound in ipairs(HumanoidRootPart:GetChildren()) do
										if sound:IsA("Sound") then
											ReplicatedStorage.PlaySound:FireServer(sound, "Stop")
										end
									end
								end
							end
						end})
					end
					--
					do -- // xray
						getgenv().xray_enabled = false
						getgenv().xray_opacity = 0.5

						local base_structure_folders = {}

						local function is_valid_structure(name)
							for _, allowed in ipairs(cheat.allowed_structures) do
								if name == allowed then return true end
							end
							return false
						end

						local function apply_xray_to_part(part)
							if part:IsA("MeshPart") then
								if getgenv().xray_enabled then
									part.Transparency = getgenv().xray_opacity
									part.Material = Enum.Material.SmoothPlastic
								else
									part.Transparency = 0
									part.Material = Enum.Material.Plastic
								end
							end
						end

						local function watch_structure_folder(folder)
							for _, obj in ipairs(folder:GetDescendants()) do
								apply_xray_to_part(obj)
							end
							folder.DescendantAdded:Connect(apply_xray_to_part)
						end

						local function process_base_folder(base)
							if not base:IsA("Folder") or base.Name ~= "Base" then return end

							for _, structure in ipairs(cheat.allowed_structures) do
								local sub_folder = base:FindFirstChild(structure)
								if sub_folder and sub_folder:IsA("Folder") then
									base_structure_folders[structure] = base_structure_folders[structure] or {}
									table.insert(base_structure_folders[structure], sub_folder)
									watch_structure_folder(sub_folder)
								end
							end

							base.ChildAdded:Connect(function(child)
								if is_valid_structure(child.Name) and child:IsA("Folder") then
									base_structure_folders[child.Name] = base_structure_folders[child.Name] or {}
									table.insert(base_structure_folders[child.Name], child)
									watch_structure_folder(child)
								end
							end)
						end

						if workspace:FindFirstChild("Bases") then
							for _, base in ipairs(workspace.Bases:GetChildren()) do
								process_base_folder(base)
							end
							workspace.Bases.ChildAdded:Connect(process_base_folder)
						end

						local function update_all_xray()
							for _, folders in pairs(base_structure_folders) do
								for _, folder in ipairs(folders) do
									for _, obj in ipairs(folder:GetDescendants()) do
										apply_xray_to_part(obj)
									end
								end
							end
						end

						exploits:toggle({
							flag = "xray",
							name = "X-ray",
							default = false,
							callback = function(state)
								getgenv().xray_enabled = state
								update_all_xray()
							end
						})

						exploits:slider({
							flag = "xray_transparency",
							name = "Transparency",
							min = 0,
							max = 100,
							default = 50,
							interval = 1,
							callback = function(v)
								getgenv().xray_opacity = v / 100
								if getgenv().xray_enabled then
									update_all_xray()
								end
							end
						})

					end
					--
					do-- // traps
						function traptoggles(partName, state)
							if state then
								for _, v in workspace:GetDescendants() do
									if v:IsA("BasePart") and v.Name == partName then
										cheat.stored_parts[partName][v] = v.Parent
										v.Parent = cloneref(game:GetService("CoreGui"))
										v.Destroying:Connect(function()
											cheat.stored_parts[partName][v] = nil
										end)
									end
								end
							else
								for part, old_parent in pairs(cheat.stored_parts[partName]) do
									if part then
										part.Parent = old_parent
									end
								end
								table.clear(cheat.stored_parts[partName])
							end
						end

						workspace.DescendantAdded:Connect(function(descendant)
							if descendant:IsA("BasePart") then
								for partName, flag in pairs({
									DamagePart = flags["DamagePart"],
									TouchCollision = flags["TouchCollision"],
								}) do
									if descendant.Name == partName and flag then
										cheat.stored_parts[partName][descendant] = descendant.Parent
										descendant.Parent = cloneref(game:GetService("CoreGui"))
										descendant.Destroying:Connect(function()
											cheat.stored_parts[partName][descendant] = nil
										end)
									end
								end
							end
						end)
						exploits:toggle({flag = "DamagePart", name = "distable spikes", default = false, callback = function(state) traptoggles("DamagePart", state) end})
						exploits:toggle({flag = "TouchCollision", name = "disable traps", default = false, callback = function(state) traptoggles("DamagePart", state) end})
					end
					--[[ --
					do
						local oldIndex
						local hrppos, hrpvel
						local a = false
						local randomnum = function(multiplier)
							return (math.random() - 0.5) * 2 * multiplier
						end
						local Players = game:GetService("Players")
						local RunService = game:GetService("RunService")
						local Client = Players.LocalPlayer

						oldIndex = hookmetamethod(game, '__index', newcclosure(function(self, key)
							if flags and flags.break_prediction then
								if not checkcaller() then
									if key == 'CFrame' then
										local character = Client.Character
										if character then
											local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
											local head = character:FindFirstChild("Head")
											local humanoid = character:FindFirstChild("Humanoid")
											
											if humanoidRootPart and head and humanoid and humanoid.Health > 0 then
												if self == humanoidRootPart then
													return hrppos or humanoidRootPart.CFrame
												elseif self == head then
													if hrppos then
														return CFrame.new(hrppos.Position + Vector3.new(0, humanoidRootPart.Size.Y / 2 + 0.5, 0))
													else
														return head.CFrame
													end
												end
											end
										end
									end
								end
							end
							return oldIndex(self, key)
						end))

						local function antifying(char)
							if flags and flags.break_prediction then
								for _, v in pairs(char:GetDescendants()) do
									if v:IsA('BasePart') then
										v.CanCollide = false
									end
								end

								char.DescendantAdded:Connect(function(v)
									if v:IsA('BasePart') and flags and flags.break_prediction then
										v.CanCollide = false
									end
								end)
							end
						end

						for _, plr in pairs(Players:GetPlayers()) do
							if plr ~= Client and plr.Character then
								antifying(plr.Character)
							end
						end

						Players.PlayerAdded:Connect(function(plr)
							plr.CharacterAdded:Connect(function(char)
								if plr ~= Client then
									antifying(char)
								end
							end)
						end)

						exploits:toggle({
							flag = "break_prediction", 
							name = "break prediction", 
							default = false, 
							Callback = LPH_NO_VIRTUALIZE(function(state)
								if flags then
									flags.break_prediction = state
									if state then
										for _, plr in pairs(Players:GetPlayers()) do
											if plr == Client then continue end
											local char = plr.Character
											if char then
												antifying(char)
											end
										end
									end
								end
							end)
						})

						local heartbeatConnection
						heartbeatConnection = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
							if flags and flags.break_prediction then
								local character = Client.Character
								if not character then return end
								
								local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
								local humanoid = character:FindFirstChild("Humanoid")
								
								if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then return end
								
								hrppos = humanoidRootPart.CFrame
								hrpvel = humanoidRootPart.AssemblyLinearVelocity
								a = not a
								
								local SpoofThis = hrppos * CFrame.new(
									Vector3.new(
										randomnum(1),
										randomnum(2) + 1.5,
										randomnum(1)
									)
								) * CFrame.Angles(
									math.rad(a and -90 or 90),
									0,
									math.rad(a and -90 or 90)
								)
								
								humanoidRootPart.CFrame = SpoofThis
								humanoidRootPart.AssemblyLinearVelocity = Vector3.new(1, 1, 1) * 9999
								
								RunService.RenderStepped:Wait()
								
								humanoidRootPart.CFrame = hrppos
								humanoidRootPart.AssemblyLinearVelocity = hrpvel
							end
						end))
					end ]]
				end
				-- // anti aim
				do	-- THIS IS IN IRI source 
				end
				-- // UI shit like recolor the ui for health etc
				do
					UI:toggle({flag = "notify mod", name = "moderator detector", default = false, callback = function(v) end}) -- this will notify users if a moderator joins using the group id and role ids
					--
					do -- // spoof name etc
						UI:toggle({flag = "spoof name", name = "spoof name", default = false, callback = function(Value)
							SpoofName = Value
							updateTeamListNames()
						end})
						:colorpicker({name = "Color", flag = "spoofnamecolor", color = Color3.new(1, 1, 1), callback = function(v) 
							SpoofColor = v
							if SpoofName then
								updateTeamListNames()
							end
						end})
						
						UI:toggle({flag = "hide server info", name = "hide server info", default = false, callback = function(state) 
							local main = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Main")

							if main and main:FindFirstChild("ServerName") then
								main.ServerName.Visible = not state
							end
						end})
						
						task.spawn(function()
							while true do
								task.wait(0.0)
								if SpoofName then
									updateTeamListNames()
								end
							end
						end)
					end
				end
				-- // skin changer
				do
					-- in iri source
				end
			end
		end

		-- // silent shit wtv
		do -- // module unpacker
			-- // Modules
			do
				local modules = rs:FindFirstChild("Modules")

				if (modules) then
					for index, module in ipairs(modules:GetChildren()) do
						local class = module.ClassName;
						local name = module.Name;
						
						if (class == "ModuleScript") then
							local success, err = pcall(function()
								cheat.modules_unpacked[name] = {module = require(module), instance = module};
								print("👽 unpacked "..name)
							end)

							if (err and (not success)) then
								print("🦀 failed to unpack "..name)
								lp:Kick(`[ InsanityPastedSloptic ] Failure to load modules. ({err})`);
							end
						end
					end
				end
			end

			local viewportsize = camera.ViewportSize
			local cent = viewportsize / 2
			local offset = Vector2.new(0, 50)
			local dih = cent + offset

			szneo.RenderStep = game:GetService("RunService").RenderStepped:Connect(function(dt)

				if cheat.target then
					local vp = camera.ViewportSize
					local x, y = vp.X / 2, vp.Y / 2
					local hitboggs =  cheat.target.Character:FindFirstChild(flags["combat hitboxes"])

					if flags["manipulation"] then
						cheat.ManipulatedPos,drawingVis = szneo.FindVisiblePosition(cheat.LocalRoot.CFrame, hitboggs)
						cheat.drawings.Manip_Indicator.Visible = drawingVis or false
						cheat.drawings.Manip_Indicator.TextColor3 = flags["manipulation color"].Color
						if cheat.ManipulatedPos then
							cheat.shouldshoot = true
						end
					end

					if flags["Hitscan"] then
						cheat.HitscannedPos,hsVis = szneo.FindHitScanPosition(cheat.LocalRoot.CFrame, hitboggs)
					end

					if (flags["combat auto shoot"] and flags["auto shoot bind"].active and cheat.shouldshoot) then
						--print("autoshooting now?")
						VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
						VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
						cheat.shouldshoot = false
					end
				else --// retarded statement idk why butn the mannip text is a bum
					cheat.drawings.Manip_Indicator.Visible = false
				end

			end)

			do -- // Silent Aim
				local vfx_module = cheat and cheat.modules_unpacked and cheat.modules_unpacked.VFXModule
				local vector_util = cheat and cheat.modules_unpacked and cheat.modules_unpacked.VectorUtil
				local view_models = rs and rs:FindFirstChild("VMs")

				if vfx_module and vfx_module.module then

					local old_create_projectile = vfx_module.module.CreateProjectile
					vfx_module.module.CreateProjectile = LPH_NO_UPVALUES(function(self, data, ...)
						if not data or type(data) ~= "table" then
							return old_create_projectile(self, data, ...)
						end

						local Args = {...}

						local real_hit_func = data.StepFunction ~= "FakeStepFunc" and data.HitFunction ~= "FakeHitFunc"
						
						if cheat and cheat.LocalRoot and real_hit_func then
							if flags and flags["combat enabled"] and flags["combat mode"] == "silent" and cheat.target and cheat.target.Character then
								local hitbox_name = flags["combat hitboxes"]
								local target_hitbox = hitbox_name and cheat.target.Character[hitbox_name]
								
								if target_hitbox and target_hitbox.Parent and (math.random(0,100) <= flags["silent_aim_hitchance"]) then
									print("Silent aim active")

									local target_position = target_hitbox.Position
									local barrel_position = data.PositionFirst or data.Position or Vector3.new(0, 0, 0)
									
									if exploits and exploits.get_fire_positions then
										local positions = exploits.get_fire_positions(cheat.LocalRoot.Position, 9, target_position) or {}
										if positions[1] then
											local cf = CFrame.new(positions[1], target_position)
											data.Position = cf.Position
											data.PositionFirst = cf.Position
											barrel_position = cf.Position
										end
									end

									local instant_bullet_enabled =flags["instant_bullet"] and flags["instant_bullet"]
									local instant_bullet_method = flags["instant_bullet_methods"] and flags["instant_bullet_methods"] or "Default"
									local is_teleport = (instant_bullet_enabled and instant_bullet_method == "Teleport")
									
									local at = CFrame.lookAt(barrel_position, target_position)
									
									if is_teleport then
										local fixed_position = target_position + Vector3.new(0, 1.3, 0)
										data.Position = fixed_position
										data.PositionFirst = fixed_position
										data.Direction = Vector3.new(0, -999, 0)
										data.DirectionFirst = Vector3.new(0, -999, 0)
									else
										data.Position = at.Position
										data.PositionFirst = at.Position
										data.Direction = at.LookVector
										data.DirectionFirst = at.LookVector
									end

									if instant_bullet_enabled and not is_teleport then
										data.Speed = 10000
									end
								end
							end

							-- // Bullet tracer
							if  flags["bullet tracer"] and  szneo.bullet_tracer then
								local origin = data.PositionFirst
								local direction = data.DirectionFirst
								local dir = origin + (direction * 1000)
								--print(typeof(origin),typeof(direction))
								
								if origin and direction then
									local filter = data.Filters or {}
									if cheat.Local_char then
										table.insert(filter, cheat.Local_char)
									end

									local color = flags["bullet tracer color"].Color or Color3.new(1, 1, 1)
									local color2 = flags["bullet tracer color2"].Color or Color3.new(1, 1, 1)
									local lifetime = flags["bullet tracer life"] or 1
									
									szneo.bullet_tracer(origin, dir, color,color2, lifetime, filter)
								end
							end

							-- // Hit markers
							if not data.HitFunctionHooked then
								data.HitFunctionHooked = true
								local original_hit_function = data.HitFunction
								
								data.HitFunction = LPH_NO_UPVALUES(function(...)
									local hit_part, hit_position = ..., select(2, ...)
									local distanceFromHit,NewHealth = math.floor((camera.CFrame.Position - hit_position).Magnitude), (hit_part.Parent:FindFirstChild("Humanoid") and hit_part.Parent.Humanoid.Health)
									
									if flags and flags["hit marker"] and flags["hit marker"] then
										if hit_position and hit_part and hit_part.Parent then
											print("hi im hit marker print")
											local humanoid = hit_part.Parent:FindFirstChildOfClass("Humanoid")
											if humanoid and szneo and szneo.hitmarker then
												local color = flags["hit marker color"].Color or Color3.new(1, 1, 1)
												local lifetime = flags["hit marker life"] or 1
												
												szneo.hitmarker(hit_position, color, lifetime, 6, Color3.fromRGB(255, 0, 0))
												
											end
										end
									end
									setthreadidentity(8)
									task.spawn(function()
										szneo.Hit_Notification(hit_part.Parent,hit_part,distanceFromHit,NewHealth,"AKniggapoop")
									end)
									setthreadidentity(3)
									
									return original_hit_function(...)
								end)
							end
						end
						
						return old_create_projectile(self, data, ...)
					end)
				end

				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Modules = ReplicatedStorage:FindFirstChild("Modules")
				local VFX = require(Modules.VFXModule)

				local ProjectileHook; ProjectileHook = hookfunction(VFX.CreateProjectile,LPH_NO_UPVALUES(function(self,...)

				local Args = {...}

				local Traceback = debug.traceback()
				if
					Traceback:find("ViewmodelController")
					and Args[1].StepFunction ~= "FakeStepFunc"
					and Args[1].HitFunction ~= "FakeHitFunc"
					and not tostring(Args[1].HitFunction):find("Ignore")
					then

					local HitFunction; HitFunction = Args[1].HitFunction;

					if debug.isvalidlevel(3) and cheat.target and cheat.target.Character then
						print("debg lvl is valid")
						local Stack = debug.getstack(3)
							if (flags["combat enabled"] and flags["combat mode"] == "silent") and (math.random(0,100) <= flags["silent_aim_hitchance"]) then
							local CameraStack = rawget(Stack, 45)
							local FlashpartStack = rawget(Stack, 51)
							local HRPStack = rawget(Stack, 52)
							local MouseHitStack = rawget(Stack, 52)
							local CameraPosition = CameraStack.p
							local hitbox_name = flags["combat hitboxes"]
							local target_hitbox = cheat.target.Character and cheat.target.Character[hitbox_name]
							local target_position = target_hitbox.CFrame.Position
							local vp = camera.ViewportSize
							local x, y = vp.X / 2, vp.Y / 2

							local FakeCameraCFrame = CFrame.new(CameraPosition, target_position)
							local FakeHRPCFrame = CFrame.new(HRPStack.p, target_position)

							local OriginalFlashOffset = FlashpartStack - CameraPosition
							local NewFlashpartPosition = CFrame.new(FlashpartStack, target_position).p

							if cheat.ManipulatedPos then
								print("maip check x2")
								NewFlashpartPosition = CFrame.new(cheat.ManipulatedPos, target_position).p

								local FlashpartOffsetCamera = CameraPosition - FlashpartStack
								local FlashpartOffsetHRP = HRPStack.p - FlashpartStack

								local NewCameraPos = NewFlashpartPosition + FlashpartOffsetCamera
								local NewHRPPos = NewFlashpartPosition + FlashpartOffsetHRP

								FakeCameraCFrame = CFrame.new(NewCameraPos, target_position)
								FakeHRPCFrame = CFrame.new(NewHRPPos, target_position)
							end

							debug.setstack(3, 45, FakeCameraCFrame)
							debug.setstack(3, 54, target_position)
							debug.setstack(3, 52, FakeHRPCFrame)
							debug.setstack(3, 51, NewFlashpartPosition)

							local Origin = Args[1].Position

							local Direction = (target_position - Origin).Unit
							local CorrectedPosition = CFrame.new(Origin, target_position).Position

							if cheat.ManipulatedPos then
								Direction = (target_position - cheat.ManipulatedPos).Unit
								CorrectedPosition = CFrame.new(cheat.ManipulatedPos, target_position).p
							end

							Args[1].Position = CorrectedPosition

							if Args[1].PositionFirst then
								Args[1].PositionFirst = CorrectedPosition
							end

							Args[1].DirectionFirst = Direction
							Args[1].Direction = Direction

							if flags["Hitscan"] and cheat.target then
								task.defer(HitFunction, target_hitbox, cheat.HitscannedPos, Vector3.new(0, 0, 1), target_hitbox.Material)
								return
							end
						end
					end
					if flags["TeleportBullet"] then
						print("i should teleport you")
						lp.Character.HumanoidRootPart.CFrame = mouse.Hit
					end
				end
					return ProjectileHook(self,unpack(Args))
				end))

				-- // VectorUtil hook for view model adjustment
				if vector_util and vector_util.module and view_models then
					local old_fire_remote = vector_util.module.FireRemote
					vector_util.module.FireRemote = LPH_NO_UPVALUES(function(self, ...)
						local args = {...}
						local data = args[3]

						if data and type(data) == "table" and data[7] then
							if flags and flags["combat enabled"] and flags["combat mode"] == "silent" and cheat and cheat.target and cheat.target.Character then
								local hitbox_name = flags["combat hitboxes"]
								local target_hitbox = hitbox_name and cheat.target.Character[hitbox_name]
								
								if target_hitbox and view_models[data[7]] then
									local target_pos = target_hitbox.Position
									local origin = data[4]
									
									if origin and origin.Position then
										data[1] = target_pos
										data[4] = CFrame.new(origin.Position, target_pos)
										data[6] = CFrame.new(origin.Position, target_pos)
									end
								end
							end
						end

						return old_fire_remote(self, ...)
					end)
				end
			end
			do
				local disable_restrictions = function(humanoid)
					for _, v in getconnections(humanoid.StateChanged) do
						if v.Function then
							local data = debug.info(v.Function, "s");
							if data:find("ViewmodelController", 1, true) then
								local old; old = hookfunction(v.Function, LPH_NO_UPVALUES(function(...)
									if flags["always grounded"] then return end;
									return old(...);
								end));
							end;
						end;
					end;
				end;
				local local_char = local_player.Character or local_player.CharacterAdded:Wait();
				if (local_player and local_char:FindFirstChild("Humanoid")) then disable_restrictions(local_char.Humanoid) end
				local_player.CharacterAdded:Connect(function(v)
					local humanoid, viewmodel_controller = v:WaitForChild("Humanoid"), v:WaitForChild("ViewmodelController");
					if humanoid and viewmodel_controller then disable_restrictions(humanoid) end;
				end);
			end
		end

        do -- // init
            library:config_list_update()

            for index, value in themes.preset do 
                pcall(function()
                    library:update_theme(index, value)
                end)
            end

            task.wait()

            library.old_config = library:get_config()
        end
    end
	setfpscap(9999)
end

library:notification({text ="InsanityPastedSloptic Fallen Survival loaded", time = 4})
