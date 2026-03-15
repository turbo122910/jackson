-- 🔥 HEADSHOT AIMLOCK - AUTO AIM ABOVE CHEST 🔥
-- Aims slightly up for headshots

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Player references
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- =============== SETTINGS ===============
local AIM_KEY = Enum.UserInputType.MouseButton2  -- Right mouse button
local MAX_DISTANCE = 300
local FOV_ANGLE = 30
local SMOOTHNESS = 0.3

-- HEADSHOT ADJUSTMENT SETTINGS
local HEADSHOT_HEIGHT = 2.8  -- How high above torso to aim (in studs)
local AIM_AT_HEAD = true     -- Try to find head first
local FORCE_HEADSHOT = true  -- Always aim above torso even if head not found

-- State
local isAiming = false
local currentTarget = nil

-- =============== MOUSE MOVEMENT ===============
local function moveMouse(deltaX, deltaY)
    return pcall(function()
        mousemoverel(deltaX, deltaY)
    end)
end

-- =============== HEADSHOT AIM POSITION ===============
local function getHeadshotPosition(player)
    if not player or not player.Character then return nil end
    
    local char = player.Character
    
    -- Try to get actual head first
    if AIM_AT_HEAD then
        local head = char:FindFirstChild("Head")
        if head then
            -- Aim at center of head
            return head.Position
        end
    end
    
    -- If no head found, aim above torso
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        -- Aim HEADSHOT_HEIGHT studs above the torso
        return hrp.Position + Vector3.new(0, HEADSHOT_HEIGHT, 0)
    end
    
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if torso then
        -- Aim above torso
        return torso.Position + Vector3.new(0, HEADSHOT_HEIGHT - 0.5, 0)
    end
    
    -- Last resort: Get bounding box and aim at upper portion
    local _, size = char:GetBoundingBox()
    return char:GetPivot().Position + Vector3.new(0, size.Y * 0.8, 0)  -- 80% up the character
end

-- =============== TARGET SELECTION ===============
local function getBestTarget()
    local bestTarget = nil
    local closestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        -- Skip self
        if player == LocalPlayer then continue end
        
        -- Check if has character
        if not player.Character then continue end
        
        -- Check if alive
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        -- Get headshot position
        local aimPos = getHeadshotPosition(player)
        if not aimPos then continue end
        
        -- Calculate distance
        local distance = (aimPos - Camera.CFrame.Position).Magnitude
        if distance > MAX_DISTANCE then continue end
        
        -- Check if in FOV
        local screenPos, onScreen = Camera:WorldToScreenPoint(aimPos)
        if not onScreen then continue end
        
        -- Calculate screen distance from crosshair
        local centerX = Camera.ViewportSize.X / 2
        local centerY = Camera.ViewportSize.Y / 2
        local screenDist = math.sqrt((screenPos.X - centerX)^2 + (screenPos.Y - centerY)^2)
        
        if screenDist < closestDistance then
            closestDistance = screenDist
            bestTarget = player
        end
    end
    
    return bestTarget
end

-- =============== AIM FUNCTION WITH HEADSHOT ===============
local function aimWithHeadshot()
    if not currentTarget or not currentTarget.Character then
        currentTarget = getBestTarget()
        if not currentTarget then return false end
    end
    
    -- Get headshot position
    local aimPos = getHeadshotPosition(currentTarget)
    if not aimPos then
        currentTarget = getBestTarget()
        return false
    end
    
    -- Get screen position of headshot
    local screenPos = Camera:WorldToScreenPoint(aimPos)
    
    -- Calculate movement to headshot position
    local deltaX = screenPos.X - Mouse.X
    local deltaY = screenPos.Y - Mouse.Y
    
    -- Apply smoothing
    deltaX = deltaX * SMOOTHNESS
    deltaY = deltaY * SMOOTHNESS
    
    -- Only move if significant
    if math.abs(deltaX) > 1 or math.abs(deltaY) > 1 then
        return moveMouse(deltaX, deltaY)
    end
    
    return true
end

