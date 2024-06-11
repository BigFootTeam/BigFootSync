local _, BigFootBot = ...
BigFootBot.utils = {}

BigFootBot.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
BigFootBot.isVanilla = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
BigFootBot.isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
BigFootBot.isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC

local U = BigFootBot.utils

---------------------------------------------------------------------
-- GetClassID
---------------------------------------------------------------------
local localizedClass = {}
FillLocalizedClassList(localizedClass)

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
-- UnitFullName
---------------------------------------------------------------------
function U.UnitFullName(unit)
    if not unit or not UnitIsPlayer(unit) then return end

    local name = GetUnitName(unit, true)
    
    if name and not string.find(name, "-") then -- 同服角色不带服务器名
        local realm = GetNormalizedRealmName() -- 不可使用 GetRealmName()，其中可能包含空格或短横线
        if realm then
            name = name.."-"..realm
        end
    end
    
    return name
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