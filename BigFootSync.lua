local addonName, BigFootSync = ...
_G.BigFootSync = BigFootSync

local P = BigFootSync.players
local A = BigFootSync.achievements
local U = BigFootSync.utils
local T = BigFootSync.token

---------------------------------------------------------------------
-- events
---------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

---------------------------------------------------------------------
-- 初始化
---------------------------------------------------------------------
function frame:ADDON_LOADED(arg)
    if arg == addonName then
        frame:UnregisterEvent("ADDON_LOADED")

        -- 保存服务器ID、名称（每次上线清空）
        BigFootSyncRealmDB = {}

        -- 所有玩家的数据（每次上线清空）
        BigFootSyncCharacterDB = {}

        -- 账号相关信息（每次上线清空）
        BigFootSyncAccountDB = {
            ["fullName"] = U.UnitName("player"),
            ["region"] = GetCVar("portal"), -- 区域
            ["isTrial"] = IsTrialAccount(), -- 是否为试玩账号
            ["gameVersion"] = GetBuildInfo(), -- 当前账号配置对应的版本号，例如 10.2.7
            ["clientVersion"] = U.GetBigFootClientVersion(), -- 对应大脚客户端内游戏版本ID
            ["addonVersion"] = C_AddOns.GetAddOnMetadata(addonName, "Version"), -- 插件版本
            ["bigfootVersion"] = BIGFOOT_VERSION,
            ["mounts"] = "",
            ["specId"] = 65,
            ["titleId"] = 95,
            ["equipments"] = {},
            ["stats"] = {},
            ["talents"] = {},
        }

        -- 玩家自己的公会信息（每次上线清空）
        BigFootSyncGuildDB = {}

        -- 账号成就（每次上线清空）
        BigFootSyncAchievementDB = {}

        -- 账号宠物（每次上线清空）
        -- BigFootSyncPetDB = {}

        -- 账号坐骑（每次上线清空）
        -- BigFootMountDB = {}

        -- 玩家自己的数据（每次上线清空）
        BigFootSyncPlayerDB = {
            [fullName] = {
                ["base"] = {}, -- 基础属性
                ["stats"] = {}, -- 战斗属性
                ["combatRating"] = {},
                ["combatRatingBonus"] = {},
                ["equipments"] = {}, -- 装备
                ["talents"] = {}, -- 天赋
            }
            [fullName] = {
                ["base"] = {}, -- 基础属性
                ["stats"] = {}, -- 战斗属性
                ["combatRating"] = {},
                ["combatRatingBonus"] = {},
                ["equipments"] = {}, -- 装备
                ["talents"] = {}, -- 天赋
            }
            [fullName] = {
                ["base"] = {}, -- 基础属性
                ["stats"] = {}, -- 战斗属性
                ["combatRating"] = {},
                ["combatRatingBonus"] = {},
                ["equipments"] = {}, -- 装备
                ["talents"] = {}, -- 天赋
            }
            [fullName] = {
                ["base"] = {}, -- 基础属性
                ["stats"] = {}, -- 战斗属性
                ["combatRating"] = {},
                ["combatRatingBonus"] = {},
                ["equipments"] = {}, -- 装备
                ["talents"] = {}, -- 天赋
            }
            [fullName] = {
                ["base"] = {}, -- 基础属性
                ["stats"] = {}, -- 战斗属性
                ["combatRating"] = {},
                ["combatRatingBonus"] = {},
                ["equipments"] = {}, -- 装备
                ["talents"] = {}, -- 天赋
            }
        }

        -- 时光徽章数据（每次上线清空）
        BigFootSyncTokenDB = {}
        T:StartTockenPriceUpdater()

        frame:RegisterEvent("PLAYER_LOGOUT")
        frame:RegisterEvent("PLAYER_LOGIN")
        frame:RegisterEvent("GROUP_ROSTER_UPDATE")
        frame:RegisterEvent("GUILD_ROSTER_UPDATE")
        frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("INSPECT_READY")
    end
end

