-- Seraphic: options screens (service menu, theme/network/graphics options...) sit over the title screen's
-- sanctuary in an LR2 window: dark glass, header band with the screen's name, banded rows and a
-- separate strip for the explanation line. The window is fitted to the screen's own row layout
-- (read from its metrics), so a two-row screen gets a small window and a long list a tall one.
-- Optional argument {x = left edge, w = width} places the window elsewhere (player options keep a sidebar on the left).
local args = ...
if type(args) ~= "table" then args = {} end
local t = Def.ActorFrame {}

t[#t + 1] = LoadActor("_sanctuary", SCREEN_CENTER_Y)

local winW = args.w or 620
local winX = args.x or (SCREEN_CENTER_X - winW / 2)
local winCX = winX + winW / 2
local headH = args.noHeader and 0 or 18

local function metric(name, key)
	local ok, v = pcall(function() return THEME:GetMetric(name, key) end)
	if ok then return v end
	return nil
end

-- where the screen puts its rows: run its RowPositionTransformFunction on a stand-in actor
local function layout()
	local screen = SCREENMAN:GetTopScreen()
	if not screen or not screen.GetNumRows then return nil end
	local name = screen:GetName()
	if name:find("MiniMenu") then return nil end -- pop-up menus lay out around their own anchor
	local f = metric(name, "RowPositionTransformFunction")
	if type(f) ~= "function" then return nil end
	local rows = screen:GetNumRows()
	local exitY
	if metric(name, "ShowExitRow") and metric(name, "SeparateExitRow") and rows > 0 then
		local ok, last = pcall(function() return screen:GetOptionRow(rows - 1):GetName() end)
		if ok and last == "Exit" then
			rows = rows - 1
			exitY = metric(name, "SeparateExitRowY")
		end
	end
	local shown = math.min(rows, tonumber(metric(name, "NumRowsShown")) or rows)
	if shown < 1 then return nil end
	local function slot(i)
		local y = 0
		local probe = {y = function(_, v) y = v end}
		local ok = pcall(f, probe, i, i, shown)
		return ok and y or nil
	end
	local y0, y1 = slot(0), slot(1)
	if not y0 then return nil end
	local step = (y1 and shown > 1) and (y1 - y0) or 32
	local L = {first = y0, step = step, shown = shown, exitY = exitY}
	if metric(name, "ShowExplanations") then
		L.explY = tonumber(metric(name, args.explMetric or "ExplanationTogetherY"))
	end
	local ok, header = pcall(function() return THEME:GetString(name, "HeaderText") end)
	if not ok or not header or header == "" then
		header = name:gsub("^Screen", ""):gsub("(%l)(%u)", "%1 %2")
	end
	L.header = header
	L.top = y0 - step / 2 - (args.noHeader and 2 or headH + 6)
	L.bottom = (exitY or (y0 + step * (shown - 1))) + step / 2 + 8
	return L
end

local function quad(init, fit)
	return Def.Quad {InitCommand = init, FitCommand = fit}
end
local function edge(fit)
	return quad(function(self) self:halign(0):valign(0):diffuse(color("#ffffff")):diffusealpha(0.18) end, fit)
end

local win = Def.ActorFrame {
	InitCommand = function(self)
		self:diffusealpha(0)
	end,
	OnCommand = function(self)
		-- rows are built by the screen; read them on the next frame
		self:queuecommand("Measure")
	end,
	MeasureCommand = function(self)
		local L = layout()
		if not L then return end
		L.h = L.bottom - L.top
		self:playcommand("Fit", L)
		self:decelerate(0.15):diffusealpha(1)
	end,
	OffCommand = function(self)
		self:decelerate(0.1):diffusealpha(0)
	end,
	-- body
	quad(function(self)
		self:x(winX):halign(0):valign(0)
		self:diffuseupperleft(color("#262626")):diffuseupperright(color("#1a1a1a"))
		self:diffuselowerleft(color("#0a0a0a")):diffuselowerright(color("#060606"))
		self:diffusealpha(0.92)
	end, function(self, L) self:y(L.top):zoomto(winW, L.h) end),
	-- faint crimson glow rising from the bottom
	quad(function(self)
		self:x(winX):halign(0):valign(1):diffuse(color("#9c1428"))
		self:diffusetopedge(color("#9c142800")):diffusebottomedge(color("#9c142830"))
	end, function(self, L) self:y(L.bottom):zoomto(winW, math.min(70, L.h * 0.4)) end),
	-- header band, crimson rule, heading
	quad(function(self) self:x(winX):halign(0):valign(0):diffuse(color("#000000")):diffusealpha(0.45) end,
		function(self, L) self:y(L.top):zoomto(winW, headH) end),
	quad(function(self) self:x(winX):halign(0):valign(0):diffuse(color("#9c1428")):diffusealpha(args.noHeader and 0 or 0.9):faderight(0.3) end,
		function(self, L) self:y(L.top + headH):zoomto(winW, 1) end),
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:visible(not args.noHeader)
			self:x(winX + 8):halign(0):zoom(0.42):diffuse(color(seraphicLabelColor))
		end,
		FitCommand = function(self, L)
			self:y(L.top + headH / 2):settext(seraphicHeading(L.header))
		end
	},
	Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_filigree"),
		InitCommand = function(self)
			self:x(winCX):valign(1):zoomto(winW - 8, 24):diffusealpha(0.12)
		end,
		FitCommand = function(self, L) self:y(L.bottom - 3) end
	},
	edge(function(self, L) self:xy(winX, L.top):zoomto(winW, 1) end),
	edge(function(self, L) self:xy(winX, L.bottom - 1):zoomto(winW, 1) end),
	edge(function(self, L) self:xy(winX, L.top):zoomto(1, L.h) end),
	edge(function(self, L) self:xy(winX + winW - 1, L.top):zoomto(1, L.h) end),
	-- crystal corners
	Def.ActorFrame {
		FitCommand = function(self, L)
			local function at(n, gx, gy) self:GetChild(n):xy(gx, gy) end
			at("TL", winX - 4, L.top - 4)
			at("TR", winX + winW + 4, L.top - 4)
			at("BL", winX - 4, L.bottom + 4)
			at("BR", winX + winW + 4, L.bottom + 4)
		end,
		Def.Sprite { Name = "TL", Texture = THEME:GetPathG("", "seraphic_corner"), InitCommand = function(self) self:halign(0):valign(0):zoom(0.3):diffusealpha(0.95) end },
		Def.Sprite { Name = "TR", Texture = THEME:GetPathG("", "seraphic_corner"), InitCommand = function(self) self:halign(0):valign(0):zoomx(-0.3):zoomy(0.3):diffusealpha(0.95) end },
		Def.Sprite { Name = "BL", Texture = THEME:GetPathG("", "seraphic_corner"), InitCommand = function(self) self:halign(0):valign(0):zoomx(0.3):zoomy(-0.3):diffusealpha(0.95) end },
		Def.Sprite { Name = "BR", Texture = THEME:GetPathG("", "seraphic_corner"), InitCommand = function(self) self:halign(0):valign(0):zoom(-0.3):diffusealpha(0.95) end }
	}
}

