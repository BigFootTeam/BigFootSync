local _, BigFootBot = ...
BigFootBot.token = {}

local T = BigFootBot.token
local U = BigFootBot.utils

local TIME_POINTS = {5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55} -- 获取数据的时间点
local UPDATE_INTERVAL = (TIME_POINTS[2] - TIME_POINTS[1]) * 60 -- 更新间隔（秒）

---------------------------------------------------------------------
-- 保存数据
---------------------------------------------------------------------
local function SaveTokenPrice()
    local price = C_WowTokenPublic.GetCurrentMarketPrice()
    local t = date("*t", GetServerTime())
    t.sec = 0
    BigFootBotTokenDB[time(t)] = price
    print("UPDATE:", string.format("%02d:%02d:%02d", t.hour, t.min, t.sec), price)
end

local function RequestTokenPrice()
    if InCombatLockdown() then return end -- 非战斗中
    print("UPDATE IN 2 SEC!!!!!")
    C_WowTokenPublic.UpdateMarketPrice() -- 请求数据
    C_Timer.After(2, SaveTokenPrice) -- 2秒后记录，而非监听 TOKEN_MARKET_PRICE_UPDATED 事件
end

---------------------------------------------------------------------
-- 立即开始
---------------------------------------------------------------------
local function StartNow()
    RequestTokenPrice() -- 立即保存
    C_Timer.NewTicker(UPDATE_INTERVAL, RequestTokenPrice) -- 定时器
end

---------------------------------------------------------------------
-- 延迟到下个 0/30 开始
---------------------------------------------------------------------
local function StartDelayed(timeDelayed, t)
    print("NOW:", string.format("%02d:%02d:%02d", t.hour, t.min, t.sec), ", DELAYED:", timeDelayed)
    C_Timer.After(timeDelayed, StartNow)
end

---------------------------------------------------------------------
-- 启用
---------------------------------------------------------------------
function T:StartTockenPriceUpdater()
    local t = date("*t", GetServerTime())

    if t.min > TIME_POINTS[#TIME_POINTS] then
        -- 大于最后一个时间点
        StartDelayed((60 - t.min) * 60 - t.sec + TIME_POINTS[1] * 60, t)
    else
        for _, v in pairs(TIME_POINTS) do
            -- if t.min == v then
            --     StartNow()
            --     break
            if t.min < v then
                StartDelayed((v - t.min) * 60 - t.sec, t)
                break
            end
        end
    end
end