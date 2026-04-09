local UserInputService = cloneref(game:GetService('UserInputService'))
local HttpService = cloneref(game:GetService('HttpService'))
local CoreGui = cloneref(game:GetService('CoreGui'))

local Flags = {}
local Config, Fetcher = {}, {}

local interface = loadstring(game:HttpGet('https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua'))()

local main = interface:CreateWindow({
    Title = 'Angeli Private',
    SubTitle = '',
    TabWidth = 107,
    Size = UDim2.fromOffset(480, 360),
    Acrylic = false,
    Theme = 'Darker',
    MinimizeKey = Enum.KeyCode.End
})

main.Flags = Flags

local mobile_button_ui = Instance.new('ImageButton')
local mobile_hidden_gui = Instance.new('ScreenGui')

mobile_hidden_gui.Enabled = UserInputService.TouchEnabled
mobile_hidden_gui.Parent = (gethui and gethui()) or CoreGui
mobile_hidden_gui.ResetOnSpawn = false

mobile_button_ui.Position = UDim2.new(0, 50, 0, 50)
mobile_button_ui.Image = 'rbxassetid://10723346871'
mobile_button_ui.Size = UDim2.new(0, 44, 0, 44)
mobile_button_ui.Parent = mobile_hidden_gui
mobile_button_ui.BackgroundTransparency = 1
mobile_button_ui.Draggable = true

mobile_button_ui.MouseButton1Click:Connect(function()
    main:Minimize()

    if interface.main.Minimized then
        mobile_button_ui.Image = 'rbxassetid://10723346959'
    else
        mobile_button_ui.Image = 'rbxassetid://10723346871'
    end
end)

interface.GUI.AncestryChanged:Connect(function(_, parent)
    if not parent then
        mobile_hidden_gui:Destroy()
    end
end)

if not isfolder('Angeli') then
    makefolder('Angeli')
end

if not isfolder('Angeli/configs') then
    makefolder('Angeli/configs')
end

local function save_config()
    if not isfile(`Angeli/configs/{game.GameId}.json`) then
        writefile(`Angeli/configs/{game.GameId}.json`, HttpService:JSONEncode({}))
    end

    for index, value in pairs(Flags) do
        Config[index] = type(value) == 'table' and HttpService:JSONDecode(HttpService:JSONEncode(value)) or value
    end

    pcall(function()
        writefile(`Angeli/configs/{game.GameId}.json`, HttpService:JSONEncode(Config))
    end)
end

local function load_config()
    if not isfile(`Angeli/configs/{game.GameId}.json`) then
        save_config()
    end

    Fetcher = HttpService:JSONDecode(readfile(`Angeli/configs/{game.GameId}.json`))

    for index, value in pairs(Fetcher) do
        Flags[index] = value
    end

    return Fetcher
end

local function callback(property, call)
    local Caller = {}

    setmetatable(Caller, {
        __call = function(_, value)
            Flags[property] = value
            save_config()

            return call(value)
        end
    })

    return Caller
end

