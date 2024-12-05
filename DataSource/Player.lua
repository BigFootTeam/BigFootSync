local _, BigFootSync = ...
BigFootSync.player = {}

local P = BigFootSync.player
local U = BigFootSync.utils

---------------------------------------------------------------------
-- 通过unitId保存单位的基础信息
---------------------------------------------------------------------
function P.SaveUnitBaseData(t, unit, useFullNameAsIndex)
    if not UnitIsPlayer(unit) then return end

    -- 全名
    local fullName, name, realm = U.UnitName(unit)
    if not (fullName and name and realm) then return end

    -- 对于所有玩家的数据保存，以全名为索引
    if useFullNameAsIndex then
        if not t[fullName] then t[fullName] = {} end
        t = t[fullName]
    else
        t["fullName"] = fullName
    end

    t["incomplete"] = nil

    -- guid（可能发生变化）
    t["guid"] = UnitGUID(unit)
    -- 名字（短）
    t["name"] = name
    -- 服务器（normalized）
    t["realm"] = realm
    -- 等级
    t["level"] = UnitLevel(unit)
    -- 性别
    t["gender"] = UnitSex(unit)
    -- 种族
    t["raceId"] = select(3, UnitRace(unit))
    -- 职业
    t["classId"] = select(2, UnitClassBase(unit))
    -- 阵营
    t["faction"] = UnitFactionGroup(unit)
    -- 公会
    t["guild"] = GetGuildInfo(unit)
    -- 地区（为了客户端读取方便）
    t["region"] = BFS_Account["region"]
    -- 游戏版本（为了客户端读取方便）
    t["version"] = U.GetBigFootClientVersion()
    -- 更新时间
    t["lastSeen"] = GetServerTime()

    -- 自己的装等
    if UnitIsUnit("player", unit) and t["level"] == U.GetMaxLevel() then
        t["itemLevel"] = Round(select(2, GetAverageItemLevel()))
    end
end


---------------------------------------------------------------------
-- 保存玩家自己的属性信息
---------------------------------------------------------------------
function P.SavePlayerStatData(t)
    -- 主属性
    local stats = {"strength", "agility", "stamina", "intellect"}
    if not BigFootSync.isRetail then tinsert(stats, "spirit") end
    for k, v in pairs(stats) do
        t[v] = select(2, UnitStat("player", k)) -- stat, effectiveStat, posBuff(包括装备), negBuff
    end

    -- 最大生命值
    t["healthMax"] = UnitHealthMax("player")
    -- 最大能量值
    t["powerMax"] = UnitPowerMax("player")
    -- 能量类型 TODO: 根据天赋仅保存主要能量类型，目前保存当前类型
    t["powerType"] = UnitPowerType("player", 0) -- MANA
    -- 护甲值
    t["armor"] = select(2, UnitArmor("player"))
    -- 护甲物理减伤百分比（目标等级相同时）
    t["armorEffectiveness"] = C_PaperDollInfo.GetArmorEffectiveness(t["armor"], UnitLevel("player"))
    -- 急速（直接加百分号，怀旧服使用 CR_HASTE_*）
    t["haste"] = GetHaste()
    -- 暴击率（直接加百分号）
    t["critChance"] = GetCritChance()
    -- 躲闪概率（直接加百分号）
    t["dodgeChance"] = GetDodgeChance()
    -- 招架概率（直接加百分号）
    t["parryChance"] = GetParryChance()
    -- 格挡概率（直接加百分号）
    t["blockChance"] = GetBlockChance()

    -- spellBonusDamage
    -- 1 Physical
    -- 2 Holy
    -- 3 Fire
    -- 4 Nature
    -- 5 Frost
    -- 6 Shadow
    -- 7 Arcane
    t["spellBonusDamage"] = 0
    for i = 1, 7 do
        local sbd = GetSpellBonusDamage(i)
        if sbd > t["spellBonusDamage"] then
            t["spellBonusDamage"] = sbd
        end
    end

    -- reset
    t["versatility"] = nil
    t["leech"] = nil
    t["avoidance"] = nil
    t["speed"] = nil
    t["resistance"] = nil

    if BigFootSync.isRetail then
        -- 全能（直接加百分号，伤害增加值，若要获取受到伤害减免值，除以2即可）
        t["versatility"] = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
        -- 吸血
        t["leech"] = GetLifesteal()
        -- 闪避
        t["avoidance"] = GetAvoidance()
        -- 加速
        t["speed"] = GetSpeed()
    else
        -- 抗性 https://warcraft.wiki.gg/wiki/API_UnitResistance
        t["resistance"] = {
            -- ["physical"] = 0,
            ["holy"] = 1,
            ["fire"] = 2,
            ["nature"] = 3,
            ["forst"] = 4,
            ["shadow"] = 5,
            ["arcane"] = 6,
        }
        for k, i in pairs(t["resistance"]) do
            t["resistance"][k] = select(2, UnitResistance("player", i))
        end
    end
