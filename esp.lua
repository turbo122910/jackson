-- 🔥 PERMANENT ESP - ALWAYS ON 🔥
-- No toggle, always active

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Drawing library for ESP
local Drawing = Drawing

-- ESP Configuration
local ESP_CONFIG = {
    -- Colors
    AllyColor = Color3.fromRGB(0, 255, 0),      -- Green for teammates
    EnemyColor = Color3.fromRGB(255, 50, 50),   -- Red for enemies
    NeutralColor = Color3.fromRGB(150, 150, 150),-- Grey for no team
    
    -- Box ESP
    BoxESP = true,
    BoxThickness = 2,
    BoxTransparency = 0,
    
    -- Tracer ESP
    TracerESP = true,
    TracerThickness = 1,
    TracerFrom = "Bottom",  -- "Bottom", "Middle", "Top"
    
    -- Name ESP
    NameESP = true,
    NameSize = 14,
    NameFont = 2,  -- 0 = UI, 1 = System, 2 = Plex, 3 = Monospace
    
    -- Distance ESP
    DistanceESP = true,
    DistanceSize = 12,
    
    -- Health Bar
    HealthBar = true,
    HealthBarThickness = 1,
    HealthBarWidth = 30,
    HealthBarHeight = 3,
    
    -- Chams (Highlight)
    Chams = true,
    ChamsTransparency = 0.8,
    
    -- Max render distance
    MaxDistance = 1000,
    
    -- Team check
    TeamCheck = true
}

-- ESP Storage
local ESP = {
    Players = {},
    Highlights = {},
    Drawings = {},
    Connections = {}
}

-- =============== UTILITY FUNCTIONS ===============

function ESP:GetTeamColor(player)
    if not ESP_CONFIG.TeamCheck then return ESP_CONFIG.NeutralColor end
    
    if LocalPlayer.Team and player.Team then
        if LocalPlayer.Team == player.Team then
            return ESP_CONFIG.AllyColor
        else
            return ESP_CONFIG.EnemyColor
        end
    end
    
    return ESP_CONFIG.NeutralColor
end

function ESP:GetScreenPosition(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

function ESP:CalculateBoxPoints(character)
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    if not rootPart then return nil end
    
    local cf = rootPart.CFrame
    local size = character:GetBoundingBox()
    
    -- Calculate the 8 corners of the bounding box
    local corners = {
        cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
        cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
        cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
        cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
        cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
        cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
        cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
        cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2)
    }
    
    return corners
end

function ESP:GetHealth(player)
    local character = player.Character
    if not character then return 0, 0 end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return 0, 0 end
    
    return humanoid.Health, humanoid.MaxHealth
end

-- =============== DRAWING FUNCTIONS ===============

function ESP:CreateDrawings(player)
    local drawings = {}
    
    if ESP_CONFIG.BoxESP then
        -- Box lines (8 corners, 12 edges)
        for i = 1, 12 do
            local line = Drawing.new("Line")
            line.Thickness = ESP_CONFIG.BoxThickness
            line.Transparency = ESP_CONFIG.BoxTransparency
            line.Visible = false
            drawings["BoxLine" .. i] = line
        end
    end
    
    if ESP_CONFIG.TracerESP then
        local tracer = Drawing.new("Line")
        tracer.Thickness = ESP_CONFIG.TracerThickness
        tracer.Visible = false
        drawings["Tracer"] = tracer
    end
    
    if ESP_CONFIG.NameESP then
        local name = Drawing.new("Text")
        name.Size = ESP_CONFIG.NameSize
        name.Center = true
        name.Outline = true
        name.OutlineColor = Color3.new(0, 0, 0)
        name.Visible = false
        name.Font = ESP_CONFIG.NameFont
        drawings["Name"] = name
    end
    
    if ESP_CONFIG.DistanceESP then
        local distance = Drawing.new("Text")
        distance.Size = ESP_CONFIG.DistanceSize
        distance.Center = true
        distance.Outline = true
        distance.OutlineColor = Color3.new(0, 0, 0)
        distance.Visible = false
        distance.Font = ESP_CONFIG.NameFont
        drawings["Distance"] = distance
    end
    
    if ESP_CONFIG.HealthBar then
        -- Health bar background
        local healthBg = Drawing.new("Square")
        healthBg.Filled = true
        healthBg.Thickness = ESP_CONFIG.HealthBarThickness
        healthBg.Visible = false
        drawings["HealthBG"] = healthBg
        
        -- Health bar fill
        local healthFill = Drawing.new("Square")
        healthFill.Filled = true
        healthFill.Thickness = ESP_CONFIG.HealthBarThickness
        healthFill.Visible = false
        drawings["HealthFill"] = healthFill
    end
    
    self.Drawings[player] = drawings
    return drawings
