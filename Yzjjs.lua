--[[
	NurHub Visual  |  v1.0  |  Murder Mystery 2  (визуал работает и в других играх Roblox)
	Только визуал: ESP, Chams, Hat, Trails, FOV, скинченджер, статистика и т.д.
	Без Drawing API: всё на Frame / UIStroke / Highlight / PointLight / Trail.
	Меню: кнопка NH или RightShift.   Telegram: https://t.me/NurHuboffical
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UIS               = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local GuiService        = game:GetService("GuiService")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
while not LP do
	task.wait()
	LP = Players.LocalPlayer
end

local VERSION = "1.0"
local TG_LINK = "https://t.me/NurHuboffical"
local WHITE   = Color3.new(1, 1, 1)
local ENV     = (typeof(getgenv) == "function" and getgenv()) or _G

-- выгружаем прошлый запуск (циклы, ESP, шляпы, трейлы, скины)
if ENV.NurHubMM2Unload then pcall(ENV.NurHubMM2Unload) end

local alive = true
local conns = {}
local function track(c)
	conns[#conns + 1] = c
	return c
end

----------------------------------------------------------------
-- Утилиты
----------------------------------------------------------------
local function mount(g)
	local ok = pcall(function()
		g.Parent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
	end)
	if not ok or not g.Parent then
		g.Parent = LP:WaitForChild("PlayerGui")
	end
end

local function new(class, props, parent)
	local o = Instance.new(class)
	if props then
		for k, v in pairs(props) do o[k] = v end
	end
	if parent then o.Parent = parent end
	return o
end
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, c, th, tr)
	return new("UIStroke", {
		Color = c, Thickness = th or 1, Transparency = tr or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, o)
end
local function tw(o, t, props, style, dir)
	local tween = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end
local orderN = 0
local function ord()
	orderN += 1
	return orderN
end
local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

do -- остатки старых запусков
	local roots = { LP:FindFirstChildOfClass("PlayerGui") }
	pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
	pcall(function() if typeof(gethui) == "function" then table.insert(roots, gethui()) end end)
	for _, r in ipairs(roots) do
		for _, n in ipairs({ "NurHubMM2_UI", "NurHubMM2_ESP", "NurHubMM2_Load" }) do
			local o = r and r:FindFirstChild(n)
			if o then pcall(function() o:Destroy() end) end
		end
	end
	pcall(function() RunService:UnbindFromRenderStep("NH_FOV") end)
	pcall(function() RunService:UnbindFromRenderStep("NH_MAIN") end)
end

local C = {
	bg      = Color3.fromRGB(13, 13, 19),
	side    = Color3.fromRGB(16, 16, 24),
	card    = Color3.fromRGB(21, 20, 31),
	drawer  = Color3.fromRGB(15, 15, 23),
	line    = Color3.fromRGB(38, 36, 54),
	text    = Color3.fromRGB(235, 235, 245),
	sub     = Color3.fromRGB(135, 133, 158),
	off     = Color3.fromRGB(50, 48, 70),
	track   = Color3.fromRGB(34, 33, 50),
	field   = Color3.fromRGB(11, 11, 17),
	accent  = Color3.fromRGB(122, 92, 255),
	accent2 = Color3.fromRGB(88, 140, 255),
	good    = Color3.fromRGB(70, 230, 130),
	bad     = Color3.fromRGB(255, 90, 100),
}

----------------------------------------------------------------
-- НАСТРОЙКИ (одна таблица, UI и ESP читают её напрямую)
----------------------------------------------------------------
local PURPLE = Color3.fromRGB(150, 110, 255)
local CFG = {
	esp     = { on = true, team = false, maxDist = 1500, roles = true, sync = true },
	box2d   = { on = false, color = WHITE },
	corner  = { on = false, color = WHITE, len = 28 }, -- len = % от размера бокса (масштабируется с дистанцией)
	fill    = { on = false, c1 = Color3.fromRGB(12, 12, 20), c2 = PURPLE, trans = 0.5 },
	box3d   = { on = false, color = Color3.fromRGB(80, 200, 255) },
	name    = { on = false, color = WHITE },
	dist    = { on = false, color = Color3.fromRGB(190, 190, 210) },
	health  = { on = false, color = Color3.fromRGB(70, 230, 120) },
	avatar  = { on = false, color = WHITE },
	chams   = { on = false, color = PURPLE, trans = 0.5 },
	outline = { on = false, color = WHITE },
	wall    = { on = false, hid = Color3.fromRGB(255, 60, 60), vis = Color3.fromRGB(70, 255, 110) },
	glow    = { on = false, color = PURPLE, range = 16, bright = 2 },
	tracer  = { on = false, color = WHITE, origin = "Bottom" },
	skel    = { on = false, color = WHITE },
	head    = { on = false, color = Color3.fromRGB(255, 90, 110) },
	arrows  = {
		on = false, color = WHITE, radius = 130, size = 14,
		murder = Color3.fromRGB(255, 60, 60), sheriff = Color3.fromRGB(70, 140, 255),
	},
	fov     = { on = false, val = 90 },
	third   = { on = false, dist = 12 },
	fps     = { on = false, color = WHITE, custom = false, value = 999, x = 0.02, y = 0.03 },
	hat     = {
		on = false, color = Color3.fromRGB(150, 90, 230), trans = 0.4, scope = "Everyone", size = 100,
		lines = 24, rainbow = true, mode = "Lines", shimmer = false,
	},
	trail   = { on = false, color = Color3.fromRGB(122, 92, 255), len = 1.2, width = 0.8, scope = "Only me" },
	steps   = { on = false, color = Color3.fromRGB(122, 92, 255), life = 2.5, shape = "Circle", scope = "Only me", dist = 2.4, delay = 0 },
	gun     = { on = false, color = Color3.fromRGB(255, 200, 50), text = true, textColor = WHITE, tracer = false },
	coin    = { on = false, color = Color3.fromRGB(255, 215, 60), text = true, textColor = WHITE },
	xray    = { on = false, amount = 0.6 },
	walk    = { on = false, val = 32 },
	jump    = { on = false, val = 90 },
	spin    = { on = false, val = 360 },
	noclip  = { on = false },
	fly     = { on = false, val = 60 },
	farm    = { on = false, fly = 60, delay = 0.3 },
	shader  = { on = false, preset = "4K" },
	wbright = { on = false, val = 0.1 },
	wglow   = { on = false, int = 1, thr = 0.9 },
	wdark   = { on = false, val = 0.4 },
	wgrade  = { on = false, sat = 0.2, con = 0.1 },
	wblur   = { on = false, val = 8 },
	wfog    = { on = false, val = 0.3 },
	wrays   = { on = false, val = 0.3 },
	wtime   = { on = false, val = 12 },
	wfull   = { on = false },
	wshadow = { on = false },
	xhair   = { on = false, shape = "Cross", color = WHITE, size = 12, thick = 2, spin = false, speed = 90 },
	bpath   = { on = false, color = Color3.fromRGB(255, 80, 80), time = 2 },
	hsound  = { on = false, sound = "Ping", volume = 6, id = "" },
	wings   = { on = false, color = Color3.fromRGB(80, 200, 255), len = 4, width = 1, scope = "Only me" },
	halo    = { on = false, color = Color3.fromRGB(80, 200, 255), radius = 1.6, scope = "Only me" },
	headless = { on = false },
	korblox = { on = false },
	god     = { on = false },
	bhop    = { on = false, dist = 45 },
	anim    = { on = false, pack = "Ninja" },
	emote   = { auto = false, name = "Dance", id = "", speed = 1 },
	grab    = { on = false },
	skin    = { gun = "", knife = "", hold = false },
	pcolor  = {},
	acolor  = {},
	target  = { mode = "All", userId = 0 },
}

----------------------------------------------------------------
-- Общие хелперы (настройки, файлы, роли, аватары)
----------------------------------------------------------------
local X = {
	SET = { lang = "en", scale = 1, trans = 0, accent = C.accent, stats = true },
	refresh = {}, transReg = {}, lists = {}, searchReg = {}, pageSF = {}, DICT = nil,
}

do
	-- файлы (если executor их поддерживает), иначе память
	local DIR = "NurHubMM2"
	local mem = ENV.NurHubMM2Mem or {}
	ENV.NurHubMM2Mem = mem
	local fsOk = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
	pcall(function()
		if fsOk and typeof(makefolder) == "function" and typeof(isfolder) == "function" and not isfolder(DIR) then
			makefolder(DIR)
		end
	end)
	function X.fsRead(name)
		if fsOk then
			local ok, res = pcall(function()
				if isfile(DIR .. "/" .. name) then return readfile(DIR .. "/" .. name) end
				return nil
			end)
			if ok then return res end
			return nil
		end
		return mem[name]
	end
	function X.fsWrite(name, str)
		if fsOk then
			pcall(writefile, DIR .. "/" .. name, str)
		else
			mem[name] = str
		end
	end

	function X.saveSettings()
		local s = X.SET
		local a = s.accent
		pcall(function()
			X.fsWrite("settings.json", HttpService:JSONEncode({
				lang = s.lang, scale = s.scale, trans = s.trans, stats = s.stats, accent = { a.R, a.G, a.B },
			}))
		end)
	end
	do
		local raw = X.fsRead("settings.json")
		if raw then
			local ok, t = pcall(function() return HttpService:JSONDecode(raw) end)
			if ok and type(t) == "table" then
				X.SET.lang = (t.lang == "ru") and "ru" or "en"
				X.SET.scale = math.clamp(tonumber(t.scale) or 1, .5, 1.3)
				X.SET.trans = math.clamp(tonumber(t.trans) or 0, 0, .6)
				if t.stats ~= nil then X.SET.stats = (t.stats == true) end
				if type(t.accent) == "table" and #t.accent == 3 then
					X.SET.accent = Color3.new(t.accent[1], t.accent[2], t.accent[3])
					C.accent = X.SET.accent
					local h, s, v = C.accent:ToHSV()
					C.accent2 = Color3.fromHSV((h + .07) % 1, s * .9, math.clamp(v + .05, 0, 1))
				end
			end
		end
	end

	-- прозрачность меню
	function X.regT(inst)
		X.transReg[#X.transReg + 1] = inst
		inst.BackgroundTransparency = X.SET.trans
	end
	function X.applyTrans()
		for _, i in ipairs(X.transReg) do i.BackgroundTransparency = X.SET.trans end
	end

	-- реестр обновления UI (после загрузки конфига)
	function X.reg(fn) X.refresh[#X.refresh + 1] = fn end
	function X.refreshAll()
		for _, f in ipairs(X.refresh) do pcall(f) end
	end

	-- реестр для поиска по функциям
	function X.regSearch(name, box)
		if X.inDrawer or not X.curTab then return end
		X.searchReg[#X.searchReg + 1] = { name = name, tab = X.curTab, box = box }
	end

	-- перевод
	function X.tr(s)
		local d = X.DICT and X.DICT[s]
		if X.SET.lang == "ru" and d then return d end
		return s
	end

	-- заглавные для кириллицы (string.upper работает только с ASCII)
	function X.upper(s)
		local out = {}
		local ok = pcall(function()
			for _, cp in utf8.codes(s) do
				if cp >= 0x430 and cp <= 0x44F then
					cp -= 32
				elseif cp == 0x451 then
					cp = 0x401
				elseif cp < 128 then
					cp = string.byte(string.upper(string.char(cp)))
				end
				out[#out + 1] = utf8.char(cp)
			end
		end)
		if not ok then return string.upper(s) end
		return table.concat(out)
	end

	-- аватары (headshot)
	local avatarCache = {}
	function X.getAvatar(uid, cb)
		if avatarCache[uid] then
			cb(avatarCache[uid])
			return
		end
		task.spawn(function()
			local ok, url = pcall(function()
				return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			end)
			if ok and url then
				avatarCache[uid] = url
				cb(url)
			end
		end)
	end

	-- видимость за стеной
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	function X.visibleTo(char, from)
		local head = char:FindFirstChild("Head") or char.PrimaryPart
		if not head then return false end
		rp.FilterDescendantsInstances = { char, LP.Character }
		return Workspace:Raycast(from, head.Position - from, rp) == nil
	end
end

----------------------------------------------------------------
-- Роли MM2: инструменты Knife / Gun + данные игры (если доступны)
----------------------------------------------------------------
local ROLE_COL = { Murderer = Color3.fromRGB(255, 70, 70), Sheriff = Color3.fromRGB(70, 140, 255) }
X.ROLE_COL = ROLE_COL

do
	local R = {
		cache = setmetatable({}, { __mode = "k" }), data = {}, dataT = 0,
		rf = nil, ev = nil, busy = false, findAt = 0,
	}
	local function hasTool(plr, n)
		local c, b = plr.Character, plr:FindFirstChild("Backpack")
		return (c and c:FindFirstChild(n)) or (b and b:FindFirstChild(n)) or nil
	end
	-- разбор таблицы ролей { [ник] = { Role = "Murderer", ... } }
	local function parse(t)
		if type(t) ~= "table" then return end
		local out, any = {}, false
		for name, info in pairs(t) do
			if type(name) == "string" and type(info) == "table" and type(info.Role) == "string" then
				local role = info.Role
				if role == "Hero" then role = "Sheriff" end
				if role == "Murderer" or role == "Sheriff" then out[name] = role end
				any = true
			end
		end
		if any then
			R.data = out
			R.dataT = os.clock()
		end
	end

	function X.roleOf(plr)
		local now = os.clock()
		local c = R.cache[plr]
		if c and now - c.t < .3 then return c.r end
		local r
		if hasTool(plr, "Knife") then
			r = "Murderer"
		elseif hasTool(plr, "Gun") then
			r = "Sheriff"
		elseif CFG.esp.sync and now - R.dataT < 20 then
			r = R.data[plr.Name]
		end
		r = r or "Innocent"
		if c then
			c.r, c.t = r, now
		else
			R.cache[plr] = { r = r, t = now }
		end
		return r
	end

	-- синхронизация с данными игры (редко, только если ESP включён)
	task.spawn(function()
		while alive do
			if CFG.esp.sync and CFG.esp.on then
				pcall(function()
					local now = os.clock()
					if (not R.ev or not R.rf) and now >= R.findAt then
						R.findAt = now + 15
						if not R.ev then
							local ev = ReplicatedStorage:FindFirstChild("PlayerDataChanged", true)
							if ev and ev:IsA("RemoteEvent") then
								R.ev = ev
								track(ev.OnClientEvent:Connect(function(a) parse(a) end))
							end
						end
						if not R.rf then
							local rf = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
							if rf and rf:IsA("RemoteFunction") then R.rf = rf end
						end
					end
					if R.rf and not R.busy then
						R.busy = true
						task.spawn(function()
							local ok, res = pcall(function() return R.rf:InvokeServer() end)
							if ok then parse(res) end
							R.busy = false
						end)
					end
				end)
			end
			task.wait(4)
		end
	end)
end

-- фильтр «ESP for...»
function X.passTarget(plr, role)
	local m = CFG.target.mode
	if m == "All" then return true end
	if m == "Murder" then return role == "Murderer" end
	if m == "Sheriff" then return role == "Sheriff" end
	return plr.UserId == CFG.target.userId
end

----------------------------------------------------------------
-- Единый покадровый цикл (после камеры => без дрожания ESP)
----------------------------------------------------------------
do
	local frameFns, warned = {}, {}
	function X.addFrame(fn) frameFns[#frameFns + 1] = fn end
	RunService:BindToRenderStep("NH_MAIN", Enum.RenderPriority.Camera.Value + 2, function(dt)
		for i = 1, #frameFns do
			local ok, err = pcall(frameFns[i], dt)
			if not ok and not warned[i] then
				warned[i] = true
				warn("[NurHub] frame #" .. i .. ": " .. tostring(err))
			end
		end
	end)
end

----------------------------------------------------------------
-- ОКНО: слева основное меню, справа «ESP Editor» (предпросмотр)
----------------------------------------------------------------
local MAIN_W, H, SIDE, PREV_W, GAP = 660, 470, 150, 252, 12
local FULL_W = MAIN_W + GAP + PREV_W
local PROF_H = 52

local gui = new("ScreenGui", {
	Name = "NurHubMM2_UI", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
mount(gui)

local Root = new("Frame", {
	Name = "Root", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromOffset(FULL_W, H), BackgroundTransparency = 1, Visible = false,
}, gui)
local fitScale = new("UIScale", { Scale = 1 }, Root)
local Anim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, Root)
local animScale = new("UIScale", { Scale = .9 }, Anim)

local Main = new("CanvasGroup", {
	Size = UDim2.fromOffset(MAIN_W, H), BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1,
}, Anim)
corner(Main, 16)
stroke(Main, C.line, 1)

local Preview = new("CanvasGroup", {
	Position = UDim2.fromOffset(MAIN_W + GAP, 0), Size = UDim2.fromOffset(PREV_W, H),
	BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1, Visible = false,
}, Anim)
corner(Preview, 16)
stroke(Preview, C.line, 1)

-- масштаб под размер экрана (телефон / маленькие окна)
local function fit()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local vs = cam.ViewportSize
	fitScale.Scale = math.clamp(math.min((vs.X - 24) / FULL_W, (vs.Y - 24) / H), 0.35, 1) * X.SET.scale
end
do
	local camConn
	local function hook()
		if camConn then camConn:Disconnect() camConn = nil end
		local cam = Workspace.CurrentCamera
		if cam then camConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
		fit()
	end
	hook()
	track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hook))
	track({ Disconnect = function() if camConn then camConn:Disconnect() end end })
end

----------------------------------------------------------------
-- Менеджер перетаскивания (одно подключение на все ползунки/окно)
----------------------------------------------------------------
local Drag = {}
track(UIS.InputChanged:Connect(function(i)
	local f = Drag.fn
	if f and isMove(i) then f(i) end
end))
track(UIS.InputEnded:Connect(function(i)
	if Drag.fn and isPress(i) then
		local stop = Drag.stop
		Drag.fn, Drag.stop = nil, nil
		if stop then pcall(stop) end
	end
end))
local function beginDrag(fn, stop)
	if Drag.stop then pcall(Drag.stop) end
	Drag.fn, Drag.stop = fn, stop
end
-- блокирует прокрутку всех родительских ScrollingFrame на время перетаскивания
local function lockScroll(inst)
	local list = {}
	local p = inst.Parent
	while p do
		if p:IsA("ScrollingFrame") and p.ScrollingEnabled then
			p.ScrollingEnabled = false
			list[#list + 1] = p
		end
		p = p.Parent
	end
	return function()
		for _, s in ipairs(list) do s.ScrollingEnabled = true end
	end
end

-- не даём окну/кнопке уехать за экран
local function keepOnScreen(target, k)
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local vs = cam.ViewportSize
	local ap, as = target.AbsolutePosition, target.AbsoluteSize
	local dx, dy = 0, 0
	if ap.X + as.X < 60 then
		dx = 60 - (ap.X + as.X)
	elseif ap.X > vs.X - 60 then
		dx = (vs.X - 60) - ap.X
	end
	if ap.Y < 0 then
		dy = -ap.Y
	elseif ap.Y > vs.Y - 40 then
		dy = (vs.Y - 40) - ap.Y
	end
	if dx ~= 0 or dy ~= 0 then
		local p = target.Position
		target.Position = UDim2.new(p.X.Scale, p.X.Offset + dx / k, p.Y.Scale, p.Y.Offset + dy / k)
	end
end

-- перетаскивание за указанную область (с поправкой на UIScale)
local function makeDraggable(handle, target, onClick, scaleObj)
	handle.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		local moved = false
		local startMouse, startPos = i.Position, target.Position
		beginDrag(function(m)
			local d = m.Position - startMouse
			if d.Magnitude > 5 then moved = true end
			if moved then
				local k = scaleObj and scaleObj.Scale or 1
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X / k, startPos.Y.Scale, startPos.Y.Offset + d.Y / k)
			end
		end, function()
			if moved then
				keepOnScreen(target, scaleObj and scaleObj.Scale or 1)
			elseif onClick then
				onClick()
			end
		end)
	end)
end

----------------------------------------------------------------
-- Иконки из Frame
----------------------------------------------------------------
local function Icon(kind, parent, size)
	local box = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1,
	}, parent)
	new("UIScale", { Scale = (size or 20) / 20 }, box)
	local ss, ff = {}, {}
	local function ring(w, h, x, y, th, rad)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
			BackgroundTransparency = 1, BorderSizePixel = 0,
		}, box)
		corner(f, rad or math.max(w, h) / 2)
		ss[#ss + 1] = stroke(f, WHITE, th or 2)
	end
	local function solid(w, h, x, y, rot, rad)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
			Rotation = rot or 0, BackgroundColor3 = WHITE, BorderSizePixel = 0,
		}, box)
		if rad then corner(f, rad) end
		ff[#ff + 1] = f
	end
	if kind == "eye" then
		ring(18, 12, 10, 10, 2); solid(6, 6, 10, 10, 0, 3)
	elseif kind == "info" then
		ring(16, 16, 10, 10, 2); solid(2, 2, 10, 6, 0, 1); solid(2, 6, 10, 12)
	elseif kind == "user" then
		ring(8, 8, 10, 6, 2); ring(16, 9, 10, 15, 2, 4)
	elseif kind == "globe" then
		ring(17, 17, 10, 10, 2); solid(17, 2, 10, 10); ring(7, 17, 10, 10, 2)
	elseif kind == "grid" then
		solid(7, 7, 5, 5, 0, 2); solid(7, 7, 15, 5, 0, 2); solid(7, 7, 5, 15, 0, 2); solid(7, 7, 15, 15, 0, 2)
	elseif kind == "cfg" then
		ring(17, 17, 10, 10, 2, 4); solid(9, 2, 10, 7); solid(9, 2, 10, 10); solid(9, 2, 10, 13)
	elseif kind == "gear" then
		ring(11, 11, 10, 10, 2); solid(3, 20, 10, 10, 0, 1); solid(20, 3, 10, 10, 0, 1)
	elseif kind == "target" then
		ring(14, 14, 10, 10, 2); solid(2, 5, 10, 2); solid(2, 5, 10, 18); solid(5, 2, 2, 10); solid(5, 2, 18, 10)
	elseif kind == "emote" then
		ring(17, 17, 10, 10, 2); solid(3, 3, 7, 8, 0, 1); solid(3, 3, 13, 8, 0, 1); solid(8, 2, 10, 14, 0, 1)
	elseif kind == "gun" then
		solid(16, 5, 9, 7, 0, 1); solid(5, 10, 6, 13, -12, 1); solid(5, 3, 13, 11, 0, 1)
	elseif kind == "knife" then
		solid(17, 4, 11, 8, -42, 2); solid(4, 8, 4, 16, -42, 1); solid(8, 2, 6, 12, -42, 1)
	elseif kind == "items" then
		ring(17, 13, 10, 12, 2, 3); solid(17, 2, 10, 6, 0, 1); solid(4, 3, 10, 11, 0, 1)
	elseif kind == "stats" then
		solid(4, 8, 4, 15, 0, 1); solid(4, 13, 10, 12, 0, 1); solid(4, 17, 16, 10, 0, 1)
	end
	local api = {}
	function api.paint(col, t)
		for _, s in ipairs(ss) do tw(s, t or .2, { Color = col }) end
		for _, f in ipairs(ff) do tw(f, t or .2, { BackgroundColor3 = col }) end
	end
	api.paint(C.sub, 0)
	return api
end

local function Arrow(parent, pos)
	local c = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = pos, Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1,
	}, parent)
	for _, d in ipairs({ { 3.5, 45 }, { 8.5, -45 } }) do
		corner(new("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(d[1], 6), Size = UDim2.fromOffset(7, 2),
			Rotation = d[2], BackgroundColor3 = C.sub, BorderSizePixel = 0,
		}, c), 1)
	end
	return c
end

----------------------------------------------------------------
-- Боковое меню: шапка, группы, профиль внизу
----------------------------------------------------------------
local Side = new("Frame", { Size = UDim2.new(0, SIDE, 1, 0), BackgroundColor3 = C.side, BorderSizePixel = 0 }, Main)
new("Frame", { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C.line, BorderSizePixel = 0 }, Side)
new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 20), Size = UDim2.new(1, -20, 0, 26),
	Font = Enum.Font.GothamBlack, Text = "NURHUB", TextSize = 21, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left,
}, Side)
new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 46), Size = UDim2.new(1, -20, 0, 14),
	Font = Enum.Font.GothamMedium, Text = "visual  •  v" .. VERSION .. " MM2", TextSize = 10, TextColor3 = C.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
}, Side)
local dragZone = new("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1 }, Side)
makeDraggable(dragZone, Root, nil, fitScale)
local dragTop = new("Frame", { Position = UDim2.fromOffset(SIDE, 0), Size = UDim2.new(1, -SIDE, 0, 12), BackgroundTransparency = 1 }, Main)
makeDraggable(dragTop, Root, nil, fitScale)

local navList = new("ScrollingFrame", {
	Position = UDim2.fromOffset(0, 72), Size = UDim2.new(1, 0, 1, -(72 + PROF_H + 16)), BackgroundTransparency = 1,
	BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
}, Side)
new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, navList)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, navList)

-- профиль игрока (внизу): аватар, ник, юзернейм
do
	local prof = new("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, PROF_H),
		BackgroundColor3 = C.card, BorderSizePixel = 0,
	}, Side)
	corner(prof, 12)
	stroke(prof, C.line, 1)
	local avBox = new("Frame", {
		Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = C.field, BorderSizePixel = 0,
	}, prof)
	corner(avBox, 17)
	local avImg = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, avBox)
	corner(avImg, 17)
	X.getAvatar(LP.UserId, function(u) if avImg.Parent then avImg.Image = u end end)
	local dot = new("Frame", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromOffset(46, 46), Size = UDim2.fromOffset(11, 11),
		BackgroundColor3 = C.good, BorderSizePixel = 0,
	}, prof)
	corner(dot, 6)
	stroke(dot, C.card, 2)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(52, 8), Size = UDim2.new(1, -58, 0, 18),
		Font = Enum.Font.GothamBold, Text = LP.DisplayName, TextSize = 12, TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, prof)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(52, 26), Size = UDim2.new(1, -58, 0, 16),
		Font = Enum.Font.GothamMedium, Text = "@" .. LP.Name, TextSize = 10, TextColor3 = C.sub,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, prof)
end

local Content = new("Frame", {
	Position = UDim2.new(0, SIDE + 14, 0, 14), Size = UDim2.new(1, -(SIDE + 28), 1, -28), BackgroundTransparency = 1,
}, Main)

----------------------------------------------------------------
-- Вкладки и группы
----------------------------------------------------------------
local tabs, pages, ptok = {}, {}, {}
local current
local onTabChanged

-- сворачиваемая группа в боковом меню
local function createGroup(title, open)
	local g = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = ord(),
	}, navList)
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, g)
	local head = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 0,
	}, g)
	local lbl = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -24, 1, 0),
		Font = Enum.Font.GothamBold, Text = string.upper(title), TextSize = 10, TextColor3 = C.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, head)
	lbl:SetAttribute("en", title)
	lbl:SetAttribute("up", true)
	local arrow = Arrow(head, UDim2.new(1, -12, .5, 0))
	arrow.Rotation = open and 180 or 0
	local box = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = 1, Visible = open,
	}, g)
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, box)
	local grp = { box = box }
	function grp.set(v)
		box.Visible = v
		tw(arrow, .22, { Rotation = v and 180 or 0 })
	end
	head.MouseButton1Click:Connect(function() grp.set(not box.Visible) end)
	return grp
end

local function paintTab(name, sel, anim)
	local t = tabs[name]
	local d = anim and .22 or 0
	tw(t.btn, d, { BackgroundTransparency = sel and 0 or 1 })
	tw(t.lbl, d, { TextColor3 = sel and WHITE or C.sub })
	t.icon.paint(sel and WHITE or C.sub, d)
end

local function switchTab(name)
	if name == current or not pages[name] then return end
	local prev = current
	current = name
	ptok[prev] = (ptok[prev] or 0) + 1
	local my = ptok[prev]
	local old, nxt = pages[prev], pages[name]
	local g = tabs[name].grp
	if g and not g.box.Visible then g.set(true) end
	tw(old, .18, { GroupTransparency = 1, Position = UDim2.new(0, 0, 0, -12) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(.2, function()
		if ptok[prev] == my and current ~= prev then old.Visible = false end
	end)
	nxt.Position = UDim2.new(0, 0, 0, 22)
	nxt.GroupTransparency = 1
	nxt.Visible = true
	tw(nxt, .45, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
	for n in pairs(tabs) do paintTab(n, n == name, true) end
	if onTabChanged then onTabChanged(name) end
end

-- страница: заголовок + прокрутка, возвращает ScrollingFrame
local function createTab(name, iconKind, sub, grp)
	local btn = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.accent, BackgroundTransparency = 1,
		BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = ord(),
	}, grp and grp.box or navList)
	corner(btn, 10)
	new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2), Rotation = 0 }, btn)
	local holder = new("Frame", { Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1 }, btn)
	local icon = Icon(iconKind, holder, 18)
	local lbl = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -40, 1, 0),
		Font = Enum.Font.GothamMedium, Text = name, TextSize = 13, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, btn)
	tabs[name] = { btn = btn, lbl = lbl, icon = icon, grp = grp }
	btn.MouseEnter:Connect(function()
		if current ~= name then tw(lbl, .15, { TextColor3 = C.text }); icon.paint(C.text, .15) end
	end)
	btn.MouseLeave:Connect(function()
		if current ~= name then tw(lbl, .15, { TextColor3 = C.sub }); icon.paint(C.sub, .15) end
	end)
	btn.MouseButton1Click:Connect(function() switchTab(name) end)

	local cg = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 }, Content)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, RichText = true,
		TextSize = 16, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = name .. ' <font color="rgb(135,133,158)">· ' .. sub .. "</font>",
	}, cg)
	local sf = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 1, -32), BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.accent, ScrollingDirection = Enum.ScrollingDirection.Y,
	}, cg)
	new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12), PaddingTop = UDim.new(0, 2) }, sf)
	pages[name] = cg
	X.curTab = name
	X.pageSF[name] = sf
	return sf
end

-- две колонки внутри страницы
local function Columns(sf)
	local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, sf)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12),
		VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)
	local function col(o)
		local c = new("Frame", {
			Size = UDim2.new(.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = o,
		}, holder)
		new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, c)
		return c
	end
	return col(1), col(2)
