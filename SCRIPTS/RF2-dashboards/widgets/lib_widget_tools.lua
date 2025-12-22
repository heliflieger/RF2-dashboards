local arg = {...}
local m_log = arg[1]
local app_name = arg[2]

local M = {}
--M.m_log = m_log
M.app_name = app_name
M.tele_src_name = nil
M.tele_src_id = nil

local getTime = getTime
local lcd = lcd

-- better font names
local FONT_38 = XXLSIZE -- 38px
local FONT_16 = DBLSIZE -- 16px
local FONT_12 = MIDSIZE -- 12px
local FONT_8 = 0 -- Default 8px
local FONT_6 = SMLSIZE -- 6px

local FONT_LIST = {FONT_6, FONT_8, FONT_12, FONT_16, FONT_38}

---------------------------------------------------------------------------------------------------
local function log(fmt, ...)
    --m_log.info(fmt, ...)
    print("[" .. M.app_name .. "] " .. string.format(fmt, ...))
end
---------------------------------------------------------------------------------------------------

-- const's
local UNIT_ID_TO_STRING = {
    "V", "A", "mA", "kts", "m/s", "f/s", "km/h", "mph", "m", "f",
    "°C", "°F", "%", "mAh", "W", "mW", "dB", "rpm", "g", "°",
    "rad", "ml", "fOz", "ml/m", "Hz", "mS", "uS", "km"
}

