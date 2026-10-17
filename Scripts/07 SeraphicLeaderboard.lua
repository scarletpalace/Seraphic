-- Online chart leaderboard requests, at most one in flight per chart.
-- When a fetch comes back the engine empties and refills that chart's cached leaderboard,
-- which frees every score object Lua already got from it (DLMAN:GetChartLeaderBoard or an
-- earlier callback). Using one of those afterwards crashes the game outright, no Lua error.
-- The engine only goes online while a chart's cache is still empty, so a second fetch for the
-- same chart can only happen while the first is out; joining it instead means a filled cache
-- is never refilled under the screens holding its scores.
-- Every request ends with a SeraLeaderboardArrived message ({chartkey = ...}); listen for that
-- rather than capturing an actor in the callback, since the reply can land after a screen change.
local pending = {} -- chartkey -> {started = time, callbacks = {...}}
local GIVE_UP = 30 -- seconds; a fetch the engine never answers (an odd status code) stops blocking new ones

function seraphicRequestLeaderboard(chartkey, callback)
	if type(chartkey) ~= "string" or chartkey == "" then return end
	local now = GetTimeSinceStart()
	local p = pending[chartkey]
	if p and now - p.started < GIVE_UP then
		if callback then p.callbacks[#p.callbacks + 1] = callback end
		return
	end
	p = {started = now, callbacks = {callback}}
	pending[chartkey] = p
	local ok, err = pcall(function()
		DLMAN:RequestChartLeaderBoardFromOnline(chartkey, function(leaderboard)
			if pending[chartkey] == p then pending[chartkey] = nil end
			for _, cb in ipairs(p.callbacks) do
				local fine, e = pcall(cb, leaderboard)
				if not fine then Trace("Seraphic: leaderboard callback failed: " .. tostring(e)) end
			end
			MESSAGEMAN:Broadcast("SeraLeaderboardArrived", {chartkey = chartkey})
		end)
	end)
	if not ok then
		if pending[chartkey] == p then pending[chartkey] = nil end
		Trace("Seraphic: leaderboard request failed: " .. tostring(err))
	end
end
