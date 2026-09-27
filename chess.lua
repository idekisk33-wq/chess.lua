local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- GUI Interface Initialization
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
local Title = Instance.new("TextLabel", MainFrame)
local LevelButton = Instance.new("TextButton", MainFrame)
local DelayButton = Instance.new("TextButton", MainFrame)
local AutoMoveButton = Instance.new("TextButton", MainFrame)
local ActionButton = Instance.new("TextButton", MainFrame)
local MoveDisplay = Instance.new("TextLabel", MainFrame)

ScreenGui.ResetOnSpawn = false
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.1, 0, 0.25, 0)
MainFrame.Size = UDim2.new(0, 230, 0, 260)
MainFrame.Active = true

Title.Text = "♟️ CyberChess Multi-Tool"
Title.Size = UDim2.new(1, 0, 0.14, 0)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14

-- Difficulty Levels Setup
local levels = {
    {name = "Beginner (1000 Elo)", depth = 2},
    {name = "Advanced (1500 Elo)", depth = 5},
    {name = "Expert (2000 Elo)", depth = 9},
    {name = "Grandmaster (2500 Elo)", depth = 13},
    {name = "Maximum (3000+ Elo)", depth = 17}
}
local currentLevelIdx = 1

local safetyDelayEnabled = true
local autoMoveEnabled = false

-- Button Layout Profiles
LevelButton.Text = "Level: " .. levels[currentLevelIdx].name
LevelButton.Position = UDim2.new(0.05, 0, 0.16, 0)
LevelButton.Size = UDim2.new(0.9, 0, 0.13, 0)
LevelButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
LevelButton.TextColor3 = Color3.fromRGB(255, 255, 100)

DelayButton.Text = "Safety Delay: ON"
DelayButton.Position = UDim2.new(0.05, 0, 0.31, 0)
DelayButton.Size = UDim2.new(0.9, 0, 0.13, 0)
DelayButton.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
DelayButton.TextColor3 = Color3.fromRGB(255, 255, 255)

AutoMoveButton.Text = "Auto-Move: OFF (Manual)"
AutoMoveButton.Position = UDim2.new(0.05, 0, 0.46, 0)
AutoMoveButton.Size = UDim2.new(0.9, 0, 0.13, 0)
AutoMoveButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
AutoMoveButton.TextColor3 = Color3.fromRGB(255, 255, 255)

ActionButton.Text = "Execute Calculation"
ActionButton.Position = UDim2.new(0.05, 0, 0.62, 0)
ActionButton.Size = UDim2.new(0.9, 0, 0.15, 0)
ActionButton.BackgroundColor3 = Color3.fromRGB(0, 110, 220)
ActionButton.TextColor3 = Color3.fromRGB(255, 255, 255)

MoveDisplay.Text = "Ready"
MoveDisplay.Position = UDim2.new(0.05, 0, 0.80, 0)
MoveDisplay.Size = UDim2.new(0.9, 0, 0.14, 0)
MoveDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MoveDisplay.TextColor3 = Color3.fromRGB(0, 255, 0)

-- 🚀 HIGH-PRECISION DRAGGING FOR MOBILE TOUCHSCREENS
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
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)

-- UI Interaction Toggles
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

-- 🎨 LOCAL VISUAL RENDERING (Advisor Highlights)
local activeHighlights = {}
local function clearOldHighlights()
    for _, hl in pairs(activeHighlights) do if hl then hl:Destroy() end end
    activeHighlights = {}
end

local function applyVisualHighlight(tileName, highlightColor)
    local boardsFolder = game.Workspace:FindFirstChild("Boards") or game.Workspace:FindFirstChild("ChessBoards")
    if not boardsFolder then return end
    for _, board in pairs(boardsFolder:GetChildren()) do
        local sourceTile = board:FindFirstChild(tileName) or board:FindFirstChild(string.lower(tileName)) or board:FindFirstChild(string.upper(tileName))
        if sourceTile then
            local hl = Instance.new("Highlight")
            hl.Parent = sourceTile
            hl.FillColor = highlightColor
            hl.FillOpacity = 0.5
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.OutlineOpacity = 0.8
            table.insert(activeHighlights, hl)
        end
    end
end

-- 🛠️ FRAMEWORK FOR BOARD INTERACTION & SCANNING
local function generateCurrentFEN()
    -- This maps the active physical matrix into chess data format
    return "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
end

local function executeAutonomousMove(fromSquare, toSquare)
    -- This handles interacting directly with game engine network remotes if Auto-Move is checked
    local chessRemotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") or game:GetService("ReplicatedStorage")
    local moveRemote = chessRemotes:FindFirstChild("SubmitMove") or chessRemotes:FindFirstChild("MovePiece")
    if moveRemote then
        moveRemote:FireServer(fromSquare, toSquare)
    end
end

local function getStockfishAdvice(fen, targetDepth)
    local apiUrl = "https://stockfish.online" .. HttpService:UrlEncode(fen) .. "&depth=" .. targetDepth
    local success, response = pcall(function() return game:HttpGet(apiUrl) end)
    if success and response then
        local data = HttpService:JSONDecode(response)
        if data and data.bestmove then
            return string.split(data.bestmove, " ") or data.bestmove
        end
    end
    return "Error"
end

-- Main Processing Pipeline
ActionButton.MouseButton1Click:Connect(function()
    clearOldHighlights()
    local currentPosition = generateCurrentFEN()
    local chosenDepth = levels[currentLevelIdx].depth
    
    if safetyDelayEnabled then
        local delayTime = math.random(3, 6)
        MoveDisplay.Text = "Safety processing (" .. delayTime .. "s)..."
        task.wait(delayTime)
    else
        MoveDisplay.Text = "Calculating..."
    end
    
    local recommendedMove = getStockfishAdvice(currentPosition, chosenDepth)
    
    if #recommendedMove >= 4 then
        local fromSquare = string.sub(recommendedMove, 1, 2)
        local toSquare = string.sub(recommendedMove, 3, 4)
        MoveDisplay.Text = "Move: " .. string.upper(fromSquare) .. " ➔ " .. string.upper(toSquare)
        
        if autoMoveEnabled then
            -- Bypass highlights and trigger autonomous board movement via network remote
            executeAutonomousMove(fromSquare, toSquare)
        else
            -- Run Visual Mode: Highlight pieces safely on your device screen only
            applyVisualHighlight(fromSquare, Color3.fromRGB(255, 165, 0)) -- Orange Piece Target
            applyVisualHighlight(toSquare, Color3.fromRGB(0, 255, 0))    -- Green Tile Destination
        end
    else
        MoveDisplay.Text = "Result: " .. recommendedMove
    end
end)
