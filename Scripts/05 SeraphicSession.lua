-- Session chronicle: what happened since the game started (shown as ::TODAY on the Profile tab).
-- Only initialised once, so reloading theme scripts doesn't wipe the session.
if SeraphicSession == nil then
	SeraphicSession = {
		plays = 0, -- results screens seen this session
		wifeSum = 0, -- sum of wife scores (0..1) for the average
		bestSSR = 0, -- highest overall SSR played this session
		startRating = nil -- player rating when the session started (read lazily)
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