end

function ESP:DestroyDrawings(player)
    local drawings = self.Drawings[player]
    if drawings then
        for _, drawing in pairs(drawings) do
            if drawing then
                drawing:Remove()
            end
        end
        self.Drawings[player] = nil
    end
end

function ESP:UpdateDrawings(player)
    local drawings = self.Drawings[player]
    if not drawings then return end
    
    local character = player.Character
    if not character then
        -- Hide all drawings if no character
        for _, drawing in pairs(drawings) do
            if drawing then drawing.Visible = false end
        end
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    if not rootPart then return end
    
    local rootPos = rootPart.Position
    local screenPos, onScreen = self:GetScreenPosition(rootPos)
    
    if not onScreen then
        for _, drawing in pairs(drawings) do
            if drawing then drawing.Visible = false end
        end
        return
    end
    
    local distance = (rootPos - Camera.CFrame.Position).Magnitude
    if distance > ESP_CONFIG.MaxDistance then
        for _, drawing in pairs(drawings) do
            if drawing then drawing.Visible = false end
        end
        return
    end
    
    local color = self:GetTeamColor(player)
    
    -- BOX ESP
    if ESP_CONFIG.BoxESP and drawings["BoxLine1"] then
        local corners = self:CalculateBoxPoints(character)
        if corners then
            -- Convert 3D corners to 2D screen positions
            local screenCorners = {}
            for i, corner in ipairs(corners) do
                local screenCorner = self:GetScreenPosition(corner.Position)
                screenCorners[i] = screenCorner
            end
            
            -- Define edges for the box (12 edges)
            local edges = {
                {1, 2}, {2, 3}, {3, 4}, {4, 1}, -- Front face
                {5, 6}, {6, 7}, {7, 8}, {8, 5}, -- Back face
                {1, 5}, {2, 6}, {3, 7}, {4, 8}  -- Connecting edges
            }
            
            -- Draw each edge
            for i, edge in ipairs(edges) do
                local line = drawings["BoxLine" .. i]
                if line then
                    local from = screenCorners[edge[1]]
                    local to = screenCorners[edge[2]]
                    
                    if from and to then
                        line.From = from
                        line.To = to
                        line.Color = color
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                end
            end
        end
    end
    
    -- TRACER ESP
    if ESP_CONFIG.TracerESP and drawings["Tracer"] then
        local tracer = drawings["Tracer"]
        
        -- Determine starting position based on config
        local startY
        if ESP_CONFIG.TracerFrom == "Top" then
            startY = 0
        elseif ESP_CONFIG.TracerFrom == "Middle" then
            startY = Camera.ViewportSize.Y / 2
        else -- "Bottom"
            startY = Camera.ViewportSize.Y
        end
        
        tracer.From = Vector2.new(Camera.ViewportSize.X / 2, startY)
        tracer.To = screenPos
        tracer.Color = color
        tracer.Visible = true
    end
    
    -- NAME ESP
    if ESP_CONFIG.NameESP and drawings["Name"] then
        local name = drawings["Name"]
        name.Position = Vector2.new(screenPos.X, screenPos.Y - 40)
        name.Text = player.Name
        name.Color = color
        name.Visible = true
    end
    
    -- DISTANCE ESP
    if ESP_CONFIG.DistanceESP and drawings["Distance"] then
        local distanceText = drawings["Distance"]
        distanceText.Position = Vector2.new(screenPos.X, screenPos.Y - 25)
        distanceText.Text = math.floor(distance) .. " studs"
        distanceText.Color = color
        distanceText.Visible = true
    end
    
    -- HEALTH BAR
    if ESP_CONFIG.HealthBar and drawings["HealthBG"] and drawings["HealthFill"] then
        local health, maxHealth = self:GetHealth(player)
        local healthPercent = maxHealth > 0 and health / maxHealth or 0
        
        local barWidth = ESP_CONFIG.HealthBarWidth
        local barHeight = ESP_CONFIG.HealthBarHeight
        
        -- Health bar background
        local healthBg = drawings["HealthBG"]
        healthBg.Position = Vector2.new(screenPos.X - barWidth/2, screenPos.Y + 20)
        healthBg.Size = Vector2.new(barWidth, barHeight)
        healthBg.Color = Color3.new(0, 0, 0)
        healthBg.Visible = true
        
        -- Health bar fill
        local healthFill = drawings["HealthFill"]
        local fillWidth = barWidth * healthPercent
        healthFill.Position = Vector2.new(screenPos.X - barWidth/2, screenPos.Y + 20)
        healthFill.Size = Vector2.new(fillWidth, barHeight)
        
        -- Health bar color (green to red based on health)
        local healthColor = Color3.new(
            1 - healthPercent,  -- More red when low health
            healthPercent,      -- More green when high health
            0
        )
        
        healthFill.Color = healthColor
        healthFill.Visible = true
    end
