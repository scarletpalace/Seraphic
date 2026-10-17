local update = false
local showOnline = false
local recentactive = false
local percentactive = false
local sessionactive = false -- ::SESSION list: scores set since the game started
local function BroadcastIfActive(msg)
	if update then
		MESSAGEMAN:Broadcast(msg)
	end
end

local translated_info = {
	Validated = THEME:GetString("TabProfile", "ScoreValidated"),
	Invalidated = THEME:GetString("TabProfile", "ScoreInvalidated"),
	Online = THEME:GetString("TabProfile", "Online"),
	Local = THEME:GetString("TabProfile", "Local"),
	Recent = THEME:GetString("TabProfile", "Recent"),
	Percent = THEME:GetString("TabProfile", "Percent"),
	NextPage = THEME:GetString("TabProfile", "NextPage"),
	PrevPage = THEME:GetString("TabProfile", "PreviousPage"),
	Save = THEME:GetString("TabProfile", "SaveProfile"),
	AssetSettings = THEME:GetString("TabProfile", "AssetSettingEntry"),
	Success = THEME:GetString("TabProfile", "SaveSuccess"),
	Failure = THEME:GetString("TabProfile", "SaveFail"),
	ValidateAll = THEME:GetString("TabProfile", "ValidateAllScores"),
	ForceRecalc = THEME:GetString("TabProfile", "ForceRecalcScores"),
	UploadAllScore = THEME:GetString("TabProfile", "UploadAllScore"),
}

local t = Def.ActorFrame {
	BeginCommand = function(self)
		self:queuecommand("Set"):visible(false)
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
		if getTabIndex() == 4 or SCREENMAN:GetTopScreen():GetName() == "ScreenNetRoom" and getTabIndex() == 1 then
			self:queuecommand("On")
			self:visible(true)
			update = true
		else
			self:queuecommand("Off")
			update = false
		end
	end,
	LogOutMessageCommand = function(self)
		showOnline = false
		BroadcastIfActive("UpdateRanking")
	end,
	LoginMessageCommand = function(self)
		BroadcastIfActive("UpdateRanking")
	end,
	LoginFailedMessageCommand = function(self)
		BroadcastIfActive("UpdateRanking")
	end,
	OnlineUpdateMessageCommand = function(self)
		BroadcastIfActive("UpdateRanking")
	end,
	TabChangedMessageCommand = function(self)
		self:queuecommand("Set")
	end
}

local frameX = 10
local frameY = 96 -- window spans y 96..384, under the top bar
local frameWidth = capWideScale(360, 400)
local frameHeight = 288
local fontScale = 0.24
local scoresperpage = 16 -- rows per page that fit inside the window
local scoreYspacing = 13.5 -- score list row pitch
local distY = 15
local offsetX = -10
local offsetY = 20
local txtDist = 33
local rankingSkillset = 1
local rankingPage = 1
local numrankingpages = math.ceil(200 / scoresperpage) -- ~200 scores, as with 20 x 10
local rankingWidth = frameWidth - capWideScale(10, 25)
local rankingX = capWideScale(25, 35)
local rankingY = capWideScale(40, 40)
local rankingTitleSpacing = (rankingWidth / (#ms.SkillSets))
-- LR2-style layout (panel-local coords)
local tabW = (frameWidth - 24) / #ms.SkillSets -- skillset selector tabs
local tabY = offsetY + 11 -- centre of the skillset tab row, under the header band
local listY = offsetY + 22 -- top of the first score row
local bandX = 6 -- score/rating row bands
local bandW = frameWidth - 12
local toggleW = 52 -- header toggles (Percent/Recent, Local/Online)
local labelZoom = 0.42 -- Common Normal, uppercase silver labels
local tabZoom = 0.36 -- Common Normal, skillset tabs
-- short skillset tab names (Overall .. Technical); all tabs share one zoom that fits the widest name
local tabNames = {"OVERALL", "STREAM", "JS", "HS", "STAMINA", "JACK", "CJ", "TECH"}
local tabTextW = {}
-- header toggles (Session/Percent/Recent/Local/Online) share one zoom that fits the widest label
local hdrTextW = {}
local function hdrFit(self)
	local widest = 1
	for _, w in pairs(hdrTextW) do
		if w > widest then widest = w end
	end
	self:zoom(math.min(labelZoom, (toggleW - 8) / widest))
end
local crimson = "#9c1428"
-- header toggle / tab look: selected = crimson tint + light text, otherwise faint dark + silver text
local function styleToggleQuad(self, selected)
	if selected then
		self:diffuse(color(crimson)):diffusealpha(0.4)
	else
		self:diffuse(color("#000000")):diffusealpha(0.25)
	end
end
local function styleToggleText(self, selected)
	self:diffuse(color(selected and seraphicValueColor or seraphicLabelColor))
end
local buttondiffuse = 0
local whee
local profile

if GAMESTATE:IsPlayerEnabled() then
	profile = GetPlayerOrMachineProfile(PLAYER_1)
end

t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(frameX, frameY):zoomto(frameWidth, frameHeight):halign(0):valign(0):diffuse(getMainColor("tabs")):diffusetopedge(panelTopColor())
	end
}
t[#t + 1] = seraphicPanel(frameX, frameY, frameWidth, frameHeight, true)
-- header band holding the Percent/Recent and Local/Online toggles
t[#t + 1] = seraphicHeaderBand(frameX, frameY, frameWidth, offsetY)
t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameX + 10, frameY + offsetY / 2):zoom(0.45):halign(0):maxwidth((frameWidth - 300) / 0.45)
		self:settext(seraphicHeading("Profile")):diffuse(color(seraphicLabelColor))
	end
}


local hoverAlpha = 0.6

local function byValidity(valid)
	if valid then
		return getMainColor("positive")
	end
	return byJudgment("TapNoteScore_Miss")
end

local function ButtonActive(self)
	return isOver(self) and update
end

-- The input callback for mouse clicks already exists within the tabmanager and redefining it within the local scope does nothing but create confusion - mina
local r = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(frameX, frameY)
	end,
	OnCommand = function(self)
		whee = SCREENMAN:GetTopScreen():GetMusicWheel()
	end
}

