local __sharedState = getgenv().L_1_ or {}
getgenv().L_1_ = __sharedState

local __EventsAndPVPModule = {}

__sharedState[130] = {
    "Guardian",
    "PirateGrandBrigade",
    "MarineGrandBrigade",
    "PirateBrigade",
    "MarineBrigade",
    "PirateSloop",
    "MarineSloop",
    "Beast Hunter"
}

__sharedState[89] = {
    "Lv 1",
    "Lv 2",
    "Lv 3",
    "Lv 4",
    "Lv 5",
    "Lv 6",
    "Lv Infinite"
}

__sharedState[39] = {}

local __playersService = game:GetService("Players")
local __runService = game:GetService("RunService")
local __userInputService = game:GetService("UserInputService")
local __replicatedStorage = game:GetService("ReplicatedStorage")
local __collectionService = game:GetService("CollectionService")
local __tweenService = game:GetService("TweenService")
local __lighting = game:GetService("Lighting")
local __virtualInputManager = game:GetService("VirtualInputManager")
local __virtualUser = game:GetService("VirtualUser")
local __localPlayer = __playersService.LocalPlayer
local __camera = workspace.CurrentCamera

local __flyEnabled = false
local __flySpeed = 50
local __flyDirections = {f = 0, b = 0, l = 0, r = 0}
local __flyBodyGyro = nil
local __flyBodyVelocity = nil
local __flyHeartbeat = nil

local __updatePlayerList = function()
    table.clear(__sharedState[39])
    for __, __player in ipairs(__playersService:GetPlayers()) do
        table.insert(__sharedState[39], __player.Name)
    end
end

local __getSeaBeastTrial = function()
    if not workspace.Map:FindFirstChild("FishmanTrial") then return nil end
    local __trialLocation = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations") and workspace._WorldOrigin.Locations:FindFirstChild("Trial of Water")
    if __trialLocation then
        for __, __beast in next, workspace.SeaBeasts:GetChildren() do
            if __beast:FindFirstChild("HumanoidRootPart") and (__beast.HumanoidRootPart.Position - __trialLocation.Position).Magnitude <= 1500 then
                if __beast:FindFirstChild("Health") and __beast.Health.Value > 0 then
                    return __beast
                end
            end
        end
    end
    return nil
end

local __chestEspHandler = function()
    if getgenv().ChestESP then
        for __, __chest in ipairs(__collectionService:GetTagged("_ChestTagged")) do
            pcall(function()
                local __pos = __chest:GetPivot().Position
                local __dist = (__pos - __localPlayer.Character.Head.Position).Magnitude
                local __att = __chest:FindFirstChild("ChestEspAttachment")
                if not __att then
                    __att = Instance.new("Attachment", __chest)
                    __att.Name = "ChestEspAttachment"
                    __att.Position = Vector3.new(0, 3, 0)
                    local __gui = Instance.new("BillboardGui", __att)
                    __gui.Name = "NameEsp"
                    __gui.Size = UDim2.new(0, 200, 0, 30)
                    __gui.Adornee = __att
                    __gui.AlwaysOnTop = true
                    local __label = Instance.new("TextLabel", __gui)
                    __label.Font = Enum.Font.Code
                    __label.TextSize = 14
                    __label.Size = UDim2.new(1, 0, 1, 0)
                    __label.BackgroundTransparency = 1
                    __label.TextColor3 = Color3.fromRGB(80, 245, 245)
                end
                __att.NameEsp.TextLabel.Text = string.format("[%s] %d M", __chest.Name:gsub("Label", ""), math.floor(__dist / 3))
            end)
        end
    else
        for __, __chest in ipairs(__collectionService:GetTagged("_ChestTagged")) do
            local __att = __chest:FindFirstChild("ChestEspAttachment")
            if __att then __att:Destroy() end
        end
    end
end