end

----------------------------------------------------------------
-- Компоненты
----------------------------------------------------------------
local ROW = 28

local function Card(parent, title)
	local outer = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = ord(),
	}, parent)
	new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, outer)
	if title then
		local t = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 1, Font = Enum.Font.GothamBold,
			Text = string.upper(title), TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
		}, outer)
		t:SetAttribute("en", title)
		t:SetAttribute("up", true)
		new("UIPadding", { PaddingLeft = UDim.new(0, 3) }, t)
	end
	local panel = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.card,
		BorderSizePixel = 0, LayoutOrder = 2,
	}, outer)
	corner(panel, 10)
	X.regT(panel)
	stroke(panel, C.line, 1)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
	}, panel)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
	return panel
end

local function Label(parent, text, color, size)
	return new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham, TextSize = size or 12, TextColor3 = color or C.sub, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, Text = text, LayoutOrder = ord(),
	}, parent)
end

-- маленькая подпись фиксированной высоты (для шторок)
X.FLabel = function(parent, text)
	return new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 12), Font = Enum.Font.GothamMedium, Text = text,
		TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = ord(),
	}, parent)
end

local function Button(parent, text, cb, fill)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = fill or C.drawer, BorderSizePixel = 0, AutoButtonColor = false,
		Font = Enum.Font.GothamBold, Text = text, TextSize = 12, TextColor3 = WHITE, LayoutOrder = ord(),
	}, parent)
	corner(b, 9)
	X.regSearch(text, b)
	if not fill then stroke(b, C.line, 1) end
	b.MouseEnter:Connect(function() tw(b, .15, { BackgroundColor3 = fill and fill:Lerp(WHITE, .12) or Color3.fromRGB(30, 29, 44) }) end)
	b.MouseLeave:Connect(function() tw(b, .15, { BackgroundColor3 = fill or C.drawer }) end)
	b.MouseButton1Click:Connect(function() if cb then cb(b) end end)
	return b
end

-- ползунок привязан к полю таблицы (opts.div — делитель, opts.fmt — формат)
local function Slider(parent, title, min, max, tbl, key, opts)
	opts = opts or {}
	local div = opts.div or 1
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = ord() }, parent)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(.62, 0, 0, 16), Font = Enum.Font.GothamMedium, Text = title,
		TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local val = new("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(.38, 0, 0, 16), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)
	local bar = new("Frame", { Position = UDim2.fromOffset(0, 23), Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = C.track, BorderSizePixel = 0 }, row)
	corner(bar, 3)
	local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, bar)
	corner(fill, 3)
	new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, fill)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(1, 0, .5, 0), Size = UDim2.fromOffset(13, 13),
		BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, fill)
	corner(knob, 7)
	local hit = new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 24),
	}, row)

	local function show()
		local v = tbl[key]
		fill.Size = UDim2.new(math.clamp((v * div - min) / (max - min), 0, 1), 0, 1, 0)
		val.Text = opts.fmt and opts.fmt(v) or tostring(v)
	end
	show()
	X.reg(show)
	X.regSearch(title, row)
	local function upd(i)
		local p = math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		tbl[key] = math.floor(min + (max - min) * p + .5) / div
		show()
	end
	hit.InputBegan:Connect(function(i)
		if isPress(i) then
			local unlock = lockScroll(hit)
			upd(i)
			beginDrag(upd, unlock)
		end
	end)
end

-- HSV-палитра с оттенками: быстрые цвета + Hue / Saturation / Brightness
local QUICK = {
	Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 70, 85), Color3.fromRGB(255, 190, 50),
	Color3.fromRGB(80, 235, 130), Color3.fromRGB(70, 215, 255), Color3.fromRGB(80, 120, 255),
	Color3.fromRGB(170, 100, 255), Color3.fromRGB(255, 100, 200),
}
local function ColorBar(parent, label, onChange)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = ord() }, parent)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), Font = Enum.Font.GothamMedium, Text = label,
		TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local bar = new("TextButton", {
		Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, row)
	corner(bar, 4)
	local grad = new("UIGradient", {}, bar)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 0, .5, 0), Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, bar)
	corner(knob, 6)
	stroke(knob, Color3.fromRGB(18, 18, 24), 2)
	local function upd(i)
		onChange(math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1))
	end
	bar.InputBegan:Connect(function(i)
		if isPress(i) then
			local unlock = lockScroll(bar)
			upd(i)
			beginDrag(upd, unlock)
		end
	end)
	return { grad = grad, set = function(a) tw(knob, .06, { Position = UDim2.new(a, 0, .5, 0) }) end }
end

local function ColorPicker(parent, tbl, key)
	local h, s, v = tbl[key]:ToHSV()
	local top = new("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = ord() }, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	}, top)
	local prev = new("Frame", { Size = UDim2.fromOffset(26, 16), BorderSizePixel = 0, LayoutOrder = 0 }, top)
	corner(prev, 4)
	stroke(prev, Color3.fromRGB(70, 68, 92), 1)
	local hueB, satB, valB
	local function refresh()
		local c = Color3.fromHSV(h, s, v)
		prev.BackgroundColor3 = c
		satB.grad.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
		valB.grad.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(h, s, 1))
		hueB.set(h); satB.set(s); valB.set(v)
		return c
	end
	for i, c in ipairs(QUICK) do
		local b = new("TextButton", {
			Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(14, 14), BackgroundColor3 = c, BorderSizePixel = 0, LayoutOrder = i,
		}, top)
		corner(b, 4)
		stroke(b, Color3.fromRGB(60, 58, 80), 1)
		b.MouseButton1Click:Connect(function()
			h, s, v = c:ToHSV()
			tbl[key] = refresh()
		end)
	end
	hueB = ColorBar(parent, "Hue", function(a) h = math.min(a, .999); tbl[key] = refresh() end)
	satB = ColorBar(parent, "Saturation", function(a) s = a; tbl[key] = refresh() end)
	valB = ColorBar(parent, "Brightness", function(a) v = a; tbl[key] = refresh() end)
	local keys = {}
	for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, .999), 1, 1)) end
	hueB.grad.Color = ColorSequence.new(keys)
	refresh()
	X.reg(function() h, s, v = tbl[key]:ToHSV(); refresh() end)
	return { set = function(c) h, s, v = c:ToHSV(); refresh() end }
end

-- палитра градиентов: готовые пары + два редактируемых цвета
local GRADS = {
	{ Color3.fromRGB(12, 12, 20), Color3.fromRGB(150, 110, 255) },
	{ Color3.fromRGB(255, 80, 100), Color3.fromRGB(255, 190, 70) },
	{ Color3.fromRGB(40, 220, 160), Color3.fromRGB(60, 140, 255) },
	{ Color3.fromRGB(255, 255, 255), Color3.fromRGB(70, 70, 90) },
	{ Color3.fromRGB(255, 100, 200), Color3.fromRGB(110, 90, 255) },
	{ Color3.fromRGB(0, 0, 0), Color3.fromRGB(230, 230, 240) },
}
local function GradientPicker(parent, tbl, k1, k2)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = ord() }, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5),
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	X.FLabel(parent, "Top color")
	local p1 = ColorPicker(parent, tbl, k1)
	X.FLabel(parent, "Bottom color")
	local p2 = ColorPicker(parent, tbl, k2)
	for i, g in ipairs(GRADS) do
		local b = new("TextButton", {
			Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(24, 20), BackgroundColor3 = WHITE,
			BorderSizePixel = 0, LayoutOrder = i,
		}, row)
		corner(b, 5)
		stroke(b, Color3.fromRGB(60, 58, 80), 1)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(g[1], g[2]) }, b)
		b.MouseButton1Click:Connect(function()
			tbl[k1], tbl[k2] = g[1], g[2]
			p1.set(g[1]); p2.set(g[2])
		end)
	end
end

-- выпадающий список (раскрывается внутри панели)
local function Dropdown(parent, title, list, tbl, key)
	local IT, GAPY = 22, 2
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = ord(),
	}, parent)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.GothamMedium, Text = title,
		TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, holder)
	local head = new("TextButton", {
		Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.field, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "",
	}, holder)
	corner(head, 6)
	stroke(head, C.line, 1)
	local curLbl = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0),
		Font = Enum.Font.GothamMedium, Text = tbl[key], TextSize = 12, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, head)
	local arrow = Arrow(head, UDim2.new(1, -14, .5, 0))
	local listH = #list * IT + (#list - 1) * GAPY + 8
	local box = new("Frame", {
		Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, listH), BackgroundColor3 = C.field, BorderSizePixel = 0,
	}, holder)
	corner(box, 6)
	stroke(box, C.line, 1)
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, box)
	new("UIListLayout", { Padding = UDim.new(0, GAPY), SortOrder = Enum.SortOrder.LayoutOrder }, box)
	local btns, open = {}, false
	local function render()
		curLbl.Text = tbl[key]
		for n, b in pairs(btns) do b.TextColor3 = (n == tbl[key]) and WHITE or C.sub end
	end
	local function setOpen(v)
		open = v
		tw(holder, .25, { Size = UDim2.new(1, 0, 0, v and (46 + listH) or 44) })
		tw(arrow, .25, { Rotation = v and 180 or 0 })
	end
	for i, n in ipairs(list) do
		local b = new("TextButton", {
			Size = UDim2.new(1, 0, 0, IT), BackgroundColor3 = C.accent, BackgroundTransparency = 1, AutoButtonColor = false,
			Text = n, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0, LayoutOrder = i,
		}, box)
		corner(b, 5)
		new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, b)
		btns[n] = b
		b.MouseEnter:Connect(function() tw(b, .12, { BackgroundTransparency = .75 }) end)
		b.MouseLeave:Connect(function() tw(b, .12, { BackgroundTransparency = 1 }) end)
		b.MouseButton1Click:Connect(function()
			tbl[key] = n
			render()
			setOpen(false)
		end)
	end
	head.MouseButton1Click:Connect(function() setOpen(not open) end)
	render()
	X.reg(render)
end

-- шторка с прокруткой внутри (если настроек много)
X.attachDrawer = function(box, head, arrowPos, builder)
	local arrow = Arrow(head, arrowPos)
	local drawer = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, ROW + 6), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = C.drawer,
		BorderSizePixel = 0, CanvasSize = UDim2.new(), ScrollBarThickness = 4, ScrollBarImageColor3 = C.accent,
		ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
	}, box)
	corner(drawer, 8)
	stroke(drawer, C.line, 1)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, drawer)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12),
	}, drawer)
	local open = false
	local function calc()
		local h, n = 0, 0
		for _, c in ipairs(drawer:GetChildren()) do
			if c:IsA("GuiObject") and c.Visible then
				h += c.Size.Y.Offset
				n += 1
			end
		end
		local ch = h + math.max(n - 1, 0) * 8 + 18
		local vh = math.min(ch, 210)
		drawer.CanvasSize = UDim2.fromOffset(0, ch)
		drawer.Size = UDim2.new(1, 0, 0, vh)
		return ROW + 6 + vh + 2
	end
	local function resize()
		local target = calc()
		if open then tw(box, .22, { Size = UDim2.new(1, 0, 0, target) }) end
	end
	local function hook(c)
		if c:IsA("GuiObject") then
			c:GetPropertyChangedSignal("Size"):Connect(resize)
			c:GetPropertyChangedSignal("Visible"):Connect(resize)
		end
	end
	local pv = X.inDrawer
	X.inDrawer = true
	builder(drawer)
	X.inDrawer = pv
	for _, c in ipairs(drawer:GetChildren()) do hook(c) end
	drawer.ChildAdded:Connect(function(c) hook(c); resize() end)
	head.MouseButton1Click:Connect(function()
		open = not open
		local target = calc()
		tw(box, .35, { Size = UDim2.new(1, 0, 0, open and target or ROW) })
		tw(arrow, .28, { Rotation = open and 180 or 0 })
	end)
end

-- переключатель привязан к tbl[key]; со стрелкой и шторкой, если есть builder(drawer)
local function Toggle(parent, title, tbl, key, builder)
	local box = new("Frame", {
		Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = ord(),
	}, parent)
	local head = new("TextButton", { Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, box)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -90, 1, 0), Font = Enum.Font.GothamMedium, Text = title,
		TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, head)
	local sw = new("TextButton", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, 0, 0, ROW / 2), Size = UDim2.fromOffset(36, 18),
		BorderSizePixel = 0, AutoButtonColor = false, Text = "", BackgroundColor3 = C.off,
	}, box)
	corner(sw, 9)
	local swGrad = new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2), Enabled = false }, sw)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, .5), Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 3, .5, 0),
		BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, sw)
	corner(knob, 6)
	local function paint(anim)
		local on = tbl[key]
		local d = anim and .2 or 0
		swGrad.Enabled = on
		tw(sw, d, { BackgroundColor3 = on and WHITE or C.off })
		tw(knob, d, { Position = on and UDim2.new(1, -15, .5, 0) or UDim2.new(0, 3, .5, 0) }, Enum.EasingStyle.Back)
	end
	paint(false)
	X.reg(function() paint(true) end)
	X.regSearch(title, box)
	sw.MouseButton1Click:Connect(function()
		tbl[key] = not tbl[key]
		paint(true)
	end)

	if builder then
		X.attachDrawer(box, head, UDim2.new(1, -52, .5, 0), builder)
	else
		head.MouseButton1Click:Connect(function()
			tbl[key] = not tbl[key]
			paint(true)
		end)
	end
end

-- строка-шторка без переключателя
X.DrawerRow = function(parent, title, builder)
	local box = new("Frame", {
		Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = ord(),
	}, parent)
	local head = new("TextButton", { Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, box)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -30, 1, 0), Font = Enum.Font.GothamMedium, Text = title,
		TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, head)
	X.regSearch(title, box)
	X.attachDrawer(box, head, UDim2.new(1, -10, .5, 0), builder)
end

-- сетка кнопок-вариантов (шейдеры, чипы и т.п.)
X.Grid = function(parent, list, get, set, cols)
	cols = cols or 2
	local rows = math.ceil(#list / cols)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, rows * 24 + (rows - 1) * 4), BackgroundTransparency = 1, LayoutOrder = ord(),
	}, parent)
	new("UIGridLayout", {
		CellSize = UDim2.new(1 / cols, -4 * (cols - 1) / cols - 1, 0, 24), CellPadding = UDim2.fromOffset(4, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)
	local btns = {}
	local function render()
		for n, b in pairs(btns) do
			local on = get() == n
			tw(b, .2, { BackgroundColor3 = on and C.accent or C.field, TextColor3 = on and WHITE or C.sub })
		end
	end
	for i, n in ipairs(list) do
		local b = new("TextButton", {
			Text = n, AutoButtonColor = false, Font = Enum.Font.GothamMedium, TextSize = 11, BorderSizePixel = 0,
			BackgroundColor3 = C.field, TextColor3 = C.sub, LayoutOrder = i,
		}, holder)
		corner(b, 6)
		btns[n] = b
		b.MouseButton1Click:Connect(function()
			set(n)
			render()
		end)
	end
	X.reg(render)
	render()
end

-- список игроков с аватаром и ником (ник шерифа синий, убийцы красный)
X.PlayerList = function(parent, height, onPick, withColor, isSel, ctbl)
	ctbl = ctbl or CFG.pcolor
	local sf = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = C.field, BorderSizePixel = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
		ScrollingDirection = Enum.ScrollingDirection.Y, LayoutOrder = ord(),
	}, parent)
	corner(sf, 8)
	stroke(sf, C.line, 1)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 6),
	}, sf)
	local rows = {}
	local function rebuild()
		for _, r in pairs(rows) do r.f:Destroy() end
		rows = {}
		local i = 0
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LP then
				i += 1
				local f = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.card, BorderSizePixel = 0, AutoButtonColor = false,
					Text = "", LayoutOrder = i,
				}, sf)
				corner(f, 8)
				local st = stroke(f, C.accent, 1.5, 1)
				local av = new("Frame", { Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = C.field, BorderSizePixel = 0 }, f)
				corner(av, 14)
				local img = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, av)
				corner(img, 14)
				X.getAvatar(plr.UserId, function(u) if img.Parent then img.Image = u end end)
				local nm = new("TextLabel", {
					BackgroundTransparency = 1, Position = UDim2.fromOffset(42, 0),
					Size = UDim2.new(1, -(withColor and 78 or 50), 1, 0), Font = Enum.Font.GothamMedium, TextSize = 12,
					TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
					Text = plr.DisplayName,
				}, f)
				local sw
				if withColor then
					sw = new("TextButton", {
						AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -6, .5, 0), Size = UDim2.fromOffset(22, 22),
						BorderSizePixel = 0, AutoButtonColor = false, Text = "", BackgroundColor3 = C.off,
					}, f)
					corner(sw, 11)
					stroke(sw, C.line, 1)
					sw.MouseButton1Click:Connect(function()
						local cur = ctbl[plr.UserId]
						local idx = 0
						for k, q in ipairs(QUICK) do
							if cur == q then idx = k end
						end
						idx += 1
						ctbl[plr.UserId] = QUICK[idx] -- после последнего цвета: сброс (nil)
					end)
				end
				f.MouseButton1Click:Connect(function() onPick(plr) end)
				rows[plr] = { f = f, nm = nm, st = st, sw = sw }
			end
		end
	end
	local function upd()
		for plr, r in pairs(rows) do
			r.nm.TextColor3 = ROLE_COL[X.roleOf(plr)] or C.text
			r.st.Transparency = (isSel and isSel(plr)) and 0 or 1
			if r.sw then r.sw.BackgroundColor3 = ctbl[plr.UserId] or C.off end
		end
	end
	rebuild()
	upd()
	X.lists[#X.lists + 1] = { rebuild = rebuild, upd = upd, frame = sf }
end

----------------------------------------------------------------
-- Рисование линий / стрелок (общее для ESP и превью)
----------------------------------------------------------------
local function mkLine(parent)
	return new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0, BackgroundColor3 = WHITE,
		Visible = false, Size = UDim2.fromOffset(0, 1),
	}, parent)
end
local function setLine(f, a, b, col, th)
	local d = b - a
	f.Size = UDim2.fromOffset(d.Magnitude, th)
	f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	f.Rotation = math.deg(math.atan2(d.Y, d.X))
	f.BackgroundColor3 = col
	f.Visible = true
end
local function hideList(l) if l then for _, f in ipairs(l) do f.Visible = false end end end

-- стрелка-указатель: цветной наконечник + белый хвост (из ровных срезов, без артефактов)
local function mkArrow(parent)
	local c = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(34, 28), BackgroundTransparency = 1, Visible = false,
	}, parent)
	local sc = new("UIScale", { Scale = 1 }, c)
	local N = 10
	local function tri(x0, w, h, col, tr, dx)
		local list = {}
		for i = 0, N - 1 do
			local fh = math.max(1, h * (1 - i / N))
			list[#list + 1] = new("Frame", {
				AnchorPoint = Vector2.new(0, .5), Position = UDim2.fromOffset(x0 + i * (w / N) + dx, 14 + dx),
				Size = UDim2.fromOffset(w / N + .7, fh), BackgroundColor3 = col, BackgroundTransparency = tr, BorderSizePixel = 0,
			}, c)
		end
		return list
	end
	local sh1, sh2 = tri(17, 16, 26, Color3.new(0, 0, 0), .55, 1), tri(2, 10, 16, Color3.new(0, 0, 0), .55, 1)
	local head, tail = tri(17, 16, 26, WHITE, 0, 0), tri(2, 10, 16, WHITE, 0, 0)
	return { frame = c, scale = sc, head = head, tail = tail, sh1 = sh1, sh2 = sh2 }
end
local function paintArrow(a, col, size, tailCol)
	tailCol = tailCol or WHITE
	if a.pc ~= col or a.pt ~= tailCol then
		a.pc, a.pt = col, tailCol
		for _, f in ipairs(a.head) do f.BackgroundColor3 = col end
		for _, f in ipairs(a.tail) do f.BackgroundColor3 = tailCol end
	end
	a.scale.Scale = size / 24
end

----------------------------------------------------------------
-- ESP слой (экранные Frame, без Drawing)
----------------------------------------------------------------
local espGui = new("ScreenGui", {
	Name = "NurHubMM2_ESP", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 50, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
mount(espGui)

local TH = 1.5
local function mkBox()
	return new("Frame", { BorderSizePixel = 0, BackgroundColor3 = WHITE, Visible = false }, espGui)
end
local function mkText()
	return new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(220, 14), Font = Enum.Font.GothamBold, TextSize = 11, TextScaled = false,
		TextStrokeTransparency = .35, TextStrokeColor3 = Color3.new(0, 0, 0), Visible = false,
	}, espGui)
end

