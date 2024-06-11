local _, BigFootBot = ...
BigFootBot.achievements = {}

local A = BigFootBot.achievements

---------------------------------------------------------------------
-- 保存成就数据
---------------------------------------------------------------------
function A.SaveAchievements(t)
    if BigFootBot.isVanilla then return end
    
    local list = GetCategoryList() -- 成就分类
    for _, categoryId in pairs(list) do
        local total = GetCategoryNumAchievements(categoryId) -- 该分类下成就个数
        for i = 1, total do
            -- https://warcraft.wiki.gg/wiki/API_GetAchievementInfo
            local id, name, points, completed, month, day, year, desc, _, icon, _, isGuild = GetAchievementInfo(categoryId, i)
            if completed and not isGuild then
                tinsert(t["achievements"], {
                    ["id"] = id,
                    -- ["name"] = name,
                    -- ["desc"] = desc,
                    ["points"] = points,
                    ["icon"] = icon,
                    ["date"] = year.."-"..month.."-"..day, -- year为年份的后两位数
                })
            end
        end
    end

    t["totalPoints"] = GetTotalAchievementPoints()
end