local __berryEspHandler = function()
    if getgenv().BerryEsp then
        for __, __bush in ipairs(__collectionService:GetTagged("BerryBush")) do
            pcall(function()
                local __pos = __bush.Parent:GetPivot().Position
                for __attr, __val in pairs(__bush:GetAttributes()) do
                    if __val then
                        local __id = "BerryEspPart_" .. tostring(__val) .. "_" .. tostring(__pos)
                        local __part = workspace:FindFirstChild(__id) or Instance.new("Part", workspace)
                        if __part.Name ~= __id then
                            __part.Name = __id
                            __part.Transparency = 1
                            __part.Size = Vector3.new(1, 1, 1)
                            __part.Anchored = true
                            __part.CanCollide = false
                            __part.CFrame = CFrame.new(__pos)
                        end
                        if not __part:FindFirstChild("NameEsp") then
                            local __gui = Instance.new("BillboardGui", __part)
                            __gui.Name = "NameEsp"
                            __gui.Size = UDim2.new(0, 200, 0, 30)
                            __gui.AlwaysOnTop = true
                            local __label = Instance.new("TextLabel", __gui)
                            __label.Font = Enum.Font.Code
                            __label.TextSize = 14
                            __label.Size = UDim2.new(1, 0, 1, 0)
                            __label.BackgroundTransparency = 1
                            __label.TextColor3 = Color3.fromRGB(80, 245, 245)
                        end
                        local __dist = (__localPlayer.Character.Head.Position - __pos).Magnitude / 3
                        __part.NameEsp.TextLabel.Text = "[" .. tostring(__val) .. "] " .. math.round(__dist) .. " M"
                    end
                end
            end)
        end
    else
        for __, __obj in ipairs(workspace:GetChildren()) do
            if __obj.Name:match("BerryEspPart_.*") then __obj:Destroy() end
        end
    end
end

local __flyLogic = function()
    local __char = __localPlayer.Character
    if not __char then return end
    local __hum = __char:FindFirstChildOfClass("Humanoid")
    if not __hum then return end
    local __move = __hum.MoveDirection
    __flyDirections.f = 0; __flyDirections.b = 0; __flyDirections.l = 0; __flyDirections.r = 0
    if __move.Z < -0.1 then __flyDirections.f = 1 elseif __move.Z > 0.1 then __flyDirections.b = -1 end
    if __move.X < -0.1 then __flyDirections.l = -1 elseif __move.X > 0.1 then __flyDirections.r = 1 end
end

local __toggleFly = function(__state)
    __flyEnabled = __state
    if __flyEnabled then
        local __char = __localPlayer.Character
        local __root = __char and (__char:FindFirstChild("Torso") or __char:FindFirstChild("UpperTorso"))
        if not __root then return end
        for __, __p in ipairs(__char:GetDescendants()) do if __p:IsA("BasePart") then __p.CanCollide = false; __p.Massless = true end end
        __flyBodyGyro = Instance.new("BodyGyro", __root)
        __flyBodyGyro.P = 90000; __flyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9); __flyBodyGyro.cframe = __root.CFrame
        __flyBodyVelocity = Instance.new("BodyVelocity", __root)
        __flyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
        __char.Humanoid.PlatformStand = true
        __flyHeartbeat = __runService.Heartbeat:Connect(function()
            if not __flyEnabled then return end
            __flyLogic()
            if (__flyDirections.l + __flyDirections.r) ~= 0 or (__flyDirections.f + __flyDirections.b) ~= 0 then
                __flyBodyVelocity.velocity = (__camera.CFrame.LookVector * (__flyDirections.f + __flyDirections.b) + (__camera.CFrame * CFrame.new(__flyDirections.l + __flyDirections.r, (__flyDirections.f + __flyDirections.b) * 0.2, 0).Position - __camera.CFrame.Position)) * __flySpeed
            else
                __flyBodyVelocity.velocity = Vector3.new(0, 0, 0)
            end
            __flyBodyGyro.cframe = __camera.CFrame
        end)
    else
        if __flyHeartbeat then __flyHeartbeat:Disconnect() end
        if __localPlayer.Character then
            __localPlayer.Character.Humanoid.PlatformStand = false
            for __, __p in ipairs(__localPlayer.Character:GetDescendants()) do if __p:IsA("BasePart") then __p.CanCollide = true; __p.Massless = false end end
        end
        if __flyBodyGyro then __flyBodyGyro:Destroy() end
        if __flyBodyVelocity then __flyBodyVelocity:Destroy() end
    end
end

