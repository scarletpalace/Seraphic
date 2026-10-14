
-- Seraphic: the search box is a dark band, crimson-tinted while typing
local function diffuseIfActiveButton(self, cond)
	if cond then
		self:diffuse(color("#3a0c16"))
	else
		self:diffuse(color("#000000"))
	end
end

local function diffuseIfActiveText(self, cond)
	if cond then
		self:diffuse(color(seraphicValueColor))
	else
		self:diffuse(color("#7d7579"))
	end
end

local activealpha = 0.8
local inactivealpha = 0.6
local highlightalpha = 0.75

local translated_info = {
	CancelCurrent = THEME:GetString("ScreenPackDownloader", "CancelCurrentDownload"),
	CancelAll = THEME:GetString("ScreenPackDownloader", "CancelAllDownloads"),
	SearchName = THEME:GetString("ScreenPackDownloader", "SearchingName"),
	SizeExplanation = THEME:GetString("ScreenPackDownloader", "ExplainSizeLimit")
}

local width = SCREEN_WIDTH / 3
local fontScale = 0.5
local packh = 30
local packgap = 4
local packspacing = packh + packgap
local offx = 10
local offy = 40

local fx = SCREEN_WIDTH / 4.5 -- this isnt very smart alignment
local f0y = 160
local f1y = f0y + 40
local f2y = f1y + 40
local fdot = 24

local tagFrameWidth = SCREEN_WIDTH / 3
local cancelButtonSpace = 4
local leftSpace = 10
local cancelFrameY = 56

-- Seraphic window layout (854x480 at 16:9)
local winTop = 14 -- top of every window
local winBottom = SCREEN_HEIGHT - 10 -- bottom of the tag filter and pack windows
local headH = 20 -- header band height
local winGap = 10
local btnH = 24 -- cancel buttons
local smallBtnH = 22 -- apply / reset / or
local dlWinH = headH + 6 + btnH + 8 -- "pack downloads" window
local tagTop = winTop + dlWinH + winGap -- tag filter window top
local rightX = leftSpace + tagFrameWidth + winGap -- pack search / table window
local rightW = SCREEN_WIDTH - 10 - rightX
local tableY = tagTop -- pack table top (lines up with the tag filter window)
local labelZoomL = 0.21 -- Common Large zoom for small labels (= Common Normal 0.42)
local accent = "#9c1428"

-- translucent dark window body with a faint filigree footer and a soft 1px edge
local function windowQuad(x, y, w, h, name)
	return Def.Quad {
		Name = name,
		InitCommand = function(self)
			self:xy(x, y):halign(0):valign(0):zoomto(w, h)
			self:diffuseupperleft(color("#262626E6")):diffuseupperright(color("#1a1a1aE6"))
			self:diffuselowerleft(color("#0a0a0aF0")):diffuselowerright(color("#060606F0"))
			self:diffusealpha(0.7)
		end
	}
end
local function windowDecor(x, y, w, h)
	return Def.ActorFrame {
		Def.Sprite {
			Texture = THEME:GetPathG("", "seraphic_filigree"),
			InitCommand = function(self)
				self:xy(x + 4, y + h - 3):halign(0):valign(1):zoomto(w - 8, 30):diffusealpha(0.18)
			end
		},
		seraphicSoftEdge(x, y, w, h)
	}
end
local function windowBody(x, y, w, h)
	return Def.ActorFrame { windowQuad(x, y, w, h), windowDecor(x, y, w, h) }
end

-- "::HEADING" text vertically centred in a header band
local function headingText(x, y, text)
	return LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(x, y + headH / 2):halign(0):zoom(0.45):diffuse(color(seraphicLabelColor))
			self:settext(seraphicHeading(text))
		end
	}
end

-- thin crimson rule under a button (top-left anchored at x, y)
local function crimsonRule(x, y, w)
	return Def.Quad {
		InitCommand = function(self)
			self:xy(x, y):halign(0):valign(0):zoomto(w, 1)
			self:diffuseleftedge(color("#9c1428E6")):diffuserightedge(color("#9c142830"))
		end
	}
end

