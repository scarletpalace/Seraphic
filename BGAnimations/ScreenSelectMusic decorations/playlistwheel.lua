-- Seraphic: playlist wheel. While the Playlists tab is open the song wheel is hidden and this list takes its place:
-- every playlist is a row styled like a pack, Start (or a click) opens it and lists its charts under it like songs.
-- Moving onto a chart selects that song, difficulty and rate on the real wheel (so banner, MSD and preview follow);
-- Start on it plays it. Back closes the open playlist, or returns to the General tab.
-- The engine has no playlist sort, so input is redirected to this file while the tab is open.

-- the wheel item art (seraphicBar, seraphicSelectedBar, seraphicPackProgressBar) is defined by this file
if not seraphicBar then
	LoadActor(THEME:GetPathG("MusicWheelItem", "Song NormalPart"))
end

local playlistTab = 7
local numSlots = 15
local centre = math.ceil(numSlots / 2)
local rowSpacing = 46
local barW = capWideScale(get43size(342), 342)
local wheelX = SCREEN_WIDTH - capWideScale(get43size(350), 350)
local wheelY = SCREEN_CENTER_Y

local rows = {} -- {kind = "playlist", pl, name} or {kind = "chart", chart, song, steps}
local openName = nil -- name of the expanded playlist
local cursor = 1
local pos = 1 -- drawn position, eases toward cursor
local slots = {}
local active = false
local ownsRedirect = false
local ssmName
local whee
local root

-- shared with _frame.lua (scroll crystal) and the wheel scroll helpers
SeraphicPlaylistWheel = {active = false, fraction = 0}

local function playSound(name)
	SOUND:PlayOnce(THEME:GetPathS("MusicWheel", name))
end

local function setRate(rate)
	if not rate or math.abs(rate - getCurRateValue()) < 0.001 then return end
	GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(rate)
	GAMESTATE:GetSongOptionsObject("ModsLevel_Song"):MusicRate(rate)
	GAMESTATE:GetSongOptionsObject("ModsLevel_Current"):MusicRate(rate)
	MESSAGEMAN:Broadcast("CurrentRateChanged")
end

local function rateString(rate)
	return string.format("%.2f", rate):gsub("%.?0+$", "") .. "x"
end

