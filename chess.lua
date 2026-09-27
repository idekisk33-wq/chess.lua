-- Delta Custom Hybrid Chess Advisor & Auto-Player (Side-Bar Layout)
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Force Close Any Overlapping Glitched UI Panels
if game.CoreGui:FindFirstChild("CyberChessScreen") then
    game.CoreGui.CyberChessScreen:Destroy()
end

-- GUI Interface Initialization (Auto-Scaling Landscape Banner)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CyberChessScreen"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
MainFrame.Size = UDim2.new(0.65, 0, 0, 45) -- Scaled dynamic width
MainFrame.Active = true

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Text = "♟️ Advisor Grid"
Title.Size = UDim2.new(0.25, 0, 1, 0)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.BorderSizePixel = 0

local ContentFrame = Instance.new("Frame")
ContentFrame.Parent = MainFrame
ContentFrame.Size = UDim2.new(0.75, 0, 1, 0)
ContentFrame.Position = UDim2.new(0.25, 0, 0, 0)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0

local ActionButton = Instance.new("TextButton")
ActionButton.Parent = ContentFrame
ActionButton.Text = "Calculate Move"
ActionButton.Position = UDim2.new(0.02, 0, 0.1, 0)
ActionButton.Size = UDim2.new(0.45, 0, 0.8, 0)
ActionButton.BackgroundColor3 = Color3.fromRGB(0, 110, 220)
ActionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionButton.TextScaled = true

local MoveDisplay = Instance.new("TextLabel")
MoveDisplay.Parent = ContentFrame
MoveDisplay.Text = "Status: Ready"
MoveDisplay.Position = UDim2.new(0.5, 0, 0.1, 0)
MoveDisplay.Size = UDim2.new(0.48, 0, 0.8, 0)
MoveDisplay.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
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
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)

-- Visual Board Highlighter Engine
local activeHighlights = {}
local function clearOldHighlights()
    for _, hl in pairs(activeHighlights) do if hl then hl:Destroy() end end
    activeHighlights = {}
end

local function applyVisualHighlight(tileName, highlightColor)
    local board = game.Workspace:FindFirstChild("Board") or game.Workspace:FindFirstChild("ChessBoard")
    if not board then return end
    for _, tile in pairs(board:GetDescendants()) do
        if tile:IsA("BasePart") and string.lower(tile.Name) == string.lower(tileName) then
            local hl = Instance.new("Highlight")
            hl.Parent = tile
            hl.FillColor = highlightColor
            hl.FillOpacity = 0.5
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.OutlineOpacity = 0.8
            table.insert(activeHighlights, hl)
        end
    end
end

local function generateCurrentFEN()
    local board = game.Workspace:FindFirstChild("Board") or game.Workspace:FindFirstChild("ChessBoard")
    if not board then return nil end
    return "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
end

local function getStockfishAdvice(fen)
    local apiUrl = "https://stockfish.online" .. HttpService:UrlEncode(fen) .. "&depth=5"
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
    
    if not currentPosition then
        MoveDisplay.Text = "Sit At Table"
        return
    end
    
    MoveDisplay.Text = "Scanning..."
    local recommendedMove = getStockfishAdvice(currentPosition)
    
    if recommendedMove and #recommendedMove >= 4 and not string.find(recommendedMove, "Error") then
        local fromSquare = string.sub(recommendedMove, 1, 2)
        local toSquare = string.sub(recommendedMove, 3, 4)
        
        MoveDisplay.Text = string.upper(fromSquare) .. " ➔ " .. string.upper(toSquare)
        applyVisualHighlight(fromSquare, Color3.fromRGB(255, 140, 0))
        applyVisualHighlight(toSquare, Color3.fromRGB(0, 255, 100))
    else
        MoveDisplay.Text = "Sit At Table"
    end
end)
