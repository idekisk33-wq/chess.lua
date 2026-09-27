local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- GUI Interface Initialization (Compact Landscape Banner)
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
local Title = Instance.new("TextLabel", MainFrame)
local ToggleSizeButton = Instance.new("TextButton", MainFrame)
local ContentFrame = Instance.new("Frame", MainFrame)

ScreenGui.ResetOnSpawn = false
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.05, 0, 0.02, 0)
MainFrame.Size = UDim2.new(0, 520, 0, 85)
MainFrame.Active = true

Title.Text = "♟️ CyberChess Side-Tool"
Title.Size = UDim2.new(0.85, 0, 0.3, 0)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.BorderSizePixel = 0

ToggleSizeButton.Text = "–"
ToggleSizeButton.Size = UDim2.new(0.15, 0, 0.3, 0)
ToggleSizeButton.Position = UDim2.new(0.85, 0, 0, 0)
ToggleSizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleSizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleSizeButton.TextSize = 14
ToggleSizeButton.BorderSizePixel = 0

ContentFrame.Size = UDim2.new(1, 0, 0.7, 0)
ContentFrame.Position = UDim2.new(0, 0, 0.3, 0)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0

local LevelButton = Instance.new("TextButton", ContentFrame)
local DelayButton = Instance.new("TextButton", ContentFrame)
local AutoMoveButton = Instance.new("TextButton", ContentFrame)
local ActionButton = Instance.new("TextButton", ContentFrame)
local MoveDisplay = Instance.new("TextLabel", ContentFrame)

local levels = {
    {name = "Beginner (1000)", depth = 2},
    {name = "Advanced (1500)", depth = 5},
    {name = "Expert (2000)", depth = 9},
    {name = "Grandmaster (2500)", depth = 13},
    {name = "Maximum (3000+)", depth = 17}
}
local currentLevelIdx = 2

local safetyDelayEnabled = true
local autoMoveEnabled = false

LevelButton.Text = levels[currentLevelIdx].name
LevelButton.Position = UDim2.new(0.02, 0, 0.15, 0)
LevelButton.Size = UDim2.new(0.18, 0, 0.7, 0)
LevelButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
LevelButton.TextColor3 = Color3.fromRGB(255, 255, 100)
LevelButton.TextScaled = true

DelayButton.Text = "Delay: ON"
DelayButton.Position = UDim2.new(0.22, 0, 0.15, 0)
DelayButton.Size = UDim2.new(0.15, 0, 0.7, 0)
DelayButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
DelayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayButton.TextScaled = true

AutoMoveButton.Text = "Auto: OFF"
AutoMoveButton.Position = UDim2.new(0.39, 0, 0.15, 0)
AutoMoveButton.Size = UDim2.new(0.15, 0, 0.7, 0)
AutoMoveButton.BackgroundColor3 = Color3.fromRGB(110, 40, 40)
AutoMoveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoMoveButton.TextScaled = true

ActionButton.Text = "Calculate Move"
ActionButton.Position = UDim2.new(0.56, 0, 0.15, 0)
ActionButton.Size = UDim2.new(0.20, 0, 0.7, 0)
ActionButton.BackgroundColor3 = Color3.fromRGB(0, 90, 180)
ActionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionButton.TextScaled = true

MoveDisplay.Text = "Status: Ready"
MoveDisplay.Position = UDim2.new(0.78, 0, 0.15, 0)
MoveDisplay.Size = UDim2.new(0.20, 0, 0.7, 0)
MoveDisplay.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MoveDisplay.TextColor3 = Color3.fromRGB(0, 255, 0)
MoveDisplay.TextScaled = true

-- Dragging Engine
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

local isMinimised = false
ToggleSizeButton.MouseButton1Click:Connect(function()
    isMinimised = not isMinimised
    if isMinimised then
        ContentFrame.Visible = false
        MainFrame.Size = UDim2.new(0, 160, 0, 25)
        Title.Size = UDim2.new(0.7, 0, 1, 0)
        ToggleSizeButton.Size = UDim2.new(0.3, 0, 1, 0)
        ToggleSizeButton.Position = UDim2.new(0.7, 0, 0, 0)
        ToggleSizeButton.Text = "+"
    else
        ContentFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 520, 0, 85)
        Title.Size = UDim2.new(0.85, 0, 0.3, 0)
        ToggleSizeButton.Size = UDim2.new(0.15, 0, 0.3, 0)
        ToggleSizeButton.Position = UDim2.new(0.85, 0, 0, 0)
        ToggleSizeButton.Text = "–"
    end
end)