local function create_signal(signal)
    function signal:create_button(button)
        return signal:AddButton({
            Title = button.title,
            Description = button.description or '',
            Callback = button.callback or (function() end)
        })
    end

    function signal:create_paragraph(paragraph)
        return signal:AddParagraph({
            Title = paragraph.title,
            Content = paragraph.content or ''
        })
    end

    function main:create_dialog(dialog)
        local buttons = {}
    
        for _, button in next, dialog.buttons do
            table.insert(buttons, {
                Title = button.title,
                Callback = button.callback
            })
        end
    
        return main:Dialog({
            Title = dialog.title,
            Content = dialog.content or '',
            Buttons = buttons
        })
    end

    function signal:create_toggle(connection, toggle)
        toggle.flag = toggle.flag or connection

        toggle.default = toggle.default or false
        toggle.callback = toggle.callback or (function() end)

        if not load_config()[toggle.flag] and not Flags[toggle.flag] then
            Flags[toggle.flag] = toggle.default
        end

        toggle.default = load_config()[toggle.flag] or Flags[toggle.flag]
        toggle.callback = callback(toggle.flag, toggle.callback)

        return signal:AddToggle(connection, {
            Title = toggle.title,
            Description = toggle.description or '',
            Default = toggle.default,
            flag = toggle.flag,
            Callback = toggle.callback
        })
    end

    function signal:create_keybind(connection, keybind)
        keybind.flag = keybind.flag or connection

        keybind.default = keybind.default or 'E'
        keybind.callback = keybind.callback or (function() end)

        if not load_config()[keybind.flag] and not Flags[keybind.flag] then
            Flags[keybind.flag] = keybind.default
        end

        keybind.default = load_config()[keybind.flag] or Flags[keybind.flag]

        return signal:AddKeybind(connection, {
            Title = keybind.title,
            Description = keybind.description or '',
            Mode = keybind.mode or 'Toggle',
            Default = keybind.default,
            flag = keybind.flag,
            Callback = keybind.callback,
            ChangedCallback = function(value)
                Flags[keybind.flag] = tostring(value):match('Enum%.KeyCode%.(.+)') or value
                save_config()
            end
        })
    end

    function signal:create_dropdown(connection, dropdown)
        dropdown.flag = dropdown.flag or connection

        dropdown.options = dropdown.options or {}
        dropdown.multi = dropdown.multi or false
        dropdown.default = dropdown.default or 1
        dropdown.callback = dropdown.callback or (function() end)

        if dropdown.multi and not load_config()[dropdown.flag] and not Flags[dropdown.flag] then
            Flags[dropdown.flag] = {}

            for _, value in pairs(dropdown.options) do
                Flags[dropdown.flag][value] = false
            end
        elseif not load_config()[dropdown.flag] and not Flags[dropdown.flag] then
            Flags[dropdown.flag] = dropdown.default
        end

        dropdown.default = load_config()[dropdown.flag] or Flags[dropdown.flag]
        dropdown.callback = callback(dropdown.flag, dropdown.callback)

        return signal:AddDropdown(connection, {
            Title = dropdown.title,
            Description = dropdown.description or '',
            Values = dropdown.options,
            Multi = dropdown.multi,
            Default = dropdown.default,
            flag = dropdown.flag,
            Callback = dropdown.callback
        })
    end

    function signal:create_slider(connection, slider)
        slider.flag = slider.flag or connection

        slider.default = slider.default or 0
        slider.callback = slider.callback or (function() end)

        if not load_config()[slider.flag] and not Flags[slider.flag] then
            Flags[slider.flag] = slider.default
        end

        slider.default = load_config()[slider.flag] or Flags[slider.flag]
        slider.callback = callback(slider.flag, slider.callback)

        return signal:AddSlider(connection, {
            Title = slider.title,
            Description = slider.description or '',
            Min = slider.min or 0,
            Max = slider.max or 100,
            Default = slider.default,
            Rounding = slider.rounding or 1,
            flag = slider.flag,
            Callback = slider.callback
        })
    end

    function signal:create_input(connection, input)
        input.flag = input.flag or connection

        input.default = input.default or ''
        input.callback = input.callback or (function() end)

        if not load_config()[input.flag] and not Flags[input.flag] then
            Flags[input.flag] = input.default
        end

        input.default = load_config()[input.flag] or Flags[input.flag]
        input.callback = callback(input.flag, input.callback)

        return signal:AddInput(connection, {
            Title = input.title,
            Description = input.description or '',
            Default = input.default,
            Placeholder = input.place or '',
            Numeric = input.numeric or false,
            Finished = input.finished or false,
            flag = input.flag,
            Callback = input.callback
        })
    end

    return signal
end

function main:create_tab(tab_name, icon)
    local tab = main:AddTab({ Title = tab_name, Icon = icon or '' })
    create_signal(tab)

    function tab:create_section(name)
        local section = tab:AddSection(name)
        create_signal(section)

        return section
    end

    return tab
end

function main:notify(index)
    interface:Notify({
        Title = index.title,
        Content = index.content,
        Duration = index.duration or 3
    })
end

function main:select_tab(index)
    return main:SelectTab(index)
end

return main