-- alternating row bands under each row slot, and a separate one for the exit row
local maxBands = 30
for i = 1, maxBands do
	win[#win + 1] = quad(function(self)
		self:x(winX + 10):halign(0):diffuse(color("#000000")):diffusealpha(i % 2 == 1 and 0.4 or 0.15):visible(false)
	end, function(self, L)
		self:visible(i <= L.shown)
		self:y(L.first + L.step * (i - 1)):zoomto(winW - 20, L.step - 4)
	end)
end
win[#win + 1] = quad(function(self)
	self:x(winX + 10):halign(0):diffuse(color("#9c1428")):diffusealpha(0.18):visible(false)
end, function(self, L)
	self:visible(L.exitY ~= nil)
	if L.exitY then self:y(L.exitY):zoomto(winW - 20, L.step - 4) end
end)
-- a thin rule between the rows and a separate exit row
win[#win + 1] = quad(function(self)
	self:x(winCX):diffuse(color("#ffffff")):diffusealpha(0.18):fadeleft(0.3):faderight(0.3):visible(false)
end, function(self, L)
	self:visible(L.exitY ~= nil)
	if L.exitY then self:y(L.exitY - L.step / 2 - 2):zoomto(winW * 0.7, 1) end
end)

-- explanation strip below the window
win[#win + 1] = Def.ActorFrame {
	InitCommand = function(self) self:visible(false) end,
	FitCommand = function(self, L)
		self:visible(L.explY ~= nil and L.explY > L.bottom + 10)
		if L.explY then self:y(L.explY + (args.explOffset or 0)) end
	end,
	Def.Quad {
		InitCommand = function(self)
			self:x(winCX):zoomto(winW, 30):diffuse(color("#000000")):diffusealpha(0.7)
		end
	},
	Def.Quad {
		InitCommand = function(self)
			self:xy(winCX, -15):zoomto(winW, 1):diffuse(color("#9c1428")):diffusealpha(0.8):fadeleft(0.3):faderight(0.3)
		end
	},
	Def.Quad {
		InitCommand = function(self)
			self:xy(winCX, 15):zoomto(winW, 1):diffuse(color("#ffffff")):diffusealpha(0.15):fadeleft(0.3):faderight(0.3)
		end
	}
}

t[#t + 1] = win
return t