local R15 = {
	{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local R6 = {
	{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
	{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}
local EDGES = {}
for i = 0, 7 do
	for _, b in ipairs({ 1, 2, 4 }) do
		if bit32.band(i, b) == 0 then EDGES[#EDGES + 1] = { i, i + b } end
	end
end

-- o: словарь объектов игрока (Instance или список Instance)
local function hideAll(o)
	for _, v in pairs(o) do
		if typeof(v) == "Instance" then
			if v:IsA("GuiObject") then
				v.Visible = false
			elseif v:IsA("Highlight") or v:IsA("Light") then
				v.Enabled = false
			end
		elseif type(v) == "table" then
			for _, f in ipairs(v) do
				if typeof(f) == "Instance" and f:IsA("GuiObject") then f.Visible = false end
			end
		end
	end
end
local function destroyData(o)
	for _, v in pairs(o) do
		if typeof(v) == "Instance" then
			pcall(function() v:Destroy() end)
		elseif type(v) == "table" then
			for _, x in ipairs(v) do
				if typeof(x) == "Instance" then pcall(function() x:Destroy() end) end
			end
		end
	end
end

-- уголки бокса: lx / ly — длина плеч по горизонтали / вертикали, t — толщина
local function setCorners(list, x0, y0, x1, y1, lx, ly, t, col)
	local spec = {
		{ x0, y0, lx, t }, { x0, y0, t, ly },
		{ x1 - lx, y0, lx, t }, { x1 - t, y0, t, ly },
		{ x0, y1 - t, lx, t }, { x0, y1 - ly, t, ly },
		{ x1 - lx, y1 - t, lx, t }, { x1 - t, y1 - ly, t, ly },
	}
	for i, s in ipairs(spec) do
		local f = list[i]
		f.Position = UDim2.fromOffset(s[1], s[2])
		f.Size = UDim2.fromOffset(s[3], s[4])
		f.BackgroundColor3 = col
		f.Visible = true
	end
end
-- доля длины плеча от стороны бокса (настройка Length в %), одинакова на любой дистанции
local function cornerRatio()
	return math.clamp(CFG.corner.len, 10, 50) / 100
end
X.cornerRatio = cornerRatio

local ESPS = {}

local function drawPlayer(d, plr, hum, root, cam, vs, ov, camPos, now)
	local o, char = d.o, d.char

	-- Chams + Outline + Wall check (Highlight)
	if CFG.chams.on or CFG.outline.on or CFG.wall.on then
		local hl = o.hl
		if not hl then
			hl = new("Highlight", { DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, espGui)
			o.hl = hl
		end
		hl.Adornee = char
		local fc, oc = ov or CFG.chams.color, ov or CFG.outline.color
		if CFG.wall.on then
			if now - (d.visT or 0) > .12 then
				d.visT = now
				d.vis = X.visibleTo(char, camPos)
			end
			local c2 = d.vis and CFG.wall.vis or CFG.wall.hid
			fc, oc = c2, c2
		end
		hl.FillColor = fc
		hl.FillTransparency = CFG.chams.on and CFG.chams.trans or 1
		hl.OutlineColor = oc
		hl.OutlineTransparency = (CFG.outline.on or CFG.wall.on) and 0 or 1
		hl.Enabled = true
	elseif o.hl then
		o.hl.Enabled = false
	end

	-- Glow (PointLight)
	if CFG.glow.on then
		local l = o.light
		if not l or l.Parent ~= root then
			if l then l:Destroy() end
			l = new("PointLight", { Shadows = false }, root)
			o.light = l
		end
		l.Color = CFG.glow.color
		l.Range = CFG.glow.range
		l.Brightness = CFG.glow.bright
		l.Enabled = true
	elseif o.light then
		o.light.Enabled = false
	end

	-- Стрелки (враг вне экрана)
	local rpv = cam:WorldToViewportPoint(root.Position)
	local off = rpv.Z <= 0 or rpv.X < 0 or rpv.X > vs.X or rpv.Y < 0 or rpv.Y > vs.Y
	if CFG.arrows.on and off then
		local a = d.arrow
		if not a then
			a = mkArrow(espGui)
			d.arrow = a
			o.arrowF = a.frame
		end
		local center = vs / 2
		local dir
		if rpv.Z > 0 then
			dir = Vector2.new(rpv.X, rpv.Y) - center
		else
			local v = cam.CFrame:PointToObjectSpace(root.Position)
			dir = Vector2.new(v.X, -v.Y)
		end
		if dir.Magnitude < 1e-3 then dir = Vector2.new(0, 1) end
		dir = dir.Unit
		local R = math.min(CFG.arrows.radius, math.min(vs.X, vs.Y) / 2 - 24)
		local pos = center + dir * R
		a.frame.Position = UDim2.fromOffset(pos.X, pos.Y)
		a.frame.Rotation = math.deg(math.atan2(dir.Y, dir.X))
		local rl = d.role
		local acol = CFG.acolor[plr.UserId] or (rl == "Murderer" and CFG.arrows.murder) or (rl == "Sheriff" and CFG.arrows.sheriff) or CFG.arrows.color
		paintArrow(a, acol, CFG.arrows.size, WHITE)
		a.frame.Visible = true
	elseif o.arrowF then
		o.arrowF.Visible = false
	end

	-- Границы персонажа (2D прямоугольник по верху/низу — только 2 проекции вместо 8)
	local needRect = CFG.box2d.on or CFG.corner.on or CFG.fill.on or CFG.name.on or CFG.dist.on or CFG.health.on or CFG.avatar.on
	local x0, y0, x1, y1 = 0, 0, 0, 0
	local rect = false
	if needRect then
		local rpos = root.Position
		local tp = cam:WorldToViewportPoint(rpos + Vector3.new(0, 2.7, 0))
		local bp = cam:WorldToViewportPoint(rpos - Vector3.new(0, 3.2, 0))
		if tp.Z > 0 and bp.Z > 0 then
			local hgt = math.abs(bp.Y - tp.Y)
			local cx = (tp.X + bp.X) / 2
			x0, x1 = cx - hgt * .28, cx + hgt * .28
			y0, y1 = math.min(tp.Y, bp.Y), math.max(tp.Y, bp.Y)
			rect = hgt > 1
		end
	end

	-- заливка (градиент)
	if CFG.fill.on and rect then
		local f = o.fill
		if not f then
			f = mkBox()
			o.fill = f
			d.fillG = new("UIGradient", { Rotation = 90 }, f)
		end
		f.Position = UDim2.fromOffset(x0, y0)
		f.Size = UDim2.fromOffset(x1 - x0, y1 - y0)
		f.BackgroundTransparency = CFG.fill.trans
		if d.fc1 ~= CFG.fill.c1 or d.fc2 ~= CFG.fill.c2 then
			d.fc1, d.fc2 = CFG.fill.c1, CFG.fill.c2
			d.fillG.Color = ColorSequence.new(d.fc1, d.fc2)
		end
		f.Visible = true
	elseif o.fill then
		o.fill.Visible = false
	end

	-- Box 2D
	if CFG.box2d.on and rect then
		local b = o.box
		if not b then
			b = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, espGui)
			o.box = b
			d.boxS = new("UIStroke", { Thickness = TH, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		end
		b.Position = UDim2.fromOffset(x0, y0)
		b.Size = UDim2.fromOffset(x1 - x0, y1 - y0)
		d.boxS.Color = ov or CFG.box2d.color
		b.Visible = true
	elseif o.box then
		o.box.Visible = false
	end

	-- Углы бокса: длина плеч = % от сторон бокса => растёт/уменьшается вместе с игроком
	if CFG.corner.on and rect then
		if not o.cn then
			o.cn = {}
			for i = 1, 8 do o.cn[i] = mkBox() end
		end
		local w, h = x1 - x0, y1 - y0
		local r = cornerRatio()
		setCorners(o.cn, x0, y0, x1, y1, w * r, h * r, 2, ov or CFG.corner.color)
	else
		hideList(o.cn)
	end

	-- Box 3D
	if CFG.box3d.on then
		local e3 = o.e3
		if not e3 then
			e3 = {}
			for i = 1, 12 do e3[i] = mkLine(espGui) end
			o.e3 = e3
		end
		local pts = d.pts
		if not pts then
			pts = {}
			d.pts = pts
		end
		local cf = root.CFrame * CFrame.new(0, -0.25, 0)
		for i = 0, 7 do
			local x = (i % 2) * 2 - 1
			local y = (math.floor(i / 2) % 2) * 2 - 1
			local z = math.floor(i / 4) * 2 - 1
			pts[i] = cam:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(x * 2, y * 2.95, z * 1)))
		end
		local col = ov or CFG.box3d.color
		for i, e in ipairs(EDGES) do
			local a, b = pts[e[1]], pts[e[2]]
			if a.Z > 0 and b.Z > 0 then
				setLine(e3[i], Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y), col, TH)
			else
				e3[i].Visible = false
			end
		end
	else
		hideList(o.e3)
	end

	-- Ник
	if CFG.name.on and rect then
		local t = o.name
		if not t then
			t = mkText()
			t.AnchorPoint = Vector2.new(.5, 1)
			o.name = t
		end
		t.Position = UDim2.fromOffset((x0 + x1) / 2, y0 - 2)
		local dn = plr.DisplayName
		if t.Text ~= dn then t.Text = dn end
		t.TextColor3 = CFG.name.color
		t.Visible = true
	elseif o.name then
		o.name.Visible = false
	end

	-- Аватар (круг с аватаркой рядом с игроком)
	if CFG.avatar.on and rect then
		local a = o.av
		if not a then
			a = new("Frame", {
				AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Color3.fromRGB(20, 20, 30),
				BorderSizePixel = 0, Visible = false,
			}, espGui)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, a)
			d.avS = new("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, a)
			local img = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, a)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, img)
			o.av = a
			X.getAvatar(plr.UserId, function(u) if img.Parent then img.Image = u end end)
		end
		a.Position = UDim2.fromOffset(x0 - 9, y0)
		d.avS.Color = ov or CFG.avatar.color
		a.Visible = true
	elseif o.av then
		o.av.Visible = false
	end

	-- Дистанция
	if CFG.dist.on and rect then
		local t = o.dist
		if not t then
			t = mkText()
			t.AnchorPoint = Vector2.new(.5, 0)
			o.dist = t
		end
		t.Position = UDim2.fromOffset((x0 + x1) / 2, y1 + 2)
		t.Text = math.floor((camPos - root.Position).Magnitude) .. "m"
		t.TextColor3 = CFG.dist.color
		t.Visible = true
	elseif o.dist then
		o.dist.Visible = false
	end

	-- Здоровье
	if CFG.health.on and rect then
		local bg = o.hpBg
		if not bg then
			bg = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .35, BorderSizePixel = 0, Visible = false }, espGui)
			o.hpBg = bg
			d.hpFill = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, bg)
		end
		local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		bg.Position = UDim2.fromOffset(x0 - 5, y0)
		bg.Size = UDim2.fromOffset(2, y1 - y0)
		d.hpFill.Size = UDim2.fromScale(1, frac)
		d.hpFill.BackgroundColor3 = CFG.health.color
		bg.Visible = true
	elseif o.hpBg then
		o.hpBg.Visible = false
	end

	-- Голова (кольцо)
	local head = d.head
	if CFG.head.on then
		if not head or not head.Parent then
			head = char:FindFirstChild("Head")
			d.head = head
		end
	end
	if CFG.head.on and head then
		local hp = cam:WorldToViewportPoint(head.Position)
		if hp.Z > 0 then
			local up = cam.CFrame.UpVector * (head.Size.Y / 2)
			local pt = cam:WorldToViewportPoint(head.Position + up)
			local pb = cam:WorldToViewportPoint(head.Position - up)
			local diam = math.max(6, math.abs(pt.Y - pb.Y))
			local r = o.ring
			if not r then
				r = new("Frame", { AnchorPoint = Vector2.new(.5, .5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, espGui)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, r)
				d.ringS = new("UIStroke", { Thickness = TH, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, r)
				o.ring = r
			end
			r.Position = UDim2.fromOffset(hp.X, hp.Y)
			r.Size = UDim2.fromOffset(diam, diam)
			d.ringS.Color = ov or CFG.head.color
			r.Visible = true
		elseif o.ring then
			o.ring.Visible = false
		end
	elseif o.ring then
		o.ring.Visible = false
	end

	-- Skeleton (кости кэшируются, не ищутся каждый кадр)
	if CFG.skel.on then
		if not o.sk then
			o.sk = {}
			for i = 1, 14 do o.sk[i] = mkLine(espGui) end
		end
		if not d.bones or d.bonesChar ~= char or now - (d.bonesT or 0) > 2 then
			local list = hum.RigType == Enum.HumanoidRigType.R15 and R15 or R6
			local bones = {}
			for i, pr in ipairs(list) do
				bones[i] = { char:FindFirstChild(pr[1]), char:FindFirstChild(pr[2]) }
			end
			d.bones, d.bonesChar, d.bonesT = bones, char, now
		end
		local col = ov or CFG.skel.color
		for i = 1, 14 do
			local pr, line = d.bones[i], o.sk[i]
			if pr and pr[1] and pr[2] and pr[1].Parent and pr[2].Parent then
				local pa = cam:WorldToViewportPoint(pr[1].Position)
				local pb = cam:WorldToViewportPoint(pr[2].Position)
				if pa.Z > 0 and pb.Z > 0 then
					setLine(line, Vector2.new(pa.X, pa.Y), Vector2.new(pb.X, pb.Y), col, TH)
				else
					line.Visible = false
				end
			else
				line.Visible = false
			end
		end
	else
		hideList(o.sk)
	end

	-- Tracers
	if CFG.tracer.on and rpv.Z > 0 then
		local org = Vector2.new(vs.X / 2, vs.Y)
		if CFG.tracer.origin == "Top" then
			org = Vector2.new(vs.X / 2, 0)
		elseif CFG.tracer.origin == "Crosshair" then
			org = Vector2.new(vs.X / 2, vs.Y / 2)
		end
		if not o.tr then o.tr = mkLine(espGui) end
		setLine(o.tr, org, Vector2.new(rpv.X, rpv.Y), ov or CFG.tracer.color, TH)
	elseif o.tr then
		o.tr.Visible = false
	end
end

local function inTeam(plr)
	return CFG.esp.team and LP.Team ~= nil and plr.Team == LP.Team
end

X.addFrame(function()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local on = CFG.esp.on
	local vs = cam.ViewportSize
	local camPos = cam.CFrame.Position
	local now = os.clock()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			local d = ESPS[plr]
			if not d then
				d = { o = {}, hidden = true }
				ESPS[plr] = d
			end
			if not on then
				if not d.hidden then
					hideAll(d.o)
					d.hidden = true
				end
			else
				local char = plr.Character
				if char ~= d.char then
					d.char = char
					d.hum, d.root, d.head, d.bones = nil, nil, nil, nil
				end
				local hum, root = d.hum, d.root
				if char and (not hum or not root or not hum.Parent or not root.Parent) then
					hum = char:FindFirstChildOfClass("Humanoid")
					root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
					d.hum, d.root, d.head = hum, root, char:FindFirstChild("Head")
				end
				local role = X.roleOf(plr)
				d.role = role
				local show = char and hum and root and hum.Health > 0
					and (camPos - root.Position).Magnitude <= CFG.esp.maxDist
					and not inTeam(plr) and X.passTarget(plr, role)
				if not show then
					if not d.hidden then
						hideAll(d.o)
						d.hidden = true
					end
				else
					d.hidden = false
					local ov = CFG.pcolor[plr.UserId] or (CFG.esp.roles and ROLE_COL[role]) or nil
					drawPlayer(d, plr, hum, root, cam, vs, ov, camPos, now)
				end
			end
		end
	end
end)

----------------------------------------------------------------
-- HAT / TRAILS / FOV
----------------------------------------------------------------
local hats, trails = {}, {}
local hatInfo = setmetatable({}, { __mode = "k" })

local function destroyTrail(t)
	if t then
		pcall(function() t.tr:Destroy() end)
		pcall(function() t.a0:Destroy() end)
		pcall(function() t.a1:Destroy() end)
	end
end

local function updateHat(plr, cam)
	local char = plr.Character
	local head = char and char:FindFirstChild("Head")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local h = hats[plr]
	local want = CFG.hat.on and head and hum and hum.Health > 0 and (CFG.hat.scope == "Everyone" or plr == LP)
	if not want then
		if h then
			pcall(function() h:Destroy() end)
			hats[plr] = nil
			hatInfo[plr] = nil
		end
		return
	end
	local info = hatInfo[plr]
	if not h or not h.Parent then
		h = new("Part", {
			Name = "NH_Hat", Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
			Size = Vector3.new(1, 1, 1), Transparency = 1, Material = Enum.Material.Neon,
		}, Workspace)
		new("SpecialMesh", { MeshType = Enum.MeshType.FileMesh, MeshId = "rbxassetid://1033714" }, h)
		hats[plr] = h
		info = { sig = "" }
		hatInfo[plr] = info
	end
	local k = CFG.hat.size / 100
	local R_, HGT = 1.7 * k, 1.0 * k
	local n = math.max(3, math.floor(CFG.hat.lines))
	local sig = n .. "|" .. tostring(CFG.hat.rainbow) .. "|" .. tostring(CFG.hat.color) .. "|" .. CFG.hat.trans
	if info.sig ~= sig then
		for _, c in ipairs(h:GetChildren()) do
			if not c:IsA("SpecialMesh") then c:Destroy() end
		end
		info.sig = sig
		info.rim, info.beams = {}, {}
		local apex = new("Attachment", { Name = "Apex" }, h)
		info.apex = apex
		for i = 1, n do info.rim[i] = new("Attachment", { Name = "R" .. i }, h) end
		local function beam(a0, a1, c0, c1)
			local b = new("Beam", {
				Attachment0 = a0, Attachment1 = a1, Width0 = .06, Width1 = .06, FaceCamera = true, LightEmission = 1,
				LightInfluence = 0, Segments = 1, Color = ColorSequence.new(c0, c1),
				Transparency = NumberSequence.new(math.clamp(CFG.hat.trans * .6, 0, .9)),
			}, h)
			info.beams[#info.beams + 1] = b
		end
		for i = 1, n do
			local j = i % n + 1
			local c0 = CFG.hat.rainbow and Color3.fromHSV((i - 1) / n, .9, 1) or CFG.hat.color
			local c1 = CFG.hat.rainbow and Color3.fromHSV((j - 1) / n, .9, 1) or CFG.hat.color
			beam(apex, info.rim[i], c0, c0)
			beam(info.rim[i], info.rim[j], c0, c1)
		end
		info.k = nil
	end
	if info.k ~= k then
		info.k = k
		info.apex.Position = Vector3.new(0, HGT / 2, 0)
		for i, at in ipairs(info.rim) do
			local ang = (i - 1) / n * math.pi * 2
			at.Position = Vector3.new(math.cos(ang) * R_, -HGT / 2, math.sin(ang) * R_)
		end
		local mesh = h:FindFirstChildOfClass("SpecialMesh")
		if mesh then mesh.Scale = Vector3.new(1.7 * k, 1.1 * k, 1.7 * k) end
	end
	local close = plr == LP and cam ~= nil and (cam.CFrame.Position - head.Position).Magnitude < 1.8
	local mode = CFG.hat.mode
	local showLines, showSolid = mode ~= "Solid", mode ~= "Lines"
	for _, b in ipairs(info.beams) do b.Enabled = showLines and not close end
	h.Transparency = (showSolid and not close) and CFG.hat.trans or 1
	h.Color = (CFG.hat.shimmer and showSolid) and Color3.fromHSV((os.clock() * .25) % 1, .7, 1) or CFG.hat.color
	h.CFrame = CFrame.new(head.Position + Vector3.new(0, head.Size.Y / 2 + HGT / 2 + .05, 0))
end

local function updateTrail(plr)
	local char = plr.Character
	local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
	local t = trails[plr]
	if CFG.trail.on and root and (CFG.trail.scope == "Everyone" or plr == LP) then
		if not t or not t.tr.Parent or t.a0.Parent ~= root then
			destroyTrail(t)
			local a0 = new("Attachment", { Name = "NH_T0" }, root)
			local a1 = new("Attachment", { Name = "NH_T1" }, root)
			local tr = new("Trail", { Name = "NH_Trail", Attachment0 = a0, Attachment1 = a1, FaceCamera = true, MinLength = 0.05 }, root)
			t = { a0 = a0, a1 = a1, tr = tr }
			trails[plr] = t
		end
		local w = CFG.trail.width
		t.a0.Position = Vector3.new(0, w / 2, 0)
		t.a1.Position = Vector3.new(0, -w / 2, 0)
		t.tr.Lifetime = CFG.trail.len
		t.tr.Color = ColorSequence.new(CFG.trail.color)
		t.tr.Transparency = NumberSequence.new(0.1, 1)
		t.tr.LightEmission = 1
		t.tr.Enabled = true
	elseif t then
		destroyTrail(t)
		trails[plr] = nil
	end
end

X.addFrame(function()
	if not CFG.hat.on and not next(hats) then return end
	local cam = Workspace.CurrentCamera
	for _, plr in ipairs(Players:GetPlayers()) do updateHat(plr, cam) end
end)

task.spawn(function()
	while alive do
		if CFG.trail.on or next(trails) then
			for _, plr in ipairs(Players:GetPlayers()) do pcall(updateTrail, plr) end
		end
		task.wait(0.2)
	end
end)

track(Players.PlayerRemoving:Connect(function(p)
	local d = ESPS[p]
	if d then
		destroyData(d.o)
		ESPS[p] = nil
	end
	if hats[p] then pcall(function() hats[p]:Destroy() end); hats[p] = nil end
	if trails[p] then destroyTrail(trails[p]); trails[p] = nil end
end))

-- Custom FOV
local fovOn, fovSaved = false, nil
RunService:BindToRenderStep("NH_FOV", Enum.RenderPriority.Camera.Value + 1, function()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	if CFG.fov.on then
		if not fovOn then fovSaved = cam.FieldOfView end
		fovOn = true
		if cam.FieldOfView ~= CFG.fov.val then cam.FieldOfView = CFG.fov.val end
	elseif fovOn then
		fovOn = false
		cam.FieldOfView = fovSaved or 70
	end
end)

----------------------------------------------------------------
-- ESP EDITOR (предпросмотр справа)
----------------------------------------------------------------
do
	local STAGE_W, STAGE_H = PREV_W - 24, 400
	local SC_W, SC_H = 160, 320
	local OX, OY = (STAGE_W - SC_W) / 2, STAGE_H - SC_H - 4
	local BX, BY, BW, BH = 12, 72, 136, 222
	local FX, FY = BX + 8, BY + 6

	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 22),
		Font = Enum.Font.GothamBold, Text = "ESP Editor", TextSize = 16, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, Preview)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 34), Size = UDim2.new(1, -32, 0, 14),
		Font = Enum.Font.GothamMedium, Text = "live preview of your settings", TextSize = 10, TextColor3 = C.sub,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, Preview)

	local stage = new("Frame", {
		Position = UDim2.fromOffset(12, 58), Size = UDim2.fromOffset(STAGE_W, STAGE_H),
		BackgroundColor3 = C.field, BorderSizePixel = 0, ClipsDescendants = true,
	}, Preview)
	corner(stage, 12)
	stroke(stage, C.line, 1)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(24, 21, 38), Color3.fromRGB(10, 10, 16)) }, stage)

	local scene = new("Frame", { Position = UDim2.fromOffset(OX, OY), Size = UDim2.fromOffset(SC_W, SC_H), BackgroundTransparency = 1 }, stage)

	local function pvFrame(x, y, w, h, col, rad)
		local f = new("Frame", {
			Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = col or WHITE,
			BorderSizePixel = 0, Visible = false,
		}, scene)
		if rad then corner(f, rad) end
		return f
	end

	-- свечение
	local gl1 = pvFrame(BX - 18, BY - 18, BW + 36, BH + 36, WHITE, 44)
	local gl2 = pvFrame(BX - 36, BY - 36, BW + 72, BH + 72, WHITE, 60)
	-- тень под ногами
	local floorShadow = pvFrame(BX + 14, BY + BH - 8, 108, 12, Color3.new(0, 0, 0), 6)
	floorShadow.BackgroundTransparency = .55
	floorShadow.Visible = true
	-- заливка
	local pvFill = pvFrame(BX, BY, BW, BH, WHITE, 0)
	local pvFillG = new("UIGradient", { Rotation = 90 }, pvFill)

	-- фигура игрока
	local BASE = Color3.fromRGB(72, 70, 96)
	local pieces = {}
	for _, p in ipairs({
		{ 43, 0, 34, 34, 17 }, { 30, 37, 60, 70, 8 }, { 10, 37, 18, 68, 7 },
		{ 92, 37, 18, 68, 7 }, { 31, 110, 28, 100, 7 }, { 61, 110, 28, 100, 7 },
	}) do
		local f = pvFrame(FX + p[1], FY + p[2], p[3], p[4], BASE, p[5])
		f.Visible = true
		local s = stroke(f, WHITE, 1.5)
		s.Enabled = false
		pieces[#pieces + 1] = { f = f, s = s }
	end

	-- линии: 3D бокс, скелет, трейсер
	local pv3 = {}
	for i = 1, 12 do pv3[i] = mkLine(scene) end
	local pvSk = {}
	for i = 1, 14 do pvSk[i] = mkLine(scene) end
	local pvTr = mkLine(scene)

	-- 2D бокс
	local pvBox = pvFrame(BX, BY, BW, BH, WHITE, 0)
	pvBox.BackgroundTransparency = 1
	local pvBoxS = new("UIStroke", { Thickness = TH, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, pvBox)
	-- углы
	local pvCn = {}
	for i = 1, 8 do pvCn[i] = pvFrame(0, 0, 4, 4, WHITE, 0) end
	-- кольцо головы
	local pvRing = pvFrame(FX + 60 - 20, FY + 17 - 20, 40, 40, WHITE, 20)
	pvRing.BackgroundTransparency = 1
	local pvRingS = new("UIStroke", { Thickness = TH, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, pvRing)

	-- шляпа (треугольник)
	local pvHatBox = new("Frame", {
		Position = UDim2.fromOffset(FX + 30, FY + 3 - 30), Size = UDim2.fromOffset(60, 30),
		BackgroundTransparency = 1, ClipsDescendants = true, Visible = false,
	}, scene)
	local pvHat = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(30, 30), Size = UDim2.fromOffset(42, 42),
		Rotation = 45, BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, pvHatBox)

	-- подписи + здоровье
	local function pvText()
		return new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.fromOffset(150, 14), Font = Enum.Font.GothamBold, TextSize = 12,
			TextStrokeTransparency = .35, TextStrokeColor3 = Color3.new(0, 0, 0), Visible = false,
		}, scene)
	end
	local pvName, pvDist = pvText(), pvText()
	pvName.Text = "NurHub"
	pvName.AnchorPoint = Vector2.new(.5, 1)
	pvDist.Text = "37m"
	pvDist.AnchorPoint = Vector2.new(.5, 0)
	pvDist.Position = UDim2.fromOffset(BX + BW / 2, BY + BH + 3)
	local pvHpBg = pvFrame(BX - 6, BY, 2, BH, Color3.new(0, 0, 0), 0)
	pvHpBg.BackgroundTransparency = .35
	local pvHpFill = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, pvHpBg)

	-- стрелка-указатель
	local pvArrow = mkArrow(scene)
	pvArrow.frame.Position = UDim2.fromOffset(SC_W / 2 - 6, 20)

	-- суставы скелета (в координатах фигуры)
	local J = {
		head = { 60, 18 }, neck = { 60, 38 }, lsh = { 32, 42 }, rsh = { 88, 42 }, lel = { 20, 72 }, rel = { 100, 72 },
		lh = { 20, 102 }, rh = { 100, 102 }, pel = { 60, 108 }, lhip = { 45, 112 }, rhip = { 75, 112 },
		lkn = { 45, 160 }, rkn = { 75, 160 }, lft = { 45, 205 }, rft = { 75, 205 },
	}
	local BONES = {
		{ "head", "neck" }, { "neck", "pel" }, { "neck", "lsh" }, { "lsh", "lel" }, { "lel", "lh" },
		{ "neck", "rsh" }, { "rsh", "rel" }, { "rel", "rh" }, { "pel", "lhip" }, { "lhip", "lkn" },
		{ "lkn", "lft" }, { "pel", "rhip" }, { "rhip", "rkn" }, { "rkn", "rft" },
	}
	local function jp(n) return Vector2.new(FX + J[n][1], FY + J[n][2]) end

	local function pvCorner3(i)
		local fx0, fy0, fx1, fy1 = BX, BY + 14, BX + 122, BY + BH
		local back = bit32.band(i, 4) ~= 0 and 14 or 0
		local x = (bit32.band(i, 1) ~= 0 and fx1 or fx0) + back
		local y = (bit32.band(i, 2) ~= 0 and fy1 or fy0) - back
		return Vector2.new(x, y)
	end

	function X.pvUpdate(t)
		local e = CFG.esp.on

		-- chams / outline на фигуре
		for _, p in ipairs(pieces) do
			local col = BASE
			if e and CFG.chams.on then col = BASE:Lerp(CFG.chams.color, 1 - CFG.chams.trans) end
			p.f.BackgroundColor3 = col
			p.s.Enabled = e and CFG.outline.on
			p.s.Color = CFG.outline.color
		end

		-- glow
		local g = e and CFG.glow.on
		gl1.Visible = g; gl2.Visible = g
		if g then
			gl1.BackgroundColor3 = CFG.glow.color; gl2.BackgroundColor3 = CFG.glow.color
			gl1.BackgroundTransparency = math.clamp(1 - CFG.glow.bright / 9, .6, .92)
			gl2.BackgroundTransparency = math.clamp(1 - CFG.glow.bright / 18, .8, .96)
		end

		-- fill
		pvFill.Visible = e and CFG.fill.on
		if pvFill.Visible then
			pvFill.BackgroundTransparency = CFG.fill.trans
			pvFillG.Color = ColorSequence.new(CFG.fill.c1, CFG.fill.c2)
		end

		-- box 2D
		pvBox.Visible = e and CFG.box2d.on
		pvBoxS.Color = CFG.box2d.color

		-- corners (плечи — % от сторон бокса, как в игре)
		if e and CFG.corner.on then
			local r = X.cornerRatio()
			setCorners(pvCn, BX, BY, BX + BW, BY + BH, BW * r, BH * r, 2, CFG.corner.color)
		else
			for _, f in ipairs(pvCn) do f.Visible = false end
		end

		-- box 3D
		if e and CFG.box3d.on then
			for i, ed in ipairs(EDGES) do
				setLine(pv3[i], pvCorner3(ed[1]), pvCorner3(ed[2]), CFG.box3d.color, TH)
			end
		else
			hideList(pv3)
		end

		-- skeleton
		if e and CFG.skel.on then
			for i, b in ipairs(BONES) do setLine(pvSk[i], jp(b[1]), jp(b[2]), CFG.skel.color, TH) end
		else
			hideList(pvSk)
		end

		-- head ring
		pvRing.Visible = e and CFG.head.on
		pvRingS.Color = CFG.head.color

		-- tracer
		if e and CFG.tracer.on then
			local o = Vector2.new(SC_W / 2, STAGE_H - OY)
			if CFG.tracer.origin == "Top" then
				o = Vector2.new(SC_W / 2, -OY)
			elseif CFG.tracer.origin == "Crosshair" then
				o = Vector2.new(SC_W / 2, STAGE_H / 2 - OY)
			end
			setLine(pvTr, o, Vector2.new(FX + 60, FY + 72), CFG.tracer.color, TH)
		else
			pvTr.Visible = false
		end

		-- hat
		pvHatBox.Visible = CFG.hat.on
		if CFG.hat.on then
			pvHat.BackgroundColor3 = CFG.hat.color
			pvHat.BackgroundTransparency = CFG.hat.trans
		end

		-- name / distance
		pvName.Visible = e and CFG.name.on
		pvName.TextColor3 = CFG.name.color
		pvName.Position = UDim2.fromOffset(BX + BW / 2, BY - 4 - (CFG.hat.on and 28 or 0))
		pvDist.Visible = e and CFG.dist.on
		pvDist.TextColor3 = CFG.dist.color

		-- health
		pvHpBg.Visible = e and CFG.health.on
		if pvHpBg.Visible then
			local frac = 0.7 + 0.3 * math.sin(t * 1.5)
			pvHpFill.Size = UDim2.fromScale(1, frac)
			pvHpFill.BackgroundColor3 = CFG.health.color
		end

		-- arrow
		pvArrow.frame.Visible = e and CFG.arrows.on
		if pvArrow.frame.Visible then
			pvArrow.frame.Rotation = (t * 50) % 360
			paintArrow(pvArrow, CFG.arrows.color, math.min(CFG.arrows.size, 30))
		end
	end
end

----------------------------------------------------------------
-- Меню: открыть / закрыть, предпросмотр показываем только в Visual
----------------------------------------------------------------
local menuOpen = false
local menuTok, pvTok = 0, 0

