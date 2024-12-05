local _, BigFootSync = ...
BigFootSync.equipment = {}

local E = BigFootSync.equipment

---------------------------------------------------------------------
-- 保存玩家自己的装备信息
---------------------------------------------------------------------
-- https://warcraft.wiki.gg/wiki/InventorySlotId

local INV_NAME_SLOT = {
    ["head"] = INVSLOT_HEAD,
    ["neck"] = INVSLOT_NECK,
    ["shoulders"] = INVSLOT_SHOULDER,
    ["shirt"] = INVSLOT_BODY,
    ["chest"] = INVSLOT_CHEST,
    ["waist"] = INVSLOT_WAIST,
    ["legs"] = INVSLOT_LEGS,
    ["feet"] = INVSLOT_FEET,
    ["wrist"] = INVSLOT_WRIST,
    ["hand"] = INVSLOT_HAND,
    ["finger1"] = INVSLOT_FINGER1,
    ["finger2"] = INVSLOT_FINGER2,
    ["trinket1"] = INVSLOT_TRINKET1,
    ["trinket2"] = INVSLOT_TRINKET2,
    ["back"] = INVSLOT_BACK,
    ["mainHand"] = INVSLOT_MAINHAND,
    ["offHand"] = INVSLOT_OFFHAND,
    ["tabard"] = INVSLOT_TABARD,
}

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
    [INVSLOT_HAND] = "hand",
    [INVSLOT_FINGER1] = "finger1",
    [INVSLOT_FINGER2] = "finger2",
    [INVSLOT_TRINKET1] = "trinket1",
    [INVSLOT_TRINKET2] = "trinket2",
    [INVSLOT_BACK] = "back",
    [INVSLOT_MAINHAND] = "mainHand",
    [INVSLOT_OFFHAND] = "offHand",
    [INVSLOT_TABARD] = "tabard",
}

if BigFootSync.isVanilla or BigFootSync.isWrath then
    INV_NAME_SLOT["ammo"] = INVSLOT_AMMO
    INV_NAME_SLOT["ranged"] = INVSLOT_RANGED
    INV_SLOT_NAME[INVSLOT_AMMO] = "ammo"
    INV_SLOT_NAME[INVSLOT_RANGED] = "ranged"
end

local GetInventoryItemLink = GetInventoryItemLink

function E.UpdateEquipments(t, slot)
    if slot then
        -- local link = GetInventoryItemLink("player", slot)
        -- print(string.gsub(link, "\124", "\124\124"))
        -- print(string.match(link, "item[%-?%d:]+"))
        t[INV_SLOT_NAME[slot]] = GetInventoryItemLink("player", slot) or ""
    else
        for name, id in pairs(INV_NAME_SLOT) do
            -- local link = GetInventoryItemLink("player", id)
            -- print(string.gsub(link, "\124", "\124\124"))
            -- print(string.match(link, "item[%-?%d:]+"))
            t[name] = GetInventoryItemLink("player", id) or ""
        end
    end
end