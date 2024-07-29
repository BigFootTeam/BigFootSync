local _, BigFootBot = ...
BigFootBot.token = {}

local T = BigFootBot.token
local U = BigFootBot.utils

local UPDATE_INTERVAL = 30 * 60

---------------------------------------------------------------------
-- 保存数据
---------------------------------------------------------------------
local function SaveTokenPrice()
    local price = C_WowTokenPublic.GetCurrentMarketPrice()
    local t = date("*t", GetServerTime())
    t.sec = 0
    BigFootBotTokenDB[time(t)] = price
end

local function RequestTokenPrice()
    if InCombatLockdown() then return end -- 非战斗中
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
local function StartDelayed(timeDelayed)
    C_Timer.After(timeDelayed, StartNow)
end

---------------------------------------------------------------------
-- 启用
---------------------------------------------------------------------
function T:StartTockenPriceUpdater()
    local t = date("*t", GetServerTime())
    if t.min == 0 or t.min == 30 then
        StartNow()
    elseif t.min < 30 then
        StartDelayed((30 - t.min) * 60 + t.sec)
    else
        StartDelayed((60 - t.min) * 60 + t.sec)
    end
    -- if t.sec == 0 or t.sec == 30 then
    --     StartNow()
    -- elseif t.sec < 30 then
    --     StartDelayed(30 - t.sec)
    -- else
    --     StartDelayed(60 - t.sec)
    -- end
end