end


---------------------------------------------------------------------
-- 保存玩家自己的 CombatRating 和 CombatRatingBonus
---------------------------------------------------------------------
local CR_RETAIL = {
    -- "CR_UNUSED_1", -- 1
    "CR_DEFENSE_SKILL", -- 2
    "CR_DODGE", -- 3
    "CR_PARRY", -- 4
    "CR_BLOCK", -- 5
    "CR_HIT_MELEE", -- 6
    "CR_HIT_RANGED", -- 7
    "CR_HIT_SPELL", -- 8
    "CR_CRIT_MELEE", -- 9
    "CR_CRIT_RANGED", -- 10
    "CR_CRIT_SPELL", -- 11
    "CR_CORRUPTION", -- 12
    "CR_CORRUPTION_RESISTANCE", -- 13
    "CR_SPEED", -- 14
    "COMBAT_RATING_RESILIENCE_CRIT_TAKEN", -- 15
    "COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN", -- 16
    "CR_LIFESTEAL", -- 17
    "CR_HASTE_MELEE", -- 18
    "CR_HASTE_RANGED", -- 19
    "CR_HASTE_SPELL", -- 20
    "CR_AVOIDANCE", -- 21
    -- "CR_UNUSED_2", -- 22
    "CR_WEAPON_SKILL_RANGED", -- 23
    "CR_EXPERTISE", -- 24
    "CR_ARMOR_PENETRATION", -- 25
    "CR_MASTERY", -- 26
    -- "CR_UNUSED_3", -- 27
    -- "CR_UNUSED_4", -- 28
    "CR_VERSATILITY_DAMAGE_DONE", -- 29
    "CR_VERSATILITY_DAMAGE_TAKEN", -- 31
}

local CR_WRATH = {
    "CR_WEAPON_SKILL", -- 1
    "CR_DEFENSE_SKILL", -- 2
    "CR_DODGE", -- 3
    "CR_PARRY", -- 4
    "CR_BLOCK", -- 5
    "CR_HIT_MELEE", -- 6
    "CR_HIT_RANGED", -- 7
    "CR_HIT_SPELL", -- 8
    "CR_CRIT_MELEE", -- 9
    "CR_CRIT_RANGED", -- 10
    "CR_CRIT_SPELL", -- 11
    "CR_RESILIENCE_CRIT_TAKEN", -- 15
    "CR_RESILIENCE_PLAYER_DAMAGE_TAKEN", -- 16
    "CR_HASTE_MELEE", -- 18
    "CR_HASTE_RANGED", -- 19
    "CR_HASTE_SPELL", -- 20
    "CR_EXPERTISE", -- 24
    "CR_ARMOR_PENETRATION", -- 25
}

local function SavePlayerCombatRatingData(t)
    local CR
    if BigFootSync.isRetail then
        CR = CR_RETAIL
    elseif BigFootSync.isWrath then
        CR = CR_WRATH
    elseif BigFootSync.isCata then
        CR = CR_CATA -- TODO: 之后再说
    end
    if not CR then return end

    for _, cr in pairs(CR) do
        if type(_G[cr]) == "number" then
            -- 数值
            t["combatRating"][cr] = GetCombatRating(_G[cr])
            -- 百分比
            t["combatRatingBonus"][cr] = GetCombatRatingBonus(_G[cr])
        end
    end
end


---------------------------------------------------------------------
-- 平均装等
---------------------------------------------------------------------
local cached = {}
function P.ShouldUpdateUnitItemLevel(guid)
    return not cached[guid]
end

