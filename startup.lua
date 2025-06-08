-- startup.lua  版本2025/6/8 21:24
-- 修改初始配置请第一次启动后查看config.lua
ver = "-- 1.0" 
-- 配置文件版本请勿更改

-- 配置文件
configfile = "-- 1.0\n-- 配置文件版本请勿更改\n".."hud_type = 0 -- 为自定义hud做准备\nparking_brake = 1 -- 手刹\n-- 初始化变速箱\ngear = 0\nspeed = 0\ngearbox_type = 0\n-- 0 = MT\n-- 1 = auto_snug\n-- 2 = auto_sports\n-- 3 = auto_overload\n-- 初始化引擎\nengine_speed = 0 -- 启动转速\nmaxSpeed = 80 -- 最大转速（此处仅为启动时最大转速）\nacceleration = 3 -- 加速率（同上）\ndeceleration = 2 -- 减速率（同上）\nthrottle = 0.0 -- 油门\nload = 0 -- 负载(负载=车重*一个很迷的数？)\nmass = 0.6 -- 车重(负载基数)\nstartup = 1.6 -- 引擎启动参数 -1：待命 0.9：启动 1.6：执行启动动作\n-- 初始化其他参数\nrelspeed = 0 -- 真实速度（m/s）"


--- 初始化
-- 显示器
local monitor = peripheral.find("monitor")
if not monitor then
    print("NOT FOUND MONITOR")
end

-- 初始化HUD参数
monitor.clear()
monitor.setTextScale(0.5)
monitor.setCursorPos(1,1)
local hud_scale = monitor.getSize()


-- 配置文件
local config = io.open("config.lua","r")
if config then
    io.input(config)
    configVer = (io.read())
    print("ConfigVer:"..configVer)
    if configVer ~= ver then
        monitor.setCursorPos(1,1)
        monitor.write("updConfig")
        os.sleep(0.1)
        local config = io.open("config.lua","w")
        io.output(config)
        io.write(configfile)
        io.close(config)
        monitor.setCursorPos(1,2)
        monitor.write("reboot...")
        os.sleep(1)
        os.reboot()
    end
    monitor.setCursorPos(1,1)
    monitor.write("configOK")
    monitor.setCursorPos(1,1)
    monitor.write(config)
    dofile("config.lua")
    io.close(config)
else
    monitor.setCursorPos(1,1)
    monitor.write("createConfig")
    os.sleep(0.1)
    local config = io.open("config.lua","w")
    io.close(config)
    local config = io.open("config.lua","a")
    io.output(config)
    io.write(configfile)
    io.close(config)
    monitor.setCursorPos(1,1)
    monitor.write("reboot...        ")
    os.sleep(1)
    os.reboot()
end


-- 转速控制器
local speedcontroller = peripheral.find("Create_RotationSpeedController")
if not speedcontroller then
    monitor.setCursorPos(1,1)
    monitor.write("NOT FOUND SPEEDCONTROLLER       ")
    return
end

-- 放在书架上的Create:Tweaked Controller
local joy = peripheral.find("tweaked_controller")
if not joy then
    monitor.setCursorPos(1,1)
    monitor.write("NOT FOUND JOY                 ")
end

-- 扬声器
local speaker = peripheral.find("speaker")
if not speaker then
    monitor.setCursorPos(1,1)
    monitor.write("NOT FOUND SPEAKER               ")
end

-- 启动引擎
function startengine()
    if startup == -1 then
        local joy_start = joy.getButton(7)
        if joy_start == true then
            startup = 1.6
        end
    end
    if startup > 1 then
        hud(speed,gear,rpm,relspeed)
        startup = math.max((startup - 0.05),1)
        engine_speed = math.min((engine_speed + 5),12)
        speaker.playNote("didgeridoo",(math.max(engine_speed / 26, 2)),(engine_speed / 3))
        speaker.playNote("bit",(math.max(engine_speed / 26, 2)),(engine_speed / 2))
        os.sleep(0.15)
    elseif startup == 1 and startup > 0.9 then
        speaker.playNote("didgeridoo",(math.max(engine_speed / 26, 3)),(engine_speed / 3))
        
        engine_speed = 15
        startup = 0.9
    end
end

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
    local rpmstr = (math.max((math.min((math.floor(engine_speed)+4),100)),0) / 10) -- 转速=1000*rpmstr

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
    monitor.setCursorPos(((hud_scale / 2 - 7) - rpmstr*5) + 2,(hud_scale / 2) + 2)
    monitor.write("-----+----+----+----+----+----+----+----+----+----+----+----+----+----")
    monitor.setCursorPos(((hud_scale / 2 - 7) - rpmstr*5) + 2,(hud_scale / 2) + 3)
    monitor.write("     0    1    2    3    4    5    6    7    8    9   10   11   12")
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
    monitor.setCursorPos((gear + 1 ) * 2 + 2    ,2)
    monitor.write("=")

   
    if gearbox_type == 3 then
    monitor.setCursorPos((hud_scale / 2) - 3,3)
    monitor.write("OVERLOAD")
    elseif gearbox_type == 2 then
    monitor.setCursorPos((hud_scale / 2) - 1,3)
    monitor.write("SPORT")
    end
    
    
    if parking_brake == 1 then
        monitor.setCursorPos(1,3)
        monitor.write("                     ")
        monitor.setCursorPos((hud_scale / 2) - 1,3)
        monitor.write("BREAK")
    end
end

-- 变速箱模式（自动）
function gearbox(gearbox_type)
    if gearbox_type == 1 then
        auto_snug()
    elseif gearbox_type == 2 then
        auto_sports()
    elseif gearbox_type == 3 then
        auto_overload()
    end
