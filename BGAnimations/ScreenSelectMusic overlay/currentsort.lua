
local hoverAlpha = 0.6

local t = Def.ActorFrame {}

-- Seraphic: the current pack sits in a frame under the clock, top-right
local boxW, boxH = 290, 29
local boxX, boxY = SCREEN_WIDTH - 60 - boxW, 50

local sortTable = {
	SortOrder_Group = THEME:GetString("SortOrder", "Group"),
	SortOrder_Title = THEME:GetString("SortOrder", "Title"),
	SortOrder_BPM = THEME:GetString("SortOrder", "BPM"),
	SortOrder_TopGrades = THEME:GetString("SortOrder", "TopGrades"),
	SortOrder_Artist = THEME:GetString("SortOrder", "Artist"),
	SortOrder_Genre = THEME:GetString("SortOrder", "Genre"),
	SortOrder_ModeMenu = THEME:GetString("SortOrder", "ModeMenu"),
	SortOrder_Length = THEME:GetString("SortOrder", "Length"),
	SortOrder_DateAdded = THEME:GetString("SortOrder", "DateAdded"),
	SortOrder_Favorites = THEME:GetString("SortOrder", "Favorites"),
	SortOrder_Overall = THEME:GetString("SortOrder", "Overall"),
	SortOrder_Stream = THEME:GetString("SortOrder", "Stream"),
	SortOrder_Jumpstream = THEME:GetString("SortOrder", "Jumpstream"),
	SortOrder_Handstream = THEME:GetString("SortOrder", "Handstream"),
	SortOrder_Stamina = THEME:GetString("SortOrder", "Stamina"),
	SortOrder_JackSpeed = THEME:GetString("SortOrder", "JackSpeed"),
	SortOrder_Chordjack = THEME:GetString("SortOrder", "Chordjack"),
	SortOrder_Technical = THEME:GetString("SortOrder", "Technical"),
	SortOrder_Author = THEME:GetString("SortOrder", "Author"),
	SortOrder_Ungrouped = THEME:GetString("SortOrder", "Ungrouped")
}

local translated_info = {
	Sort = THEME:GetString("SortOrder", "SortWord")
}

-- sort selector between the clock and the pack box: "Sort: Group". Clicking it drops down a table of every sort
-- (two columns); click one to switch to it, click the box again or anywhere else to close the table.
-- Group keeps the packs; the other sorts regroup every song (by title letter, MSD range, BPM range, ...).
local sortList = {
	"SortOrder_Group", "SortOrder_Title", "SortOrder_Artist", "SortOrder_Author", "SortOrder_Genre",
	"SortOrder_BPM", "SortOrder_Length", "SortOrder_DateAdded", "SortOrder_TopGrades", "SortOrder_Favorites",
	"SortOrder_Overall", "SortOrder_Stream", "SortOrder_Jumpstream", "SortOrder_Handstream", "SortOrder_Stamina",
	"SortOrder_JackSpeed", "SortOrder_Chordjack", "SortOrder_Technical", "SortOrder_Ungrouped"
}
local selW, selH = 210, 15
local selX, selY = boxX + (boxW - selW) / 2, 31
-- the table: under the selector, as wide as the pack box, drawn over everything (high z wins the clicks)
local cols, cellH = 2, 15
local rowsN = math.ceil(#sortList / cols)
local tblX, tblY, tblW = boxX, selY + selH + 2, boxW
local cellW = tblW / cols
local tblZ = 20
local dropdown -- the table's ActorFrame

local function setOpen(open)
	if dropdown then
		dropdown:visible(open)
		dropdown:playcommand("Refresh")
	end
end

local function chooseSort(so)
	setOpen(false)
	if so == GAMESTATE:GetSortOrder() then return end
	local top = SCREENMAN:GetTopScreen()
	local w = top and top.GetMusicWheel and top:GetMusicWheel()
	if not w then return end
	local ok, changed = pcall(function() return w:ChangeSort(so) end)
	if ok and changed then
		SOUND:PlayOnce(THEME:GetPathS("MusicWheel", "change"))
	end
end

t[#t + 1] = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(selX, selY)
	end,
	Def.Sprite {
		Texture = THEME:GetPathG("", "seraphic_packbar"),
		InitCommand = function(self)
			self:halign(0):valign(0):zoomto(selW, selH):diffusealpha(0.85)
		end
	},
	LoadFont("Common Normal") .. {
		Name = "Text",
		InitCommand = function(self)
			self:xy(selW / 2, selH / 2):zoom(0.34):maxwidth((selW - 40) / 0.34):diffuse(color(seraphicValueColor))
		end,
		BeginCommand = function(self)
			self:playcommand("Set")
		end,
		SetCommand = function(self)
			local sort = GAMESTATE:GetSortOrder()
			self:settextf("%s: %s", translated_info["Sort"], sort and sortTable[sort] or "")
		end,
		SortOrderChangedMessageCommand = function(self)
			self:queuecommand("Set")
		end
	},
	-- small "v" on the right: this box opens a list
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(selW - 12, selH / 2):zoom(0.34):settext("v"):diffuse(color(seraphicLabelColor))
		end
	},
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:halign(0):valign(0):zoomto(selW, selH):diffusealpha(0)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				setOpen(not dropdown:GetVisible())
			end
		end,
		MouseOverCommand = function(self)
			self:GetParent():GetChild("Text"):diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:GetParent():GetChild("Text"):diffusealpha(1)
		end
	}
}

