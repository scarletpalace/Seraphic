-- Seraphic: player options over the sanctuary, rows in an LR2 window right of the noteskin sidebar
-- (the shared options window, placed past the sidebar; the explanation sits at ExplanationP1Y)
local t = Def.ActorFrame {}

t[#t + 1] = LoadActor("ScreenOptions underlay", {x = 156, w = 566, explMetric = "ExplanationP1Y", noHeader = true})

if SameColor(getMainColor("positive"),color("#9654FD")) then
	t[#t + 1] =
		LoadActor(THEME:GetPathG("", "_OptionsSidebar")) ..
		{
			OnCommand = function(self)
				self:zoomto(152, SCREEN_HEIGHT):align(0,0)
			end
		}
else
	t[#t + 1] =
		LoadActor(THEME:GetPathG("", "_OptionsGreySidebar")) ..
		{
			OnCommand = function(self)
				self:zoomto(152, SCREEN_HEIGHT):align(0,0)
				self:diffuse(ColorMultiplier(getMainColor("positive"),1.5))
			end
		}
	t[#t + 1] =
		LoadActor(THEME:GetPathG("", "_OptionsGreySidebar")) ..
		{
			OnCommand = function(self)
				self:zoomto(152, SCREEN_HEIGHT):align(0,0)
				self:diffuse(ColorMultiplier(getMainColor("positive"),0.75))
				self:diffusealpha(0.2):blend(Blend.Add)
			end
		}
end

return t
