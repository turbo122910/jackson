-- Advanced Fly Script for Roblox
-- Put this in a LocalScript

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Configuration
local FLY_SPEED = 50
local BOOST_MULTIPLIER = 3
local MOUSE_SENSITIVITY = 0.5
local SMOOTHNESS = 0.2
local MAX_SPEED = 200
local ACCELERATION = 2

-- State variables
local flying = false
local speed = FLY_SPEED
local velocity = Vector3.new(0, 0, 0)
local bodyVelocity
local bodyGyro
local lastInput = {}

-- Toggle key (change to your preference)
local TOGGLE_KEY = Enum.KeyCode.F
local BOOST_KEY = Enum.KeyCode.LeftShift
local ALT_CONTROL_KEY = Enum.KeyCode.LeftAlt  -- For alternative control scheme

-- Control schemes
local controlSchemes = {
    -- Standard: WASD + Space/Shift
    STANDARD = {
        forward = Enum.KeyCode.W,
        backward = Enum.KeyCode.S,
        left = Enum.KeyCode.A,
        right = Enum.KeyCode.D,
        up = Enum.KeyCode.Space,
        down = Enum.KeyCode.LeftShift
    },
    
    -- Arrow keys alternative
    ARROWS = {
        forward = Enum.KeyCode.Up,
        backward = Enum.KeyCode.Down,
        left = Enum.KeyCode.Left,
        right = Enum.KeyCode.Right,
        up = Enum.KeyCode.PageUp,
        down = Enum.KeyCode.PageDown
    },
    
    -- Gamepad style (WASD + Q/E)
    GAMEPAD = {
        forward = Enum.KeyCode.W,
        backward = Enum.KeyCode.S,
        left = Enum.KeyCode.A,
        right = Enum.KeyCode.D,
        up = Enum.KeyCode.Q,
        down = Enum.KeyCode.E
    }
}

local currentScheme = controlSchemes.STANDARD
local useAlternative = false  -- Toggle between standard and current scheme

-- Create flying parts
local function createFlyingParts()
    local character = LocalPlayer.Character
    if not character then return nil, nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil, nil end
    
    -- BodyVelocity for movement
    if bodyVelocity then bodyVelocity:Destroy() end
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FlyVelocity"
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.P = 10000
    bodyVelocity.Parent = humanoidRootPart
    
    -- BodyGyro for rotation
    if bodyGyro then bodyGyro:Destroy() end
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FlyGyro"
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 10000
    bodyGyro.D = 100
    bodyGyro.Parent = humanoidRootPart
    
    -- Set initial rotation to match camera
    bodyGyro.CFrame = Camera.CFrame
    
    return bodyVelocity, bodyGyro
end

-- Start flying
local function startFlying()
    if flying then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Enable flying state
    flying = true
    
    -- Create physics parts
    createFlyingParts()
    
    -- Disable gravity for a smoother experience
    humanoid.PlatformStand = true
    
    -- Create visual effects
    createFlyEffects(true)
    
    -- Play sound
    playFlySound(true)
    
    -- Update GUI
    updateFlyGUI(true)
    
    print("Fly mode: ENABLED")
    print("Controls:")
    print("- " .. currentScheme.forward.Name .. ": Forward")
    print("- " .. currentScheme.backward.Name .. ": Backward")
    print("- " .. currentScheme.left.Name .. ": Left")
    print("- " .. currentScheme.right.Name .. ": Right")
    print("- " .. currentScheme.up.Name .. ": Up")
    print("- " .. currentScheme.down.Name .. ": Down")
    print("- " .. BOOST_KEY.Name .. ": Boost")
    print("- " .. ALT_CONTROL_KEY.Name .. ": Toggle control scheme")
    print("- Mouse: Look around")
end

-- Stop flying
local function stopFlying()
    if not flying then return end
    
    flying = false
    
    -- Remove physics parts
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    
    -- Re-enable gravity
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
    
    -- Remove visual effects
    createFlyEffects(false)
    
    -- Stop sound
    playFlySound(false)
    
    -- Update GUI
    updateFlyGUI(false)
    
    print("Fly mode: DISABLED")