local tbl = Def.ActorFrame {
	InitCommand = function(self)
		dropdown = self
		self:visible(false)
	end,
	-- leaving the screen or switching tabs closes it
	OffCommand = function(self) self:visible(false) end,
	TabChangedMessageCommand = function(self) self:visible(false) end,
	SortOrderChangedMessageCommand = function(self) self:playcommand("Refresh") end,
	-- clicks anywhere outside the table close it (and do not reach the wheel under it)
	UIElements.QuadButton(tblZ - 1, 1) .. {
		InitCommand = function(self)
			self:xy(0, 0):halign(0):valign(0):zoomto(SCREEN_WIDTH, SCREEN_HEIGHT):diffusealpha(0)
		end,
		MouseDownCommand = function(self, params)
			setOpen(false)
		end
	},
	-- panel: dark glass with the theme's thin silver rim
	Def.Quad {
		InitCommand = function(self)
			self:xy(tblX, tblY):halign(0):valign(0):zoomto(tblW, rowsN * cellH + 6)
			self:diffuse(color("#08080b")):diffusealpha(0.94)
		end
	},
	Def.Quad {
		InitCommand = function(self)
			self:xy(tblX, tblY):halign(0):valign(0):zoomto(tblW, 1):diffuse(color(seraphicLabelColor)):diffusealpha(0.6)
		end
	},
	Def.Quad {
		InitCommand = function(self)
			self:xy(tblX, tblY + rowsN * cellH + 6):halign(0):valign(1):zoomto(tblW, 1)
			self:diffuse(color(seraphicLabelColor)):diffusealpha(0.6)
		end
	},
	-- column divider
	Def.Quad {
		InitCommand = function(self)
			self:xy(tblX + cellW, tblY + 4):halign(0.5):valign(0):zoomto(1, rowsN * cellH - 2)
			self:diffuse(color(seraphicLabelColor)):diffusealpha(0.25)
		end
	}
}
for i, so in ipairs(sortList) do
	local col = math.floor((i - 1) / rowsN)
	local row = (i - 1) % rowsN
	local x, y = tblX + col * cellW, tblY + 3 + row * cellH
	tbl[#tbl + 1] = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(x, y)
		end,
		-- current sort: red wash like the selected wheel row
		Def.Quad {
			Name = "Cur",
			InitCommand = function(self)
				self:xy(2, 0):halign(0):valign(0):zoomto(cellW - 4, cellH)
				self:diffuseleftedge(color("#e0283c55")):diffuserightedge(color("#e0283c10"))
			end,
			RefreshCommand = function(self)
				self:visible(GAMESTATE:GetSortOrder() == so)
			end
		},
		Def.Quad {
			Name = "Hover",
			InitCommand = function(self)
				self:xy(2, 0):halign(0):valign(0):zoomto(cellW - 4, cellH):diffuse(color("#ffffff")):diffusealpha(0)
			end
		},
		LoadFont("Common Normal") .. {
			Name = "Text",
			InitCommand = function(self)
				self:xy(10, cellH / 2):halign(0):zoom(0.34):maxwidth((cellW - 16) / 0.34)
				self:settext(sortTable[so] or so:gsub("SortOrder_", ""))
			end,
			RefreshCommand = function(self)
				self:diffuse(color(GAMESTATE:GetSortOrder() == so and seraphicValueColor or seraphicLabelColor))
			end
		},
		UIElements.QuadButton(tblZ, 1) .. {
			InitCommand = function(self)
				self:halign(0):valign(0):zoomto(cellW, cellH):diffusealpha(0)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and dropdown:GetVisible() then
					chooseSort(so)
				end
			end,
			MouseOverCommand = function(self)
				self:GetParent():GetChild("Hover"):diffusealpha(0.08)
			end,
			MouseOutCommand = function(self)
				self:GetParent():GetChild("Hover"):diffusealpha(0)
			end
		}
	}
