local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

Lighting.Brightness = 1
Lighting.Ambient = Color3.fromRGB(128, 128, 128)
Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
Lighting.FogEnd = 1000

local function rejoin()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

CoreGui.ChildAdded:Connect(function(child)
    if child:IsA("ScreenGui") and child.Name == "ErrorPrompt" then
        task.wait(2)
        rejoin()
    end
end)

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "ZeckHub",
    LoadingTitle = "Loading RiqHub...",
    LoadingSubtitle = "by Riq",
    ConfigurationSaving = {
        Enabled = false,
        FileName = "riqhub_config"
    },
    KeySystem = false,
    KeySettings = {
        Title = "Access Required",
        Subtitle = "Enter the key to continue",
        Note = "Join Discord for key",
        FileName = "zeckhub_key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = "robertzeck08"
    },
    ToggleUIKeybind = Enum.KeyCode.K
})

local HitboxTab = Window:CreateTab("Ball", "flame")
local hitboxScale = 5.0

local function findFirstPart(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            return descendant
        end
    end
end

local function updateHitboxes(scale)
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
            local ball = model:FindFirstChild("Ball.001")
            if not ball then
                local basePart = findFirstPart(model)
                if basePart then
                    ball = Instance.new("Part")
                    ball.Name = "Ball.001"
                    ball.Shape = Enum.PartType.Ball
                    ball.Size = Vector3.new(2, 2, 2) * scale
                    ball.CFrame = basePart.CFrame
                    ball.Anchored = true
                    ball.CanCollide = false
                    ball.Transparency = 0.7
                    ball.Material = Enum.Material.ForceField
                    ball.Color = Color3.fromRGB(0, 255, 0)
                    ball.Parent = model
                end
            else
                ball.Size = Vector3.new(2, 2, 2) * scale
            end
        end
    end
end

local function removeHitboxes()
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
            local ball = model:FindFirstChild("Ball.001")
            if ball then
                ball:Destroy()
            end
        end
    end
end

Workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child.Name:match("^CLIENT_BALL_%d+$") then
        task.wait(0.1)
        updateHitboxes(hitboxScale)
    end
end)

HitboxTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {0, 20},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = hitboxScale,
    Callback = function(value)
        hitboxScale = value
        updateHitboxes(value)
        Rayfield:Notify({
            Title = "Size Changed",
            Content = "Hitbox scale set to " .. value .. "x",
            Duration = 2,
            Image = "maximize"
        })
    end
})

HitboxTab:CreateButton({
    Name = "Remove Hitboxes",
    Callback = function()
        removeHitboxes()
        Rayfield:Notify({
            Title = "Hitboxes Removed",
            Content = "All hitboxes cleared",
            Duration = 2,
            Image = "power-off"
        })
    end
})

local CharacterTab = Window:CreateTab("Character", "user-round")
local autoShiftLock = true
local airMovement = false
local airMovementSpeed = 16
local bodyVelocity = nil

local function getWalkSpeed()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.WalkSpeed or 16
end

local function applyAirControl(rootPart)
    if bodyVelocity then return end
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.P = 2500
    bodyVelocity.Name = "AirControlVelocity"
    bodyVelocity.Parent = rootPart
end

local function removeAirControl()
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
end

local function setupCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    airMovementSpeed = getWalkSpeed()

    humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
        if humanoid.Jump then
            if autoShiftLock then
                task.defer(function()
                    task.wait(0.03)
                    local lookVector = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
                    if lookVector.Magnitude > 0 then
                        rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + lookVector.Unit)
                        humanoid.AutoRotate = false
                    end
                end)
            else
                humanoid.AutoRotate = true
            end
        end
    end)

    humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Freefall then
            if airMovement then
                applyAirControl(rootPart)
            end
        elseif newState == Enum.HumanoidStateType.Landed then
            removeAirControl()
            humanoid.AutoRotate = true
        end
    end)
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

CharacterTab:CreateToggle({
    Name = "Auto Shift Lock",
    CurrentValue = true,
    Callback = function(value)
        autoShiftLock = value
    end
})

CharacterTab:CreateToggle({
    Name = "Air Movement (Freeflight)",
    CurrentValue = false,
    Callback = function(value)
        airMovement = value
        if not value then
            removeAirControl()
        end
    end
})

CharacterTab:CreateSlider({
    Name = "Air Movement Speed",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = getWalkSpeed(),
    Suffix = " studs/s",
    Callback = function(value)
        airMovementSpeed = value
    end
})

RunService.RenderStepped:Connect(function()
    if airMovement and bodyVelocity and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            bodyVelocity.Velocity = humanoid.MoveDirection * airMovementSpeed
        end
    end
end)