function M.unitIdToString(unitId)
    if unitId == nil then
        return ""
    end
    -- UNIT_RAW
    if unitId == "0" then
        return ""
    end

    --log("idUnit: " .. unitId)

    if (unitId > 0 and unitId <= #UNIT_ID_TO_STRING) then
        local txtUnit = UNIT_ID_TO_STRING[unitId]
        --log("txtUnit: " .. txtUnit)
        return txtUnit
    end

    --return "-#-"
    return ""
end

---------------------------------------------------------------------------------------------------

function M.periodicInit()
    local t = {}
    t.startTime = -1;
    t.durationMili = -1;
    return t
end

function M.periodicStart(t, durationMili)
    t.startTime = getTime();
    t.durationMili = durationMili;
end

function M.periodicHasPassed(t, show_log)
    -- not started yet
    if (t.durationMili <= 0) then
        return false;
    end

    local elapsed = getTime() - t.startTime;
    --log('elapsed: %d (t.durationMili: %d)', elapsed, t.durationMili)
    if show_log == true then
        log('elapsed: %0.1f/%0.1f sec', elapsed/100, t.durationMili/1000)
    end
    local elapsedMili = elapsed * 10;
    if (elapsedMili < t.durationMili) then
        return false;
    end
    return true;
end

function M.periodicGetElapsedTime(t, show_log)
    local elapsed = getTime() - t.startTime;
    local elapsedMili = elapsed * 10;
    if show_log == true then
        log('elapsed: %0.1f/%0.1f sec', elapsed/100, t.durationMili/1000)
    end
    return elapsedMili;
end

function M.periodicReset(t)
    t.startTime = getTime();
    --log("periodicReset()");
    M.periodicGetElapsedTime(t)
end

function M.getDurationMili(t)
    return t.durationMili
end

---------------------------------------------------------------------------------------------------

function M.isTelemetryAvailable()
    -- select telemetry source
    if not M.tele_src_id then
        --log("select telemetry source")
        local tele_src = getFieldInfo("RSSI")
        if not tele_src then tele_src = getFieldInfo("1RSS") end
        if not tele_src then tele_src = getFieldInfo("2RSS") end
        if not tele_src then tele_src = getFieldInfo("RQly") end
        if not tele_src then tele_src = getFieldInfo("VFR%") end
        if not tele_src then tele_src = getFieldInfo("VFR") end
        if not tele_src then tele_src = getFieldInfo("TRSS") end
        if not tele_src then tele_src = getFieldInfo("RxBt") end
        if not tele_src then tele_src = getFieldInfo("A1") end

        if tele_src == nil then
            --log("no telemetry sensor found")
            M.tele_src_id = nil
            M.tele_src_name = "---"
            return false
        else
            --log("telemetry sensor found: " .. tele_src.name)
            M.tele_src_id = tele_src.id
            M.tele_src_name = tele_src.name
        end
    end

    if M.tele_src_id == nil then
        return false
    end

    local rx_val = getValue(M.tele_src_id)
    if rx_val ~= 0 then
        return true
    end
    return false
end

---------------------------------------------------------------------------------------------------

-- workaround to detect telemetry-reset event, until a proper implementation on the lua interface will be created
-- this workaround assume that:
--   RSSI- is always going down
--   RSSI- is reset on the C++ side when a telemetry-reset is pressed by user
--   widget is calling this func on each refresh/background
-- on event detection, the function onTelemetryResetEvent() will be trigger
--
function M.detectResetEvent(wgt, callback_onTelemetryResetEvent)
    local currMinRSSI = getValue('RSSI-')
    if (currMinRSSI == nil) then
        log("telemetry reset event: can not be calculated")
        return
    end
    if (currMinRSSI == wgt.telemResetLowestMinRSSI) then
        --log("telemetry reset event: not found")
        return
    end

    if (currMinRSSI < wgt.telemResetLowestMinRSSI) then
        -- rssi just got lower, record it
        wgt.telemResetLowestMinRSSI = currMinRSSI
        --log("telemetry reset event: not found")
        return
    end

    -- reset telemetry detected
    wgt.telemResetLowestMinRSSI = 101
    log("telemetry reset event detected")

    -- notify event
    callback_onTelemetryResetEvent(wgt)
end

---------------------------------------------------------------------------------------------------
function M.getSensorPrecession(sensorName)

    for i=0, 30, 1 do
        local s2 = model.getSensor(i)
        --type (number) 0 = custom, 1 = calculated
        --name (string) Name
        --unit (number) See list of units in the appendix of the OpenTX Lua Reference Guide
        --prec (number) Number of decimals
        --id (number) Only custom sensors
        --instance (number) Only custom sensors
        --formula (number) Only calculated sensors. 0 = Add etc. see list of formula choices in Companion popup

        --log("getSensorPrecession: %d. name: %s, unit: %s , prec: %s , id: %s , instance: %s ", i, s2.name, s2.unit, s2.prec, s2.id, s2.instance)

        if s2.name == sensorName then
            return s2.prec
        end
    end

    return -1
end

--function M.getSensors()
--    local sensors = {}
--    for i=0, 30, 1 do
--        local s1 = {}
--        local s2 = model.getSensor(i)
--
--        --type (number) 0 = custom, 1 = calculated
--        s1.type = s2.type
--        --name (string) Name
--        s1.name = s2.name
--        --unit (number) See list of units in the appendix of the OpenTX Lua Reference Guide
--        s1.unit = s2.unit
--        --prec (number) Number of decimals
--        s1.prec = s2.prec
--        --id (number) Only custom sensors
--        s1.id = s2.id
--        --instance (number) Only custom sensors
--        s1.instance = s2.instance
--        --formula (number) Only calculated sensors. 0 = Add etc. see list of formula choices in Companion popup
--        s1.formula = s2.formula
--
--        s1.appendix
--
--        log("getSensorPrecession: %d. name: %s, unit: %s , prec: %s , id: %s , instance: %s ", i, s2.name, s2.unit, s2.prec, s2.id, s2.instance)
--
--        if s2.name == sensorName then
--            return s2.prec
--        end
--    end
--
--    return -1
--end

---------------------------------------------------------------------------------------------------
-- workaround for bug in getFiledInfo()  -- ???? why?
function M.cleanInvalidCharFromGetFiledInfo(sourceName)

    if string.byte(string.sub(sourceName, 1, 1)) > 127 then
        sourceName = string.sub(sourceName, 2, -1)
    end
    if string.byte(string.sub(sourceName, 1, 1)) > 127 then
        sourceName = string.sub(sourceName, 2, -1)
    end

    return sourceName
end

------------------------------------------------------------------------------------------------------
function M.getFontSizeRelative(orgFontSize, delta)
    for i = 1, #FONT_LIST do
        if FONT_LIST[i] == orgFontSize then
            local newIndex = i + delta
            newIndex = math.min(newIndex, #FONT_LIST)
            newIndex = math.max(newIndex, 1)
            return FONT_LIST[newIndex]
        end
    end
    return orgFontSize
end

------------------------------------------------------------------------------------------------------
function M.lcdSizeTextFixed(txt, font_size)
    local ts_w, ts_h = lcd.sizeText(txt, font_size)

    local v_offset = 0
    if font_size == FONT_38 then
        v_offset = -15
    elseif font_size == FONT_16 then
        v_offset = -8
    elseif font_size == FONT_12 then
        v_offset = -6
    elseif font_size == FONT_8 then
        v_offset = -4
    elseif font_size == FONT_6 then
        v_offset = -3
    end
    return ts_w, ts_h +2*v_offset, v_offset
end

------------------------------------------------------------------------------------------------------
function M.drawText(x, y, text, font_size, text_color, bg_color)
    local ts_w, ts_h, v_offset = M.lcdSizeTextFixed(text, font_size)
    lcd.drawRectangle(x, y, ts_w, ts_h, BLUE)
    lcd.drawText(x, y + v_offset, text, font_size + text_color)
    return ts_w, ts_h, v_offset
end

function M.drawBadgedText(txt, txtX, txtY, font_size, text_color, bg_color)
    local ts_w, ts_h, v_offset = M.lcdSizeTextFixed(txt, font_size)
    local v_space = 2
    local bdg_h = v_space + ts_h + v_space
    local r = bdg_h / 2
    lcd.drawFilledCircle(txtX , txtY + r, r, bg_color)
    lcd.drawFilledCircle(txtX + ts_w , txtY + r, r, bg_color)
    lcd.drawFilledRectangle(txtX, txtY , ts_w, bdg_h, bg_color)

    lcd.drawText(txtX, txtY + v_offset + v_space, txt, font_size + text_color)

    --lcd.drawRectangle(txtX, txtY , ts_w, bdg_h, RED) -- dbg
end

function M.drawBadgedTextCenter(txt, txtX, txtY, font_size, text_color, bg_color)
    local ts_w, ts_h, v_offset = M.lcdSizeTextFixed(txt, font_size)
    local r = ts_h / 2
    local x = txtX - ts_w/2
    local y = txtY - ts_h/2
    lcd.drawFilledCircle(x + r * 0.3, y + r, r, bg_color)
    lcd.drawFilledCircle(x - r * 0.3 + ts_w , y + r, r, bg_color)
    lcd.drawFilledRectangle(x, y, ts_w, ts_h, bg_color)

    lcd.drawText(x, y + v_offset, txt, font_size + text_color)

    -- dbg
    --lcd.drawRectangle(x, y , ts_w, ts_h, RED) -- dbg
    --lcd.drawLine(txtX-30, txtY, txtX+30, txtY, SOLID, RED) -- dbg
    --lcd.drawLine(txtX, txtY-20, txtX, txtY+20, SOLID, RED) -- dbg
end

-- Data gathered from commercial lipo sensors
local percent_list_lipo = {
    {3.000,  0},
    {3.093,  1}, {3.196,  2}, {3.301,  3}, {3.401,  4}, {3.477,  5}, {3.544,  6}, {3.601,  7}, {3.637,  8}, {3.664,  9}, {3.679, 10},
    {3.683, 11}, {3.689, 12}, {3.692, 13}, {3.705, 14}, {3.710, 15}, {3.713, 16}, {3.715, 17}, {3.720, 18}, {3.731, 19}, {3.735, 20},
    {3.744, 21}, {3.753, 22}, {3.756, 23}, {3.758, 24}, {3.762, 25}, {3.767, 26}, {3.774, 27}, {3.780, 28}, {3.783, 29}, {3.786, 30},
    {3.789, 31}, {3.794, 32}, {3.797, 33}, {3.800, 34}, {3.802, 35}, {3.805, 36}, {3.808, 37}, {3.811, 38}, {3.815, 39}, {3.818, 40},
    {3.822, 41}, {3.825, 42}, {3.829, 43}, {3.833, 44}, {3.836, 45}, {3.840, 46}, {3.843, 47}, {3.847, 48}, {3.850, 49}, {3.854, 50},
    {3.857, 51}, {3.860, 52}, {3.863, 53}, {3.866, 54}, {3.870, 55}, {3.874, 56}, {3.879, 57}, {3.888, 58}, {3.893, 59}, {3.897, 60},
    {3.902, 61}, {3.906, 62}, {3.911, 63}, {3.918, 64}, {3.923, 65}, {3.928, 66}, {3.939, 67}, {3.943, 68}, {3.949, 69}, {3.955, 70},
    {3.961, 71}, {3.968, 72}, {3.974, 73}, {3.981, 74}, {3.987, 75}, {3.994, 76}, {4.001, 77}, {4.007, 78}, {4.014, 79}, {4.021, 80},
    {4.029, 81}, {4.036, 82}, {4.044, 83}, {4.052, 84}, {4.062, 85}, {4.074, 86}, {4.085, 87}, {4.095, 88}, {4.105, 89}, {4.111, 90},
    {4.116, 91}, {4.120, 92}, {4.125, 93}, {4.129, 94}, {4.135, 95}, {4.145, 96}, {4.176, 97}, {4.179, 98}, {4.193, 99}, {4.200,100},
}

--- return the percentage remaining in a single Lipo cel
M.getCellPercent = function(cellValue)
    if cellValue == nil then
        return 0
    end

    -- if voltage too low, return 0%
    if cellValue <= percent_list_lipo[1][1] then
        return 0
    end

    -- if voltage too high, return 100%
    if cellValue >= percent_list_lipo[#percent_list_lipo][1] then
        return 100
    end

    -- binary search
    local l = 1
    local u = #percent_list_lipo
    while true do
        local n = (u + l) // 2
        if cellValue >= percent_list_lipo[n][1] and cellValue <= percent_list_lipo[n+1][1] then
            -- return closest value
            if cellValue < (percent_list_lipo[n][1] + percent_list_lipo[n + 1][1]) / 2 then
                return percent_list_lipo[n][2]
            else
                return percent_list_lipo[n+1][2]
            end
        end
        if cellValue < percent_list_lipo[n][1] then
            u = n
        else
            l = n
        end
    end

    return 0
end

M.isFileExist = function(file_name)
    -- log("is_file_exist()")
    local hFile = io.open(file_name, "r")
    if hFile == nil then
        -- log("file not exist - %s", file_name)
        return false
    end
    io.close(hFile)
    -- log("file exist - %s", file_name)
    return true
end

return M
