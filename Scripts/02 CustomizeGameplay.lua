local keymode
local allowedCustomization
local usingReverse

MovableValues = {}

local function loadValuesTable()
	allowedCustomization = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).CustomizeGameplay
	usingReverse = GAMESTATE:GetPlayerState():GetCurrentPlayerOptions():UsingReverse()
	MovableValues.JudgeX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].JudgeX
	MovableValues.JudgeY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].JudgeY
	MovableValues.JudgeZoom = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].JudgeZoom
	MovableValues.ComboX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].ComboX
	MovableValues.ComboY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].ComboY
	MovableValues.ComboZoom = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].ComboZoom
	MovableValues.ErrorBarX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].ErrorBarX
	MovableValues.ErrorBarY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].ErrorBarY
	MovableValues.ErrorBarWidth = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].ErrorBarWidth
	MovableValues.ErrorBarHeight = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].ErrorBarHeight
	MovableValues.TargetTrackerX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].TargetTrackerX
	MovableValues.TargetTrackerY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].TargetTrackerY
	MovableValues.TargetTrackerZoom = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].TargetTrackerZoom
	MovableValues.FullProgressBarX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].FullProgressBarX
	MovableValues.FullProgressBarY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].FullProgressBarY
	MovableValues.FullProgressBarWidth = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].FullProgressBarWidth
	MovableValues.FullProgressBarHeight = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].FullProgressBarHeight
	MovableValues.MiniProgressBarX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].MiniProgressBarX
	MovableValues.MiniProgressBarY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].MiniProgressBarY
	MovableValues.DisplayPercentX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].DisplayPercentX
	MovableValues.DisplayPercentY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].DisplayPercentY
	MovableValues.DisplayPercentZoom = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].DisplayPercentZoom
	MovableValues.DisplayMeanX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].DisplayMeanX
	MovableValues.DisplayMeanY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].DisplayMeanY
	MovableValues.DisplayMeanZoom = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].DisplayMeanZoom
	MovableValues.NotefieldX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].NotefieldX
	MovableValues.NotefieldY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].NotefieldY
	MovableValues.NotefieldWidth = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].NotefieldWidth
	MovableValues.NotefieldHeight = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].NotefieldHeight
	MovableValues.NotefieldSpacing = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].NotefieldSpacing
	MovableValues.JudgeCounterX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].JudgeCounterX
	MovableValues.JudgeCounterY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].JudgeCounterY
	MovableValues.ReplayButtonsX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].ReplayButtonsX
	MovableValues.ReplayButtonsY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].ReplayButtonsY
	MovableValues.ReplayButtonsSpacing = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].ReplayButtonsSpacing
	MovableValues.ReplayButtonsZoom = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].ReplayButtonsZoom
	MovableValues.NPSGraphX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].NPSGraphX
	MovableValues.NPSGraphY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].NPSGraphY
	MovableValues.NPSGraphWidth = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].NPSGraphWidth
	MovableValues.NPSGraphHeight = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].NPSGraphHeight
	MovableValues.NPSDisplayX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].NPSDisplayX
	MovableValues.NPSDisplayY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].NPSDisplayY
	MovableValues.NPSDisplayZoom = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].NPSDisplayZoom
	MovableValues.LeaderboardX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].LeaderboardX
	MovableValues.LeaderboardY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].LeaderboardY
	MovableValues.LeaderboardSpacing = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].LeaderboardSpacing
	MovableValues.LeaderboardWidth = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].LeaderboardWidth
	MovableValues.LeaderboardHeight = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].LeaderboardHeight
	MovableValues.LifeP1X = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].LifeP1X
	MovableValues.LifeP1Y = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].LifeP1Y
	MovableValues.LifeP1Rotation = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].LifeP1Rotation
	MovableValues.LifeP1Width = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].LifeP1Width
	MovableValues.LifeP1Height = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].LifeP1Height
	MovableValues.PracticeCDGraphX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].PracticeCDGraphX
	MovableValues.PracticeCDGraphY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].PracticeCDGraphY
	MovableValues.PracticeCDGraphHeight = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].PracticeCDGraphHeight
	MovableValues.PracticeCDGraphWidth = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].PracticeCDGraphWidth
	MovableValues.BPMTextX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].BPMTextX
	MovableValues.BPMTextY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].BPMTextY
	MovableValues.BPMTextZoom = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].BPMTextZoom
	MovableValues.MusicRateX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].MusicRateX
	MovableValues.MusicRateY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].MusicRateY
	MovableValues.MusicRateZoom = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].MusicRateZoom
	MovableValues.PaceMakerX = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].PaceMakerX
	MovableValues.PaceMakerY = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplayXYCoordinates[keymode].PaceMakerY
	MovableValues.PaceMakerZoom = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).GameplaySizes[keymode].PaceMakerZoom
