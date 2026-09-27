-- Delta Self-Contained Local Engine Chess Advisor
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Force Clear Pre-Existing Interfaces Safely
if game.CoreGui:FindFirstChild("CyberChessScreen") then
    game.CoreGui.CyberChessScreen:Destroy()
end

-- GUI Interface Initialization (Classic Vertical Box)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CyberChessScreen"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 230, 0, 260) 
MainFrame.Active = true

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Text = "♟️ CyberChess Multi-Tool"
Title.Size = UDim2.new(1, 0, 0.14, 0)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.BorderSizePixel = 0

local ToggleSizeButton = Instance.new("TextButton")
ToggleSizeButton.Parent = MainFrame
ToggleSizeButton.Text = "–"
ToggleSizeButton.Size = UDim2.new(0, 30, 0.14, 0)
ToggleSizeButton.Position = UDim2.new(1, -30, 0, 0)
ToggleSizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleSizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleSizeButton.TextSize = 16
ToggleSizeButton.BorderSizePixel = 0

local ContentFrame = Instance.new("Frame")
ContentFrame.Parent = MainFrame
ContentFrame.Size = UDim2.new(1, 0, 0.86, 0)
ContentFrame.Position = UDim2.new(0, 0, 0.14, 0)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0

local LevelButton = Instance.new("TextButton", ContentFrame)
local DelayButton = Instance.new("TextButton", ContentFrame)
local AutoMoveButton = Instance.new("TextButton", ContentFrame)
local ActionButton = Instance.new("TextButton", ContentFrame)
local MoveDisplay = Instance.new("TextLabel", ContentFrame)

local levels = {
    {name = "Beginner (1000 Elo)", depth = 2},
    {name = "Advanced (1500 Elo)", depth = 4},
    {name = "Expert (2000 Elo)", depth = 6},
    {name = "Grandmaster (2500 Elo)", depth = 8},
    {name = "Maximum (3000+ Elo)", depth = 12}
}
local currentLevelIdx = 2
local safetyDelayEnabled = true
local autoMoveEnabled = false

LevelButton.Text = "Level: " .. levels[currentLevelIdx].name
LevelButton.Position = UDim2.new(0.05, 0, 0.04, 0)
LevelButton.Size = UDim2.new(0.9, 0, 0.14, 0)
LevelButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
LevelButton.TextColor3 = Color3.fromRGB(255, 255, 100)
LevelButton.TextSize = 12

DelayButton.Text = "Safety Delay: ON"
DelayButton.Position = UDim2.new(0.05, 0, 0.22, 0)
DelayButton.Size = UDim2.new(0.9, 0, 0.14, 0)
DelayButton.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
DelayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayButton.TextSize = 12

AutoMoveButton.Text = "Auto-Move: OFF (Manual)"
AutoMoveButton.Position = UDim2.new(0.05, 0, 0.40, 0)
AutoMoveButton.Size = UDim2.new(0.9, 0, 0.14, 0)
AutoMoveButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
AutoMoveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoMoveButton.TextSize = 12

ActionButton.Text = "Execute Calculation"
ActionButton.Position = UDim2.new(0.05, 0, 0.58, 0)
ActionButton.Size = UDim2.new(0.9, 0, 0.18, 0)
ActionButton.BackgroundColor3 = Color3.fromRGB(0, 110, 220)
ActionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionButton.TextSize = 14

MoveDisplay.Text = "Ready"
MoveDisplay.Position = UDim2.new(0.05, 0, 0.80, 0)
MoveDisplay.Size = UDim2.new(0.9, 0, 0.16, 0)
MoveDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MoveDisplay.TextColor3 = Color3.fromRGB(0, 255, 0)
MoveDisplay.TextScaled = true
-- Touch Dragger Calculus
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
game:GetService("UserInputService").InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)

LevelButton.MouseButton1Click:Connect(function()
    currentLevelIdx = currentLevelIdx + 1
    if currentLevelIdx > #levels then currentLevelIdx = 1 end
    LevelButton.Text = "Level: " .. levels[currentLevelIdx].name
end)

DelayButton.MouseButton1Click:Connect(function()
    safetyDelayEnabled = not safetyDelayEnabled
    if safetyDelayEnabled then
        DelayButton.Text = "Safety Delay: ON"
        DelayButton.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
    else
        DelayButton.Text = "Safety Delay: OFF (Instant)"
        DelayButton.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
    end
end)

AutoMoveButton.MouseButton1Click:Connect(function()
    autoMoveEnabled = not autoMoveEnabled
    if autoMoveEnabled then
        AutoMoveButton.Text = "Auto-Move: ON (Autonomous)"
        AutoMoveButton.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
    else
        AutoMoveButton.Text = "Auto-Move: OFF (Manual)"
        AutoMoveButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    end
end)

local isMinimised = false
ToggleSizeButton.MouseButton1Click:Connect(function()
    isMinimised = not isMinimised
    if isMinimised then
        ContentFrame.Visible = false
        MainFrame.Size = UDim2.new(0, 230, 0, 35)
        ToggleSizeButton.Text = "+"
    else
        ContentFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 230, 0, 260)
        ToggleSizeButton.Text = "–"
    end