end

-- =============== HIGHLIGHT CHAMS ===============

function ESP:CreateHighlight(player)
    if not ESP_CONFIG.Chams then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight_" .. player.Name
    highlight.FillTransparency = ESP_CONFIG.ChamsTransparency
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    self.Highlights[player] = highlight
    return highlight
end

function ESP:UpdateHighlight(player)
    if not ESP_CONFIG.Chams then return end
    
    local highlight = self.Highlights[player]
    if not highlight then
        highlight = self:CreateHighlight(player)
    end
    
    local character = player.Character
    if character then
        highlight.Adornee = character
        highlight.Enabled = true
        
        local color = self:GetTeamColor(player)
        highlight.FillColor = color
        highlight.OutlineColor = color
        
        -- Parent to workspace for visibility
        if not highlight.Parent then
            highlight.Parent = Workspace
        end
    else
        highlight.Enabled = false
    end
end

function ESP:DestroyHighlight(player)
    local highlight = self.Highlights[player]
    if highlight then
        highlight:Destroy()
        self.Highlights[player] = nil
    end
end

-- =============== PLAYER MANAGEMENT ===============

function ESP:AddPlayer(player)
    if player == LocalPlayer then return end
    
    -- Create drawings for player
    self:CreateDrawings(player)
    
    -- Setup character tracking
    local function setupCharacter()
        if player.Character then
            self:UpdateDrawings(player)
            self:UpdateHighlight(player)
        end
        
        -- Character added
        local charAdded
        charAdded = player.CharacterAdded:Connect(function(character)
            wait(0.5) -- Wait for character to fully load
            self:UpdateDrawings(player)
            self:UpdateHighlight(player)
        end)
        
        -- Character removing
        local charRemoving
        charRemoving = player.CharacterRemoving:Connect(function()
            self:UpdateDrawings(player) -- This will hide drawings
            self:UpdateHighlight(player) -- This will hide highlight
        end)
        
        -- Humanoid health changes
        local humanoid
        local healthChanged
        player.CharacterAdded:Connect(function(character)
            wait(1) -- Wait for humanoid to load
            humanoid = character:WaitForChild("Humanoid")
            if humanoid then
                healthChanged = humanoid.HealthChanged:Connect(function()
                    self:UpdateDrawings(player)
                end)
            end
        end)
        
        -- Store connections
        self.Connections[player] = {
            CharAdded = charAdded,
            CharRemoving = charRemoving,
            HealthChanged = healthChanged
        }
    end
    
    -- Team changed
    local teamChanged
    teamChanged = player:GetPropertyChangedSignal("Team"):Connect(function()
        self:UpdateDrawings(player)
        self:UpdateHighlight(player)
    end)
    
    table.insert(self.Connections[player] or {}, teamChanged)
    
    -- Initial setup
    setupCharacter()
    
    -- Store player
    table.insert(self.Players, player)