local function rankingLabel(i)
	local ths  -- the top highscore object - mina
	local ck
	local thssteps
	local thssong
	local xoffset
	local onlineScore

	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(rankingX + offsetX + 7, listY + (i - 0.5) * scoreYspacing)
			-- self:RunCommandsOnChildren(cmd(halign,0;zoom,fontScale))
			self:visible(false)
		end,
		UpdateRankingMessageCommand = function(self)
			if rankingSkillset > 1 and update and not recentactive and not sessionactive then
				if not showOnline then
					ths = SCOREMAN:GetTopSSRHighScoreForGame(i + (scoresperpage * (rankingPage - 1)), ms.SkillSets[rankingSkillset])
					if ths then
						self:visible(true)
						ck = ths:GetChartKey()
						thssong = SONGMAN:GetSongByChartKey(ck)
						thssteps = SONGMAN:GetStepsByChartKey(ck)
						MESSAGEMAN:Broadcast("DisplayProfileRankingLabels")
					else
						self:visible(false)
					end
				else
					onlineScore = DLMAN:GetTopSkillsetScore(i, ms.SkillSets[rankingSkillset])
					MESSAGEMAN:Broadcast("DisplayProfileRankingLabels")
					if not onlineScore then
						self:visible(false)
					else
						self:visible(true)
					end
				end
			else
				onlinesScore = nil
				self:visible(false)
			end
		end,
		seraphicRowBand(bandX - (rankingX + offsetX + 7), -scoreYspacing / 2, bandW, scoreYspacing - 1, i),
		LoadFont("Common Large") .. {
			Name = "text1",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:maxwidth(100)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if not showOnline then
					if ths then
						self:halign(0.5)
						self:settext(((rankingPage - 1) * scoresperpage) + i .. ".")
						self:diffuse(byValidity(ths:GetEtternaValid()))
					end
				else
					self:halign(0.5)
					self:settext(i .. ".")
					self:diffuse(getMainColor("positive"))
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "text2",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(15):maxwidth(160)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if not showOnline then
					if ths then
						self:settextf("%5.2f", ths:GetSkillsetSSR(ms.SkillSets[rankingSkillset]))
						self:diffuse(byValidity(ths:GetEtternaValid()))
					else
						self:settext("")
					end
				else
					if onlineScore then
						self:settextf("%5.2f", onlineScore.ssr)
						self:diffuse(getMainColor("positive"))
					else
						self:settext("")
					end
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "text3",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(60):maxwidth(580)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if not showOnline then
					if thssong and ths then
						self:settext(thssong:GetDisplayMainTitle())
						self:diffuse(byValidity(ths:GetEtternaValid()))
					else
						self:settext("")
					end
				else
					if onlineScore then
						self:settext(onlineScore.songName)
						self:diffuse(getMainColor("positive"))
					else
						self:settext("")
					end
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "text4",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(225)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if not showOnline then
					if ths then
						self:halign(0.5)
						local ratestring = string.format("%.2f", ths:GetMusicRate()):gsub("%.?0+$", "") .. "x"
						self:settext(ratestring)
						self:diffuse(byValidity(ths:GetEtternaValid()))
					else
						self:settext("")
					end
				else
					if onlineScore then
						local ratestring = string.format("%.2f", onlineScore.rate):gsub("%.?0+$", "") .. "x"
						self:halign(0.5)
						self:settext(ratestring)
						self:diffuse(getMainColor("positive"))
					else
						self:settext("")
					end
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "text5",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(245):maxwidth(160)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if not showOnline then
					if ths then
						local wifeval = ths:GetWifeScore() * 100
						if wifeval > 99.9 then
							self:settextf("%5.4f%%", wifeval)
						else
							self:settextf("%5.2f%%", wifeval)
						end
						if not ths:GetEtternaValid() then
							self:diffuse(byJudgment("TapNoteScore_Miss"))
						else
							self:diffuse(getGradeColor(ths:GetWifeGrade()))
						end
					else
						self:settext("")
					end
				else
					if onlineScore then
						self:settextf("%5.2f%%", onlineScore.wife * 100)
						self:diffuse(getGradeColor(onlineScore.grade))
					else
						self:settext("")
					end
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "text6",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(305)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				self:halign(0.5)
				if not showOnline then
					if thssteps then
						local diff = thssteps:GetDifficulty()
						self:diffuse(byDifficulty(diff))
						self:settext(getShortDifficulty(diff))
					else
						self:settext("")
					end
				else
					if onlineScore then
						local diff = onlineScore.difficulty
						self:diffuse(byDifficulty(diff))
						self:settext(getShortDifficulty(diff))
					else
						self:settext("")
					end
				end
			end
		},
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:x(-8):halign(0):diffusealpha(buttondiffuse)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self) -- hacky
				self:visible(true)
				self:zoomto(frameWidth - capWideScale(38,78), scoreYspacing - 1)
			end,
			MouseDownCommand = function(self, params)
				if rankingSkillset > 1 and params.event == "DeviceButton_left mouse button" and update then
					if not showOnline then
						if ths then
							whee:SelectSong(thssong)
						end
					elseif onlineScore and onlineScore.chartkey then
						local song = SONGMAN:GetSongByChartKey(onlineScore.chartkey)
						if song then
							whee:SelectSong(song)
						end
					end
				elseif params.event == "DeviceButton_right mouse button" and update and not showOnline and ths then
					ths:ToggleEtternaValidation()
					BroadcastIfActive("UpdateRanking")
					if ths:GetEtternaValid() then
						ms.ok(translated_info["Validated"])
					else
						ms.ok(translated_info["Invalidated"])
					end
				end
			end,
			MouseOverCommand = function(self)
				local alpha = 0.7
				for i = 1,6 do
					self:GetParent():GetChild("text" .. i):diffusealpha(alpha)
				end
			end,
			MouseOutCommand = function(self)
				local alpha = 1
				for i = 1,6 do
					self:GetParent():GetChild("text" .. i):diffusealpha(alpha)
				end
			end,
		}
	}
	return t