end

-- Toggle flying
local function toggleFlying()
    if flying then
        stopFlying()
    else
        startFlying()
    end
end

-- Toggle control scheme
local function toggleControlScheme()
    useAlternative = not useAlternative
    
    if useAlternative then
        -- Cycle through available schemes
        if currentScheme == controlSchemes.STANDARD then
            currentScheme = controlSchemes.ARROWS
        elseif currentScheme == controlSchemes.ARROWS then
            currentScheme = controlSchemes.GAMEPAD
        else
            currentScheme = controlSchemes.STANDARD
        end
    else
        currentScheme = controlSchemes.STANDARD
    end
    
    print("Control scheme: " .. (useAlternative and "ALTERNATIVE" or "STANDARD"))
    if useAlternative then
        print("Using: " .. 
            currentScheme.forward.Name .. "/" ..
            currentScheme.backward.Name .. "/" ..
            currentScheme.left.Name .. "/" ..
            currentScheme.right.Name .. "/" ..
            currentScheme.up.Name .. "/" ..
            currentScheme.down.Name)
    end
end

-- Handle input for movement
local function handleMovement(inputState)
    if inputState == Enum.UserInputState.Begin then
        lastInput[input.KeyCode] = true
    elseif inputState == Enum.UserInputState.End then
        lastInput[input.KeyCode] = nil
    end
end

-- Calculate movement direction
local function getMovementDirection()
    local direction = Vector3.new(0, 0, 0)
    local isBoosting = UserInputService:IsKeyDown(BOOST_KEY)
    local currentSpeed = isBoosting and speed * BOOST_MULTIPLIER or speed
    
    -- Get camera vectors
    local lookVector = Camera.CFrame.LookVector
    local rightVector = Camera.CFrame.RightVector
    local upVector = Vector3.new(0, 1, 0)
    
    -- Check each movement key
    if UserInputService:IsKeyDown(currentScheme.forward) then
        direction = direction + lookVector
    end
    if UserInputService:IsKeyDown(currentScheme.backward) then
        direction = direction - lookVector
    end
    if UserInputService:IsKeyDown(currentScheme.left) then
        direction = direction - rightVector
    end
    if UserInputService:IsKeyDown(currentScheme.right) then
        direction = direction + rightVector
    end
    if UserInputService:IsKeyDown(currentScheme.up) then
        direction = direction + upVector
    end
    if UserInputService:IsKeyDown(currentScheme.down) then
        direction = direction - upVector
    end
    
    -- Normalize direction and apply speed
    if direction.Magnitude > 0 then
        direction = direction.Unit * currentSpeed
    end
    
    return direction
end

-- Mouse look
local mouseDelta = Vector2.new(0, 0)
local yaw = 0
local pitch = 0

UserInputService.InputChanged:Connect(function(input)
    if not flying then return end
    
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        mouseDelta = input.Delta
        
        -- Update camera rotation
        yaw = yaw - mouseDelta.X * MOUSE_SENSITIVITY
        pitch = math.clamp(pitch - mouseDelta.Y * MOUSE_SENSITIVITY, -89, 89)
        
        if bodyGyro then
            local character = LocalPlayer.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- Calculate new CFrame
                    local newCFrame = CFrame.new(hrp.Position) *
                                     CFrame.Angles(0, math.rad(yaw), 0) *
                                     CFrame.Angles(math.rad(pitch), 0, 0)
                    
                    -- Smooth rotation
                    bodyGyro.CFrame = bodyGyro.CFrame:Lerp(newCFrame, SMOOTHNESS)
                end
            end
        end
    end
end)

-- Main update loop
RunService.Heartbeat:Connect(function(deltaTime)
    if not flying or not bodyVelocity or not bodyGyro then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Get movement direction
    local targetVelocity = getMovementDirection()
    
    -- Smooth velocity changes
    velocity = velocity:Lerp(targetVelocity, ACCELERATION * deltaTime)
    
    -- Apply velocity
    bodyVelocity.Velocity = velocity
    
    -- Update camera to follow rotation
    if bodyGyro then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * bodyGyro.CFrame.Rotation
    end
end)