end

function ESP:RemovePlayer(player)
    -- Destroy drawings
    self:DestroyDrawings(player)
    
    -- Destroy highlight
    self:DestroyHighlight(player)
    
    -- Disconnect connections
    local connections = self.Connections[player]
    if connections then
        for _, connection in pairs(connections) do
            if connection then
                connection:Disconnect()
            end
        end
        self.Connections[player] = nil
    end
    
    -- Remove from players list
    for i, p in ipairs(self.Players) do
        if p == player then
            table.remove(self.Players, i)
            break
        end
    end
end

-- =============== MAIN LOOP ===============

function ESP:UpdateAll()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not self.Drawings[player] then
                self:AddPlayer(player)
            end
            self:UpdateDrawings(player)
            self:UpdateHighlight(player)
        end
    end
end

function ESP:Initialize()
    print("🔥 PERMANENT ESP INITIALIZED - ALWAYS ON 🔥")
    print("No toggle - ESP is always active")
    
    -- Setup existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:AddPlayer(player)
        end
    end
    
    -- Player added
    Players.PlayerAdded:Connect(function(player)
        wait(1) -- Wait for player to fully join
        if player ~= LocalPlayer then
            self:AddPlayer(player)
        end
    end)
    
    -- Player removing
    Players.PlayerRemoving:Connect(function(player)
        self:RemovePlayer(player)
    end)
    
    -- Local player team changes
    LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        self:UpdateAll()
    end)
    
    -- Update loop
    RunService.RenderStepped:Connect(function()
        self:UpdateAll()
    end)
    
    -- Camera changes
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Camera = Workspace.CurrentCamera
    end)
end

-- =============== STARTUP ===============

-- Wait for game to load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Wait for player
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

-- Initialize ESP
ESP:Initialize()

-- Status message
local function createStatusMessage()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESP_Status"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local frame = Instance.new("Frame")
    frame.Name = "StatusFrame"
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(0.02, 0, 0.02, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0.5, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔥 PERMANENT ESP - ALWAYS ON"
    title.TextColor3 = Color3.fromRGB(255, 100, 100)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.Parent = frame
    
    local info = Instance.new("TextLabel")
    info.Name = "Info"
    info.Size = UDim2.new(1, 0, 0.5, 0)
    info.Position = UDim2.new(0, 0, 0.5, 0)
    info.BackgroundTransparency = 1
    info.Text = "Box | Tracer | Name | Distance | Health | Chams"
    info.TextColor3 = Color3.fromRGB(200, 200, 200)
    info.Font = Enum.Font.SourceSans
    info.TextSize = 12
    info.Parent = frame
    
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Auto-remove after 10 seconds
    delay(10, function()
        screenGui:Destroy()
    end)
end

createStatusMessage()

print("========================================")
print("🔥 PERMANENT ESP SYSTEM ACTIVE 🔥")
print("========================================")
print("Features always enabled:")
print("- Box ESP with team colors")
print("- Tracer lines to players")
print("- Player names")
print("- Distance display")
print("- Health bars")
print("- Chams (Highlights)")
print("========================================")
print("Team Colors:")
print("- Green: Teammates")
print("- Red: Enemies")
print("- Grey: No team")
print("========================================")
