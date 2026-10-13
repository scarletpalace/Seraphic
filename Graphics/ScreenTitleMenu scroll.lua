local gc = Var("GameCommand")

return Def.ActorFrame {
	-- lit bar behind the focused entry (same sprite as the selected song on the music wheel)
	Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_barsel_full"),
		InitCommand = function(self)
			self:xy(266, -72):halign(0):zoomto(0, 26):diffusealpha(0)
		end,
		GainFocusCommand = function(self)
			self:stoptweening():diffusealpha(1):linear(0.12):zoomto(232, 26)
		end,
		LoseFocusCommand = function(self)
			self:stoptweening():linear(0.08):diffusealpha(0):zoomto(0, 26)
		end
	},
	-- diamond bullet: bright on the focused entry, dim on the others
	Def.Quad {
		InitCommand = function(self)
			self:xy(279, -72):rotationz(45):zoomto(5, 5):diffuse(color("#ffffff")):diffusealpha(0.4)
		end,
		GainFocusCommand = function(self)
			self:stoptweening():linear(0.1):diffusealpha(1):zoomto(7, 7)
		end,
		LoseFocusCommand = function(self)
			self:stoptweening():linear(0.1):diffusealpha(0.4):zoomto(5, 5)
		end
	},
	LoadFont("Common Large") ..
		{
			Text = THEME:GetString("ScreenTitleMenu", gc:GetText()),
			OnCommand = function(self)
				self:xy(293, -72):align(0, 0.5):maxwidth(190 / 0.34)
			end,
			GainFocusCommand = function(self)
				self:stoptweening():linear(0.1):zoom(0.34):diffuse(color("#ffffff"))
			end,
			LoseFocusCommand = function(self)
				self:stoptweening():linear(0.1):zoom(0.29):diffuse(getTitleColor('Line_Left')):diffusealpha(0.75)
			end
		}
}
