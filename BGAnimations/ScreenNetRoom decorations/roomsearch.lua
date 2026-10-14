local searchstring = ""
local englishes = {
	"?",
	"-",
	".",
	",",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"0",
	"a",
	"b",
	"c",
	"d",
	"e",
	"f",
	"g",
	"h",
	"i",
	"j",
	"k",
	"l",
	"m",
	"n",
	"o",
	"p",
	"q",
	"r",
	"s",
	"t",
	"u",
	"v",
	"w",
	"x",
	"y",
	"z",
	";"
}
local frameX = 10
local frameY = 300
local active = false
local whee
local searchtitle = ""
local searchdesc = ""
local searchingame = true
local searchpassword = true
local searchopen = true
local inputchar = ""
local backspace = false
local changed = false
local inputting = 0
local CtrlPressed = false

local offsetX = -10
local offsetY = 20
local frameWidth = 400
local frameHeight = 350

local function searchInput(event)
	if event.type ~= "InputEventType_Release" and active then
		if event.DeviceInput.button == "DeviceButton_left mouse button" then
			inputting = 0
			MESSAGEMAN:Broadcast("UpdateString")
		elseif event.DeviceInput.button == "DeviceButton_right mouse button" then
			inputting = 0
			MESSAGEMAN:Broadcast("UpdateString")
		end
	end
	if event.type ~= "InputEventType_Release" and active == true and inputting ~= 0 then
		if event.button == "Back" then
			searchtitle = ""
			searchdesc = ""
			searchingame = true
			searchpassword = true
			searchopen = true
			whee:Search(searchtitle, searchdesc, searchingame, searchpassword, searchopen)
			whee:StopSearch()
			local tind = getTabIndex()
			resetTabIndex(0)
			MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = 0})
			MESSAGEMAN:Broadcast("EndingSearch")
		elseif event.button == "Start" then
			inputting = 0
			MESSAGEMAN:Broadcast("UpdateString")
		elseif event.DeviceInput.button == "DeviceButton_space" then -- add space to the string
			inputchar = " " -- remove the last element of the string
		elseif event.DeviceInput.button == "DeviceButton_delete" then
			inputchar = ""
		elseif event.DeviceInput.button == "DeviceButton_=" then
			inputchar = "="
		elseif event.DeviceInput.button == "DeviceButton_backspace" then
			backspace = true
			inputchar = searchstring:sub(1, -2)
		elseif event.DeviceInput.button == "DeviceButton_v" and CtrlPressed then
			inputchar = Arch.getClipboard()
		else
			for i = 1, #englishes do -- add standard characters to string
				if event.DeviceInput.button == "DeviceButton_" .. englishes[i] then
					inputchar = englishes[i]
				end
			end
		end
		if inputting == 1 then
			if backspace then
				backspace = false
				searchtitle = searchtitle:sub(1, -2)
			else
				searchtitle = searchtitle .. inputchar
				inputchar = ""
			end
			changed = true
		elseif inputting == 2 then
			if backspace then
				backspace = false
				searchdesc = searchdesc:sub(1, -2)
			else
				searchdesc = searchdesc .. inputchar
				inputchar = ""
			end
			changed = true
		end
		if changed == true then
			changed = false
			MESSAGEMAN:Broadcast("UpdateString")
			whee:Search(searchtitle, searchdesc, searchingame, searchpassword, searchopen)
		end
	end
	if event.DeviceInput.button == "DeviceButton_right ctrl" or event.DeviceInput.button == "DeviceButton_left ctrl" then
		if event.type == "InputEventType_Release" then
			CtrlPressed = false
		else
			CtrlPressed = true
		end
	end
end

local translated_info = {
	Title = THEME:GetString("TabSearch", "RoomTitle"),
	Subtitle = THEME:GetString("TabSearch", "RoomSubtitle"),
	Opened = THEME:GetString("TabSearch", "RoomOpened"),
	Passworded = THEME:GetString("TabSearch", "RoomPassworded"),
	InGameplay = THEME:GetString("TabSearch", "RoomInGameplay"),
	TabTitle = THEME:GetString("TabSearch", "Title"),
	Explanation = THEME:GetString("TabSearch", "ExplainLimitation")
}

local function ButtonActive(self)
	return isOver(self) and update
end

local t = Def.ActorFrame {
	InitCommand = function(self)
		self:zoom(0.9)
	end,
	BeginCommand = function(self)
		whee = SCREENMAN:GetTopScreen():GetMusicWheel()
		SCREENMAN:GetTopScreen():AddInputCallback(searchInput)
		self:finishtweening()
		if NSMAN:IsETTP() then
			self:visible(true)
			active = true
			whee:Move(0)
			MESSAGEMAN:Broadcast("BeginningSearch")
			MESSAGEMAN:Broadcast("RefreshSearchResults")
		else
			self:visible(false)
		end
		self:queuecommand("Set")
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
		if getTabIndex() == (NSMAN:IsETTP() and 0 or 1) then
			MESSAGEMAN:Broadcast("BeginningSearch")
			self:visible(true)
			self:queuecommand("On")
			active = true
			whee:Move(0)
			MESSAGEMAN:Broadcast("RefreshSearchResults")
		else
			self:queuecommand("Off")
			active = false
		end
	end,
	TabChangedMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	-- Seraphic: LR2 window: dark glass body, header band with "::ROOM SEARCH", text fields and toggle rows
	Def.Quad {
		InitCommand = function(self)
			self:xy(frameX, 45):zoomto(frameWidth, frameHeight):halign(0):valign(0)
			self:diffuseupperleft(color("#262626")):diffuseupperright(color("#1a1a1a"))
			self:diffuselowerleft(color("#0a0a0a")):diffuselowerright(color("#060606"))
			self:diffusealpha(0.8)
		end
	},
	seraphicPanel(frameX, 45, frameWidth, frameHeight, true),
	seraphicHeaderBand(frameX, 45, frameWidth, offsetY),
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(frameX + 10, 45 + offsetY / 2):zoom(0.5):halign(0)
			self:settext(seraphicHeading(translated_info["TabTitle"])):diffuse(color(seraphicLabelColor))
		end
	},
}

