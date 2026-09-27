-- Delta Automated Universal Chess Link & Sync Engine
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
    {name = "Advanced (1500 Elo)", depth = 5},
    {name = "Expert (2000 Elo)", depth = 9},
    {name = "Grandmaster (2500 Elo)", depth = 13},
    {name = "Maximum (3000+ Elo)", depth = 17}
}
local currentLevelIdx = 3 -- Expert Level

local safetyDelayEnabled = true
local autoMoveEnabled = false
local moveCounter = 0 -- 🛠️ NEW: Tracks turn progression to humanize delay dynamically

LevelButton.Text = "Level: " .. levels[currentLevelIdx].name
LevelButton.Position = UDim2.new(0.05, 0, 0.04, 0)
LevelButton.Size = UDim2.new(0.9, 0, 0.14, 0)
LevelButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
LevelButton.TextColor3 = Color3.fromRGB(255, 255, 100)
LevelButton.TextSize = 12

DelayButton.Text = "Adaptive Delay: SMART"
DelayButton.Position = UDim2.new(0.05, 0, 0.22, 0)
DelayButton.Size = UDim2.new(0.9, 0, 0.14, 0)
DelayButton.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
DelayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayButton.TextSize = 12

AutoMoveButton.Text = "Sync Mirror: OFF (Manual)"
AutoMoveButton.Position = UDim2.new(0.05, 0, 0.40, 0)
AutoMoveButton.Size = UDim2.new(0.9, 0, 0.14, 0)
AutoMoveButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
AutoMoveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoMoveButton.TextSize = 12

ActionButton.Text = "Sync & Play Move"
ActionButton.Position = UDim2.new(0.05, 0, 0.58, 0)
ActionButton.Size = UDim2.new(0.9, 0, 0.18, 0)
ActionButton.BackgroundColor3 = Color3.fromRGB(0, 110, 220)
ActionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionButton.TextSize = 14

MoveDisplay.Text = "Ready (Turn 0)"
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
        DelayButton.Text = "Adaptive Delay: SMART"
        DelayButton.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
    else
        DelayButton.Text = "Adaptive Delay: INSTANT"
        DelayButton.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
    end
end)

AutoMoveButton.MouseButton1Click:Connect(function()
    autoMoveEnabled = not autoMoveEnabled
    if autoMoveEnabled then
        AutoMoveButton.Text = "Sync Mirror: ON (Auto)"
        AutoMoveButton.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
    else
        AutoMoveButton.Text = "Sync Mirror: OFF (Manual)"
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
    for _, hl in pairs(activeHighlights) do if hl then hl:Destroy() end end
    activeHighlights = {}
end

local function applyVisualHighlight(tileName, highlightColor)
    for _, part in pairs(game.Workspace:GetDescendants()) do
        if part:IsA("BasePart") and string.lower(part.Name) == string.lower(tileName) then
            local hl = Instance.new("Highlight")
            hl.Parent = part
            hl.FillColor = highlightColor
            hl.FillOpacity = 0.5
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.OutlineOpacity = 0.8
            table.insert(activeHighlights, hl)
        end
    end
end

-- 🛠️ GARBAGE COLLECTION MEMORY CAPTURE
local function getActiveGameMemory()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "activeTeam") and rawget(v, "contents") and rawget(v, "tiles") then
            return v
        end
    end
    return nil
end

local piece_map = { Pawn="p", Knight="n", Bishop="b", Rook="r", Queen="q", King="k" }

local function generateLiveCookieFEN()
    local current_board = getActiveGameMemory()
    if not current_board then return nil end
    local fenRows = {}
    for y = 8, 1, -1 do
        local currentRowText = ""
        local emptyCount = 0
        for x = 8, 1, -1 do
            local piece = current_board.contents[x][y]
            if piece then
                if emptyCount > 0 then
                    currentRowText = currentRowText .. tostring(emptyCount)
                    emptyCount = 0
                end
                local letter = piece_map[piece.Name] or "p"
                currentRowText = currentRowText .. (piece.team and string.upper(letter) or letter)
            else
                emptyCount = emptyCount + 1
            end
        end
        if emptyCount > 0 then currentRowText = currentRowText .. tostring(emptyCount) end
        table.insert(fenRows, currentRowText)
    end
    local turn = current_board.activeTeam and "w" or "b"
    return table.concat(fenRows, "/") .. " " .. turn .. " KQkq - 0 1"
end

-- Reset Turn Counter if board disappears/reloads
game.Workspace.ChildRemoved:Connect(function(child)
    if string.find(string.lower(child.Name), "board") or string.find(string.lower(child.Name), "chess") then
        moveCounter = 0
    end
end)

local function executeAutonomousMove(fromX, fromY, toX, toY)
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") or game:GetService("ReplicatedStorage")
    local moveEvent = remotes:FindFirstChild("MovePiece") or remotes:FindFirstChild("SubmitMove")
    if moveEvent and moveEvent:IsA("RemoteEvent") then
        moveEvent:FireServer(fromX, fromY, toX, toY)
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

-- Main Synchronization Event Pipeline
ActionButton.MouseButton1Click:Connect(function()
    clearOldHighlights()
    local currentPosition = generateLiveCookieFEN()
    local chosenDepth = levels[currentLevelIdx].depth
    
    if not currentPosition then
        MoveDisplay.Text = "Error: Stand inside table"
        return
    end
    
    -- 🧠 ADAPTIVE DELAY CALCULATION LAYER
    if safetyDelayEnabled then
        moveCounter = moveCounter + 1
        local delayTime = 0
        
        if moveCounter <= 5 then
            delayTime = math.random(0, 1) -- ⚡ Openings: Ultra fast response
        elseif moveCounter <= 12 then
            delayTime = math.random(2, 4) -- ⚙️ Midgame: Average human thinking time
        else
            delayTime = math.random(5, 8) -- 🐢 Endgame: Deep critical analysis delay
        end
        
        MoveDisplay.Text = "Thinking (" .. delayTime .. "s) | Turn " .. moveCounter .. "..."
        task.wait(delayTime)
    else
        MoveDisplay.Text = "Calculating..."
    end
    
    local recommendedMove = getStockfishAdvice(currentPosition, chosenDepth)
    if recommendedMove and #recommendedMove >= 4 and not string.find(recommendedMove, "Error") then
        local files = {a=8, b=7, c=6, d=5, e=4, f=3, g=2, h=1}
        local fromX = files[string.sub(recommendedMove, 1, 1)]
        local fromY = tonumber(string.sub(recommendedMove, 2, 2))
        local toX = files[string.sub(recommendedMove, 3, 3)]
        local toY = tonumber(string.sub(recommendedMove, 4, 4))
        
        MoveDisplay.Text = "Played: " .. string.upper(string.sub(recommendedMove,1,2)) .. " ➔ " .. string.upper(string.sub(recommendedMove,3,4))
        
        if autoMoveEnabled then
            executeAutonomousMove(fromX, fromY, toX, toY)
        else
            local fromTile = tostring(fromX) .. "," .. tostring(fromY)
            local toTile = tostring(toX) .. "," .. tostring(toY)
            applyVisualHighlight(fromTile, Color3.fromRGB(255, 140, 0))
            applyVisualHighlight(toTile, Color3.fromRGB(0, 255, 100))
        end
    else
        MoveDisplay.Text = "Sync Fail: Try Again"
    end
end)
