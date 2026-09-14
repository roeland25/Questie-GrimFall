local GrimfallFixes = QuestieLoader:CreateModule("GrimfallFixes")
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")

-- ============================================================
-- Grimfall easy quest database
--
-- Paste generated lines in the section marked below.
--
-- Format:
-- GrimfallQuestStarter("GameObject", QUEST_ID, OBJECT_ID, "Quest Name")
-- GrimfallQuestStarter("Creature", QUEST_ID, NPC_ID, "Quest Name")
-- ============================================================

local grimfallQuests = {}
local grimfallObjects = {}
local grimfallNPCs = {}


-- ============================================================
-- Helper used by the generated lines
-- ============================================================

local function GrimfallQuestStarter(giverType, questID, giverID, questName)

    -- Store the quest itself
    grimfallQuests[questID] = grimfallQuests[questID] or {
        name = questName,
        npcStarters = {},
        objectStarters = {},
    }

    local quest = grimfallQuests[questID]

    quest.name = questName or quest.name

    if giverType == "GameObject" then

        table.insert(quest.objectStarters, giverID)

        grimfallObjects[giverID] = grimfallObjects[giverID] or {
            questStarts = {},
        }

        table.insert(
            grimfallObjects[giverID].questStarts,
            questID
        )

    elseif giverType == "Creature" then

        table.insert(quest.npcStarters, giverID)

        grimfallNPCs[giverID] = grimfallNPCs[giverID] or {
            questStarts = {},
        }

        table.insert(
            grimfallNPCs[giverID].questStarts,
            questID
        )

    else
        error(
            "GrimfallQuestStarter: Unknown giver type: "
            .. tostring(giverType)
        )
    end
end


-- ============================================================
-- GRIMFALL CUSTOM QUESTS:
--
-- Alliance callboard ID: 278574
-- Horde callboard ID: 278457
--
-- ============================================================

-- ============================================================
-- Callboard quests:
-- ============================================================

GrimfallQuestStarter("GameObject", 1225, 278574, "Call to Arms: Tol Barad")
GrimfallQuestStarter("GameObject", 1359, 278574, "Call to Arms: Outland")
GrimfallQuestStarter("GameObject", 1400, 278574, "Call to Arms: Outland")
GrimfallQuestStarter("GameObject", 1401, 278574, "Call to Arms: Northrend")
GrimfallQuestStarter("GameObject", 1402, 278574, "Call to Arms: Northrend")

GrimfallQuestStarter("GameObject", 1408, 278574, "Adventurer's Change of Destiny: Part One")
GrimfallQuestStarter("GameObject", 1409, 278574, "Adventurer's Call of Reshaping: Part One")
GrimfallQuestStarter("GameObject", 1410, 278574, "Adventurer's Change of Destiny: Part Two")
GrimfallQuestStarter("GameObject", 1411, 278574, "Adventurer's Call of Reshaping: Part Two")
GrimfallQuestStarter("GameObject", 1412, 278574, "Adventurer's Change of Destiny: Part Three")
GrimfallQuestStarter("GameObject", 1413, 278574, "Adventurer's Call of Reshaping: Part Three")
GrimfallQuestStarter("GameObject", 1414, 278574, "Adventurer's Change of Destiny: Part Four")
GrimfallQuestStarter("GameObject", 1415, 278574, "Adventurer's Call of Reshaping: Part Four")
GrimfallQuestStarter("GameObject", 1416, 278574, "Adventurer's Change of Destiny: Part Five")
GrimfallQuestStarter("GameObject", 1417, 278574, "Adventurer's Call of Reshaping: Part Five")

GrimfallQuestStarter("GameObject", 1493, 278574, "Continued Adventure of Destiny: Part One")
GrimfallQuestStarter("GameObject", 1494, 278574, "Continued Adventure of Destiny: Part Two")
GrimfallQuestStarter("GameObject", 1495, 278574, "Continued Adventure of Reshaping: Part One")
GrimfallQuestStarter("GameObject", 1496, 278574, "Continued Adventure of Reshaping: Part Two")
GrimfallQuestStarter("GameObject", 1497, 278574, "Continued Adventure of Destiny: Part One (Tol Barad)")
GrimfallQuestStarter("GameObject", 1539, 278574, "Continued Adventure of Destiny: Part Two (Tol Barad)")
GrimfallQuestStarter("GameObject", 1540, 278574, "Continued Adventure of Reshaping: Part One (Heroic Dungeons)")
GrimfallQuestStarter("GameObject", 1541, 278574, "Continued Adventure of Destiny: Part Two (Heroic Dungeons)")
GrimfallQuestStarter("GameObject", 1542, 278574, "Continued Adventure of Destiny: Part Three (Heroic Dungeons)")
GrimfallQuestStarter("GameObject", 1543, 278574, "Continued Adventure of Destiny: Part Four (Heroic Dungeons)")

-- ============================================================
-- Chromie/prestige quests:
-- ============================================================
GrimfallQuestStarter("Creature", 1403, 779, "A Fracture in Time")
GrimfallQuestStarter("GameObject", 1405, 278574, "Prestige: Fractured Timeways")

-- ============================================================
-- Everything below automatically creates Questie's DB entries.
-- ============================================================

function GrimfallFixes:LoadQuests()
    local q = QuestieDB.questKeys
    local result = {}

    for questID, data in pairs(grimfallQuests) do

        local npcStarters = nil
        local objectStarters = nil

        if #data.npcStarters > 0 then
            npcStarters = data.npcStarters
        end

        if #data.objectStarters > 0 then
            objectStarters = data.objectStarters
        end

        result[questID] = {
            [q.name] = data.name,

            [q.startedBy] = {
                npcStarters,
                objectStarters,
                nil, -- Item
            },

            [q.finishedBy] = {
                nil, -- NPC
                nil, -- GameObject
            },

            [q.objectives] = {
                nil, -- NPC objectives
                nil, -- Object objectives
                nil, -- Item objectives
                nil, -- Reputation objectives
            },
            
            [q.requiredLevel] = 1,
            [q.questLevel] = -1,

            -- Questie expects this to be a number
            [q.sourceItemId] = 0,
        }
    end

    return result
end


function GrimfallFixes:LoadObjects()
    local o = QuestieDB.objectKeys
    local result = {}

    for objectID, data in pairs(grimfallObjects) do
        result[objectID] = {
            [o.questStarts] = data.questStarts,
        }
    end

    return result
end


function GrimfallFixes:LoadNPCs()
    local n = QuestieDB.npcKeys
    local result = {}

    for npcID, data in pairs(grimfallNPCs) do
        result[npcID] = {
            [n.questStarts] = data.questStarts,
        }
    end

    return result
end


return GrimfallFixes