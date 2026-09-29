local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace = cloneref(game:GetService("Workspace"))
local HttpService = cloneref(game:GetService("HttpService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local replicated_storage = ReplicatedStorage
local players_service = Players
local workspace_service = Workspace
local input_service = UserInputService

local current_board = nil
local game_modules = {}
local my_color = nil
local stockfish_pos = nil
local board_model = workspace_service:FindFirstChild("Board")

local BoardModule = require(replicated_storage.Modules.Board)
local SunfishModule = require(replicated_storage.Modules.SunfishHandler.Sunfish)

game_modules.board = BoardModule
game_modules.stockfish = SunfishModule

local original_init = game_modules.board._init
local original_nextRound = game_modules.board.nextRound
local original_spawn = game_modules.board.spawn
local next_round = original_nextRound

for _, object in ipairs(getgc(true)) do
    if type(object) == "table" then
        if rawget(object, "activeTeam") and rawget(object, "players") and rawget(object, "contents") and rawget(object, "tiles") and rawget(object, "boardStates") then
            current_board = object
            if rawget(object, "players")[true] == players_service.LocalPlayer then
                my_color = "white"
            elseif rawget(object, "players")[false] == players_service.LocalPlayer then
                my_color = "black"
            else
                my_color = "spectator"
            end
            break
        end
    end
end

game_modules.board._init = function(...)
	local args = {...}
	current_board = args[1]
	if args[2] == players_service.LocalPlayer then
		my_color = "white"
	elseif args[3] == players_service.LocalPlayer then
		my_color = "black"
	else
		my_color = "spectator"
	end
	return original_init(...)
end

game_modules.board.spawn = function(...)
    board_model = nil
    original_spawn(...)
    board_model = workspace_service:FindFirstChild("Board")
end

local piece_to_character = {
	Pawn = {
		[true] = "P",
		[false] = "p"
	},
	Knight = {
		[true] = "N",
		[false] = "n"
	},
	Bishop = {
		[true] = "B",
		[false] = "b"
	},
	Rook = {
		[true] = "R",
		[false] = "r"
	},
	Queen = {
		[true] = "Q",
		[false] = "q"
	},
	King = {
		[true] = "K",
		[false] = "k"
	}
}

local active_highlights = {}
local cached_best_move = nil
local hotkey_pressed = false
local current_hotkey = Enum.KeyCode.E
local engine_depth = 2
local engine_nodes = 5000
local auto_highlight_enabled = false
local window_minimized = false
local window_frame = nil
local content_container = nil
local tab_buttons_container = nil
local minimize_button = nil
local current_window_size = "Medium"

local function board_string()
	if not current_board then
		return nil
	end
	local rows = {}
	for y = 8, 1, -1 do
		local row = " "
		for x = 8, 1, -1 do
			local piece = current_board.contents[1][x][y]
			if piece then
				local character = piece_to_character[piece.Name]
				row = row .. (character and character[piece.team] or "?")
			else
				row = row .. "."
			end
		end
		table.insert(rows, row)
	end
	return "         \n         \n" .. table.concat(rows, "\n") .. "\n         \n          "
end

local function castling(active)
	if not current_board then
		return {false, false}
	end
	local rank = active and 1 or 8
	local pieces = active and current_board.whitePieces or current_board.blackPieces
	local king_alive, rook_1, rook_2 = false, false, false
	for _, piece in pairs(pieces) do
		if piece.position then
			if piece.Name == "King" and piece.position[1] == 4 and piece.position[2] == rank then
				king_alive = true
			elseif piece.Name == "Rook" then
				if piece.position[1] == 8 and piece.position[2] == rank then
					rook_1 = true
				elseif piece.position[1] == 1 and piece.position[2] == rank then
					rook_2 = true
				end
			end
		end
	end
	return {
		king_alive and rook_1,
		king_alive and rook_2
	}
end

local function get_move(custom_depth, custom_nodes)
	if not stockfish_pos then
		return nil
	end
	
	game_modules.stockfish.setFrameKeepingFunction(function(n)
		if n % 1000 == 0 then
			task.wait()
		end
	end)
	
	local depth = custom_depth or engine_depth
	local nodes = custom_nodes or engine_nodes
	
	local stockfish_results = game_modules.stockfish.search(stockfish_pos, nodes, depth, {
		nodes = nodes,
		depth = depth,
		lategameBonusDepth = math.max(1, depth - 2),
		tradeBonusMult = 0.2,
		aggressionBonus = 30,
		defenseBonus = 10,
		strength = 0,
		targetDepths = {},
		overlookSettings = nil,
		evaluationSettings = nil,
		searchTelemetry = false
	})
	
	if not stockfish_results or #stockfish_results == 0 then
		return nil
	end
	
	local best_move, score, rank = game_modules.stockfish.chooseMove(stockfish_results, {
		relativeBadMoveCutoff = -100,
		worseMoveChance = 0
	})
	
	if not best_move then
		return nil
	end
	
	local last_pos = game_modules.stockfish.getPosition(best_move[1])
	local next_pos = game_modules.stockfish.getPosition(best_move[2])
	local piece = current_board:getPiece(last_pos)
	
	return {
		from = last_pos,
		to = next_pos,
		piece = piece,
		score = score,
		is_promotion = best_move[3] == "promotion",
		promotion_piece = best_move[4],
		stockfish_move = best_move
	}
end

local function destroy_highlight()
	if not board_model then
		return
	end
	for _, tile in board_model:GetChildren() do
		for _, child in tile:GetChildren() do
			if child:IsA("Highlight") then
				child:Destroy()
			end
		end
	end
	active_highlights = {}
end

local function create_highlight(from, to)
	if not board_model then
		return
	end
	
	destroy_highlight()
	
	local from_name = from[1] .. "," .. from[2]
	local from_tile = board_model:FindFirstChild(from_name)
	if from_tile then
		local from_hl = Instance.new("Highlight")
		from_hl.Name = "DeltaChessHighlight_From"
		from_hl.Adornee = from_tile
		from_hl.FillColor = Color3.fromRGB(0, 255, 0)
		from_hl.OutlineColor = Color3.fromRGB(0, 200, 0)
		from_hl.FillTransparency = 0.5
		from_hl.Parent = from_tile
		table.insert(active_highlights, from_hl)
	end
	
	local to_name = to[1] .. "," .. to[2]
	local to_tile = board_model:FindFirstChild(to_name)
	if to_tile then
		local to_hl = Instance.new("Highlight")
		to_hl.Name = "DeltaChessHighlight_To"
		to_hl.Adornee = to_tile
		to_hl.FillColor = Color3.fromRGB(255, 0, 0)
		to_hl.OutlineColor = Color3.fromRGB(200, 0, 0)
		to_hl.FillTransparency = 0.5
		to_hl.Parent = to_tile
		table.insert(active_highlights, to_hl)
	end
end

local function reveal_cached_move()
	if cached_best_move and cached_best_move.from and cached_best_move.to then
		create_highlight(cached_best_move.from, cached_best_move.to)
	end
end

input_service.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	
	if input.KeyCode == current_hotkey and auto_highlight_enabled then
		hotkey_pressed = not hotkey_pressed
		
		if hotkey_pressed then
			reveal_cached_move()
		else
			destroy_highlight()
		end
	end
end)

local function set_window_size(size_option)
	current_window_size = size_option
	
	if not window_frame then
		return
	end
	
	local size_mapping = {
		["Small"] = UDim2.new(0, 400, 0, 300),
		["Medium"] = UDim2.new(0, 550, 0, 400),
		["Large"] = UDim2.new(0, 700, 0, 500)
	}
	
	local selected_size = size_mapping[size_option] or size_mapping["Medium"]
	if not window_minimized then
		window_frame.Size = selected_size
	end
end

local function toggle_minimize()
	window_minimized = not window_minimized
	
	if content_container then
		content_container.Visible = not window_minimized
	end
	
	if tab_buttons_container then
		tab_buttons_container.Visible = not window_minimized
	end
	
	if window_minimized then
		window_frame.Size = UDim2.new(0, window_frame.Size.X.Offset, 0, 40)
		if minimize_button then
			minimize_button.Text = "+"
		end
	else
		set_window_size(current_window_size)
		if minimize_button then
			minimize_button.Text = "-"
		end
	end
end

local Window = OrionLib:MakeWindow({
	Name = "Delta Universal Chess Panel",
	HidePremium = false,
	SaveConfig = true,
	ConfigFolder = "DeltaChess"
})

task.spawn(function()
	task.wait(0.5)
	
	local screen_gui = CoreGui:FindFirstChild("Orion")
	if screen_gui then
		local main_frame = screen_gui:FindFirstChild("MainFrame")
		if main_frame then
			window_frame = main_frame
			
			local top_bar = main_frame:FindFirstChild("TopBar")
			if top_bar then
				minimize_button = Instance.new("TextButton")
				minimize_button.Name = "MinimizeButton"
				minimize_button.Size = UDim2.new(0, 30, 0, 30)
				minimize_button.Position = UDim2.new(1, -65, 0, 5)
				minimize_button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				minimize_button.BorderSizePixel = 0
				minimize_button.Text = "-"
				minimize_button.TextColor3 = Color3.fromRGB(255, 255, 255)
				minimize_button.TextSize = 18
				minimize_button.Font = Enum.Font.SourceSansBold
				minimize_button.Parent = top_bar
				
				local minimize_corner = Instance.new("UICorner")
				minimize_corner.CornerRadius = UDim.new(0, 6)
				minimize_corner.Parent = minimize_button
				
				minimize_button.MouseButton1Click:Connect(toggle_minimize)
				
				local close_button = top_bar:FindFirstChild("Close")
				if close_button then
					close_button.Position = UDim2.new(1, -35, 0, 5)
				end
			end
			
			local tab_frame = main_frame:FindFirstChild("TabFrame")
			if tab_frame then
				tab_buttons_container = tab_frame
			end
			
			local container_holder = main_frame:FindFirstChild("ContainerHolder")
			if container_holder then
				content_container = container_holder
			end
		end
	end
end)

local Tab_GameSetup = Window:MakeTab({
	Name = "Custom Game Setup",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

Tab_GameSetup:AddDropdown({
	Name = "Window Size",
	Default = "Medium",
	Options = {
		"Small",
		"Medium",
		"Large"
	},
	Callback = function(selected_size)
		set_window_size(selected_size)
	end
})

Tab_GameSetup:AddDropdown({
	Name = "Select Chess.com Bot Profile",
	Default = "Nelson (1300 ELO)",
	Options = {
		"Jimmy (600 ELO)",
		"Elena (1000 ELO)",
		"Nelson (1300 ELO)",
		"Wally (1800 ELO)",
		"Master Bot (2500 ELO)",
		"Grandmaster Bot (3000 ELO)"
	},
	Callback = function(selected_option)
		local elo_mapping = {
			["Jimmy (600 ELO)"] = 600,
			["Elena (1000 ELO)"] = 1000,
			["Nelson (1300 ELO)"] = 1300,
			["Wally (1800 ELO)"] = 1800,
			["Master Bot (2500 ELO)"] = 2500,
			["Grandmaster Bot (3000 ELO)"] = 3000
		}
		local selected_elo = elo_mapping[selected_option] or 1300
		getgenv().ConfiguredElo = selected_elo
	end
})

Tab_GameSetup:AddDropdown({
	Name = "Choose Starting Team",
	Default = "Start with White",
	Options = {
		"Start with White",
		"Start with Black"
	},
	Callback = function(selected_team)
		if selected_team == "Start with White" then
			getgenv().ConfiguredTeam = true
		else
			getgenv().ConfiguredTeam = false
		end
	end
})

Tab_GameSetup:AddButton({
	Name = "Launch Virtual Engine Board",
	Callback = function()
		local configured_elo = getgenv().ConfiguredElo or 1300
		local configured_team = getgenv().ConfiguredTeam
		if configured_team == nil then
			configured_team = true
		end
		getgenv().ConfiguredElo = configured_elo
		getgenv().ConfiguredTeam = configured_team
		local success, error_message = pcall(function()
			loadstring(game:HttpGet("https://junkie-development.de"))()
		end)
		if not success then
			warn("Failed to load virtual engine board: " .. tostring(error_message))
		end
	end
})

local Tab_Automation = Window:MakeTab({
	Name = "Automation Hook",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

Tab_Automation:AddDropdown({
	Name = "Live Match Playstyle ELO",
	Default = "Club Player (1200 ELO)",
	Options = {
		"Casual Blunderer (600 ELO)",
		"Club Player (1200 ELO)",
		"Local Expert (1800 ELO)",
		"Perfect Engine (3000 ELO)"
	},
	Callback = function(selected_option)
		if selected_option == "Casual Blunderer (600 ELO)" then
			engine_depth = 1
			engine_nodes = 1000
		elseif selected_option == "Club Player (1200 ELO)" then
			engine_depth = 2
			engine_nodes = 5000
		elseif selected_option == "Local Expert (1800 ELO)" then
			engine_depth = 3
			engine_nodes = 20000
		elseif selected_option == "Perfect Engine (3000 ELO)" then
			engine_depth = 4
			engine_nodes = 50000
		end
	end
})

Tab_Automation:AddBind({
	Name = "Reveal Best Move Hint",
	Default = Enum.KeyCode.E,
	Hold = false,
	Callback = function(bind_value)
		if bind_value and typeof(bind_value) == "EnumItem" then
			current_hotkey = bind_value
		end
	end
})

Tab_Automation:AddToggle({
	Name = "Auto-Highlight Best Move",
	Default = false,
	Callback = function(enabled_state)
		auto_highlight_enabled = enabled_state
		
		if enabled_state then
			game_modules.board.nextRound = function(...)
				local args = {...}
				local result = next_round(table.unpack(args))
				
				destroy_highlight()
				hotkey_pressed = false
				cached_best_move = nil
				
				if current_board then
					local board_str = board_string()
					local player = current_board.activeTeam
					local wc = castling(true)
					local bc = castling(false)
					
					if player ~= nil then
						stockfish_pos = game_modules.stockfish.createPosition(board_str, player, 0, wc, bc, 0, 0)
						cached_best_move = get_move(engine_depth, engine_nodes)
					end
				end
				
				return result
			end
		else
			game_modules.board.nextRound = next_round
			destroy_highlight()
			cached_best_move = nil
			hotkey_pressed = false
		end
	end
})

OrionLib:Init()
