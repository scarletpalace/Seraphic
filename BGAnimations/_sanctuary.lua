-- Seraphic sanctuary backdrop shared by the title menu, profile select and pack downloader: a
-- rose window of turning magic circles under the chain garland, embers rising from a floor glow
-- whose colour follows the player's clock (day, dusk, night).
-- Optional argument: the window's centre y.
local windowArg = ...
local t = Def.ActorFrame {}
local cx = SCREEN_CENTER_X
local windowY = windowArg or (SCREEN_CENTER_Y + 52)

-- Candle-light: each mood is plain numbers (no color() objects) so two moods can be blended
-- when a long session crosses an hour boundary.
local moods = {
	-- day: cool silver-blue light, a few slow embers
	day = {
		overlay = 0.5, floor = {0.32, 0.40, 0.55, 0.5}, halo = {0.62, 0.72, 0.92, 0.2},
		ember = {0.82, 0.90, 1.0}, embers = 6, speed = 0.7, candles = 0
	},
	-- dusk: warm amber/crimson floor (#7a2a10), a touch brighter
	dusk = {
		overlay = 0.5, floor = {0.478, 0.165, 0.063, 0.75}, halo = {0.78, 0.25, 0.12, 0.3},
		ember = {1.0, 0.68, 0.45}, embers = 10, speed = 1.0, candles = 0
	},
	-- night: deeper dark, crimson glow, more embers rising faster, candles at the foot
	night = {
		overlay = 0.68, floor = {0.36, 0.03, 0.07, 0.72}, halo = {0.62, 0.07, 0.15, 0.24},
		ember = {1.0, 0.55, 0.45}, embers = 16, speed = 1.35, candles = 1
	}
}
local function currentHour()
	local h
	if type(Hour) == "function" then
		local ok, v = pcall(Hour)
		if ok then
			h = tonumber(v)
		end
	end
	if type(h) ~= "number" then
		h = tonumber(os.date("%H"))
	end
	return h or 20
end
local function moodFor(h)
	if h >= 6 and h <= 16 then
		return moods.day
	elseif h >= 17 and h <= 20 then
		return moods.dusk
	end
	return moods.night
end
-- the live state starts as a copy of the current mood, so the screen opens already settled
local target = moodFor(currentHour())
local live = {
	overlay = target.overlay, speed = target.speed, embers = target.embers, candles = target.candles,
	floor = {unpack(target.floor)}, halo = {unpack(target.halo)}, ember = {unpack(target.ember)}
}
-- actors the update loop recolours, captured in their InitCommands
local overlayQuad, floorQuad, haloSprite
local emberSprites, candleSprites = {}, {}

local function applyBackdrop()
	if overlayQuad then
		overlayQuad:diffusealpha(live.overlay)
	end
	if floorQuad then
		local f = live.floor
		floorQuad:diffuse({f[1], f[2], f[3], f[4]}):diffusetopedge({f[1], f[2], f[3], 0})
	end
	if haloSprite then
		local h = live.halo
		haloSprite:diffuse({h[1], h[2], h[3], h[4]})
	end
end

-- backdrop, pushed into the dark
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "_OptionsScreen"),
	InitCommand = function(self)
		self:FullScreen():diffuse(color("#5a5560"))
	end
}
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		overlayQuad = self
		self:FullScreen():diffuse(color("#000000")):diffusealpha(live.overlay)
	end
}
-- side shadows close the frame in like the walls of a nave
for _, side in ipairs({0, 1}) do
	t[#t + 1] = Def.Quad {
		InitCommand = function(self)
			self:xy(side == 0 and 0 or SCREEN_WIDTH, 0):halign(side):valign(0):zoomto(SCREEN_WIDTH * 0.32, SCREEN_HEIGHT)
			self:diffuse(color("#000000"))
			if side == 0 then
				self:diffuserightedge(color("#00000000"))
			else
				self:diffuseleftedge(color("#00000000"))
			end
		end
	}
