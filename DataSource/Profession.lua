---@class BigFootSync
local BigFootSync = select(2, ...)
BigFootSync.profession = {}

---@class Profession
local PF = BigFootSync.profession

local GetProfessions = GetProfessions
local GetProfessionInfo = GetProfessionInfo

---------------------------------------------------------------------
-- profession names
---------------------------------------------------------------------
local porfNames = {
    [129] = "first_aid",
    [164] = "blacksmithing",
    [165] = "leatherworking",
    [171] = "alchemy",
    [182] = "herbalism",
    [184] = "cooking",
    [186] = "mining",
    [197] = "tailoring",
    [202] = "engineering",
    [333] = "enchanting",
    [356] = "fishing",
    [393] = "skinning",
    [755] = "jewelcrafting",
    [773] = "inscription",
    [794] = "archaeology"
}

---------------------------------------------------------------------
-- profession
---------------------------------------------------------------------
function PF:GetProfessions()
    if not (GetProfessions and GetProfessionInfo) then
        -- TODO: WotLK: GetNumSkillLines & GetSkillLineInfo
        return ""
    end

    local prof1, prof2 = GetProfessions()
    local professions = {}
    local _, skillLevel, skillLine

    if prof1 then
        -- name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset
        _, _, skillLevel, _, _, _, skillLine = GetProfessionInfo(prof1)
        if porfNames[skillLine] then
            tinsert(professions, porfNames[skillLine] .. "=" .. skillLevel)
        end
    end

    if prof2 then
        _, _, skillLevel, _, _, _, skillLine = GetProfessionInfo(prof2)
        if porfNames[skillLine] then
            tinsert(professions, porfNames[skillLine] .. "=" .. skillLevel)
        end
    end

    return table.concat(professions, "/")
end