if BigFootSync.isRetail then
    local SLOTS = {
        INVSLOT_HEAD,
        INVSLOT_NECK,
        INVSLOT_SHOULDER,
        INVSLOT_CHEST,
        INVSLOT_WAIST,
        INVSLOT_LEGS,
        INVSLOT_FEET,
        INVSLOT_WRIST,
        INVSLOT_HAND,
        INVSLOT_FINGER1,
        INVSLOT_FINGER2,
        INVSLOT_TRINKET1,
        INVSLOT_TRINKET2,
        INVSLOT_BACK,
        INVSLOT_MAINHAND,
        INVSLOT_OFFHAND,
    }

    local NUM_SLOTS = 16

    local TWO_HANDED = {
        INVTYPE_2HWEAPON = true,
        INVTYPE_RANGED = true,
        INVTYPE_RANGEDRIGHT = true,
    }

    local ITEM_LEVEL_PATTERN = ITEM_LEVEL:gsub("%%d", "(%%d+)")
    local ITEM_LEVEL_ALT_PATTERN = ITEM_LEVEL_ALT:gsub("%%d %(%%d%)", "%%d+ %%((%%d+)%%)")

    local GetTooltipData = C_TooltipInfo.GetInventoryItem
    -- local scanner = CreateFrame("GameTooltip", "BigFootScanner", UIParent, "GameTooltipTemplate")
    -- if not GetTooltipData then
    --     GetTooltipData = function(unit, slot)
    --         scanner:SetOwner(UIParent, "ANCHOR_NONE")
    --         local hasItem = scanner:SetInventoryItem(unit, slot)
    --         if hasItem then
    --             scanner:Show()
    --             return scanner:GetTooltipData()
    --         end
    --     end
    -- end

    local function GetSlotInfo(unit, slot)
        local item = GetInventoryItemLink(unit, slot)
        if item then
            local _, _, quality, _, _, _, _, _, equipLoc, _, _, classId, subClassId = C_Item.GetItemInfo(item)
            return quality, equipLoc, classId, subClassId
        end
    end

    local function GetSlotLevel(data)
        if not data then
            return 0
        end

        local line = data.lines[1]
        local text = line and line.leftText
        if not text or text == RETRIEVING_ITEM_INFO then
            return nil
        end

        for i = 2, #data.lines do
            local line = data.lines[i]
            local text = line.leftText
            if text and text ~= "" then
                text = text:match(ITEM_LEVEL_PATTERN) or text:match(ITEM_LEVEL_ALT_PATTERN)
                if text then
                    return tonumber(text)
                end
            end
        end
    end

    local slotData = {}

    function P.SaveUnitItemLevel(t, unit, guid)
        if not slotData[guid] then slotData[guid] = {} end

        local spec = GetInspectSpecialization(unit)

        for _, slot in pairs(SLOTS) do
            slotData[guid][slot] = GetTooltipData(unit, slot)
        end

        C_Timer.After(0.1, function()
            local mainLevel = GetSlotLevel(slotData[guid][INVSLOT_MAINHAND])
            local offLevel = GetSlotLevel(slotData[guid][INVSLOT_OFFHAND])
            slotData[guid][INVSLOT_MAINHAND] = nil
            slotData[guid][INVSLOT_OFFHAND] = nil

            -- print(mainLevel, offLevel)

            if mainLevel and offLevel then
                local total = 0
                local mainQuality, mainEquipLoc, mainClassId, mainSubClassId = GetSlotInfo(unit, INVSLOT_MAINHAND)
                if spec ~= 72 and mainEquipLoc and (mainQuality == Enum.ItemQuality.Artifact or TWO_HANDED[mainEquipLoc])
                    and not (mainClassId == 2 and mainSubClassId == 19) then -- 2:武器 19:魔杖
                    total = total + max(mainLevel, offLevel) * 2
                else
                    total = total + mainLevel + offLevel
                end

                for _, data in pairs(slotData[guid]) do
                    local slot = GetSlotLevel(data)
                    -- print(data.hyperlink, slot)
                    if slot then
                        total = total + slot
                    else
                        total = nil
                        break
                    end
                end

                if total and total ~= 0 then
                    t["itemLevel"] = max(Round(total / NUM_SLOTS), 1)
                    cached[guid] = GetTime()
                    -- print(t["itemLevel"])
                end

            end

            slotData[guid] = nil
        end)
    end