local function showPreview(v)
	pvTok += 1
	local my = pvTok
	if v then
		Preview.Visible = true
		tw(Preview, .5, { GroupTransparency = 0 })
	else
		tw(Preview, .22, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(.25, function()
			if pvTok == my then Preview.Visible = false end
		end)
	end
end
onTabChanged = function(name)
	if menuOpen then showPreview(name == "Visual") end
end

local function setMenu(open)
	if open == menuOpen then return end
	menuOpen = open
	menuTok += 1
	local my = menuTok
	if open then
		Root.Visible = true
		tw(Main, .4, { GroupTransparency = 0 })
		tw(animScale, .5, { Scale = 1 }, Enum.EasingStyle.Back)
		if current == "Visual" then showPreview(true) end
	else
		tw(Main, .25, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tw(animScale, .28, { Scale = .9 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		showPreview(false)
		task.delay(.3, function()
			if menuTok == my then Root.Visible = false end
		end)
	end
end

----------------------------------------------------------------
-- MM2 ФУНКЦИИ: FPS, third person, следы, xray, мир, игрок, фарм, телепорт, конфиги
----------------------------------------------------------------
X.unloaders = {}
function X.onUnload(fn) X.unloaders[#X.unloaders + 1] = fn end

do
	local function run()
		for _, n in ipairs({ "NH_CC", "NH_Bloom", "NH_Rays", "NH_Blur" }) do
			local o = Lighting:FindFirstChild(n)
			if o then o:Destroy() end
		end

		------------------------------------------------ Show FPS
		local fpsLbl = new("TextLabel", {
			Name = "NH_FPS", BackgroundColor3 = Color3.fromRGB(14, 14, 20), BackgroundTransparency = .2,
			Size = UDim2.fromOffset(84, 26), Font = Enum.Font.GothamBold, TextSize = 14, Text = "60 FPS",
			BorderSizePixel = 0, Visible = false,
		}, espGui)
		corner(fpsLbl, 8)
		stroke(fpsLbl, C.line, 1)
		local acc, cnt, shown = 0, 0, 60
		X.fps = 60
		X.addFrame(function(dt)
			acc += dt
			cnt += 1
			if acc >= .5 then
				shown = math.floor(cnt / acc + .5)
				X.fps = shown
				acc, cnt = 0, 0
			end
			if fpsLbl.Visible ~= CFG.fps.on then fpsLbl.Visible = CFG.fps.on end
			if CFG.fps.on then
				fpsLbl.Text = (CFG.fps.custom and CFG.fps.value or shown) .. " FPS"
				fpsLbl.TextColor3 = CFG.fps.color
				fpsLbl.AnchorPoint = Vector2.new(CFG.fps.x, CFG.fps.y)
				fpsLbl.Position = UDim2.fromScale(CFG.fps.x, CFG.fps.y)
			end
		end)

		------------------------------------------------ Third person
		local saved
		X.addFrame(function()
			if CFG.third.on then
				if not saved then saved = { LP.CameraMinZoomDistance, LP.CameraMaxZoomDistance, LP.CameraMode } end
				pcall(function()
					if LP.CameraMode ~= Enum.CameraMode.Classic then LP.CameraMode = Enum.CameraMode.Classic end
					if LP.CameraMaxZoomDistance ~= CFG.third.dist then LP.CameraMaxZoomDistance = CFG.third.dist end
					if LP.CameraMinZoomDistance ~= CFG.third.dist then LP.CameraMinZoomDistance = CFG.third.dist end
				end)
			elseif saved then
				pcall(function()
					LP.CameraMinZoomDistance = saved[1]
					LP.CameraMaxZoomDistance = saved[2]
					LP.CameraMode = saved[3]
				end)
				saved = nil
			end
		end)

		------------------------------------------------ Следы игрока (с анимацией)
		local stepParams = RaycastParams.new()
		stepParams.FilterType = Enum.RaycastFilterType.Exclude
		local live = 0
		local lastPos = setmetatable({}, { __mode = "k" })
		local function mkPart(round, size, cf, col)
			local p = new("Part", {
				Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
				Material = Enum.Material.Neon, Color = col, Transparency = .1, Name = "NH_Step",
			}, Workspace)
			if round then
				p.Shape = Enum.PartType.Cylinder
				p.Size = Vector3.new(.05, size, size)
				p.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
			else
				p.Size = Vector3.new(size, .05, size)
				p.CFrame = cf
			end
			return p
		end
		local function spawnStep(pos, look, side)
			if live > 160 then return end
			local col, life, shape = CFG.steps.color, CFG.steps.life, CFG.steps.shape
			local base = CFrame.lookAt(pos, pos + look)
			local parts = {}
			local function add(round, size, cf, grow)
				local p = mkPart(round, size, cf, col)
				parts[#parts + 1] = p
				local goal = round and Vector3.new(.05, size * grow, size * grow) or Vector3.new(size * grow, .05, size * grow)
				TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1, Size = goal }):Play()
			end
			if shape == "Circle" then
				add(true, 1.2, base, 2.2)
			elseif shape == "Square" then
				add(false, 1.1, base, 1.8)
			elseif shape == "Diamond" then
				add(false, 1.1, base * CFrame.Angles(0, math.rad(45), 0), 1.8)
			else
				add(true, .55, base * CFrame.new(side * .22, 0, -.45), 1.5)
				add(true, .38, base * CFrame.new(side * .22, 0, .35), 1.5)
			end
			live += #parts
			task.delay(life + .2, function()
				for _, p in ipairs(parts) do pcall(function() p:Destroy() end) end
				live -= #parts
			end)
		end
		track(RunService.Heartbeat:Connect(function()
			if not CFG.steps.on then return end
			for _, plr in ipairs(Players:GetPlayers()) do
				if CFG.steps.scope == "Everyone" or plr == LP then
					local ch = plr.Character
					local hum = ch and ch:FindFirstChildOfClass("Humanoid")
					local root = ch and ch:FindFirstChild("HumanoidRootPart")
					if hum and root and hum.Health > 0 and hum.FloorMaterial ~= Enum.Material.Air then
						local st = lastPos[plr]
						if not st then
							lastPos[plr] = { pos = root.Position, side = 1 }
						else
							local d = root.Position - st.pos
							local flat = Vector3.new(d.X, 0, d.Z)
							if flat.Magnitude >= CFG.steps.dist and os.clock() - (st.t or 0) >= CFG.steps.delay then
								stepParams.FilterDescendantsInstances = { ch }
								local r = Workspace:Raycast(root.Position, Vector3.new(0, -8, 0), stepParams)
								if r then spawnStep(r.Position + Vector3.new(0, .06, 0), flat.Unit, st.side) end
								st.side = -st.side
								st.t = os.clock()
								st.pos = root.Position
							end
						end
					end
				end
			end
		end))

		------------------------------------------------ Xray
		local xr = setmetatable({}, { __mode = "k" })
		local function skip(p)
			if p.Size.Magnitude < 6 then return true end
			local m = p:FindFirstAncestorOfClass("Model")
			while m do
				if m:FindFirstChildOfClass("Humanoid") then return true end
				m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model") or nil
			end
			return false
		end
		local function xrOne(p)
			if p:IsA("BasePart") and not p:IsA("Terrain") and not skip(p) then
				xr[p] = true
				p.LocalTransparencyModifier = CFG.xray.amount
			end
		end
		local was, lastAmt = false, nil
		task.spawn(function()
			while alive do
				if CFG.xray.on then
					if not was or lastAmt ~= CFG.xray.amount then
						was, lastAmt = true, CFG.xray.amount
						local n = 0
						for _, p in ipairs(Workspace:GetDescendants()) do
							xrOne(p)
							n += 1
							if n % 600 == 0 then task.wait() end
						end
					end
				elseif was then
					was = false
					for p in pairs(xr) do
						if p.Parent then p.LocalTransparencyModifier = 0 end
					end
					xr = setmetatable({}, { __mode = "k" })
				end
				task.wait(.3)
			end
		end)

		------------------------------------------------ Монеты / пушка (сканер, одно подключение на Workspace)
		local coins = setmetatable({}, { __mode = "k" })
		local guns = setmetatable({}, { __mode = "k" })
		X.coins, X.guns = coins, guns
		local function scan(v)
			if v.Name == "Coin_Server" and v:IsA("BasePart") then
				coins[v] = true
			elseif v.Name == "GunDrop" and (v:IsA("BasePart") or v:IsA("Model")) then
				guns[v] = true
			end
		end
		track(Workspace.DescendantAdded:Connect(function(v)
			scan(v)
			if CFG.xray.on then xrOne(v) end
		end))
		task.spawn(function()
			local n = 0
			for _, v in ipairs(Workspace:GetDescendants()) do
				scan(v)
				n += 1
				if n % 800 == 0 then task.wait() end
			end
		end)

		------------------------------------------------ Мир: шейдеры + свет
		local cc = new("ColorCorrectionEffect", { Name = "NH_CC" }, Lighting)
		local bloom = new("BloomEffect", { Name = "NH_Bloom", Intensity = 0, Size = 24, Threshold = 2 }, Lighting)
		local rays = new("SunRaysEffect", { Name = "NH_Rays", Intensity = 0, Spread = .6 }, Lighting)
		local blur = new("BlurEffect", { Name = "NH_Blur", Size = 0 }, Lighting)

		local PRESETS = {
			["Sakura"]    = { tint = Color3.fromRGB(255, 226, 236), sat = 0.15, contrast = 0.05, bloom = 0.4, weather = "sakura" },
			["Blood"]     = { tint = Color3.fromRGB(255, 165, 165), sat = 0.1, contrast = 0.2, bright = -0.08, bloom = 0.3, weather = "blood" },
			["4K"]        = { sat = 0.25, contrast = 0.22, bright = 0.02, bloom = 0.5, rays = 0.1 },
			["Snow"]      = { tint = Color3.fromRGB(226, 240, 255), sat = -0.1, bright = 0.05, weather = "snow" },
			["Sunset"]    = { tint = Color3.fromRGB(255, 200, 150), sat = 0.25, rays = 0.25, bloom = 0.6 },
			["Rain"]      = { tint = Color3.fromRGB(190, 205, 225), sat = -0.2, contrast = 0.1, bright = -0.05, weather = "rain" },
			["Neon"]      = { tint = Color3.fromRGB(220, 190, 255), sat = 0.5, contrast = 0.25, bloom = 1.2 },
			["Noir"]      = { sat = -1, contrast = 0.3 },
			["Vintage"]   = { tint = Color3.fromRGB(255, 235, 200), sat = -0.25, contrast = 0.1 },
			["Cyberpunk"] = { tint = Color3.fromRGB(200, 170, 255), sat = 0.45, contrast = 0.2, bloom = 0.9 },
			["Ocean"]     = { tint = Color3.fromRGB(170, 215, 255), sat = 0.2, bright = 0.02, rays = 0.15 },
			["Matrix"]    = { tint = Color3.fromRGB(150, 255, 170), sat = -0.2, contrast = 0.25, bloom = 0.5 },
			["Autumn"]    = { tint = Color3.fromRGB(255, 205, 150), sat = 0.2, weather = "leaves" },
			["Dreamy"]    = { tint = Color3.fromRGB(255, 230, 245), sat = 0.1, bright = 0.06, bloom = 1.0, rays = 0.2 },
		}
		X.PRESET_LIST = { "Sakura", "Blood", "4K", "Snow", "Sunset", "Rain", "Neon", "Noir", "Vintage", "Cyberpunk", "Ocean", "Matrix", "Autumn", "Dreamy" }

		local weatherPart = new("Part", {
			Name = "NH_Weather", Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
			Transparency = 1, Size = Vector3.new(90, 1, 90), CastShadow = false,
		})
		local emitters, curWeather = {}, nil
		local WEATHER = {
			snow = function(e)
				e.Rate = 260; e.Lifetime = NumberRange.new(5, 6); e.Speed = NumberRange.new(6, 9)
				e.Size = NumberSequence.new(0.3); e.Color = ColorSequence.new(WHITE)
				e.Transparency = NumberSequence.new(0.1); e.Acceleration = Vector3.new(2, 0, 1)
				e.RotSpeed = NumberRange.new(-60, 60); e.SpreadAngle = Vector2.new(12, 12)
			end,
			rain = function(e)
				e.Rate = 650; e.Lifetime = NumberRange.new(0.4, 0.45); e.Speed = NumberRange.new(95, 110)
				e.Size = NumberSequence.new(0.14); e.Color = ColorSequence.new(Color3.fromRGB(180, 200, 230))
				e.Transparency = NumberSequence.new(0.35); e.SpreadAngle = Vector2.new(3, 3)
				e.Orientation = Enum.ParticleOrientation.VelocityParallel
			end,
			sakura = function(e)
				e.Rate = 70; e.Lifetime = NumberRange.new(7, 9); e.Speed = NumberRange.new(3, 6)
				e.Size = NumberSequence.new(0.5)
				e.Color = ColorSequence.new(Color3.fromRGB(255, 170, 200), Color3.fromRGB(255, 205, 225))
				e.Transparency = NumberSequence.new(0.05); e.Acceleration = Vector3.new(3, 0, 1.5)
				e.RotSpeed = NumberRange.new(-120, 120); e.SpreadAngle = Vector2.new(25, 25)
			end,
			blood = function(e)
				e.Rate = 130; e.Lifetime = NumberRange.new(2.5, 3); e.Speed = NumberRange.new(12, 16)
				e.Size = NumberSequence.new(0.35); e.Color = ColorSequence.new(Color3.fromRGB(170, 0, 10))
				e.Transparency = NumberSequence.new(0.1); e.SpreadAngle = Vector2.new(6, 6)
			end,
			leaves = function(e)
				e.Rate = 60; e.Lifetime = NumberRange.new(7, 9); e.Speed = NumberRange.new(3, 6)
				e.Size = NumberSequence.new(0.5)
				e.Color = ColorSequence.new(Color3.fromRGB(230, 120, 40), Color3.fromRGB(150, 80, 30))
				e.Transparency = NumberSequence.new(0.05); e.Acceleration = Vector3.new(4, 0, 2)
				e.RotSpeed = NumberRange.new(-150, 150); e.SpreadAngle = Vector2.new(25, 25)
			end,
		}
		local function setWeather(kind)
			if kind == curWeather then return end
			curWeather = kind
			for k, e in pairs(emitters) do e.Enabled = (k == kind) end
			if kind then
				if not emitters[kind] then
					local e = new("ParticleEmitter", {
						EmissionDirection = Enum.NormalId.Bottom, LockedToPart = false, Rotation = NumberRange.new(0, 360),
					}, weatherPart)
					WEATHER[kind](e)
					emitters[kind] = e
				end
				emitters[kind].Enabled = true
				weatherPart.Parent = Workspace.CurrentCamera
			else
				weatherPart.Parent = nil
			end
		end

		-- свет: если игра сама меняет Lighting (лобби/карта) — берём новое значение как базу
		local LKEYS = { "Brightness", "Ambient", "OutdoorAmbient", "FogEnd", "FogStart", "FogColor", "GlobalShadows", "ExposureCompensation" }
		local orig, lastSet, active = nil, {}, false
		local function same(a, b)
			local ta = typeof(a)
			if ta == "number" then return math.abs(a - b) < 1e-3 end
			if ta == "Color3" then return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 2e-3 end
			return a == b
		end
		local function snap()
			orig, lastSet = {}, {}
			for _, k in ipairs(LKEYS) do orig[k] = Lighting[k] end
		end
		local function neutral()
			cc.Brightness, cc.Contrast, cc.Saturation, cc.TintColor = 0, 0, 0, WHITE
			bloom.Intensity, bloom.Threshold = 0, 2
			rays.Intensity = 0
			blur.Size = 0
		end
		local function restore()
			neutral()
			setWeather(nil)
			if orig then
				for _, k in ipairs(LKEYS) do
					if orig[k] ~= nil then pcall(function() Lighting[k] = orig[k] end) end
				end
			end
		end
		local function anyOn()
			return CFG.shader.on or CFG.wbright.on or CFG.wglow.on or CFG.wdark.on or CFG.wgrade.on or CFG.wblur.on
				or CFG.wfog.on or CFG.wrays.on or CFG.wfull.on or CFG.wshadow.on
		end
		local function apply()
			for _, k in ipairs(LKEYS) do
				local ls = lastSet[k]
				if ls ~= nil and not same(Lighting[k], ls) then orig[k] = Lighting[k] end
			end
			local p = (CFG.shader.on and PRESETS[CFG.shader.preset]) or {}
			local bright = (p.bright or 0) + (CFG.wbright.on and CFG.wbright.val or 0) - (CFG.wdark.on and CFG.wdark.val * .5 or 0)
			local contrast = (p.contrast or 0) + (CFG.wgrade.on and CFG.wgrade.con or 0)
			local sat = (p.sat or 0) + (CFG.wgrade.on and CFG.wgrade.sat or 0)
			cc.Brightness = math.clamp(bright, -1, 1)
			cc.Contrast = math.clamp(contrast, -1, 1)
			cc.Saturation = math.clamp(sat, -1, 1)
			cc.TintColor = p.tint or WHITE
			bloom.Intensity = (p.bloom or 0) + (CFG.wglow.on and CFG.wglow.int or 0)
			bloom.Threshold = CFG.wglow.on and CFG.wglow.thr or (p.bloom and 1.2 or 2)
			rays.Intensity = math.clamp((p.rays or 0) + (CFG.wrays.on and CFG.wrays.val or 0), 0, 1)

			local t = {}
			t.ExposureCompensation = orig.ExposureCompensation - (CFG.wdark.on and CFG.wdark.val * 1.5 or 0)
			t.Brightness = orig.Brightness + (CFG.wfull.on and 2 or 0)
			if CFG.wfull.on then
				t.Ambient = Color3.fromRGB(170, 170, 170)
				t.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
			else
				t.Ambient = orig.Ambient
				t.OutdoorAmbient = orig.OutdoorAmbient
			end
			if CFG.wfog.on then
				t.FogStart = 0
				t.FogEnd = math.max(30, 2200 * (1 - CFG.wfog.val) ^ 2)
				t.FogColor = Color3.fromRGB(180, 180, 190)
			else
				t.FogStart = orig.FogStart
				t.FogEnd = orig.FogEnd
				t.FogColor = orig.FogColor
			end
			if CFG.wshadow.on then
				t.GlobalShadows = false
			else
				t.GlobalShadows = orig.GlobalShadows
			end
			for k, v in pairs(t) do
				if not same(Lighting[k], v) then Lighting[k] = v end
				lastSet[k] = v
			end
			setWeather(p.weather)
		end
		task.spawn(function()
			while alive do
				if anyOn() then
					if not active then
						active = true
						snap()
					end
					pcall(apply)
				elseif active then
					active = false
					restore()
				end
				task.wait(.12)
			end
		end)

		-- время суток + motion blur + погода за камерой
		local savedClock, lastLook = nil, Vector3.new(0, 0, -1)
		X.addFrame(function()
			local cam = Workspace.CurrentCamera
			if weatherPart.Parent and cam then
				weatherPart.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 38, 0))
			end
			if CFG.wtime.on then
				if not savedClock then savedClock = Lighting.ClockTime end
				Lighting.ClockTime = CFG.wtime.val
			elseif savedClock then
				Lighting.ClockTime = savedClock
				savedClock = nil
			end
			if CFG.wblur.on and cam then
				local look = cam.CFrame.LookVector
				local ang = math.acos(math.clamp(look:Dot(lastLook), -1, 1))
				lastLook = look
				local goal = math.clamp(ang * CFG.wblur.val * 30, 0, 28)
				blur.Size = blur.Size + (goal - blur.Size) * .4
			elseif cam and blur.Size ~= 0 and not active then
				blur.Size = 0
			end
		end)

		------------------------------------------------ Gun ESP / Coin ESP
		local gunO, coinO = {}, {}
		local function posOf(i)
			if i:IsA("Model") then return i:GetPivot().Position end
			return i.Position
		end
		X.addFrame(function()
			local cam = Workspace.CurrentCamera
			if not cam then return end
			local vs = cam.ViewportSize
			if CFG.gun.on or next(gunO) then
				for g in pairs(guns) do
					local o = gunO[g]
					if not g.Parent then
						guns[g] = nil
						if o then
							for _, x in pairs(o) do pcall(function() x:Destroy() end) end
							gunO[g] = nil
						end
					elseif CFG.gun.on then
						if not o then
							o = {
								hl = new("Highlight", { DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, FillTransparency = .45 }, espGui),
								txt = mkText(), ln = mkLine(espGui),
							}
							gunO[g] = o
						end
						o.hl.Adornee = g
						o.hl.FillColor = CFG.gun.color
						o.hl.OutlineColor = CFG.gun.color
						o.hl.Enabled = true
						local p = cam:WorldToViewportPoint(posOf(g))
						if p.Z > 0 then
							if CFG.gun.text then
								o.txt.Text = "Gun"
								o.txt.TextColor3 = CFG.gun.textColor
								o.txt.AnchorPoint = Vector2.new(.5, 1)
								o.txt.Position = UDim2.fromOffset(p.X, p.Y - 10)
								o.txt.Visible = true
							else
								o.txt.Visible = false
							end
							if CFG.gun.tracer then
								local org = Vector2.new(vs.X / 2, vs.Y)
								if CFG.tracer.origin == "Top" then
									org = Vector2.new(vs.X / 2, 0)
								elseif CFG.tracer.origin == "Crosshair" then
									org = Vector2.new(vs.X / 2, vs.Y / 2)
								end
								setLine(o.ln, org, Vector2.new(p.X, p.Y), CFG.gun.color, TH)
							else
								o.ln.Visible = false
							end
						else
							o.txt.Visible = false
							o.ln.Visible = false
						end
					elseif o then
						o.hl.Enabled = false
						o.txt.Visible = false
						o.ln.Visible = false
					end
				end
			end

			if CFG.coin.on or next(coinO) then
				local camPos = cam.CFrame.Position
				for c in pairs(coins) do
					local o = coinO[c]
					if not c.Parent then
						coins[c] = nil
						if o then
							o.f:Destroy()
							coinO[c] = nil
						end
					elseif CFG.coin.on then
						local p = cam:WorldToViewportPoint(c.Position)
						if p.Z > 0 and (camPos - c.Position).Magnitude < CFG.esp.maxDist then
							if not o then
								local f = new("Frame", {
									AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1,
									BorderSizePixel = 0, Visible = false,
								}, espGui)
								corner(f, 6)
								local s = new("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
								local t = new("TextLabel", {
									BackgroundTransparency = 1, AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 0, -2),
									Size = UDim2.fromOffset(60, 12), Font = Enum.Font.GothamBold, TextSize = 11, Text = "Coin",
									TextStrokeTransparency = .35,
								}, f)
								o = { f = f, s = s, t = t }
								coinO[c] = o
							end
							o.f.Position = UDim2.fromOffset(p.X, p.Y)
							o.s.Color = CFG.coin.color
							o.t.Visible = CFG.coin.text
							o.t.TextColor3 = CFG.coin.textColor
							o.f.Visible = true
						elseif o then
							o.f.Visible = false
						end
					elseif o then
						o.f.Visible = false
					end
				end
			end
		end)

		------------------------------------------------ Игрок: speed / jump / spin / noclip / fly / autofarm
		local bv, bg
		local oldWalk, oldJump
		local farmT, farmWait = nil, 0
		local cool = setmetatable({}, { __mode = "k" })
		local function cleanFly()
			if bv then bv:Destroy(); bv = nil end
			if bg then bg:Destroy(); bg = nil end
		end
		track(RunService.Heartbeat:Connect(function(dt)
			local ch = LP.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if not hum or not root or hum.Health <= 0 then
				cleanFly()
				return
			end
			if CFG.walk.on then
				oldWalk = oldWalk or hum.WalkSpeed
				if hum.WalkSpeed ~= CFG.walk.val then hum.WalkSpeed = CFG.walk.val end
			elseif oldWalk then
				hum.WalkSpeed = oldWalk
				oldWalk = nil
			end
			if CFG.jump.on then
				oldJump = oldJump or hum.JumpPower
				hum.UseJumpPower = true
				if hum.JumpPower ~= CFG.jump.val then hum.JumpPower = CFG.jump.val end
			elseif oldJump then
				hum.JumpPower = oldJump
				oldJump = nil
			end
			if CFG.spin.on then
				root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(CFG.spin.val * dt), 0)
			end

			-- автофарм монет: цель + плавное перемещение
			if CFG.farm.on then
				farmWait -= dt
				if farmWait <= 0 then
					if farmT and not farmT.Parent then farmT = nil end
					if not farmT then
						local best, bd, now = nil, math.huge, os.clock()
						for part in pairs(coins) do
							if part.Parent and (not cool[part] or cool[part] < now) then
								local d = (part.Position - root.Position).Magnitude
								if d < bd then best, bd = part, d end
							end
						end
						farmT = best
					end
					if farmT then
						local to = farmT.Position - root.Position
						local d = to.Magnitude
						if d < 3 then
							cool[farmT] = os.clock() + 4
							farmT = nil
							farmWait = CFG.farm.delay
						else
							root.CFrame = root.CFrame + to.Unit * math.min(d, CFG.farm.fly * dt)
						end
					end
				end
			else
				farmT = nil
			end

			-- fly / удержание на месте только пока есть цель автофарма
			local holding = CFG.farm.on and farmT ~= nil
			if holding or CFG.fly.on then
				if not bv or bv.Parent ~= root then
					cleanFly()
					bv = new("BodyVelocity", { MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.zero }, root)
					bg = new("BodyGyro", { MaxTorque = Vector3.new(1e9, 1e9, 1e9), P = 1e4 }, root)
				end
				local cam = Workspace.CurrentCamera
				local vel = Vector3.zero
				if CFG.fly.on and not holding and cam then
					local md = hum.MoveDirection
					local lv = cam.CFrame.LookVector
					if md.Magnitude > 0 then
						local flat = Vector3.new(lv.X, 0, lv.Z)
						local fwd = flat.Magnitude > 0 and md:Dot(flat.Unit) or 0
						vel = md * CFG.fly.val + Vector3.new(0, lv.Y * CFG.fly.val * math.max(fwd, 0), 0)
					end
					if hum.Jump then vel += Vector3.new(0, CFG.fly.val, 0) end
					if Vector3.new(lv.X, 0, lv.Z).Magnitude > .01 then
						bg.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(lv.X, 0, lv.Z))
					else
						bg.CFrame = root.CFrame
					end
				else
					bg.CFrame = root.CFrame
				end
				bv.Velocity = vel
			else
				cleanFly()
			end
		end))

		-- noclip (список частей кэшируется)
		local ncParts, ncChar, ncT = {}, nil, 0
		track(RunService.Stepped:Connect(function()
			if CFG.noclip.on or CFG.farm.on then
				local ch = LP.Character
				if ch then
					local now = os.clock()
					if ch ~= ncChar or now - ncT > 1 then
						ncChar, ncT = ch, now
						ncParts = {}
						for _, p in ipairs(ch:GetDescendants()) do
							if p:IsA("BasePart") then ncParts[#ncParts + 1] = p end
						end
					end
					for i = 1, #ncParts do
						local p = ncParts[i]
						if p.CanCollide then p.CanCollide = false end
					end
				end
			end
		end))

		------------------------------------------------ Телепорты
		local function myRoot()
			local c = LP.Character
			return c and c:FindFirstChild("HumanoidRootPart")
		end
		function X.tpPlayer(plr)
			local r = myRoot()
			local t = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if r and t then
				r.CFrame = t.CFrame * CFrame.new(0, 0, 3)
				return true
			end
			return false
		end
		function X.tpSpawn()
			local r = myRoot()
			if not r then return false end
			local lobby = Workspace:FindFirstChild("Lobby")
			local sp = nil
			if lobby and lobby:FindFirstChild("Spawns") then
				sp = lobby.Spawns:FindFirstChildWhichIsA("BasePart", true)
			end
			sp = sp or Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
			if sp then
				r.CFrame = sp.CFrame * CFrame.new(0, 4, 0)
				return true
			end
			return false
		end
		local function getMap()
			for _, m in ipairs(Workspace:GetChildren()) do
				if m:IsA("Model") and m.Name ~= "Lobby" and (m:FindFirstChild("CoinContainer") or m:FindFirstChild("Spawns"))
					and not Players:GetPlayerFromCharacter(m) then
					return m
				end
			end
			return nil
		end
		function X.tpMap()
			local r = myRoot()
			if not r then return false end
			local m = getMap()
			if m then
				local sp = m:FindFirstChild("Spawns")
				local part = sp and sp:FindFirstChildWhichIsA("BasePart", true)
				if part then
					r.CFrame = part.CFrame * CFrame.new(0, 4, 0)
				else
					r.CFrame = CFrame.new(m:GetPivot().Position + Vector3.new(0, 15, 0))
				end
				return true
			end
			for c in pairs(coins) do
				if c.Parent then
					r.CFrame = c.CFrame * CFrame.new(0, 3, 0)
					return true
				end
			end
			return false
		end
		function X.tpRole(role)
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LP and X.roleOf(p) == role then return X.tpPlayer(p) end
			end
			return false
		end

		-- обновление списков игроков (ники, роли, выбор)
		task.spawn(function()
			while alive do
				for _, l in ipairs(X.lists) do
					if l.frame.Parent then pcall(l.upd) end
				end
				task.wait(.8)
			end
		end)
		local function relist()
			for _, l in ipairs(X.lists) do
				if l.frame.Parent then
					pcall(l.rebuild)
					pcall(l.upd)
				end
			end
		end
		track(Players.PlayerAdded:Connect(function() task.delay(.6, relist) end))
		track(Players.PlayerRemoving:Connect(function() task.delay(.2, relist) end))

		------------------------------------------------ Конфиги (5 слотов)
		local SKIP = { pcolor = true, target = true, acolor = true }
		local function ser(v)
			if typeof(v) == "Color3" then return { __c = { v.R, v.G, v.B } } end
			if type(v) == "table" then
				local o = {}
				for k, x in pairs(v) do
					if type(k) == "string" then o[k] = ser(x) end
				end
				return o
			end
			return v
		end
		local function deser(dst, src)
			for k, v in pairs(src) do
				local cur = dst[k]
				if type(v) == "table" then
					if v.__c then
						dst[k] = Color3.new(v.__c[1], v.__c[2], v.__c[3])
					elseif type(cur) == "table" then
						deser(cur, v)
					end
				elseif cur ~= nil and type(cur) == type(v) then
					dst[k] = v
				end
			end
		end
		local slots = {}
		local function writeSlots()
			local o = {}
			for i = 1, 5 do
				if slots[i] then o[tostring(i)] = slots[i] end
			end
			pcall(function() X.fsWrite("configs.json", HttpService:JSONEncode(o)) end)
		end
		do
			local raw = X.fsRead("configs.json")
			if raw then
				local ok, t = pcall(function() return HttpService:JSONDecode(raw) end)
				if ok and type(t) == "table" then
					for i = 1, 5 do
						local s = t[tostring(i)]
						if type(s) == "table" and s.name and type(s.data) == "table" then slots[i] = s end
					end
				end
			end
		end
		X.cfgApi = {
			slots = function() return slots end,
			count = function()
				local n = 0
				for i = 1, 5 do
					if slots[i] then n += 1 end
				end
				return n
			end,
			save = function(name)
				name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
				if name == "" then name = "config" end
				local idx
				for i = 1, 5 do
					if slots[i] and slots[i].name == name then idx = i end
				end
				if not idx then
					for i = 1, 5 do
						if not slots[i] then
							idx = i
							break
						end
					end
				end
				if not idx then return nil end
				local snapshot = {}
				for k, v in pairs(CFG) do
					if not SKIP[k] then snapshot[k] = ser(v) end
				end
				slots[idx] = { name = name, data = snapshot }
				writeSlots()
				return idx
			end,
			load = function(i)
				local s = slots[i]
				if not s then return false end
				deser(CFG, s.data)
				X.refreshAll()
				return true
			end,
			delete = function(i)
				slots[i] = nil
				writeSlots()
			end,
		}

		------------------------------------------------ Выгрузка
		X.onUnload(function()
			pcall(restore)
			pcall(function() cc:Destroy(); bloom:Destroy(); rays:Destroy(); blur:Destroy(); weatherPart:Destroy() end)
			pcall(cleanFly)
			pcall(function() fpsLbl:Destroy() end)
			for p in pairs(xr) do
				if p.Parent then p.LocalTransparencyModifier = 0 end
			end
			if saved then
				pcall(function()
					LP.CameraMinZoomDistance = saved[1]
					LP.CameraMaxZoomDistance = saved[2]
					LP.CameraMode = saved[3]
				end)
			end
			if savedClock then pcall(function() Lighting.ClockTime = savedClock end) end
			local ch = LP.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if hum then
				if oldWalk then hum.WalkSpeed = oldWalk end
				if oldJump then hum.JumpPower = oldJump end
			end
			for _, o in pairs(coinO) do pcall(function() o.f:Destroy() end) end
			for _, o in pairs(gunO) do
				for _, x in pairs(o) do pcall(function() x:Destroy() end) end
			end
		end)
	end
	run()
end

----------------------------------------------------------------
-- Прицел, путь пули, звук попадания, крылья/нимб, внешний вид, bhop, походки, эмоции, auto grab
----------------------------------------------------------------
do
	local function run()
		local SoundService = game:GetService("SoundService")
		local Debris = game:GetService("Debris")

		------------------------------------------------ Свой прицел (линии, вращение)
		local SHAPES = {
			Cross = { { -1, 0, 1, 0 }, { 0, -1, 0, 1 } },
			Plus = { { -1, 0, -.3, 0 }, { .3, 0, 1, 0 }, { 0, -1, 0, -.3 }, { 0, .3, 0, 1 } },
			X = { { -.8, -.8, .8, .8 }, { -.8, .8, .8, -.8 } },
			Square = { { -1, -1, 1, -1 }, { 1, -1, 1, 1 }, { 1, 1, -1, 1 }, { -1, 1, -1, -1 } },
			Diamond = { { 0, -1, 1, 0 }, { 1, 0, 0, 1 }, { 0, 1, -1, 0 }, { -1, 0, 0, -1 } },
			Triangle = { { 0, -1, 1, .8 }, { 1, .8, -1, .8 }, { -1, .8, 0, -1 } },
			Star = {},
			Circle = {},
			Dot = { { -.25, 0, .25, 0 }, { 0, -.25, 0, .25 } },
		}
		for k = 0, 4 do
			local a1 = math.rad(-90 + 72 * k)
			local a2 = math.rad(-90 + 72 * ((k + 2) % 5))
			SHAPES.Star[#SHAPES.Star + 1] = { math.cos(a1), math.sin(a1), math.cos(a2), math.sin(a2) }
		end
		for k = 0, 19 do
			local a1, a2 = math.rad(k * 18), math.rad((k + 1) * 18)
			SHAPES.Circle[#SHAPES.Circle + 1] = { math.cos(a1), math.sin(a1), math.cos(a2), math.sin(a2) }
		end
		X.SHAPE_LIST = { "Cross", "Plus", "X", "Square", "Diamond", "Triangle", "Star", "Circle", "Dot" }

		function X.drawShape(pool, parent, cx, cy, shape, size, thick, col, ang)
			local segs = SHAPES[shape] or SHAPES.Cross
			local ca, sa = math.cos(ang), math.sin(ang)
			for i = 1, #segs do
				local f = pool[i]
				if not f then
					f = mkLine(parent)
					pool[i] = f
				end
				local s = segs[i]
				local x1, y1 = (s[1] * ca - s[2] * sa) * size, (s[1] * sa + s[2] * ca) * size
				local x2, y2 = (s[3] * ca - s[4] * sa) * size, (s[3] * sa + s[4] * ca) * size
				setLine(f, Vector2.new(cx + x1, cy + y1), Vector2.new(cx + x2, cy + y2), col, thick)
			end
			for i = #segs + 1, #pool do pool[i].Visible = false end
		end

		local xPool, xShown = {}, false
		X.addFrame(function()
			local cam = Workspace.CurrentCamera
			if not cam then return end
			if CFG.xhair.on then
				xShown = true
				local vs = cam.ViewportSize
				local ang = CFG.xhair.spin and (os.clock() * math.rad(CFG.xhair.speed)) or 0
				X.drawShape(xPool, espGui, vs.X / 2, vs.Y / 2, CFG.xhair.shape, CFG.xhair.size, CFG.xhair.thick, CFG.xhair.color, ang)
			elseif xShown then
				xShown = false
				for _, f in ipairs(xPool) do f.Visible = false end
			end
		end)

		------------------------------------------------ Звук попадания
		local SOUNDS = {
			Ping = "rbxasset://sounds/electronicpingshort.wav", Click = "rbxasset://sounds/clickfast.wav",
			Switch = "rbxasset://sounds/switch.wav", Button = "rbxasset://sounds/button.wav", Bass = "rbxasset://sounds/bass.wav",
			Snap = "rbxasset://sounds/snap.mp3", Splat = "rbxasset://sounds/splat.wav", Victory = "rbxasset://sounds/victory.wav",
			Oof = "rbxasset://sounds/uuhhh.mp3",
		}
		X.SOUND_LIST = { "Ping", "Click", "Switch", "Button", "Bass", "Snap", "Splat", "Victory", "Oof" }
		function X.playHit()
			local s = new("Sound", { Volume = CFG.hsound.volume / 10 * 2 }, SoundService)
			if CFG.hsound.id ~= "" then
				s.SoundId = "rbxassetid://" .. CFG.hsound.id
			else
				s.SoundId = SOUNDS[CFG.hsound.sound] or SOUNDS.Ping
			end
			s:Play()
			Debris:AddItem(s, 4)
		end

		------------------------------------------------ Путь пули + попадание
		local rpHit = RaycastParams.new()
		rpHit.FilterType = Enum.RaycastFilterType.Exclude
		local function beamPart(a, b, col, life)
			local d = b - a
			local len = d.Magnitude
			if len < .1 then return end
			local p = new("Part", {
				Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
				Material = Enum.Material.Neon, Color = col, Size = Vector3.new(.12, .12, len), Transparency = .1, Name = "NH_Bullet",
			}, Workspace)
			p.CFrame = CFrame.lookAt(a + d / 2, b)
			TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Transparency = 1, Size = Vector3.new(.02, .02, len) }):Play()
			task.delay(life + .1, function() p:Destroy() end)
		end
		local function onShoot(tool)
			if not alive then return end
			local cam = Workspace.CurrentCamera
			if not cam then return end
			local ch = LP.Character
			rpHit.FilterDescendantsInstances = { ch }
			local pos = UIS.TouchEnabled and Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2) or UIS:GetMouseLocation()
			local ray = cam:ViewportPointToRay(pos.X, pos.Y)
			local res = Workspace:Raycast(ray.Origin, ray.Direction * 500, rpHit)
			local endp = res and res.Position or (ray.Origin + ray.Direction * 300)
			local handle = tool:FindFirstChild("Handle")
			local head = ch and ch:FindFirstChild("Head")
			local startp = handle and handle.Position or (head and head.Position) or ray.Origin
			if CFG.bpath.on then beamPart(startp, endp, CFG.bpath.color, CFG.bpath.time) end
			if CFG.hsound.on and res then
				local m = res.Instance:FindFirstAncestorOfClass("Model")
				local plr = m and Players:GetPlayerFromCharacter(m)
				if plr and plr ~= LP then X.playHit() end
			end
		end
		local hooked = setmetatable({}, { __mode = "k" })
		local function hookTool(tool)
			if tool:IsA("Tool") and tool.Name == "Gun" and not hooked[tool] then
				hooked[tool] = true
				tool.Activated:Connect(function() onShoot(tool) end) -- отключается сам при Destroy инструмента
			end
		end
		local charConn
		local function hookChar(ch)
			if charConn then charConn:Disconnect() end
			for _, c in ipairs(ch:GetChildren()) do hookTool(c) end
			charConn = ch.ChildAdded:Connect(hookTool)
		end
		if LP.Character then hookChar(LP.Character) end
		track(LP.CharacterAdded:Connect(hookChar))
		track({ Disconnect = function() if charConn then charConn:Disconnect() end end })

		------------------------------------------------ Крылья и нимб (BulkMoveTo — быстрее, стиль только при изменении)
		local fx = {}
		local WF, HN = 9, 20
		local function mkNeon(col, tr)
			return new("Part", {
				Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
				Material = Enum.Material.Neon, Color = col, Transparency = tr, Size = Vector3.new(.2, .04, 1), Name = "NH_FX",
			}, Workspace)
		end
		local function ensure(list, n, col, tr)
			local changed = false
			while #list < n do list[#list + 1] = mkNeon(col, tr); changed = true end
			while #list > n do table.remove(list):Destroy(); changed = true end
			return changed
		end
		local function killFx(plr)
			local f = fx[plr]
			if f then
				for _, key in ipairs({ "wings", "halo" }) do
					for _, p in ipairs(f[key]) do p:Destroy() end
				end
				fx[plr] = nil
			end
		end
		track(Players.PlayerRemoving:Connect(killFx))
		local function wingL(i, len)
			local u = (i - 1) / (WF - 1)
			return len * (.55 + .45 * math.sin(math.pi * (.15 + .85 * u)))
		end
		X.addFrame(function()
			if not CFG.wings.on and not CFG.halo.on and not next(fx) then return end
			local t = os.clock()
			local pl, cl = {}, {}
			for _, plr in ipairs(Players:GetPlayers()) do
				local ch = plr.Character
				local torso = ch and (ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"))
				local head = ch and ch:FindFirstChild("Head")
				local hum = ch and ch:FindFirstChildOfClass("Humanoid")
				local alive_ = hum and hum.Health > 0
				local wantW = CFG.wings.on and (CFG.wings.scope == "Everyone" or plr == LP) and torso and alive_
				local wantH = CFG.halo.on and (CFG.halo.scope == "Everyone" or plr == LP) and head and alive_
				local f = fx[plr]
				if not (wantW or wantH) then
					if f then killFx(plr) end
				else
					if not f then
						f = { wings = {}, halo = {} }
						fx[plr] = f
					end
					if wantW then
						local len, wid = CFG.wings.len, CFG.wings.width
						local sig = len .. "|" .. wid .. "|" .. tostring(CFG.wings.color)
						if ensure(f.wings, WF * 2, CFG.wings.color, .25) or f.wsig ~= sig then
							f.wsig = sig
							local k = 0
							for _ = 1, 2 do
								for i = 1, WF do
									k += 1
									local p = f.wings[k]
									p.Size = Vector3.new(.14 * wid + .08, .04, wingL(i, len))
									p.Color = CFG.wings.color
								end
							end
						end
						local flap = math.sin(t * 3) * .12
						local base = torso.CFrame
						local k = 0
						for side = -1, 1, 2 do
							for i = 1, WF do
								k += 1
								local u = (i - 1) / (WF - 1)
								local a = math.rad(-25 + u * 75 * wid) + flap
								local dir = Vector3.new(side * math.cos(a), math.sin(a), .3).Unit
								local L = wingL(i, len)
								local shoulder = Vector3.new(side * .5, .6, .5)
								local cw = base:PointToWorldSpace(shoulder + dir * (L / 2))
								local dw = base:VectorToWorldSpace(dir)
								pl[#pl + 1] = f.wings[k]
								cl[#cl + 1] = CFrame.lookAt(cw, cw + dw)
							end
						end
					else
						ensure(f.wings, 0)
					end
					if wantH then
						local r = CFG.halo.radius
						local chord = 2 * r * math.sin(math.pi / HN) * 1.08
						local sig = r .. "|" .. tostring(CFG.halo.color)
						if ensure(f.halo, HN * 2, CFG.halo.color, .1) or f.hsig ~= sig then
							f.hsig = sig
							for _, p in ipairs(f.halo) do
								p.Size = Vector3.new(.1, .1, chord)
								p.Color = CFG.halo.color
							end
						end
						local center = head.Position + Vector3.new(0, head.Size.Y / 2 + .55, 0)
						for ring = 1, 2 do
							local tilt = ring == 1 and CFrame.Angles(0, 0, 0) or CFrame.Angles(math.rad(35), 0, math.rad(20))
							local cf = CFrame.new(center) * tilt
							local spin = t * (ring == 1 and 1.2 or -1.6)
							for i = 1, HN do
								local th = i / HN * math.pi * 2 + spin
								local wp = cf:PointToWorldSpace(Vector3.new(math.cos(th) * r, 0, math.sin(th) * r))
								local tan = cf:VectorToWorldSpace(Vector3.new(-math.sin(th), 0, math.cos(th)))
								pl[#pl + 1] = f.halo[(ring - 1) * HN + i]
								cl[#cl + 1] = CFrame.lookAt(wp, wp + tan)
							end
						end
					else
						ensure(f.halo, 0)
					end
				end
			end
			if #pl > 0 then Workspace:BulkMoveTo(pl, cl, Enum.BulkMoveMode.FireCFrameChanged) end
		end)

		------------------------------------------------ Headless / Korblox / God / Bunnyhop
		local orig = { head = setmetatable({}, { __mode = "k" }), kor = setmetatable({}, { __mode = "k" }) }
		local function setProp(key, part, prop, val)
			local o = orig[key]
			o[part] = o[part] or {}
			if o[part][prop] == nil then o[part][prop] = part[prop] end
			part[prop] = val
		end
		local function restoreKey(key)
			for part, props in pairs(orig[key]) do
				if part.Parent then
					for k, v in pairs(props) do pcall(function() part[k] = v end) end
				end
			end
			orig[key] = setmetatable({}, { __mode = "k" })
		end
		local godWas = false
		track(RunService.Heartbeat:Connect(function()
			local ch = LP.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if not hum or not root then return end

			if CFG.headless.on then
				local head = ch:FindFirstChild("Head")
				if head then
					setProp("head", head, "Transparency", 1)
					local face = head:FindFirstChildOfClass("Decal")
					if face then setProp("head", face, "Transparency", 1) end
				end
			elseif next(orig.head) then
				restoreKey("head")
			end

			if CFG.korblox.on then
				for _, n in ipairs({ "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg" }) do
					local p = ch:FindFirstChild(n)
					if p then
						setProp("kor", p, "Color", Color3.fromRGB(28, 28, 34))
						setProp("kor", p, "Material", Enum.Material.Metal)
					end
				end
			elseif next(orig.kor) then
				restoreKey("kor")
			end

			if CFG.god.on then
				godWas = true
				pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
				if hum.Health < hum.MaxHealth and hum.Health > 0 then hum.Health = hum.MaxHealth end
			elseif godWas then
				godWas = false
				pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end)
			end

			if CFG.bhop.on then
				local md = hum.MoveDirection
				local hold = UIS:IsKeyDown(Enum.KeyCode.Space) or hum.Jump
				if hold and md.Magnitude > 0 then
					local v = root.AssemblyLinearVelocity
					if hum.FloorMaterial ~= Enum.Material.Air then
						hum:ChangeState(Enum.HumanoidStateType.Jumping)
						root.AssemblyLinearVelocity = Vector3.new(md.X * CFG.bhop.dist, math.max(hum.JumpPower, 45), md.Z * CFG.bhop.dist)
					else
						root.AssemblyLinearVelocity = Vector3.new(md.X * CFG.bhop.dist, v.Y, md.Z * CFG.bhop.dist)
					end
				end
			end
		end))

		------------------------------------------------ Походки (паки анимаций)
		local PACKS = {
			Ninja = { 656117400, 656118341, 656121766, 656118852, 656117878, 656115606, 656114359 },
			Superhero = { 616111295, 616113536, 616122287, 616117076, 616115533, 616108001, 616104706 },
			Robot = { 616088211, 616089559, 616095330, 616091570, 616090535, 616087089, 616086039 },
			Cartoony = { 742637544, 742638445, 742640026, 742638842, 742637942, 742637151, 742636889 },
			Zombie = { 616158929, 616160636, 616168032, 616163682, 616161997, 616157476, 616156119 },
			Mage = { 707742142, 707855907, 707897309, 707861613, 707853694, 707829716, 707826056 },
			Pirate = { 750781874, 750782770, 750785693, 750783738, 750782230, 750780242, 750779899 },
			Knight = { 657595757, 657568135, 657552124, 657564596, 658409194, 657600338, 658360781 },
			Astronaut = { 891621366, 891633237, 891667138, 891636393, 891627522, 891617961, 891609353 },
			Levitation = { 616006778, 616008087, 616013216, 616010382, 616008936, 616005863, 616003713 },
			Stylish = { 616136790, 616138447, 616146177, 616140816, 616139451, 616134815, 616133594 },
			Toy = { 782841498, 782845736, 782843345, 782842708, 782847020, 782846423, 782843869 },
			Vampire = { 1083445855, 1083450166, 1083473930, 1083462077, 1083455352, 1083443587, 1083439238 },
			Werewolf = { 1083195517, 1083214717, 1083178339, 1083216690, 1083218792, 1083189019, 1083182000 },
			Bubbly = { 910004836, 910009958, 910034870, 910025107, 910016857, 910001910, 909997997 },
			Elder = { 845397899, 845400520, 845403856, 845386501, 845398858, 845396048, 845392038 },
		}
		X.PACK_LIST = { "Ninja", "Superhero", "Robot", "Cartoony", "Zombie", "Mage", "Pirate", "Knight", "Astronaut", "Levitation", "Stylish", "Toy", "Vampire", "Werewolf", "Bubbly", "Elder" }
		local SLOTS = { { "idle", "Animation1" }, { "idle", "Animation2" }, { "walk", "WalkAnim" }, { "run", "RunAnim" }, { "jump", "JumpAnim" }, { "fall", "FallAnim" }, { "climb", "ClimbAnim" } }
		local origAnim = setmetatable({}, { __mode = "k" })
		local lastChar, lastPack, applied = nil, nil, false
		local function packTargets(ch)
			local an = ch:FindFirstChild("Animate")
			local out = {}
			if an then
				for i, s in ipairs(SLOTS) do
					local f = an:FindFirstChild(s[1])
					local a = f and f:FindFirstChild(s[2])
					if a then out[i] = a end
				end
			end
			return an, out
		end
		task.spawn(function()
			while alive do
				local ch = LP.Character
				if ch then
					local an, targets = packTargets(ch)
					if an then
						if CFG.anim.on then
							if ch ~= lastChar or CFG.anim.pack ~= lastPack then
								lastChar, lastPack, applied = ch, CFG.anim.pack, true
								local pk = PACKS[CFG.anim.pack]
								for i, a in pairs(targets) do
									if origAnim[a] == nil then origAnim[a] = a.AnimationId end
									a.AnimationId = "rbxassetid://" .. pk[i]
								end
								an.Disabled = true
								task.wait(.05)
								an.Disabled = false
							end
						elseif applied then
							applied, lastChar, lastPack = false, nil, nil
							for a, id in pairs(origAnim) do
								if a.Parent then a.AnimationId = id end
							end
							origAnim = setmetatable({}, { __mode = "k" })
							an.Disabled = true
							task.wait(.05)
							an.Disabled = false
						end
					end
				end
				task.wait(.5)
			end
		end)

		------------------------------------------------ Эмоции
		local EMOTES = {
			["Wave"] = 507770239, ["Point"] = 507770453, ["Cheer"] = 507770677, ["Laugh"] = 507770818, ["Dance"] = 507771019,
			["Dance 2"] = 507776043, ["Dance 3"] = 507777268, ["Salute"] = 3360689775, ["Tilt"] = 3360692915,
			["Stadium"] = 3360686498, ["Shrug"] = 3576968026, ["Floss"] = 5917570207, ["Hype Dance"] = 3333499508,
		}
		X.EMOTE_LIST = { "Wave", "Point", "Cheer", "Laugh", "Dance", "Dance 2", "Dance 3", "Salute", "Tilt", "Stadium", "Shrug", "Floss", "Hype Dance" }
		local curTrack, lastTry = nil, 0
		function X.stopEmote()
			if curTrack then
				pcall(function() curTrack:Stop(.2) end)
				curTrack = nil
			end
		end
		function X.playEmote()
			X.stopEmote()
			local ch = LP.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if not hum then return false end
			local id = CFG.emote.id ~= "" and CFG.emote.id or tostring(EMOTES[CFG.emote.name] or "")
			if id == "" then return false end
			local animator = hum:FindFirstChildOfClass("Animator") or new("Animator", nil, hum)
			local a = new("Animation", { AnimationId = "rbxassetid://" .. id })
			local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
			a:Destroy()
			if not ok or not tr then return false end
			tr.Priority = Enum.AnimationPriority.Action
			tr.Looped = true
			tr:Play(.2)
			tr:AdjustSpeed(CFG.emote.speed)
			curTrack = tr
			return true
		end
		local stillT = 0
		track(RunService.Heartbeat:Connect(function(dt)
			if not CFG.emote.auto then
				stillT = 0
				return
			end
			local ch = LP.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if not hum or not root or hum.Health <= 0 then return end
			local still = hum.MoveDirection.Magnitude < .1 and root.AssemblyLinearVelocity.Magnitude < 1.5
				and hum.FloorMaterial ~= Enum.Material.Air
			if still then
				stillT += dt
				if stillT > .5 and not (curTrack and curTrack.IsPlaying) and os.clock() - lastTry > .6 then
					lastTry = os.clock()
					X.playEmote()
				end
			else
				stillT = 0
				if curTrack then X.stopEmote() end
			end
		end))

		------------------------------------------------ Auto grab gun
		local grabBusy = false
		local grabCool = setmetatable({}, { __mode = "k" })
		track(RunService.Heartbeat:Connect(function()
			if not CFG.grab.on or grabBusy or not X.guns then return end
			local ch = LP.Character
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if not root or not hum or hum.Health <= 0 then return end
			if X.roleOf(LP) == "Murderer" then return end
			local now = os.clock()
			for g in pairs(X.guns) do
				if g.Parent and (not grabCool[g] or grabCool[g] < now) then
					grabBusy = true
					grabCool[g] = now + 6
					task.spawn(function()
						local back = root.CFrame
						local part = g
						if g:IsA("Model") then part = g.PrimaryPart or g:FindFirstChildWhichIsA("BasePart", true) end
						if part then
							root.CFrame = part.CFrame * CFrame.new(0, 2, 0)
							if typeof(firetouchinterest) == "function" then
								pcall(function()
									firetouchinterest(root, part, 0)
									task.wait()
									firetouchinterest(root, part, 1)
								end)
							end
							local t0 = os.clock()
							while os.clock() - t0 < .7 and g.Parent do task.wait(.05) end
							if root.Parent then root.CFrame = back end
						end
						grabBusy = false
					end)
					break
				end
			end
		end))

		------------------------------------------------ Выгрузка
		X.onUnload(function()
			for plr in pairs(fx) do killFx(plr) end
			pcall(restoreKey, "head")
			pcall(restoreKey, "kor")
			pcall(X.stopEmote)
			for a, id in pairs(origAnim) do
				if a.Parent then a.AnimationId = id end
			end
			for _, f in ipairs(xPool) do pcall(function() f:Destroy() end) end
		end)
	end
	run()
end

----------------------------------------------------------------
-- СКИНЧЕНДЖЕР: каталог, фото (картинки/модели игры), применение к Gun / Knife, локальные предметы
----------------------------------------------------------------
do
	local function run()
		local StarterPack = game:GetService("StarterPack")

		local function hex(s)
			local n = tonumber(s, 16) or 0xffffff
			return Color3.fromRGB(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
		end
		local function hsh(s)
			local h = 0
			for i = 1, #s do h = (h * 31 + s:byte(i)) % 360 end
			return h / 360
		end
		local function parse(list)
			local out = {}
			for _, line in ipairs(list) do
				local f = {}
				for part in (line .. "|"):gmatch("([^|]*)|") do f[#f + 1] = part end
				local name, rar = f[1], f[2] or "Godly"
				local c1, c2
				if f[3] and f[3] ~= "" then
					c1 = hex(f[3])
					c2 = (f[4] and f[4] ~= "") and hex(f[4]) or c1:Lerp(Color3.new(0, 0, 0), .55)
				else
					local h = hsh(name)
					c1, c2 = Color3.fromHSV(h, .65, .95), Color3.fromHSV((h + .08) % 1, .8, .5)
				end
				out[#out + 1] = {
					name = name, rar = rar, c1 = c1, c2 = c2,
					rainbow = (rar == "Chroma") or (f[5] == "rb"),
				}
			end
			return out
		end

		-- имя|редкость|цвет1|цвет2|rb
		local GUNS = {
			"Rainbow Gun|Godly|ff5577|55aaff|rb", "Raygun|Godly|6cff3a|2a7a1e", "Red Luger|Godly|ff3b3b|7a1111",
			"Shark|Godly|9aa3b5|d83a3a", "Snowcannon|Godly|9fdcff|e8f6ff", "Soul|Godly|b9bcc8|3a3a46",
			"Spectre|Godly|4fe0d0|2a7f9a", "Sugar|Godly|ff4f6e|ffffff", "Sunrise|Godly|b04cff|ffc43a",
			"Swirly Gun|Godly|ff7ac8|7a6bff", "Traveler's Gun|Godly|ff9d2e|3b8f3b", "Vampire's Gun|Godly|a8102a|2a0a12",
			"Watergun|Godly|5dd13a|ff8a1f", "Xenoshot|Godly|9b4dff|2a1a5a", "Luger|Godly|c9ced8|4a4f5c",
			"Laser|Godly|ff3a6e|3ad1ff", "Elderwood Revolver|Godly|8b5a2b|3f2a14", "Constellation|Godly|6a5cff|14123a",
			"Ice Cannon|Godly|7fd6ff|2a6fb0", "Heartbreaker|Godly|ff5a8a|8a1a3a", "Blossom Gun|Godly|ffb3d1|ff6fa5",
			"Pumpkin Gun|Godly|ff8a1f|3a1f0a", "Ghost Gun|Godly|e8eef7|8a93a8", "Candy Gun|Godly|ff5a7a|7aff9a",
			"Frostbite Gun|Godly|8fe3ff|3a7ad1", "Prismatic Gun|Godly|ff7aa8|7ab8ff|rb", "Virtual Gun|Godly|3affb5|1a3a8a",
			"Bubblegum Gun|Godly|ff8fd0|8fd0ff", "Cyber Gun|Godly|3affea|ff3aa8", "Plasma Gun|Godly|a64dff|4dd2ff",
			"Dragon Gun|Godly|ff4a2a|2a0a0a", "Galaxy Gun|Godly|6a4dff|ff4dd2", "Neon Gun|Godly|3aff7a|ff3aa8",
			"Hallowgun|Godly|ff7a1a|2a1a3a", "Golden Gun|Unique|ffd54a|b8860b", "Blaster|Vintage|8a8f9a|3a3f4a",
			"Chroma Luger|Chroma|ff5577|55aaff", "Chroma Shark|Chroma|55ffaa|5577ff", "Chroma Tides|Chroma|55ddff|ff55aa",
			"Chroma Fade|Chroma|ff55ee|55ffdd", "Chroma Heat Gun|Chroma|ff7733|ffee33", "Chroma Raygun|Chroma|88ff44|44ddff",
			"Chroma Sunrise|Chroma|cc55ff|ffcc44", "Chroma Watergun|Chroma|44ffaa|ff9944",
		}
		local KNIVES = {
			"Seer|Godly|ffd34a|7a3aff", "Heat|Godly|ff7a1a|ffdd44", "Fang|Godly|e8e8f0|7a2a2a", "Slasher|Godly|c43a3a|2a2a34",
			"Gemstone|Godly|4affd8|b84aff", "Saw|Godly|b8bcc8|ff9a2a", "Boneblade|Godly|efe8d8|5a4a3a", "Harvester|Ancient|ff7a2a|2a1a0a",
			"Nikilis|Godly|8a2aff|1a0a3a", "Ice Dragon|Ancient|7fd6ff|2a5ab0", "Corrupt|Godly|7a2aa8|0a0a14", "Lightbringer|Godly|fff3b0|ffcf4a",
			"Darkbringer|Godly|3a2a5a|b84aff", "Icepiercer|Godly|aee6ff|3a7ad1", "Batwing|Godly|3a3a4a|ff3a5a", "Eternal|Godly|ff4a6a|ffcf4a",
			"Eternal II|Godly|ff6a8a|ffdf6a", "Eternal III|Godly|ff8aa8|ffef8a", "Eternal IV|Godly|ffaac8|fff0a8", "Gingerblade|Godly|c98a4a|ff4a4a",
			"Heartblade|Godly|ff5a8a|8a1a3a", "Pumpking|Godly|ff8a1f|3a1f0a", "Blossom|Godly|ffb3d1|ff6fa5", "Hallow's Blade|Godly|ff7a1a|2a1a3a",
			"Ghostblade|Godly|e8eef7|8a93a8", "Cookiecane|Godly|ff4a5a|ffffff", "Candy Knife|Godly|ff5a7a|7aff9a", "Flames|Godly|ff4a1a|ffcf2a",
			"Frostbite|Godly|8fe3ff|3a7ad1", "Bioblade|Godly|6aff3a|1a5a1a", "Icewing|Godly|b8f0ff|4a8aff", "Elderwood Scythe|Godly|8b5a2b|3f2a14",
			"Elderwood Blade|Godly|9b6a3b|4f3a24", "Ocean|Godly|3ad1ff|1a4a9a", "Swirly Blade|Godly|ff7ac8|7a6bff", "Handlebar|Godly|c9a24a|3a2a14",
			"Prismatic|Godly|ff7aa8|7ab8ff|rb", "Virtual|Godly|3affb5|1a3a8a", "Peppermint|Godly|ff4a5a|ffffff", "Deathshard|Godly|a8102a|1a0a14",
			"Chill|Godly|9fe8ff|3a7ad1", "Fade|Godly|ff55ee|55ffdd", "Iceblade|Godly|aee6ff|4a8aff", "Xmas|Godly|ff3a3a|3aff5a",
			"Splitter|Godly|ffaa2a|2a2a34", "Prince|Godly|ffd34a|4a2aff", "Tides|Godly|55ddff|1a5a9a", "Embersickle|Godly|ff5a1a|2a0a0a",
			"Mortal|Godly|3a3a4a|ff3a3a", "Immortal|Godly|e8e8f0|ffcf4a", "Alien|Godly|6aff8a|2a1a4a", "Bloody|Godly|b81a2a|2a0a0a",
			"Crimson|Godly|d42a4a|3a0a14", "Sakura|Godly|ffb3d1|ff6fa5", "Jade|Godly|3affa8|0a4a3a", "Phantom|Godly|a8a8ff|2a2a5a",
			"Chroma Seer|Chroma|ffd34a|7a3aff", "Chroma Fang|Chroma|e8e8f0|ff55aa", "Chroma Heat|Chroma|ff7a1a|ffdd44", "Chroma Slasher|Chroma|ff5555|55aaff",
			"Chroma Gemstone|Chroma|4affd8|b84aff", "Chroma Saw|Chroma|ffaa44|44aaff", "Chroma Boneblade|Chroma|efe8d8|ff55aa", "Chroma Darkbringer|Chroma|b84aff|55ffaa",
			"Chroma Lightbringer|Chroma|fff3b0|ff9a44", "Chroma Candleflame|Chroma|ffcf4a|ff4a4a", "Chroma Deathshard|Chroma|ff3355|33ddff", "Chroma Elderwood Blade|Chroma|9b6a3b|55ffaa",
		}
		local ITEMS = {
			"Teddy Bear|Item", "C4|Item|ff3b3b|7a1111", "Rubber Duck|Item|ffe14a|ff9a2a", "Balloon|Item|ff5a8a|ffffff", "Boombox|Item|3a3a4a|ff5a8a",
			"Crown|Item|ffd34a|b8860b", "Gem|Item|4affd8|b84aff", "Heart|Item|ff5a8a|8a1a3a", "Star|Item|ffe14a|ff9a2a", "Lantern|Item|ffcf4a|7a4a1a",
			"Ghost|Item|e8eef7|8a93a8", "Pet Rock|Item|8a8f9a|3a3f4a", "Candle|Item|fff3b0|ff9a2a", "Bomb|Item|2a2a34|ff3b3b", "Trophy|Item|ffd34a|b8860b",
			"Present|Item|ff3a3a|3aff5a", "Pizza|Item|ffb84a|ff4a3a", "Donut|Item|ff8fd0|c98a4a", "Bat|Item|8a5a2b|3f2a14", "Flashlight|Item|c9ced8|4a4f5c",
		}
		X.SKINS = { Gun = parse(GUNS), Knife = parse(KNIVES), Items = parse(ITEMS) }
		local byName = {}
		for kind, list in pairs(X.SKINS) do
			for _, s in ipairs(list) do byName[kind .. "|" .. s.name] = s end
		end

		local RAR = {
			Godly = Color3.fromRGB(165, 70, 255), Chroma = Color3.fromRGB(255, 255, 255), Ancient = Color3.fromRGB(255, 120, 40),
			Unique = Color3.fromRGB(255, 90, 200), Vintage = Color3.fromRGB(255, 200, 60), Item = Color3.fromRGB(110, 140, 255),
			Found = Color3.fromRGB(150, 110, 255),
		}

		------------------------------------------------ Индекс игры: модели + картинки предметов (фото)
		local function norm(s) return (tostring(s):lower():gsub("[^%w]", "")) end
		local Assets = { idx = {}, img = {}, state = 0, waiters = {} }
		X.Assets = Assets
		local function toUrl(v)
			if type(v) == "number" then return "rbxassetid://" .. v end
			if type(v) == "string" and v ~= "" then
				if v:find("^rbxassetid://") or v:find("^rbxasset://") or v:find("^http") then return v end
				if v:match("^%d+$") then return "rbxassetid://" .. v end
			end
			return nil
		end
		local function scanDB(t, depth, seen)
			if seen[t] or depth > 3 then return end
			seen[t] = true
			for k, v in pairs(t) do
				if type(v) == "table" then
					local nm = v.ItemName or v.DisplayName or v.Name or (type(k) == "string" and k or nil)
					local url = toUrl(v.Image or v.Icon or v.ImageId or v.ImageID or v.Thumbnail)
					if type(nm) == "string" and url then
						local key = norm(nm)
						if not Assets.img[key] then Assets.img[key] = url end
					else
						scanDB(v, depth + 1, seen)
					end
				end
			end
		end
		function Assets.start()
			if Assets.state ~= 0 then return end
			Assets.state = 1
			task.spawn(function()
				local mods, n = {}, 0
				for _, r in ipairs({ ReplicatedStorage, StarterPack, LP:FindFirstChild("Backpack"), LP.Character }) do
					if r then
						for _, d in ipairs(r:GetDescendants()) do
							n += 1
							if n % 1000 == 0 then task.wait() end
							if d:IsA("Tool") or d:IsA("Model") or d:IsA("MeshPart") then
								local k = norm(d.Name)
								local cur = Assets.idx[k]
								if not cur or (d:IsA("Tool") and not cur:IsA("Tool")) then Assets.idx[k] = d end
							elseif r == ReplicatedStorage and d:IsA("ModuleScript") and #mods < 6 then
								local ln = d.Name:lower()
								if ln == "item" or ln == "items" or ln == "itemdatabase" or ln == "itemdb" or ln == "weapons" or ln == "skins" then
									mods[#mods + 1] = d
								end
							end
						end
					end
				end
				Assets.state = 2
				for _, f in ipairs(Assets.waiters) do task.spawn(f) end
				for _, m in ipairs(mods) do
					local ok, res = pcall(require, m)
					if ok and type(res) == "table" then pcall(scanDB, res, 0, {}) end
					task.wait()
				end
				Assets.state = 3
				for _, f in ipairs(Assets.waiters) do task.spawn(f) end
			end)
		end
		function Assets.rescan()
			Assets.idx, Assets.img, Assets.state = {}, {}, 0
			Assets.start()
		end
		local function variants(name)
			local k = norm(name)
			local out = { k }
			local a = k:gsub("gun$", "")
			if a ~= k and #a > 2 then out[#out + 1] = a end
			local b = k:gsub("blade$", "")
			if b ~= k and #b > 2 then out[#out + 1] = b end
			local c = k:gsub("^chroma", "")
			if c ~= k and #c > 2 then out[#out + 1] = c end
			return out
		end
		function Assets.model(name)
			for _, k in ipairs(variants(name)) do
				local m = Assets.idx[k]
				if m then return m end
			end
			return nil
		end
		function Assets.image(name)
			for _, k in ipairs(variants(name)) do
				local u = Assets.img[k]
				if u then return u end
			end
			return nil
		end

		------------------------------------------------ Применение скина к реальным инструментам Gun / Knife
		X.rbParts = setmetatable({}, { __mode = "k" })
		X.rbParts3 = setmetatable({}, { __mode = "k" })
		X.rbStrokes = setmetatable({}, { __mode = "k" })
		local applied = setmetatable({}, { __mode = "k" })

		local function cleanClone(clone)
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("LuaSourceContainer") or d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Constraint") then
					d:Destroy()
				end
			end
		end
		-- переносит все BasePart ассета в tool и приваривает к handle (без запуска чужих скриптов)
		local function attachModel(tool, handle, asset)
			local clone = asset:Clone()
			cleanClone(clone)
			local parts = {}
			if clone:IsA("BasePart") then parts[1] = clone end
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("BasePart") then parts[#parts + 1] = d end
			end
			if #parts == 0 then
				clone:Destroy()
				return nil
			end
			local ref = clone:FindFirstChild("Handle", true)
			if not (ref and ref:IsA("BasePart")) then ref = parts[1] end
			if clone:IsA("BasePart") and clone.Name == "Handle" then ref = clone end
			local offs = {}
			for i, p in ipairs(parts) do offs[i] = ref.CFrame:ToObjectSpace(p.CFrame) end
			for i, p in ipairs(parts) do
				p.Name = "NH_SkinPart"
				p.Anchored = false
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
				p.Massless = true
				p.Parent = tool
				new("Weld", { Part0 = handle, Part1 = p, C0 = offs[i] }, p)
			end
			if clone ~= parts[1] then clone:Destroy() end
			return parts
		end

		local function clearSkin(tool)
			local rec = applied[tool]
			if not rec then return end
			for _, p in ipairs(rec.parts) do pcall(function() p:Destroy() end) end
			for _, p in ipairs(rec.hidden) do
				if p.Parent then p.LocalTransparencyModifier = 0 end
			end
			for p, o in pairs(rec.tint) do
				X.rbParts3[p] = nil
				if p.Parent then
					for k, v in pairs(o) do pcall(function() p[k] = v end) end
				end
			end
			applied[tool] = nil
		end
		local function applySkin(tool, def)
			local handle = tool:FindFirstChild("Handle")
			if not handle or not handle:IsA("BasePart") then return end
			local rec = { name = def.name, parts = {}, hidden = {}, tint = {}, handle = handle, lastTr = -1 }
			local asset = Assets.model(def.name)
			local parts = asset and attachModel(tool, handle, asset)
			if parts then
				rec.parts = parts
				for _, d in ipairs(tool:GetDescendants()) do
					if d:IsA("BasePart") and d.Name ~= "NH_SkinPart" then
						d.LocalTransparencyModifier = 1
						rec.hidden[#rec.hidden + 1] = d
					end
				end
			else
				rec.tinted = true
				local first = true
				for _, d in ipairs(tool:GetDescendants()) do
					if d:IsA("BasePart") and d.Name ~= "NH_SkinPart" then
						rec.tint[d] = { Color = d.Color, Material = d.Material }
						d.Color = first and def.c1 or def.c2
						d.Material = Enum.Material.Neon
						first = false
						if def.rainbow then X.rbParts3[d] = true end
					end
				end
			end
			applied[tool] = rec
		end

		local function findTool(name)
			local c, b = LP.Character, LP:FindFirstChild("Backpack")
			return (c and c:FindFirstChild(name)) or (b and b:FindFirstChild(name)) or nil
		end

		------------------------------------------------ Локальные инструменты (предметы / предпросмотр в руке / Found)
		local given, holds = {}, {}
		local function pp(tool, handle, size, cf, col, mat, shape)
			local p = new("Part", {
				Name = "NH_SkinPart", Size = size, Color = col, Material = mat or Enum.Material.SmoothPlastic, CanCollide = false,
				CanTouch = false, CanQuery = false, Massless = true, Shape = shape or Enum.PartType.Block,
			})
			new("Weld", { Part0 = handle, Part1 = p, C0 = cf }, p)
			p.Parent = tool
			return p
		end
		local function buildPrim(tool, handle, kind, def)
			if kind == "Gun" then
				pp(tool, handle, Vector3.new(.35, .45, 1.8), CFrame.new(0, .3, -.9), def.c1, Enum.Material.Metal)
				pp(tool, handle, Vector3.new(.37, .12, 1.4), CFrame.new(0, .56, -.8), def.c2, Enum.Material.Neon)
				pp(tool, handle, Vector3.new(.3, .9, .4), CFrame.new(0, -.2, .05) * CFrame.Angles(math.rad(-12), 0, 0), def.c2, Enum.Material.SmoothPlastic)
				pp(tool, handle, Vector3.new(.2, .2, .35), CFrame.new(0, .3, -1.9), def.c1, Enum.Material.Neon)
			else
				pp(tool, handle, Vector3.new(.12, .5, 2.0), CFrame.new(0, .1, -1.4), def.c1, Enum.Material.Metal)
				pp(tool, handle, Vector3.new(.12, .38, .38), CFrame.new(0, .1, -2.5) * CFrame.Angles(math.rad(45), 0, 0), def.c1, Enum.Material.Metal)
				pp(tool, handle, Vector3.new(.14, .95, .2), CFrame.new(0, 0, -.35), def.c2, Enum.Material.Neon)
				pp(tool, handle, Vector3.new(.2, .2, .9), CFrame.new(0, 0, .15), def.c2, Enum.Material.SmoothPlastic)
			end
		end
		local function makeHoldTool(kind, def)
			local bp = LP:FindFirstChild("Backpack")
			if not bp then return nil end
			local tool = new("Tool", { Name = "NH_" .. kind, CanBeDropped = false, ToolTip = def.name, RequiresHandle = true })
			local handle = new("Part", {
				Name = "Handle", Size = Vector3.new(.4, .4, .4), Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false,
				Massless = true,
			}, tool)
			local asset = Assets.model(def.name)
			local parts = asset and attachModel(tool, handle, asset)
			if parts then
				if asset:IsA("Tool") then
					pcall(function()
						tool.GripPos, tool.GripForward = asset.GripPos, asset.GripForward
						tool.GripRight, tool.GripUp = asset.GripRight, asset.GripUp
					end)
				end
			else
				buildPrim(tool, handle, kind, def)
			end
			tool.Parent = bp
			return tool, parts ~= nil
		end

		function X.toggleItem(name)
			if given[name] then
				given[name]:Destroy()
				given[name] = nil
				return false
			end
			local s = byName["Items|" .. name]
			local bp = LP:FindFirstChild("Backpack")
			if not s or not bp then return false end
			local tool = new("Tool", { Name = name, CanBeDropped = false, ToolTip = name, RequiresHandle = true })
			local h = new("Part", {
				Name = "Handle", Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), Color = s.c1,
				Material = Enum.Material.SmoothPlastic, CanCollide = false,
			}, tool)
			local function bit(size, off, col, shape)
				local p = new("Part", {
					Size = size, Color = col, Material = Enum.Material.SmoothPlastic, CanCollide = false, Massless = true,
					Shape = shape or Enum.PartType.Ball,
				}, tool)
				p.CFrame = h.CFrame * CFrame.new(off)
				new("WeldConstraint", { Part0 = h, Part1 = p }, p)
			end
			if name == "C4" or name == "Bomb" then
				h.Shape = Enum.PartType.Block
				h.Size = Vector3.new(1.5, 1, .6)
				h.Color = Color3.fromRGB(190, 40, 40)
				bit(Vector3.new(1, .4, .1), Vector3.new(0, .1, -.35), Color3.fromRGB(20, 20, 24), Enum.PartType.Block)
				bit(Vector3.new(.1, .6, .1), Vector3.new(.5, .7, 0), Color3.fromRGB(230, 230, 230), Enum.PartType.Block)
				bit(Vector3.new(.3, .3, .1), Vector3.new(-.4, .1, -.35), Color3.fromRGB(80, 255, 90), Enum.PartType.Block)
			else
				bit(Vector3.new(.55, .55, .55), Vector3.new(-.5, .75, 0), s.c2)
				bit(Vector3.new(.55, .55, .55), Vector3.new(.5, .75, 0), s.c2)
				bit(Vector3.new(.6, .6, .6), Vector3.new(0, -.2, -.6), s.c2)
			end
			tool.Parent = bp
			given[name] = tool
			return true
		end
		function X.hasItem(name) return given[name] ~= nil end

		-- реальные инструменты игры (вкладка Found)
		local foundGiven = {}
		function X.scanFound()
			local out, seen = {}, {}
			for _, r in ipairs({ ReplicatedStorage, StarterPack, LP:FindFirstChild("Backpack") }) do
				if r then
					for _, d in ipairs(r:GetDescendants()) do
						if d:IsA("Tool") and not seen[d.Name] and #out < 400 then
							seen[d.Name] = true
							out[#out + 1] = d
						end
					end
				end
			end
			table.sort(out, function(a, b) return a.Name < b.Name end)
			return out
		end
		function X.toggleFound(tool)
			if foundGiven[tool.Name] then
				foundGiven[tool.Name]:Destroy()
				foundGiven[tool.Name] = nil
				return false
			end
			local bp = LP:FindFirstChild("Backpack")
			if not bp then return false end
			local ok, c = pcall(function() return tool:Clone() end)
			if not ok or not c then return false end
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("LuaSourceContainer") then d:Destroy() end
			end
			c.Parent = bp
			foundGiven[tool.Name] = c
			return true
		end
		function X.hasFound(name) return foundGiven[name] ~= nil end

		------------------------------------------------ Цикл применения
		task.spawn(function()
			while alive do
				if CFG.skin.gun ~= "" or CFG.skin.knife ~= "" or next(applied) then Assets.start() end
				for kind, toolName in pairs({ Gun = "Gun", Knife = "Knife" }) do
					local want = CFG.skin[kind:lower()]
					for _, holder in ipairs({ LP.Character, LP:FindFirstChild("Backpack") }) do
						local tool = holder and holder:FindFirstChild(toolName)
						if tool and tool:IsA("Tool") then
							local rec = applied[tool]
							if want ~= "" then
								if rec and (rec.name ~= want or (rec.tinted and Assets.state >= 2 and Assets.model(want))) then
									clearSkin(tool)
									rec = nil
								end
								if not rec then
									local def = byName[kind .. "|" .. want]
									if def then pcall(applySkin, tool, def) end
								end
							elseif rec then
								clearSkin(tool)
							end
						end
					end

					-- предпросмотр в руке, если настоящего оружия нет
					local h = holds[kind]
					local need = CFG.skin.hold and want ~= "" and not findTool(toolName)
					if h and (not need or h.skin ~= want or not h.tool.Parent or (not h.real and Assets.model(want))) then
						pcall(function() h.tool:Destroy() end)
						holds[kind] = nil
						h = nil
					end
					if need and not h then
						local def = byName[kind .. "|" .. want]
						if def then
							local ok, tool, real = pcall(makeHoldTool, kind, def)
							if ok and tool then holds[kind] = { tool = tool, skin = want, real = real } end
						end
					end
				end
				task.wait(.5)
			end
		end)
		-- прозрачность наших деталей повторяет прозрачность родной рукояти (бросок ножа и т.п.)
		X.addFrame(function()
			for _, rec in pairs(applied) do
				local h = rec.handle
				if h and h.Parent and #rec.parts > 0 then
					local tr = h.Transparency
					if tr ~= rec.lastTr then
						rec.lastTr = tr
						for _, p in ipairs(rec.parts) do p.LocalTransparencyModifier = tr end
					end
				end
			end
		end)
		-- радужные (Chroma) плитки и детали
		local rbT = 0
		X.addFrame(function()
			local now = os.clock()
			if now - rbT < .05 then return end
			rbT = now
			local col = Color3.fromHSV((now * .3) % 1, .8, 1)
			for p in pairs(X.rbParts) do
				if p.Parent then p.BackgroundColor3 = col end
			end
			for s in pairs(X.rbStrokes) do
				if s.Parent then s.Color = col end
			end
		end)
		-- в 3D те же Chroma-детали красим отдельным циклом (Color, а не BackgroundColor3)
		X.addFrame(function()
			for p in pairs(X.rbParts3) do
				if p.Parent then p.Color = Color3.fromHSV((os.clock() * .3) % 1, .85, 1) end
			end
		end)

		X.onUnload(function()
			for tool in pairs(applied) do
				if tool.Parent then pcall(clearSkin, tool) end
			end
			for _, t in pairs(given) do pcall(function() t:Destroy() end) end
			for _, t in pairs(foundGiven) do pcall(function() t:Destroy() end) end
			for _, h in pairs(holds) do pcall(function() h.tool:Destroy() end) end
		end)

		------------------------------------------------ Плитки с фото (как в Star Hub) + поиск
		local function art(parent, kind, c1, c2)
			local parts = {}
			local function box(w, h, x, y, rot, col, rad)
				local f = new("Frame", {
					AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
					Rotation = rot, BackgroundColor3 = col, BorderSizePixel = 0,
				}, parent)
				corner(f, rad or 3)
				parts[#parts + 1] = f
				return f
			end
			local glow = box(44, 44, 31, 26, 0, c1, 22)
			glow.BackgroundTransparency = .86
			if kind == "Gun" then
				box(38, 12, 29, 19, 0, c1, 4)
				box(14, 5, 52, 21, 0, c2, 2)
				box(9, 20, 20, 33, 14, c2, 3)
				box(8, 4, 40, 29, 0, c1, 2)
				box(20, 3, 28, 15, 0, WHITE, 1).BackgroundTransparency = .55
			elseif kind == "Knife" then
				box(38, 8, 36, 20, -38, c1, 4)
				box(9, 14, 20, 32, -38, c2, 2)
				box(15, 6, 14, 39, -38, c2, 3)
				box(26, 2, 38, 18, -38, WHITE, 1).BackgroundTransparency = .55
			else
				box(26, 26, 30, 28, 0, c1, 13)
				box(12, 12, 20, 12, 0, c2, 6)
				box(12, 12, 40, 12, 0, c2, 6)
				box(10, 10, 30, 32, 0, c2, 5)
			end
			return parts
		end

		local function thumb(parent, asset)
			local vp = new("ViewportFrame", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(170, 170, 180),
				LightColor = WHITE, LightDirection = Vector3.new(-1, -1, -.5), ZIndex = 3,
			}, parent)
			local model = new("Model", nil, vp)
			local count = 0
			local function add(p)
				if count >= 60 then return end
				local ok, c = pcall(function() return p:Clone() end)
				if ok and c then
					for _, ch in ipairs(c:GetDescendants()) do
						if ch:IsA("LuaSourceContainer") then ch:Destroy() end
					end
					c.Anchored = true
					c.Parent = model
					count += 1
				end
			end
			if asset:IsA("BasePart") then
				add(asset)
			else
				for _, d in ipairs(asset:GetDescendants()) do
					if d:IsA("BasePart") then add(d) end
				end
			end
			if count == 0 then
				vp:Destroy()
				return nil
			end
			local cf, size = model:GetBoundingBox()
			local cam = new("Camera", { FieldOfView = 35 }, vp)
			vp.CurrentCamera = cam
			local dist = math.max(size.Magnitude, 1) * 1.6
			cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(1, .55, 1).Unit * dist, cf.Position)
			return vp
		end

		-- сетка плиток: виртуализация (фото грузятся только для видимых плиток)
		local function TileGrid(sf)
			local holder = new("Frame", {
				Size = UDim2.new(1, 0, 0, 60), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = ord(),
			}, sf)
			new("UIGridLayout", {
				CellSize = UDim2.fromOffset(70, 88), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder,
			}, holder)
			local G = { tiles = {}, query = "", artKind = "Gun" }

			local function unloadVisual(t)
				if t.vis then
					t.vis:Destroy()
					t.vis = nil
					for _, p in ipairs(t.parts) do p.Visible = true end
				end
			end
			local function loadVisual(t)
				if t.vis or t.loading or t.fail then return end
				local e = t.e
				local url = (not e.asset) and Assets.image(e.name) or nil
				if url then
					t.loading = true
					local img = new("ImageLabel", {
						BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = url, ScaleType = Enum.ScaleType.Fit, ZIndex = 3,
					}, t.art)
					task.spawn(function()
						local t0 = os.clock()
						while img.Parent and not img.IsLoaded and os.clock() - t0 < 4 do task.wait(.1) end
						t.loading = false
						if img.Parent and img.IsLoaded then
							t.vis = img
							for _, p in ipairs(t.parts) do p.Visible = false end
						else
							img:Destroy()
							t.fail = true
						end
					end)
					return
				end
				local m = e.asset or Assets.model(e.name)
				if m then
					local ok, vp = pcall(thumb, t.art, m)
					if ok and vp then
						t.vis = vp
						for _, p in ipairs(t.parts) do p.Visible = false end
					else
						t.fail = true
					end
				end
			end

			function G.clear()
				for _, t in ipairs(G.tiles) do t.btn:Destroy() end
				G.tiles = {}
			end
			function G.render()
				for _, t in ipairs(G.tiles) do
					local sel = G.isSel and G.isSel(t.e) or false
					if t.e.rainbow then
						X.rbStrokes[t.st] = true
					else
						t.st.Color = t.rc
					end
					t.st.Thickness = sel and 3 or 1.5
					t.badge.Visible = sel
				end
			end
			function G.filter()
				for _, t in ipairs(G.tiles) do
					t.btn.Visible = G.query == "" or t.e.name:lower():find(G.query, 1, true) ~= nil
				end
			end
			function G.set(entries, artKind, pick, isSel)
				G.clear()
				G.isSel = isSel
				for i, e in ipairs(entries) do
					local rc = RAR[e.rar] or RAR.Godly
					local b = new("TextButton", {
						Size = UDim2.fromOffset(70, 88), BackgroundColor3 = Color3.fromRGB(16, 14, 24), BorderSizePixel = 0,
						AutoButtonColor = false, Text = "", LayoutOrder = i,
					}, holder)
					corner(b, 10)
					local st = stroke(b, rc, 1.5)
					local artBox = new("Frame", {
						Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(62, 52), BackgroundColor3 = e.c2,
						BackgroundTransparency = .82, BorderSizePixel = 0, ClipsDescendants = true,
					}, b)
					corner(artBox, 8)
					local parts = art(artBox, artKind, e.c1, e.c2)
					if e.rainbow then
						for _, p in ipairs(parts) do X.rbParts[p] = true end
					end
					new("TextLabel", {
						BackgroundTransparency = 1, Position = UDim2.fromOffset(2, 57), Size = UDim2.fromOffset(66, 28),
						Font = Enum.Font.GothamMedium, Text = e.name, TextSize = 9, TextColor3 = C.text, TextWrapped = true,
					}, b)
					local badge = new("Frame", {
						AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -5, 0, 5), Size = UDim2.fromOffset(10, 10),
						BackgroundColor3 = C.good, BorderSizePixel = 0, Visible = false, ZIndex = 5,
					}, b)
					corner(badge, 5)
					local t = { btn = b, st = st, e = e, art = artBox, parts = parts, badge = badge, rc = rc }
					G.tiles[#G.tiles + 1] = t
					b.MouseEnter:Connect(function() tw(b, .12, { BackgroundColor3 = Color3.fromRGB(26, 22, 40) }) end)
					b.MouseLeave:Connect(function() tw(b, .12, { BackgroundColor3 = Color3.fromRGB(16, 14, 24) }) end)
					b.MouseButton1Click:Connect(function()
						pick(e)
						X.refreshAll()
					end)
				end
				G.filter()
				G.render()
			end
			function G.setQuery(q)
				G.query = q:lower()
				G.filter()
			end
			function G.refreshVisuals()
				for _, t in ipairs(G.tiles) do
					if t.fail and not t.vis then t.fail = false end
				end
			end
			Assets.waiters[#Assets.waiters + 1] = function() G.refreshVisuals() end
			X.reg(G.render)

			task.spawn(function()
				while alive do
					if sf.Parent and sf.Parent.Visible and #G.tiles > 0 then
						local top = sf.AbsolutePosition.Y
						local bot = top + sf.AbsoluteSize.Y
						for _, t in ipairs(G.tiles) do
							if t.btn.Visible then
								local y = t.btn.AbsolutePosition.Y
								local inRange = (y + 90 > top - 120) and (y < bot + 120)
								if inRange then loadVisual(t) else unloadVisual(t) end
							end
						end
					end
					task.wait(.2)
				end
			end)
			return G
		end

		local function searchBox(parent)
			local sb = new("TextBox", {
				Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.field, BorderSizePixel = 0, Font = Enum.Font.GothamMedium,
				TextSize = 12, TextColor3 = C.text, PlaceholderText = "Search skin...", PlaceholderColor3 = C.sub, Text = "",
				ClearTextOnFocus = false, LayoutOrder = ord(),
			}, parent)
			corner(sb, 8)
			stroke(sb, C.line, 1)
			new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, sb)
			return sb
		end

		-- страницы Gun / Knife
		function X.buildSkinPage(kind, icon, grp)
			local sf = createTab(kind, icon, "skin changer", grp)
			new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
			local cTop = Card(sf, "Skin changer")
			local sb = searchBox(cTop)
			Toggle(cTop, "Hold preview", CFG.skin, "hold")
			Label(cTop, "Skins are applied on your client (only you see them). Photos come from the game's own assets when available.", C.sub, 11)
			local key = kind:lower()
			Button(cTop, "Reset skin", function()
				CFG.skin[key] = ""
				X.refreshAll()
			end)
			local grid = TileGrid(sf)
			grid.set(X.SKINS[kind], kind, function(e)
				CFG.skin[key] = (CFG.skin[key] == e.name) and "" or e.name
				Assets.start()
			end, function(e) return CFG.skin[key] == e.name end)
			sb:GetPropertyChangedSignal("Text"):Connect(function() grid.setQuery(sb.Text) end)
		end

		-- страница Items (+ Found)
		function X.buildItemsPage(grp)
			local sf = createTab("Items", "items", "local items", grp)
			new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
			local cTop = Card(sf, "Items")
			local cat = "Items"
			local grid
			local function build()
				if cat == "Items" then
					grid.set(X.SKINS.Items, "Items", function(e) X.toggleItem(e.name) end, function(e) return X.hasItem(e.name) end)
				else
					local list = {}
					for _, tool in ipairs(X.scanFound()) do
						list[#list + 1] = {
							name = tool.Name, rar = "Found", c1 = Color3.fromRGB(150, 110, 255), c2 = Color3.fromRGB(70, 50, 120),
							rainbow = false, asset = tool,
						}
					end
					grid.set(list, "Items", function(e) X.toggleFound(e.asset) end, function(e) return X.hasFound(e.name) end)
				end
			end
			X.Grid(cTop, { "Items", "Found" }, function() return cat end, function(n)
				cat = n
				build()
			end, 2)
			local sb = searchBox(cTop)
			Label(cTop, "Local tools: only you see them. Found = real tools from the game's storage.", C.sub, 11)
			Button(cTop, "Rescan game assets", function()
				Assets.rescan()
				build()
			end)
			Button(cTop, "Remove all", function()
				for _, e in ipairs(X.SKINS.Items) do
					if X.hasItem(e.name) then X.toggleItem(e.name) end
				end
				for _, tool in ipairs(X.scanFound()) do
					if X.hasFound(tool.Name) then X.toggleFound(tool) end
				end
				X.refreshAll()
			end)
			grid = TileGrid(sf)
			build()
			sb:GetPropertyChangedSignal("Text"):Connect(function() grid.setQuery(sb.Text) end)
		end
	end
	run()
end

----------------------------------------------------------------
-- СТРАНИЦЫ: Visual / Player / World / Misc / Emote / Skin changer / Config / Setting
----------------------------------------------------------------
local grpSkin
do
	local function build()
		local FL, DR, Grid, PL = X.FLabel, X.DrawerRow, X.Grid, X.PlayerList
		local function pct(v) return math.floor(v * 100 + .5) .. "%" end

		local function IdBox(parent, ph, get, set)
			local tb = new("TextBox", {
				Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.field, BorderSizePixel = 0, Font = Enum.Font.GothamMedium,
				TextSize = 12, TextColor3 = C.text, PlaceholderText = ph, PlaceholderColor3 = C.sub, Text = get(),
				ClearTextOnFocus = false, LayoutOrder = ord(),
			}, parent)
			corner(tb, 8)
			stroke(tb, C.line, 1)
			tb.FocusLost:Connect(function()
				local digits = tb.Text:gsub("%D", "")
				set(digits)
				tb.Text = digits
			end)
			X.reg(function() tb.Text = get() end)
			return tb
		end

		-- цвета стрелок: убийца / шериф / каждый игрок отдельно
		local function arrowDrawer(dr)
			FL(dr, "Murderer arrow")
			ColorPicker(dr, CFG.arrows, "murder")
			FL(dr, "Sheriff arrow")
			ColorPicker(dr, CFG.arrows, "sheriff")
			FL(dr, "Pick a player / tap the circle to change his arrow color")
			PL(dr, 150, function() end, true, nil, CFG.acolor)
		end

		------------------------------------------------------------ VISUAL
		local sfV = createTab("Visual", "eye", "esp & render")
		local L, R = Columns(sfV)

		local cGen = Card(L, "General")
		Toggle(cGen, "ESP master", CFG.esp, "on")
		Toggle(cGen, "Role colors", CFG.esp, "roles")
		Toggle(cGen, "Game role sync", CFG.esp, "sync")
		Slider(cGen, "Max distance", 100, 5000, CFG.esp, "maxDist", { fmt = function(v) return v .. " st" end })
		DR(cGen, "ESP for...", function(dr)
			FL(dr, "Show ESP only for")
			Grid(dr, { "All", "Murder", "Sheriff" }, function() return CFG.target.mode end, function(n) CFG.target.mode = n end, 3)
			FL(dr, "Pick a player / tap the circle to change his color")
			PL(dr, 150, function(plr)
				CFG.target.mode = "Player"
				CFG.target.userId = plr.UserId
			end, true, function(plr) return CFG.target.mode == "Player" and CFG.target.userId == plr.UserId end)
		end)

		local cBox = Card(L, "Boxes")
		Toggle(cBox, "Esp box 2D", CFG.box2d, "on", function(dr) ColorPicker(dr, CFG.box2d, "color") end)
		Toggle(cBox, "Esp box 3D", CFG.box3d, "on", function(dr) ColorPicker(dr, CFG.box3d, "color") end)
		Toggle(cBox, "Corner box", CFG.corner, "on", function(dr)
			ColorPicker(dr, CFG.corner, "color")
			Slider(dr, "Length", 10, 50, CFG.corner, "len", { fmt = function(v) return v .. "%" end })
		end)
		Toggle(cBox, "Filled box", CFG.fill, "on", function(dr)
			GradientPicker(dr, CFG.fill, "c1", "c2")
			Slider(dr, "Transparency", 0, 100, CFG.fill, "trans", { div = 100, fmt = pct })
		end)

		local cInfo = Card(L, "Info")
		Toggle(cInfo, "Show nickname", CFG.name, "on", function(dr) ColorPicker(dr, CFG.name, "color") end)
		Toggle(cInfo, "Show distance", CFG.dist, "on", function(dr) ColorPicker(dr, CFG.dist, "color") end)
		Toggle(cInfo, "Show health", CFG.health, "on", function(dr) ColorPicker(dr, CFG.health, "color") end)
		Toggle(cInfo, "Show avatar", CFG.avatar, "on", function(dr) ColorPicker(dr, CFG.avatar, "color") end)

		local cHud = Card(L, "HUD")
		Toggle(cHud, "Show FPS", CFG.fps, "on", function(dr)
			ColorPicker(dr, CFG.fps, "color")
			Toggle(dr, "Custom FPS", CFG.fps, "custom")
			local row = new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, LayoutOrder = ord() }, dr)
			local tb = new("TextBox", {
				Size = UDim2.fromOffset(84, 38), BackgroundColor3 = C.field, BorderSizePixel = 0, Font = Enum.Font.GothamBold,
				TextSize = 16, TextColor3 = C.accent, Text = tostring(CFG.fps.value), ClearTextOnFocus = false,
				PlaceholderText = "999", PlaceholderColor3 = C.sub,
			}, row)
			corner(tb, 10)
			stroke(tb, C.line, 1.5)
			new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(92, 0), Size = UDim2.new(1, -92, 1, 0),
				Font = Enum.Font.GothamMedium, Text = "Drag the badge across the screen", TextSize = 10, TextColor3 = C.sub,
				TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
			}, row)
			tb.FocusLost:Connect(function()
				local n = tonumber(tb.Text)
				if n then CFG.fps.value = math.clamp(math.floor(n), 1, 99999) end
				tb.Text = tostring(CFG.fps.value)
			end)
			X.reg(function() tb.Text = tostring(CFG.fps.value) end)

			local st = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = WHITE, BorderSizePixel = 0, AutoButtonColor = false,
				Text = "", LayoutOrder = ord(),
			}, dr)
			corner(st, 10)
			stroke(st, C.line, 1)
			new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(40, 44, 78), Color3.fromRGB(16, 17, 30)) }, st)
			local badge = new("TextLabel", {
				Size = UDim2.fromOffset(58, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, Text = "60 FPS",
			}, st)
			local function place()
				badge.AnchorPoint = Vector2.new(CFG.fps.x, CFG.fps.y)
				badge.Position = UDim2.fromScale(CFG.fps.x, CFG.fps.y)
				badge.TextColor3 = CFG.fps.color
			end
			place()
			X.reg(place)
			local function upd(i)
				local pos = (i.UserInputType == Enum.UserInputType.Touch) and Vector2.new(i.Position.X, i.Position.Y) or UIS:GetMouseLocation()
				CFG.fps.x = math.clamp((pos.X - st.AbsolutePosition.X) / math.max(st.AbsoluteSize.X, 1), 0, 1)
				CFG.fps.y = math.clamp((pos.Y - st.AbsolutePosition.Y) / math.max(st.AbsoluteSize.Y, 1), 0, 1)
				place()
			end
			st.InputBegan:Connect(function(i)
				if isPress(i) then
					local unlock = lockScroll(st)
					upd(i)
					beginDrag(upd, unlock)
				end
			end)
		end)

		local cRen = Card(R, "Render")
		Toggle(cRen, "Chams", CFG.chams, "on", function(dr)
			ColorPicker(dr, CFG.chams, "color")
			Slider(dr, "Fill transparency", 0, 100, CFG.chams, "trans", { div = 100, fmt = pct })
		end)
		Toggle(cRen, "Outline", CFG.outline, "on", function(dr) ColorPicker(dr, CFG.outline, "color") end)
		Toggle(cRen, "Wall check", CFG.wall, "on", function(dr)
			FL(dr, "Color behind a wall")
			ColorPicker(dr, CFG.wall, "hid")
			FL(dr, "Color when visible")
			ColorPicker(dr, CFG.wall, "vis")
		end)
		Toggle(cRen, "Glow", CFG.glow, "on", function(dr)
			ColorPicker(dr, CFG.glow, "color")
			Slider(dr, "Range", 5, 60, CFG.glow, "range")
			Slider(dr, "Brightness", 5, 60, CFG.glow, "bright", { div = 10 })
		end)
		Toggle(cRen, "Custom FOV", CFG.fov, "on", function(dr)
			Slider(dr, "Field of view", 30, 120, CFG.fov, "val")
		end)
		Toggle(cRen, "Third person", CFG.third, "on", function(dr)
			Slider(dr, "Distance", 4, 40, CFG.third, "dist", { fmt = function(v) return v .. " st" end })
		end)

		local cLin = Card(R, "Lines")
		Toggle(cLin, "Line / Tracers", CFG.tracer, "on", function(dr)
			Dropdown(dr, "Line origin", { "Crosshair", "Bottom", "Top" }, CFG.tracer, "origin")
			ColorPicker(dr, CFG.tracer, "color")
		end)
		Toggle(cLin, "Skeleton", CFG.skel, "on", function(dr) ColorPicker(dr, CFG.skel, "color") end)
		Toggle(cLin, "Show head", CFG.head, "on", function(dr) ColorPicker(dr, CFG.head, "color") end)
		Toggle(cLin, "Enemy arrows", CFG.arrows, "on", function(dr)
			ColorPicker(dr, CFG.arrows, "color")
			Slider(dr, "Radius", 60, 400, CFG.arrows, "radius", { fmt = function(v) return v .. " px" end })
			Slider(dr, "Size", 8, 30, CFG.arrows, "size")
			arrowDrawer(dr)
		end)

		local cItem = Card(R, "Items")
		Toggle(cItem, "Gun ESP", CFG.gun, "on", function(dr)
			ColorPicker(dr, CFG.gun, "color")
			Toggle(dr, "Show text", CFG.gun, "text", function(d2) ColorPicker(d2, CFG.gun, "textColor") end)
			Toggle(dr, "Tracers", CFG.gun, "tracer")
		end)
		Toggle(cItem, "Coin ESP", CFG.coin, "on", function(dr)
			ColorPicker(dr, CFG.coin, "color")
			Toggle(dr, "Show text", CFG.coin, "text", function(d2) ColorPicker(d2, CFG.coin, "textColor") end)
		end)

		local cEx = Card(R, "Extras")
		Toggle(cEx, "Hat", CFG.hat, "on", function(dr)
			Dropdown(dr, "Hat style", { "Lines", "Solid", "Both" }, CFG.hat, "mode")
			ColorPicker(dr, CFG.hat, "color")
			Toggle(dr, "Rainbow lines", CFG.hat, "rainbow")
			Toggle(dr, "Shimmer color", CFG.hat, "shimmer")
			Slider(dr, "Lines", 4, 60, CFG.hat, "lines")
			Slider(dr, "Transparency", 0, 100, CFG.hat, "trans", { div = 100, fmt = pct })
			Slider(dr, "Size", 50, 200, CFG.hat, "size", { fmt = function(v) return v .. "%" end })
			Dropdown(dr, "Show for", { "Everyone", "Only me" }, CFG.hat, "scope")
		end)
		Toggle(cEx, "Trails", CFG.trail, "on", function(dr)
			ColorPicker(dr, CFG.trail, "color")
			Slider(dr, "Length", 2, 50, CFG.trail, "len", { div = 10, fmt = function(v) return v .. " s" end })
			Slider(dr, "Width", 2, 40, CFG.trail, "width", { div = 10 })
			Dropdown(dr, "Show for", { "Everyone", "Only me" }, CFG.trail, "scope")
		end)
		Toggle(cEx, "Footsteps", CFG.steps, "on", function(dr)
			ColorPicker(dr, CFG.steps, "color")
			Slider(dr, "Fade time", 5, 80, CFG.steps, "life", { div = 10, fmt = function(v) return v .. " s" end })
			Slider(dr, "Step distance", 10, 100, CFG.steps, "dist", { div = 10, fmt = function(v) return v .. " st" end })
			Slider(dr, "Step delay", 0, 20, CFG.steps, "delay", { div = 10, fmt = function(v) return v .. " s" end })
			Dropdown(dr, "Shape", { "Circle", "Square", "Diamond", "Foot" }, CFG.steps, "shape")
			Dropdown(dr, "Show for", { "Only me", "Everyone" }, CFG.steps, "scope")
		end)

		-- прицел / пуля / косметика
		local cX = Card(L, "Crosshair")
		Toggle(cX, "Custom crosshair", CFG.xhair, "on", function(dr)
			FL(dr, "Preview")
			local stage = new("Frame", {
				Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = C.field, BorderSizePixel = 0, LayoutOrder = ord(),
				ClipsDescendants = true,
			}, dr)
			corner(stage, 10)
			stroke(stage, C.line, 1)
			local pool = {}
			X.addFrame(function()
				if not stage.Parent or not X.menuOpen() then return end
				local sc = math.max(fitScale.Scale * animScale.Scale, .01)
				local w = stage.AbsoluteSize.X / sc
				local ang = CFG.xhair.spin and (os.clock() * math.rad(CFG.xhair.speed)) or 0
				X.drawShape(pool, stage, w / 2, 45, CFG.xhair.shape, math.min(CFG.xhair.size, 36), CFG.xhair.thick, CFG.xhair.color, ang)
			end)
			Grid(dr, X.SHAPE_LIST, function() return CFG.xhair.shape end, function(n) CFG.xhair.shape = n end, 3)
			ColorPicker(dr, CFG.xhair, "color")
			Slider(dr, "Size", 4, 40, CFG.xhair, "size")
			Slider(dr, "Thickness", 1, 6, CFG.xhair, "thick")
			Toggle(dr, "Spin", CFG.xhair, "spin")
			Slider(dr, "Spin speed", 10, 720, CFG.xhair, "speed", { fmt = function(v) return v .. " deg/s" end })
		end)
		local cB = Card(L, "Bullet")
		Toggle(cB, "Bullet path", CFG.bpath, "on", function(dr)
			ColorPicker(dr, CFG.bpath, "color")
			Slider(dr, "Fade time", 5, 80, CFG.bpath, "time", { div = 10, fmt = function(v) return v .. " s" end })
		end)
		local cC = Card(R, "Cosmetics")
		Toggle(cC, "Wings", CFG.wings, "on", function(dr)
			ColorPicker(dr, CFG.wings, "color")
			Slider(dr, "Wing length", 15, 80, CFG.wings, "len", { div = 10 })
			Slider(dr, "Wing width", 5, 20, CFG.wings, "width", { div = 10 })
			Dropdown(dr, "Show for", { "Only me", "Everyone" }, CFG.wings, "scope")
		end)
		Toggle(cC, "Halo", CFG.halo, "on", function(dr)
			ColorPicker(dr, CFG.halo, "color")
			Slider(dr, "Radius", 8, 40, CFG.halo, "radius", { div = 10 })
			Dropdown(dr, "Show for", { "Only me", "Everyone" }, CFG.halo, "scope")
		end)

		------------------------------------------------------------ PLAYER
		local sfP = createTab("Player", "user", "movement")
		local PL1, PR1 = Columns(sfP)
		local cMove = Card(PL1, "Movement")
		Toggle(cMove, "Walkspeed", CFG.walk, "on", function(dr)
			Slider(dr, "Speed", 16, 200, CFG.walk, "val")
		end)
		Toggle(cMove, "Jump power", CFG.jump, "on", function(dr)
			Slider(dr, "Power", 50, 300, CFG.jump, "val")
		end)
		Toggle(cMove, "Spin", CFG.spin, "on", function(dr)
			Slider(dr, "Spin speed", 30, 2000, CFG.spin, "val", { fmt = function(v) return v .. " deg/s" end })
		end)
		local cMove2 = Card(PR1, "Flight")
		Toggle(cMove2, "Noclip", CFG.noclip, "on")
		Toggle(cMove2, "Fly", CFG.fly, "on", function(dr)
			Slider(dr, "Fly speed", 10, 300, CFG.fly, "val")
		end)
		local cA = Card(PL1, "Appearance")
		Toggle(cA, "Headless", CFG.headless, "on")
		Toggle(cA, "Korblox", CFG.korblox, "on")
		Toggle(cA, "God mode", CFG.god, "on")
		local cH = Card(PR1, "Extra movement")
		Toggle(cH, "Bunnyhop", CFG.bhop, "on", function(dr)
			Slider(dr, "Jump distance", 20, 120, CFG.bhop, "dist")
			FL(dr, "Hold jump while moving")
		end)
		local cW = Card(PR1, "Animations")
		Toggle(cW, "Animation pack", CFG.anim, "on", function(dr)
			Grid(dr, X.PACK_LIST, function() return CFG.anim.pack end, function(n) CFG.anim.pack = n end, 2)
		end)

		------------------------------------------------------------ WORLD
		local sfW = createTab("World", "globe", "world & shaders")
		local WL, WR = Columns(sfW)
		local cSh = Card(WL, "Shaders")
		Toggle(cSh, "Shaders", CFG.shader, "on", function(dr)
			Grid(dr, X.PRESET_LIST, function() return CFG.shader.preset end, function(n) CFG.shader.preset = n end, 2)
		end)
		local cT = Card(WL, "Time")
		Toggle(cT, "Time of day", CFG.wtime, "on", function(dr)
			Slider(dr, "Time", 0, 24, CFG.wtime, "val", { div = 10, fmt = function(v)
				local hh = math.floor(v) % 24
				return string.format("%02d:%02d", hh, math.floor((v - math.floor(v)) * 60))
			end })
		end)
		Toggle(cT, "Xray", CFG.xray, "on", function(dr)
			Slider(dr, "Wall transparency", 10, 90, CFG.xray, "amount", { div = 100, fmt = pct })
		end)
		local cL = Card(WR, "Lighting")
		Toggle(cL, "Brightness", CFG.wbright, "on", function(dr)
			Slider(dr, "Amount", -50, 50, CFG.wbright, "val", { div = 100, fmt = function(v) return string.format("%.2f", v) end })
		end)
		Toggle(cL, "Glow", CFG.wglow, "on", function(dr)
			Slider(dr, "Intensity", 0, 30, CFG.wglow, "int", { div = 10 })
			Slider(dr, "Threshold", 0, 20, CFG.wglow, "thr", { div = 10 })
		end)
		Toggle(cL, "Darkness", CFG.wdark, "on", function(dr)
			Slider(dr, "Strength", 0, 100, CFG.wdark, "val", { div = 100, fmt = pct })
		end)
		Toggle(cL, "Color grading", CFG.wgrade, "on", function(dr)
			Slider(dr, "Saturation", -100, 100, CFG.wgrade, "sat", { div = 100, fmt = pct })
			Slider(dr, "Contrast", -100, 100, CFG.wgrade, "con", { div = 100, fmt = pct })
		end)
		Toggle(cL, "Motion blur", CFG.wblur, "on", function(dr)
			Slider(dr, "Strength", 1, 30, CFG.wblur, "val")
		end)
		Toggle(cL, "Fog", CFG.wfog, "on", function(dr)
			Slider(dr, "Density", 0, 100, CFG.wfog, "val", { div = 100, fmt = pct })
		end)
		Toggle(cL, "Sun rays", CFG.wrays, "on", function(dr)
			Slider(dr, "Intensity", 0, 100, CFG.wrays, "val", { div = 100, fmt = pct })
		end)
		Toggle(cL, "Full bright", CFG.wfull, "on")
		Toggle(cL, "No shadows", CFG.wshadow, "on")

		------------------------------------------------------------ MISC
		local sfM = createTab("Misc", "grid", "teleport & farm")
		local ML, MR = Columns(sfM)
		local cF = Card(ML, "Autofarm")
		Toggle(cF, "Autofarm coins", CFG.farm, "on", function(dr)
			FL(dr, "Noclip turns on automatically")
			Slider(dr, "Fly speed", 20, 200, CFG.farm, "fly")
			Slider(dr, "Farm delay", 0, 30, CFG.farm, "delay", { div = 10, fmt = function(v) return v .. " s" end })
		end)
		local cG = Card(ML, "Combat")
		Toggle(cG, "Auto grab gun", CFG.grab, "on", function(dr)
			FL(dr, "Teleports to the dropped gun and back")
		end)
		Toggle(cG, "Hit sound", CFG.hsound, "on", function(dr)
			Grid(dr, X.SOUND_LIST, function() return CFG.hsound.id == "" and CFG.hsound.sound or "" end, function(n)
				CFG.hsound.sound = n
				CFG.hsound.id = ""
			end, 3)
			Slider(dr, "Volume", 1, 10, CFG.hsound, "volume")
			FL(dr, "Or paste a sound ID")
			IdBox(dr, "Sound ID", function() return CFG.hsound.id end, function(v) CFG.hsound.id = v end)
			Button(dr, "Test sound", function() X.playHit() end)
		end)

		local function tpBtn(parent, text, fn)
			Button(parent, text, function(b)
				if not fn() then
					local o = b.Text
					b.Text = "Not found"
					task.delay(1.2, function() if b.Parent then b.Text = o end end)
				end
			end)
		end
		local cTp = Card(MR, "Teleport")
		DR(cTp, "Teleport to player", function(dr)
			PL(dr, 170, function(plr) X.tpPlayer(plr) end, false, nil)
		end)
		tpBtn(cTp, "Teleport to spawn", function() return X.tpSpawn() end)
		tpBtn(cTp, "Teleport to map", function() return X.tpMap() end)
		tpBtn(cTp, "Teleport to murder", function() return X.tpRole("Murderer") end)
		tpBtn(cTp, "Teleport to sheriff", function() return X.tpRole("Sheriff") end)

		------------------------------------------------------------ EMOTE
		local sfE = createTab("Emote", "emote", "emotes")
		local EL, ER = Columns(sfE)
		local idbox
		local c1 = Card(EL, "Emote")
		Toggle(c1, "Auto emote", CFG.emote, "auto")
		Label(c1, "Plays the chosen emote when you stop moving", C.sub, 11)
		Grid(c1, X.EMOTE_LIST, function() return CFG.emote.id ~= "" and "" or CFG.emote.name end, function(n)
			CFG.emote.name = n
			CFG.emote.id = ""
			if idbox then idbox.Text = "" end
		end, 2)
		local c2 = Card(ER, "Any emote (ID)")
		Label(c2, "Paste the animation asset ID of any emote, including paid ones", C.sub, 11)
		idbox = IdBox(c2, "Animation ID", function() return CFG.emote.id end, function(v) CFG.emote.id = v end)
		Slider(c2, "Speed", 3, 30, CFG.emote, "speed", { div = 10 })
		Button(c2, "Play", function() X.playEmote() end, C.accent)
		Button(c2, "Stop", function() X.stopEmote() end)

		------------------------------------------------------------ SKIN CHANGER (Gun / Knife / Items)
		grpSkin = createGroup("Skin changer", false)
		X.buildSkinPage("Gun", "gun", grpSkin)
		X.buildSkinPage("Knife", "knife", grpSkin)
		X.buildItemsPage(grpSkin)

		------------------------------------------------------------ CONFIG
		local sfC = createTab("Config", "cfg", "configs")
		local CL, CR = Columns(sfC)
		local cNew = Card(CL, "New config")
		Label(cNew, "Save your current settings under a name", C.sub, 11)
		local nameBox = new("TextBox", {
			Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.field, BorderSizePixel = 0, Font = Enum.Font.GothamMedium,
			TextSize = 13, TextColor3 = C.text, PlaceholderText = "Config name...", PlaceholderColor3 = C.sub, Text = "",
			ClearTextOnFocus = false, LayoutOrder = ord(),
		}, cNew)
		corner(nameBox, 10)
		stroke(nameBox, C.line, 1.5)
		local slotLbl
		local rowsUI = {}
		local function refreshSlots()
			local slots = X.cfgApi.slots()
			slotLbl.Text = X.tr("Slots:") .. " " .. X.cfgApi.count() .. " / 5"
			for i = 1, 5 do
				local r = rowsUI[i]
				if r then
					r.name.Text = slots[i] and slots[i].name or X.tr("— empty —")
					r.name.TextColor3 = slots[i] and C.text or Color3.fromRGB(80, 78, 104)
					r.del.Visible = slots[i] ~= nil
				end
			end
		end
		local saveBtn = Button(cNew, "Save", function(b)
			local idx = X.cfgApi.save(nameBox.Text)
			if idx then
				nameBox.Text = ""
				refreshSlots()
			else
				local o = b.Text
				b.Text = "No free slots"
				task.delay(1.2, function() if b.Parent then b.Text = o end end)
			end
		end, WHITE)
		new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, saveBtn)
		saveBtn.TextColor3 = Color3.fromRGB(14, 14, 24)
		slotLbl = Label(cNew, "Slots: 0 / 5", C.sub, 11)

		local cSv = Card(CR, "Saved")
		for i = 1, 5 do
			local f = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.field, BorderSizePixel = 0, AutoButtonColor = false,
				Text = "", LayoutOrder = ord(),
			}, cSv)
			corner(f, 10)
			stroke(f, C.line, 1.5)
			new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.fromOffset(16, 38),
				Font = Enum.Font.GothamBold, Text = tostring(i), TextSize = 12, TextColor3 = C.sub,
			}, f)
			local nm = new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -84, 1, 0),
				Font = Enum.Font.GothamMedium, Text = "", TextSize = 13, TextColor3 = C.text,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, f)
			local del = new("TextButton", {
				AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -6, .5, 0), Size = UDim2.fromOffset(28, 28),
				BackgroundColor3 = C.card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold,
				Text = "x", TextSize = 13, TextColor3 = C.text,
			}, f)
			corner(del, 8)
			rowsUI[i] = { name = nm, del = del }
			f.MouseButton1Click:Connect(function()
				if X.cfgApi.slots()[i] then X.cfgApi.load(i) end
			end)
			del.MouseButton1Click:Connect(function()
				X.cfgApi.delete(i)
				refreshSlots()
			end)
		end
		refreshSlots()
		X.reg(refreshSlots)

		------------------------------------------------------------ SETTING
		local sfS = createTab("Setting", "gear", "menu & language")
		local SL, SR = Columns(sfS)
		local cMenu = Card(SL, "Menu")
		Slider(cMenu, "Menu scale", 50, 130, X.SET, "scale", { div = 100, fmt = pct })
		Slider(cMenu, "Transparency", 0, 60, X.SET, "trans", { div = 100, fmt = pct })
		DR(cMenu, "Menu color", function(dr)
			ColorPicker(dr, X.SET, "accent")
		end)
		local cLang = Card(SR, "Language")
		Label(cLang, "The chosen language is saved automatically", C.sub, 11)
		Grid(cLang, { "English", "Русский" }, function() return X.SET.lang == "ru" and "Русский" or "English" end, function(n)
			X.setLang(n == "Русский" and "ru" or "en")
		end, 2)
		local cPriv = Card(SR, "Privacy")
		Toggle(cPriv, "Online stats", X.SET, "stats")
		Label(cPriv, "Sends only a random session ID and a hashed server ID to count NurHub users online. No name, no UserId.", C.sub, 11)
	end
	build()
