local _, BigFootBot = ...
BigFootBot.utils = {}

BigFootBot.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
BigFootBot.isVanilla = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
BigFootBot.isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
BigFootBot.isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC

local U = BigFootBot.utils

---------------------------------------------------------------------
-- GetBigFootClientVersion
---------------------------------------------------------------------
function U.GetBigFootClientVersion(wowProjectID)
    wowProjectID = wowProjectID or WOW_PROJECT_ID
    if wowProjectID == WOW_PROJECT_MAINLINE then
        return 0
    elseif wowProjectID == WOW_PROJECT_CLASSIC then
        return 1
    elseif wowProjectID == WOW_PROJECT_WRATH_CLASSIC then
        return 3
    else
        return 2
    end
end

---------------------------------------------------------------------
-- GetClassID
---------------------------------------------------------------------
local localizedClass
if FillLocalizedClassList then
    localizedClass = {}
    FillLocalizedClassList(localizedClass)
else
    localizedClass = LocalizedClassList()
end

local classFileToID = {}
local localizedClassToID = {}

do
    -- WARRIOR = 1,
    -- PALADIN = 2,
    -- HUNTER = 3,
    -- ROGUE = 4,
    -- PRIEST = 5,
    -- DEATHKNIGHT = 6,
    -- SHAMAN = 7,
    -- MAGE = 8,
    -- WARLOCK = 9,
    -- MONK = 10,
    -- DRUID = 11,
    -- DEMONHUNTER = 12,
    -- EVOKER = 13,
    for i = 1, GetNumClasses() do
        local classFile = select(2, GetClassInfo(i))
        if classFile then -- returns nil for classes not exist in Classic
            classFileToID[classFile] = i
            localizedClassToID[localizedClass[classFile]] = i
        end
    end
end

function U.GetClassID(class)
    return classFileToID[class] or localizedClassToID[class]
end

---------------------------------------------------------------------
-- UnitName
---------------------------------------------------------------------
function U.UnitName(unit)
    if not unit or not UnitIsPlayer(unit) then return end

    local name, realm = UnitNameUnmodified(unit)
    if not name or name == "" then return end

    -- 同服角色不带服务器名，不可使用 GetRealmName()，其中可能包含空格或短横线
    if not realm then realm = GetNormalizedRealmName() end
    if not realm or realm == "" then return end

    return name.."-"..realm, name, realm
end

---------------------------------------------------------------------
-- UnitShortName
---------------------------------------------------------------------
function U.ToShortName(fullName)
    if not fullName then return "" end
    local shortName = strsplit("-", fullName)
    return shortName
end

---------------------------------------------------------------------
-- IterateGroupMembers
---------------------------------------------------------------------
function U.IterateGroupMembers()
    local groupType = IsInRaid() and "raid" or "party"
    local numGroupMembers = GetNumGroupMembers()
    local i

    if groupType == "party" then
        i = 0
        numGroupMembers = numGroupMembers - 1
    else
        i = 1
    end

    return function()
        local ret
        if i == 0 then
            ret = "player"
        elseif i <= numGroupMembers and i > 0 then
            ret = groupType .. i
        end
        i = i + 1
        return ret
    end
end