end

local function rankingButton(i)
	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(12 + (i - 0.5) * tabW, tabY)
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:zoomto(tabW - 2, 16)
				styleToggleQuad(self, i == rankingSkillset and not recentactive and not sessionactive)
			end,
			SetCommand = function(self)
				styleToggleQuad(self, i == rankingSkillset and not recentactive and not sessionactive)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update then
					recentactive = false
					sessionactive = false
					rankingSkillset = i
					rankingPage = 1
					if not percentactive then
						SCOREMAN:SortSSRsForGame(ms.SkillSets[rankingSkillset])
					else
						SCOREMAN:SortSSRsByPercentForGame()
					end
					BroadcastIfActive("UpdateRanking")
				end
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			MouseOverCommand = function(self)
				local alpha = 0.7
				self:GetParent():GetChild("RankButtonTxt"):diffusealpha(alpha)
			end,
			MouseOutCommand = function(self)
				local alpha = 1
				self:GetParent():GetChild("RankButtonTxt"):diffusealpha(alpha)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "RankButtonTxt",
			InitCommand = function(self)
				self:zoom(tabZoom)
				styleToggleText(self, i == rankingSkillset and not recentactive and not sessionactive)
			end,
			BeginCommand = function(self)
				self:settext(tabNames[i] or tostring(ms.SkillSetsTranslated[i]):upper())
				tabTextW[i] = self:GetWidth()
			end,
			OnCommand = function(self)
				local widest = 1
				for _, w in pairs(tabTextW) do
					if w > widest then widest = w end
				end
				self:zoom(math.min(tabZoom, (tabW - 10) / widest))
			end,
			UpdateRankingMessageCommand = function(self)
				styleToggleText(self, i == rankingSkillset and not recentactive and not sessionactive)
			end
		}
	}
	return t
end


local function recentLabel(i)
	local ths  -- aAAAAAAAA
	local ck
	local thssteps
	local thssong
	local xoffset
	local onlineScore

	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(rankingX - 22 , listY + (i - 0.5) * scoreYspacing)
			self:visible(false)
		end,
		UpdateRankingMessageCommand = function(self)
			if (recentactive or sessionactive) and update then
					local idx = i + (scoresperpage * (rankingPage - 1))
					if sessionactive then
						ths = SeraphicSessionScore and SeraphicSessionScore(idx)
					else
						ths = SCOREMAN:GetRecentScoreForGame(idx)
					end
					if ths then
						self:visible(true)
						ck = ths:GetChartKey()
						thssong = SONGMAN:GetSongByChartKey(ck)
						thssteps = SONGMAN:GetStepsByChartKey(ck)
						MESSAGEMAN:Broadcast("DisplayProfileRankingLabels")
					else
						self:visible(false)
					end
			else
				onlinesScore = nil
				self:visible(false)
			end
		end,
		seraphicRowBand(bandX - (rankingX - 22), -scoreYspacing / 2, bandW, scoreYspacing - 1, i),
		LoadFont("Common Large") .. {
			Name = "rectext1",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:maxwidth(100)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if ths and IsUsingWideScreen() then
					self:halign(0.5)
					self:settext(((rankingPage - 1) * scoresperpage) + i .. ".")
					self:diffuse(byValidity(ths:GetEtternaValid()))
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext2",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(15):maxwidth(160)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if ths then
					self:settextf("%5.2f", ths:GetSkillsetSSR(ms.SkillSets[1]))
					self:diffuse(byValidity(ths:GetEtternaValid()))
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext3",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(55):maxwidth(580)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if thssong and ths then
					self:settext(thssong:GetDisplayMainTitle())
					self:diffuse(byValidity(ths:GetEtternaValid()))
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext4",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(220)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if ths then
					self:halign(0.5)
					local ratestring = string.format("%.2f", ths:GetMusicRate()):gsub("%.?0+$", "") .. "x"
					self:settext(ratestring)
					self:diffuse(byValidity(ths:GetEtternaValid()))
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext5",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(240):maxwidth(160)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if ths then
					local wifeval = ths:GetWifeScore() * 100
					if wifeval > 99.9 then
						self:settextf("%5.4f%%", wifeval)
					else
						self:settextf("%5.2f%%", wifeval)
					end
					if not ths:GetEtternaValid() then
						self:diffuse(byJudgment("TapNoteScore_Miss"))
					else
						self:diffuse(getGradeColor(ths:GetWifeGrade()))
					end
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext6",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(300)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				self:halign(0.5)
				if thssteps then
					local diff = thssteps:GetDifficulty()
					self:diffuse(byDifficulty(diff))
					self:settext(getShortDifficulty(diff))
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Normal") .. {
			Name = "rectext7",
			--date
			InitCommand = function(self)
				self:x(312):zoom(fontScale + 0.05):halign(0)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if ths then
					if not IsUsingWideScreen() then
						self:settext(getScoreDate(ths):sub(1,10)):x(318)
					else
						self:settext(getScoreDate(ths)):maxwidth((frameWidth - 8 - (rankingX - 22) - 312) / (fontScale + 0.05))
					end
				else
					self:settext("")
				end
			end,
		},
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:x(capWideScale(15,-7)):halign(0):zoom(fontScale):diffusealpha(buttondiffuse)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self) -- hacky
				self:visible(true)
				self:zoomto(frameWidth - capWideScale(14,10), scoreYspacing - 1)
			end,
			MouseDownCommand = function(self, params)
				if (recentactive or sessionactive) and params.event == "DeviceButton_left mouse button" and update then
					if ths then
						whee:SelectSong(thssong)
					end
				elseif params.event == "DeviceButton_right mouse button" and update and recentactive then
					if ths and not showOnline then
						ths:ToggleEtternaValidation()
						BroadcastIfActive("UpdateRanking")
						if ths:GetEtternaValid() then
							ms.ok(translated_info["Validated"])
						else
							ms.ok(translated_info["Invalidated"])
						end
					end
				end
			end,
			MouseOverCommand = function(self)
				local alpha = 0.7
				for i = 1,7 do
					self:GetParent():GetChild("rectext" .. i):diffusealpha(alpha)
				end
			end,
			MouseOutCommand = function(self)
				local alpha = 1
				for i = 1,7 do
					self:GetParent():GetChild("rectext" .. i):diffusealpha(alpha)
				end
			end,
		},
	}
	return t