-- Create visual effects
local flyEffects = {}
local function createFlyEffects(enable)
    local character = LocalPlayer.Character
    if not character then return end
    
    if enable then
        -- Create wing-like particles
        local leftWing = Instance.new("Part")
        leftWing.Name = "FlyEffectLeft"
        leftWing.Size = Vector3.new(0.5, 2, 0.1)
        leftWing.Transparency = 0.3
        leftWing.Color = Color3.fromRGB(0, 150, 255)
        leftWing.Material = Enum.Material.Neon
        leftWing.CanCollide = false
        leftWing.Anchored = false
        leftWing.Parent = character
        
        local rightWing = leftWing:Clone()
        rightWing.Name = "FlyEffectRight"
        rightWing.Parent = character
        
        -- Attach wings to torso
        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        if torso then
            local leftWeld = Instance.new("Weld")
            leftWeld.Part0 = torso
            leftWeld.Part1 = leftWing
            leftWeld.C0 = CFrame.new(-1.5, 0.5, 0)
            leftWeld.Parent = leftWing
            
            local rightWeld = Instance.new("Weld")
            rightWeld.Part0 = torso
            rightWeld.Part1 = rightWing
            rightWeld.C0 = CFrame.new(1.5, 0.5, 0)
            rightWeld.Parent = rightWing
        end
        
        -- Create trail effect
        local trail = Instance.new("Trail")
        trail.Name = "FlyTrail"
        trail.Color = ColorSequence.new(Color3.fromRGB(0, 150, 255))
        trail.Transparency = NumberSequence.new(0.5)
        trail.Lifetime = 0.5
        trail.Parent = hrp
        
        -- Store effects
        flyEffects = {leftWing, rightWing, trail}
    else
        -- Remove effects
        for _, effect in pairs(flyEffects) do
            if effect then
                effect:Destroy()
            end
        end
        flyEffects = {}
    end
end

-- Create fly sound
local flySound
local function playFlySound(play)
    if play then
        if not flySound then
            flySound = Instance.new("Sound")
            flySound.Name = "FlySound"
            flySound.SoundId = "rbxassetid://911846666"  -- Whoosh sound
            flySound.Looped = true
            flySound.Volume = 0.3
            flySound.Parent = workspace
        end
        flySound:Play()
    else
        if flySound then
            flySound:Stop()
        end
    end
end

