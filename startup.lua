-- startup.lua  版本2025/6/6 9:28
-- 转速控制器
local speedcontroller = peripheral.find("Create_RotationSpeedController")
if not speedcontroller then
    print("NOT FOUND SPEEDCONTROLLER")
    return
end

-- 显示器
local monitor = peripheral.find("monitor")
if not monitor then
    print("NOT FOUND MONITOR")
end

-- 放在书架上的Create:Tweaked Controller
local joy = peripheral.find("tweaked_controller")
if not joy then
    print("NOT FOUND JOY")
end

-- 扬声器
local speaker = peripheral.find("speaker")
if not speaker then
    print("NOT FOUND SPEAKER")
end

------------ 初始化
-- 初始化HUD
monitor.clear()
monitor.setTextScale(0.5)
local hud_scale = monitor.getSize()
local hud_type = 0 -- 为自定义hud做准备（）

-- 初始化变速箱
gear = 0
speed = 0
gearbox_type = 2
-- 0 = MT
-- 1 = auto_snug
-- 2 = auto_sports

-- 初始化引擎
local engine_speed = 10 -- 启动转速
local maxSpeed = 80 -- 最大转速
local acceleration = 3 -- 加速率
local deceleration = 2 -- 减速率
throttle = 0.0 -- 油门
local load = 0 -- 负载(负载=车重*变速箱档位)
local mass = 0.6 -- 车重(负载基数)

-- HUD
function hud(speed,gear,rpm,relspeed)
    if hud_type == 0 then
        hud_0(speed,gear,rpm,relspeed)
    end
end

function hud_0(speed,gear,rpm,relspeed)
    monitor.clear()
    monitor.setTextScale(0.5)
    monitor.setCursorPos(1,1)
    local speedstr = tostring(math.floor(relspeed * 3.6))  --0.987 math.floor(relspeed * 3.6) (speed * 0.987)
    local rpmstr = ((math.min((math.floor(engine_speed)+4),100)) / 10) -- 转速=1000*rpmstr

    -- 迈速表（KMH）
    if #speedstr == 1 then -- 1位数 1-3位数的居中显示
        monitor.setCursorPos((hud_scale + 1) / 2,(hud_scale / 2) - 2)
        monitor.write(speedstr)
    elseif #speedstr == 2 then -- 2位数
        monitor.setCursorPos(hud_scale / 2,(hud_scale / 2) - 2)
        monitor.write(speedstr:gsub(".", "%1 "):sub(1,-2))
    elseif #speedstr == 3 then -- 3位数
        monitor.setCursorPos(hud_scale / 2,(hud_scale / 2) - 2)
        monitor.write(speedstr)
    end
    monitor.setCursorPos(hud_scale / 2,(hud_scale / 2) - 1)
    monitor.write("KMH")

    -- 转速表
    monitor.setCursorPos(1,(hud_scale / 2) + 2)
    monitor.write("-----------------------------------------------------------")
    monitor.setCursorPos(((hud_scale / 2 - 5) - rpmstr*5) + 2,(hud_scale / 2) + 2)
    monitor.write("+----+----+----+----+----+----+----+----+----+----+----+---------")
    monitor.setCursorPos(((hud_scale / 2 - 5) - rpmstr*5) + 2,(hud_scale / 2) + 3)
    monitor.write("     0    1    2    3    4    5    6    7    8    9   10         ")
    monitor.setCursorPos((hud_scale / 2) + 1,(hud_scale / 2) + 2)
    monitor.write("|")

    -- 挡位指示器
    monitor.setCursorPos((hud_scale / 2) - 5,1)
    monitor.write("R ")
    monitor.write("N ")
    monitor.write("1 ")
    monitor.write("2 ")
    monitor.write("3 ")
    monitor.write("4 ")
    monitor.write("5")
    if gear == -1 then
        monitor.setCursorPos((hud_scale / 2) - 5,2)
        monitor.write("=")
    elseif gear == 0 then
        monitor.setCursorPos((hud_scale / 2) - 3,2)
        monitor.write("=")
    elseif gear == 1 then
        monitor.setCursorPos((hud_scale / 2) - 1,2)
        monitor.write("=")
    elseif gear == 2 then
        monitor.setCursorPos((hud_scale / 2) + 1,2)
        monitor.write("=")
    elseif gear == 3 then
        monitor.setCursorPos((hud_scale / 2) + 3,2)
        monitor.write("=")
    elseif gear == 4 then
        monitor.setCursorPos((hud_scale / 2) + 5,2)
        monitor.write("=")
    elseif gear == 5 then
        monitor.setCursorPos((hud_scale / 2) + 7,2)
        monitor.write("=")
    end
   
    if gearbox_type == 1 then

    elseif gearbox_type == 2 then
    monitor.setCursorPos((hud_scale / 2) - 1,3)
    monitor.write("SPORT")
    end
end

-- 变速箱模式
function gearbox(gearbox_type)
    if gearbox_type == 2 then
        auto_sports()
    elseif gearbox_type == 1 then
        auto_snug()
    end
end   

-- 变速箱：AT运动模式
function auto_sports()
    maxSpeed = 80 -- 最大引擎转速:8000RPM
    if speed < 2 then
        gear = 1
    end
    if engine_speed > 75 then
        gear = math.min(gear + 1,5)
    elseif engine_speed < 30 then
        gear = math.max(gear -1,1)
    end  
end