-- dark band button: silver uppercase text, crimson-tinted band on hover
local function styleButton(self, w, h, text)
	self.txt:xy(w / 2, h / 2)
	self.txt:valign(0.5)
	self.txt:settext(text:upper())
	self.txt:zoom(labelZoomL)
	self.txt:maxwidth((w - 8) / labelZoomL)
	self.bg:zoomto(w, h)
	self.bg:halign(0):valign(0)
	self.alphaDeterminingFunction = function(self)
		if isOver(self.bg) then
			self.bg:diffuse(color("#4a0e1a")):diffusealpha(0.8)
			self.txt:diffuse(color(seraphicValueColor))
		else
			self.bg:diffuse(color("#000000")):diffusealpha(0.55)
			self.txt:diffuse(color(seraphicLabelColor))
		end
	end
	self:alphaDeterminingFunction()
end

local selectedTags = {}
local tagsMatchAny = true
local nameInput = ""

local o = Def.ActorFrame {
	Name = "MainFrame",
	InitCommand = function(self)
		self:xy(0, 0):halign(0.5):valign(0)
		self:GetChild("PacklistDisplay"):xy(rightX + 4, tableY)
	end,
	WheelUpSlowMessageCommand = function(self)
		self:queuecommand("PrevPage")
	end,
	WheelDownSlowMessageCommand = function(self)
		self:queuecommand("NextPage")
	end,
	UpdateFilterDisplaysMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	FilterChangedMessageCommand = function(self)
		self:queuecommand("PackTableRefresh")
	end,
	MouseRightClickMessageCommand = function(self)
		SCREENMAN:GetTopScreen():Cancel()
	end,

}