-- text field: label on the left, dark input box on the right (crimson tint while typing in it)
local function field(index, label, y, getText)
	local fx, fw, fh = frameX + 110, frameWidth - 130, 24
	t[#t + 1] = LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(frameX + 22, y):zoom(0.55):halign(0):diffuse(color(seraphicLabelColor))
			self:settext(tostring(label):upper())
		end
	}
	t[#t + 1] = UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(fx, y):halign(0):zoomto(fw, fh)
		end,
		SetCommand = function(self)
			if inputting == index then
				self:diffuse(color("#9c1428")):diffusealpha(0.4)
			else
				self:diffuse(color("#000000")):diffusealpha(0.5)
			end
		end,
		UpdateStringMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and active then
				inputting = index
				MESSAGEMAN:Broadcast("UpdateString")
			end
		end
	}
	t[#t + 1] = seraphicSoftEdge(fx, y - fh / 2, fw, fh, 0.16)
	t[#t + 1] = LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(fx + 8, y):zoom(0.55):halign(0):maxwidth((fw - 16) / 0.55):diffuse(color(seraphicValueColor))
		end,
		SetCommand = function(self)
			self:settext(getText())
		end,
		UpdateStringMessageCommand = function(self)
			self:queuecommand("Set")
		end
	}
end
field(1, translated_info["Title"], 100, function() return searchtitle end)
field(2, translated_info["Subtitle"], 138, function() return searchdesc end)

-- filter rows: banded row, label on the left, a diamond that is crimson when the filter is on
t[#t + 1] = seraphicHeaderBand(frameX + 12, 172, frameWidth - 24, 16)
t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameX + 20, 180):zoom(0.42):halign(0):diffuse(color(seraphicLabelColor)):settext(seraphicHeading("Show rooms"))
	end
}
local function toggleRow(i, label, get, flip)
	local y = 196 + (i - 1) * 30
	local rx, rw, rh = frameX + 12, frameWidth - 24, 26
	t[#t + 1] = seraphicRowBand(rx, y, rw, rh, i)
	t[#t + 1] = UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(rx, y):halign(0):valign(0):zoomto(rw, rh):diffusealpha(0)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and active then
				flip()
				MESSAGEMAN:Broadcast("UpdateString")
				whee:Search(searchtitle, searchdesc, searchingame, searchpassword, searchopen)
			end
		end
	}
	t[#t + 1] = LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(rx + 12, y + rh / 2):zoom(0.55):halign(0):diffuse(color(seraphicValueColor)):settext(tostring(label):upper())
		end
	}
	t[#t + 1] = LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(rx + rw - 30, y + rh / 2):zoom(0.45):halign(1)
		end,
		SetCommand = function(self)
			self:settext(get() and "SHOWN" or "HIDDEN"):diffuse(color(get() and seraphicValueColor or "#7a7275"))
		end,
		UpdateStringMessageCommand = function(self)
			self:queuecommand("Set")
		end
	}
	t[#t + 1] = Def.Quad {
		InitCommand = function(self)
			self:xy(rx + rw - 16, y + rh / 2):rotationz(45):zoomto(8, 8)
		end,
		SetCommand = function(self)
			if get() then
				self:diffuse(color("#9c1428")):diffusealpha(1)
			else
				self:diffuse(color("#000000")):diffusealpha(0.6)
			end
		end,
		UpdateStringMessageCommand = function(self)
			self:queuecommand("Set")
		end
	}
	t[#t + 1] = Def.Quad {
		InitCommand = function(self)
			self:xy(rx + rw - 16, y + rh / 2):rotationz(45):zoomto(10, 10):diffuse(color("#e8b8c2")):diffusealpha(0.35)
		end
	}
end
toggleRow(1, translated_info["Opened"], function() return searchopen end, function() searchopen = not searchopen end)
toggleRow(2, translated_info["Passworded"], function() return searchpassword end, function() searchpassword = not searchpassword end)
toggleRow(3, translated_info["InGameplay"], function() return searchingame end, function() searchingame = not searchingame end)

t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameX + 22, 45 + frameHeight - 24):zoom(0.42):halign(0):maxwidth((frameWidth - 44) / 0.42)
		self:diffuse(color(seraphicLabelColor)):settext(translated_info["Explanation"])
	end,
}

return t