end

local function recentButton()
	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(frameWidth - 154, offsetY / 2)
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:zoomto(toggleW - 2, 15)
				styleToggleQuad(self, recentactive)
			end,
			SetCommand = function(self)
				styleToggleQuad(self, recentactive)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update then
					recentactive = true
					sessionactive = false
					percentactive = false
					rankingPage = 1
					SCOREMAN:SortRecentScoresForGame()
					BroadcastIfActive("UpdateRanking")
				end
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			MouseOverCommand = function(self)
				local alpha = 0.7
				self:GetParent():GetChild("RecentButtonTxt"):diffusealpha(alpha)
			end,
			MouseOutCommand = function(self)
				local alpha = 1
				self:GetParent():GetChild("RecentButtonTxt"):diffusealpha(alpha)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "RecentButtonTxt",
			OnCommand = function(self)
				hdrTextW[self:GetName()] = self:GetWidth()
				self:queuecommand("HdrFit")
			end,
			HdrFitCommand = hdrFit,
			InitCommand = function(self)
				self:zoom(labelZoom)
				styleToggleText(self, recentactive)
			end,
			BeginCommand = function(self)
				self:settext(tostring(translated_info["Recent"]):upper())
			end,
			UpdateRankingMessageCommand = function(self)
				styleToggleText(self, recentactive)
			end
		}
	}
	return t
end

local function percentButton()
	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(frameWidth - 208, offsetY / 2)
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:zoomto(toggleW - 2, 15)
				styleToggleQuad(self, percentactive)
			end,
			SetCommand = function(self)
				styleToggleQuad(self, percentactive)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update then
					percentactive = not percentactive
					showOnline = false
					recentactive = false
					sessionactive = false
					rankingPage = 1
					if rankingSkillset == 1 then
						rankingSkillset = 2
					end

					if not percentactive then
						SCOREMAN:SortSSRsForGame(ms.SkillSets[rankingSkillset])
					else
						SCOREMAN:SortSSRsByPercentForGame()
					end
					BroadcastIfActive("UpdateRanking")
				end
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			MouseOverCommand = function(self)
				local alpha = 0.7
				self:GetParent():GetChild("PercentButtonTxt"):diffusealpha(alpha)
			end,
			MouseOutCommand = function(self)
				local alpha = 1
				self:GetParent():GetChild("PercentButtonTxt"):diffusealpha(alpha)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "PercentButtonTxt",
			OnCommand = function(self)
				hdrTextW[self:GetName()] = self:GetWidth()
				self:queuecommand("HdrFit")
			end,
			HdrFitCommand = hdrFit,
			InitCommand = function(self)
				self:zoom(labelZoom)
				styleToggleText(self, percentactive)
			end,
			BeginCommand = function(self)
				self:settext(tostring(translated_info["Percent"]):upper())
			end,
			UpdateRankingMessageCommand = function(self)
				styleToggleText(self, percentactive)
			end
		}
	}
	return t
end