end)

local activeHighlights = {}
local function clearOldHighlights()
    local board_model = game.Workspace:FindFirstChild("Board")
    if not board_model then return end
    for _, v in pairs(board_model:GetChildren()) do
        for _, h in pairs(v:GetChildren()) do
            if h:IsA("Highlight") then h:Destroy() end
        end
    end
    activeHighlights = {}
end

local function applyVisualHighlight(x, y, highlightColor)
    local board_model = game.Workspace:FindFirstChild("Board")
    if not board_model then return end
    local tile_name = tostring(x) .. "," .. tostring(y)
    local target_tile = board_model:FindFirstChild(tile_name)
    if target_tile then
        local hl = Instance.new("Highlight")
        hl.Parent = target_tile
        hl.FillColor = highlightColor
        hl.FillOpacity = 0.5
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineOpacity = 0.9
        table.insert(activeHighlights, hl)
    end
end

-- 🎯 LOCAL GAME ENGINE EXPLOIT INTERFACE
local function getInternalModules()
    local rep = game:GetService("ReplicatedStorage")
    local mods = rep:FindFirstChild("Modules")
    if mods then
        local sun = mods:FindFirstChild("SunfishHandler") and mods.SunfishHandler:FindFirstChild("Sunfish")
        local bka = mods:FindFirstChild("Board")
        if sun and bka then
            return require(bka), require(sun)
        end
    end
    return nil, nil
end

local function getActiveGameMemory()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "activeTeam") and rawget(v, "contents") and rawget(v, "tiles") then
            return v
        end
    end
    return nil
end

local piece_to_character = { Pawn={[true]="P",[false]="p"}, Knight={[true]="N",[false]="n"}, Bishop={[true]="B",[false]="b"}, Rook={[true]="R",[false]="r"}, Queen={[true]="Q",[false]="q"}, King={[true]="K",[false]="k"} }

local function generateLocalBoardString(current_board)
    local rows = {}
    for y = 8, 1, -1 do
        local row = " "
        for x = 8, 1, -1 do
            local piece = current_board.contents[x][y]
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

local function executeAutonomousMove(fromX, fromY, toX, toY)
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    local moveEvent = remotes and (remotes:FindFirstChild("MovePiece") or remotes:FindFirstChild("SubmitMove"))
    if moveEvent and moveEvent:IsA("RemoteEvent") then
        moveEvent:FireServer(fromX, fromY, toX, toY)
    end
end

-- Action Pipeline Execution
ActionButton.MouseButton1Click:Connect(function()
    clearOldHighlights()
    
    local board_mod, sunfish = getInternalModules()
    local current_board = getActiveGameMemory()
    
    if not current_board or not sunfish then
        MoveDisplay.Text = "Error: Sit At Table"
        return
    end
    
    if safetyDelayEnabled then
        local delayTime = math.random(3, 4)
        MoveDisplay.Text = "Syncing Engine (" .. delayTime .. "s)..."
        task.wait(delayTime)
    else
        MoveDisplay.Text = "Calculating locally..."
    end
    
    -- 🚀 LOCAL CALCULATION: Compiles the local game memory strings inside the game's Sunfish handler
    local bString = generateLocalBoardString(current_board)
    local activePlayer = current_board.activeTeam
    
    local stockfish_pos = sunfish.createPosition(bString, activePlayer, 0, {true, true}, {true, true}, 0, 0)
    local maxNodes = levels[currentLevelIdx].depth * 10000
    
    local results = sunfish.search(stockfish_pos, maxNodes, levels[currentLevelIdx].depth, {
        nodes = maxNodes,
        depth = levels[currentLevelIdx].depth,
        lategameBonusDepth = 2,
        tradeBonusMult = 0.2,
        aggressionBonus = 30,
        defenseBonus = 10,
        strength = 0
    })
    
    local best_move = results and sunfish.chooseMove(results, {relativeBadMoveCutoff = -100, worseMoveChance = 0})
    
    if best_move then
        local last_pos = sunfish.getPosition(best_move[1])
        local next_pos = sunfish.getPosition(best_move[2])
        
        -- Converts array coordinates cleanly to alphanumeric markers for display
        local columns = {"h","g","f","e","d","c","b","a"}
        local fromStr = string.upper(columns[last_pos[1]] .. tostring(last_pos[2]))
        local toStr = string.upper(columns[next_pos[1]] .. tostring(next_pos[2]))
        
        MoveDisplay.Text = "Move: " .. fromStr .. " ➔ " .. toStr
        
        if autoMoveEnabled then
            executeAutonomousMove(last_pos[1], last_pos[2], next_pos[1], next_pos[2])
        else
            applyVisualHighlight(last_pos[1], last_pos[2], Color3.fromRGB(255, 140, 0))
            applyVisualHighlight(next_pos[1], next_pos[2], Color3.fromRGB(0, 255, 100))
        end
    else
        MoveDisplay.Text = "Internal Calculation Failed"
    end
end)