end   


-- 变速箱：MT手动
function mt()
    local joy_a = (joy.getButton(1)) -- 获取A按键（XBOX）
    local joy_b = (joy.getButton(2)) -- 获取B按键（XBOX）
    if joy_b == true then -- B加档
        gear = math.min((gear + 1),5)
        os.sleep(0.05)
    end
    if joy_a == true then -- A减档
        gear = math.max((gear - 1),-1)
        os.sleep(0.05)
    end
end

-- 变速箱：AT运动模式

function auto_sports()
    mass = 0.6
    acceleration = 3 -- 加速率
    deceleration = 2 -- 减速率
    maxSpeed = 80 -- 最大引擎转速:8000RPM
    if relspeed < 0.3 then -- 如果真实速度小于0.3则自动空档
        gear = 0
    end

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
    mass = 0.45
    acceleration = 2.3 -- 加速率
    deceleration = 1.5 -- 减速率
    maxSpeed = 50 -- 最大引擎转速:5000RPM
    if speed < 2 then
        gear = 1
    end
    if engine_speed > 40 then
        gear = math.min(gear + 1,5)
    elseif engine_speed < 10 then
        gear = math.max(gear -1,1)
    end  
end

-- 变速箱：AT过载
function auto_overload()
    mass = 0.6
    acceleration = 3 -- 加速率
    deceleration = 2 -- 减速率
    maxSpeed = 120 -- 最大引擎转速:8000RPM
    if speed < 2 then
        gear = 1
    end
    if engine_speed > 100 then
        gear = math.min(gear + 1,5)
    elseif engine_speed < 30 then
        gear = math.max(gear -1,1)
    end  
end    

-- 轮速度（引擎速度->齿轮比->轮速）
function speed_ctl()
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
end

-- 引擎速度（轮速->齿轮比->引擎速度）
function engine_speed_ctl() 
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
end

-- 引擎油门（节气门）
function engine_accelerator()
    if throttle > 0 then -- 加速
        engine_speed = math.min((engine_speed + acceleration * throttle) - load, maxSpeed)  -- 加速
        -- (引擎速度+加速率*油门开度)- 负载 小于最大速度
    else -- 减速
        engine_speed = math.max(engine_speed - deceleration, 2)  
        -- 引擎速度-减速率 最小0rpm
    end
end

-- 控制器（前进/后退）（自动）
function car_ctl_auto()
    if joy_y < 0 or joy_rt > 0.1 then -- 油门
        
    if gear == -1 and relspeed > 3 then
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
end

-- 控制器（油门/刹车/离合）（手动）
function car_ctl_mt()
    local joy_lb = (joy.getButton(5)) -- 获取L按键（XBOX）

    if joy_y < 0 or joy_rt > 0.1 then -- 油门
            deceleration = 2 -- 引擎减速率=2
            if joy_rt > 0.1 then
                throttle = joy_rt
            else
                throttle = math.abs(joy_y)
            end     
    elseif joy_y < 0.1 then
        throttle = 0
        -- 减速
    elseif joy_y > 0 or joy_lb == true then -- 刹车
        throttle = 0
        -- 减速
        brake = 1
        speed = speed * (1 - brake) -- 减速
    end
    if joy_lt > 0.1 then -- 离合器
        mt()
    else
        speed_ctl()
        engine_speed_ctl()
    end
    engine_accelerator()
end

function main()
    -- 通用
    joy_add = joy.getButton(8) -- 获取+/菜单按键/开始（XBOX）
    joy_x = joy.getButton(3) -- 获取X按键（XBOX）
    joy_start = joy.getButton(7) -- 获取返回按键(XBOX)
    joy_y = joy.getAxis(2) -- 获取手柄左摇杆Y轴
    joy_rt = joy.getAxis(6) -- 获取手柄右扳机
    joy_lt = joy.getAxis(5) -- 获取手柄左扳机


    local truespeed = ship.getVelocity() -- 获取速度分量
    relspeed = math.sqrt(truespeed.x^2 + truespeed.z^2) -- 计算真实速度(m/s)
    
    -- 关闭引擎
    if joy_start == true then
        startup = -1
    end

    -- 变速箱模式切换
    if joy_add == true then
        if gear ~= 5 then
            engine_speed = 0
            gearbox_type = gearbox_type + 1
            if gearbox_type == 4 then
                gearbox_type = 0
            end
        end
        os.sleep(0.5)
    end
    
    

    -- 手刹
    if joy_x == true then
        if parking_brake == 1 then
            parking_brake = 0
            
        else
            parking_brake = 1
        end
        os.sleep(0.05)
    end

    if parking_brake == 1 then
        speed = 0

    end

    -- 引擎速度（轮速->齿轮比->引擎速度）
    if gearbox_type ~= 0 then
        engine_speed_ctl()

        -- 引擎油门（节气门）
        engine_accelerator()

        -- 轮速度（引擎速度->齿轮比->轮速）
        speed_ctl()
    end

    speedcontroller.setTargetSpeed(speed) -- 这东西不放这会出问题=-=

    if gearbox_type ~= 0 then
        car_ctl_auto()
    else
        car_ctl_mt()
    end

    speedcontroller.setTargetSpeed(speed) -- 将轮速更改实施
    
    -- 模拟声浪
    speaker.playNote("didgeridoo",(math.max(engine_speed / 26, 0.5)),(engine_speed / 8))

    -- hud渲染
    hud(speed,gear,rpm,relspeed)    
end





-- 主循环(有很多东西可以简化成funciton)
while true do
    
    startengine()
    if startup == 0.9 then
        main()
    end
end