-- Online and Local buttons
t[#t + 1] = Def.ActorFrame {
	InitCommand = function(self)
		if DLMAN:IsLoggedIn() then
			self:visible(true)
		else
			self:visible(false)
		end
	end,
	SetCommand = function(self)
		if DLMAN:IsLoggedIn() then
			self:visible(true)
		else
			self:visible(false)
		end
	end,
	UpdateRankingMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	Def.ActorFrame {
		InitCommand = function(self)
			self:xy(frameX + frameWidth - 92, frameY + offsetY / 2)
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:zoomto(toggleW - 2, 15)
				styleToggleQuad(self, not showOnline)
			end,
			SetCommand = function(self)
				styleToggleQuad(self, not showOnline)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update then
					showOnline = false
					BroadcastIfActive("UpdateRanking")
				end
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			MouseOverCommand = function(self)
				local alpha = 0.7
				self:GetParent():GetChild("LocalTxt"):diffusealpha(alpha)
			end,
			MouseOutCommand = function(self)
				local alpha = 1
				self:GetParent():GetChild("LocalTxt"):diffusealpha(alpha)
			end,
		},
		LoadFont("Common Large") ..{
			Name = "LocalTxt",
			OnCommand = function(self)
				hdrTextW[self:GetName()] = self:GetWidth()
				self:queuecommand("HdrFit")
			end,
			HdrFitCommand = hdrFit,
			InitCommand = function(self)
				self:zoom(labelZoom)
				styleToggleText(self, not showOnline)
			end,
			BeginCommand = function(self)
				self:settext(tostring(translated_info["Local"]):upper())
			end,
			UpdateRankingMessageCommand = function(self)
				styleToggleText(self, not showOnline)
			end
		}
	},
	Def.ActorFrame {
		InitCommand = function(self)
			self:xy(frameX + frameWidth - 38, frameY + offsetY / 2)
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:zoomto(toggleW - 2, 15)
				if DLMAN:IsLoggedIn() then
					styleToggleQuad(self, showOnline)
				else
					self:diffuse(getMainColor("disabled")):diffusealpha(0.1)
				end
			end,
			SetCommand = function(self)
				if DLMAN:IsLoggedIn() then
					styleToggleQuad(self, showOnline)
				else
					self:diffuse(getMainColor("disabled")):diffusealpha(0.1)
				end
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update and DLMAN:IsLoggedIn() then
					showOnline = true
					BroadcastIfActive("UpdateRanking")
				end
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			MouseOverCommand = function(self)
				local alpha = 0.7
				self:GetParent():GetChild("OnlineTxt"):diffusealpha(alpha)
			end,
			MouseOutCommand = function(self)
				local alpha = 1
				self:GetParent():GetChild("OnlineTxt"):diffusealpha(alpha)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "OnlineTxt",
			OnCommand = function(self)
				hdrTextW[self:GetName()] = self:GetWidth()
				self:queuecommand("HdrFit")
			end,
			HdrFitCommand = hdrFit,
			InitCommand = function(self)
				self:zoom(labelZoom)
				styleToggleText(self, showOnline)
			end,
			BeginCommand = function(self)
				self:settext(tostring(translated_info["Online"]):upper())
			end,
			UpdateRankingMessageCommand = function(self)
				styleToggleText(self, showOnline)
			end
		}
	},

}
-- pages in the current list (the session list only has as many pages as it needs)
local function pageCount()
	if sessionactive then
		local n = (SeraphicSession and SeraphicSession.scores) and #SeraphicSession.scores or 0
		return math.max(1, math.ceil(n / scoresperpage))
	end
	return numrankingpages
end
-- prev/next page; text matches the bottom profile buttons (Common Large at 0.19)
local pageZoom = 0.19
r[#r + 1] = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(10, frameHeight - 12):visible(false)
	end,
	UpdateRankingMessageCommand = function(self)
		if (rankingSkillset > 1 or recentactive or sessionactive) and not showOnline then
			self:visible(true)
			if not self and self.GetChildren then
				for child in self:GetChildren() do
					child:queuecommand("Display")
				end
			end
		else
			self:visible(false)
		end
	end,
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(frameWidth - 20, 0):zoomto(56, 15):halign(1):diffuse(color("#000000")):diffusealpha(0.5)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				if rankingPage < pageCount() then
					rankingPage = rankingPage + 1
				else
					rankingPage = 1
				end
				BroadcastIfActive("UpdateRanking")
			end
		end,
		MouseOverCommand = function(self)
			local alpha = 0.7
			self:GetParent():GetChild("NextP"):diffusealpha(alpha)
		end,
		MouseOutCommand = function(self)
			local alpha = 1
			self:GetParent():GetChild("NextP"):diffusealpha(alpha)
		end,

	},
	LoadFont("Common Large") .. {
		Name = "NextP",
		InitCommand = function(self)
			self:x(frameWidth - 48):zoom(pageZoom):maxwidth(50 / pageZoom):diffuse(color(seraphicValueColor))
			self:settext(tostring(translated_info["NextPage"]):upper())
		end,
	},
	seraphicSoftEdge(frameWidth - 76, -7.5, 56, 15, 0.14),
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(-2, 0):zoomto(56, 15):halign(0):diffuse(color("#000000")):diffusealpha(0.5)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				if rankingPage > 1 then
					rankingPage = rankingPage - 1
				else
					rankingPage = pageCount()
				end
				BroadcastIfActive("UpdateRanking")
			end
		end,
		MouseOverCommand = function(self)
			local alpha = 0.7
			self:GetParent():GetChild("PrevP"):diffusealpha(alpha)
		end,
		MouseOutCommand = function(self)
			local alpha = 1
			self:GetParent():GetChild("PrevP"):diffusealpha(alpha)
		end,
	},
	LoadFont("Common Large") .. {
		Name = "PrevP",
		InitCommand = function(self)
			self:x(26):zoom(pageZoom):maxwidth(50 / pageZoom):diffuse(color(seraphicValueColor))
			self:settext(tostring(translated_info["PrevPage"]):upper())
		end,
	},
	seraphicSoftEdge(-2, -7.5, 56, 15, 0.14),
}

