-- Seraphic sanctuary backdrop shared by the title menu and profile select: a rose window
-- of turning magic circles under the chain garland, embers rising from a crimson floor glow.
-- Optional argument: the window's centre y.
local windowArg = ...
local t = Def.ActorFrame {}
local cx = SCREEN_CENTER_X
local windowY = windowArg or (SCREEN_CENTER_Y + 52)

-- backdrop, pushed into the dark
t[#t + 1] = LoadActor(THEME:GetPathG("", "_OptionsScreen")) .. {
	InitCommand = function(self)
		self:FullScreen():diffuse(color("#5a5560"))
	end
}
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:FullScreen():diffuse(color("#000000")):diffusealpha(0.55)
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
-- ember light rising from below
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(0, SCREEN_HEIGHT):halign(0):valign(1):zoomto(SCREEN_WIDTH, SCREEN_HEIGHT * 0.55)
		self:diffuse(color("#5a0a14A6")):diffusetopedge(color("#5a0a1400"))
	end
}

-- rose window: three circles turning against each other, with a crimson halo
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_circle"),
	InitCommand = function(self)
		self:xy(cx, windowY):zoom(1.12):diffuse(color("#b0182c")):diffusealpha(0.26):blend("BlendMode_Add")
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

-- embers drifting up through the window. Driven by an update function rather than tweens:
-- the menu locks input until every tween on the screen has finished, so looping tweens here
-- would keep the menu frozen.
do
	local embers = {
		{-300, 11, 0.0, 0.35}, {-210, 14, 3.1, 0.25}, {-130, 9, 5.5, 0.3}, {-60, 13, 1.7, 0.22},
		{40, 10, 4.2, 0.3}, {120, 12, 0.8, 0.25}, {205, 15, 6.3, 0.32}, {290, 10, 2.5, 0.28},
		{-250, 16, 7.4, 0.2}, {250, 13, 8.8, 0.22}
	}
	local f = Def.ActorFrame {
		InitCommand = function(self)
			local clock = 0
			self:SetUpdateFunction(function(frame, dt)
				clock = clock + dt
				for i, e in ipairs(embers) do
					local s = frame:GetChild("Ember" .. i)
					-- progress through one rise, 0..1, offset per ember
					local p = ((clock + e[3]) % e[2]) / e[2]
					local a = math.min(p / 0.2, (1 - p) / 0.3, 1) * 0.9
					s:xy(cx + e[1] + math.sin(p * 6.28 + i) * 8, SCREEN_HEIGHT + 10 - p * SCREEN_HEIGHT * 0.8)
					s:rotationz(p * 140):diffusealpha(math.max(a, 0))
				end
			end)
		end
	}
	for i, e in ipairs(embers) do
		f[#f + 1] = Def.Sprite {
			Name = "Ember" .. i,
			Texture = THEME:GetPathG("", "seraphic_sparkle"),
			InitCommand = function(self)
				self:blend("BlendMode_Add"):zoom(e[4]):diffuse(color("#ff9a7a")):diffusealpha(0)
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