-- 变速箱：AT舒适模式
function auto_snug()
    maxSpeed = 50 -- 最大引擎转速:5000RPM
    if speed < 2 then
        gear = 1
    end
    if engine_speed > 30 then
        gear = math.min(gear + 1,5)
    elseif engine_speed < 10 then
        gear = math.max(gear -1,1)
    end  
end




-- 主循环(有很多东西可以简化成funciton)
while true do
    local joy_y = joy.getAxis(2) -- 获取手柄左摇杆Y轴
    local joy_rt = joy.getAxis(6) -- 获取手柄右扳机
    local joy_lt = joy.getAxis(5) -- 获取手柄左扳机

    local truespeed = ship.getVelocity() -- 获取速度分量
    relspeed = math.sqrt(truespeed.x^2 + truespeed.z^2) -- 计算真实速度(m/s)

    -- 引擎速度（轮速->齿轮比->引擎速度）
    if gear == 1 then -- AT1档
        load = 1.2 * mass -- 负载
        engine_speed = speed / 1.7 -- 轮速
    elseif gear == 2 then -- AT2档 *2
        load = 2.0 * mass -- 负载
        engine_speed = speed / (1.7 * 2)
    elseif gear == 3 then -- AT3档 *3
        load = 2.5 * mass -- 负载
        engine_speed = speed / (1.7 * 3)
    elseif gear == 4 then -- AT4档 *4
        load = 3 * mass -- 负载
        engine_speed = speed / (1.7 * 4)
    elseif gear == 5 then -- AT5档 *5
        load = 4.5 * mass -- 负载
        engine_speed = speed / (1.7 * 5)
    elseif gear == 0 then
        load = 0 * mass -- 负载
        engine_speed = engine_speed
    elseif gear == -1 then -- 倒挡
        if joy_y ~= -1  then -- 排除刹车
            load = 1.2 * mass -- 负载
            engine_speed = speed / -1.7 
        end
    end

    -- 引擎油门（节气门）
    if throttle > 0 then -- 加速
        engine_speed = math.min((engine_speed + acceleration * throttle) - load, maxSpeed)  -- 加速
        -- (引擎速度+加速率*油门开度)- 负载 小于最大速度
    else -- 减速
        engine_speed = math.max(engine_speed - deceleration, 2)  
        -- 引擎速度-减速率 最小0rpm
    end


    -- 轮速度（引擎速度->齿轮比->轮速）
    if gear == 1 then -- AT1档
        speed = engine_speed * 1.7 -- 轮速
    elseif gear == 2 then -- AT2档 *2
        speed = engine_speed * (1.7 * 2)
    elseif gear == 3 then -- AT3档 *3
        speed = engine_speed * (1.7 * 3)
    elseif gear == 4 then -- AT4档 *4
        speed = engine_speed * (1.7 * 4)
    elseif gear == 5 then -- AT5档 *5
        speed = engine_speed * (1.7 * 5)
    elseif gear == 0 then -- 空档(模拟惯性)
        if relspeed < 2 then -- 模拟惯性停车 
            speed = 0
        elseif relspeed < 6 and relspeed >= 4 then -- 模拟惯性1档
            speed = 30
        elseif relspeed < 12 and relspeed >= 6 then -- 模拟惯性2档
            speed = 51.2
        elseif relspeed < 19 and relspeed >= 12 then -- 模拟惯性3档
            speed = 102.4
        elseif relspeed < 22 and relspeed >= 19 then -- 模拟惯性4档
            speed = 153.6
        elseif relspeed >= 22 then -- 模拟惯性5档
            speed = 204.8
        end
    elseif gear == -1 then -- 倒挡
        speed = engine_speed * -1.7
    end
    
    speedcontroller.setTargetSpeed(speed) -- 这东西不放这会出问题=-=

    if relspeed < 0.3 then -- 如果真实速度小于0.3则自动空档
        gear = 0
    end
    
    if joy_y < 0 or joy_rt > 0.1 then -- 油门
        
        if gear == -1 then
                -- 倒车时的刹车按键
                -- 引擎减速率=5
                deceleration = 5
        else
                deceleration = 2 -- 引擎减速率=2
                if joy_rt > 0.1 then
                    throttle = joy_rt
                else
                    throttle = math.abs(joy_y)
                end
                gearbox(gearbox_type)
        end
    elseif joy_y > 0 or joy_lt > 0.1 then -- 油门：倒挡/刹车
        
        if relspeed < 5 then -- <5m/s 倒挡
            if joy_rt > 0.1 then
                throttle = joy_rt
            else
                throttle = math.abs(joy_y)
            end
            load = 1.5-- 负载1.0*重量
            throttle = 1 -- 油门开度:30%
            maxSpeed = 35 -- 最大引擎转速:3500RPM
            gear = -1
        elseif gear ~= -1 then -- >5m/s 刹车
            maxSpeed = 80 -- 最大引擎转速:8000RPM
            -- 前进时的刹车按键
            -- 引擎减速率=5
            deceleration = 5
        end
    elseif joy_y == 0 then -- 油门：空
        throttle = 0 -- 油门开度:0%
        maxSpeed = 80 -- 最大引擎转速:8000RPM

    end
    speedcontroller.setTargetSpeed(speed) -- 将轮速更改实施
    
    -- 模拟声浪
    speaker.playNote("didgeridoo",(math.max(engine_speed / 26, 0.5)),(engine_speed / 5))

    -- hud渲染
    hud(speed,gear,rpm,relspeed)    
end
