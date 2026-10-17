local t = Def.ActorFrame {}

--bg
-- Seraphic: the title screen's sanctuary backdrop (rose window, chains, embers, clock-coloured light)
t[#t + 1] = LoadActor("_sanctuary", SCREEN_CENTER_Y)

--black dim behind songwheel text
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(SCREEN_WIDTH, 0):halign(1):valign(0):zoomto(capWideScale(get43size(350), 350), SCREEN_HEIGHT)
		self:diffuse(0.1,0.1,0.1,0.4)
	end,
	BeginCommand= function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(MPinput)
	end
}
--vertical bar left of songwheel
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(SCREEN_WIDTH - capWideScale(get43size(350), 350), 0):halign(0):valign(0):zoomto(1, SCREEN_HEIGHT)
		self:diffuse(color("#ffffff")):diffusealpha(0.18) -- Seraphic: faint silver line instead of the bright bar
	end
}

return t
