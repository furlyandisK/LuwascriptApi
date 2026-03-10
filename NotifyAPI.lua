--[[
    NOTIFYAPI - FULL GUIDE
    ----------------------
    STEP 1: Load it at the top of your LocalScript (once):
            local Notify = loadstring(game:HttpGet("YOUR_RAW_URL"))()

    STEP 2: Call it anywhere:

        -- Message only
        Notify("Hello world!")

        -- Title + message
        Notify("Welcome", "Thanks for using the script!")

        -- With type
        Notify("Done", "Trade completed!", { Type = "success" })
        Notify("Careful", "Your health is low!", { Type = "warn" })
        Notify("Oops", "Something went wrong.", { Type = "error" })
        Notify("Info", "Server restarts in 5 min.", { Type = "info" })

        -- With custom duration (seconds)
        Notify("Quick", "This disappears fast.", { Duration = 2 })

        -- Both options together
        Notify("Update", "New version is out!", { Type = "success", Duration = 8 })

    TYPES:
        "info"    - Blue  - bell icon  (default)
        "success" - Green - check icon
        "warn"    - Orange - warning icon
        "error"   - Red   - X icon

    FEATURES:
        - Hover over a notification to pause its timer
        - Click x to close it immediately
        - Up to 6 notifications stacked at once
        - Long messages auto-wrap, card grows to fit
]]


local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CARD_W = 270
local CORNER = 12
local DEFAULT_DUR = 5
local MAX_NOTIFS = 6
local ANIM_IN = 0.38
local ANIM_OUT = 0.28
local FONT_TITLE = Enum.Font.GothamBold
local FONT_BODY = Enum.Font.Gotham

local THEMES = {
	info    = { Accent = Color3.fromRGB(99, 179, 237),  Icon = "🔔", Label = "INFO" },
	success = { Accent = Color3.fromRGB(104, 211, 145), Icon = "✓",  Label = "SUCCESS" },
	warn    = { Accent = Color3.fromRGB(246, 173, 85),  Icon = "⚠",  Label = "WARNING" },
	error   = { Accent = Color3.fromRGB(252, 129, 129), Icon = "✕",  Label = "ERROR" },
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NotifyAPI_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local Container = Instance.new("Frame")
Container.Name = "NotifContainer"
Container.AnchorPoint = Vector2.new(1, 1)
Container.Position = UDim2.new(1, -16, 1, -16)
Container.Size = UDim2.new(0, CARD_W, 1, -32)
Container.BackgroundTransparency = 1
Container.ClipsDescendants = false
Container.Parent = ScreenGui

local ListLayout = Instance.new("UIListLayout")
ListLayout.FillDirection = Enum.FillDirection.Vertical
ListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 8)
ListLayout.Parent = Container

local activeNotifs = {}