local __removeDodgeCooldown = function()
    local __script = __localPlayer.Character:FindFirstChild("Dodge")
    if not __script then return end
    for __, __v in next, getgc() do
        if typeof(__v) == "function" and getfenv(__v).script == __script then
            for __i, __up in next, getupvalues(__v) do
                if tostring(__up) == "0.4" then setupvalue(__v, __i, 0) end
            end
        end
    end
end

local __isAlive = function(__target)
    local __h = __target and __target:FindFirstChild("Humanoid")
    return __h and __h.Health > 0
end

local __getTargetsInRange = function(__origin, __range)
    local __list = {}
    local __pos = __origin:GetPivot().Position
    for __, __e in ipairs(workspace.Enemies:GetChildren()) do
        if __e:FindFirstChild("HumanoidRootPart") and __isAlive(__e) then
            if (__e.HumanoidRootPart.Position - __pos).Magnitude <= __range then table.insert(__list, __e) end
        end
    end
    for __, __p in ipairs(__playersService:GetPlayers()) do
        if __p ~= __localPlayer and __p.Character and __p.Character:FindFirstChild("HumanoidRootPart") and __isAlive(__p.Character) then
            if (__p.Character.HumanoidRootPart.Position - __pos).Magnitude <= __range then table.insert(__list, __p.Character) end
        end
    end
    return __list
end

