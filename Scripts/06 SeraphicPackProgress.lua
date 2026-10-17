-- Pack progress for the song list: how many songs in a pack have their best score
-- (at 1.0x or faster, any difficulty) in each grade family. Only the songs the music
-- wheel currently shows for the pack are counted, so search and filters narrow both
-- the lamps and the "x / y" count. Each song's grade family is cached per pack (song
-- dir -> family, 0 when unplayed); the cache is dropped whenever a new score is set
-- (Scripts/05 SeraphicSession.lua).
SeraphicPackProgressCache = {}

-- grade families, best first; colour comes from getGradeColor of the family's grade
SeraphicPackProgressFamilies = {
	{name = "AAAA", grade = "Grade_Tier04"},
	{name = "AAA", grade = "Grade_Tier07"},
	{name = "AA", grade = "Grade_Tier10"},
	{name = "A", grade = "Grade_Tier13"},
	{name = "B-", grade = "Grade_Tier14"}
}

local function familyOf(grade)
	if type(grade) ~= "string" then return nil end
	if grade == "Grade_Failed" then return 5 end
	local tier = tonumber(grade:match("Tier(%d+)"))
	if not tier then return nil end
	if tier <= 4 then return 1 end
	if tier <= 7 then return 2 end
	if tier <= 10 then return 3 end
	if tier <= 13 then return 4 end
	return 5
end

-- best wife score and its grade over every chart of a song, rates of 1.0x and up
local function songBest(song)
	local bestWife, bestGrade = -1, nil
	local charts
	pcall(function() charts = song:GetChartsOfCurrentGameMode() end)
	if not charts then pcall(function() charts = song:GetAllSteps() end) end
	for _, steps in ipairs(charts or {}) do
		pcall(function()
			local byRate = SCOREMAN:GetScoresByKey(steps:GetChartKey())
			if not byRate then return end
			for rate, list in pairs(byRate) do
				local r = tonumber((tostring(rate):gsub("x", ""))) or 0
				if r >= 0.999 then
					local top = list:GetScores()[1]
					if top then
						local w = top:GetWifeScore()
						if w > bestWife then
							bestWife, bestGrade = w, top:GetWifeGrade()
						end
					end
				end
			end
		end)
	end
	return bestGrade
end

-- the songs the music wheel shows for a pack under the current search and filters;
-- the whole pack when there is no wheel (e.g. while the screen is still being built)
local function visibleSongs(pack)
	-- only real packs get a bar (not the sections of other sort orders)
	local ok, isPack = pcall(function() return SONGMAN:DoesSongGroupExist(pack) end)
	if ok and not isPack then return nil end
	local songs
	pcall(function()
		local wheel = SCREENMAN:GetTopScreen():GetMusicWheel()
		if wheel then songs = wheel:GetSongsInGroup(pack) end
	end)
	if not songs then pcall(function() songs = SONGMAN:GetSongsInGroup(pack) end) end
	return songs
end

-- {total = songs, counts = {AAAA, AAA, AA, A, B-}} for a pack, or nil when it has no visible songs
function SeraphicPackProgress(pack)
	if not pack or pack == "" then return nil end
	local songs = visibleSongs(pack)
	if not songs or #songs == 0 then return nil end
	local c = os.clock()
	local fams = SeraphicPackProgressCache[pack]
	if not fams then
		fams = {}
		SeraphicPackProgressCache[pack] = fams
	end
	local out = {total = #songs, counts = {0, 0, 0, 0, 0}}
	for _, song in ipairs(songs) do
		local dir = song:GetSongDir()
		local f = fams[dir]
		if f == nil then
			f = familyOf(songBest(song)) or 0
			fams[dir] = f
		end
		if f > 0 then out.counts[f] = out.counts[f] + 1 end
	end
	local took = os.clock() - c
	if took > 0.01 then Warn(string.format("[Seraphic] pack progress %s: %.3fs", pack, took)) end
	return out
end

-- drop one pack's cached counts (a score was set in it), or all of them when no pack is given
function SeraphicPackProgressReset(pack)
	if pack then
		SeraphicPackProgressCache[pack] = nil
	else
		SeraphicPackProgressCache = {}
	end
end

-- load-time diagnostics: "[Seraphic] t=<clock> +<since last stamp> <label>" lines in the log
local seraphicLastStamp
function SeraphicStamp(label)
	local now = os.clock()
	Warn(string.format("[Seraphic] t=%.3f +%.3f %s", now, now - (seraphicLastStamp or now), label))
	seraphicLastStamp = now
end
