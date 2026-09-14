---@class QuestgiverFrame
local QuestgiverFrame = QuestieLoader:CreateModule("QuestgiverFrame")

---@type QuestieDB
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")

---@type QuestieLib
local QuestieLib = QuestieLoader:ImportModule("QuestieLib")

--- COMPATIBILITY ---
local UnitGUID = QuestieCompat.UnitGUID

local _G = _G
local tinsert = tinsert
local MAX_NUM_QUESTS = MAX_NUM_QUESTS

-- This is the logic used for determining which icon we should show for a quest
-- This just determines the "type" of icon shown, not the exact icon file - see Questie.icons
---@param questID number
---@param isActive boolean
---@return string
local function determineAppropriateQuestIcon(questID, isActive)
    if questID == 0 then -- if we were fed a questID of 0, the ID bruteforce failed, abort
        if isActive == true then
            return Questie.icons["complete"]
        else
            return Questie.icons["available"]
        end
    end
    local icon = Questie.icons["available"] -- fallback icon in case any of the logic below fails
    if isActive == true then
        icon = Questie.icons["incomplete"] -- fallback icon in case any of the logic below fails
        if QuestieDB.IsComplete(questID) == 1 then
            if QuestieDB.IsPvPQuest(questID) then
                icon = Questie.icons["pvpquest_complete"]
            elseif QuestieDB.IsActiveEventQuest(questID) then
                icon = Questie.icons["eventquest_complete"]
            elseif QuestieDB.IsRepeatable(questID) then
                icon = Questie.icons["repeatable_complete"]
            else
                icon = Questie.icons["complete"]
            end
        end
    else
        if QuestieDB.IsPvPQuest(questID) then
            icon = Questie.icons["pvpquest"]
        elseif QuestieDB.IsActiveEventQuest(questID) then
            icon = Questie.icons["eventquest"]
        elseif QuestieDB.IsRepeatable(questID) then
            icon = Questie.icons["repeatable"]
        end
    end
    return icon
end

-- 9.0.0 API GOSSIP
local function updateGossipFrame()
    local numAvailable = GetNumGossipAvailableQuests()
    local numActive = GetNumGossipActiveQuests()
    local availQuests = {QuestieCompat.GetAvailableQuests()}
    local activeQuests = {QuestieCompat.GetActiveQuests()}
    local index = 0 -- this variable tracks the GossipTitleButton we should be targeting for icon changes
    local questgiver = UnitGUID("npc")
    if numAvailable > 0 then
        for i=1, numAvailable do
            index = index + 1
            -- GetGossipAvailableQuests() returns 7 individual values per quest entry...
            -- so we have to filter out to every 7th value, starting with 1, 8, 15, etc
            local questIndex = (1 + ((i - 1) * 7))
            local questname = availQuests[questIndex]
            local questid = QuestieDB.GetQuestIDFromName(questname, questgiver, true)
            local gossipIcon = _G["GossipTitleButton" .. index .. "GossipIcon"]
            gossipIcon:SetTexture(determineAppropriateQuestIcon(questid, false))
        end
        -- each new section in a gossip frame has an offset of 1, so for instance, with 2 quests shown,
        -- 1 active 1 available, the available will be GossipTitleButton1 and the active will be GossipTitleButton3
        if numActive > 0 then index = index + 1 end
    end
    if numActive > 0 then
        for i=1, numActive do
            index = index + 1
            -- GetGossipActiveQuests() returns 6 individual values per quest entry...
            -- so we have to filter out to every 6th value, starting with 1, 7, 13, etc
            local questIndex = (1 + ((i - 1) * 6))
            local questname = activeQuests[questIndex]
            local questid = QuestieDB.GetQuestIDFromName(questname, questgiver, false)
            local gossipIcon = _G["GossipTitleButton" .. index .. "GossipIcon"]
            gossipIcon:SetTexture(determineAppropriateQuestIcon(questid, true))
        end
    end
end