else
    local SLOTS = {
        INVSLOT_HEAD,
        INVSLOT_NECK,
        INVSLOT_SHOULDER,
        INVSLOT_CHEST,
        INVSLOT_WAIST,
        INVSLOT_LEGS,
        INVSLOT_FEET,
        INVSLOT_WRIST,
        INVSLOT_HAND,
        INVSLOT_FINGER1,
        INVSLOT_FINGER2,
        INVSLOT_TRINKET1,
        INVSLOT_TRINKET2,
        INVSLOT_BACK,
        INVSLOT_RANGED,
    }

    local NUM_SLOTS = 17

    local function GetSlotLevel(unit, slot)
        local link = GetInventoryItemLink(unit, slot)
        local level = 0
        if link then
            level = select(4, GetItemInfo(link))
        end
        return level
    end

    function P.SaveUnitItemLevel(t, unit, guid)
        C_Timer.After(0.1, function()
            local mainLevel, offLevel = 0, 0
            local mainEquipLoc

            local mainLink = GetInventoryItemLink(unit, INVSLOT_MAINHAND)
            if mainLink then
                mainLevel, _, _, _, _, mainEquipLoc = select(4, GetItemInfo(mainLink))
            end

            local offLink = GetInventoryItemLink(unit, INVSLOT_OFFHAND)
            if offLink then
                offLevel = select(4, GetItemInfo(offLink))
            end

            if mainLevel and offLevel then
                local total = 0
                if mainEquipLoc and mainEquipLoc == INVTYPE_2HWEAPON then
                    total = total + mainLevel * 2
                else
                    total = total + mainLevel + offLevel
                end

                for _, slot in pairs(SLOTS) do
                    slot = GetSlotLevel(unit, slot)
                    total = total + slot
                end

                if total and total ~= 0 then
                    t["itemLevel"] = max(Round(total / NUM_SLOTS), 1)
                    cached[guid] = GetTime()
                    -- print(t["itemLevel"])
                end

            end
        end)
    end
end

---------------------------------------------------------------------
-- 保存玩家自己的天赋信息
---------------------------------------------------------------------
if BigFootSync.isRetail then
    local function SaveTalentsByConfigID(t, configId)
        local configInfo = C_Traits.GetConfigInfo(configId)
        t["name"] = configInfo.name -- talent loadout name
        t["nodes"] = {}

        for _, treeId in pairs(configInfo.treeIDs) do
            for _, nodeId in pairs(C_Traits.GetTreeNodes(treeId)) do
                -- https://warcraft.wiki.gg/wiki/API_C_Traits.GetNodeInfo
                local nodeInfo = C_Traits.GetNodeInfo(configId, nodeId)
                if nodeInfo.currentRank ~= 0 then
                    t["nodes"][nodeId] = nodeInfo.currentRank
                end
            end
        end
    end

    P.SavePlayerTalents = function(t)
        wipe(t)

        local configId = C_ClassTalents.GetActiveConfigID()
        if not configId then return end

        -- 保存当前天赋
        SaveTalentsByConfigID(t, configId)
        local classId = select(2, UnitClassBase("player"))
        t["specId"] = GetSpecializationInfoForClassID(classId, GetSpecialization())

        -- 保存所有
        -- for i = 1, GetNumSpecializationsForClassID(PlayerUtil.GetClassID()) do
        --     local specId = GetSpecializationInfoForClassID(PlayerUtil.GetClassID(),  i)
        --     t[specId] = {}

        --     local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specId)
        --     for _, configId in pairs(configIDs) do
        --         t[specId][configId] = {}
        --         SaveTalentsByConfigID(t[specId][configId], configId)
        --     end
        -- end
    end
else
    P.SavePlayerTalents = function(t)
        -- 仅保存当前天赋配置
        for tabIndex = 1, GetNumTalentTabs() do
            -- 每个“专精”单独存放
            t[tabIndex] = {
                ["pointsSpent"] = select(3, GetTalentTabInfo(tabIndex)),
                ["details"] = {},
            }
            -- 遍历所有天赋点
            for talentIndex = 1, GetNumTalents(tabIndex) do
                local _, _, row, column, rank = GetTalentInfo(tabIndex, talentIndex)
                if rank ~= 0 then
                    tinsert(t[tabIndex]["details"], {
                        ["row"] = row,
                        ["column"] = column,
                        ["rank"] = rank,
                    })
                end
            end
        end
    end
end


---------------------------------------------------------------------
-- 保存队内玩家数据
---------------------------------------------------------------------
function P.SaveGroupMemberData(t)
    for unit in U.IterateGroupMembers() do
        P.SaveUnitBaseData(t, unit, true)
    end
