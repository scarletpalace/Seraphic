local searchstring = ""
local frameX = 10
local frameY = 40
local frameWidth = SCREEN_WIDTH * 0.56
local frameHeight = 346 -- ends at the bottom bar
local offsetX = 10
local offsetY = 20 -- header band height
local innerWidth = frameWidth - offsetX * 2
local stateY = frameY + offsetY + 70 -- "Search Active" heading
local boxY = stateY + 14 -- query box top
local boxHeight = 30
local active = false
local whee
local lastsearchstring = ""
local instantSearch = themeConfig:get_data().global.InstantSearch
local IgnoreTabInput = themeConfig:get_data().global.IgnoreTabInput

local function searchInput(event)
	if event.type ~= "InputEventType_Release" and active == true then
		if event.button == "Back" then
			local tind = getTabIndex()
			searchstring = ""
			whee:SongSearch(searchstring)
			resetTabIndex(0)
			MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = 0})
			MESSAGEMAN:Broadcast("EndingSearch")
		elseif event.button == "Start" then
			local tind = getTabIndex()
			resetTabIndex(0)
			if not instantSearch then
				whee:SongSearch(searchstring)
			end
			MESSAGEMAN:Broadcast("EndingSearch")
			MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = 0})
		elseif event.DeviceInput.button == "DeviceButton_space" then -- add space to the string
			searchstring = searchstring .. " "
		elseif event.DeviceInput.button == "DeviceButton_backspace" then
			searchstring = searchstring:sub(1, -2) -- remove the last element of the string
		elseif event.DeviceInput.button == "DeviceButton_delete" then
			searchstring = ""
		else
			local CtrlPressed = INPUTFILTER:IsControlPressed()
			if event.DeviceInput.button == "DeviceButton_v" and CtrlPressed then
				searchstring = searchstring .. Arch.getClipboard()
			elseif
			--if not nil and (not a number or (ctrl pressed and not online))
				event.char and event.char:match('[%%%+%-%!%@%#%$%^%&%*%(%)%=%_%.%,%:%;%\'%"%>%<%?%/%~%|%w%[%]%{%}%`%\\]') and
					(not tonumber(event.char) or CtrlPressed or IgnoreTabInput > 1)
			 then
				searchstring = searchstring .. event.char
			end
		end
		if lastsearchstring ~= searchstring then
			MESSAGEMAN:Broadcast("UpdateString")
			if instantSearch then
				whee:SongSearch(searchstring)
			end
			lastsearchstring = searchstring
		end
	end
end

local translated_info = {
	Active = THEME:GetString("TabSearch", "Active"),
	Complete = THEME:GetString("TabSearch", "Complete"),
	ExplainStart = THEME:GetString("TabSearch", "ExplainStart"),
	ExplainBack = THEME:GetString("TabSearch", "ExplainBack"),
	ExplainDel = THEME:GetString("TabSearch", "ExplainDelete"),
	ExplainLimit = THEME:GetString("TabSearch", "ExplainLimitation"),
	ExplainNumInput = THEME:GetString("TabSearch", "ExplainNumInput"),
	ExplainSuperSearch = THEME:GetString("TabSearch","ExplainSuperSearch"),
}

local t = Def.ActorFrame {
	BeginCommand = function(self)
		self:visible(false)
		self:queuecommand("Set")
		whee = SCREENMAN:GetTopScreen():GetMusicWheel()
		SCREENMAN:GetTopScreen():AddInputCallback(searchInput)
	end,
	OffCommand = function(self)
		self:bouncebegin(0.2):xy(-500, 0):diffusealpha(0)
		self:sleep(0.04):queuecommand("Invis")
	end,
	InvisCommand= function(self)
		self:visible(false)
	end,
	OnCommand = function(self)
		self:bouncebegin(0.2):xy(0, 0):diffusealpha(1)
	end,
	SetCommand = function(self)
		self:finishtweening()
		if getTabIndex() == 3 then
			MESSAGEMAN:Broadcast("BeginningSearch")
			self:visible(true)
			self:queuecommand("On")
			active = true
			whee:Move(0)
			SCREENMAN:set_input_redirected(PLAYER_1, true)
			MESSAGEMAN:Broadcast("RefreshSearchResults")
		else
			self:queuecommand("Off")
			active = false
			SCREENMAN:set_input_redirected(PLAYER_1, false)
		end
	end,
	TabChangedMessageCommand = function(self)
		self:queuecommand("Set")
	end
}

