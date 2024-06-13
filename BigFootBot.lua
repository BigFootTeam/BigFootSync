local addonName, BigFootBot = ...
_G.BigFootBot = BigFootBot

local P = BigFootBot.players
local A = BigFootBot.achievements
local U = BigFootBot.utils

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

        -- 保存服务器ID、名称
        if type(BigFootBotRealmDB) ~= "table" then BigFootBotRealmDB = {} end

        -- 所有玩家的数据（每次上线清空）
        BigFootBotCharacterDB = {}

        -- 账号相关信息（每次上线清空）
        BigFootBotAccountDB = {
            ["region"] = GetCVar("portal"), -- 区域
            ["isTrial"] = IsTrialAccount(), -- 是否为试玩账号
            ["version"] = GetBuildInfo(), -- 当前账号配置对应的版本号，例如 10.2.0
            ["versionId"] = U.GetGameVersion(), -- 对应大脚客户端内的ID
        }

        -- 玩家自己的公会信息（每次上线清空）
        BigFootBotGuildDB = {}

        -- 账号成就（每次上线清空）
        if not BigFootBot.isVanilla then
            BigFootBotAchievementDB = {
                ["achievements"] = {},
                ["totalPoints"] = 0,
            }
        end

        -- 账号宠物（每次上线清空）
        -- BigFootBotPetDB = {}

        -- 账号坐骑（每次上线清空）
        -- BigFootMountDB = {}

        -- 玩家自己的数据（每次上线清空）
        BigFootBotPlayerDB = {
            ["base"] = {}, -- 基础属性
            ["stats"] = {}, -- 战斗属性
            ["combatRating"] = {},
            ["combatRatingBonus"] = {},
            ["equipments"] = {}, -- 装备
            ["talents"] = {}, -- 天赋
        }

        -- frame:RegisterEvent("PLAYER_LOGOUT")
        frame:RegisterEvent("PLAYER_LOGIN")
        frame:RegisterEvent("GROUP_ROSTER_UPDATE")
        frame:RegisterEvent("GUILD_ROSTER_UPDATE")
        frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    end
end

---------------------------------------------------------------------
-- 重载后/登出时，FIXME: 无法在此事件中获取数据
---------------------------------------------------------------------
function frame:PLAYER_LOGOUT()
    -- 保存玩家自己的信息到角色配置
    P.SavePlayerData(BigFootBotPlayerDB)

    -- 保存玩家自己的基础信息到账号配置
    P.SaveUnitBaseData(BigFootBotCharacterDB, "player", true)

    -- 保存成就信息
    -- A.SaveAchievements(BigFootBotAchievementDB) -- 会增加下线/重载前的卡顿时间
end

---------------------------------------------------------------------
-- 重载后/登入时
---------------------------------------------------------------------
function frame:PLAYER_LOGIN()
    -- 保存服务器信息
    BigFootBotRealmDB[GetRealmID()] = {
        ["name"] = GetRealmName(),
        ["normalizedName"] = GetNormalizedRealmName(),
    }

    -- 保存玩家自己的信息到角色配置
    P.SavePlayerData(BigFootBotPlayerDB)

    -- 保存玩家自己的基础信息到账号配置
    P.SaveUnitBaseData(BigFootBotCharacterDB, "player", true)

    -- 保存成就信息
    A.SaveAchievements(BigFootBotAchievementDB)

    -- 保存好友信息
    P.SaveFriendData(BigFootBotCharacterDB)
    P.SaveBNetFriendData(BigFootBotCharacterDB, BigFootBotRealmDB)

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

    -- 公会信息
    BigFootBotGuildDB["name"] = guildName
    BigFootBotGuildDB["members"] = GetNumGuildMembers()
    BigFootBotGuildDB["realm"] = guildRealm

    -- 公会成员信息
    P.SaveGuildMemberData(BigFootBotCharacterDB, guildName, guildRealm)
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
        P.SaveGroupMemberData(BigFootBotCharacterDB)

    else -- 10秒内队伍成员没变化才进行遍历操作
        timer = C_Timer.NewTimer(10, function()
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
-- 鼠标指向
---------------------------------------------------------------------
function frame:UPDATE_MOUSEOVER_UNIT()
    if InCombatLockdown() then return end
    P.SaveUnitBaseData(BigFootBotCharacterDB, "mouseover", true)
end

---------------------------------------------------------------------
-- 当前目标
---------------------------------------------------------------------
function frame:PLAYER_TARGET_CHANGED()
    if InCombatLockdown() then return end
    P.SaveUnitBaseData(BigFootBotCharacterDB, "target", true)
end