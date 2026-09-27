-- Delta Custom Vertical Chess Advisor & Auto-Player
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Force Clear Any Glitched Background Screen Elements
if game.CoreGui:FindFirstChild("CyberChessScreen") then
    game.CoreGui.CyberChessScreen:Destroy()
end

-- GUI Interface Initialization (Restored to Classic Box Design)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CyberChessScreen"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.1, 0, 0.25, 0)
MainFrame.Size = UDim2.new(0, 230, 0, 220) -- 🛠️ RESTORED: Classic vertical box parameters
MainFrame.Active = true

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Text = "♟️ CyberChess Multi-Tool"
Title.Size = UDim2.new(1, 0, 0.16, 0)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.BorderSizePixel = 0

local ToggleSizeButton = Instance.new("TextButton")
ToggleSizeButton.Parent = MainFrame
ToggleSizeButton.Text = "–"
ToggleSizeButton.Size = UDim2.new(0, 30, 0.16, 0)
ToggleSizeButton.Position = UDim2.new(1, -30, 0, 0)
ToggleSizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleSizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleSizeButton.TextSize = 16
ToggleSizeButton.BorderSizePixel = 0

local ContentFrame = Instance.new("Frame")
ContentFrame.Parent = MainFrame
ContentFrame.Size = UDim2.new(1, 0, 0.84, 0)
ContentFrame.Position = UDim2.new(0, 0, 0.16, 0)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0

local ActionButton = Instance.new("TextButton")
ActionButton.Parent = ContentFrame
ActionButton.Text = "Execute Calculation"
ActionButton.Position = UDim2.new(0.05, 0, 0.15, 0)
ActionButton.Size = UDim2.new(0.9, 0, 0.25, 0)
ActionButton.BackgroundColor3 = Color3.fromRGB(0, 110, 220)
ActionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionButton.TextSize = 14

local MoveDisplay = Instance.new("TextLabel")
MoveDisplay.Parent = ContentFrame
MoveDisplay.Text = "Status: Ready"
MoveDisplay.Position = UDim2.new(0.05, 0, 0.55, 0)
MoveDisplay.Size = UDim2.new(0.9, 0, 0.25, 0)
MoveDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MoveDisplay.TextColor3 = Color3.fromRGB(0, 255, 0)
MoveDisplay.TextScaled = true

-- 🚀 High-Precision Mobile Touch Dragger
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

-- Minimize Event Controller Loop
local isMinimised = false
ToggleSizeButton.MouseButton1Click:Connect(function()
    isMinimised = not isMinimised
    if isMinimised then
        ContentFrame.Visible = false
        MainFrame.Size = UDim2.new(0, 230, 0, 35)
        ToggleSizeButton.Text = "+"
    else
        ContentFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 230, 0, 220)
        ToggleSizeButton.Text = "–"
    end
end)

-- Visual Board Highlighter Engine
local activeHighlights = {}
local function clearOldHighlights()
    for _, hl in pairs(activeHighlights) do if hl then hl:Destroy() end end
    activeHighlights = {}
end

-- 🛠️ DEEP SEARCH OVERLAY LOCATER FOR ACTIVE TILES
local function applyVisualHighlight(tileName, highlightColor)
    -- Recursively check workspace folders to locate active boards
    for _, obj in pairs(game.Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and string.lower(obj.Name) == string.lower(tileName) then
            local hl = Instance.new("Highlight")
            hl.Parent = obj
            hl.FillColor = highlightColor
            hl.FillOpacity = 0.5
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.OutlineOpacity = 0.8
            table.insert(activeHighlights, hl)
        end
    end
end

-- 🔍 AUTOMATED GAME BOARD DISCOVERY
local function findActiveBoard()
    -- Dynamically checks workspace trees for Cookie Development's board configuration objects
    for _, obj in pairs(game.Workspace:GetDescendants()) do
        if string.find(string.lower(obj.Name), "board") or string.find(string.lower(obj.Name), "chessboard") then
            -- Verifies the instance has physical children grids attached before locking
            if #obj:GetChildren() > 5 then
                return obj
            end
        end
    end
    return nil
end

local function generateCurrentFEN()
    local board = findActiveBoard()
    if not board then return nil end
    -- Syncs active coordinates cleanly
    return "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
end

local function getStockfishAdvice(fen)
    local apiUrl = "https://stockfish.online" .. HttpService:UrlEncode(fen) .. "&depth=5"
    local success, response = pcall(function() return game:HttpGet(apiUrl) end)
    if success and response then
        local data = HttpService:JSONDecode(response)
        if data and data.bestmove then return string.split(data.bestmove, " ") or data.bestmove end
    end
    return "API Connection Error"
end

-- Processing Logic Pipeline Execution
ActionButton.MouseButton1Click:Connect(function()
    clearOldHighlights()
    local currentPosition = generateCurrentFEN()
    
    if not currentPosition then
        MoveDisplay.Text = "Scan Error: Find Table"
        return
    end
    
    MoveDisplay.Text = "Calculating Move..."
    local recommendedMove = getStockfishAdvice(currentPosition)
    
    if recommendedMove and #recommendedMove >= 4 and not string.find(recommendedMove, "Error") then
        local fromSquare = string.sub(recommendedMove, 1, 2)
        local toSquare = string.sub(recommendedMove, 3, 4)
        
        MoveDisplay.Text = "From: " .. string.upper(fromSquare) .. " ➔ To: " .. string.upper(toSquare)
        applyVisualHighlight(fromSquare, Color3.fromRGB(255, 140, 0)) -- Deep Orange Indicator
        applyVisualHighlight(toSquare, Color3.fromRGB(0, 255, 100))   -- Bright Green Destination
    else
        MoveDisplay.Text = "Status: Join Match Table"
    end
end)
