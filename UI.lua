local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Debug, LocalPlayer = false, PlayerService.LocalPlayer

local MainAssetFolder = Debug and ReplicatedStorage.BracketV32 or InsertService:LoadLocalAsset("rbxassetid://9153139105")

local THEME_ACCENT = Color3.fromRGB(60,140,255)
local THEME_OFF = Color3.fromRGB(70,70,85)

local function GetAsset(AssetPath)
	AssetPath = AssetPath:split("/")
	local Asset = MainAssetFolder
	for _,Name in pairs(AssetPath) do
		Asset = Asset[Name]
	end
	return Asset:Clone()
end

local function GetLongest(A,B)
	return A > B and A or B
end

local function GetType(Object,Default,Type)
	if typeof(Object) == Type then
		return Object
	end
	return Default
end

local function MakeDraggable(Dragger,Object,Callback)
	local StartPosition,StartDrag
	Dragger.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			StartPosition = UserInputService:GetMouseLocation()
			StartDrag = Object.AbsolutePosition
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if StartDrag and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local Mouse = UserInputService:GetMouseLocation()
			local Delta = Mouse - StartPosition
			StartPosition = Mouse
			Object.Position = Object.Position + UDim2.new(0,Delta.X,0,Delta.Y)
		end
	end)
	Dragger.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			StartPosition,StartDrag = nil,nil
			if Callback then
				Callback(Object.Position)
			end
		end
	end)
end

local function MakeResizeable(Dragger,Object,MinSize,Callback)
	local StartPosition,StartSize
	Dragger.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			StartPosition = UserInputService:GetMouseLocation()
			StartSize = Object.AbsoluteSize
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if StartPosition and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local Mouse = UserInputService:GetMouseLocation()
			local Delta = Mouse - StartPosition
			local Size = StartSize + Delta
			Object.Size = UDim2.fromOffset(
				math.max(MinSize.X,Size.X),
				math.max(MinSize.Y,Size.Y)
			)
		end
	end)
	Dragger.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			StartPosition,StartSize = nil,nil
			if Callback then
				Callback(Object.Size)
			end
		end
	end)
end

local function ChooseTab(ScreenAsset,TabButtonAsset,TabAsset)
	for _,Instance in pairs(ScreenAsset:GetChildren()) do
		if Instance.Name == "Palette" or Instance.Name == "OptionContainer" then
			Instance.Visible = false
		end
	end
	for _,Instance in pairs(ScreenAsset.Window.TabContainer:GetChildren()) do
		if Instance:IsA("ScrollingFrame") then
			Instance.Visible = Instance == TabAsset
		end
	end
	for _,Instance in pairs(ScreenAsset.Window.TabButtonContainer:GetChildren()) do
		if Instance:IsA("TextButton") then
			Instance.Highlight.Visible = Instance == TabButtonAsset
		end
	end
end

local function ChooseTabSide(TabAsset,Mode)
	if Mode == "Left" then
		return TabAsset.LeftSide
	elseif Mode == "Right" then
		return TabAsset.RightSide
	end
	if TabAsset.LeftSide.ListLayout.AbsoluteContentSize.Y > TabAsset.RightSide.ListLayout.AbsoluteContentSize.Y then
		return TabAsset.LeftSide
	end
	return TabAsset.RightSide
end

local function InitScreen()
	local ScreenAsset = GetAsset("Screen/Bracket")
	if not Debug then
		sethiddenproperty(ScreenAsset,"OnTopOfCoreBlur",true)
	end
	ScreenAsset.Name = "SouthBronxUI_" .. HttpService:GenerateGUID(false)
	ScreenAsset.Parent = Debug and LocalPlayer.PlayerGui or CoreGui
	return {ScreenAsset = ScreenAsset}
end

