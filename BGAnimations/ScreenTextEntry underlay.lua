local t = Def.ActorFrame {
	OnCommand = function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(function(event)
			if event.DeviceInput.button == "DeviceButton_right mouse button" then
				SCREENMAN:GetTopScreen():Cancel()
			end
		end)
	end,
}

-- Seraphic: the title screen's sanctuary backdrop (rose window, chains, embers) behind login and other prompts;
-- inside Music Select the prompt stays over the select screen instead
t[#t + 1] = Def.ActorFrame {
	InitCommand = function(self)
		self:visible(false):diffusealpha(0)
	end,
	OnCommand = function(self)
		if not inScreenSelectMusic then
			self:visible(true):decelerate(0.1):diffusealpha(1)
		end
	end,
	LoadActor("_sanctuary", SCREEN_CENTER_Y)
}

-- Seraphic: the question sits in an LR2 window (dark glass, soft edge, header band with a crimson rule, filigree).
-- The window grows upward to fit the question (it can be one line or several), ending below the answer.
local winW = SCREEN_WIDTH - 250
local winX = SCREEN_CENTER_X - winW / 2
local winBottom = SCREEN_CENTER_Y + 50
local function questionHeight()
	local h = 46
	pcall(function()
		local q = SCREENMAN:GetTopScreen():GetChild("Question")
		if q and q:GetHeight() > 0 then h = q:GetHeight() * q:GetZoomY() end
	end)
	return h
end
local function edgeQuad(fit)
	return Def.Quad {
		InitCommand = function(self)
			self:halign(0):valign(0):diffuse(color("#ffffff")):diffusealpha(0.18)
		end,
		FitCommand = fit
	}
end
-- over Music Select the prompt gets a dim veil so it reads as a pop-up rather than part of the screen
t[#t+1] = Def.Quad {
	InitCommand = function(self)
		self:FullScreen():diffuse(color("#000000")):diffusealpha(0)
	end,
	OnCommand = function(self)
		if inScreenSelectMusic then self:decelerate(0.12):diffusealpha(0.6) end
	end,
	OffCommand = function(self)
		self:decelerate(0.1):diffusealpha(0)
	end
}
t[#t+1] = Def.ActorFrame {
	Name = "Window",
	InitCommand = function(self)
		self:diffusealpha(0)
	end,
	OnCommand = function(self)
		-- question text is set by the screen; measure it on the next frame
		self:queuecommand("Measure")
		self:decelerate(0.1):diffusealpha(1)
	end,
	MeasureCommand = function(self)
		local top = math.max(20, (SCREEN_CENTER_Y - 20) - questionHeight() - 24)
		-- hidden input (passwords) shows the Unhide button under the answer, so the window reaches below it
		local bottom = winBottom
		pcall(function() if SCREENMAN:GetTopScreen():IsInputHidden() then bottom = SCREEN_CENTER_Y + 70 end end)
		self:playcommand("Fit", {top = top, h = bottom - top, bottom = bottom})
	end,
	OffCommand = function(self)
		self:decelerate(0.1):diffusealpha(0)
	end,
	Def.Quad {
		Name = "BG",
		InitCommand = function(self)
			self:xy(winX, SCREEN_CENTER_Y - 60):halign(0):valign(0):zoomto(winW, 110)
			self:diffuseupperleft(color("#262626")):diffuseupperright(color("#1a1a1a"))
			self:diffuselowerleft(color("#0a0a0a")):diffuselowerright(color("#060606"))
			self:diffusealpha(0.96)
		end,
		FitCommand = function(self, p) self:y(p.top):zoomto(winW, p.h) end
	},
	-- faint crimson glow rising from the bottom of the window
	Def.Quad {
		InitCommand = function(self)
			self:x(winX):halign(0):valign(1):diffuse(color("#9c1428"))
			self:diffusetopedge(color("#9c142800")):diffusebottomedge(color("#9c142830"))
		end,
		FitCommand = function(self, p) self:y(p.bottom):zoomto(winW, math.min(60, p.h * 0.5)) end
	},
	-- header band with its crimson rule
	Def.Quad {
		InitCommand = function(self)
			self:x(winX):halign(0):valign(0):zoomto(winW, 14):diffuse(color("#000000")):diffusealpha(0.45)
		end,
		FitCommand = function(self, p) self:y(p.top) end
	},
	Def.Quad {
		InitCommand = function(self)
			self:x(winX):halign(0):valign(0):zoomto(winW, 1):diffuse(color("#9c1428")):diffusealpha(0.9)
			self:faderight(0.3)
		end,
		FitCommand = function(self, p) self:y(p.top + 14) end
	},
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:x(winX + 6):halign(0):zoom(0.38):diffuse(color(seraphicLabelColor)):settext(seraphicHeading("Input"))
		end,
		FitCommand = function(self, p) self:y(p.top + 7) end
	},
	Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_filigree"),
		InitCommand = function(self)
			self:xy(SCREEN_CENTER_X, winBottom - 3):valign(1):zoomto(winW - 8, 24):diffusealpha(0.14)
		end,
		FitCommand = function(self, p) self:y(p.bottom - 3) end
	},
	edgeQuad(function(self, p) self:xy(winX, p.top):zoomto(winW, 1) end),
	edgeQuad(function(self, p) self:xy(winX, p.bottom - 1):zoomto(winW, 1) end),
	edgeQuad(function(self, p) self:xy(winX, p.top):zoomto(1, p.h) end),
	edgeQuad(function(self, p) self:xy(winX + winW - 1, p.top):zoomto(1, p.h) end),
	-- crystal corners
	Def.ActorFrame {
		FitCommand = function(self, p)
			local function at(name, gx, gy) self:GetChild(name):xy(gx, gy) end
			at("TL", winX - 4, p.top - 4)
			at("TR", winX + winW + 4, p.top - 4)
			at("BL", winX - 4, p.bottom + 4)
			at("BR", winX + winW + 4, p.bottom + 4)
		end,
		Def.Sprite { Name = "TL", Texture = THEME:GetPathG("", "seraphic_corner"), InitCommand = function(self) self:halign(0):valign(0):zoom(0.3):diffusealpha(0.95) end },
		Def.Sprite { Name = "TR", Texture = THEME:GetPathG("", "seraphic_corner"), InitCommand = function(self) self:halign(0):valign(0):zoomx(-0.3):zoomy(0.3):diffusealpha(0.95) end },
		Def.Sprite { Name = "BL", Texture = THEME:GetPathG("", "seraphic_corner"), InitCommand = function(self) self:halign(0):valign(0):zoomx(0.3):zoomy(-0.3):diffusealpha(0.95) end },
		Def.Sprite { Name = "BR", Texture = THEME:GetPathG("", "seraphic_corner"), InitCommand = function(self) self:halign(0):valign(0):zoom(-0.3):diffusealpha(0.95) end }
	},
	-- underline the answer sits on
	Def.Quad {
		InitCommand = function(self)
			self:xy(SCREEN_CENTER_X, SCREEN_CENTER_Y + 24):zoomto(winW * 0.5, 1):diffuse(color("#ffffff"))
			self:diffusealpha(0.35):fadeleft(0.3):faderight(0.3)
		end
	}
}