-- Create fly GUI
local flyGUI
local function updateFlyGUI(visible)
    if not flyGUI then
        -- Create GUI
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FlyGUI"
        screenGui.ResetOnSpawn = false
        
        -- Main container
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "FlyPanel"
        mainFrame.Size = UDim2.new(0, 300, 0, 120)
        mainFrame.Position = UDim2.new(0.5, -150, 0.05, 0)
        mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        mainFrame.BackgroundTransparency = 0.3
        mainFrame.BorderSizePixel = 0
        mainFrame.Parent = screenGui
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0.2, 0)
        title.BackgroundTransparency = 1
        title.Text = "✈️ FLIGHT MODE ✈️"
        title.TextColor3 = Color3.fromRGB(100, 200, 255)
        title.Font = Enum.Font.SourceSansBold
        title.TextSize = 18
        title.Parent = mainFrame
        
        -- Status
        local status = Instance.new("TextLabel")
        status.Name = "Status"
        status.Size = UDim2.new(1, 0, 0.3, 0)
        status.Position = UDim2.new(0, 0, 0.2, 0)
        status.BackgroundTransparency = 1
        status.Text = "Status: READY"
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
        status.Font = Enum.Font.SourceSans
        status.TextSize = 16
        status.Parent = mainFrame
        
        -- Speed display
        local speedDisplay = Instance.new("TextLabel")
        speedDisplay.Name = "Speed"
        speedDisplay.Size = UDim2.new(1, 0, 0.3, 0)
        speedDisplay.Position = UDim2.new(0, 0, 0.5, 0)
        speedDisplay.BackgroundTransparency = 1
        speedDisplay.Text = "Speed: " .. FLY_SPEED .. " studs/sec"
        speedDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
        speedDisplay.Font = Enum.Font.SourceSans
        speedDisplay.TextSize = 14
        speedDisplay.Parent = mainFrame
        
        -- Controls hint
        local controls = Instance.new("TextLabel")
        controls.Name = "Controls"
        controls.Size = UDim2.new(1, 0, 0.3, 0)
        controls.Position = UDim2.new(0, 0, 0.8, 0)
        controls.BackgroundTransparency = 1
        controls.Text = "Press " .. TOGGLE_KEY.Name .. " to toggle | " .. BOOST_KEY.Name .. " to boost"
        controls.TextColor3 = Color3.fromRGB(150, 150, 150)
        controls.Font = Enum.Font.SourceSans
        controls.TextSize = 12
        controls.Parent = mainFrame
        
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        flyGUI = {screenGui = screenGui, status = status, speedDisplay = speedDisplay}
    end
    
    -- Update visibility and text
    if flyGUI then
        flyGUI.screenGui.Enabled = visible
        
        if visible then
            flyGUI.status.Text = "Status: FLYING"
            flyGUI.status.TextColor3 = Color3.fromRGB(0, 255, 0)
            
            -- Update speed display in real-time
            RunService.Heartbeat:Connect(function()
                if flying and flyGUI then
                    local isBoosting = UserInputService:IsKeyDown(BOOST_KEY)
                    local currentSpeed = isBoosting and speed * BOOST_MULTIPLIER or speed
                    flyGUI.speedDisplay.Text = "Speed: " .. math.floor(currentSpeed) .. " studs/sec"
                    flyGUI.speedDisplay.TextColor3 = isBoosting and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(200, 200, 200)
                end
            end)
        else
            flyGUI.status.Text = "Status: READY"
            flyGUI.status.TextColor3 = Color3.fromRGB(200, 200, 200)
            flyGUI.speedDisplay.Text = "Speed: " .. FLY_SPEED .. " studs/sec"
            flyGUI.speedDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Toggle flying
    if input.KeyCode == TOGGLE_KEY then
        toggleFlying()
    
    -- Toggle control scheme
    elseif input.KeyCode == ALT_CONTROL_KEY then
        toggleControlScheme()
    
    -- Speed adjustment (optional feature)
    elseif input.KeyCode == Enum.KeyCode.Equals and flying then  -- Increase speed
        speed = math.min(speed + 10, MAX_SPEED)
        print("Speed increased to: " .. speed)
    elseif input.KeyCode == Enum.KeyCode.Minus and flying then  -- Decrease speed
        speed = math.max(speed - 10, 10)
        print("Speed decreased to: " .. speed)
    end
    
    -- Handle movement keys
    if flying then
        handleMovement(Enum.UserInputState.Begin)
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Handle movement keys
    if flying then
        handleMovement(Enum.UserInputState.End)
    end
end)

-- Handle character respawns
LocalPlayer.CharacterAdded:Connect(function(character)
    if flying then
        -- Wait a bit for character to load
        wait(1)
        
        -- Recreate flying parts
        createFlyingParts()
        
        -- Reapply platform stand
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
        end
        
        -- Recreate effects
        createFlyEffects(true)
    end
end)

-- Clean up on removal
LocalPlayer.CharacterRemoving:Connect(function()
    if flying then
        stopFlying()
    end
end)

-- Initialize
print("========================================")
print("ADVANCED FLY SCRIPT LOADED")
print("========================================")
print("Controls:")
print("- " .. TOGGLE_KEY.Name .. ": Toggle fly mode")
print("- WASD: Move horizontally")
print("- Space/Shift: Move up/down")
print("- Mouse: Look around")
print("- " .. BOOST_KEY.Name .. ": Boost speed")
print("- " .. ALT_CONTROL_KEY.Name .. ": Toggle control scheme")
print("- +/-: Adjust speed (while flying)")
print("========================================")
print("Features:")
print("- Smooth camera-controlled movement")
print("- Speed boost with " .. BOOST_KEY.Name)
print("- Multiple control schemes")
print("- Visual effects")
print("- Sound effects")
print("- Speed display GUI")
print("- Auto-reapply on respawn")
print("========================================")