local Bracket = InitScreen()
local function InitWindow(ScreenAsset,Window)
	local WindowAsset = GetAsset("Window/Window")
	WindowAsset.Parent = ScreenAsset
	WindowAsset.Visible = Window.Enabled
	WindowAsset.Title.Text = Window.Name
	WindowAsset.Position = Window.Position
	WindowAsset.Size = Window.Size

	MakeDraggable(WindowAsset.Drag,WindowAsset,function(Pos)
		Window.Position = Pos
	end)

	MakeResizeable(WindowAsset.Resize,WindowAsset,Vector2.new(320,320),function(Size)
		Window.Size = Size
	end)

	WindowAsset.TabButtonContainer.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		WindowAsset.TabButtonContainer.CanvasSize = UDim2.new(
			0,
			WindowAsset.TabButtonContainer.ListLayout.AbsoluteContentSize.X,
			0,0
		)
	end)

	RunService.RenderStepped:Connect(function()
		if WindowAsset.Visible then
			ScreenAsset.ToolTip.Position = UDim2.new(
				0,UserInputService:GetMouseLocation().X + 6,
				0,UserInputService:GetMouseLocation().Y - 6
			)
		end
	end)

	RunService.RenderStepped:Connect(function()
		Window.RainbowHue = os.clock() % 10 / 10
	end)

	function Window:SetName(Name)
		Window.Name = Name
		WindowAsset.Title.Text = Name
	end

	function Window:SetSize(Size)
		Window.Size = Size
		WindowAsset.Size = Size
	end

	function Window:SetPosition(Position)
		Window.Position = Position
		WindowAsset.Position = Position
	end

	function Window:SetColor(Color)
		for _,Obj in pairs(Window.Colorable) do
			if Obj.BackgroundColor3 == Window.Color then
				Obj.BackgroundColor3 = Color
			end
			if Obj.BorderColor3 == Window.Color then
				Obj.BorderColor3 = Color
			end
		end
		Window.Color = Color
	end

	function Window:Toggle(Bool)
		Window.Enabled = Bool
		WindowAsset.Visible = Bool
	end

	Window.Background = WindowAsset.Background
	return WindowAsset
end

local function InitTab(ScreenAsset,WindowAsset,Window,Tab)
	local TabButtonAsset = GetAsset("Tab/TabButton")
	local TabAsset = GetAsset("Tab/Tab")

	TabButtonAsset.Parent = WindowAsset.TabButtonContainer
	TabButtonAsset.Text = Tab.Name
	TabButtonAsset.Highlight.BackgroundColor3 = Window.Color
	TabButtonAsset.Size = UDim2.new(0,TabButtonAsset.TextBounds.X + 10,1,-2)

	TabAsset.Parent = WindowAsset.TabContainer
	TabAsset.Visible = false

	table.insert(Window.Colorable,TabButtonAsset.Highlight)

	local function UpdateCanvas()
		local Side = ChooseTabSide(TabAsset)
		TabAsset.CanvasSize = UDim2.new(
			0,0,
			0,Side.ListLayout.AbsoluteContentSize.Y + 24
		)
	end

	TabAsset.LeftSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
	TabAsset.RightSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

	TabButtonAsset.MouseButton1Click:Connect(function()
		ChooseTab(ScreenAsset,TabButtonAsset,TabAsset)
	end)

	if #WindowAsset.TabContainer:GetChildren() == 1 then
		ChooseTab(ScreenAsset,TabButtonAsset,TabAsset)
	end

	function Tab:SetName(Name)
		Tab.Name = Name
		TabButtonAsset.Text = Name
		TabButtonAsset.Size = UDim2.new(0,TabButtonAsset.TextBounds.X + 10,1,-2)
	end

	return function(Side)
		return ChooseTabSide(TabAsset,Side)
	end
end

function Bracket:Window(Window)
	Window = GetType(Window,{},"table")
	Window.Name = GetType(Window.Name,"South Bronx","string")
	Window.Color = GetType(Window.Color,THEME_ACCENT,"Color3")
	Window.Size = GetType(Window.Size,UDim2.new(0,520,0,520),"UDim2")
	Window.Position = GetType(Window.Position,UDim2.new(0.5,-260,0.5,-260),"UDim2")
	Window.Enabled = GetType(Window.Enabled,true,"boolean")

	Window.RainbowHue = 0
	Window.Colorable = {}
	Window.Elements = {}
	Window.Flags = {}

	local WindowAsset = InitWindow(Bracket.ScreenAsset,Window)

	function Window:Tab(Tab)
		Tab = GetType(Tab,{},"table")
		Tab.Name = GetType(Tab.Name,"Tab","string")
		local ChooseSide = InitTab(Bracket.ScreenAsset,WindowAsset,Window,Tab)

		function Tab:Divider(Divider)
			Divider = GetType(Divider,{},"table")
			Divider.Text = GetType(Divider.Text,"","string")
			local Asset = GetAsset("Divider/Divider")
			Asset.Parent = ChooseSide(Divider.Side)
			Asset.Title.Text = Divider.Text
			return Divider
		end

		function Tab:Label(Label)
			Label = GetType(Label,{},"table")
			Label.Text = GetType(Label.Text,"Label","string")
			local Asset = GetAsset("Label/Label")
			Asset.Parent = ChooseSide(Label.Side)
			Asset.Text = Label.Text
			return Label
		end

		return Tab
	end

	return Window
