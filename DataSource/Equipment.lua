local _, BigFootSync = ...
BigFootSync.equipment = {}

local E = BigFootSync.equipment

---------------------------------------------------------------------
-- 保存玩家自己的装备信息
---------------------------------------------------------------------
-- https://warcraft.wiki.gg/wiki/InventorySlotId
local INV_SLOT_NAME = {
    [INVSLOT_HEAD] = "head",
    [INVSLOT_NECK] = "neck",
    [INVSLOT_SHOULDER] = "shoulders",
    [INVSLOT_BODY] = "shirt",
    [INVSLOT_CHEST] = "chest",
    [INVSLOT_WAIST] = "waist",
    [INVSLOT_LEGS] = "legs",
    [INVSLOT_FEET] = "feet",
    [INVSLOT_WRIST] = "wrist",
    [INVSLOT_HAND] = "hands",
    [INVSLOT_FINGER1] = "finger1",
    [INVSLOT_FINGER2] = "finger2",
    [INVSLOT_TRINKET1] = "trinket1",
    [INVSLOT_TRINKET2] = "trinket2",
    [INVSLOT_BACK] = "back",
    [INVSLOT_MAINHAND] = "main_hand",
    [INVSLOT_OFFHAND] = "off_hand",
    [INVSLOT_TABARD] = "tabard",
}

if BigFootSync.isVanilla or BigFootSync.isWrath then
    INV_SLOT_NAME[INVSLOT_AMMO] = "ammo"
    INV_SLOT_NAME[INVSLOT_RANGED] = "ranged"
end

local GetInventoryItemLink = GetInventoryItemLink
local GetItemName = C_Item.GetItemName
local GetItemCraftedQualityByItemInfo = C_TradeSkillUI and C_TradeSkillUI.GetItemCraftedQualityByItemInfo
local GetItemStats = GetItemStats or C_Item.GetItemStats
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo or C_Item.GetDetailedItemLevelInfo

local ID_INDEX = 1
local ENCHANT_INDEX = 2
local GEM_INDEX_START, GEM_INDEX_END = 3, 6
local SUFFIX_INDEX = 7
-- local SPEC_INDEX = 10
local CONTEXT_INDEX = 12
local BONUS_INDEX = 13
local CRAFTING_STAT_1 = Enum.ItemModification.ChangeModifiedCraftingStat_1
local CRAFTING_STAT_2 = Enum.ItemModification.ChangeModifiedCraftingStat_2

local function ExtractEquipmentData(slot)
    local data = {}
    local link = GetInventoryItemLink("player", slot)

    if link then
        -- print(string.gsub(link, "\124", "\124\124"))
        -- print(string.match(link, "item[%-?%d:]+"))

        local str = strmatch(link, "|Hitem:(.+)|h.+|h")
        -- local str, name = strmatch(link, "|Hitem:(.+)|h%[([^|]+).*%]|h")
        -- data.name = strtrim(name) -- not always available

        local t = {strsplit(":", str)}
        for k, v in pairs(t) do
            if v == "" then
                t[k] = nil
            else
                t[k] = tonumber(v)
            end
        end

        -- slot
        data.slot = INV_SLOT_NAME[slot]

        -- id
        data.id = t[ID_INDEX]

        -- enchant
        data.enchant = t[ENCHANT_INDEX]

        -- gems
        data.gems = {}
        for k = GEM_INDEX_START, GEM_INDEX_END do
            if t[k] then
                tinsert(data.gems, t[k])
            end
        end

        -- suffix
        data.suffix = t[SUFFIX_INDEX]

        -- context (source)
        data.context = t[CONTEXT_INDEX]

        -- bonuses
        data.bonuses = {}
        local numBonusIDs = t[BONUS_INDEX]
        if numBonusIDs then
            local bonusIndex = BONUS_INDEX + 1
            for i = 1, numBonusIDs do
                tinsert(data.bonuses, t[i])
                bonusIndex = bonusIndex + 1
            end
        end

        -- modifiers
        data.modifiers = {}
        local modifierIndex = BONUS_INDEX + (numBonusIDs or 0) + 1
        local numModifiers = t[modifierIndex]
        if numModifiers then
            local modifierKeyIndex = modifierIndex + 1
            for i = 1, numModifiers do
                data.modifiers[t[modifierKeyIndex]] = t[modifierKeyIndex + 1]
                modifierKeyIndex = modifierKeyIndex + 2
            end
        end

        -- simc
        data.simc = data.slot .. "=,id=" .. data.id
        if data.enchant then
            data.simc = data.simc .. ",enchant_id=" .. data.enchant
        end
        if #data.gems ~= 0 then
            data.simc = data.simc .. ",gem_id=" .. table.concat(data.gems, "/")
        end
        if #data.bonuses ~= 0 then
            data.simc = data.simc .. ",bonus_id=" .. table.concat(data.bonuses, "/")
        end

        if BigFootSync.isRetail then
            -- craftedStats
            data.craftedStats = {}
            if data.modifiers[CRAFTING_STAT_1] then
                tinsert(data.craftedStats, data.modifiers[CRAFTING_STAT_1])
            end
            if data.modifiers[CRAFTING_STAT_2] then
                tinsert(data.craftedStats, data.modifiers[CRAFTING_STAT_2])
            end

            -- crafted quality
            data.craftedQuality = GetItemCraftedQualityByItemInfo(link)

            -- simc
            if #data.craftedStats ~= 0 then
                data.simc = data.simc .. ",crafted_stats=" .. table.concat(data.craftedStats, "/")
            end
            if data.craftedQuality then
                data.simc = data.simc .. ",crafting_quality=" .. data.craftedQuality
            end
        end

        -- stats
        data.stats = GetItemStats(link)

        -- level
        data.level = GetDetailedItemLevelInfo(link)
    end
    return data
end

function E.UpdateEquipments(t, slot)
    if slot then
        t[INV_SLOT_NAME[slot]] = ExtractEquipmentData(slot)
    else
        for id in pairs(INV_SLOT_NAME) do
            t[INV_SLOT_NAME[id]] = ExtractEquipmentData(id)
        end
    end
end