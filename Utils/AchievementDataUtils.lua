local _, BigFootBot = ...
BigFootBot.achievements = {}

local A = BigFootBot.achievements

---------------------------------------------------------------------
-- 保存成就数据
---------------------------------------------------------------------
-- local queue = {}
-- local saveTo
-- local updater = CreateFrame("Frame")
-- updater:Hide()

-- updater:SetScript("OnUpdate", function()
--     local t = queue[1]
--     if t then
--         if t[3] == "waiting" then
--             print("processing", t[1], t[2])
--             t[3] = "processing"
--             -- https://warcraft.wiki.gg/wiki/API_GetAchievementInfo
--             local id, name, points, completed, month, day, year, desc, _, icon, _, isGuild = GetAchievementInfo(t[1], t[2])
--             if completed and not isGuild then
--                 tinsert(saveTo["achievements"], {
--                     ["id"] = id,
--                     -- ["name"] = name,
--                     -- ["desc"] = desc,
--                     ["points"] = points,
--                     ["icon"] = icon,
--                     ["date"] = year.."-"..month.."-"..day, -- year为年份的后两位数
--                 })
--             end
--             t[3] = "done"
--         elseif t[3] == "done" then
--             tremove(queue, 1)
--         end
--     else
--         updater:Hide()
--         print(GetTime() - start)
--     end
-- end)

function A.SaveAchievements(t)
    if BigFootBot.isVanilla then return end
    t["totalPoints"] = GetTotalAchievementPoints()
    
    local list = GetCategoryList() -- 成就分类
    for _, categoryId in pairs(list) do
        local total = GetCategoryNumAchievements(categoryId) -- 该分类下成就个数
        for i = 1, total do
            -- tinsert(queue, {categoryId, i, "waiting"})
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
    -- updater:Show()
end