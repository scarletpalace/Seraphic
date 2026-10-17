if SeraphicStamp then SeraphicStamp("overlay start") end
local showVisualizer = themeConfig:get_data().global.ShowVisualizer

local function input(event)
	-- mouse click events left here to let anything in selectmusic react to them
	if event.DeviceInput.button == "DeviceButton_left mouse button" then 
		if event.type == "InputEventType_Release" then
			MESSAGEMAN:Broadcast("MouseLeftClick")
			MESSAGEMAN:Broadcast("MouseUp", {event = event})
		elseif event.type == "InputEventType_FirstPress" then
			MESSAGEMAN:Broadcast("MouseDown", {event = event})
		end
	elseif event.DeviceInput.button == "DeviceButton_right mouse button" then
		if event.type == "InputEventType_Release" then
			MESSAGEMAN:Broadcast("MouseRightClick")
			MESSAGEMAN:Broadcast("MouseUp", {event = event})
		elseif event.type == "InputEventType_FirstPress" then
			MESSAGEMAN:Broadcast("MouseDown", {event = event})
		end
	end
	return false
end

local hoverAlpha = 0.6

local t = Def.ActorFrame {
	BeginCommand = function(self)
		local s = SCREENMAN:GetTopScreen()
		s:AddInputCallback(input)
		setenv("NewOptions","Main")
	end
}

t[#t + 1] = Def.Actor {InitCommand = function() if SeraphicStamp then SeraphicStamp("overlay built start") end end}
t[#t + 1] = Def.Actor {
	CodeMessageCommand = function(self, params)
		if params.Name == "AvatarShow" and getTabIndex() == 0 and not SCREENMAN:get_input_redirected(PLAYER_1) then
			SCREENMAN:SetNewScreen("ScreenAssetSettings")
		end
	end,
	OnCommand = function(self)
		inScreenSelectMusic = true
	end,
	EndCommand = function(self)
		inScreenSelectMusic = nil
	end,
}

t[#t + 1] = LoadActor("../_frame")
t[#t + 1] = Def.Actor {InitCommand = function() if SeraphicStamp then SeraphicStamp("overlay built ../_frame") end end}
t[#t + 1] = LoadActor("../_PlayerInfo")
t[#t + 1] = Def.Actor {InitCommand = function() if SeraphicStamp then SeraphicStamp("overlay built ../_PlayerInfo") end end}
t[#t + 1] = LoadActor("../_scorepanel")
t[#t + 1] = Def.Actor {InitCommand = function() if SeraphicStamp then SeraphicStamp("overlay built ../_scorepanel") end end}
-- feather tabs must be drawn above the bottom bar, so they live in the overlay
t[#t + 1] = LoadActor("../ScreenSelectMusic decorations/tabs")
t[#t + 1] = Def.Actor {InitCommand = function() if SeraphicStamp then SeraphicStamp("overlay built ../ScreenSelectMusic decorations/tabs") end end}

if false and showVisualizer then -- (hidden on the select screen: its bar showed up in the top bar)
	local vis = audioVisualizer:new {
		x = 175,
		y = 35,
		maxHeight = 30,
		freqIntervals = audioVisualizer.multiplyIntervals(audioVisualizer.defaultIntervals, 5),
		color = getMainColor("positive"),
		onBarUpdate = function(self)
			--[
			self:diffusetopedge(getMainColor("frames"))
			self:diffusebottomedge(getMainColor("positive"))
			--]]
			--[[
			self:diffuselowerleft()
			self:diffuseupperleft()
			self:diffuselowerright()
			self:diffuseupperright()
			--]]
		end
	}
	t[#t + 1] = vis
end


t[#t + 1] = LoadActor("currentsort")
t[#t + 1] = Def.Actor {InitCommand = function() if SeraphicStamp then SeraphicStamp("overlay built currentsort") end end}
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_title"),
	InitCommand = function(self)
		self:xy(30, 8):halign(0):valign(0):zoom(1.0)
	end,
	-- the tab panels (profile, msd, ...) open over this area, so the logo steps aside while one is open
	TabChangedMessageCommand = function(self, params)
		self:visible(((params and params.to) or getTabIndex()) == 0)
	end,
	ChartPreviewOnMessageCommand = function(self) self:visible(false) end,
	ChartPreviewOffMessageCommand = function(self) self:visible(getTabIndex() == 0) end
}
t[#t + 1] = UIElements.TextToolTip(1, 1, "Common Large") .. {
	Name="rando",
	InitCommand = function(self)
		self:xy(30, 60):halign(0):valign(1):zoom(0.9):diffuse(getMainColor("positive")):diffusealpha(0)
		self:settextf("%s:", THEME:GetString("ScreenSelectMusic", "Title"))
		self.randex = 0
		self.randlist = {}
	end,
	MouseOverCommand = function(self) end,
	MouseOutCommand = function(self) end,
	MouseDownCommand = function(self, params)
		local w = SCREENMAN:GetTopScreen():GetMusicWheel()

		local function newrandsong()
			local t = w:GetSongs()
			if #t == 0 then return nil end
			local random_song = t[math.random(#t)]
			return random_song
		end

		if params.event == "DeviceButton_left mouse button" then
			
			if INPUTFILTER:IsShiftPressed() then
				self.randex = self.randex - 1
				if self.randex < 1 then
					self.randex = 1
					table.insert(self.randlist, 1, newrandsong())
				end
				local randsong = self.randlist[self.randex]

				-- if the last random song wasnt filtered out, we can select it
				-- so end early after jumping to it
				if w:SelectSong(randsong) then
					return
				end
				-- otherwise, just pick a new random song
			end

			self.randex = self.randex + 1
			if self.randex > #self.randlist then
				self.randex = #self.randlist + 1
				table.insert(self.randlist, newrandsong())
			end
			local randsong = self.randlist[self.randex]
			w:SelectSong(randsong)
		end
	end
}

t[#t + 1] = LoadActor("../_cursor")
t[#t + 1] = Def.Actor {InitCommand = function() if SeraphicStamp then SeraphicStamp("overlay built ../_cursor") end end}
t[#t + 1] = LoadActor("../_halppls")
t[#t + 1] = Def.Actor {InitCommand = function() if SeraphicStamp then SeraphicStamp("overlay built ../_halppls") end end}

updateNowPlaying()

t[#t + 1] = Def.Actor {InitCommand = function() if SeraphicStamp then SeraphicStamp("overlay init done") end end}
return t
