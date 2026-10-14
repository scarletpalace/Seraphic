local gc = Var("GameCommand")

-- Seraphic: centred entries; the focused one is lifted on a crimson glow between two wings
local wingH = 30
local function wing(dir)
	return Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_tab_feather"),
		InitCommand = function(self)
			self:x(dir * 80):rotationz(dir * 62):zoomto(dir * wingH * 160 / 256, wingH)
			self:diffusealpha(0)
		end,
		GainFocusCommand = function(self)
			local text = self:GetParent():GetChild("Label")
			local half = text and text:GetWidth() * 0.34 / 2 or 60
			self:stoptweening():x(dir * (half + 4)):diffusealpha(0)
			self:decelerate(0.18):x(dir * (half + 20)):diffusealpha(0.9)
		end,
		LoseFocusCommand = function(self)
			self:stoptweening():linear(0.1):diffusealpha(0)
		end
	}
end

return Def.ActorFrame {
	-- crimson glow behind the focused entry, fading out at both ends
	Def.Quad {
		InitCommand = function(self)
			self:zoomto(0, 20):diffuse(color("#9c1428")):diffusealpha(0):fadeleft(0.45):faderight(0.45)
		end,
		GainFocusCommand = function(self)
			self:stoptweening():decelerate(0.15):zoomto(280, 20):diffusealpha(0.55)
		end,
		LoseFocusCommand = function(self)
			self:stoptweening():linear(0.1):zoomto(120, 20):diffusealpha(0)
		end
	},
	-- hairlines above and below the glow
	Def.Quad {
		InitCommand = function(self)
			self:y(-10):zoomto(0, 1):diffuse(color("#f0dada")):diffusealpha(0):fadeleft(0.5):faderight(0.5)
		end,
		GainFocusCommand = function(self)
			self:stoptweening():decelerate(0.15):zoomto(240, 1):diffusealpha(0.7)
		end,
		LoseFocusCommand = function(self)
			self:stoptweening():linear(0.1):zoomto(0, 1):diffusealpha(0)
		end
	},
	Def.Quad {
		InitCommand = function(self)
			self:y(10):zoomto(0, 1):diffuse(color("#f0dada")):diffusealpha(0):fadeleft(0.5):faderight(0.5)
		end,
		GainFocusCommand = function(self)
			self:stoptweening():decelerate(0.15):zoomto(240, 1):diffusealpha(0.7)
		end,
		LoseFocusCommand = function(self)
			self:stoptweening():linear(0.1):zoomto(0, 1):diffusealpha(0)
		end
	},
	LoadFont("Common Large") .. {
		Name = "Label",
		Text = THEME:GetString("ScreenTitleMenu", gc:GetText()),
		OnCommand = function(self)
			self:maxwidth(200 / 0.34)
		end,
		GainFocusCommand = function(self)
			self:stoptweening():linear(0.1):zoom(0.34):diffuse(color("#ffffff"))
		end,
		LoseFocusCommand = function(self)
			self:stoptweening():linear(0.1):zoom(0.28):diffuse(color("#bdb3b6")):diffusealpha(0.7)
		end
	},
	wing(-1),
	wing(1)
}