end

-- LR2-style beveled bar (cropped from the skin's select sheet)
t[#t + 1] = Def.Sprite {
	Texture = THEME:GetPathG("", "seraphic_packbar"),
	InitCommand = function(self)
		self:xy(boxX, boxY):halign(0):valign(0):zoomto(boxW, boxH)
	end
}

local group_rand = ""
t[#t + 1] = UIElements.TextToolTip(1, 1, "Seraphic Title") .. {
	Name="rando",
	InitCommand = function(self)
		self:xy(boxX + boxW / 2, boxY + boxH / 2):halign(0.5):valign(0.5):zoom(0.34):maxwidth((boxW - 44) / 0.34)
		self.randex = 0
		self.randlist = {}
	end,
	BeginCommand = function(self)
		self:queuecommand("Set")
	end,
	SetCommand = function(self)
		local sort = GAMESTATE:GetSortOrder()
		local song = GAMESTATE:GetCurrentSong()
		if sort == nil then
			self:settextf("%s: ", translated_info["Sort"])
		elseif sort == "SortOrder_Group" and song ~= nil then
			group_rand = song:GetGroupName()
			self:settext(group_rand)
		else
			-- other sorts: the group the wheel is in (letter, MSD range, ...); the sort itself is shown above
			group_rand = ""
			local top = SCREENMAN:GetTopScreen()
			local w = top and top.GetMusicWheel and top:GetMusicWheel()
			local section = w and w:GetSelectedSection() or ""
			if section ~= "" then
				self:settext(section)
			else
				self:settextf("%s: %s", translated_info["Sort"], sortTable[sort])
			end
		end
	end,
	SortOrderChangedMessageCommand = function(self)
		self:queuecommand("Set"):diffuse(getMainColor("positive"))
	end,
	CurrentSongChangedMessageCommand = function(self)
		self:playcommand("Set")
	end,
	MouseDownCommand = function(self, params)
		if group_rand ~= "" and params.event == "DeviceButton_left mouse button" then
			local w = SCREENMAN:GetTopScreen():GetMusicWheel()

			local function newrandsong()
				local t = w:GetSongsInGroup(group_rand)
				if #t == 0 then return nil end
				local random_song = t[math.random(#t)]
				return random_song
			end
			
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
	end,
	MouseOverCommand = function(self)
		if group_rand ~= "" then
			self:diffusealpha(hoverAlpha)
		end
	end,
	MouseOutCommand = function(self)
		if group_rand ~= "" then
			self:diffusealpha(1)
		end
	end,
}

t[#t + 1] = StandardDecorationFromFileOptional("BPMDisplay", "BPMDisplay")

-- sort table last, so it sits over the pack box
t[#t + 1] = tbl
t[#t + 1] = StandardDecorationFromFileOptional("BPMLabel", "BPMLabel")

return t