end


---------------------------------------------------------------------
-- 保存公会玩家数据
---------------------------------------------------------------------
function P.SaveGuildMemberData(t, guildName, guildRealm, guildFaction)
    for i = 1, GetNumGuildMembers() do
        local name, _, _, level, _, _, _, _, _, _, classFile = GetGuildRosterInfo(i)

        if not t[name] then
            -- 标记该记录需要进一步的信息完善
            t[name] = {["incomplete"] = true}
        end

        t[name]["name"] = U.ToShortName(name)
        t[name]["level"] = level
        t[name]["classId"] = U.GetClassID(classFile)
        t[name]["guild"] = guildName
        t[name]["realm"] = guildRealm -- 默认为公会服务器
        t[name]["faction"] = guildFaction -- 默认为公会阵营
        t[name]["region"] = BFS_Account["region"] -- 地区（为了客户端读取方便）
        t[name]["version"] = U.GetBigFootClientVersion() -- 游戏版本（为了客户端读取方便）
        t[name]["lastSeen"] = GetServerTime() -- 更新时间
    end
end


---------------------------------------------------------------------
-- 保存好友数据
---------------------------------------------------------------------
function P.SaveFriendData(t)
    for i = 1, C_FriendList.GetNumFriends() do
        local info = C_FriendList.GetFriendInfoByIndex(i)

        local name, realm
        -- 角色名可能不带服务器
        if strfind(info.name, "-") then
            name, realm = strsplit("-", info.name)
        else
            name = info.name
            realm = GetNormalizedRealmName()
            info.name = info.name.."-"..GetNormalizedRealmName()
        end

        if not t[info.name] then
            -- 标记该记录需要进一步的信息完善
            t[info.name] = {["incomplete"] = true}
        end

        t[info.name]["name"] = name
        t[info.name]["guid"] = info.guid
        t[info.name]["level"] = info.level -- 未在线可能为0
        t[info.name]["realm"] = realm
        if info.className ~= _G.UNKNOWN then
            t[info.name]["classId"] = U.GetClassID(info.className)
        end
        t[info.name]["region"] = BFS_Account["region"] -- 地区（为了客户端读取方便）
        t[info.name]["faction"] = UnitFactionGroup("player") -- 游戏好友，阵营与玩家一致
        t[info.name]["version"] = U.GetBigFootClientVersion() -- 游戏版本（为了客户端读取方便）
        t[info.name]["lastSeen"] = GetServerTime() -- 更新时间
    end
end

function P.SaveBNetFriendData(t, realmDataTable)
    for i = 1, BNGetNumFriends() do
        -- https://warcraft.wiki.gg/wiki/API_C_BattleNet.GetFriendAccountInfo
        local info = C_BattleNet.GetFriendAccountInfo(i)
        if info.gameAccountInfo and info.gameAccountInfo.clientProgram == _G.BNET_CLIENT_WOW then
            info = info.gameAccountInfo

            -- 游戏版本（为了客户端读取方便）
            local version = info.wowProjectID and U.GetBigFootClientVersion(info.wowProjectID)

            -- 不同版本客户端之间可能获取不到服务器
            if info.realmName and info.isInCurrentRegion and version then
                -- 角色名不带服务器
                local name = info.characterName.."-"..info.realmName

                if not t[name] then
                    -- 标记该记录需要进一步的信息完善
                    t[name] = {["incomplete"] = true}
                end

                t[name]["name"] = info.characterName
                t[name]["guid"] = info.playerGuid
                t[name]["level"] = info.characterLevel
                t[name]["realm"] = info.realmDisplayName
                t[name]["faction"] = info.factionName
                t[name]["classId"] = U.GetClassID(info.className)
                t[name]["lastSeen"] = GetServerTime() -- 更新时间
                -- info.raceName: 本地化后的种族名

                -- 补充服务器信息
                if not realmDataTable[info.realmID] then
                    realmDataTable[info.realmID] = {
                        ["name"] = info.realmDisplayName,
                        ["normalizedName"] = info.realmName,
                    }
                end

                t[name]["region"] = BFS_Account["region"] -- 地区（为了客户端读取方便）
                t[name]["version"] = version -- 游戏版本（为了客户端读取方便）
            end
        end
    end
end