local function buildRows()
	local cur = rows[cursor]
	local curKey = cur and (cur.kind == "playlist" and "p" .. cur.name or "c" .. cur.key .. cur.index)
	rows = {}
	local lists = SONGMAN:GetPlaylists() or {}
	for _, pl in ipairs(lists) do
		local name = pl:GetName()
		rows[#rows + 1] = {kind = "playlist", pl = pl, name = name}
		if name == openName then
			local charts = pl:GetAllSteps() or {}
			local keys = pl:GetChartkeys() or {}
			for i, chart in ipairs(charts) do
				local key = keys[i]
				local loaded = chart:IsLoaded()
				rows[#rows + 1] = {
					kind = "chart",
					chart = chart,
					key = key or "",
					index = i,
					loaded = loaded,
					song = loaded and key and SONGMAN:GetSongByChartKey(key) or nil,
					steps = loaded and key and SONGMAN:GetStepsByChartKey(key) or nil
				}
			end
		end
	end
	-- keep the cursor on the same row when the list changes under it
	cursor = math.max(1, math.min(cursor, #rows))
	if curKey then
		for i, r in ipairs(rows) do
			if (r.kind == "playlist" and "p" .. r.name or "c" .. r.key .. r.index) == curKey then
				cursor = i
				break
			end
		end
	end
	for _, s in ipairs(slots) do s.idx = nil end
end

local function cursorToPlaylist(name)
	for i, r in ipairs(rows) do
		if r.kind == "playlist" and r.name == name then
			cursor = i
			return
		end
	end
end

-- the chart under the cursor becomes the real wheel's song, difficulty and rate
local previewed
local function preview()
	local r = rows[cursor]
	if not r or r.kind ~= "chart" or not r.song or not r.steps or previewed == r then return end
	previewed = r
	setRate(r.chart:GetRate())
	GAMESTATE:SetPreferredDifficulty(PLAYER_1, r.steps:GetDifficulty())
	-- false when the song is hidden by the current filters
	r.selected = whee:SelectSong(r.song)
	-- the screen picks the steps a moment later; put the playlist's chart back if it chose another one
	root:GetChild("FixTimer"):stoptweening():sleep(0.05):queuecommand("Fix")
end

local function openPlaylist(name)
	openName = name
	SONGMAN:SetActivePlaylist(name)
	MESSAGEMAN:Broadcast("DisplaySinglePlaylist")
	buildRows()
	cursorToPlaylist(name)
end

local function closePlaylist()
	local name = openName
	openName = nil
	MESSAGEMAN:Broadcast("DisplayAllPlaylists")
	buildRows()
	if name then cursorToPlaylist(name) end
end

local function move(n)
	if #rows == 0 or n == 0 then return end
	local new = cursor + n
	if new < 1 or new > #rows then
		-- wrap like the song wheel, without sweeping through the whole list
		new = ((new - 1) % #rows) + 1
		pos = new
	end
	cursor = new
	playSound("change")
	root:GetChild("PreviewTimer"):stoptweening():sleep(0.12):queuecommand("Preview")
end

local function startPlaying()
	local r = rows[cursor]
	if not r or not r.song then return end
	previewed = nil
	preview()
	local top = SCREENMAN:GetTopScreen()
	if not r.selected then
		ms.ok("This chart is hidden by the current filters")
		return
	end
	if GAMESTATE:GetCurrentSteps() ~= r.steps then
		GAMESTATE:SetCurrentSteps(PLAYER_1, r.steps)
	end
	-- give input back before the screen goes away, gameplay must not start redirected
	if ownsRedirect then
		SCREENMAN:set_input_redirected(PLAYER_1, false)
		ownsRedirect = false
	end
	active = false
	top:SelectCurrent()
	-- not started after all (wheel still moving): keep the list
	if top:GetSelectionState() ~= 2 then active = true end
end

local function activate(i)
	local r = rows[i or cursor]
	if not r then return end
	if r.kind == "playlist" then
		if openName == r.name then
			playSound("collapse")
			closePlaylist()
		else
			playSound("expand")
			openPlaylist(r.name)
		end
	elseif r.loaded then
		startPlaying()
	end
end

local function leaveTab()
	local from = getTabIndex()
	setTabIndex(0)
	MESSAGEMAN:Broadcast("TabChanged", {from = from, to = 0})
end

local function input(event)
	if not active or event.type == "InputEventType_Release" then return false end
	local top = SCREENMAN:GetTopScreen()
	if not top or top:GetName() ~= ssmName then return false end
	local btn = event.DeviceInput.button
	if btn == "DeviceButton_mousewheel up" then
		move(-1)
		return false
	elseif btn == "DeviceButton_mousewheel down" then
		move(1)
		return false
	end
	-- ctrl+P: new playlist, as on the song wheel (the screen does not see keys while this list has them)
	if btn == "DeviceButton_p" and event.type == "InputEventType_FirstPress"
		and (INPUTFILTER:IsBeingPressed("left ctrl") or INPUTFILTER:IsBeingPressed("right ctrl")) then
		SONGMAN:NewPlaylist()
		return false
	end
	local gb = event.GameButton
	if gb == "MenuUp" or gb == "MenuLeft" then
		move(-1)
	elseif gb == "MenuDown" or gb == "MenuRight" then
		move(1)
	elseif gb == "Start" and event.type == "InputEventType_FirstPress" then
		activate()
	elseif gb == "Back" and event.type == "InputEventType_FirstPress" then
		if openName then
			playSound("collapse")
			closePlaylist()
		else
			leaveTab()
		end
	end
	return false
end

-- one row of the wheel; its contents are filled when the row it shows changes
local function slot(k)
	local playlistPart = Def.ActorFrame {
		Name = "PL",
		LoadFont("MusicWheelItem SectionCollapsed") .. {
			Name = "Name",
			InitCommand = function(self)
				self:xy(10, -9):zoom(0.44):halign(0):maxwidth(capWideScale(get43size(320), 320) / 0.44)
			end
		},
		seraphicPackProgressBar() .. {Name = "Prog"}
	}
	local chartPart = Def.ActorFrame {
		Name = "CH",
		LoadFont("TextBanner text") .. {
			Name = "Title",
			InitCommand = function(self)
				self:xy(22, -9):zoom(0.64):halign(0):maxwidth((barW - 130) / 0.64)
			end
		},
		LoadFont("TextBanner text") .. {
			Name = "Sub",
			InitCommand = function(self)
				self:xy(22, 9):zoom(0.38):halign(0):diffusealpha(0.78):maxwidth((barW - 150) / 0.38)
			end
		},
		LoadFont("Common Normal") .. {
			Name = "Diff",
			InitCommand = function(self)
				self:xy(barW - 14, -9):zoom(0.42):halign(1)
			end
		},
		LoadFont("Common Normal") .. {
			Name = "MSD",
			InitCommand = function(self)
				self:xy(barW - 14, 9):zoom(0.38):halign(1)
			end
		}
	}
	return Def.ActorFrame {
		Name = "Slot" .. k,
		InitCommand = function(self)
			slots[k] = {actor = self}
			self:visible(false)
		end,
		FillCommand = function(self, r)
			self:visible(r ~= nil)
			if not r then return end
			local pl, ch = self:GetChild("PL"), self:GetChild("CH")
			pl:visible(r.kind == "playlist")
			ch:visible(r.kind == "chart")
			if r.kind == "playlist" then
				pl:GetChild("Name"):settext(r.name)
				pl:GetChild("Prog"):playcommand("Set", {Progress = SeraphicPlaylistProgress(r.pl)})
			else
				local c = r.chart
				local rate = c:GetRate()
				ch:GetChild("Title"):settext(c:GetSongTitle())
				ch:GetChild("Title"):diffusealpha(r.loaded and 1 or 0.45)
				ch:GetChild("Sub"):settext(c:GetPackName())
				local diff = r.steps and r.steps:GetDifficulty() or c:GetDifficulty()
				ch:GetChild("Diff"):settext(getShortDifficulty(diff) .. "  " .. rateString(rate)):diffuse(byDifficulty(diff))
				if r.steps then
					local msd = r.steps:GetMSD(rate, 1)
					ch:GetChild("MSD"):settextf("%5.2f", msd):diffuse(byMSD(msd))
				else
					ch:GetChild("MSD"):settext("not loaded"):diffuse(color(seraphicLabelColor))
				end
			end
		end,
		seraphicBar("bar", 31, 1, 0.78),
		seraphicSelectedBar() .. {Name = "Sel"},
		Def.Quad {
			InitCommand = function(self)
				self:xy(16, -2 - 38 / 2 + 3):halign(0):zoomto(barW - 16, 1)
				self:diffuseleftedge(color("#ffffff66")):diffuserightedge(color("#ffffff00"))
			end
		},
		playlistPart,
		chartPart,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:halign(0):zoomto(barW + 8, rowSpacing):diffusealpha(0)
			end,
			MouseDownCommand = function(self, params)
				if not active or params.event ~= "DeviceButton_left mouse button" then return end
				local idx = slots[k].idx
				if not rows[idx] then return end
				if idx == cursor then
					activate(idx)
				else
					move(idx - cursor)
					if rows[cursor].kind == "playlist" then activate() end
				end
			end
		}
	}
end

local function place(dt)
	if math.abs(cursor - pos) < 0.002 then
		pos = cursor
	else
		pos = pos + (cursor - pos) * math.min(1, dt * 20)
	end
	local base = math.floor(pos + 0.5)
	for k = 1, numSlots do
		local s = slots[k]
		local idx = base + k - centre
		if s.idx ~= idx then
			s.idx = idx
			s.actor:playcommand("Fill", rows[idx])
		end
		local sel = idx == cursor
		if s.sel ~= sel then
			s.sel = sel
			s.actor:GetChild("Sel"):playcommand("Set", {DrawIndex = sel and centre or -1})
		end
		-- same curve as the song wheel (metrics.ini, ItemTransformFunction)
		local o = idx - pos
		local c = math.max(-6, math.min(6, o))
		s.actor:xy(-3 * c - 18 * math.max(0, 1 - math.abs(o)), o * rowSpacing)
	end
	SeraphicPlaylistWheel.fraction = #rows > 1 and (cursor - 1) / (#rows - 1) or 0
end

-- input belongs to this list only while it is shown and the select screen is on top (text entry popups need it)
local function syncRedirect()
	local top = SCREENMAN:GetTopScreen()
	local want = active and top ~= nil and top:GetName() == ssmName
	if want and not SCREENMAN:get_input_redirected(PLAYER_1) then
		SCREENMAN:set_input_redirected(PLAYER_1, true)
		ownsRedirect = true
		-- back from a popup (new playlist name, ...): pick up what changed
		buildRows()
	elseif not want and ownsRedirect then
		ownsRedirect = false
		-- the search tab keeps the keyboard itself
		if getTabIndex() ~= 3 then
			SCREENMAN:set_input_redirected(PLAYER_1, false)
		end
	end
end

local t = Def.ActorFrame {
	InitCommand = function(self)
		root = self
		self:xy(wheelX, wheelY):visible(false)
	end,
	BeginCommand = function(self)
		local top = SCREENMAN:GetTopScreen()
		ssmName = top:GetName()
		whee = top:GetMusicWheel()
		top:AddInputCallback(input)
		self:SetUpdateFunction(function(self, dt)
			syncRedirect()
			if active then
				-- other parts of the screen show the song wheel again (chart preview / calc info closing on a
				-- tab or song change), so keep it hidden for as long as this list is up
				whee:visible(false)
				place(dt)
			end
		end)
	end,
	OffCommand = function(self)
		active = false
		SeraphicPlaylistWheel.active = false
		syncRedirect()
	end,
	SetCommand = function(self)
		-- only on the solo select screen (the net screen keeps its own wheel handling)
		local show = getTabIndex() == playlistTab and ssmName == "ScreenSelectMusic"
		if show == active then return end
		active = show
		SeraphicPlaylistWheel.active = show
		whee:visible(not show)
		self:visible(show)
		if show then
			openName = nil
			buildRows()
			-- start on the playlist the left panel last opened, else the first one
			local apl = SONGMAN:GetActivePlaylist()
			if apl then cursorToPlaylist(apl:GetName()) end
			pos = cursor
			previewed = nil
		end
		syncRedirect()
	end,
	TabChangedMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	-- the left panel opened a playlist, closed one, or changed one (deleted chart, new rate, deleted playlist)
	DisplaySinglePlaylistMessageCommand = function(self)
		if not active then return end
		local apl = SONGMAN:GetActivePlaylist()
		if apl and apl:GetName() ~= openName then
			openName = apl:GetName()
			buildRows()
			cursorToPlaylist(openName)
		else
			buildRows()
		end
	end,
	DisplayAllPlaylistsMessageCommand = function(self)
		if not active then return end
		local name = openName
		openName = nil
		buildRows()
		if name then cursorToPlaylist(name) end
	end
}

for k = 1, numSlots do
	t[#t + 1] = slot(k)
end

-- timers: preview the chart once scrolling pauses, then correct the steps the screen picked
t[#t + 1] = Def.Actor {
	Name = "PreviewTimer",
	PreviewCommand = function(self)
		if active then preview() end
	end
}
t[#t + 1] = Def.Actor {
	Name = "FixTimer",
	FixCommand = function(self)
		local r = previewed
		if active and r and r.selected and GAMESTATE:GetCurrentSong() == r.song and GAMESTATE:GetCurrentSteps() ~= r.steps then
			GAMESTATE:SetCurrentSteps(PLAYER_1, r.steps)
		end
	end
}

return t