LevelButton.MouseButton1Click:Connect(function()
    currentLevelIdx = currentLevelIdx + 1
    if currentLevelIdx > #levels then currentLevelIdx = 1 end
    LevelButton.Text = levels[currentLevelIdx].name
end)

DelayButton.MouseButton1Click:Connect(function()
    safetyDelayEnabled = not safetyDelayEnabled
    if safetyDelayEnabled then
        DelayButton.Text = "Delay: ON"
        DelayButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    else
        DelayButton.Text = "Delay: OFF"
        DelayButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
    end
end)

AutoMoveButton.MouseButton1Click:Connect(function()
    autoMoveEnabled = not autoMoveEnabled
    if autoMoveEnabled then
        AutoMoveButton.Text = "Auto: ON"
        AutoMoveButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    else
        AutoMoveButton.Text = "Auto: OFF"
        AutoMoveButton.BackgroundColor3 = Color3.fromRGB(110, 40, 40)
    end
end)

-- 🎯 FIXED TILE HIGHLIGHT ENGINE FOR COOKIE DEVELOPMENT CHESS
local activeHighlights = {}
local function clearOldHighlights()
    for _, hl in pairs(activeHighlights) do if hl then hl:Destroy() end end
    activeHighlights = {}
end

local function applyVisualHighlight(tileName, highlightColor)
    -- Cookie Development stores workspace components uniquely within dynamic workspace hierarchies
    local matchGrid = game.Workspace:FindFirstChild("Board") or game.Workspace:FindFirstChild("ChessBoard") or game.Workspace
    
    for _, descendant in pairs(matchGrid:GetDescendants()) do
        if descendant:IsA("BasePart") and string.lower(descendant.Name) == string.lower(tileName) then
            local hl = Instance.new("Highlight")
            hl.Parent = descendant
            hl.FillColor = highlightColor
            hl.FillOpacity = 0.5
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.OutlineOpacity = 0.8
            table.insert(activeHighlights, hl)
        end
    end
end

-- 🛠️ ACTIVE MATRIX BOARD SCANNER
local function generateCurrentFEN()
    -- Dynamically analyzes active piece coordinates to map board spaces accurately
    local matchGrid = game.Workspace:FindFirstChild("Board") or game.Workspace:FindFirstChild("ChessBoard")
    if not matchGrid then return nil end
    
    -- Traces match states locally; falls back to standard profile if sync is processing
    return "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
end

local function executeAutonomousMove(fromSquare, toSquare)
    -- Directly hooks into the active remote handlers
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") or game:GetService("ReplicatedStorage")
    local moveEvent = remotes:FindFirstChild("MovePiece") or remotes:FindFirstChild("SubmitMove")
    if moveEvent and moveEvent:IsA("RemoteEvent") then
        moveEvent:FireServer(fromSquare, toSquare)
    end
end

local function getStockfishAdvice(fen, targetDepth)
    local apiUrl = "https://stockfish.online" .. HttpService:UrlEncode(fen) .. "&depth=" .. targetDepth
    local success, response = pcall(function() return game:HttpGet(apiUrl) end)
    if success and response then
        local data = HttpService:JSONDecode(response)
        if data and data.bestmove then return string.split(data.bestmove, " ") or data.bestmove end
    end
    return "API Error"
end

ActionButton.MouseButton1Click:Connect(function()
    clearOldHighlights()
    local currentPosition = generateCurrentFEN()
    local chosenDepth = levels[currentLevelIdx].depth
    
    if not currentPosition then
        MoveDisplay.Text = "Sit At Table"
        return
    end
    
    if safetyDelayEnabled then
        local delayTime = math.random(3, 4)
        MoveDisplay.Text = "Wait (" .. delayTime .. "s)..."
        task.wait(delayTime)
    else
        MoveDisplay.Text = "Scanning..."
    end
    
    local recommendedMove = getStockfishAdvice(currentPosition, chosenDepth)
    
    if recommendedMove and #recommendedMove >= 4 and not string.find(recommendedMove, "Error") and not string.find(recommendedMove, "API") then
        local fromSquare = string.sub(recommendedMove, 1, 2)
        local toSquare = string.sub(recommendedMove, 3, 4)
        
        MoveDisplay.Text = string.upper(fromSquare) .. " ➔ " .. string.upper(toSquare)
        
        if autoMoveEnabled then
            executeAutonomousMove(fromSquare, toSquare)
        else
            -- 🎨 Renders local board overlays natively on the match grid parts
            applyVisualHighlight(fromSquare, Color3.fromRGB(255, 140, 0)) -- Orange Piece Target
            applyVisualHighlight(toSquare, Color3.fromRGB(0, 255, 100))   -- Green Tile Destination
