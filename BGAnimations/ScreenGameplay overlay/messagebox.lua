local settext = BitmapText.settext

local function highlight(self)
	self:queuecommand("Highlight")
end

local function highlightIfOver(self)
	if isOver(self) then
		self:diffusealpha(0.2)
	else
		self:diffusealpha(1)
	end
end

local function transStr(line)
	return THEME:GetString("CustomizeGameplay", line)
end

return Def.ActorFrame {
	OnCommand = function(self)
		if SCREENMAN:GetTopScreen():GetName() == "ScreenGameplaySyncMachine" then 
			self:visible(false)
		end
		SCREENMAN:GetTopScreen():AddInputCallback(MovableInput)
		self:SetUpdateFunction(highlight)
	end,
	OffCommand = function(self)
		-- save CustomizeGameplay changes when leaving the screen
		playerConfig:save(pn_to_profile_slot(PLAYER_1))
	end,
	Def.BitmapText {
		Name = "message",
		Font = "Common Normal",
		InitCommand = function(self)
			Movable.message = self
			self:horizalign(left):vertalign(top):shadowlength(2):xy(10, 20):zoom(.5):visible(false)
		end
	},
	Def.BitmapText {
		Name = "Instructions",
		Font = "Common Normal",
		InitCommand = function(self)
			self:horizalign(left):vertalign(top):xy(SCREEN_WIDTH - 240, 20):zoom(.375):visible(true)
		end,
		HighlightCommand = function(self)
			highlightIfOver(self)
		end,
		OnCommand = function(self)
			-- next frame, once every element has said whether it is enabled
			self:queuecommand("CustomizeGameplaySelectionMessage")
		end,
		CustomizeGameplaySelectionMessageCommand = function(self)
			local text = {
				transStr("InstructionAutoplay"),
				transStr("InstructionSelect"),
				transStr("InstructionMouse"),
				transStr("InstructionMode"),
				transStr("InstructionArrows"),
				transStr("InstructionUndo"),
				transStr("InstructionReset"),
				transStr("InstructionCancel"),
			}
			if playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).LaneCover ~= 0 then
				local selectStr = THEME:GetString("GameButton", "Select")
				table.insert(text, selectStr..": "..transStr("LaneCoverHeight"))
			end
			text[#text + 1] = ""
			local labels, selected = getMovableElementList()
			for i, label in ipairs(labels) do
				text[#text + 1] = (i == selected and "> " or "   ")..label
			end
			self:settext(table.concat(text, "\n"))
		end
	}
}