end
local function InitButton(Parent,ScreenAsset,Window,Button)
	local Asset = GetAsset("Button/Button")
	Asset.Parent = Parent
	Asset.Title.Text = Button.Name

	table.insert(Window.Colorable,Asset)

	Button.Connection = Asset.MouseButton1Click:Connect(Button.Callback)

	Asset.MouseButton1Down:Connect(function()
		Asset.BorderColor3 = Window.Color
	end)
	Asset.MouseButton1Up:Connect(function()
		Asset.BorderColor3 = Color3.new(0,0,0)
	end)
	Asset.MouseLeave:Connect(function()
		Asset.BorderColor3 = Color3.new(0,0,0)
	end)

	Asset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
		Asset.Size = UDim2.new(1,0,0,Asset.Title.TextBounds.Y + 4)
	end)
end

local function InitToggle(Parent,ScreenAsset,Window,Toggle)
	local Asset = GetAsset("Toggle/Toggle")
	Asset.Parent = Parent
	Asset.Title.Text = Toggle.Name
	Asset.Tick.BackgroundColor3 = Toggle.Value and Window.Color or THEME_OFF

	table.insert(Window.Colorable,Asset.Tick)

	Asset.MouseButton1Click:Connect(function()
		Toggle.Value = not Toggle.Value
		Window.Flags[Toggle.Flag] = Toggle.Value
		Toggle.Callback(Toggle.Value)
		Asset.Tick.BackgroundColor3 = Toggle.Value and Window.Color or THEME_OFF
	end)

	Asset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
		Asset.Size = UDim2.new(1,0,0,Asset.Title.TextBounds.Y)
	end)
end

local function InitSlider(Parent,ScreenAsset,Window,Slider)
	local Asset = GetAsset("Slider/Slider")
	Asset.Parent = Parent
	Asset.Title.Text = Slider.Name

	table.insert(Window.Colorable,Asset.Background.Bar)
	Asset.Background.Bar.BackgroundColor3 = Window.Color

	local function Update(Value)
		Slider.Value = Value
		Asset.Background.Bar.Size = UDim2.new(
			(Value - Slider.Min) / (Slider.Max - Slider.Min),
			0,1,0
		)
		Window.Flags[Slider.Flag] = Value
		Slider.Callback(Value)
	end

	Update(Slider.Value)

	Asset.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			local X = math.clamp(
				(Input.Position.X - Asset.Background.AbsolutePosition.X)
				/ Asset.Background.AbsoluteSize.X,
				0,1
			)
			Update(math.floor((Slider.Min + (Slider.Max-Slider.Min)*X)*10)/10)
		end
	end)
end

local function InitTextbox(Parent,ScreenAsset,Window,Textbox)
	local Asset = GetAsset("Textbox/Textbox")
	Asset.Parent = Parent
	Asset.Title.Text = Textbox.Name
	Asset.Background.Input.Text = Textbox.Value
	Asset.Background.Input.PlaceholderText = Textbox.Placeholder

	Asset.Background.Input.FocusLost:Connect(function(Enter)
		if not Enter then return end
		Textbox.Value = Asset.Background.Input.Text
		Window.Flags[Textbox.Flag] = Textbox.Value
		Textbox.Callback(Textbox.Value)
	end)
end

local function InitKeybind(Parent,ScreenAsset,Window,Keybind)
	local Asset = GetAsset("Keybind/Keybind")
	Asset.Parent = Parent
	Asset.Title.Text = Keybind.Name
	Asset.Value.Text = "[ "..Keybind.Value.." ]"

	Asset.MouseButton1Click:Connect(function()
		Asset.Value.Text = "[ ... ]"
		Keybind.Waiting = true
	end)

	UserInputService.InputBegan:Connect(function(Input)
		if Keybind.Waiting and Input.UserInputType == Enum.UserInputType.Keyboard then
			local Key = tostring(Input.KeyCode):gsub("Enum.KeyCode.","")
			Keybind.Value = Key
			Asset.Value.Text = "[ "..Key.." ]"
			Keybind.Waiting = false
			Window.Flags[Keybind.Flag] = Key
			Keybind.Callback(Key,true)
		end
	end)