local unhideWidth = 100 / 1920 * SCREEN_WIDTH
local unhideHeight = 55 / 1080 * SCREEN_HEIGHT


local translations = {
    Unhide = THEME:GetString("ScreenTextEntry", "Unhide"),
}


local boxWidth = SCREEN_WIDTH - 250
local boxHeight = 175
local sideMargin = 15 / 1920 * SCREEN_WIDTH
local bottomMargin = 15 / 1080 * SCREEN_HEIGHT

local textsize = 0.86


t[#t+1] = Def.ActorFrame {
	InitCommand = function(self)
		self:Center()
	end,
	BeginCommand = function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(function(event)
			if event.type == "InputEventType_FirstPress" then
				if event.DeviceInput.button == "DeviceButton_left mouse button" then
					self:playcommand("PressyMyMouseButton")
				end
			elseif event.type == "InputEventType_Release" then
				if event.DeviceInput.button == "DeviceButton_left mouse button" then
					self:playcommand("ReleaseMouseButton")
				end
			end
		end)
		self:SetUpdateFunction(function(self) self:playcommand("HighlightyMyMouseHovering") end)
	end,
	-- Seraphic: hold-to-reveal button centred under the answer, styled like the other LR2 toggles
	Def.Quad {
		Name = "UnhideButton",
		InitCommand = function(self)
			self:xy(0, 46):zoomto(110, 16)
			self:diffuse(color("#000000")):diffusealpha(0.55)
			self:visible(false)
			self.isheld = false
		end,
		OnCommand = function(self)
			self:visible(SCREENMAN:GetTopScreen():IsInputHidden())
			-- (the window makes room for this button itself, see Window's MeasureCommand)
		end,
		PressyMyMouseButtonCommand = function(self)
			if self:GetVisible() and isOver(self) then
				if self.isheld then return end
				self.isheld = true
				SCREENMAN:GetTopScreen():ToggleInputHidden()
			end
		end,
		ReleaseMouseButtonCommand = function(self)
			if self.isheld then
				self.isheld = false
				SCREENMAN:GetTopScreen():ToggleInputHidden()
			end
		end,
		HighlightyMyMouseHoveringCommand = function(self)
			if self.isheld then
				self:diffuse(color("#9c1428")):diffusealpha(0.7)
			elseif isOver(self) then
				self:diffuse(color("#9c1428")):diffusealpha(0.4)
			else
				self:diffuse(color("#000000")):diffusealpha(0.55)
			end
		end
	},
	Def.ActorFrame {
		InitCommand = function(self) self:visible(false) end,
		OnCommand = function(self)
			self:visible(SCREENMAN:GetTopScreen():IsInputHidden())
		end,
		seraphicSoftEdge(-55, 38, 110, 16, 0.25)
	},
	LoadFont("Common Normal") .. {
		Name = "Unhide",
		InitCommand = function(self)
			self:xy(0, 46):zoom(0.4):maxwidth(100 / 0.4):diffuse(color(seraphicLabelColor))
			self:settext(tostring(translations["Unhide"]):upper())
			self:visible(false)
		end,
		OnCommand = function(self)
			self:visible(SCREENMAN:GetTopScreen():IsInputHidden())
		end,
	}
}

return t