---------------------------------------------------------------------
-- 重载后/登出时（文件保存前）
---------------------------------------------------------------------
function frame:PLAYER_LOGOUT()
    local indices = {"guid", "name", "realm", "level", "gender", "raceId", "classId", "faction", "region", "version"}
    for k, t in pairs(BigFootSyncCharacterDB) do
        for _, index in pairs(indices) do
            -- 对应属性为空，空字符串，或者为0（非version属性）时，丢弃此条数据
            if not t[index] or t[index] == "" or (index ~= "version" and t[index] == 0) then
                BigFootSyncCharacterDB[k] = nil
                break
            end
        end
    end

    -- FIXME: 无法在此事件中获取数据
    -- 保存玩家自己的信息到角色配置
    -- P.SavePlayerData(BigFootSyncPlayerDB)

    -- 保存玩家自己的基础信息到账号配置
    -- P.SaveUnitBaseData(BigFootSyncCharacterDB, "player", true)

    -- 保存成就信息
    -- A.SaveAchievements(BigFootSyncAchievementDB) -- 会增加下线/重载前的卡顿时间
end

---------------------------------------------------------------------
-- 重载后/登入时
---------------------------------------------------------------------
function frame:PLAYER_LOGIN()
    -- 保存服务器信息
    BigFootSyncRealmDB = {
        ["id"] = GetRealmID(), -- 服务器ID
        ["name"] = GetRealmName(), -- 服务器名
        ["normalizedName"] = GetNormalizedRealmName(), -- 服务器名（去除空格等符号，外服常见）
        ["region"] = GetCVar("portal"), -- 区域
    }

    -- 保存玩家自己的信息到角色配置
    P.SavePlayerData(BigFootSyncPlayerDB)

    -- 保存玩家自己的基础信息到账号配置（所有收集到的玩家数据）
    P.SaveUnitBaseData(BigFootSyncCharacterDB, "player", true)

    -- 保存成就信息
    if not BigFootSync.isVanilla then
        A.SaveAchievements(BigFootSyncAchievementDB)
    end

    -- 保存好友信息
    -- P.SaveFriendData(BigFootSyncCharacterDB)
    -- P.SaveBNetFriendData(BigFootSyncCharacterDB, BigFootSyncRealmDB)

    -- 请求公会数据
    C_GuildInfo.GuildRoster()
end

---------------------------------------------------------------------
-- 进入世界
---------------------------------------------------------------------
function frame:PLAYER_ENTERING_WORLD()
    frame:UnregisterEvent("PLAYER_ENTERING_WORLD")

    -- 已经在队伍中
    if IsInGroup() then
        frame:GROUP_ROSTER_UPDATE()
    end
end

---------------------------------------------------------------------
-- 公会
---------------------------------------------------------------------
function frame:GUILD_ROSTER_UPDATE()
    if InCombatLockdown() then
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame.updateGuildRosterRequired = true
        return
    end

    frame:UnregisterEvent("GUILD_ROSTER_UPDATE") -- 仅扫描一次公会成员
    frame.updateGuildRosterRequired = nil

    if not IsInGuild() then return end

    local guildName, _, _, guildRealm = GetGuildInfo("player")
    guildRealm = guildRealm or GetNormalizedRealmName()

    local guildFaction = GetGuildFactionGroup() == 0 and "Horde" or "Alliance"

    -- 公会信息
    BigFootSyncGuildDB["name"] = guildName
    BigFootSyncGuildDB["members"] = GetNumGuildMembers()
    BigFootSyncGuildDB["realm"] = guildRealm
    BigFootSyncGuildDB["faction"] = guildFaction
    BigFootSyncGuildDB["region"] = BigFootSyncAccountDB["region"]

    -- 公会在线人数/等级/职业分布
    BigFootSyncGuildDB["online"] = 0
    BigFootSyncGuildDB["levels"] = {}
    BigFootSyncGuildDB["classesAtMaxLevel"] = {}

    -- NOTE: 怀旧服没有 GetMaxLevelForLatestExpansion
    local maxLevel = GetMaxLevelForExpansionLevel(LE_EXPANSION_LEVEL_CURRENT)

    for i = 1, BigFootSyncGuildDB["members"] do
        local name, _, _, level, _, _, _, _, isOnline, _, classFile = GetGuildRosterInfo(i)
        if isOnline then
            BigFootSyncGuildDB["online"] = BigFootSyncGuildDB["online"] + 1
        end

        -- 等级分布
        local k = tostring(level) -- 只要有数字索引1的，不连续的索引会被补nil，且不保持k=v格式
        BigFootSyncGuildDB["levels"][k] = (BigFootSyncGuildDB["levels"][k] or 0) + 1

        -- 满级职业分布
        if level == maxLevel then
            local classId = tostring(U.GetClassID(classFile)) -- 同 level
            BigFootSyncGuildDB["classesAtMaxLevel"][classId] = (BigFootSyncGuildDB["classesAtMaxLevel"][classId] or 0) + 1
        end
    end

    -- 公会成员信息
    -- P.SaveGuildMemberData(BigFootSyncCharacterDB, guildName, guildRealm, guildFaction)