local LinesTab = Window:CreateTab("Lines", "eye")
local lineDistance = 50
local lines = {}
local linesEnabled = true
local lineColors = {
    Color3.fromRGB(255, 0, 0),
    Color3.fromRGB(0, 255, 0),
    Color3.fromRGB(0, 0, 255),
    Color3.fromRGB(255, 165, 0),
    Color3.fromRGB(128, 0, 128),
    Color3.fromRGB(255, 255, 0),
    Color3.fromRGB(139, 0, 0),
    Color3.fromRGB(0, 100, 0)
}

local function removeLine(player)
    local data = lines[player]
    if data then
        if data.beam then data.beam:Destroy() end
        if data.target and data.target.Parent then data.target:Destroy() end
        if data.attachment and data.attachment.Parent then data.attachment:Destroy() end
        lines[player] = nil
    end
end

local function updateLine(player, index)
    if not linesEnabled then
        removeLine(player)
        return
    end

    local character = player.Character
    if not character or not character:FindFirstChild("Head") or not character:FindFirstChild("HumanoidRootPart") then
        removeLine(player)
        return
    end

    local head = character.Head
    local rootPart = character.HumanoidRootPart

    if not lines[player] then
        local attachment = Instance.new("Attachment", head)
        local target = Instance.new("Part")
        target.Anchored = true
        target.CanCollide = false
        target.Transparency = 1
        target.Size = Vector3.new(0.1, 0.1, 0.1)
        target.Parent = Workspace

        local targetAttachment = Instance.new("Attachment", target)
        local beam = Instance.new("Beam")
        beam.Attachment0 = attachment
        beam.Attachment1 = targetAttachment
        beam.Width0 = 0.25
        beam.Width1 = 0.25
        beam.FaceCamera = true
        beam.LightEmission = 1
        beam.Transparency = NumberSequence.new(0.3)
        beam.Color = ColorSequence.new(lineColors[(index - 1) % #lineColors + 1])
        beam.Parent = head

        lines[player] = { beam = beam, target = target, attachment = attachment }
    end

    local data = lines[player]
    data.target.Position = head.Position + rootPart.CFrame.LookVector * lineDistance
end

RunService.RenderStepped:Connect(function()
    if linesEnabled then
        for index, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
                updateLine(player, index)
            else
                removeLine(player)
            end
        end
    else
        for player in pairs(lines) do
            removeLine(player)
        end
    end
end)

Players.PlayerRemoving:Connect(removeLine)

LinesTab:CreateToggle({
    Name = "Enable Lines",
    CurrentValue = true,
    Callback = function(value)
        linesEnabled = value
        if not value then
            for player in pairs(lines) do
                removeLine(player)
            end
        end
    end
})

LinesTab:CreateSlider({
    Name = "Line Distance",
    Range = {0, 100},
    Increment = 10,
    CurrentValue = lineDistance,
    Suffix = " studs",
    Callback = function(value)
        lineDistance = value
    end
})

LinesTab:CreateParagraph({
    Title = "Note",
    Content = "If the lines do not appear, just turn the toggle off and on."
})

local VisualTab = Window:CreateTab("Visual", "moon")
local defaultAmbient = Lighting.Ambient
local defaultBrightness = Lighting.Brightness
local defaultOutdoorAmbient = Lighting.OutdoorAmbient
local defaultFogEnd = Lighting.FogEnd
local nightMode = false
local fullbright = false
local ambientToggle = false
local ambientColor = Color3.fromRGB(100, 100, 255)

local espEnabled = true
local espHighlights = {}
local espConnections = {}

local function isEnemy(player)
    return player ~= LocalPlayer and player.Team and LocalPlayer.Team and player.Team ~= LocalPlayer.Team
end

local function applyESP(player)
    if not player.Character or espHighlights[player] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "JumpESP"
    highlight.Adornee = player.Character
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = player.Character
    espHighlights[player] = highlight
end

local function removeESP(player)
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
end

local function cleanupConnections(player)
    if espConnections[player] then
        for _, connection in pairs(espConnections[player]) do
            pcall(function() connection:Disconnect() end)
        end
        espConnections[player] = nil
    end
    removeESP(player)
end

local function setupESP(player)
    if player == LocalPlayer then return end
    local function onCharacterAdded(character)
        cleanupConnections(player)
        local humanoid = character:WaitForChild("Humanoid", 3)
        local head = character:FindFirstChild("Head")
        if not humanoid or not head then return end

        local stateConnection = humanoid.StateChanged:Connect(function(_, newState)
            if not espEnabled then return end
            if isEnemy(player) then
                if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
                    applyESP(player)
                elseif newState == Enum.HumanoidStateType.Landed then
                    removeESP(player)
                end
            else
                removeESP(player)
            end
        end)

        local heartbeatConnection = RunService.Heartbeat:Connect(function()
            if not player.Character or not isEnemy(player) then
                removeESP(player)
            else
                local state = humanoid:GetState()
                if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
                    removeESP(player)
                end
            end
        end)

        espConnections[player] = { stateConnection, heartbeatConnection }
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupESP(player)
end
Players.PlayerAdded:Connect(setupESP)

VisualTab:CreateToggle({
    Name = "ESP (Jump)",
    CurrentValue = true,
    Callback = function(value)
        espEnabled = value
        if not value then
            for player in pairs(espHighlights) do
                removeESP(player)
            end
        end
    end
})

local function toggleNightMode(enabled)
    nightMode = enabled
    if enabled then
        Lighting.Ambient = Color3.fromRGB(20, 20, 20)
        Lighting.Brightness = 1
    else
        Lighting.Ambient = defaultAmbient
        Lighting.Brightness = defaultBrightness
    end
end

local function toggleFullbright(enabled)
    fullbright = enabled
    if enabled then
        Lighting.Brightness = 3
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        Lighting.Brightness = defaultBrightness
        Lighting.Ambient = defaultAmbient
        Lighting.OutdoorAmbient = defaultOutdoorAmbient
    end
end

local bloomEffect = Instance.new("BloomEffect", Lighting)
bloomEffect.Intensity = 0
bloomEffect.Size = 56
bloomEffect.Threshold = 1

VisualTab:CreateToggle({
    Name = "Night Mode",
    CurrentValue = false,
    Callback = function(value)
        toggleNightMode(value)
        Rayfield:Notify({
            Title = value and "Night Mode on" or "Night Mode off",
            Content = value and "Ambient applied." or "Ambient reset.",
            Duration = 3,
            Image = value and "moon" or "sun"
        })
    end
})

VisualTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(value)
        toggleFullbright(value)
        Rayfield:Notify({
            Title = "Fullbright",
            Content = value and "Fullbright on." or "Fullbright off.",
            Duration = 2,
            Image = value and "flashlight" or "x"
        })
    end
})

