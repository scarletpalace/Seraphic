-- Seraphic: multiplayer room player list, a panel in the top bar right of the Music Select logo.
-- Each player gets a diamond and a name colored by state: green ready, pink not ready,
-- grey playing, silver in options, white on the results screen.
local boxX = 272
local boxY = 8
local boxW = 224
local boxH = 56
local headerH = 13
local padX = 8
local bodyTop = boxY + headerH + 3
local bodyH = boxY + boxH - 5 - bodyTop
local maxUsers = 20

local top
local posit = getMainColor("positive")
local negat = getMainColor("negative")
local enable = getMainColor("enabled")
local disabled = getMainColor("disabled")
local highlight = getMainColor("highlight")

-- columns, rows and text zoom for a given player count
local function gridFor(qty)
	if qty <= 6 then
		return 2, 3, 0.42
	elseif qty <= 12 then
		return 3, 4, 0.36
	end
	return 4, 5, 0.3
end

local function userQty()
	if not top or not top.GetUserQty then return 0 end
	return math.min(top:GetUserQty(), maxUsers)
end

local function userColor(num)
	local state = top:GetUserState(num)
	if state == 3 then
		return posit -- eval
	elseif state == 2 then
		return disabled -- playing
	elseif state == 4 then
		return highlight -- options
	end
	return top:GetUserReady(num) and enable or negat
end

local r =
	Def.ActorFrame {
	BeginCommand = function(self)
		self:queuecommand("Set")
	end,
	-- queued so the screen exists; playcommand reaches every slot
	SetCommand = function(self)
		top = SCREENMAN:GetTopScreen()
		if not top or top:GetName() ~= "ScreenNetSelectMusic" then
			top = nil
		end
		self:playcommand("Refresh")
	end,
	UsersUpdateMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	PlayerJoinedMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	PlayerUnjoinedMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	-- panel body only, no border
	Def.Quad {
		InitCommand = function(self)
			self:xy(boxX, boxY):halign(0):valign(0):zoomto(boxW, boxH)
			self:diffuseupperleft(color("#262626E6")):diffuseupperright(color("#1a1a1aE6"))
			self:diffuselowerleft(color("#0a0a0aF0")):diffuselowerright(color("#060606F0"))
			self:diffusealpha(0.85)
		end
	},
	seraphicHeaderBand(boxX + 4, boxY + 4, boxW - 8, headerH - 2),
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(boxX + padX, boxY + 4 + (headerH - 2) / 2):halign(0):zoom(0.36)
			self:diffuse(color(seraphicLabelColor)):settext(seraphicHeading("Players"))
		end
	},
	-- "ready / total" on the right of the header
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(boxX + boxW - padX, boxY + 4 + (headerH - 2) / 2):halign(1):zoom(0.36)
			self:diffuse(color(seraphicValueColor))
		end,
		RefreshCommand = function(self)
			local qty = userQty()
			local ready = 0
			for i = 1, qty do
				if userColor(i) == enable then
					ready = ready + 1
				end
			end
			self:settextf("%d/%d READY", ready, qty)
			self:diffuse(qty > 0 and ready == qty and enable or color(seraphicValueColor))
		end
	}
}

local function userSlot(i)
	local cell = {}
	return Def.ActorFrame {
		RefreshCommand = function(self)
			local qty = userQty()
			if i > qty then
				self:visible(false)
				return
			end
			local cols, rows, zoom = gridFor(qty)
			local colW = (boxW - padX * 2) / cols
			local rowH = bodyH / rows
			local col = (i - 1) % cols
			local row = math.floor((i - 1) / cols)
			self:visible(row < rows)
			self:xy(boxX + padX + col * colW, bodyTop + row * rowH + rowH / 2)
			local c = userColor(i)
			cell.dot:diffuse(c)
			cell.name:zoom(zoom):maxwidth((colW - 12) / zoom):settext(top:GetUser(i)):diffuse(c)
		end,
		Def.Quad {
			InitCommand = function(self)
				cell.dot = self
				self:x(2):rotationz(45):zoomto(3.5, 3.5)
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				cell.name = self
				self:x(8):halign(0)
			end
		}
	}
end

for i = 1, maxUsers do
	r[#r + 1] = userSlot(i)
end

return r