end

function unsetMovableKeymode()
	MovableValues = {}
end

function setMovableKeymode(key)
	keymode = key
	loadValuesTable()
end

local Round = notShit.round
local Floor = notShit.floor
local queuecommand = Actor.queuecommand
local playcommand = Actor.queuecommand
local settext = BitmapText.settext

local propsFunctions = {
	X = Actor.x,
	Y = Actor.y,
	Zoom = Actor.zoom,
	Height = Actor.zoomtoheight,
	Width = Actor.zoomtowidth,
	AddX = Actor.addx,
	AddY = Actor.addy,
	Rotation = Actor.rotationz,
}

Movable = {
	message = {},
	current = "None",
	pressed = false,
	JudgePosition = {
		name = "Judge",
		textHeader = "Judgment Label Position:",
		element = {},
		children = {"Judgment", "Border"},
		properties = {"X", "Y"},
		propertyOffsets = nil,	-- manual offsets for stuff hardcoded to be relative to center and maybe other things (init in wifejudgmentspotting)
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -5
		},
		DeviceButton_down = {
			property = "Y",
			inc = 5
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	JudgeSize = {	-- note: there's almost certainly an update function associated with this that is doing things we aren't aware of
		name = "Judge",
		textHeader = "Judgment Label Size:",
		element = {},
		children = {"Judgment"},
		properties = {"Zoom"},
		elementTree = "GameplaySizes",
		noBorder = true,
		DeviceButton_up = {
			property = "Zoom",
			inc = 0.01
		},
		DeviceButton_down = {
			property = "Zoom",
			inc = -0.01
		}
	},
	ComboPosition = {
		name = "Combo",
		textHeader = "Combo Position:",
		element = {},
		children = {"Label", "Number", "Border"},
		properties = {"X", "Y"},
		propertyOffsets = nil,
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -5
		},
		DeviceButton_down = {
			property = "Y",
			inc = 5
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	ComboSize = {	-- combo and label are 2 text objects, 1 right aligned and 1 left, this makes border resizing desync from the text sometimes
		name = "Combo",	-- i really dont want to deal with this right now -mina
		textHeader = "Combo Size:",
		element = {},
		children = {"Label", "Number"},
		properties = {"Zoom"},
		elementTree = "GameplaySizes",
		noBorder = true,
		DeviceButton_up = {
			property = "Zoom",
			inc = 0.01
		},
		DeviceButton_down = {
			property = "Zoom",
			inc = -0.01
		}
	},
	ErrorBarPosition = {
		name = "ErrorBar",
		textHeader = "Error Bar Position:",
		element = {}, -- initialized later
		properties = {"X", "Y"},
		children = {"Center", "WeightedBar", "Border"},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -5
		},
		DeviceButton_down = {
			property = "Y",
			inc = 5
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	ErrorBarSize = {
		name = "ErrorBar",
		textHeader = "Error Bar Size:",
		element = {},
		properties = {"Width", "Height"},
		children = {"Center", "WeightedBar"},
		elementTree = "GameplaySizes",
		DeviceButton_up = {
			property = "Height",
			inc = 1
		},
		DeviceButton_down = {
			property = "Height",
			inc = -1
		},
		DeviceButton_left = {
			property = "Width",
			inc = -10
		},
		DeviceButton_right = {
			property = "Width",
			inc = 10
		}
	},
	TargetTrackerPosition = {
		name = "TargetTracker",
		textHeader = "Goal Tracker Position:",
		element = {},
		properties = {"X", "Y"},
		-- no children so the changes are applied to the element itself
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -5
		},
		DeviceButton_down = {
			property = "Y",
			inc = 5
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	TargetTrackerSize = {
		name = "TargetTracker",
		textHeader = "Goal Tracker Size:",
		element = {},
		properties = {"Zoom"},
		elementTree = "GameplaySizes",
		DeviceButton_up = {
			property = "Zoom",
			inc = 0.01
		},
		DeviceButton_down = {
			property = "Zoom",
			inc = -0.01
		}
	},
	FullProgressBarPosition = {
		name = "FullProgressBar",
		textHeader = "Full Progress Bar Position:",
		element = {},
		properties = {"X", "Y"},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -3
		},
		DeviceButton_down = {
			property = "Y",
			inc = 3
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	FullProgressBarSize = {
		name = "FullProgressBar",
		textHeader = "Full Progress Bar Size:",
		element = {},
		properties = {"Width", "Height"},
		elementTree = "GameplaySizes",
		noBorder = true,
		DeviceButton_up = {
			property = "Height",
			inc = 0.1
		},
		DeviceButton_down = {
			property = "Height",
			inc = -0.1
		},
		DeviceButton_left = {
			property = "Width",
			inc = -0.01
		},
		DeviceButton_right = {
			property = "Width",
			inc = 0.01
		}
	},
	MiniProgressBarPosition = {
		name = "MiniProgressBar",
		textHeader = "Mini Progress Bar Position:",
		element = {},
		properties = {"X", "Y"},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -5
		},
		DeviceButton_down = {
			property = "Y",
			inc = 5
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	DisplayPercentPosition = {
		name = "DisplayPercent",
		textHeader = "Current Percent Position:",
		element = {},
		properties = {"X", "Y"},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -5
		},
		DeviceButton_down = {
			property = "Y",
			inc = 5
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	DisplayPercentSize = {
		name = "DisplayPercent",
		textHeader = "Current Percent Size:",
		element = {},
		properties = {"Zoom"},
		elementTree = "GameplaySizes",
		DeviceButton_up = {
			property = "Zoom",
			inc = 0.01
		},
		DeviceButton_down = {
			property = "Zoom",
			inc = -0.01
		}
	},
	NotefieldPosition = {
		name = "Notefield",
		textHeader = "Notefield Position:",
		element = {},
		properties = {"X", "Y"},
		elementTree = "GameplayXYCoordinates",
		noBorder = true,
		DeviceButton_up = {
			notefieldY = true,
			property = "AddY",
			inc = -3
		},
		DeviceButton_down = {
			notefieldY = true,
			property = "AddY",
			inc = 3
		},
		DeviceButton_left = {
			property = "AddX",
			inc = -3
		},
		DeviceButton_right = {
			property = "AddX",
			inc = 3
		}
	},
	NotefieldSize = {
		name = "Notefield",
		textHeader = "Notefield Size:",
		element = {},
		elementList = true, -- god bless the notefield
		properties = {"Width", "Height"},
		elementTree = "GameplaySizes",
		noBorder = true,
		DeviceButton_up = {
			property = "Height",
			inc = 0.01
		},
		DeviceButton_down = {
			property = "Height",
			inc = -0.01
		},
		DeviceButton_left = {
			property = "Width",
			inc = -0.01
		},
		DeviceButton_right = {
			property = "Width",
			inc = 0.01
		}
	},
	NPSDisplayPosition = {
		name = "NPSDisplay",
		textHeader = "NPS Display Position:",
		element = {},
		properties = {"X", "Y"},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -5
		},
		DeviceButton_down = {
			property = "Y",
			inc = 5
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	NPSDisplaySize = {
		name = "NPSDisplay",
		textHeader = "NPS Display Size:",
		element = {},
		properties = {"Zoom"},
		elementTree = "GameplaySizes",
		DeviceButton_up = {
			property = "Zoom",
			inc = 0.01
		},
		DeviceButton_down = {
			property = "Zoom",
			inc = -0.01
		}
	},
	NPSGraphPosition = {
		name = "NPSGraph",
		textHeader = "NPS Graph Position:",
		element = {},
		properties = {"X", "Y"},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -5
		},
		DeviceButton_down = {
			property = "Y",
			inc = 5
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	NPSGraphSize = {
		name = "NPSGraph",
		textHeader = "NPS Graph Size:",
		element = {},
		properties = {"Width", "Height"},
		noBorder = true,
		elementTree = "GameplaySizes",
		DeviceButton_up = {
			property = "Height",
			inc = 0.01
		},
		DeviceButton_down = {
			property = "Height",
			inc = -0.01
		},
		DeviceButton_left = {
			property = "Width",
			inc = -0.01
		},
		DeviceButton_right = {
			property = "Width",
			inc = 0.01
		}
	},
	JudgeCounterPosition = {
		name = "JudgeCounter",
		textHeader = "Judge Counter Position:",
		element = {},
		properties = {"X", "Y"},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -3
		},
		DeviceButton_down = {
			property = "Y",
			inc = 3
		},
		DeviceButton_left = {
			property = "X",
			inc = -3
		},
		DeviceButton_right = {
			property = "X",
			inc = 3
		}
	},
	LeaderboardPosition = {
		name = "Leaderboard",
		textHeader = "Leaderboard Position:",
		properties = {"X", "Y"},
		element = {},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -3
		},
		DeviceButton_down = {
			property = "Y",
			inc = 3
		},
		DeviceButton_left = {
			property = "X",
			inc = -3
		},
		DeviceButton_right = {
			property = "X",
			inc = 3
		}
	},
	LeaderboardSize = {
		name = "Leaderboard",
		textHeader = "Leaderboard Size:",
		properties = {"Width", "Height"},
		element = {},
		elementTree = "GameplaySizes",
		noBorder = true,
		DeviceButton_up = {
			property = "Height",
			inc = 0.01
		},
		DeviceButton_down = {
			property = "Height",
			inc = -0.01
		},
		DeviceButton_left = {
			property = "Width",
			inc = -0.01
		},
		DeviceButton_right = {
			property = "Width",
			inc = 0.01
		}
	},
	LeaderboardSpacing = {
		name = "Leaderboard",
		textHeader = "Leaderboard Spacing:",
		properties = {"Spacing"},
		elementTree = "GameplaySizes",
		DeviceButton_up = {
			arbitraryInc = true,
			property = "Spacing",
			inc = -0.3
		},
		DeviceButton_down = {
			arbitraryInc = true,
			property = "Spacing",
			inc = 0.3
		},
	},
	ReplayButtonsPosition = {
		name = "ReplayButtons",
		textHeader = "Replay Buttons Position:",
		element = {},
		properties = {"X", "Y"},
		elementTree = "GameplayXYCoordinates",
		condition = false,
		DeviceButton_up = {
			property = "Y",
			inc = -3
		},
		DeviceButton_down = {
			property = "Y",
			inc = 3
		},
		DeviceButton_left = {
			property = "X",
			inc = -3
		},
		DeviceButton_right = {
			property = "X",
			inc = 3
		}
	},--[[
	ReplayButtonsSize = {
		name = "ReplayButtons",
		textHeader = "Replay Buttons Size:",
		element = {},
		noBorder = true,
		properties = {"Zoom"},
		elementTree = "GameplaySizes",
		condition = false,
		DeviceButton_up = {
			property = "Zoom",
			inc = 0.01
		},
		DeviceButton_down = {
			property = "Zoom",
			inc = -0.01
		}
	},]]
	ReplayButtonsSpacing = {
		name = "ReplayButtons",
		textHeader = "Replay Buttons Spacing:",
		properties = {"Spacing"},
		elementTree = "GameplaySizes",
		condition = false,
		DeviceButton_up = {
			arbitraryInc = true,
			property = "Spacing",
			inc = -0.5
		},
		DeviceButton_down = {
			arbitraryInc = true,
			property = "Spacing",
			inc = 0.5
		},
	},
	LifeP1Position = {
		name = "LifeP1",
		textHeader = "Lifebar Position:",
		element = {},
		properties = {"X", "Y"},
		-- propertyOffsets = {"178", "10"},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -3
		},
		DeviceButton_down = {
			property = "Y",
			inc = 3
		},
		DeviceButton_left = {
			property = "X",
			inc = -3
		},
		DeviceButton_right = {
			property = "X",
			inc = 3
		}
	},
	LifeP1Size = {
		name = "LifeP1",
		textHeader = "Lifebar Size:",
		properties = {"Width", "Height"},
		element = {},
		elementTree = "GameplaySizes",
		noBorder = true,
		DeviceButton_up = {
			property = "Height",
			inc = 0.1
		},
		DeviceButton_down = {
			property = "Height",
			inc = -0.1
		},
		DeviceButton_left = {
			property = "Width",
			inc = -0.01
		},
		DeviceButton_right = {
			property = "Width",
			inc = 0.01
		}
	},
	LifeP1Rotation = {
		name = "LifeP1",
		textHeader = "Lifebar Rotation:",
		properties = {"Rotation"},
		element = {},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Rotation",
			inc = -1
		},
		DeviceButton_down = {
			property = "Rotation",
			inc = 1
		},
	},
	PracticeCDGraphPosition = {
		name = "PracticeCDGraph",
		textHeader = "Chord Density Graph Position:",
		properties = {"X","Y"},
		element = {},
		elementTree = "GameplayXYCoordinates",
		propertyOffsets = nil,
		DeviceButton_up = {
			property = "Y",
			inc = -3
		},
		DeviceButton_down = {
			property = "Y",
			inc = 3
		},
		DeviceButton_left = {
			property = "X",
			inc = -3
		},
		DeviceButton_right = {
			property = "X",
			inc = 3
		}
	},
	--[[PracticeCDGraphSize = {
		name = "PracticeCDGraph",
		textHeader = "Chord Density Graph Size:",
		properties = {"Width", "Height"},
		element = {},
		elementTree = "GameplaySizes",
		propertyOffsets = nil,
		DeviceButton_up = {
			property = "Height",
			inc = 0.1
		},
		DeviceButton_down = {
			property = "Height",
			inc = -0.1
		},
		DeviceButton_left = {
			property = "Width",
			inc = -0.01
		},
		DeviceButton_right = {
			property = "Width",
			inc = 0.01
		}
	},]]
	BPMTextPosition = {
		name = "BPMText",
		textHeader = "BPM Text Position:",
		element = {},
		properties = {"X", "Y"},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -5
		},
		DeviceButton_down = {
			property = "Y",
			inc = 5
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	BPMTextSize = {
		name = "BPMText",
		textHeader = "BPM Text Size:",
		element = {},
		properties = {"Zoom"},
		elementTree = "GameplaySizes",
		DeviceButton_up = {
			property = "Zoom",
			inc = 0.01
		},
		DeviceButton_down = {
			property = "Zoom",
			inc = -0.01
		}
	},
	MusicRatePosition = {
		name = "MusicRate",
		textHeader = "Music Rate Position:",
		element = {},
		properties = {"X", "Y"},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -5
		},
		DeviceButton_down = {
			property = "Y",
			inc = 5
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	MusicRateSize = {
		name = "MusicRate",
		textHeader = "Music Rate Size:",
		element = {},
		properties = {"Zoom"},
		elementTree = "GameplaySizes",
		DeviceButton_up = {
			property = "Zoom",
			inc = 0.01
		},
		DeviceButton_down = {
			property = "Zoom",
			inc = -0.01
		}
	},
	NotefieldSpacing = {
		name = "Notefield",
		textHeader = "Notefield Columns:",
		properties = {"Spacing"},
		elementTree = "GameplaySizes",
		noBorder = true,
		DeviceButton_up = {
			arbitraryInc = true,
			property = "Spacing",
			inc = 1
		},
		DeviceButton_down = {
			arbitraryInc = true,
			property = "Spacing",
			inc = -1
		},
	},
	DisplayMeanPosition = {
		name = "DisplayMean",
		textHeader = "Current Mean Position:",
		element = {},
		properties = {"X", "Y"},
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -5
		},
		DeviceButton_down = {
			property = "Y",
			inc = 5
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	DisplayMeanSize = {
		name = "DisplayMean",
		textHeader = "Current Mean Size:",
		element = {},
		properties = {"Zoom"},
		elementTree = "GameplaySizes",
		DeviceButton_up = {
			property = "Zoom",
			inc = 0.01
		},
		DeviceButton_down = {
			property = "Zoom",
			inc = -0.01
		}
	},
	PaceMakerPosition = {
		name = "PaceMaker",
		textHeader = "Pacemaker Graph Position:",
		element = {},
		properties = {"X", "Y"},
		propertyOffsets = nil, -- set in pacemaker.lua so mouse drags hold the graph by its middle
		elementTree = "GameplayXYCoordinates",
		DeviceButton_up = {
			property = "Y",
			inc = -5
		},
		DeviceButton_down = {
			property = "Y",
			inc = 5
		},
		DeviceButton_left = {
			property = "X",
			inc = -5
		},
		DeviceButton_right = {
			property = "X",
			inc = 5
		}
	},
	PaceMakerSize = {
		name = "PaceMaker",
		textHeader = "Pacemaker Graph Size:",
		element = {},
		properties = {"Zoom"},
		elementTree = "GameplaySizes",
		DeviceButton_up = {
			property = "Zoom",
			inc = 0.05
		},
		DeviceButton_down = {
			property = "Zoom",
			inc = -0.05
		}
	}
}

-- Gameplay elements in the order Tab cycles through them. Each one lists its
-- adjustment modes (entries of Movable) in the order Space cycles through them.
-- The first mode of every element is its position, which is what mouse drags move.
local movableElements = {
	{label = "Judgment", modes = {"JudgePosition", "JudgeSize"}},
	{label = "Combo", modes = {"ComboPosition", "ComboSize"}},
	{label = "Notefield", modes = {"NotefieldPosition", "NotefieldSize", "NotefieldSpacing"}},
	{label = "Lifebar", modes = {"LifeP1Position", "LifeP1Size", "LifeP1Rotation"}},
	{label = "Error Bar", modes = {"ErrorBarPosition", "ErrorBarSize"}},
	{label = "Goal Tracker", modes = {"TargetTrackerPosition", "TargetTrackerSize"}},
	{label = "Current Percent", modes = {"DisplayPercentPosition", "DisplayPercentSize"}},
	{label = "Current Mean", modes = {"DisplayMeanPosition", "DisplayMeanSize"}},
	{label = "Judge Counter", modes = {"JudgeCounterPosition"}},
	{label = "Pacemaker Graph", modes = {"PaceMakerPosition", "PaceMakerSize"}},
	{label = "Full Progress Bar", modes = {"FullProgressBarPosition", "FullProgressBarSize"}},
	{label = "Mini Progress Bar", modes = {"MiniProgressBarPosition"}},
	{label = "NPS Display", modes = {"NPSDisplayPosition", "NPSDisplaySize"}},
	{label = "NPS Graph", modes = {"NPSGraphPosition", "NPSGraphSize"}},
	{label = "Leaderboard", modes = {"LeaderboardPosition", "LeaderboardSize", "LeaderboardSpacing"}},
	{label = "BPM Text", modes = {"BPMTextPosition", "BPMTextSize"}},
	{label = "Music Rate", modes = {"MusicRatePosition", "MusicRateSize"}},
	{label = "Replay Buttons", modes = {"ReplayButtonsPosition", "ReplayButtonsSpacing"}},
	{label = "Chord Density Graph", modes = {"PracticeCDGraphPosition"}},
}

local modeNames = {
	X = "Position",
	Zoom = "Size",
	Width = "Size",
	Spacing = "Spacing",
	Rotation = "Rotation",
}

-- values of the selected element when it was selected, for Backspace
local undoState = {}

local function modeName(id)
	return modeNames[Movable[id].properties[1]]
end

local function availableModes(element)
	local o = {}
	for _, id in ipairs(element.modes) do
		if Movable[id] ~= nil and Movable[id].condition then
			o[#o + 1] = id
		end
	end
	return o
end

local function availableElements()
	local o = {}
	for _, element in ipairs(movableElements) do
		if #availableModes(element) > 0 then
			o[#o + 1] = element
		end
	end
	return o
end

local function elementOf(id)
	for _, element in ipairs(movableElements) do
		for _, m in ipairs(element.modes) do
			if m == id then
				return element
			end
		end
	end
end

-- every value a mode adjusts is reachable through its left or up key
local function eachValueKey(id, f)
	local entry = Movable[id]
	for _, b in ipairs({"DeviceButton_left", "DeviceButton_up"}) do
		local curKey = entry[b]
		if curKey ~= nil then
			f(curKey, entry.name .. string.gsub(curKey.property, "Add", ""))
		end
	end
end

-- set one value of a mode, move the actors to match and save it for the current keymode
local function applyValue(id, curKey, newVal)
	local current = Movable[id]
	local keyProperty = curKey.property
	local prop = current.name .. string.gsub(keyProperty, "Add", "")
	local diff = newVal - MovableValues[prop]
	MovableValues[prop] = newVal

	if curKey.arbitraryFunction then
		if curKey.arbitraryInc then
			curKey.arbitraryFunction(diff)
		else
			curKey.arbitraryFunction(newVal)
		end
	elseif current.children then
		for _, attribute in ipairs(current.children) do
			propsFunctions[keyProperty](current.element[attribute], newVal)
		end
	elseif current.elementList then
		for _, elem in ipairs(current.element) do
			propsFunctions[keyProperty](elem, newVal)
		end
	elseif keyProperty == "AddX" then
		propsFunctions[keyProperty](current.element, diff)
	elseif keyProperty == "AddY" then
		-- the notefield's saved Y counts upwards unless reverse is on
		propsFunctions[keyProperty](current.element, diff * (usingReverse and 1 or -1))
	else
		propsFunctions[keyProperty](current.element, newVal)
	end

	local border = current.Border
	if not current.noBorder and border ~= nil then
		if keyProperty == "Height" or keyProperty == "Width" or keyProperty == "Zoom" then
			border:playcommand("Change" .. keyProperty, {val = newVal})
		end
	end

	playerConfig:get_data(pn_to_profile_slot(PLAYER_1))[current.elementTree][keymode][prop] = newVal
	playerConfig:set_dirty(pn_to_profile_slot(PLAYER_1))
	-- saved to disk when the screen changes, see messagebox.lua
	MESSAGEMAN:Broadcast("CustomizeGameplayChanged", {id = id, property = keyProperty, diff = diff})
end

local function updatetext()
	if Movable.message.settext == nil then return end
	local id = Movable.current
	local current = Movable[id]
	local element = elementOf(id)
	if current == nil or element == nil then
		Movable.message:visible(false)
		return
	end
	local modes = {}
	for _, m in ipairs(availableModes(element)) do
		modes[#modes + 1] = m == id and "[" .. modeName(m) .. "]" or modeName(m)
	end
	local text = {element.label, table.concat(modes, "  ")}
	for _, prop in ipairs(current.properties) do
		text[#text + 1] = prop .. ": " .. Round(MovableValues[current.name .. prop] or 0, 3)
	end
	Movable.message:settext(table.concat(text, "\n"))
	Movable.message:visible(true)
end

-- select a mode of an element, or nothing when id is nil
local function selectMode(id)
	local before = elementOf(Movable.current)
	local element = id ~= nil and elementOf(id) or nil
	Movable.current = id or "None"
	Movable.pressed = id ~= nil
	if element ~= nil and element ~= before then
		undoState = {}
		for _, m in ipairs(availableModes(element)) do
			eachValueKey(m, function(_, prop)
				undoState[prop] = MovableValues[prop]
			end)
		end
	end
	updatetext()
	MESSAGEMAN:Broadcast("CustomizeGameplaySelection")
end

local function cycleElement(dir)
	local list = availableElements()
	if #list == 0 then return end
	local current = elementOf(Movable.current)
	local index = 0
	for i, element in ipairs(list) do
		if element == current then
			index = i
		end
	end
	if index == 0 then
		index = dir > 0 and 1 or #list
	else
		index = (index - 1 + dir) % #list + 1
	end
	selectMode(availableModes(list[index])[1])
end

local function cycleMode()
	local modes = availableModes(elementOf(Movable.current))
	for i, m in ipairs(modes) do
		if m == Movable.current then
			selectMode(modes[i % #modes + 1])
			return
		end
	end
end

-- put every value of the selected element back to how it was when it was selected, or to its default
local function restoreElement(useDefaults)
	local element = elementOf(Movable.current)
	if element == nil then return end
	for _, id in ipairs(availableModes(element)) do
		eachValueKey(id, function(curKey, prop)
			local val = undoState[prop]
			if useDefaults then
				if Movable[id].elementTree == "GameplayXYCoordinates" then
					val = getDefaultGameplayCoordinate(prop)
				else
					val = getDefaultGameplaySize(prop)
				end
			end
			if val ~= nil and val ~= MovableValues[prop] then
				applyValue(id, curKey, val)
			end
		end)
	end
	updatetext()
end

local positionProperties = {X = true, Y = true, AddX = true, AddY = true}
-- modes with a single value take it from any arrow key
local sameValueKey = {DeviceButton_left = "DeviceButton_down", DeviceButton_right = "DeviceButton_up"}

local function nudge(button, fine)
	local id = Movable.current
	local current = Movable[id]
	local curKey = current[button]
	if curKey == nil and sameValueKey[button] ~= nil and current.DeviceButton_left == nil then
		curKey = current[sameValueKey[button]]
	end
	if curKey == nil then return end

	local step = curKey.inc
	if fine then
		if positionProperties[curKey.property] then
			step = step > 0 and 1 or -1
		else
			step = step / 5
		end
	end
	if curKey.notefieldY and not usingReverse then
		step = -step
	end
	local prop = current.name .. string.gsub(curKey.property, "Add", "")
	applyValue(id, curKey, Round(MovableValues[prop] + step, 4))
	updatetext()
end

local function isHeld(a, b)
	return INPUTFILTER:IsBeingPressed(a) or INPUTFILTER:IsBeingPressed(b)
end

-- Rebirth style controls: pick an element with Tab or the mouse, then one shared set of keys adjusts it
--	Tab / Shift+Tab		next / previous element
--	Space				next mode of the element (position, size, spacing, rotation)
--	arrows				adjust, hold Shift for fine steps
--	Backspace			undo changes since the element was selected
--	Ctrl+Backspace		reset the element to default
--	right click			deselect
function MovableInput(event)
	if SCREENMAN:GetTopScreen():GetName() == "ScreenGameplaySyncMachine" then return end
	if getAutoplay() == 0 then return false end

	local button = event.DeviceInput.button
	if event.DeviceInput.is_mouse then
		if button == "DeviceButton_left mouse button" then
			if event.type == "InputEventType_FirstPress" then
				Movable.clickPending = true
			elseif event.type == "InputEventType_Release" then
				Movable.clickPending = false
				Movable.dragging = nil
			end
		elseif button == "DeviceButton_right mouse button" and event.type == "InputEventType_FirstPress" then
			selectMode(nil)
		end
		return false
	end

	if event.type == "InputEventType_Release" then return false end
	local firstPress = event.type == "InputEventType_FirstPress"
	local shift = isHeld("left shift", "right shift")

	if button == "DeviceButton_tab" then
		cycleElement(shift and -1 or 1)
	elseif Movable[Movable.current] == nil then
		return false
	elseif button == "DeviceButton_space" then
		if firstPress then
			cycleMode()
		end
	elseif button == "DeviceButton_backspace" then
		if firstPress then
			restoreElement(isHeld("left ctrl", "right ctrl"))
		end
	elseif button == "DeviceButton_up" or button == "DeviceButton_down" or button == "DeviceButton_left" or button == "DeviceButton_right" then
		nudge(button, shift)
	end
	return false
end

-- for the element list in messagebox.lua: labels of the elements that can be customized
-- and the index of the selected one (0 if none)
function getMovableElementList()
	local labels = {}
	local selected = 0
	local current = elementOf(Movable.current)
	for i, element in ipairs(availableElements()) do
		labels[i] = element.label
		if element == current then
			selected = i
		end
	end
	return labels, selected
end

function setBorderAlignment(self, h, v)
	self:RunCommandsOnChildren(
		function(self)
			self:halign(h):valign(v)
		end
	)
	self:GetChild("hideybox"):addx(-2 * (h - 0.5))
	self:GetChild("hideybox"):addy(-2 * (v - 0.5))
end

function setBorderToText(b, t)
	b:playcommand("ChangeWidth", {val = t:GetZoomedWidth()})
	b:playcommand("ChangeHeight", {val = t:GetZoomedHeight()})
	b:playcommand("ChangeZoom", {val = t:GetParent():GetZoom()})
end

local function elementForActor(name)
	name = name == "Judgment" and "Judge" or name
	for _, element in ipairs(movableElements) do
		local entry = Movable[element.modes[1]]
		if entry ~= nil and entry.name == name and entry.properties[1] == "X" then
			return element
		end
	end
end

local function bordermousereact(self)
	self:queuecommand("mousereact")
end

-- clicking an element selects it, holding the click drags it
local function movewhendragged(self)
	-- this is a somewhat dangerous hierarchical assumption but it should help us get organied in the short term -mina
	local element = elementForActor(self:GetParent():GetParent():GetName())
	if element == nil then return end
	local id = element.modes[1]
	local entry = Movable[id]
	if not entry.condition then return end

	if Movable.clickPending and isOver(self) then
		Movable.clickPending = false
		Movable.dragging = element
		if elementOf(Movable.current) ~= element then
			selectMode(id)
		end
	end

	if Movable.dragging == element and INPUTFILTER:IsBeingPressed("Mouse 0", "Mouse") then
		local nx = Round(INPUTFILTER:GetMouseX())
		local ny = Round(INPUTFILTER:GetMouseY())
		if entry.propertyOffsets ~= nil then
			nx = nx - entry.propertyOffsets[1]
			ny = ny - entry.propertyOffsets[2]
		end
		local moved = false
		if nx ~= MovableValues[entry.name .. "X"] then
			applyValue(id, entry.DeviceButton_left, nx)
			moved = true
		end
		if ny ~= MovableValues[entry.name .. "Y"] then
			applyValue(id, entry.DeviceButton_up, ny)
			moved = true
		end
		if moved then
			updatetext()
		end
	end

	if elementOf(Movable.current) == element then
		self:GetParent():diffusealpha(0.75)	-- this is selected
	elseif isOver(self) or Movable.pressed then
		self:GetParent():diffusealpha(0.35)	-- moused over, or something else is selected
	else
		self:GetParent():diffusealpha(0.1)	-- nothing is selected and this is not moused over
	end
end

-- border function in use -mina
function MovableBorder(width, height, bw, x, y)
	if not allowedCustomization then return end	-- we don't want to be loading all this garbage if we aren't in customization
	return Def.ActorFrame {
		Name = "Border",
		InitCommand=function(self)
			self:xy(x,y):diffusealpha(0)
			self:SetUpdateFunction(bordermousereact)
		end,
		OnCommand=function(self)
			if SCREENMAN:GetTopScreen():GetName() == "ScreenGameplaySyncMachine" then
				self:visible(false)
				self:SetUpdateFunction(nil)
			end
		end,
		ChangeWidthCommand=function(self, params)
			self:GetChild("xbar"):zoomx(params.val)
			self:GetChild("showybox"):zoomx(params.val)
			self:GetChild("hideybox"):zoomx(params.val-2*bw)
		end,
		ChangeHeightCommand=function(self, params)
			self:GetChild("ybar"):zoomy(params.val)
			self:GetChild("showybox"):zoomy(params.val)
			self:GetChild("hideybox"):zoomy(params.val-2*bw)
		end,
		ChangeZoomCommand=function(self,params)
			local wot = self:GetZoom()/(1/params.val)
			self:zoom(1/params.val)
			self:playcommand("ChangeWidth", {val = self:GetChild("showybox"):GetZoomX() * wot})
			self:playcommand("ChangeHeight", {val = self:GetChild("showybox"):GetZoomY() * wot})
		end,
		Def.Quad {
			Name = "xbar",
			InitCommand=function(self)
				self:zoomto(width,bw):diffusealpha(0.5)	-- did not realize this was multiplicative with parent's value -mina
			end
		},
		Def.Quad {
			Name = "ybar",
			InitCommand=function(self)
				self:zoomto(bw,height):diffusealpha(0.5)
			end
		},
		Def.Quad {
			Name = "hideybox",
			InitCommand=function(self)
				self:zoomto(width-2*bw, height-2*bw):MaskSource(true)
			end
		},
		Def.Quad {
			Name = "showybox",
			InitCommand=function(self)
				self:zoomto(width,height):MaskDest()
			end,
			mousereactCommand=function(self)
				movewhendragged(self)	-- this quad owns the mouse movement function -mina
			end
		},
	}
end
