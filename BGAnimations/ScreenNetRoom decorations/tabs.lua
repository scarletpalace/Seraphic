local active = true

local CtrlPressed = false
local function input(event)
	if event.type ~= "InputEventType_Release" and active then
		for i = 1, (NSMAN:IsETTP() and 2 or 3) do
			if event.DeviceInput.button == "DeviceButton_" .. i and CtrlPressed == true then
				local tind = getTabIndex()
				setTabIndex(i - 1)
				MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = i-1})
			end
		end
	end
	if event.DeviceInput.button == "DeviceButton_left ctrl" then
		if event.type == "InputEventType_Release" then
			CtrlPressed = false
		else
			CtrlPressed = true
		end
	end
	if event.DeviceInput.button == "DeviceButton_right ctrl" then
		if event.type == "InputEventType_Release" then
			CtrlPressed = false
		else
			CtrlPressed = true
		end
	end
	return false
end

local t = Def.ActorFrame {
	OnCommand = function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	BeginCommand = function(self)
		resetTabIndex()
	end,
	PlayerJoinedMessageCommand = function(self)
		resetTabIndex()
	end,
	BeginningSearchMessageCommand = function(self)
		active = true
	end,
	EndingSearchMessageCommand = function(self)
		active = true
	end,
	ReloadedScriptsMessageCommand = function(self)
		MESSAGEMAN:Broadcast("TabChanged", {from = 1, to = 1})
	end,
}

-- Just for debug
--[[
t[#t+1] = LoadFont("Common Normal") .. {
	InitCommand=function(self)
		self:xy(300,300):halign(0):zoom(2):diffuse(getMainColor(2))
	end;
	BeginCommand=function(self)
		self:queuecommand("Set")
	end;
	SetCommand=function(self)
		self:settext(getTabIndex())
	end;
	CodeMessageCommand=function(self)
		self:queuecommand("Set")
	end;
};
--]]
--======================================================================================

local tabNames
if NSMAN:IsETTP() then
	tabNames = {"Search", "Profile"}
else
	tabNames = {"Chatbox", "Search", "Profile"}
end

-- Seraphic: LR2 toggles (dark glass, soft edge, crimson when selected) under the room search window
local frameWidth = 104
local frameX = 12 + frameWidth / 2
local frameY = 386 -- under the room search window, above the bottom bar (it starts at y 408)

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
			local bg = self:GetChild("TabBG")
			if getTabIndex() == index - 1 then
				bg:diffuse(color("#9c1428")):diffusealpha(0.45)
				self:GetChild("TabText"):diffuse(color(seraphicValueColor))
			else
				bg:diffuse(color("#000000")):diffusealpha(0.5)
				self:GetChild("TabText"):diffuse(color(isTabEnabled(index) and seraphicLabelColor or "#666666"))
			end
		end,
		TabChangedMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		PlayerJoinedMessageCommand = function(self)
			self:queuecommand("Set")
		end
	}

	t[#t + 1] = UIElements.QuadButton(1, 1) .. {
		Name = "TabBG",
		InitCommand = function(self)
			self:zoomto(frameWidth - 6, 18):diffuse(color("#000000")):diffusealpha(0.5)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				local tind = getTabIndex()
				setTabIndex(index - 1)
				MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = index-1})
			end
		end
	}

	t[#t + 1] = seraphicSoftEdge(-(frameWidth - 6) / 2, -9, frameWidth - 6, 18, 0.2)
	t[#t + 1] = LoadFont("Common Normal") .. {
		Name = "TabText",
		InitCommand = function(self)
			self:zoom(0.48):maxwidth((frameWidth - 14) / 0.48):diffuse(color(seraphicLabelColor))
		end,
		BeginCommand = function(self)
			self:settext(THEME:GetString("TabNames", tabNames[index]):upper())
		end,
		PlayerJoinedMessageCommand = function(self)
			self:queuecommand("Set")
		end
	}
	return t
end

--Make tabs
for i = 1, #tabNames do
	t[#t + 1] = tabs(i)
end

return t