end
-- light rising from the floor, tinted by the hour
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		floorQuad = self
		self:xy(0, SCREEN_HEIGHT):halign(0):valign(1):zoomto(SCREEN_WIDTH, SCREEN_HEIGHT * 0.55)
		applyBackdrop()
	end
}

-- rose window: three circles turning against each other, with a halo tinted by the hour
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_circle"),
	InitCommand = function(self)
		haloSprite = self
		self:xy(cx, windowY):zoom(1.12):blend("BlendMode_Add")
		applyBackdrop()
		self:spin():effectmagnitude(0, 0, -1.5)
	end
}
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_circle"),
	InitCommand = function(self)
		self:xy(cx, windowY):zoom(0.98):diffusealpha(0.42):blend("BlendMode_Add")
		self:spin():effectmagnitude(0, 0, 2.5)
	end
}
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_circle"),
	InitCommand = function(self)
		self:xy(cx, windowY):zoom(0.5):diffusealpha(0.24):blend("BlendMode_Add")
		self:spin():effectmagnitude(0, 0, -6)
	end
}
-- dark well in the middle of the window so the menu stays readable
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(cx, windowY):zoomto(300, 220):diffuse(color("#000000")):diffusealpha(0.5)
		self:fadeleft(0.4):faderight(0.4):fadetop(0.25):fadebottom(0.25)
	end
}

-- chain garland across the top, as on the music select header
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_chain"),
	InitCommand = function(self)
		self:xy(cx, 0):valign(0):zoomto(SCREEN_WIDTH, SCREEN_WIDTH * 96 / 640):diffusealpha(0.55):blend("BlendMode_Add")
	end
}