end

----------------------------------------------------------------
-- STATS: версия, онлайн сервера, онлайн NurHub (ntfy.sh как лёгкий счётчик присутствия)
----------------------------------------------------------------
function X.menuOpen() return menuOpen end

local unload
local bannerGrad
local statsGrad

do
	local function run()
		-- Публичный pub/sub (ntfy.sh): каждый клиент раз в BEAT сек. шлёт анонимный «пульс», счётчик = уникальные сеансы за WINDOW сек.
		-- Свой сервер: поменяй HOST (ntfy можно захостить самому) и/или TOPIC.
		local HOST  = "https://ntfy.sh"
		local TOPIC = "nurhub-mm2-online-4f7a1c9e2b"
		local BEAT, WINDOW = 20, 70

		local sid = (HttpService:GenerateGUID(false):gsub("%-", "")):sub(1, 14)
		local function hashJob(s)
			local h = 7
			for i = 1, #s do h = (h * 31 + s:byte(i)) % 4294967291 end
			return string.format("%x", h)
		end
		local jobHash = hashJob(game.JobId ~= "" and game.JobId or tostring(game.PlaceId))

		local S = { server = #Players:GetPlayers(), max = Players.MaxPlayers, nh = nil, here = nil, ok = false, err = nil, hist = {}, t = 0 }
		X.stats = S

		local function httpReq(opts)
			local fn = (typeof(request) == "function" and request)
				or (typeof(http_request) == "function" and http_request)
				or (typeof(syn) == "table" and typeof(syn.request) == "function" and syn.request)
				or (typeof(http) == "table" and typeof(http.request) == "function" and http.request)
				or (typeof(fluxus) == "table" and typeof(fluxus.request) == "function" and fluxus.request)
			if not fn then return nil, "no http" end
			local ok, res = pcall(fn, opts)
			if ok and type(res) == "table" then return res end
			return nil, tostring(res)
		end

		local function beat(bye)
			local body = sid .. "|" .. (bye and "bye" or jobHash) .. "|" .. VERSION
			return httpReq({
				Url = HOST .. "/" .. TOPIC, Method = "POST", Headers = { ["Content-Type"] = "text/plain" }, Body = body,
			})
		end

		local function poll()
			local res, err = httpReq({
				Url = HOST .. "/" .. TOPIC .. "/json?poll=1&since=" .. WINDOW .. "s", Method = "GET",
				Headers = { Accept = "application/x-ndjson" },
			})
			if not res then
				S.ok, S.err = false, err
				return
			end
			local code = tonumber(res.StatusCode) or 0
			if type(res.Body) ~= "string" or (code ~= 0 and code ~= 200) then
				S.ok, S.err = false, "http " .. code
				return
			end
			local active = {}
			for line in res.Body:gmatch("[^\r\n]+") do
				local okj, j = pcall(function() return HttpService:JSONDecode(line) end)
				if okj and type(j) == "table" and j.event == "message" and type(j.message) == "string" then
					local id, job = j.message:match("^(%w+)|([^|]*)|")
					if id then
						if job == "bye" then active[id] = nil else active[id] = job end
					end
				end
			end
			if X.SET.stats then active[sid] = jobHash end
			local n, here = 0, 0
			for _, job in pairs(active) do
				n += 1
				if job == jobHash then here += 1 end
			end
			S.nh, S.here, S.ok, S.err, S.t = n, here, true, nil, os.clock()
			local h = S.hist
			h[#h + 1] = n
			if #h > 24 then table.remove(h, 1) end
		end

		task.spawn(function()
			task.wait(2)
			local ticks, lastOn = 0, false
			while alive do
				local on = X.SET.stats
				if on then
					if not lastOn or ticks >= BEAT * 2 then
						ticks = 0
						pcall(beat, false)
						pcall(poll)
					end
				else
					S.nh, S.here, S.ok, S.err = nil, nil, false, "off"
				end
				lastOn = on
				ticks += 1
				task.wait(.5)
			end
		end)

		task.spawn(function()
			while alive do
				S.server = #Players:GetPlayers()
				S.max = Players.MaxPlayers
				task.wait(1)
			end
		end)

		X.onUnload(function()
			if X.SET.stats then task.spawn(function() pcall(beat, true) end) end
		end)

		------------------------------------------------ Страница Stats
		local sf = createTab("Stats", "stats", "live stats")
		new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, sf)

		local banner = new("Frame", {
			Size = UDim2.new(1, 0, 0, 104), BackgroundColor3 = WHITE, BorderSizePixel = 0, LayoutOrder = ord(),
		}, sf)
		corner(banner, 14)
		statsGrad = new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2), Rotation = 35 }, banner)
		local logo = new("Frame", {
			Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = WHITE, BackgroundTransparency = .8,
			BorderSizePixel = 0,
		}, banner)
		corner(logo, 23)
		stroke(logo, WHITE, 1.5, .4)
		new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, Text = "NH",
			TextSize = 17, TextColor3 = WHITE,
		}, logo)
		new("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(72, 18), Size = UDim2.new(1, -170, 0, 22),
			Font = Enum.Font.GothamBlack, Text = "NurHub Stats", TextSize = 19, TextColor3 = WHITE,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, banner)
		new("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(72, 42), Size = UDim2.new(1, -170, 0, 16),
			Font = Enum.Font.GothamMedium, Text = "Live numbers, updated automatically", TextSize = 11,
			TextColor3 = Color3.fromRGB(235, 235, 255), TextXAlignment = Enum.TextXAlignment.Left,
		}, banner)
		local pill = new("Frame", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 16), Size = UDim2.fromOffset(88, 24),
			BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .6, BorderSizePixel = 0,
		}, banner)
		corner(pill, 12)
		local pillDot = new("Frame", {
			AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 10, .5, 0), Size = UDim2.fromOffset(8, 8),
			BackgroundColor3 = C.sub, BorderSizePixel = 0,
		}, pill)
		corner(pillDot, 4)
		local pillTxt = new("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -28, 1, 0),
			Font = Enum.Font.GothamBold, Text = "...", TextSize = 11, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left,
		}, pill)
		local upd = new("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(72, 70), Size = UDim2.new(1, -90, 0, 16),
			Font = Enum.Font.GothamMedium, Text = "", TextSize = 10, TextColor3 = Color3.fromRGB(225, 225, 250),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, banner)

		-- три больших плитки
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 116), BackgroundTransparency = 1, LayoutOrder = ord() }, sf)
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
		}, row)
		local function tile(order, title, iconKind)
			local f = new("Frame", {
				Size = UDim2.new(1 / 3, -6, 1, 0), BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = order,
			}, row)
			corner(f, 12)
			X.regT(f)
			stroke(f, C.line, 1)
			local t = new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -44, 0, 12),
				Font = Enum.Font.GothamBold, Text = string.upper(title), TextSize = 10, TextColor3 = C.sub,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, f)
			t:SetAttribute("en", title)
			t:SetAttribute("up", true)
			local ib = new("Frame", {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 6), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1,
			}, f)
			Icon(iconKind, ib, 16).paint(C.accent, 0)
			local sc = new("UIScale", { Scale = 1 })
			local v = new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 32), Size = UDim2.new(1, -20, 0, 34),
				Font = Enum.Font.GothamBlack, Text = "-", TextSize = 28, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left,
			}, f)
			sc.Parent = v
			local cap = new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 70), Size = UDim2.new(1, -20, 0, 14),
				Font = Enum.Font.GothamMedium, Text = "", TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, f)
			local cap2 = new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 88), Size = UDim2.new(1, -20, 0, 14),
				Font = Enum.Font.GothamMedium, Text = "", TextSize = 10, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, f)
			return { v = v, cap = cap, cap2 = cap2, sc = sc, frame = f }
		end
		local tVer = tile(1, "Version", "info")
		local tSrv = tile(2, "Online", "globe")
		local tNH = tile(3, "NurHub online", "user")
		tVer.v.Text = VERSION
		tVer.cap.Text = "NurHub Visual MM2"
		tVer.cap2.Text = "build " .. VERSION

		local barBg = new("Frame", {
			Position = UDim2.fromOffset(12, 100), Size = UDim2.new(1, -24, 0, 4), BackgroundColor3 = C.track, BorderSizePixel = 0,
		}, tSrv.frame)
		corner(barBg, 2)
		local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, barBg)
		corner(barFill, 2)
		new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, barFill)
		tSrv.cap2.Visible = false

		-- график активности NurHub
		local cAct = Card(sf, "Activity")
		local graph = new("Frame", {
			Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = C.field, BorderSizePixel = 0, LayoutOrder = ord(),
		}, cAct)
		corner(graph, 8)
		new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, graph)
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, graph)
		local bars = {}
		for i = 1, 24 do
			local b = new("Frame", {
				Size = UDim2.new(1 / 24, -2, .05, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, LayoutOrder = i,
			}, graph)
			corner(b, 2)
			new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C.accent2, C.accent) }, b)
			bars[i] = b
		end
		local perf = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.GothamMedium, Text = "",
			TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = ord(),
		}, cAct)
		Label(cAct, "NurHub online = people running this script right now (all servers). Only a random session ID and a hashed server ID are sent. Turn it off in Setting > Privacy.", C.sub, 10)

		local last = {}
		local function pulse(tl, key, val)
			if last[key] ~= val then
				last[key] = val
				tl.v.Text = val
				tl.sc.Scale = 1.18
				tw(tl.sc, .35, { Scale = 1 }, Enum.EasingStyle.Back)
			end
		end
		local function refreshUI()
			pulse(tSrv, "srv", tostring(S.server))
			tSrv.cap.Text = X.tr("players on this server") .. "  /  " .. S.max
			barFill.Size = UDim2.fromScale(math.clamp(S.server / math.max(S.max, 1), 0, 1), 1)
			pulse(tNH, "nh", S.nh and tostring(S.nh) or "-")
			tNH.cap.Text = X.tr("using NurHub right now")
			tNH.cap2.Text = S.here and (X.tr("on this server") .. ": " .. S.here) or ""
			if S.ok then
				pillDot.BackgroundColor3 = C.good
				pillTxt.Text = "LIVE"
				upd.Text = X.tr("updated") .. " " .. math.floor(os.clock() - S.t) .. "s " .. X.tr("ago")
			elseif S.err == "off" then
				pillDot.BackgroundColor3 = C.sub
				pillTxt.Text = "OFF"
				upd.Text = X.tr("Online stats are off")
			else
				pillDot.BackgroundColor3 = C.bad
				pillTxt.Text = "OFFLINE"
				upd.Text = S.err and (X.tr("no connection") .. " (" .. tostring(S.err) .. ")") or ""
			end
			local mx = 1
			for _, v in ipairs(S.hist) do mx = math.max(mx, v) end
			local off = 24 - #S.hist
			for i = 1, 24 do
				local v = S.hist[i - off]
				bars[i].Size = UDim2.new(1 / 24, -2, v and math.clamp(v / mx, .06, 1) or .04, 0)
				bars[i].BackgroundTransparency = v and 0 or .7
			end
			local ping = 0
			pcall(function() ping = math.floor(LP:GetNetworkPing() * 1000 + .5) end)
			perf.Text = "FPS " .. tostring(X.fps or 0) .. "   -   Ping " .. ping .. " ms"
		end
		refreshUI()
		task.spawn(function()
			while alive do
				if menuOpen and pages.Stats and pages.Stats.Visible then pcall(refreshUI) end
				task.wait(1)
			end
		end)
	end
	run()