local function createCard(title, message, theme)
	local Slot = Instance.new("Frame")
	Slot.Name = "NotifSlot"
	Slot.Size = UDim2.new(1, 0, 0, 0)
	Slot.AutomaticSize = Enum.AutomaticSize.Y
	Slot.BackgroundTransparency = 1
	Slot.ClipsDescendants = false

	local Card = Instance.new("Frame")
	Card.Name = "Card"
	Card.Size = UDim2.new(1, 0, 0, 0)
	Card.AutomaticSize = Enum.AutomaticSize.Y
	Card.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
	Card.BackgroundTransparency = 0.35
	Card.BorderSizePixel = 0
	Card.ClipsDescendants = false
	Card.Position = UDim2.new(0, CARD_W + 30, 0, 0)
	Card.Parent = Slot
	Instance.new("UICorner", Card).CornerRadius = UDim.new(0, CORNER)

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(255, 255, 255)
	Stroke.Transparency = 0.92
	Stroke.Thickness = 1
	Stroke.Parent = Card

	local Shadow = Instance.new("Frame")
	Shadow.Size = UDim2.new(1, 14, 1, 14)
	Shadow.Position = UDim2.new(0, -7, 0, 7)
	Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Shadow.BackgroundTransparency = 0.7
	Shadow.BorderSizePixel = 0
	Shadow.ZIndex = 1
	Shadow.Parent = Card
	Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, CORNER + 5)

	local AccentBar = Instance.new("Frame")
	AccentBar.Size = UDim2.new(0, 3, 1, -16)
	AccentBar.Position = UDim2.new(0, 8, 0, 8)
	AccentBar.BackgroundColor3 = theme.Accent
	AccentBar.BorderSizePixel = 0
	AccentBar.ZIndex = 3
	AccentBar.Parent = Card
	Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(1, 0)

	local Inner = Instance.new("Frame")
	Inner.BackgroundTransparency = 1
	Inner.Size = UDim2.new(1, -52, 0, 0)
	Inner.Position = UDim2.new(0, 20, 0, 0)
	Inner.AutomaticSize = Enum.AutomaticSize.Y
	Inner.ZIndex = 3
	Inner.Parent = Card

	local InnerLayout = Instance.new("UIListLayout")
	InnerLayout.FillDirection = Enum.FillDirection.Vertical
	InnerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	InnerLayout.Padding = UDim.new(0, 4)
	InnerLayout.Parent = Inner

	local InnerPad = Instance.new("UIPadding")
	InnerPad.PaddingTop = UDim.new(0, 9)
	InnerPad.PaddingBottom = UDim.new(0, 11)
	InnerPad.Parent = Inner

	local Badge = Instance.new("TextLabel")
	Badge.LayoutOrder = 1
	Badge.Size = UDim2.new(0, 0, 0, 16)
	Badge.AutomaticSize = Enum.AutomaticSize.X
	Badge.BackgroundColor3 = theme.Accent
	Badge.BackgroundTransparency = 0.78
	Badge.TextColor3 = theme.Accent
	Badge.Text = theme.Icon .. "  " .. theme.Label
	Badge.Font = FONT_TITLE
	Badge.TextSize = 8
	Badge.TextXAlignment = Enum.TextXAlignment.Center
	Badge.ZIndex = 4
	Badge.Parent = Inner
	Instance.new("UICorner", Badge).CornerRadius = UDim.new(0, 4)
	local BP = Instance.new("UIPadding")
	BP.PaddingLeft = UDim.new(0, 7)
	BP.PaddingRight = UDim.new(0, 7)
	BP.Parent = Badge

	local TitleLbl = Instance.new("TextLabel")
	TitleLbl.LayoutOrder = 2
	TitleLbl.Size = UDim2.new(1, 0, 0, 0)
	TitleLbl.AutomaticSize = Enum.AutomaticSize.Y
	TitleLbl.BackgroundTransparency = 1
	TitleLbl.TextColor3 = Color3.fromRGB(238, 238, 255)
	TitleLbl.Font = FONT_TITLE
	TitleLbl.TextSize = 13
	TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
	TitleLbl.TextWrapped = true
	TitleLbl.Text = title or message
	TitleLbl.ZIndex = 4
	TitleLbl.Parent = Inner

	if title and message then
		local MsgLbl = Instance.new("TextLabel")
		MsgLbl.LayoutOrder = 3
		MsgLbl.Size = UDim2.new(1, 0, 0, 0)
		MsgLbl.AutomaticSize = Enum.AutomaticSize.Y
		MsgLbl.BackgroundTransparency = 1
		MsgLbl.TextColor3 = Color3.fromRGB(155, 155, 178)
		MsgLbl.Font = FONT_BODY
		MsgLbl.TextSize = 11
		MsgLbl.TextXAlignment = Enum.TextXAlignment.Left
		MsgLbl.TextWrapped = true
		MsgLbl.Text = message
		MsgLbl.ZIndex = 4
		MsgLbl.Parent = Inner
	end

	local ProgressBG = Instance.new("Frame")
	ProgressBG.AnchorPoint = Vector2.new(0, 1)
	ProgressBG.Position = UDim2.new(0, 0, 1, 0)
	ProgressBG.Size = UDim2.new(1, 0, 0, 3)
	ProgressBG.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
	ProgressBG.BackgroundTransparency = 0
	ProgressBG.BorderSizePixel = 0
	ProgressBG.ZIndex = 5
	ProgressBG.Parent = Card
	Instance.new("UICorner", ProgressBG).CornerRadius = UDim.new(0, 3)

	local ProgressFill = Instance.new("Frame")
	ProgressFill.Size = UDim2.new(1, 0, 1, 0)
	ProgressFill.BackgroundColor3 = theme.Accent
	ProgressFill.BorderSizePixel = 0
	ProgressFill.ZIndex = 6
	ProgressFill.Parent = ProgressBG
	Instance.new("UICorner", ProgressFill).CornerRadius = UDim.new(0, 3)

	local CloseBtn = Instance.new("TextButton")
	CloseBtn.AnchorPoint = Vector2.new(1, 0)
	CloseBtn.Position = UDim2.new(1, -8, 0, 8)
	CloseBtn.Size = UDim2.new(0, 20, 0, 20)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
	CloseBtn.BackgroundTransparency = 0.3
	CloseBtn.TextColor3 = Color3.fromRGB(175, 175, 200)
	CloseBtn.Font = FONT_TITLE
	CloseBtn.TextSize = 14
	CloseBtn.Text = "×"
	CloseBtn.AutoButtonColor = false
	CloseBtn.ZIndex = 7
	CloseBtn.Parent = Card
	Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

	CloseBtn.MouseEnter:Connect(function()
		TweenService:Create(CloseBtn, TweenInfo.new(0.1), { BackgroundTransparency = 0, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
	end)
	CloseBtn.MouseLeave:Connect(function()
		TweenService:Create(CloseBtn, TweenInfo.new(0.1), { BackgroundTransparency = 0.3, TextColor3 = Color3.fromRGB(175, 175, 200) }):Play()
	end)

	return Slot, Card, ProgressFill, CloseBtn
end

local function dismissCard(slot, card)
	if not slot or not slot.Parent then return end
	for i, s in ipairs(activeNotifs) do
		if s == slot then table.remove(activeNotifs, i) break end
	end
	TweenService:Create(card, TweenInfo.new(ANIM_OUT, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
		{ Position = UDim2.new(0, CARD_W + 30, 0, 0), BackgroundTransparency = 0.6 }):Play()
	task.delay(ANIM_OUT * 0.5, function()
		if not slot or not slot.Parent then return end
		local h = slot.AbsoluteSize.Y
		slot.AutomaticSize = Enum.AutomaticSize.None
		slot.Size = UDim2.new(1, 0, 0, h)
		TweenService:Create(slot, TweenInfo.new(ANIM_OUT * 0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Size = UDim2.new(1, 0, 0, 0) }):Play()
	end)
	task.delay(ANIM_OUT + ANIM_OUT * 0.5 + ANIM_OUT * 0.7 + 0.05, function()
		if slot and slot.Parent then slot:Destroy() end
	end)
end

local function Notify(arg1, arg2, arg3)
	local title, message, opts
	if type(arg1) == "string" and type(arg2) == "string" then
		title, message, opts = arg1, arg2, type(arg3) == "table" and arg3 or {}
	elseif type(arg1) == "string" then
		title, message, opts = nil, arg1, type(arg2) == "table" and arg2 or {}
	else
		warn("[NotifyAPI] Usage: Notify(msg) or Notify(title, msg) or Notify(title, msg, opts)")
		return
	end

	local duration = tonumber(opts.Duration) or DEFAULT_DUR
	local theme = THEMES[(opts.Type and THEMES[opts.Type]) and opts.Type or "info"]

	if #activeNotifs >= MAX_NOTIFS then
		local oldest = activeNotifs[1]
		if oldest and oldest.Parent then
			dismissCard(oldest, oldest:FindFirstChild("Card"))
		end
	end

	local slot, card, progressFill, closeBtn = createCard(title, message, theme)
	slot.LayoutOrder = #activeNotifs + 1
	slot.Parent = Container
	table.insert(activeNotifs, slot)

	TweenService:Create(card, TweenInfo.new(ANIM_IN, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, 0, 0, 0) }):Play()

	local remaining = duration
	local hovered = false
	local dismissed = false

	local function startProgressTween(frac)
		TweenService:Create(progressFill, TweenInfo.new(remaining * frac, Enum.EasingStyle.Linear),
			{ Size = UDim2.new(0, 0, 1, 0) }):Play()
	end
	startProgressTween(1)

	local hbConn
	hbConn = RunService.Heartbeat:Connect(function(dt)
		if dismissed then hbConn:Disconnect() return end
		if hovered then return end
		remaining = remaining - dt
		if remaining <= 0 then
			dismissed = true
			hbConn:Disconnect()
			dismissCard(slot, card)
		end
	end)

	card.MouseEnter:Connect(function()
		if dismissed then return end
		hovered = true
		progressFill.Size = UDim2.new(math.clamp(remaining / duration, 0, 1), 0, 1, 0)
		TweenService:Create(card, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(26, 26, 36), BackgroundTransparency = 0.2 }):Play()
	end)
	card.MouseLeave:Connect(function()
		if dismissed then return end
		hovered = false
		startProgressTween(math.clamp(remaining / duration, 0, 1))
		TweenService:Create(card, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(16, 16, 22), BackgroundTransparency = 0.35 }):Play()
	end)

	closeBtn.MouseButton1Click:Connect(function()
		if dismissed then return end
		dismissed = true
		hbConn:Disconnect()
		dismissCard(slot, card)
	end)
end

return Notify