for i = 1, scoresperpage do
	r[#r + 1] = rankingLabel(i)
end

for i = 1, scoresperpage do
	r[#r + 1] = recentLabel(i)
end

-- Technically the "overall" skillset is used for single value display during music select/eval and isn't factored in to the profile rating
-- Only the specific skillsets are, and so overall should be used to display the specific skillset breakdowns separately - mina
for i = 1, #ms.SkillSets do
	r[#r + 1] = rankingButton(i)
end

local function sessionButton()
	return Def.ActorFrame {
		InitCommand = function(self)
			self:xy(frameWidth - 262, offsetY / 2)
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:zoomto(toggleW - 2, 15)
				styleToggleQuad(self, sessionactive)
			end,
			SetCommand = function(self)
				styleToggleQuad(self, sessionactive)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update then
					sessionactive = true
					recentactive = false
					percentactive = false
					rankingPage = 1
					BroadcastIfActive("UpdateRanking")
				end
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			MouseOverCommand = function(self)
				self:GetParent():GetChild("SessionButtonTxt"):diffusealpha(0.7)
			end,
			MouseOutCommand = function(self)
				self:GetParent():GetChild("SessionButtonTxt"):diffusealpha(1)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "SessionButtonTxt",
			OnCommand = function(self)
				hdrTextW[self:GetName()] = self:GetWidth()
				self:queuecommand("HdrFit")
			end,
			HdrFitCommand = hdrFit,
			InitCommand = function(self)
				self:zoom(labelZoom)
				styleToggleText(self, sessionactive)
				self:settext("SESSION")
			end,
			UpdateRankingMessageCommand = function(self)
				styleToggleText(self, sessionactive)
			end
		}
	}
end

r[#r + 1] = sessionButton()
-- shown in place of the list while no score has been set this session
r[#r + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameWidth / 2, listY + 40):zoom(0.45):diffuse(color(seraphicLabelColor)):visible(false)
		self:settext("No scores set this session yet")
	end,
	UpdateRankingMessageCommand = function(self)
		local n = (SeraphicSession and SeraphicSession.scores) and #SeraphicSession.scores or 0
		self:visible(sessionactive and update and n == 0)
	end
}
r[#r + 1] = recentButton()
r[#r + 1] = percentButton()

-- overview layout: compact skillset rows + ::TODAY chronicle on the left, skill sigil on the right,
-- one row of buttons along the bottom (all panel-local; the window is 288 tall)
local ovLeftX = 8
local ovLeftW = math.floor(frameWidth * 0.44)
local ratingPitch = 19
local ratingH = 17
local ratingY = listY + 2 -- top of the first rating row
local todayY = ratingY + 7 * ratingPitch + 5 -- top of the ::TODAY panel
local todayH = 72
local ovBottom = todayY + todayH -- bottom of the overview content (buttons go under it)

local function overviewVisible(self)
	self:visible(rankingSkillset == 1 and update and not recentactive and not sessionactive)
end

-- the rating a skillset row / sigil vertex shows (local or online)
local function skillsetRating(i)
	if showOnline then
		return DLMAN:GetSkillsetRating(ms.SkillSets[i]) or 0
	end
	if not profile then return 0 end
	return profile:GetPlayerSkillsetRating(ms.SkillSets[i]) or 0
end

-- skillset ratings: compact banded "LABEL ..... value" rows
local function littlebits(i)
	local rowY = ratingY + (i - 2) * ratingPitch + ratingH / 2
	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(0, rowY)
		end,
		UpdateRankingMessageCommand = function(self)
			overviewVisible(self)
		end,
		seraphicRowBand(ovLeftX, -ratingH / 2, ovLeftW, ratingH, i - 1),
		seraphicBullet(ovLeftX + 7, 0),
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:x(ovLeftX + 15):maxwidth((ovLeftW * 0.5 - 15) / 0.4):halign(0):zoom(0.4):diffuse(color(seraphicLabelColor))
			end,
			SetCommand = function(self)
				self:settext(tostring(ms.SkillSetsTranslated[i]):upper())
			end,
		},
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:x(ovLeftX + ovLeftW - 6):halign(1):zoom(0.26):maxwidth((ovLeftW * 0.5 - 8) / 0.26)
			end,
			SetCommand = function(self)
				local rating = skillsetRating(i)
				if not showOnline then
					self:settextf("%05.2f", rating)
				else
					self:settextf("%05.2f (#%i)", rating, DLMAN:GetSkillsetRank(ms.SkillSets[i]))
				end
				self:diffuse(byMSD(rating))
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			PlayerRatingUpdatedMessageCommand = function(self)
				self:queuecommand("Set")
			end
		}
	}
	return t
end

for i = 2, #ms.SkillSets do
	r[#r + 1] = littlebits(i)
end

-- SKILL SIGIL: the 7 skillset ratings as a heptagram/radar
local sigilLeft = ovLeftX + ovLeftW + 8
local sigilW = frameWidth - 8 - sigilLeft
local sigilCX = sigilLeft + sigilW / 2
local sigilCY = (listY + ovBottom) / 2
local sigilR = math.min(sigilW / 2 - 20, (ovBottom - listY) / 2 - 14)
local sigilN = #ms.SkillSets - 1
local fillCol = color("#9c142866")
local fillCenterCol = color("#9c142833")
local lineCol = color("#e8b8c2E6")
local faintCol = color("#bdb3b630")

local function sigilAngle(k) -- k = 1..7, first vertex straight up
	return -math.pi / 2 + (k - 1) * 2 * math.pi / sigilN
end
local function sigilPoint(k, rad)
	local a = sigilAngle(k)
	return math.cos(a) * rad, math.sin(a) * rad
end
-- short labels around the radar (Stream .. Technical)
local sigilAbbr = {"STREAM", "JS", "HS", "STAMINA", "JACK", "CJ", "TECH"}
-- vertex radii for the current ratings, scaled to the player's own min..max range
-- (weakest skillset sits at sigilFloor, strongest on the outer ring) so differences stand out
local sigilFloor = 0.6
local function sigilRadii()
	local vals, lo, hi, best = {}, math.huge, -math.huge, 1
	for k = 1, sigilN do
		vals[k] = skillsetRating(k + 1)
		if vals[k] < lo then lo = vals[k] end
		if vals[k] > hi then hi = vals[k]; best = k end
	end
	local radii = {}
	for k = 1, sigilN do
		local f = 1
		if hi - lo > 0.005 then
			f = sigilFloor + (1 - sigilFloor) * (vals[k] - lo) / (hi - lo)
		end
		radii[k] = sigilR * f
	end
	return radii, best
end
-- heptagon outline at a fixed radius (guide rings)
local function ringVerts(rad)
	local v = {}
	for k = 1, sigilN + 1 do
		local x, y = sigilPoint((k - 1) % sigilN + 1, rad)
		v[#v + 1] = {{x, y, 0}, faintCol}
	end
	return v
end

local sigil = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(sigilCX, sigilCY)
	end,
	UpdateRankingMessageCommand = function(self)
		overviewVisible(self)
		self:queuecommand("SigilSet")
	end,
	PlayerRatingUpdatedMessageCommand = function(self)
		self:queuecommand("SigilSet")
	end,
	SetCommand = function(self)
		self:queuecommand("SigilSet")
	end,
	-- guide rings at 50% / 100% and faint spokes
	Def.ActorMultiVertex {
		InitCommand = function(self)
			self:SetDrawState({Mode = "DrawMode_LineStrip"})
			self:SetLineWidth(1)
			self:SetVertices(ringVerts(sigilR))
		end
	},
	Def.ActorMultiVertex {
		InitCommand = function(self)
			self:SetDrawState({Mode = "DrawMode_LineStrip"})
			self:SetLineWidth(1)
			self:SetVertices(ringVerts(sigilR * 0.5))
		end
	},
	Def.ActorMultiVertex {
		InitCommand = function(self)
			local v = {}
			for k = 1, sigilN do
				local x, y = sigilPoint(k, sigilR)
				v[#v + 1] = {{0, 0, 0}, faintCol}
				v[#v + 1] = {{x, y, 0}, faintCol}
			end
			v[#v + 1] = {{0, 0, 0}, faintCol}
			-- spokes as one line strip that runs out to each point and back (there is no DrawMode_Lines)
			self:SetDrawState({Mode = "DrawMode_LineStrip"})
			self:SetLineWidth(1)
			self:SetVertices(v)
		end
	},
	-- translucent crimson fill
	Def.ActorMultiVertex {
		SigilSetCommand = function(self)
			local radii = sigilRadii()
			local v = {{{0, 0, 0}, fillCenterCol}}
			for k = 1, sigilN + 1 do
				local kk = (k - 1) % sigilN + 1
				local x, y = sigilPoint(kk, radii[kk])
				v[#v + 1] = {{x, y, 0}, fillCol}
			end
			self:SetDrawState({Mode = "DrawMode_Fan"})
			self:SetVertices(v)
		end
	},
	-- brighter outline
	Def.ActorMultiVertex {
		SigilSetCommand = function(self)
			local radii = sigilRadii()
			local v = {}
			for k = 1, sigilN + 1 do
				local kk = (k - 1) % sigilN + 1
				local x, y = sigilPoint(kk, radii[kk])
				v[#v + 1] = {{x, y, 0}, lineCol}
			end
			self:SetDrawState({Mode = "DrawMode_LineStrip"})
			self:SetLineWidth(1.5)
			self:SetVertices(v)
		end
	}
}
-- vertex diamonds and tip labels; the strongest skillset is picked out in crimson
for k = 1, sigilN do
	sigil[#sigil + 1] = Def.Quad {
		InitCommand = function(self)
			self:rotationz(45)
		end,
		SigilSetCommand = function(self)
			local radii, best = sigilRadii()
			local x, y = sigilPoint(k, radii[k])
			self:xy(x, y)
			if k == best then
				self:zoomto(7, 7):diffuse(color("#ff3355"))
			else
				self:zoomto(4, 4):diffuse(color("#f4ecee"))
			end
		end
	}
	sigil[#sigil + 1] = LoadFont("Common Normal") .. {
		InitCommand = function(self)
			local x, y = sigilPoint(k, sigilR + 12)
			self:xy(x, y):settext(sigilAbbr[k] or "")
		end,
		SigilSetCommand = function(self)
			local _, best = sigilRadii()
			if k == best then
				self:zoom(0.36):diffuse(color("#ff3355"))
			else
				self:zoom(0.3):diffuse(color(seraphicLabelColor))
			end
		end
	}
end
r[#r + 1] = sigil

-- ::SESSION chronicle (data from Scripts/05 SeraphicSession.lua)
local todayRows = {"Plays", "Avg Wife", "Best MSD", "Rating"}
local function todayValue(n)
	local s = SeraphicSession or {}
	local plays = s.plays or 0
	if n == 1 then
		return tostring(plays)
	elseif n == 2 then
		if plays > 0 then return string.format("%.2f%%", (s.wifeSum or 0) / plays * 100) end
		return "--"
	elseif n == 3 then
		if (s.bestSSR or 0) > 0 then return string.format("%.2f", s.bestSSR) end
		return "--"
	else
		local start = SeraphicSessionStartRating and SeraphicSessionStartRating()
		local now = SeraphicSessionCurrentRating and SeraphicSessionCurrentRating()
		if not now then return "--" end
		if not start then return string.format("%.2f", now) end
		return string.format("%.2f (%+.2f)", now, now - start)
	end
end
local today = Def.ActorFrame {
	UpdateRankingMessageCommand = function(self)
		overviewVisible(self)
	end,
	Def.Quad {
		InitCommand = function(self)
			self:xy(ovLeftX, todayY):halign(0):valign(0):zoomto(ovLeftW, todayH):diffuse(color("#000000")):diffusealpha(0.3)
		end
	},
	seraphicSoftEdge(ovLeftX, todayY, ovLeftW, todayH, 0.12),
	seraphicHeaderBand(ovLeftX, todayY, ovLeftW, 14),
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(ovLeftX + 6, todayY + 7):halign(0):zoom(0.38):diffuse(color(seraphicLabelColor))
			self:settext(seraphicHeading("Session"))
		end
	}
}
for n = 1, #todayRows do
	local y = todayY + 16 + (n - 1) * 14
	today[#today + 1] = seraphicRowBand(ovLeftX + 2, y, ovLeftW - 4, 13, n)
	today[#today + 1] = LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(ovLeftX + 8, y + 6.5):halign(0):zoom(0.36):maxwidth((ovLeftW * 0.45) / 0.36)
			self:diffuse(color(seraphicLabelColor)):settext(todayRows[n]:upper())
		end
	}
	today[#today + 1] = LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(ovLeftX + ovLeftW - 6, y + 6.5):halign(1):zoom(0.38):maxwidth((ovLeftW * 0.5) / 0.38)
			self:diffuse(color(seraphicValueColor))
		end,
		SetCommand = function(self)
			self:settext(todayValue(n))
		end,
		UpdateRankingMessageCommand = function(self)
			self:queuecommand("Set")
		end,
		PlayerRatingUpdatedMessageCommand = function(self)
			self:queuecommand("Set")
		end
	}
end
r[#r + 1] = today

local user
local pass
-- bottom buttons: one compact row along the bottom of the window
local pbCount = 5
local pbW = (frameWidth - 16 - (pbCount - 1) * 5) / pbCount
local pbH = 15
local function pbX(col) return frameX + 8 + pbW / 2 + (col - 1) * (pbW + 5) end
local function pbY(row) return frameY + frameHeight - 14 end
local function pbFrame(col, row)
	return Def.ActorFrame {
		Def.Quad {
			InitCommand = function(self)
				self:xy(pbX(col), pbY(row)):zoomto(pbW, pbH):diffuse(color("#000000")):diffusealpha(0.5)
			end
		},
		seraphicSoftEdge(pbX(col) - pbW / 2, pbY(row) - pbH / 2, pbW, pbH, 0.14)
	}
end
local function pbText(self, col, row, text)
	self:xy(pbX(col), pbY(row)):halign(0.5):diffuse(color(seraphicValueColor)):zoom(0.19):maxwidth((pbW - 6) / 0.19)
	self:settext(tostring(text):upper())
end
local profilebuttons = Def.ActorFrame {
	InitCommand = function(self)
	end,
	BeginCommand = function(self)
		user = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).UserName
		local passToken = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).PasswordToken
		if passToken ~= "" and answer ~= "" then
			if not DLMAN:IsLoggedIn() then
				DLMAN:LoginWithToken(user, passToken)
			end
		else
			passToken = ""
			user = ""
		end
	end,
	UpdateRankingMessageCommand = function(self)
		if rankingSkillset == 1 and update and not recentactive and not sessionactive then
			self:visible(true)
		else
			self:visible(false)
		end
	end,
	pbFrame(1, 1), pbFrame(2, 1), pbFrame(3, 1), pbFrame(4, 1), pbFrame(5, 1),
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			pbText(self, 1, 1, translated_info["Save"])
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and update and rankingSkillset == 1 and not recentactive and not sessionactive then
				if PROFILEMAN:SaveProfile(PLAYER_1) then
					ms.ok(translated_info["Success"])
					STATSMAN:UpdatePlayerRating()
				else
					ms.ok(translated_info["Failure"])
				end
			end
		end
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			pbText(self, 2, 1, translated_info["AssetSettings"])
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and update and rankingSkillset == 1 and not recentactive and not sessionactive then
				SCREENMAN:SetNewScreen("ScreenAssetSettings")
			end
		end,
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			pbText(self, 3, 1, translated_info["ValidateAll"])
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and update and rankingSkillset == 1 and not recentactive and not sessionactive then
				profile:UnInvalidateAllScores()
				STATSMAN:UpdatePlayerRating()
			end
		end,
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			pbText(self, 4, 1, translated_info["ForceRecalc"])
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and update and rankingSkillset == 1 and not recentactive and not sessionactive  then
				ms.ok("Recalculating Scores... this might be slow and may or may not crash")
				profile:ForceRecalcScores()
				STATSMAN:UpdatePlayerRating()
			end
		end,
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			pbText(self, 5, 1, translated_info["UploadAllScore"])
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and update and rankingSkillset == 1 and not recentactive and not sessionactive  then
				if DLMAN:IsLoggedIn() then
					DLMAN:UploadAllScores()
				else
					ms.ok("You must be logged in...")
				end
			end
		end,
	},
}

t[#t + 1] = profilebuttons
t[#t + 1] = r
return t