end

----------------------------------------------------------------
-- СТРАНИЦА INFO
----------------------------------------------------------------
do
	local sfI = createTab("Info", "info", "about")
	new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, sfI)

	local banner = new("Frame", {
		Size = UDim2.new(1, 0, 0, 168), BackgroundColor3 = WHITE, BorderSizePixel = 0, LayoutOrder = ord(),
	}, sfI)
	corner(banner, 14)
	bannerGrad = new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2), Rotation = 35 }, banner)

	local logo = new("Frame", {
		Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(50, 50), BackgroundColor3 = WHITE, BackgroundTransparency = .8,
		BorderSizePixel = 0,
	}, banner)
	corner(logo, 25)
	stroke(logo, WHITE, 1.5, .4)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, Text = "NH",
		TextSize = 18, TextColor3 = WHITE,
	}, logo)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(80, 20), Size = UDim2.new(1, -96, 0, 24),
		Font = Enum.Font.GothamBlack, Text = "NurHub Official", TextSize = 20, TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, banner)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(80, 46), Size = UDim2.new(1, -96, 0, 16),
		Font = Enum.Font.GothamMedium, Text = "News, updates and support", TextSize = 12,
		TextColor3 = Color3.fromRGB(235, 235, 255), TextXAlignment = Enum.TextXAlignment.Left,
	}, banner)

	local pill = new("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -18), Size = UDim2.new(1, -36, 0, 40),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .65, BorderSizePixel = 0,
	}, banner)
	corner(pill, 12)
	stroke(pill, WHITE, 1, .7)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0),
		Font = Enum.Font.GothamBold, Text = "t.me/NurHuboffical", TextSize = 15, TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, pill)

	local cLinks = Card(sfI, "Telegram")
	Button(cLinks, "Copy link", function(b)
		local fn = (typeof(setclipboard) == "function" and setclipboard) or (typeof(toclipboard) == "function" and toclipboard)
		local ok = fn and pcall(fn, TG_LINK)
		b.Text = ok and "Copied!" or TG_LINK
		task.delay(1.6, function() if b.Parent then b.Text = "Copy link" end end)
	end, C.accent)
	Button(cLinks, "Open Telegram", function()
		pcall(function() GuiService:OpenBrowserWindow(TG_LINK) end)
	end)

	local cAbout = Card(sfI, "About")
	Label(cAbout, "NurHub Visual v" .. VERSION .. " MM2 - visual features, skin changer and live stats. No Drawing API: everything is built from Frame, Highlight, Trail and Lighting objects.", C.sub, 12)
	Label(cAbout, "Menu key: RightShift  •  or the NH button.", C.sub, 11)
	Button(cAbout, "Unload script", function() unload() end)