-- GREETING FRAMES (API independent)
local function updateGreetingFrame()
    local titleLines = {}
    local questIconTextures = {}
    local questgiver = UnitGUID("npc")
    for i = 1, MAX_NUM_QUESTS do
        local titleLine = _G["QuestTitleButton" .. i]
        if titleLine then
            tinsert(titleLines, titleLine)
            tinsert(questIconTextures, _G[titleLine:GetName() .. "QuestIcon"])
        else
            Questie:Error("Frame error! Could not obtain Greeting's QuestTitleButton object. Please report this on Github or Discord!")
            Questie:Error("Questgiver is: " .. questgiver)
            Questie:Error("Client info is: " .. GetBuildInfo() .. "; " .. QuestieLib:GetAddonVersionString())
            return
        end
    end
    for i, titleLine in ipairs(titleLines) do
        if (titleLine:IsVisible()) then
            local lineIcon = questIconTextures[i]
            -- determining if the current line is a "Current" quest or "Available" quest is important
            -- because we have to use different API calls to obtain their quest titles
            if (titleLine.isActive == 1) then
                lineIcon:SetTexture(Questie.icons["incomplete"]) -- fallback icon in case any of the logic below fails
                local title = GetActiveTitle(titleLine:GetID()) -- obtain plaintext name of quest
                local questID = QuestieDB.GetQuestIDFromName(title, questgiver, false)
                local icon = determineAppropriateQuestIcon(questID, true)
                lineIcon:SetTexture(icon)
            else
                lineIcon:SetTexture(Questie.icons["available"]) -- fallback icon in case any of the logic below fails
                local title = GetAvailableTitle(titleLine:GetID())
                local questID = QuestieDB.GetQuestIDFromName(title, questgiver, true)
                local icon = determineAppropriateQuestIcon(questID, false)
                lineIcon:SetTexture(icon)
            end
        end
    end
end

function QuestgiverFrame.GossipMark()
    if Questie.db.profile.enableQuestFrameIcons == true then
        if GossipAvailableQuestButtonMixin then -- This call is added with Dragonflight (10.0.0) API, use if available
            return -- This call is automatically hooked, no need to run a function
        else -- If DF API not available, use Shadowlands (9.0.0) method
            updateGossipFrame()
        end
    end
end

function QuestgiverFrame.GreetingMark()
    if Questie.db.profile.enableQuestFrameIcons == true then
        updateGreetingFrame()
    end
end

-- 10.0.0 API GOSSIP
-- Boy, this code is clean... these DF Gossip APIs sure are great!
-- What a shame that the greeting API hasn't been touched in two decades.
if GossipAvailableQuestButtonMixin then
    local oldAvailableSetup = GossipAvailableQuestButtonMixin.Setup
    function GossipAvailableQuestButtonMixin:Setup(...)
        oldAvailableSetup(self, ...)
        if (not Questie.started) then
            return
        end

        if self.GetElementData ~= nil and Questie.db.profile.enableQuestFrameIcons == true then
            local id = self.GetElementData().info.questID
            if id then
                self.Icon:SetTexture(determineAppropriateQuestIcon(id, false))
            else
                Questie:Error("Frame error! Missing Gossip line item quest ID. Please report this on Github or Discord!")
                Questie:Error("Questgiver for available quest is: " .. UnitGUID("npc"))
                Questie:Error("Client info is: " .. GetBuildInfo() .. "; " .. QuestieLib:GetAddonVersionString())
                return
            end
        end
    end

    local oldActiveSetup = GossipActiveQuestButtonMixin.Setup
    function GossipActiveQuestButtonMixin:Setup(...)
        oldActiveSetup(self, ...)
        if (not Questie.started) then
            return
        end

        if self.GetElementData ~= nil and Questie.db.profile.enableQuestFrameIcons == true then
            local id = self.GetElementData().info.questID
            if id then
                self.Icon:SetTexture(determineAppropriateQuestIcon(id, true))
            else
                Questie:Error("Frame error! Missing Gossip line item quest ID. Please report this on Github or Discord!")
                Questie:Error("Questgiver for active quest is: " .. UnitGUID("npc"))
                Questie:Error("Client info is: " .. GetBuildInfo() .. "; " .. QuestieLib:GetAddonVersionString())
                return
            end
        end
    end
end

-- ============================================================
-- Grimfall quest capture
-- ============================================================

local GrimfallCaptureFrame = CreateFrame("Frame")

GrimfallCaptureFrame:RegisterEvent("QUEST_ACCEPTED")

GrimfallCaptureFrame:SetScript("OnEvent", function(self, event, ...)

    if not QuestieDB.GrimfallMissingQuests then
        return
    end

    if event == "QUEST_ACCEPTED" then
        local questLogIndex, questID = ...

        -- 3.3.5 fallback: get the quest ID from the quest log entry
        if not questID and questLogIndex then
            questID = select(8, QuestieCompat.GetQuestLogTitle(questLogIndex))
        end

        if not questID or questID == 0 then
            return
        end

        local questTitle

        if questLogIndex then
            questTitle = QuestieCompat.GetQuestLogTitle(questLogIndex)
        end

        if not questTitle then
            return
        end

        local missing = QuestieDB.GrimfallMissingQuests[questTitle]

        if not missing then
            return
        end

        Questie:Print(
            "|cff00ff00[Grimfall]|r "
            .. 'GrimfallQuestStarter("'
            .. missing.giverType
            .. '", '
            .. questID
            .. ', '
            .. missing.giverID
            .. ', "'
            .. questTitle
            .. '")'
        )

        QuestieDB.GrimfallMissingQuests[questTitle] = nil
    end
end)