-- sanctuary backdrop, dimmed so it stays behind the windows
o[#o + 1] = LoadActor("_sanctuary", SCREEN_CENTER_Y)
o[#o + 1] = Def.Quad {
	InitCommand = function(self)
		self:FullScreen():diffuse(color("#000000")):diffusealpha(0.35)
	end
}

-- right window: pack search + pack table
o[#o + 1] = Def.ActorFrame {
	Name = "PackWindow",
	windowBody(rightX, winTop, rightW, winBottom - winTop),
	seraphicHeaderBand(rightX, winTop, rightW, headH),
	headingText(rightX + 8, winTop, "Pack Search"),
}

local dlBtnW = (tagFrameWidth - 18) / 2

o[#o+1] = Def.ActorFrame {
	Name = "LeftButtonFrame",
	InitCommand = function(self)
		self:xy(leftSpace, winTop)
	end,

	windowBody(0, 0, tagFrameWidth, dlWinH),
	seraphicHeaderBand(0, 0, tagFrameWidth, headH),
	LoadFont("Common Normal") .. {
		Name = "TitleText",
		InitCommand = function(self)
			self:xy(8, headH / 2):halign(0)
			self:zoom(0.45)
			self:maxwidth((tagFrameWidth - 16) / 0.45)
			self:diffuse(color(seraphicLabelColor))
			self:settext(seraphicHeading("Pack Downloads"))
		end
	},
	crimsonRule(6, headH + 6 + btnH, dlBtnW),
	crimsonRule(12 + dlBtnW, headH + 6 + btnH, dlBtnW),
	UIElements.TextButton(1, 1, "Common Large") .. {
		Name = "StopAllDownloadsButton",
		InitCommand = function(self)
			self.txt = self:GetChild("Text")
			self.bg = self:GetChild("BG")

			self:xy(6, headH + 6)
			styleButton(self, dlBtnW, btnH, translated_info["CancelAll"])
		end,
		RolloverUpdateCommand = function(self, params)
			self:alphaDeterminingFunction()
		end,
		ClickCommand = function(self, params)
			if params.update == "OnMouseDown" then
				local count = 0
				for _, p in ipairs(DLMAN:GetQueuedPacks()) do
					local s = p:RemoveFromQueue()
					if s then count = count + 1 end
				end
				for _, p in ipairs(DLMAN:GetDownloadingPacks()) do
					p:GetDownload():Stop()
					count = count + 1
				end
				if count > 0 then
					ms.ok("Stopped All Downloads: "..count.." Downloads")
				end
			end
		end,
	},
	UIElements.TextButton(1, 1, "Common Large") .. {
		Name = "StopCurrentDownloadButton",
		InitCommand = function(self)
			self.txt = self:GetChild("Text")
			self.bg = self:GetChild("BG")

			self:xy(12 + dlBtnW, headH + 6)
			styleButton(self, dlBtnW, btnH, translated_info["CancelCurrent"])
		end,
		RolloverUpdateCommand = function(self, params)
			self:alphaDeterminingFunction()
		end,
		ClickCommand = function(self, params)
			if params.update == "OnMouseDown" then
				local dl = DLMAN:GetDownloads()[1]
				if dl then
					dl:Stop()
				end
			end
		end,
	},
}

local function unbundleize(bundlestr)
	local bundleWord = "Bundle: "
	if bundlestr:find(bundleWord) ~= nil then
		bundlestr = bundlestr:sub(#bundleWord+1):lower()
	end
	return bundlestr
end

local function tagframe()
	local maxtags = 12
	local curpage = 1

	local frameBGHeight = winBottom - tagTop
	local frameBGWidth = SCREEN_WIDTH / 3
	local tagSpacing = 2
	local tagListStartY = headH + 24 + smallBtnH + 8
	local tagHeight = (frameBGHeight - tagListStartY - 8) / maxtags - tagSpacing
	local tagWidth = frameBGWidth - 12
	local tagTextSize = 0.42
	local btn3W = (frameBGWidth - 24) / 3
	local btnRowY = headH + 24

	local orderedTags = {}
	local function loadTags()
		local alltags = DLMAN:GetPackTags()
		local skillsetTags = table.sorted(alltags["global_skillset"] or {})
		local keycountTags = table.sorted(alltags["global_keyCount"] or {}, function(a,b)
			local ax = a:sub(1, #a-1)
			local bx = b:sub(1, #b-1)
			return tonumber(ax) < tonumber(bx)
		end)
		local otherTags = table.sorted(alltags["pack_tag"] or {})
		local bundleTags = table.withfuncapplied(alltags["pack_bundle"] or {}, function(key,val)
			return key, "Bundle: " .. val:sub(1,1):upper() .. val:sub(2)
		end)
		orderedTags = table.combine(keycountTags, skillsetTags, otherTags, bundleTags)
	end
	loadTags()

	local function movePage(n)
		local newpage = curpage + n
		local maxpage = math.ceil(#orderedTags / maxtags)
		if newpage < 1 then
			newpage = maxpage
		elseif newpage > maxpage then
			newpage = 1
		end
		curpage = newpage
		MESSAGEMAN:Broadcast("SetTagPage")
	end

	local t = Def.ActorFrame {
		Name = "TagFrame",
		InitCommand = function(self)
			self:xy(leftSpace, tagTop)
		end,
		BeginCommand = function(self)
			SCREENMAN:GetTopScreen():AddInputCallback(function(event)
				if isOver(self:GetChild("BG")) then
					if event.type == "InputEventType_FirstPress" then
						if event.DeviceInput.button == "DeviceButton_mousewheel up" then
							movePage(-1)
						elseif event.DeviceInput.button == "DeviceButton_mousewheel down" then
							movePage(1)
						end
					end
				end
			end)
			self:playcommand("UpdateTags")
		end,
		SetTagPageMessageCommand = function(self)
			self:playcommand("UpdateTags")
		end,
		PackTagsRefreshedMessageCommand = function(self)
			loadTags()
		end,
	
		-- window body; also the mouse wheel area for paging tags
		windowQuad(0, 0, frameBGWidth, frameBGHeight, "BG"),
		windowDecor(0, 0, frameBGWidth, frameBGHeight),
		seraphicHeaderBand(0, 0, frameBGWidth, headH),
		headingText(8, 0, "Tag Filter"),
		crimsonRule(6, btnRowY + smallBtnH, btn3W),
		crimsonRule(12 + btn3W, btnRowY + smallBtnH, btn3W),
		crimsonRule(18 + btn3W * 2, btnRowY + smallBtnH, btn3W),
		LoadFont("Common Large") .. {
			Name = "TagExplain",
			InitCommand = function(self)
				self:settext("Select tags to filter packs")
				self:zoom(0.18)
				self:valign(0.5)
				self:xy(frameBGWidth/2, headH + 12)
				self:maxwidth((frameBGWidth - 16) / 0.18)
				self:diffuse(color(seraphicLabelColor))
			end,
		},
		LoadFont("Common Large") .. {
			Name = "PageNum",
			InitCommand = function(self)
				self:zoom(0.18)
				self:valign(0.5):halign(1)
				self:xy(frameBGWidth - 8, headH / 2)
				self:diffuse(color(seraphicValueColor))
			end,
			UpdateTagsCommand = function(self)
				self:settextf("%d-%d of %d", (curpage-1) * maxtags + 1, math.min(#orderedTags, curpage * maxtags), #orderedTags)
			end,
		},
		UIElements.TextButton(1, 1, "Common Large") .. {
			Name = "ApplyButton",
			InitCommand = function(self)
				self.bg = self:GetChild("BG")
				self.txt = self:GetChild("Text")
				self:xy(6, btnRowY)
				styleButton(self, btn3W, smallBtnH, "Apply")
			end,
			RolloverUpdateCommand = function(self, params)
				self:alphaDeterminingFunction()
			end,
			ClickCommand = function(self, params)
				if params.update ~= "OnMouseDown" then return end
				local tags = {}
				for k,v in pairs(selectedTags) do
					if v == true then
						tags[#tags+1] = unbundleize(k)
					end
				end
				MESSAGEMAN:Broadcast("InvokePackSearch", {name=nameInput, tags=tags, tagsMatchAny=tagsMatchAny})
			end,
		},
		UIElements.TextButton(1, 1, "Common Large") .. {
			Name = "ResetButton",
			InitCommand = function(self)
				self.bg = self:GetChild("BG")
				self.txt = self:GetChild("Text")
				self:xy(12 + btn3W, btnRowY)
				styleButton(self, btn3W, smallBtnH, "Reset")
			end,
			RolloverUpdateCommand = function(self, params)
				self:alphaDeterminingFunction()
			end,
			ClickCommand = function(self, params)
				if params.update ~= "OnMouseDown" then return end
				selectedTags = {}
				self:GetParent():playcommand("UpdateTags")
				MESSAGEMAN:Broadcast("InvokePackSearch", {name=nameInput, tags={}, tagsMatchAny=tagsMatchAny})
			end,
		},
		UIElements.TextButton(1, 1, "Common Large") .. {
			Name = "ANDORButton",
			InitCommand = function(self)
				self.bg = self:GetChild("BG")
				self.txt = self:GetChild("Text")
				self:xy(18 + btn3W * 2, btnRowY)
				styleButton(self, btn3W, smallBtnH, tagsMatchAny and "OR" or "AND")
			end,
			RolloverUpdateCommand = function(self, params)
				self:alphaDeterminingFunction()
			end,
			ClickCommand = function(self, params)
				if params.update ~= "OnMouseDown" then return end
				tagsMatchAny = not tagsMatchAny
				self.txt:settext(tagsMatchAny and "OR" or "AND")
				local tags = {}
				for k,v in pairs(selectedTags) do
					if v == true then
						tags[#tags+1] = unbundleize(k)
					end
				end
				MESSAGEMAN:Broadcast("InvokePackSearch", {name=nameInput, tags=tags, tagsMatchAny=tagsMatchAny})
			end,
		},
	}

	local function tagentry(i)
		local tagtxt = nil
		return UIElements.TextButton(1, 1, "Common Normal") .. {
			Name = "Tag"..i,
			InitCommand = function(self)
				self.bg = self:GetChild("BG")
				self.txt = self:GetChild("Text")

				self:xy(
					tagFrameWidth/2,
					tagListStartY + tagHeight/2 + tagSpacing + (i-1) * (tagHeight + tagSpacing)
				)

				self.bg:zoomto(tagWidth, tagHeight)
				self.txt:zoom(tagTextSize)
				self.txt:maxwidth((tagWidth - 10) / tagTextSize)
				self.bg:diffuse(color("#000000FF"))

				-- alternating dark bands; a selected tag is a crimson-tinted band with bright text
				self.alphaDeterminingFunction = function(self)
					local over = isOver(self.bg)
					if selectedTags[tagtxt] then
						self.bg:diffuse(color("#6a1020")):diffusealpha(over and 0.9 or 0.7)
						self.txt:diffuse(color(seraphicValueColor))
					else
						self.bg:diffuse(color("#000000")):diffusealpha(over and 0.65 or (i % 2 == 1 and 0.4 or 0.15))
						self.txt:diffuse(color(over and seraphicValueColor or seraphicLabelColor))
					end
				end
				self:alphaDeterminingFunction()
			end,
			UpdateTagsCommand = function(self)
				tagtxt = orderedTags[i + ((curpage-1) * maxtags)]

				if tagtxt then
					self:visible(true)
					self.txt:settextf("%s", tagtxt)
				else
					self:visible(false)
				end
				self:alphaDeterminingFunction()
			end,
			RolloverUpdateCommand = function(self, params)
				self:alphaDeterminingFunction()
			end,
			ClickCommand = function(self, params)
				if params.update ~= "OnMouseDown" then return end
				if selectedTags[tagtxt] == true then
					selectedTags[tagtxt] = nil
				else
					selectedTags[tagtxt] = true
				end
				self:alphaDeterminingFunction()
			end,
		}
	end

	for i=1,maxtags do
		t[#t+1] = tagentry(i)
	end

	return t
end
o[#o+1] = tagframe()

local namex = rightX + 54 -- box left edge; the "NAME:" label sits to its left
local namey = winTop + headH + 15
local nhite = 22
local nameoffx = 8
local nboxw = rightX + rightW - 8 - namex
local inputting = 0

-- name string search
o[#o + 1] = Def.ActorFrame {
	Name = "TextEntryFrame",
	InitCommand = function(self)
		self:xy(namex, namey):halign(0):valign(0)
	end,
	BeginCommand = function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(function(event)
			if event.type ~= "InputEventType_Release" then
				local btn = event.DeviceInput.button
				local shift = INPUTFILTER:IsShiftPressed()
				local ctrl = INPUTFILTER:IsControlPressed()

				if btn == "DeviceButton_enter" or event.button == "Start" then
					-- invoke search
					local tags = {}
					for k,v in pairs(selectedTags) do
						if v == true then
							tags[#tags+1] = unbundleize(k)
						end
					end
					MESSAGEMAN:Broadcast("InvokePackSearch", {name=nameInput, tags=tags, tagsMatchAny=tagsMatchAny})
				else
					local del = btn == "DeviceButton_delete"
					local bs = btn == "DeviceButton_backspace"
					local back = btn == "DeviceButton_escape"
					local copypasta = btn == "DeviceButton_v" and ctrl
					local char = inputToCharacter(event)

					-- paste
					if copypasta then
						char = Arch.getClipboard()
					end

					if bs then
						nameInput = nameInput:sub(1, -2)
					elseif back then
						SCREENMAN:GetTopScreen():Cancel()
					elseif del then
						nameInput = ""
					elseif char then
						nameInput = nameInput .. char
					else
						return
					end

					self:playcommand("Set")

				end
			end
		end)
	end,
	UIElements.QuadButton(1, 1) .. {
		Name = "SearchBox",
		InitCommand = function(self)
			self:zoomto(nboxw, nhite):halign(0)
			self:diffusealpha(inactivealpha)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				inputting = 1
				curInput = ""
				self:GetParent():GetParent():queuecommand("Set")
				self:diffusealpha(activealpha)
				SCREENMAN:set_input_redirected(PLAYER_1, true)
			end
		end,
		SetCommand = function(self)
			diffuseIfActiveButton(self, inputting == 1)
			if isOver(self) then
				self:diffusealpha(highlightalpha)
			else
				self:diffusealpha(inactivealpha)
			end
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(highlightalpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(inactivealpha)
		end,
	},
	seraphicSoftEdge(0, -nhite / 2, nboxw, nhite, 0.15),
	-- crimson rule under the box while typing
	Def.Quad {
		Name = "SearchActiveRule",
		InitCommand = function(self)
			self:xy(0, nhite / 2):halign(0):valign(0):zoomto(nboxw, 1)
			self:diffuseleftedge(color("#9c1428E6")):diffuserightedge(color("#9c142830"))
			self:visible(false)
		end,
		SetCommand = function(self)
			self:visible(inputting == 1)
		end,
	},
	LoadFont("Common Large") .. {
		Name = "UserInputText",
		InitCommand = function(self)
			self:x(nameoffx):halign(0)
			self:zoom(0.22)
			self:maxwidth((nboxw - nameoffx * 2) / 0.22)
		end,
		SetCommand = function(self)
			local fval = nameInput
			self:settext(fval)
			diffuseIfActiveText(self, fval ~= "" or inputting == 1)
		end,
	},
	LoadFont("Common Large") .. {
		Name = "SearchLabel",
		InitCommand = function(self)
			self:xy(-6, 0)
			self:halign(1)
			self:zoom(labelZoomL)
			self:maxwidth((namex - rightX - 12) / labelZoomL)
			self:diffuse(color(seraphicLabelColor))
			self:settextf("%s:", translated_info["SearchName"]:upper())
		end,
	},
	LoadFont("Common Normal") .. {
		Name = "PackSizeRestrictionLabel",
		InitCommand = function(self)
			self:xy(rightX + 8 - namex, nhite / 2 + 11):halign(0):valign(0.5)
			self:zoom(0.34)
			self:maxwidth((rightW - 16) / 0.34)
			self:diffuse(color("#8a8285"))
			self:settextf("%s", translated_info["SizeExplanation"])
		end,
	}
}

o[#o + 1] = LoadActor("packlistDisplay")

return o