end

----------------------------------------------------------------
-- Язык / цвет меню / сохранение настроек
----------------------------------------------------------------
do
	local function run()
		X.regT(Main)
		X.regT(Preview)
		X.regT(Side)

		X.DICT = {
			["Hat style"] = "Стиль шляпы", ["Shimmer color"] = "Переливающийся цвет", ["Solid"] = "Сплошная", ["Both"] = "Оба",
			["Step distance"] = "Дистанция шага", ["Step delay"] = "Задержка шага", ["Found"] = "Найдено", ["Rescan game assets"] = "Пересканировать игру",
			["Skins are applied on your client (only you see them). Photos come from the game's own assets when available."] = "Скины применяются на твоём клиенте (видишь только ты). Фото берутся из ассетов игры, если они доступны.",
			["Local tools: only you see them. Found = real tools from the game's storage."] = "Локальные предметы: видишь только ты. Found = реальные инструменты из хранилища игры.",
			["Gun"] = "Оружие", ["Emote"] = "Эмоции", ["skin changer"] = "смена скинов", ["emotes"] = "эмоции",
			["Skin changer"] = "Скинченджер", ["Knife"] = "Нож", ["Items"] = "Предметы", ["Search skin..."] = "Поиск скина...",
			["Reset skin"] = "Сбросить скин", ["Hold preview"] = "Показ в руке", ["Remove all"] = "Убрать всё", ["local items"] = "локальные предметы",
			["Crosshair"] = "Прицел", ["Custom crosshair"] = "Свой прицел", ["Preview"] = "Предпросмотр", ["Thickness"] = "Толщина",
			["Spin"] = "Вращение", ["Spin speed"] = "Скорость вращения", ["Bullet"] = "Пуля", ["Bullet path"] = "Путь пули",
			["Fade time"] = "Время затухания", ["Cosmetics"] = "Косметика", ["Wings"] = "Крылья", ["Wing length"] = "Длина крыльев",
			["Wing width"] = "Ширина крыльев", ["Halo"] = "Нимб", ["Murderer arrow"] = "Стрелка убийцы", ["Sheriff arrow"] = "Стрелка шерифа",
			["Pick a player / tap the circle to change his arrow color"] = "Выбери игрока / нажми на круг, чтобы сменить цвет стрелки",
			["Appearance"] = "Внешний вид", ["Headless"] = "Без головы", ["Korblox"] = "Корблокс", ["God mode"] = "Режим бога",
			["Extra movement"] = "Доп. движение", ["Bunnyhop"] = "Банихоп", ["Jump distance"] = "Длина прыжка",
			["Hold jump while moving"] = "Зажми прыжок во время движения", ["Animations"] = "Анимации", ["Animation pack"] = "Пак анимаций",
			["Combat"] = "Бой", ["Auto grab gun"] = "Авто-подбор пушки", ["Teleports to the dropped gun and back"] = "Телепорт к выпавшей пушке и обратно",
			["Hit sound"] = "Звук попадания", ["Volume"] = "Громкость", ["Or paste a sound ID"] = "Или вставь ID звука", ["Test sound"] = "Проверить звук",
			["Auto emote"] = "Авто-эмоция", ["Plays the chosen emote when you stop moving"] = "Включает выбранную эмоцию, когда ты стоишь",
			["Any emote (ID)"] = "Любая эмоция (ID)", ["Paste the animation asset ID of any emote, including paid ones"] = "Вставь ID анимации любой эмоции, в том числе платной",
			["Play"] = "Играть", ["Stop"] = "Стоп",
			["Visual"] = "Визуал", ["Player"] = "Игрок", ["World"] = "Мир", ["Misc"] = "Разное", ["Config"] = "Конфиг",
			["Setting"] = "Настройки", ["Info"] = "Инфо", ["Stats"] = "Статистика",
			["esp & render"] = "есп и рендер", ["movement"] = "движение", ["world & shaders"] = "мир и шейдеры",
			["teleport & farm"] = "телепорт и фарм", ["configs"] = "конфиги", ["menu & language"] = "меню и язык", ["about"] = "о скрипте",
			["live stats"] = "живая статистика",
			-- Visual
			["General"] = "Основное", ["ESP master"] = "ESP включить", ["Role colors"] = "Цвета по ролям", ["Game role sync"] = "Синхр. ролей с игрой",
			["Max distance"] = "Макс. дистанция",
			["ESP for..."] = "ESP для...", ["Show ESP only for"] = "Показывать ESP только для",
			["Pick a player / tap the circle to change his color"] = "Выбери игрока / нажми на круг, чтобы сменить цвет",
			["All"] = "Все", ["Murder"] = "Убийца", ["Sheriff"] = "Шериф",
			["Boxes"] = "Боксы", ["Esp box 2D"] = "ESP бокс 2D", ["Esp box 3D"] = "ESP бокс 3D", ["Corner box"] = "Углы бокса",
			["Filled box"] = "Заливка бокса", ["Length"] = "Длина", ["Transparency"] = "Прозрачность", ["Top color"] = "Верхний цвет",
			["Bottom color"] = "Нижний цвет",
			["Show nickname"] = "Показать ник", ["Show distance"] = "Показать дистанцию", ["Show health"] = "Показать HP",
			["Show avatar"] = "Показать аватар", ["HUD"] = "HUD", ["Show FPS"] = "Показать FPS", ["Custom FPS"] = "Свой FPS",
			["Drag the badge across the screen"] = "Перетащи значок по экрану",
			["Render"] = "Рендер", ["Chams"] = "Чамсы", ["Fill transparency"] = "Прозрачность заливки", ["Outline"] = "Контур",
			["Wall check"] = "Проверка стены", ["Color behind a wall"] = "Цвет за стеной", ["Color when visible"] = "Цвет когда виден",
			["Glow"] = "Свечение", ["Range"] = "Радиус", ["Brightness"] = "Яркость", ["Custom FOV"] = "Свой FOV",
			["Field of view"] = "Поле зрения", ["Third person"] = "Третье лицо", ["Distance"] = "Дистанция",
			["Lines"] = "Линии", ["Line / Tracers"] = "Линии / трейсеры", ["Line origin"] = "Начало линии",
			["Bottom"] = "Снизу", ["Top"] = "Сверху", ["Skeleton"] = "Скелет", ["Show head"] = "Показать голову",
			["Enemy arrows"] = "Стрелки врагов", ["Radius"] = "Радиус", ["Size"] = "Размер",
			["Gun ESP"] = "ESP пушки", ["Coin ESP"] = "ESP монет", ["Show text"] = "Показать текст", ["Tracers"] = "Трейсеры",
			["Extras"] = "Дополнительно", ["Hat"] = "Шляпа", ["Rainbow lines"] = "Радужные линии",
			["Show for"] = "Показывать для", ["Everyone"] = "Все", ["Only me"] = "Только я",
			["Trails"] = "Трейлы", ["Width"] = "Ширина", ["Footsteps"] = "Следы", ["Shape"] = "Форма",
			["Circle"] = "Круг", ["Square"] = "Квадрат", ["Diamond"] = "Ромб", ["Foot"] = "Нога",
			-- Player
			["Movement"] = "Движение", ["Walkspeed"] = "Скорость", ["Speed"] = "Скорость", ["Jump power"] = "Сила прыжка", ["Power"] = "Сила",
			["Flight"] = "Полёт", ["Noclip"] = "Ноклип", ["Fly"] = "Полёт (Fly)", ["Fly speed"] = "Скорость полёта",
			-- World
			["Shaders"] = "Шейдеры", ["Time"] = "Время", ["Time of day"] = "Время суток", ["Xray"] = "Xray", ["Wall transparency"] = "Прозрачность стен",
			["Lighting"] = "Освещение", ["Amount"] = "Значение", ["Intensity"] = "Интенсивность", ["Threshold"] = "Порог",
			["Darkness"] = "Затемнение", ["Strength"] = "Сила", ["Color grading"] = "Цветокоррекция", ["Saturation"] = "Насыщенность",
			["Contrast"] = "Контраст", ["Motion blur"] = "Моушн блюр", ["Fog"] = "Туман", ["Density"] = "Плотность", ["Sun rays"] = "Лучи солнца",
			["Full bright"] = "Полная яркость", ["No shadows"] = "Без теней",
			-- Misc
			["Autofarm"] = "Автофарм", ["Autofarm coins"] = "Автофарм монет", ["Noclip turns on automatically"] = "Ноклип включается автоматически",
			["Farm delay"] = "Задержка фарма", ["Teleport"] = "Телепорт", ["Teleport to player"] = "Телепорт к игроку",
			["Teleport to spawn"] = "Телепорт на спавн", ["Teleport to map"] = "Телепорт на карту", ["Teleport to murder"] = "Телепорт к убийце",
			["Teleport to sheriff"] = "Телепорт к шерифу", ["Not found"] = "Не найдено",
			-- Config
			["New config"] = "Новый конфиг", ["Save your current settings under a name"] = "Сохрани текущие настройки под именем",
			["Config name..."] = "Имя конфига...", ["Save"] = "Сохранить", ["Slots:"] = "Слоты:", ["Saved"] = "Сохранённые",
			["— empty —"] = "— пусто —", ["No free slots"] = "Нет свободных слотов",
			-- Setting
			["Menu"] = "Меню", ["Menu scale"] = "Масштаб меню", ["Menu color"] = "Цвет меню", ["Language"] = "Язык",
			["The chosen language is saved automatically"] = "Выбранный язык сохраняется автоматически",
			["Privacy"] = "Приватность", ["Online stats"] = "Онлайн-статистика",
			["Sends only a random session ID and a hashed server ID to count NurHub users online. No name, no UserId."] = "Отправляет только случайный ID сеанса и хэш ID сервера для подсчёта онлайна NurHub. Без ника и UserId.",
			-- Stats
			["Version"] = "Версия", ["Online"] = "Онлайн", ["NurHub online"] = "NurHub онлайн", ["Activity"] = "Активность",
			["NurHub Stats"] = "Статистика NurHub", ["Live numbers, updated automatically"] = "Живые цифры, обновляются автоматически",
			["players on this server"] = "игроков на сервере", ["using NurHub right now"] = "сейчас пользуются NurHub",
			["on this server"] = "на этом сервере", ["updated"] = "обновлено", ["ago"] = "назад",
			["Online stats are off"] = "Онлайн-статистика выключена", ["no connection"] = "нет связи",
			["NurHub online = people running this script right now (all servers). Only a random session ID and a hashed server ID are sent. Turn it off in Setting > Privacy."] = "NurHub онлайн = люди, которые прямо сейчас запустили этот скрипт (все серверы). Отправляется только случайный ID сеанса и хэш ID сервера. Выключается в Настройки > Приватность.",
			-- Info
			["Telegram"] = "Телеграм", ["Copy link"] = "Копировать ссылку", ["Open Telegram"] = "Открыть Telegram", ["About"] = "О скрипте",
			["Unload script"] = "Выгрузить скрипт", ["News, updates and support"] = "Новости, обновления и поддержка",
			["ESP Editor"] = "Редактор ESP", ["live preview of your settings"] = "живой предпросмотр настроек",
			["Search..."] = "Поиск...", ["Nothing found"] = "Ничего не найдено",
		}

		local function show(d, en, ru)
			local base = ru and (X.DICT[en] or en) or en
			if d:GetAttribute("up") then base = ru and X.upper(base) or string.upper(base) end
			return base
		end

		local function applyLang()
			local ru = X.SET.lang == "ru"
			for _, d in ipairs(gui:GetDescendants()) do
				if d:IsA("TextLabel") or d:IsA("TextButton") then
					if d.RichText then
						local en = d:GetAttribute("en")
						if not en then
							en = d.Text
							d:SetAttribute("en", en)
						end
						local a, b = en:match('^(.-) <font color="rgb%(135,133,158%)">· (.-)</font>$')
						if a then
							local ta = ru and (X.DICT[a] or a) or a
							local tb2 = ru and (X.DICT[b] or b) or b
							d.Text = ta .. ' <font color="rgb(135,133,158)">· ' .. tb2 .. "</font>"
						end
					else
						local en = d:GetAttribute("en")
						if not en and X.DICT[d.Text] then
							en = d.Text
							d:SetAttribute("en", en)
						end
						if en then
							local cur = d.Text
							if cur == show(d, en, false) or cur == show(d, en, true) then d.Text = show(d, en, ru) end
						end
					end
				elseif d:IsA("TextBox") then
					local en = d:GetAttribute("en")
					if not en and X.DICT[d.PlaceholderText] then
						en = d.PlaceholderText
						d:SetAttribute("en", en)
					end
					if en then d.PlaceholderText = (ru and X.DICT[en]) or en end
				end
			end
			pcall(X.refreshAll)
		end

		function X.setLang(l)
			X.SET.lang = l
			applyLang()
			X.saveSettings()
		end

		-- цвет меню (акцент)
		local function applyAccent(n)
			local oldA, oldB = C.accent, C.accent2
			local h, s, v = n:ToHSV()
			local newB = Color3.fromHSV((h + .07) % 1, s * .9, math.clamp(v + .05, 0, 1))
			for _, d in ipairs(gui:GetDescendants()) do
				if d:IsA("UIGradient") then
					local out, ch = {}, false
					for i, k in ipairs(d.Color.Keypoints) do
						local val = k.Value
						if val == oldA then
							val = n
							ch = true
						elseif val == oldB then
							val = newB
							ch = true
						end
						out[i] = ColorSequenceKeypoint.new(k.Time, val)
					end
					if ch then d.Color = ColorSequence.new(out) end
				elseif d:IsA("GuiObject") then
					if d.BackgroundColor3 == oldA then d.BackgroundColor3 = n end
					if d:IsA("ScrollingFrame") and d.ScrollBarImageColor3 == oldA then d.ScrollBarImageColor3 = n end
				end
			end
			C.accent, C.accent2 = n, newB
		end

		-- следим за настройками меню и сохраняем их
		local last = { scale = X.SET.scale, trans = X.SET.trans, stats = X.SET.stats }
		task.spawn(function()
			while alive do
				local s = X.SET
				local changed = false
				if s.accent ~= C.accent then
					applyAccent(s.accent)
					changed = true
				end
				if s.scale ~= last.scale then
					last.scale = s.scale
					fit()
					changed = true
				end
				if s.trans ~= last.trans then
					last.trans = s.trans
					X.applyTrans()
					changed = true
				end
				if s.stats ~= last.stats then
					last.stats = s.stats
					changed = true
				end
				if changed then X.saveSettings() end
				task.wait(.25)
			end
		end)

		fit()
		applyLang()
	end
	run()
