-- Session chronicle: what happened since the game started (shown as ::SESSION on the Profile tab).
-- Only initialised once, so reloading theme scripts doesn't wipe the session.
if SeraphicSession == nil or SeraphicSession.scores == nil then
	local started = ""
	pcall(function() started = os.date("%Y-%m-%d %H:%M:%S") end)
	SeraphicSession = {
		plays = 0, -- scores set this session
		wifeSum = 0, -- sum of wife scores (0..1) for the average
		bestSSR = 0, -- highest overall SSR played this session
		startRating = nil, -- player rating when the session started (read lazily)
		started = started, -- "YYYY-MM-DD HH:MM:SS", same format as HighScore:GetDate()
		scores = {}, -- snapshots of the scores set this session, newest first
		keys = {} -- score keys already recorded (a results screen can be opened more than once)
	}
end

-- current player rating, or nil when there is no profile yet
function SeraphicSessionCurrentRating()
	local ok, rating = pcall(function()
		local profile = PROFILEMAN:GetProfile(PLAYER_1)
		return profile and profile:GetPlayerRating()
	end)
	if ok and type(rating) == "number" then
		return rating
	end
	return nil
end

-- rating at the start of the session; captured the first time it is read
function SeraphicSessionStartRating()
	if SeraphicSession.startRating == nil then
		SeraphicSession.startRating = SeraphicSessionCurrentRating()
	end
	return SeraphicSession.startRating
end

-- a plain copy of a HighScore that answers the same getters the score lists use
-- (the engine's PlayerStageStats score object is reused by the next play, so it isn't kept)
local function snapshot(hs)
	local v = {}
	local function grab(field, fn)
		local ok, res = pcall(fn)
		if ok then v[field] = res end
	end
	grab("key", function() return hs:GetScoreKey() end)
	grab("date", function() return hs:GetDate() end)
	grab("chartkey", function() return hs:GetChartKey() end)
	grab("rate", function() return hs:GetMusicRate() end)
	grab("wife", function() return hs:GetWifeScore() end)
	grab("grade", function() return hs:GetWifeGrade() end)
	grab("valid", function() return hs:GetEtternaValid() end)
	v.ssr = {}
	for _, ss in ipairs(ms.SkillSets) do
		local ok, res = pcall(function() return hs:GetSkillsetSSR(ss) end)
		v.ssr[ss] = ok and res or 0
	end
	if type(v.date) == "string" and #v.date == 10 then v.date = v.date .. " 00:00:00" end
	return {
		GetScoreKey = function() return v.key end,
		GetDate = function() return v.date or "" end,
		GetChartKey = function() return v.chartkey end,
		GetMusicRate = function() return v.rate or 1 end,
		GetWifeScore = function() return v.wife or 0 end,
		GetWifeGrade = function() return v.grade or "Grade_Failed" end,
		GetEtternaValid = function() return v.valid ~= false end,
		GetSkillsetSSR = function(_, ss) return v.ssr[ss] or 0 end
	}
end

-- record one finished play from its HighScore; ignores scores set before the session started
-- (replays and results opened from the Scores tab) and scores already recorded
function SeraphicSessionRecordScore(hs)
	if not hs then return end
	local snap = snapshot(hs)
	local date, key = snap:GetDate(), snap:GetScoreKey()
	if SeraphicSession.started ~= "" and date ~= "" and date < SeraphicSession.started then return end
	if key then
		if SeraphicSession.keys[key] then return end
		SeraphicSession.keys[key] = true
	end
	table.insert(SeraphicSession.scores, 1, snap)
	SeraphicSessionRecordPlay(snap:GetWifeScore(), snap:GetSkillsetSSR("Overall"))
end

-- the n-th score of this session, newest first (nil past the end)
function SeraphicSessionScore(n)
	return SeraphicSession.scores[n]
end

-- record one finished play (wife 0..1, ssr = overall SSR)
function SeraphicSessionRecordPlay(wife, ssr)
	SeraphicSessionStartRating()
	SeraphicSession.plays = SeraphicSession.plays + 1
	if type(wife) == "number" then
		SeraphicSession.wifeSum = SeraphicSession.wifeSum + wife
	end
	if type(ssr) == "number" and ssr > SeraphicSession.bestSSR then
		SeraphicSession.bestSSR = ssr
	end
end