local __attackNoCooldown = function()
    if not _G.FastAttack and not _G.ares then return end
    local __char = __localPlayer.Character
    if not __char then return end
    local __tool = __char:FindFirstChildOfClass("Tool")
    if not __tool then return end
    local __targets = __getTargetsInRange(__char, 60)
    if #__targets == 0 then return end
    local __net = __replicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
    local __hitData = {}
    local __primaryPart = nil
    for __, __t in ipairs(__targets) do
        if not __t:GetAttribute("IsBoat") then
            local __parts = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"}
            local __p = __t:FindFirstChild(__parts[math.random(#__parts)]) or __t.PrimaryPart
            if __p then table.insert(__hitData, {__t, __p}); __primaryPart = __p end
        end
    end
    if not __primaryPart then return end
    __net["RE/RegisterAttack"]:FireServer(0)
    local __sendHits = nil
    pcall(function() __sendHits = getsenv(__localPlayer.PlayerScripts:FindFirstChildOfClass("LocalScript"))._G.SendHitsToServer end)
    if __sendHits and require(__replicatedStorage.Modules.Flags).COMBAT_REMOTE_THREAD then
        __sendHits(__primaryPart, __hitData)
    else
        __net["RE/RegisterHit"]:FireServer(__primaryPart, __hitData)
    end
end

local __getMonster = function()
    for __, __e in pairs(workspace.Enemies:GetChildren()) do
        local __p = __e:FindFirstChild("UpperTorso") or __e:FindFirstChild("Head")
        if __e:FindFirstChild("HumanoidRootPart", true) and __p then
            if (__e.Head.Position - __localPlayer.Character.HumanoidRootPart.Position).Magnitude <= 50 then return true, __p.Position end
        end
    end
    for __, __b in pairs(workspace.SeaBeasts:GetChildren()) do
        if __b:FindFirstChild("HumanoidRootPart") and __b:FindFirstChild("Health") and __b.Health.Value > 0 then return true, __b.HumanoidRootPart.Position end
    end
    for __, __e in pairs(workspace.Enemies:GetChildren()) do
        if __e:FindFirstChild("Health") and __e.Health.Value > 0 and __e:FindFirstChild("VehicleSeat") then return true, __e.Engine.Position end
    end
    return false, nil
end

local __triggerTool = function()
    local __t = __localPlayer.Character:FindFirstChildOfClass("Tool")
    if not __t then return end
    for __, __c in next, getconnections(__t.Activated) do
        if typeof(__c.Function) == "function" then getupvalues(__c.Function) end
    end
end

function __EventsAndPVPModule.startLoops()
    require(__replicatedStorage.Util.CameraShaker):Stop()
    __updatePlayerList()

    task.spawn(function() while task.wait() do if _G.FastAttack or _G.ares then pcall(__attackNoCooldown) end end end)

    task.spawn(function()
        while task.wait(1) do
            if _G.Auto_SuperHuman then
                pcall(function()
                    local __beli = __localPlayer.Data.Beli.Value
                    local __frag = __localPlayer.Data.Fragments.Value
                    if not GetBP("Superhuman") then
                        if not GetBP("Black Leg") and __beli >= 150000 then __sharedState[18].Remotes.CommF_:InvokeServer("BuyBlackLeg") end
                        if not GetBP("Electro") and __beli >= 500000 then __sharedState[18].Remotes.CommF_:InvokeServer("BuyElectro") end
                        if not GetBP("Fishman Karate") and __beli >= 750000 then __sharedState[18].Remotes.CommF_:InvokeServer("BuyFishmanKarate") end
                        if not GetBP("Dragon Claw") and __frag >= 1500 then __sharedState[18].Remotes.CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2") end
                        __sharedState[18].Remotes.CommF_:InvokeServer("BuySuperhuman")
                    end
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            if _G.AutoDeathStep then
                pcall(function()
                    if not GetBP("Death Step") then
                        if GetBP("Black Leg") and GetBP("Black Leg").Level.Value >= 400 then
                            if workspace.Map.IceCastle.Hall.LibraryDoor.PhoeyuDoor.Transparency == 0 then
                                if GetBP("Library Key") then
                                    _tp(CFrame.new(6371, 296, -6841))
                                    __sharedState[18].Remotes.CommF_:InvokeServer("BuyDeathStep")
                                else
                                    local __adm = GetConnectionEnemies("Awakened Ice Admiral")
                                    if __adm then __sharedState[4].Kill(__adm, true) else _tp(CFrame.new(5668, 28, -6483)) end
                                end
                            else __sharedState[18].Remotes.CommF_:InvokeServer("BuyDeathStep") end
                        end
                    end
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            if _G.Auto_SharkMan_Karate then
                pcall(function()
                    if not GetBP("Sharkman Karate") then
                        if GetBP("Fishman Karate") and GetBP("Fishman Karate").Level.Value >= 400 then
                            if GetBP("Water Key") then
                                _tp(CFrame.new(-2604, 239, -10315))
                                __sharedState[18].Remotes.CommF_:InvokeServer("BuySharkmanKarate")
                            else
                                local __tk = GetConnectionEnemies("Tide Keeper")
                                if __tk then __sharedState[4].Kill(__tk, true) else _tp(CFrame.new(-3053, 237, -10145)) end
                            end
                        end
                    end
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            if _G.Auto_God_Human then
                pcall(function()
                    local __res = __sharedState[18].Remotes.CommF_:InvokeServer("BuyGodhuman", true)
                    if type(__res) == "string" and __res:find("Bring me 20 Fish Tai") then
                        if not GetM("Dragon Scale") or GetM("Dragon Scale") < 10 then Lv = 1575; _G.Level = true
                        elseif not GetM("Fish Tail") or GetM("Fish Tail") < 20 then Lv = 1775; _G.Level = true
                        elseif not GetM("Mystic Droplet") or GetM("Mystic Droplet") < 10 then Lv = 1425; _G.Level = true
                        elseif not GetM("Magma Ore") or GetM("Magma Ore") < 20 then Lv = 1175; _G.Level = true end
                    else __sharedState[18].Remotes.CommF_:InvokeServer("BuyGodhuman") end
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            if _G.Auto_Fish then
                pcall(function()
                    local __alc = __sharedState[18].Remotes.CommF_:InvokeServer("Alchemist", "1")
                    if __alc == 1 then
                        if not __localPlayer.Backpack:FindFirstChild("Flower 1") then _tp(workspace.Flower1.CFrame)
                        elseif not __localPlayer.Backpack:FindFirstChild("Flower 2") then _tp(workspace.Flower2.CFrame)
                        elseif not __localPlayer.Backpack:FindFirstChild("Flower 3") then
                            local __sp = GetConnectionEnemies("Swan Pirate")
                            if __sp then __sharedState[4].Kill(__sp, true) else _tp(CFrame.new(980, 121, 1287)) end
                        end
                    elseif __alc == 0 then __sharedState[18].Remotes.CommF_:InvokeServer("Alchemist", "2")
                    elseif __alc == 2 then __sharedState[18].Remotes.CommF_:InvokeServer("Alchemist", "3") end
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if _G.FindMirage then
                if not workspace["_WorldOrigin"].Locations:FindFirstChild("Mirage Island", true) then
                    local __b = CheckBoat()
                    if not __b then _tp(CFrame.new(-16927, 9, 433)); __sharedState[18].Remotes.CommF_:InvokeServer("BuyBoat", _G.SelectedBoat)
                    elseif not __localPlayer.Character.Humanoid.Sit then _tp(__b.VehicleSeat.CFrame * CFrame.new(0, 1, 0))
                    else _tp(CFrame.new(-10000000, 31, 37016.25)) end
                else _tp(workspace.Map.MysticIsland.Center.CFrame * CFrame.new(0, 300, 0)) end
            end
        end
    end)

    task.spawn(function()
        while task.wait() do
            if _G.SailBoats then
                pcall(function()
                    local __b = CheckBoat()
                    if __b and __localPlayer.Character.Humanoid.Sit then
                        local __cf = nil
                        if _G.DangerSc == "Lv 1" then __cf = CFrame.new(-21998, 30, -682)
                        elseif _G.DangerSc == "Lv 2" then __cf = CFrame.new(-26779, 30, -822)
                        elseif _G.DangerSc == "Lv 3" then __cf = CFrame.new(-31171, 30, -2256)
                        elseif _G.DangerSc == "Lv 4" then __cf = CFrame.new(-34054, 30, -2560)
                        elseif _G.DangerSc == "Lv 5" then __cf = CFrame.new(-38887, 30, -2162)
                        elseif _G.DangerSc == "Lv 6" then __cf = CFrame.new(-44541, 30, -1244)
                        elseif _G.DangerSc == "Lv Infinite" then __cf = CFrame.new(-10000000, 31, 37016) end
                        if __cf then _tp(__cf) end
                    end
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait() do
            if _G.AimCam then
                pcall(function()
                    local __m = math.huge; local __t = nil
                    for __, __p in pairs(__playersService:GetPlayers()) do
                        if __p ~= __localPlayer and __p.Character and __isAlive(__p.Character) then
                            local __d = (__p.Character.Head.Position - __localPlayer.Character.Head.Position).Magnitude
                            if __d < __m then __m = __d; __t = __p end
                        end
                    end
                    if __t then __camera.CFrame = CFrame.new(__camera.CFrame.Position, __t.Character.HumanoidRootPart.Position) end
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait() do
            if _G.WalkWater and __localPlayer.Character:FindFirstChild("LeftFoot") then
                pcall(function()
                    local __p = Instance.new("Part", workspace)
                    __p.Transparency = 0.5; __p.Anchored = true; __p.CanCollide = false; __p.Color = Color3.fromRGB(128, 187, 219)
                    __p.Size = Vector3.new(12, 1, 12); __p.CFrame = CFrame.new(__localPlayer.Character.HumanoidRootPart.Position.X, -3.8, __localPlayer.Character.HumanoidRootPart.Position.Z)
                    __tweenService:Create(__p, TweenInfo.new(2), {Size = Vector3.new(0, 0, 0)}):Play()
                    task.delay(2, function() __p:Destroy() end)
                end)
            end
        end
    end)

    __runService.Heartbeat:Connect(function()
        if _G.Seriality then
            __attackNoCooldown()
            local __t = __localPlayer.Character:FindFirstChildOfClass("Tool")
            if __t and __t.ToolTip == "Blox Fruit" then
                local __m, __pos = __getMonster()
                if __m then
                    local __r = __t:FindFirstChild("LeftClickRemote")
                    if __r then __triggerTool(); __r:FireServer(Vector3.new(0, -500, 0), 1, true); __r:FireServer(false) end
                end
            end
        end
    end)

    __runService.RenderStepped:Connect(function()
        if getgenv().SpeedBoat and __localPlayer.Character and __localPlayer.Character.Humanoid.Sit then
            for __, __b in pairs(workspace.Boats:GetChildren()) do
                local __s = __b:FindFirstChildWhichIsA("VehicleSeat")
                if __s then __s.MaxSpeed = getgenv().SetSpeedBoat or 100 end
            end
        end
        __chestEspHandler()
        __berryEspHandler()
    end)
end

return __EventsAndPVPModule