-- =============== INPUT HANDLER ===============
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == AIM_KEY then
        isAiming = true
        print("🎯 HEADSHOT AIM ACTIVATED")
        
        -- Find target immediately
        currentTarget = getBestTarget()
        if currentTarget then
            
            -- Show headshot position info
            local aimPos = getHeadshotPosition(currentTarget)
            if aimPos then
                local hrp = currentTarget.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local heightAbove = aimPos.Y - hrp.Position.Y
                    print("📏 Aiming " .. math.floor(heightAbove * 10)/10 .. " studs above torso")
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == AIM_KEY then
        isAiming = false
        currentTarget = nil
    end
end)

-- =============== MAIN LOOP ===============
RunService.RenderStepped:Connect(function()
    if not isAiming then return end
    
    -- Aim with headshot adjustment
    local success = aimWithHeadshot()
    
    -- If failed, find new target
    if not success then
        currentTarget = getBestTarget()
    end
end)

-- =============== VISUAL INDICATOR ===============
local function createHeadshotIndicator()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HeadshotIndicator"
    screenGui.ResetOnSpawn = false
    
    -- Crosshair with headshot marker
    local crosshair = Instance.new("Frame")
    crosshair.Name = "Crosshair"
    crosshair.Size = UDim2.new(0, 20, 0, 20)
    crosshair.Position = UDim2.new(0.5, -10, 0.5, -10)
    crosshair.BackgroundTransparency = 1
    
    -- Main crosshair dot
    local dot = Instance.new("Frame")
    dot.Name = "CenterDot"
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0.5, -2, 0.5, -2)
    dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    dot.BackgroundTransparency = 0.5
    dot.BorderSizePixel = 0
    dot.Parent = crosshair
    
    -- Headshot indicator (small dot above center)
    local headshotDot = Instance.new("Frame")
    headshotDot.Name = "HeadshotDot"
    headshotDot.Size = UDim2.new(0, 2, 0, 2)
    headshotDot.Position = UDim2.new(0.5, -1, 0.45, -1)  -- Positioned above center
    headshotDot.BackgroundColor3 = Color3.fromRGB(0, 255, 255)  -- Cyan color
    headshotDot.BackgroundTransparency = 0.3
    headshotDot.BorderSizePixel = 0
    headshotDot.Visible = isAiming
    headshotDot.Parent = crosshair
    
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Show headshot dot only when aiming
    RunService.RenderStepped:Connect(function()
        headshotDot.Visible = isAiming
    end)
    
    return crosshair
end

-- =============== DEBUG FUNCTIONS ===============
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Test with H key
    if input.KeyCode == Enum.KeyCode.H then
        print("=== HEADSHOT DEBUG ===")
        
        if currentTarget and currentTarget.Character then
            local aimPos = getHeadshotPosition(currentTarget)
            local hrp = currentTarget.Character:FindFirstChild("HumanoidRootPart")
            
            if aimPos and hrp then
                local heightDiff = aimPos.Y - hrp.Position.Y
                print("Target: " .. currentTarget.Name)
                print("HRP Position: " .. tostring(hrp.Position))
                print("Headshot Position: " .. tostring(aimPos))
                print("Height above torso: " .. math.floor(heightDiff * 10)/10 .. " studs")
                print("Aiming for head: " .. tostring(AIM_AT_HEAD))
            end
        else
            print("No current target")
        end
    end
    
    -- Adjust headshot height with + and - keys
    if input.KeyCode == Enum.KeyCode.Equals then  -- + key
        HEADSHOT_HEIGHT = HEADSHOT_HEIGHT + 0.75
        print("📏 Headshot height increased to: " .. HEADSHOT_HEIGHT .. " studs")
    end
    
    if input.KeyCode == Enum.KeyCode.Minus then  -- - key
        HEADSHOT_HEIGHT = math.max(0.5, HEADSHOT_HEIGHT - 0.5)
        print("📏 Headshot height decreased to: " .. HEADSHOT_HEIGHT .. " studs")
    end
    
    -- Toggle head aiming with B key
    if input.KeyCode == Enum.KeyCode.B then
        AIM_AT_HEAD = not AIM_AT_HEAD
        print("🧠 Head aiming: " .. (AIM_AT_HEAD and "ENABLED" or "DISABLED"))
    end
end)

-- =============== INITIALIZATION ===============
-- Create headshot indicator
createHeadshotIndicator()