end
local function InitSection(Parent,Section)
	local Asset = GetAsset("Section/Section")
	Asset.Parent = Parent
	Asset.Title.Text = Section.Name

	Asset.Container.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Asset.Size = UDim2.new(1,0,0,Asset.Container.ListLayout.AbsoluteContentSize.Y + 18)
	end)

	function Section:SetName(Name)
		Section.Name = Name
		Asset.Title.Text = Name
	end

	return Asset.Container
end

local function InitDropdown(Parent,ScreenAsset,Window,Dropdown)
	local Asset = GetAsset("Dropdown/Dropdown")
	local Options = GetAsset("Dropdown/OptionContainer")
	Asset.Parent = Parent
	Asset.Title.Text = Dropdown.Name
	Options.Parent = ScreenAsset

	local function Refresh()
		local Selected = {}
		for _,Opt in pairs(Dropdown.List) do
			if Opt.Value then
				table.insert(Selected,Opt.Name)
			end
		end
		Asset.Background.Value.Text = #Selected > 0 and table.concat(Selected,", ") or "..."
	end

	for _,Opt in pairs(Dropdown.List) do
		local OptAsset = GetAsset("Dropdown/Option")
		OptAsset.Parent = Options
		OptAsset.Title.Text = Opt.Name
		OptAsset.BorderColor3 = Opt.Value and Window.Color or THEME_OFF
		table.insert(Window.Colorable,OptAsset)

		OptAsset.MouseButton1Click:Connect(function()
			if Opt.Mode == "Button" then
				for _,O in pairs(Dropdown.List) do
					O.Value = false
				end
				Options.Visible = false
			end
			Opt.Value = not Opt.Value
			OptAsset.BorderColor3 = Opt.Value and Window.Color or THEME_OFF
			Refresh()
			Window.Flags[Dropdown.Flag] = Dropdown.Value
			if Opt.Callback then
				Opt.Callback(Dropdown.Value,Opt)
			end
		end)
	end

	Asset.MouseButton1Click:Connect(function()
		Options.Visible = not Options.Visible
		if Options.Visible then
			Options.Position = UDim2.new(
				0,Asset.Background.AbsolutePosition.X,
				0,Asset.Background.AbsolutePosition.Y + Asset.Background.AbsoluteSize.Y + 36
			)
		end
	end)
end

local function InitColorpicker(Parent,ScreenAsset,Window,Colorpicker)
	local Asset = GetAsset("Colorpicker/Colorpicker")
	local Palette = GetAsset("Colorpicker/Palette")
	Asset.Parent = Parent
	Asset.Title.Text = Colorpicker.Name
	Palette.Parent = ScreenAsset

	local function Update()
		local Col = Color3.fromHSV(Colorpicker.Value[1],Colorpicker.Value[2],Colorpicker.Value[3])
		Asset.Color.BackgroundColor3 = Col
		Window.Flags[Colorpicker.Flag] = Colorpicker.Value
		Colorpicker.Callback(Colorpicker.Value,Col)
	end

	Asset.MouseButton1Click:Connect(function()
		Palette.Visible = not Palette.Visible
	end)

	RunService.RenderStepped:Connect(function()
		if Colorpicker.Value[5] then
			Colorpicker.Value[1] = Window.RainbowHue
			Update()
		end
	end)

	Update()
end

function Bracket:Notification(Notification)
	Notification = GetType(Notification,{},"table")
	local Asset = GetAsset("Notification/ND")
	Asset.Parent = Bracket.ScreenAsset.NDHandle
	Asset.Title.Text = Notification.Title
	Asset.Description.Text = Notification.Description

	if Notification.Duration then
		task.delay(Notification.Duration,function()
			Asset:Destroy()
		end)
	else
		Asset.Title.Close.MouseButton1Click:Connect(function()
			Asset:Destroy()
		end)
	end
end

function Bracket:Notification2(Notification)
	Notification = GetType(Notification,{},"table")
	local Asset = GetAsset("Notification/NL")
	Asset.Parent = Bracket.ScreenAsset.NLHandle
	Asset.Main.Title.Text = Notification.Title
	Asset.Main.GLine.BackgroundColor3 = THEME_ACCENT
	task.delay(Notification.Duration or 5,function()
		Asset:Destroy()
	end)
end

return Bracket