VisualTab:CreateSlider({
    Name = "Fog End Distance",
    Range = {0, 1000},
    Increment = 50,
    CurrentValue = Lighting.FogEnd,
    Suffix = " studs",
    Callback = function(value)
        Lighting.FogEnd = value
    end
})

VisualTab:CreateColorPicker({
    Name = "Ambient Color",
    Color = Lighting.Ambient,
    Callback = function(color)
        Lighting.Ambient = color
    end
})

VisualTab:CreateToggle({
    Name = "Ambient Color Toggle",
    CurrentValue = false,
    Callback = function(value)
        ambientToggle = value
        if value then
            Lighting.Ambient = ambientColor
        else
            Lighting.Ambient = defaultAmbient
        end
    end
})

VisualTab:CreateSlider({
    Name = "Bloom Intensity",
    Range = {0, 5},
    Increment = 0.1,
    CurrentValue = bloomEffect.Intensity,
    Suffix = "",
    Callback = function(value)
        bloomEffect.Intensity = value
    end
})

local defaultSettings = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    Effects = {}
}

for _, effect in pairs(Lighting:GetChildren()) do
    if effect:IsA("PostEffect") then
        defaultSettings.Effects[#defaultSettings.Effects + 1] = effect:Clone()
    end
end

VisualTab:CreateButton({
    Name = "🔄 Reset All",
    Callback = function()
        Lighting.Brightness = defaultSettings.Brightness
        Lighting.Ambient = defaultSettings.Ambient
        Lighting.OutdoorAmbient = defaultSettings.OutdoorAmbient
        Lighting.FogEnd = defaultSettings.FogEnd
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect:Destroy()
            end
        end
        for _, effect in pairs(defaultSettings.Effects) do
            local clonedEffect = effect:Clone()
            clonedEffect.Parent = Lighting
        end
        Rayfield:Notify({
            Title = "Ambient Reset",
            Content = "Ambient settings reset.",
            Duration = 3,
            Image = "refresh-cw"
        })
    end
})

local OthersTab = Window:CreateTab("Others", "alert-triangle")

OthersTab:CreateButton({
    Name = "Rejoin",
    Callback = rejoin
})

OthersTab:CreateButton({
    Name = "Turn Off All",
    Callback = function()
        removeHitboxes()
        autoShiftLock = false
        airMovement = false
        linesEnabled = false
        for player in pairs(lines) do
            removeLine(player)
        end
        Rayfield:Notify({
            Title = "Panic Mode",
            Content = "All features disabled.",
            Duration = 3,
            Image = "skull"
        })
    end
})