-- window
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(frameX, frameY):zoomto(frameWidth, frameHeight):halign(0):valign(0):diffuse(getMainColor("tabs")):diffusetopedge(panelTopColor())
	end
}
t[#t + 1] = seraphicPanel(frameX, frameY, frameWidth, frameHeight, true)
t[#t + 1] = seraphicHeaderBand(frameX, frameY, frameWidth, offsetY)
t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameX + offsetX, frameY + offsetY / 2):zoom(0.45):halign(0)
		self:settext(seraphicHeading("Search"))
		self:diffuse(color(seraphicLabelColor))
	end
}

-- instructions (Start / Escape / Delete)
local function explainLine(i, key)
	local y = frameY + offsetY + 14 + (i - 1) * 15
	return Def.ActorFrame {
		seraphicBullet(frameX + offsetX + 4, y),
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(frameX + offsetX + 12, y):zoom(0.42):halign(0)
				self:maxwidth((innerWidth - 12) / 0.42)
				self:settext(translated_info[key])
				self:diffuse(color(seraphicLabelColor))
			end
		}
	}
end
t[#t + 1] = explainLine(1, "ExplainStart")
t[#t + 1] = explainLine(2, "ExplainBack")
t[#t + 1] = explainLine(3, "ExplainDel")

-- search state heading
t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameX + offsetX, stateY):zoom(0.55):halign(0):maxwidth(innerWidth / 0.55)
	end,
	SetCommand = function(self)
		if active then
			self:settextf("%s:", translated_info["Active"]:upper())
			self:diffuse(getGradeColor("Grade_Tier10"))
		elseif not active and searchstring ~= "" then
			self:settext(translated_info["Complete"]:upper())
			self:diffuse(getGradeColor("Grade_Tier04"))
		else
			self:settext("")
		end
	end,
	UpdateStringMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	SetSearchStringMessageCommand = function(self, params)
		if params.searchstring then
			searchstring = params.searchstring
			lastsearchstring = searchstring --i dont like this
			MESSAGEMAN:Broadcast("UpdateString")
		end
	end
}

-- query box: dark band with a faint edge
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(frameX + offsetX, boxY):zoomto(innerWidth, boxHeight):halign(0):valign(0)
		self:diffuse(color("#000000")):diffusealpha(0.6)
	end
}
t[#t + 1] = seraphicSoftEdge(frameX + offsetX, boxY, innerWidth, boxHeight, 0.15)
t[#t + 1] = LoadFont("Common Large") .. {
	InitCommand = function(self)
		self:xy(frameX + offsetX + 8, boxY + boxHeight / 2):zoom(0.34):halign(0)
		self:maxwidth((innerWidth - 16) / 0.34)
		self:diffuse(color(seraphicValueColor))
	end,
	SetCommand = function(self)
		self:settext(searchstring)
	end,
	UpdateStringMessageCommand = function(self)
		self:queuecommand("Set")
	end
}

-- help notes
local notesY = boxY + boxHeight + 16
t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameX + offsetX, notesY):zoom(0.38):align(0, 0)
		self:maxwidth(innerWidth / 0.38)
		self:settext(translated_info["ExplainLimit"])
		self:diffuse(color(seraphicLabelColor))
	end
}
t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameX + offsetX, notesY + 16):zoom(0.38):align(0, 0)
		self:maxwidth(innerWidth / 0.38)
		self:settext(translated_info["ExplainNumInput"])
		self:diffuse(color(seraphicLabelColor))
	end
}
t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameX + offsetX, notesY + 46):zoom(0.38):align(0, 0)
		self:maxwidth(innerWidth / 0.38)
		self:settext(translated_info["ExplainSuperSearch"])
		self:diffuse(color(seraphicLabelColor))
	end
}

return t