-- embers drifting up through the window, and at night a few candle flames at the foot.
-- Driven by an update function rather than tweens: the menu locks input until every tween on
-- the screen has finished, so looping tweens here would keep the menu frozen.
do
	-- {x offset, seconds per rise, start phase, zoom}; the first six burn by day, the first ten
	-- at dusk, all sixteen at night
	local embers = {
		{-300, 11, 0.0, 0.35}, {-130, 9, 5.5, 0.3}, {40, 10, 4.2, 0.3}, {205, 15, 6.3, 0.32},
		{-250, 16, 7.4, 0.2}, {290, 10, 2.5, 0.28},
		{-210, 14, 3.1, 0.25}, {-60, 13, 1.7, 0.22}, {120, 12, 0.8, 0.25}, {250, 13, 8.8, 0.22},
		{-345, 12, 9.6, 0.2}, {-175, 10, 2.0, 0.24}, {-20, 11, 6.9, 0.2}, {80, 14, 3.6, 0.22},
		{170, 9, 7.9, 0.2}, {340, 12, 4.8, 0.24}
	}
	-- {x offset, height above the bottom, zoom, flicker phase}: low on either side, clear of the motto
	local candles = {
		{-360, 34, 0.2, 0.0}, {-300, 22, 0.16, 1.9}, {-232, 40, 0.14, 3.7},
		{232, 40, 0.14, 2.6}, {300, 22, 0.16, 4.4}, {360, 34, 0.2, 5.8}
	}
	local progress, weight = {}, {}
	for i, e in ipairs(embers) do
		progress[i] = (e[3] % e[2]) / e[2]
		weight[i] = i <= live.embers and 1 or 0
	end

	local function approach(a, b, k)
		return a + (b - a) * k
	end
	local function blendLive(k)
		live.overlay = approach(live.overlay, target.overlay, k)
		live.speed = approach(live.speed, target.speed, k)
		live.candles = approach(live.candles, target.candles, k)
		live.embers = target.embers
		for c = 1, 4 do
			live.floor[c] = approach(live.floor[c], target.floor[c], k)
			live.halo[c] = approach(live.halo[c], target.halo[c], k)
		end
		for c = 1, 3 do
			live.ember[c] = approach(live.ember[c], target.ember[c], k)
		end
	end
	local function settled()
		local d = math.abs(live.overlay - target.overlay) + math.abs(live.candles - target.candles)
		for c = 1, 4 do
			d = d + math.abs(live.floor[c] - target.floor[c]) + math.abs(live.halo[c] - target.halo[c])
		end
		return d < 0.01
	end

	local f = Def.ActorFrame {
		InitCommand = function(self)
			local clock = 0
			local sinceCheck = 0
			local blending = false
			self:SetUpdateFunction(function(frame, dt)
				clock = clock + dt
				-- re-read the clock once a minute; a new mood eases in over a few seconds
				sinceCheck = sinceCheck + dt
				if sinceCheck >= 60 then
					sinceCheck = 0
					local m = moodFor(currentHour())
					if m ~= target then
						target = m
						blending = true
					end
				end
				if blending then
					blendLive(math.min(1, dt * 0.8))
					if settled() then
						blendLive(1)
						blending = false
					end
					applyBackdrop()
				end

				local er, eg, eb = live.ember[1], live.ember[2], live.ember[3]
				for i, e in ipairs(embers) do
					local s = emberSprites[i]
					if s then
						-- embers joining or leaving with a mood fade rather than pop
						weight[i] = approach(weight[i], i <= live.embers and 1 or 0, math.min(1, dt * 0.5))
						-- progress through one rise, 0..1, advanced at the mood's speed
						progress[i] = (progress[i] + dt * live.speed / e[2]) % 1
						local p = progress[i]
						local a = math.max(math.min(p / 0.2, (1 - p) / 0.3, 1), 0) * 0.9 * weight[i]
						s:xy(cx + e[1] + math.sin(p * 6.28 + i) * 8, SCREEN_HEIGHT + 10 - p * SCREEN_HEIGHT * 0.8)
						s:rotationz(p * 140):diffuse({er, eg, eb, a})
					end
				end

				-- candle flames: two slow waves and a quick one, so each breathes unevenly
				local cw = live.candles
				for i, c in ipairs(candleSprites) do
					if cw < 0.01 then
						c:diffusealpha(0)
					else
						local ph = candles[i][4]
						local fl = 0.72 + 0.14 * math.sin(clock * 2.3 + ph) + 0.09 * math.sin(clock * 5.1 + ph * 1.7)
							+ 0.05 * math.sin(clock * 11.7 + ph * 2.9)
						c:diffusealpha(0.55 * fl * cw):zoom(candles[i][3] * (0.94 + 0.08 * fl))
					end
				end
			end)
		end
	}
	for i, e in ipairs(embers) do
		f[#f + 1] = Def.Sprite {
			Name = "Ember" .. i,
			Texture = THEME:GetPathG("", "seraphic_sparkle"),
			InitCommand = function(self)
				emberSprites[i] = self
				self:blend("BlendMode_Add"):zoom(e[4]):diffuse(color("#ff9a7a")):diffusealpha(0)
			end
		}
	end
	for i, c in ipairs(candles) do
		f[#f + 1] = Def.Sprite {
			Name = "Candle" .. i,
			Texture = THEME:GetPathG("", "seraphic_sparkle"),
			InitCommand = function(self)
				candleSprites[i] = self
				self:xy(cx + c[1], SCREEN_HEIGHT - c[2]):zoom(c[3]):blend("BlendMode_Add")
				self:diffuse(color("#ffc27a")):diffusealpha(0)
			end
		}
	end
	t[#t + 1] = f
end

-- a few still stars caught in the window's glass
do
	local sparks = {{-150, -95, 0.5, 0.0}, {165, -60, 0.6, 1.3}, {-185, 70, 0.45, 2.2}, {140, 95, 0.4, 0.7}, {0, -128, 0.55, 1.8}}
	for _, sp in ipairs(sparks) do
		t[#t + 1] = Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_sparkle"),
			InitCommand = function(self)
				self:xy(cx + sp[1], windowY + sp[2]):zoom(sp[3]):blend("BlendMode_Add")
				self:diffuseshift():effectcolor1(color("1,1,1,0")):effectcolor2(color("1,1,1,0.9"))
				self:effectperiod(3.2):effectoffset(sp[4])
			end
		}
	end
end

return t
