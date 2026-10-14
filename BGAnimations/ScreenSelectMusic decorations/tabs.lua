local active = true
local numericinputactive = false
local whee

local function IgnoreTabInputs()
	local IgnoreTabInput = themeConfig:get_data().global.IgnoreTabInput
	if IgnoreTabInput == 3 then
		return true
	elseif IgnoreTabInput == 2 and getTabIndex() == 3 then
		return true
	else
		return false
	end
end

local tabNames = {"General", "MSD", "Scores", "Search", "Profile", "Filters", "Goals", "Playlists", "Packs", "Tags"} -- this probably should be in tabmanager.

local function input(event)
	if event.type ~= "InputEventType_Release" and active then
		if numericinputactive == false then
			if
				not (INPUTFILTER:IsBeingPressed("left ctrl") or INPUTFILTER:IsBeingPressed("right ctrl") or
					(SCREENMAN:GetTopScreen():GetName() ~= "ScreenSelectMusic" and
					 SCREENMAN:GetTopScreen():GetName() ~= "ScreenNetSelectMusic"))
			 then
				if event.DeviceInput.button == "DeviceButton_0" then
					local tind = getTabIndex()
					-- if on the search tab dont let them press 0 if currently holding shift...
					-- prevents attempting to enter ')' causing page change
					-- (HACK) (HACK) (HACK) (HACK) (HACK) (HACK) (HACK) (HACK) (HACK) (HACK)
					if tind == 3 and (INPUTFILTER:IsBeingPressed("left shift") or INPUTFILTER:IsBeingPressed("right shift")) then
						return false
					end

					if not IgnoreTabInputs() then
						setTabIndex(9)
						MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = 9})
					end
				else
					for i = 1, #tabNames do
						local numpad = event.DeviceInput.button == "DeviceButton_KP "..event.char	-- explicitly ignore numpad inputs for tab swapping (doesn't care about numlock) -mina
						if not numpad and event.char and tonumber(event.char) and tonumber(event.char) == i and not IgnoreTabInputs() then
							local tind = getTabIndex()
							setTabIndex(i - 1)
							MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = i-1})
						end
					end
				end
			end
		end
	end
	return false
end
local t =
	Def.ActorFrame {
	BeginCommand = function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(MPinput)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
		resetTabIndex()
	end,
	NumericInputActiveMessageCommand = function(self)
		numericinputactive = true
	end,
	NumericInputEndedMessageCommand = function(self)
		numericinputactive = false
	end,
	ReloadedScriptsMessageCommand = function(self)
		MESSAGEMAN:Broadcast("TabChanged", {from = 1, to = 1})
	end,
}

local frameWidth = 38 -- tab pitch; feathers overlap slightly like in the LR2 skin
local frameX = 44 -- shifted a bit to the right (clears the bottom-left crystal)
local frameY = SCREEN_HEIGHT - 86

-- Seraphic: big feather tabs (LR2 "option / score / effects" style) with slanted labels.
-- feather art is 40x64 (cell units); the label runs along its left edge at ~57 degrees
local featherH = 80
local featherW = featherH * 40 / 64
local fk = featherH / 64
local featherBottom = 84 -- feather sits in the bottom bar, its tip reaching above the bar line -- feather bottom edge, relative to frameY
local labelAngle = -57
local labelX = (15 - 20) * fk
local labelY = featherBottom + (34.5 - 64) * fk
local labelZoom = 0.46
local labelMaxLen = 44 * fk

-- idle feathers are silver-white, the selected one lights up in AliceBlue
local selectedColor = "#F0F8FF"
-- (unused) per-tab feather colours (blue/yellow/red/orange/green/purple like the LR2 tab feathers, then 4 extras)
local featherColors = {"#4d7dff", "#f2e04a", "#ff4a4a", "#ff8a2a", "#3ad65a", "#9a6bff", "#4dd8ff", "#ff6bd0", "#b8e84a", "#ffffff"}

