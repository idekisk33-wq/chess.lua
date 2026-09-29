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

local BoardModule = require(replicated_storage.Modules.Board)
local SunfishModule = require(replicated_storage.Modules.SunfishHandler.Sunfish)

game_modules.board = BoardModule
game_modules.stockfish = SunfishModule

for _, object in ipairs(getgc()) do
    if type(object) == "table" then
        if rawget(object, "activeTeam") and rawget(object, "players") and rawget(object, "contents") and rawget(object, "tiles") and rawget(object, "boardStates") then
            current_board = object
            break
        end
    end
end

local original_init = game_modules.board._init
local original_nextRound = game_modules.board.nextRound
local original_spawn = game_modules.board.spawn
local next_round = original_nextRound

local piece_to_character = {
    [true] = {
        Pawn = "P",
        Knight = "N",
        Bishop = "B",
        Rook = "R",
        Queen = "Q",
        King = "K"
    },
    [false] = {
        Pawn = "p",
        Knight = "n",
        Bishop = "b",
        Rook = "r",
        Queen = "q",
        King = "k"
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
    
    local board_matrix = {}
    local contents = current_board.contents
    
    for rank = 8, 1, -1 do
        local rank_string = ""
        for file = 8, 1, -1 do
            local piece_data = contents[file][rank]
            if piece_data and piece_data.Name then
                local is_white = piece_data.isWhite
                local piece_char = piece_to_character[is_white][piece_data.Name]
                if piece_char then
                    rank_string = rank_string .. piece_char
                else
                    rank_string = rank_string .. "."
                end
            else
                rank_string = rank_string .. "."
            end
        end
        table.insert(board_matrix, rank_string)
    end
    
    return table.concat(board_matrix, "/")
end

local function castling(active)
    if not current_board then
        return nil
    end
    
    local castling_rights = ""
    local board_states = current_board.boardStates
    local kingside_white = true
    local queenside_white = true
    local kingside_black = true
    local queenside_black = true
    
    if active then
        if current_board.activeTeam == true then
            return "KQ"
        else
            return "kq"
        end
    end
    
    return "-"
end

local function get_move(custom_depth, custom_nodes)
    if not game_modules.stockfish then
        return nil
    end
    
    local board_state = board_string()
    if not board_state then
        return nil
    end
    
    local castling_rights = castling(false)
    local fen_string = board_state .. " " .. (current_board.activeTeam and "w" or "b") .. " " .. castling_rights .. " - 0 1"
    
    local search_depth = custom_depth or engine_depth
    local node_limit = custom_nodes or engine_nodes
    
    local best_move = game_modules.stockfish.search(fen_string, search_depth, node_limit)
    
    if not best_move then
        best_move = game_modules.stockfish.chooseMove(fen_string, search_depth)
    end
    
    return best_move
end

local function file_to_letter(file)
    local letters = {"a", "b", "c", "d", "e", "f", "g", "h"}
    return letters[file] or "a"
end

local function tile_to_algebraic(file, rank)
    return file_to_letter(file) .. tostring(rank)
end

local function algebraic_to_tile(algebraic)
    local file_letter = string.sub(algebraic, 1, 1)
    local rank_number = tonumber(string.sub(algebraic, 2, 2))
    
    local file_map = {a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8}
    local file = file_map[file_letter] or 1
    
    return file, rank_number
end

local function create_highlight(from, to)
    if not workspace_service:FindFirstChild("Board") then
        return
    end
    
    destroy_highlight()
    
    local board = workspace_service.Board
    
    local from_file, from_rank = algebraic_to_tile(from)
    local to_file, to_rank = algebraic_to_tile(to)
    
    local from_name = tile_to_algebraic(from_file, from_rank)
    local to_name = tile_to_algebraic(to_file, to_rank)
    
    local from_tile = board:FindFirstChild(from_name)
    local to_tile = board:FindFirstChild(to_name)
    
    if from_tile then
        local from_highlight = Instance.new("Highlight")
        from_highlight.Name = "DeltaChessHighlight_From"
        from_highlight.FillColor = Color3.fromRGB(0, 255, 0)
        from_highlight.OutlineColor = Color3.fromRGB(0, 200, 0)
        from_highlight.FillTransparency = 0.5
        from_highlight.OutlineTransparency = 0
        from_highlight.Parent = from_tile
        table.insert(active_highlights, from_highlight)
    end
    
    if to_tile then
        local to_highlight = Instance.new("Highlight")
        to_highlight.Name = "DeltaChessHighlight_To"
        to_highlight.FillColor = Color3.fromRGB(255, 0, 0)
        to_highlight.OutlineColor = Color3.fromRGB(200, 0, 0)
        to_highlight.FillTransparency = 0.5
        to_highlight.OutlineTransparency = 0
        to_highlight.Parent = to_tile
        table.insert(active_highlights, to_highlight)
    end
end

local function destroy_highlight()
    for index = #active_highlights, 1, -1 do
        local highlight = active_highlights[index]
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
        table.remove(active_highlights, index)
    end
end

local function reveal_cached_move()
    if cached_best_move and type(cached_best_move) == "string" and #cached_best_move >= 4 then
        local from_square = string.sub(cached_best_move, 1, 2)
        local to_square = string.sub(cached_best_move, 3, 4)
        
        if from_square and to_square and #from_square == 2 and #to_square == 2 then
            create_highlight(from_square, to_square)
        end
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
    window_frame.Size = selected_size
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
                local title_label = top_bar:FindFirstChild("Title")
                
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
                
                cached_best_move = get_move(engine_depth, engine_nodes)
                
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