-- ============================================================
-- Grimfall Quest ID Scanner
--
-- Usage:
--   /gfscan 1200 1450
--   /gfstop
--
-- It requests each quest once, waits for the server response,
-- then queries it again and prints the name if one exists.
-- ============================================================

local GFScanTooltip = CreateFrame(
    "GameTooltip",
    "GFScanTooltip",
    UIParent,
    "GameTooltipTemplate"
)

GFScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local GFScanner = CreateFrame("Frame")

GFScanner.running = false
GFScanner.currentID = 0
GFScanner.endID = 0
GFScanner.stage = 1
GFScanner.elapsed = 0

-- How long to wait between the first request and reading it back.
-- Increase this if your connection/server is slow.
GFScanner.delay = 1.0


local function GFRequestQuest(questID)
    GFScanTooltip:ClearLines()

    pcall(
        GFScanTooltip.SetHyperlink,
        GFScanTooltip,
        "quest:" .. questID .. ":60"
    )
end


local function GFReadQuestName(questID)
    GFScanTooltip:ClearLines()

    local success = pcall(
        GFScanTooltip.SetHyperlink,
        GFScanTooltip,
        "quest:" .. questID .. ":60"
    )

    if not success then
        return nil
    end

    local titleRegion = _G["GFScanTooltipTextLeft1"]

    if not titleRegion then
        return nil
    end

    local title = titleRegion:GetText()

    if not title or title == "" then
        return nil
    end

    -- Ignore Blizzard's temporary cache/loading text
    if string.find(string.lower(title), "retrieving") then
        return nil
    end

    return title
end


GFScanner:SetScript("OnUpdate", function(self, elapsed)

    if not self.running then
        return
    end

    self.elapsed = self.elapsed + elapsed

    if self.elapsed < self.delay then
        return
    end

    self.elapsed = 0

    ------------------------------------------------------------
    -- STAGE 1:
    -- Ask the server/client for this quest ID.
    ------------------------------------------------------------
    if self.stage == 1 then

        GFRequestQuest(self.currentID)

        self.stage = 2
        return
    end

    ------------------------------------------------------------
    -- STAGE 2:
    -- Query it again after the cache had time to populate.
    ------------------------------------------------------------
    if self.stage == 2 then

        local questName = GFReadQuestName(self.currentID)

        if questName then
            Questie:Print(
                "|cff00ff00[GFSCAN]|r "
                .. self.currentID
                .. " = "
                .. questName
            )
        end

        --------------------------------------------------------
        -- Move to next ID
        --------------------------------------------------------

        self.currentID = self.currentID + 1
        self.stage = 1

        if self.currentID > self.endID then
            self.running = false

            Questie:Print(
                "|cff00ff00[GFSCAN]|r Scan complete."
            )
        end
    end
end)


SLASH_GFSCAN1 = "/gfscan"

SlashCmdList["GFSCAN"] = function(msg)

    local startID, endID = string.match(
        msg,
        "^(%d+)%s+(%d+)$"
    )

    startID = tonumber(startID)
    endID = tonumber(endID)

    if not startID or not endID then
        Questie:Print(
            "|cffffd200[GFSCAN]|r Usage: /gfscan START END"
        )

        Questie:Print(
            "|cffffd200[GFSCAN]|r Example: /gfscan 1200 1450"
        )

        return
    end

    if endID < startID then
        Questie:Print(
            "|cffff0000[GFSCAN]|r End ID must be higher than start ID."
        )

        return
    end

    -- Safety limit
    if (endID - startID) > 500 then
        Questie:Print(
            "|cffff0000[GFSCAN]|r Maximum range is 500 IDs at once."
        )

        return
    end

    GFScanner.currentID = startID
    GFScanner.endID = endID
    GFScanner.stage = 1
    GFScanner.elapsed = 0
    GFScanner.running = true

    Questie:Print(
        "|cff00ff00[GFSCAN]|r Scanning quests "
        .. startID
        .. " through "
        .. endID
        .. "..."
    )
end


SLASH_GFSTOP1 = "/gfstop"

SlashCmdList["GFSTOP"] = function()

    GFScanner.running = false

    Questie:Print(
        "|cffffd200[GFSCAN]|r Scan stopped."
    )
end