local function tabs(index)
	local t = Def.ActorFrame {
		Name = "Tab" .. index,
		InitCommand = function(self)
			self:xy(frameX + ((index - 1) * frameWidth), frameY)
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
		end,
		SetCommand = function(self)
			self:finishtweening()
			self:smooth(0.1)
			local feather = self:GetChild("Feather")
			local glow = self:GetChild("FeatherGlow")
			if getTabIndex() == index - 1 then
				-- selected: lit up in its colour, lifted a little, with a soft glow
				self:diffusealpha(1):y(frameY - 6)
				feather:diffuse(color(selectedColor)):diffusealpha(1)
				glow:diffuse(color(selectedColor)):diffusealpha(0.6)
			else
				self:diffusealpha(1):y(frameY)
				feather:diffuse(color("#dcdce8")):diffusealpha(0.88)
				glow:diffusealpha(0)
			end
		end,
		TabChangedMessageCommand = function(self, params)
			self:queuecommand("Set")
			if SeraphicFx.tabAnim and params and params.to == index - 1 and params.from ~= params.to then
				self:queuecommand("Flutter")
			end
		end,
		-- the feather of the newly selected tab swings like a wing and flashes
		FlutterCommand = SeraphicFx.tabAnim and function(self)
			local feather = self:GetChild("Feather")
			local glow = self:GetChild("FeatherGlow")
			feather:stoptweening():rotationz(-8):smooth(0.09):rotationz(5):smooth(0.09):rotationz(-3):smooth(0.1):rotationz(0)
			glow:stoptweening():diffusealpha(1):smooth(0.55):diffusealpha(0.6)
		end or nil
	}

	-- invisible hit area covering the whole feather
	t[#t + 1] = UIElements.QuadButton(1, 1) .. {
		Name = "TabBG",
		InitCommand = function(self)
			self:xy(0, featherBottom):valign(1):zoomto(frameWidth, featherH):diffusealpha(0)
		end,
		MouseOverCommand = SeraphicFx.tabAnim and function(self)
			if getTabIndex() ~= index - 1 then
				local p = self:GetParent()
				p:GetChild("Feather"):stoptweening():smooth(0.1):diffuse(color("#ffffff")):diffusealpha(1)
				p:GetChild("FeatherGlow"):stoptweening():smooth(0.1):diffuse(color(selectedColor)):diffusealpha(0.25)
			end
		end or nil,
		MouseOutCommand = SeraphicFx.tabAnim and function(self)
			if getTabIndex() ~= index - 1 then
				local p = self:GetParent()
				p:GetChild("Feather"):stoptweening():smooth(0.1):diffuse(color("#dcdce8")):diffusealpha(0.88)
				p:GetChild("FeatherGlow"):stoptweening():smooth(0.1):diffusealpha(0)
			end
		end or nil,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				local tind = getTabIndex()
				setTabIndex(index - 1)
				MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = index - 1})
			end
		end
	}

	-- soft additive glow (only visible on the selected tab)
	t[#t + 1] = Def.Sprite {
		Name = "FeatherGlow",
		Texture = THEME:GetPathG("", "seraphic_tab_feather"),
		InitCommand = function(self)
			self:xy(0, featherBottom + 2):valign(1):zoomto(featherW * 1.18, featherH * 1.08):diffusealpha(0)
			self:blend("BlendMode_Add")
		end
	}

	t[#t + 1] = Def.Sprite {
		Name = "Feather",
		Texture = THEME:GetPathG("", "seraphic_tab_feather"),
		InitCommand = function(self)
			self:xy(0, featherBottom):valign(1):zoomto(featherW, featherH):diffuse(color("#dcdce8")):diffusealpha(0.88)
		end
	}

	-- slanted label running along the feather: white text with a black outline (4 offset copies), like the LR2 skin
	local outline = {{-0.7, 0}, {0.7, 0}, {0, -0.7}, {0, 0.7}}
	local function label(name, ox, oy, main)
		return LoadFont("TextBanner text") .. {
			Name = name,
			InitCommand = function(self)
				self:xy(labelX, labelY):rotationz(labelAngle):zoom(labelZoom * 1.08):maxwidth(labelMaxLen / (labelZoom * 1.08))
				if not main then
					-- offsets are in screen space, so rotate them with the text
					local a = math.rad(-labelAngle)
					self:addx(ox * math.cos(a) - oy * math.sin(a)):addy(ox * math.sin(a) + oy * math.cos(a))
				end
				self:diffuse(main and color("#ffffff") or color("#000000"))
			end,
			BeginCommand = function(self)
				self:queuecommand("Set")
			end,
			SetCommand = function(self)
				self:settext(THEME:GetString("TabNames", tabNames[index]))
				local en = isTabEnabled(index)
				if main then
					if en then
						if index == 6 and FILTERMAN:AnyActiveFilter() then
							self:diffuse(color("#ff5a5a"))
						else
							self:diffuse(color("#ffffff"))
						end
					else
						self:diffuse(color("#777777"))
					end
				else
					self:diffuse(color("#000000")):diffusealpha(en and 0.95 or 0.5)
				end
			end
		}
	end
	for _, o in ipairs(outline) do
		t[#t + 1] = label("TabTextOutline", o[1], o[2], false)
	end
	t[#t + 1] = label("TabText", 0, 0, true)
	return t
end

--Make tabs
for i = 1, #tabNames do
	t[#t + 1] = tabs(i)
end

return t