end

-- стартовое состояние вкладок
current = "Visual"
pages.Visual.Visible = true
pages.Visual.GroupTransparency = 0
for n in pairs(tabs) do paintTab(n, n == current, false) end

----------------------------------------------------------------
-- Кнопка NH (буквы двигаются) + клавиша
----------------------------------------------------------------
local OpenBtn = new("Frame", {
	Name = "NH_Button", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 46, .5, 0),
	Size = UDim2.fromOffset(52, 52), BackgroundColor3 = Color3.fromRGB(14, 14, 20), BorderSizePixel = 0,
}, gui)
corner(OpenBtn, 16)
local btnScale = new("UIScale", { Scale = 1 }, OpenBtn)
local btnStroke = stroke(OpenBtn, WHITE, 2)
local btnGrad = new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.accent), ColorSequenceKeypoint.new(.5, WHITE), ColorSequenceKeypoint.new(1, C.accent2),
	}),
}, btnStroke)
local letterN = new("TextLabel", {
	BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(.5, 1, .5, 0),
	Size = UDim2.fromOffset(20, 24), Font = Enum.Font.GothamBlack, Text = "N", TextSize = 20, TextColor3 = WHITE,
}, OpenBtn)
local letterH = new("TextLabel", {
	BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(.5, -1, .5, 0),
	Size = UDim2.fromOffset(20, 24), Font = Enum.Font.GothamBlack, Text = "H", TextSize = 20, TextColor3 = WHITE,
}, OpenBtn)
local hitBtn = new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1) }, OpenBtn)
makeDraggable(hitBtn, OpenBtn, function() setMenu(not menuOpen) end)
hitBtn.MouseEnter:Connect(function() tw(btnScale, .25, { Scale = 1.1 }, Enum.EasingStyle.Back) end)
hitBtn.MouseLeave:Connect(function() tw(btnScale, .25, { Scale = 1 }, Enum.EasingStyle.Back) end)
hitBtn.MouseButton1Down:Connect(function() tw(btnScale, .12, { Scale = .92 }) end)
hitBtn.MouseButton1Up:Connect(function() tw(btnScale, .2, { Scale = 1.1 }, Enum.EasingStyle.Back) end)

X.addFrame(function()
	local t = os.clock()
	local off = math.sin(t * 2.4) * 4
	local sx = math.cos(t * 2.4) * 2
	letterN.Position = UDim2.new(.5, 1 + sx, .5, off)
	letterH.Position = UDim2.new(.5, -1 - sx, .5, -off)
	btnGrad.Rotation = (t * 120) % 360
	if menuOpen then
		if bannerGrad then bannerGrad.Rotation = 35 + math.sin(t * .6) * 25 end
		if statsGrad then statsGrad.Rotation = 35 + math.sin(t * .6 + 1) * 25 end
		if Preview.Visible then X.pvUpdate(t) end
	end
end)

track(UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == Enum.KeyCode.RightShift then
		setMenu(not menuOpen)
	end
end))

----------------------------------------------------------------
-- Выгрузка
----------------------------------------------------------------
function unload()
	alive = false
	for _, f in ipairs(X.unloaders) do pcall(f) end
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	pcall(function() RunService:UnbindFromRenderStep("NH_FOV") end)
	pcall(function() RunService:UnbindFromRenderStep("NH_MAIN") end)
	pcall(function()
		local cam = Workspace.CurrentCamera
		if fovOn and cam then cam.FieldOfView = fovSaved or 70 end
	end)
	for _, d in pairs(ESPS) do destroyData(d.o) end
	for _, h in pairs(hats) do pcall(function() h:Destroy() end) end
	for _, t in pairs(trails) do destroyTrail(t) end
	pcall(function() espGui:Destroy() end)
	pcall(function() gui:Destroy() end)
	ENV.NurHubMM2Unload = nil
end
ENV.NurHubMM2Unload = unload

----------------------------------------------------------------
-- Поиск по функциям + загрузочный экран + Welcome
----------------------------------------------------------------
do
	local function run()
		-- ПОИСК
		local sbox = new("TextBox", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 8), Size = UDim2.fromOffset(190, 26),
			BackgroundColor3 = C.field, BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.text,
			PlaceholderText = "Search...", PlaceholderColor3 = C.sub, Text = "", ClearTextOnFocus = false, ZIndex = 5,
		}, Main)
		corner(sbox, 9)
		stroke(sbox, C.line, 1)
		new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, sbox)

		local results = new("Frame", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 38), Size = UDim2.fromOffset(250, 0),
			BackgroundColor3 = C.card, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, ZIndex = 20,
		}, Main)
		corner(results, 10)
		stroke(results, C.line, 1)
		new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, results)
		new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, results)

		local function flash(box)
			if not box or not box.Parent then return end
			local h = math.min(box.Size.Y.Offset, 40)
			local ov = new("Frame", {
				Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = Color3.fromRGB(255, 50, 60), BackgroundTransparency = 1,
				BorderSizePixel = 0, ZIndex = 10,
			}, box)
			corner(ov, 7)
			local s = stroke(ov, Color3.fromRGB(255, 70, 80), 2, 1)
			task.spawn(function()
				for _ = 1, 3 do
					tw(ov, .28, { BackgroundTransparency = .55 })
					tw(s, .28, { Transparency = 0 })
					task.wait(.3)
					tw(ov, .28, { BackgroundTransparency = .9 })
					tw(s, .28, { Transparency = .5 })
					task.wait(.3)
				end
				tw(ov, .3, { BackgroundTransparency = 1 })
				tw(s, .3, { Transparency = 1 })
				task.wait(.35)
				ov:Destroy()
			end)
		end

		local function jump(e)
			results.Visible = false
			results.Size = UDim2.fromOffset(250, 0)
			sbox.Text = ""
			switchTab(e.tab)
			task.delay(.55, function()
				local sf = X.pageSF[e.tab]
				if sf and e.box.Parent then
					local sc = math.max(fitScale.Scale * animScale.Scale, .01)
					local target = math.max(0, (e.box.AbsolutePosition.Y - sf.AbsolutePosition.Y) / sc + sf.CanvasPosition.Y - 24)
					tw(sf, .5, { CanvasPosition = Vector2.new(0, target) })
				end
				task.delay(.25, function() flash(e.box) end)
			end)
		end

		local rows = {}
		local function refreshResults()
			for _, r in ipairs(rows) do r:Destroy() end
			rows = {}
			local q = sbox.Text:lower()
			if q == "" then
				results.Visible = false
				return
			end
			local n = 0
			for _, e in ipairs(X.searchReg) do
				local en = e.name:lower()
				local ru = X.tr(e.name):lower()
				if en:find(q, 1, true) or ru:find(q, 1, true) then
					n += 1
					if n > 7 then break end
					local b = new("TextButton", {
						Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.accent, BackgroundTransparency = 1,
						BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = n, ZIndex = 21,
					}, results)
					corner(b, 7)
					new("TextLabel", {
						BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -90, 1, 0),
						Font = Enum.Font.GothamMedium, Text = X.tr(e.name), TextSize = 12, TextColor3 = C.text,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 22,
					}, b)
					new("TextLabel", {
						BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0),
						Size = UDim2.fromOffset(78, 28), Font = Enum.Font.GothamMedium, Text = X.tr(e.tab), TextSize = 10,
						TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 22,
					}, b)
					b.MouseEnter:Connect(function() tw(b, .12, { BackgroundTransparency = .7 }) end)
					b.MouseLeave:Connect(function() tw(b, .12, { BackgroundTransparency = 1 }) end)
					b.MouseButton1Click:Connect(function() jump(e) end)
					rows[#rows + 1] = b
				end
			end
			if n == 0 then
				local l = new("TextLabel", {
					BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), Font = Enum.Font.GothamMedium, Text = X.tr("Nothing found"),
					TextSize = 12, TextColor3 = C.sub, ZIndex = 21,
				}, results)
				rows[#rows + 1] = l
				n = 1
			end
			results.Visible = true
			tw(results, .25, { Size = UDim2.fromOffset(250, math.min(n, 7) * 30 + 8) })
		end
		sbox:GetPropertyChangedSignal("Text"):Connect(refreshResults)

		-- ЗАГРУЗКА + WELCOME
		function X.intro()
			OpenBtn.Visible = false
			local ig = new("ScreenGui", {
				Name = "NurHubMM2_Load", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 300,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			})
			mount(ig)
			local bgf = new("Frame", {
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 6, 10), BackgroundTransparency = 1, BorderSizePixel = 0,
			}, ig)
			tw(bgf, .4, { BackgroundTransparency = .2 })
			local card = new("CanvasGroup", {
				AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(330, 176),
				BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1,
			}, bgf)
			corner(card, 18)
			local cs = new("UIScale", { Scale = .88 }, card)
			local frame = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, card)
			stroke(frame, C.line, 1)
			local logo = new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 40),
				Font = Enum.Font.GothamBlack, Text = "NURHUB", TextSize = 34, TextColor3 = WHITE,
			}, card)
			local lg = new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, logo)
			new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 0, 16),
				Font = Enum.Font.GothamMedium, Text = "Murder Mystery 2  •  v" .. VERSION, TextSize = 11, TextColor3 = C.sub,
			}, card)
			local status = new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(35, 108), Size = UDim2.new(1, -70, 0, 14),
				Font = Enum.Font.GothamMedium, Text = "Loading modules...", TextSize = 11, TextColor3 = C.sub,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, card)
			local pctL = new("TextLabel", {
				BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -35, 0, 108),
				Size = UDim2.fromOffset(50, 14), Font = Enum.Font.GothamBold, Text = "0%", TextSize = 11, TextColor3 = C.text,
				TextXAlignment = Enum.TextXAlignment.Right,
			}, card)
			local bar = new("Frame", {
				Position = UDim2.fromOffset(35, 132), Size = UDim2.new(1, -70, 0, 6), BackgroundColor3 = C.track, BorderSizePixel = 0,
			}, card)
			corner(bar, 3)
			local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, bar)
			corner(fill, 3)
			new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, fill)

			tw(card, .5, { GroupTransparency = 0 })
			tw(cs, .6, { Scale = 1 }, Enum.EasingStyle.Back)

			local texts = { "Loading modules...", "Preparing ESP...", "Building interface...", "Almost ready..." }
			task.spawn(function()
				local t0, dur = os.clock(), 2.8
				while alive do
					local a = math.clamp((os.clock() - t0) / dur, 0, 1)
					local p = a * a * (3 - 2 * a)
					fill.Size = UDim2.fromScale(p, 1)
					pctL.Text = math.floor(p * 100) .. "%"
					status.Text = texts[math.clamp(math.floor(p * 4) + 1, 1, 4)]
					lg.Rotation = (os.clock() * 90) % 360
					if a >= 1 then break end
					task.wait()
				end
				if not alive then
					ig:Destroy()
					return
				end
				tw(card, .35, { GroupTransparency = 1 })
				tw(cs, .35, { Scale = 1.08 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.wait(.4)

				-- Welcome
				local wl = new("TextLabel", {
					AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(520, 60),
					BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 36, TextColor3 = WHITE,
					Text = "Welcome, " .. LP.DisplayName, MaxVisibleGraphemes = 0,
				}, bgf)
				local wg = new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, wl)
				local ws = new("UIScale", { Scale = .8 }, wl)
				tw(ws, .7, { Scale = 1 }, Enum.EasingStyle.Back)
				local total = utf8.len(wl.Text) or #wl.Text
				for i = 1, total do
					wl.MaxVisibleGraphemes = i
					task.wait(.045)
				end
				local t1 = os.clock()
				while os.clock() - t1 < 1.1 and alive do
					wg.Rotation = (os.clock() * 120) % 360
					task.wait()
				end
				tw(wl, .4, { TextTransparency = 1 })
				tw(bgf, .5, { BackgroundTransparency = 1 })
				task.wait(.5)
				ig:Destroy()
				if not alive then return end
				OpenBtn.Visible = true
				btnScale.Scale = .2
				tw(btnScale, .6, { Scale = 1 }, Enum.EasingStyle.Back)
				setMenu(true)
			end)
		end
	end
	run()
end

X.intro()
