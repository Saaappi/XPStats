local addonName, addonTable = ...
local e = CreateFrame("Frame")
local L = addonTable.L
local mapName = ""
local unitN = ""

e:RegisterEvent("ADDON_LOADED")
e:RegisterEvent("PLAYER_XP_UPDATE")
e:RegisterEvent("QUEST_TURNED_IN")
e:RegisterEvent("NAME_PLATE_UNIT_ADDED")
e:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
e:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
e:RegisterEvent("ZONE_CHANGED_NEW_AREA")

local function GetCurrentMap()
	local id = C_Map.GetBestMapForUnit("player")
	if id then
		local mapInfo = C_Map.GetMapInfo(id)
		if not mapInfo.mapID then return end
		mapName = mapInfo.name
	end
end

local function GetUnitName(unit)
	if UnitIsPlayer(unit) == false then
		-- The unit is an NPC
		if UnitIsFriend(unit, "player") == false then
			-- We don't want to track friendly units.
			local unitName = UnitName(unit)
			return unitName
		end
	end
end

e:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addon = ...
		if addon == addonName then
			if XPStatsPDB == nil then
				XPStatsPDB = {}
			end
			C_Timer.After(2, function()
				GetCurrentMap()
				if XPStatsPDB[mapName] == nil then
					XPStatsPDB[mapName] = {}
					XPStatsPDB[mapName]["Creatures"] = {}
					XPStatsPDB[mapName]["Quests"] = {}
				end
			end)
			XPStatsPDB[""] = nil
		end
	end
	if event == "NAME_PLATE_UNIT_ADDED" then
		-- The entire purpose of this function is to
		-- document the creatures seen via nameplates.
		local unit = ...
		local guid = UnitGUID(unit)
		if guid then
			local unitName = GetUnitName(unit)
			if unitName then
				if XPStatsPDB[mapName] == nil then
					XPStatsPDB[mapName] = {}
					XPStatsPDB[mapName]["Creatures"] = {}
				else
					if XPStatsPDB[mapName]["Creatures"] == nil then
						XPStatsPDB[mapName]["Creatures"] = {}
					end
					if XPStatsPDB[mapName]["Creatures"][unitName] == nil then
						-- The first time the creature has been seen.
						XPStatsPDB[mapName]["Creatures"][unitName] = 0
					end
				end
			end
		end
	end
	if event == "CHAT_MSG_COMBAT_XP_GAIN" then
		local str = ...
		if string.find(str, "dies") then
			-- This was a creature kill.
			local unitName = string.match(str, "(.*) dies")
			local experience = str:gsub("%D+", "")
			XPStatsPDB[mapName]["Creatures"][unitName] = XPStatsPDB[mapName]["Creatures"][unitName] + experience
		end
	end
	if event == "PLAYER_XP_UPDATE" then
		local unit = ...
		unitN = GetUnitName(unit)
	end
	if event == "QUEST_TURNED_IN" then
		local questId, experience = ...
		if XPStatsPDB[mapName] == nil then
			XPStatsPDB[mapName] = {}
			XPStatsPDB[mapName]["Quests"] = {}
		end
		XPStatsPDB[mapName]["Quests"][questId] = experience
	end
	if event == "UPDATE_MOUSEOVER_UNIT" then
		local guid = UnitGUID("mouseover")
		if guid then
			local unitName = GetUnitName("mouseover")
			if unitName then
				if XPStatsPDB[mapName] == nil then
					XPStatsPDB[mapName] = {}
					XPStatsPDB[mapName]["Creatures"] = {}
				else
					if XPStatsPDB[mapName]["Creatures"] == nil then
						XPStatsPDB[mapName]["Creatures"] = {}
					end
					if XPStatsPDB[mapName]["Creatures"][unitName] == nil then
						-- The first time the creature has been seen.
						XPStatsPDB[mapName]["Creatures"][unitName] = 0
					end
				end
			end
		end
	end
	if event == "ZONE_CHANGED_NEW_AREA" then
		GetCurrentMap()
	end
end)

SLASH_XPStats1 = "/xp"
SlashCmdList["XPStats"] = function(command, editbox)
	local _, _, command, arguments = string.find(command, "%s?(%w+)%s?(.*)") -- Using pattern matching the addon will be able to interpret subcommands.
	if not command or command == "" then
		print("Please enter a zone name.")
	elseif command == "s" and arguments ~= "" then
		local totalExperience = 0
		for questId, experience in pairs(XPStatsPDB[arguments]["Quests"]) do
			totalExperience = totalExperience + experience
		end
		for unitName, experience in pairs(XPStatsPDB[arguments]["Creatures"]) do
			totalExperience = totalExperience + experience
		end
		print("Total experience earned in |cffFFFF00" .. arguments .. "|r is " .. totalExperience .. ".")
	end
end