end

---------------------------------------------------------------------
-- 队伍
---------------------------------------------------------------------
local timer
function frame:GROUP_ROSTER_UPDATE(immediate)
    if timer then
        timer:Cancel()
        timer = nil
    end

    if immediate then -- 立即执行
        if InCombatLockdown() then -- 检查战斗状态
            frame.updateGroupRosterRequired = true
            frame:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        end
        frame.updateGroupRosterRequired = nil
        frame:UnregisterEvent("GROUP_ROSTER_UPDATE") -- 成功记录一次之后不再记录
        P.SaveGroupMemberData(BigFootSyncCharacterDB)

    else -- 5秒内队伍成员没变化才进行遍历操作
        timer = C_Timer.NewTimer(5, function()
            timer = nil
            frame:GROUP_ROSTER_UPDATE(true)
        end)
    end
end

---------------------------------------------------------------------
-- 脱战后
---------------------------------------------------------------------
function frame:PLAYER_REGEN_ENABLED()
    frame:UnregisterEvent("PLAYER_REGEN_ENABLED")

    if frame.updateGuildRosterRequired then
        frame:GUILD_ROSTER_UPDATE()
    end

    if frame.updateGroupRosterRequired then
        frame:GROUP_ROSTER_UPDATE()
    end
end

---------------------------------------------------------------------
-- INSPECT_READY
---------------------------------------------------------------------
local GUIDS = {}

local function RequestUnitItemLevel(unit)
    if (InspectFrame and InspectFrame:IsShown()) or (CharacterFrame and CharacterFrame:IsShown()) or UnitIsUnit(unit, "player") then
        return
    end

    local level = UnitLevel(unit)
    if level == U.GetMaxLevel() and CanInspect(unit) and (BigFootSync.isRetail or CheckInteractDistance(unit, 4)) then
        local guid = UnitGUID(unit)
        if guid and P.ShouldUpdateUnitItemLevel(guid) then
            local fullName = U.UnitName(unit)
            -- print("REQUEST", unit, guid, fullName)
            GUIDS[guid] = unit
            NotifyInspect(unit)
        end
    end
end

function frame:INSPECT_READY(guid)
    if InCombatLockdown() then return end
    local unit = GUIDS[guid]
    if unit then
        GUIDS[guid] = nil
        local fullName = U.UnitName(unit)
        local correct_guid = UnitGUID(unit)
        if correct_guid == guid and BigFootSyncCharacterDB[fullName] then
            -- print("INSPECT_READY", unit, guid, fullName)
            P.SaveUnitItemLevel(BigFootSyncCharacterDB[fullName], unit, guid)
        end
    end
end

---------------------------------------------------------------------
-- 鼠标指向
---------------------------------------------------------------------
function frame:UPDATE_MOUSEOVER_UNIT()
    if InCombatLockdown() then return end
    P.SaveUnitBaseData(BigFootSyncCharacterDB, "mouseover", true)
    RequestUnitItemLevel("mouseover")
end

---------------------------------------------------------------------
-- 当前目标
---------------------------------------------------------------------
function frame:PLAYER_TARGET_CHANGED()
    if InCombatLockdown() then return end
    P.SaveUnitBaseData(BigFootSyncCharacterDB, "target", true)
    RequestUnitItemLevel("target")
end