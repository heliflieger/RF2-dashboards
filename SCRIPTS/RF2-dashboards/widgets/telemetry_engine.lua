local arg = {...}
local is_sim = arg[1]
local app_name = arg[2]
local log = arg[3]

local M = {}
-- local sensors = {}
local protocol
local telemetryState = false


local sensorTable = {

    -- VFR / RQly Quality
    link_rqly = {
        name = "link_rqly",
        sourceId = (protocol=="sport") and "VFR" or "RQly",
        sensors = {
            sim = {
                getValue = function() return 92 end,
                getValueMin = function() return 42 end,
                getValueMax = function() return 100 end,
            },
        },
    },

    -- link power
    link_tx_power = {
        name = "link_tx_power",
        sourceId = "TPWR",
        sensors = {
            sim = {
                getValue = function() return 25 end,
                getValueMin = function() return 10 end,
                getValueMax = function() return 500 end,
            },
        },
    },


    -- Arm Flags
    armflags = {
        name = "arming_flags",
        sourceId = "ARMD",
        sensors = {
            sim = {
                getValue = function() return 0 end,
                getValueMax = function() return 1 end,
            },
        },
        onchange = function(value)
                if value == 1 or value == 3 then
                    rfsuite.session.isArmed = true
                else
                    rfsuite.session.isArmed = false
                end
        end,
    },

    -- Is Armed
    isArmed = {
        name = "is_armed",
        sourceId = "ARM",
        sensors = {
            sim = {
                getValue = function() return 0 end,
                getValueMax = function() return 1 end,
            },
        },
        onchange = function(value)
                if value == 1 or value == 3 then
                    rfsuite.session.isArmed = true
                else
                    rfsuite.session.isArmed = false
                end
        end,
    },

    -- Voltage Sensors
    batt_voltage = {
        name = "bat-voltage",
        sourceId = "Vbat",
        lastValue = nil,
        lastValueMax = nil,
        sensors = {
            sim = {
                getValue = function() return 23.0 end,
                getValueMax = function() return 25.6 end,
            },
        },
    },

    -- Bec Voltage
    bec_voltage = {
        name = "bec_voltage",
        sourceId = "Vbec",
        lastValue = nil,
        lastValueMax = nil,
        sensors = {
            sim = {
                getValue = function() return 8.4 end,
                getValueMin = function() return 7.2 end,
                getValueMax = function() return 12 end,
            },
        },
    },

    -- -- Cell Count Sensors
    -- cell_count = {
    --     name = "cell-count",
    --     sourceId = "Cel#",
    --     lastValue = nil,
    --     lastValueMax = nil,
    --     sensors = {
    --         sim = {
    --             getValue = function() return 3 end,
    --             getValueMax = function() return 12 end,
    --         },
    --     },
    -- },

    -- RPM Sensors
    rpm = {
        name = "headspeed",
        sourceId = "Hspd", -- Hspd / RPM
        lastValue = nil,
        lastValueMax = nil,
        sensors = {
            sim = {
                getValue = function() return 1500 end,
                getValueMax = function() return 1800 end,
            },
        },
    },

    current = {
        name = "current",
        sourceId = "Curr", --???
        lastValue = nil,
        lastValueMax = nil,
        sensors = {
            sim = {
                -- getValue = function() return math.random(0, 150) end,
                -- getValueMax = function() return math.random(60, 150) end,
                getValue = function() return 40 end,
                getValueMax = function() return 120 end,

            },
        },
    },

    -- ESC Temperature Sensors
    temp_esc = {
        name = "esc_temp",
        sourceId = "Tesc", -- Tesc
        lastValue = nil,
        lastValueMax = nil,
        sensors = {
            sim = {
                -- getValue = function() return math.random(0, 80) end,
                -- getValueMax = function() return math.random(60, 130) end,
                getValue = function() return 40 end,
                getValueMax = function() return 120 end,
            }, -- Tmp1, Tmp2, EscT
        },
        --     if isFahrenheit then
        --         -- Convert from Celsius to Fahrenheit
        --         return value * 1.8 + 32, major, "°F"
        --     end
        --     -- Default: return Celsius
        --     return value, major, "°C"
    },

    capa = {
        name = "capacity",
        sourceId = "Capa", -- Capa
        lastValue = nil,
        lastValueMax = nil,
        sensors = {
            sim = {
                getValue = function() return 1000 end,
                getValueMax = function() return 1000 end,
            },
        },
    },

    -- governor = {
    --     name = "governor",
    --     sourceId = nil,
        -- lastValue = nil,
        -- lastValueMax = nil,
    --     sensors = {
    --         sim = { min = 0, max = 200 },
    --     },
    -- },

    -- -- Adjustment Sensors
    -- adj_f = {
    --     name = "adj_func",
    --     sourceId = nil,
    --     sensors = {
    --         sim = { min = 0, max = 10 },
    --     },
    -- },

    -- adj_v = {
    --     name = "adj_val",
    --     sourceId = nil,
    --     sensors = {
    --         sim = { min = 0, max = 2000 },
    --     },
    -- },

    -- PID and Rate Profiles
    pid_profile = {
        name = "pid_profile",
        sourceId = "PID#",
        lastValue = nil,
        lastValueMax = nil,
        sensors = {
            sim = {
                getValue = function() return 2 end,
                -- getValueMax = function() return 1800 end,
            },
        },
    },

    rate_profile = {
        name = "rate_profile",
        sourceId = "RTE#",
        lastValue = nil,
        lastValueMax = nil,
        sensors = {
            sim = {
                getValue = function() return 3 end,
            },
        },
    },

    -- Throttle Sensors
    throttle_percent = {
        name = "throttle_pct",
        sourceId = "Thr",
        lastValue = nil,
        lastValueMax = nil,
        sensors = {
            sim = {
                getValue = function() return 40 end,
                getValueMax = function() return 77 end,
            },
        },
    },

    -- -- Arm Disable Flags
    -- armdisableflags = {
    --     name = "armdisableflags",
    --     sourceId = nil,
        -- lastValue = nil,
        -- lastValueMax = nil,
    --     sensors = {
    --         sim = {
    --             { uid = 0x5015, unit = nil, dec = nil,
    --               value = function() return rfsuite.utils.simSensors('armdisableflags') end,
    --               min = 0, max = 65536 },
    --         },
    --     },
    -- },


}

local function searchForProtocol()
    if is_sim then
        -- log("x-telemetery7  searchForProtocol() --> SIM (simulation mode)")
        return "sim"
    end
    for n = 0, 59, 1 do
        local sensor = model.getSensor(n)
        if sensor ~= nil and sensor.name ~= '' then
            if sensor.name == "RSSI" or sensor.name == "VFR" then
                -- log("x-telemetery7  searchForProtocol() --> SPOPRT (by %s)", sensor.name)
                return "sport"
            end
            if sensor.name == "1RSS" or sensor.name == "2RSS" or sensor.name == "RQly" then
                -- log("x-telemetery7  searchForProtocol() --> CRSF (by %s)", sensor.name)
                return "crsf"
            end
        end
    end
    -- log("x-telemetery7  searchForProtocol() --> SIM (sensor not found)")
    return "sim"
end


function M.getSensorProtocol()
    return protocol
end

function M.value(objSensor)
    if objSensor == nil then
        log("x-telemetery7  value() --> objSensor is nil")
        return -1
    end

    if is_sim then
        -- log("x-telemetery7  value(%s:%s) --> SIM (simulation mode)", objSensor.name, objSensor.sourceId)
        local sm = objSensor.sensors.sim
        if not sm then
            return -2
        end

        if sm.getValue then
            local v = sm.getValue()
            -- log("x-telemetery7  value(%s:%s) --> SIM (simulation mode) = %s", objSensor.name, objSensor.sourceId, v)
            objSensor.lastValue = v
            return v
        end
        return -3
    end

    local sourceId = objSensor.sourceId
    if type(sourceId) == "function" then
        sourceId = sourceId()
    end

    local v = getValue(sourceId)
    objSensor.lastValue = v
    return v
end

function M.valueMin(objSensor)

    if objSensor == nil then
        -- log("x-telemetery  getValueMin() --> objSensor is nil")
        return -1
    end

    if is_sim then
        -- log("x-telemetery7  valueMin(%s:%s) --> SIM (simulation mode)", objSensor.name, objSensor.sourceId)
        local sm = objSensor.sensors.sim
        if not sm then
            return -2
        end
        if sm.getValueMin then
            local v = sm.getValueMin()
            -- log("x-telemetery7  valueMin(%s:%s) --> SIM (simulation mode) = %s", objSensor.name, objSensor.sourceId, v)
            if (v == nil or v == 0) then
                objSensor.lastValueMin = v
            end
            return v
        end
        return -3
    end

    local sourceId = objSensor.sourceId
    if type(sourceId) == "function" then
        sourceId = sourceId()
    end

    local v = getValue(sourceId .. "-")
    if (v == nil or v == 0) then
        objSensor.lastValueMin = v
    end

    return v
end

function M.valueMax(objSensor)

    if objSensor == nil then
        -- log("x-telemetery7  valueMax() --> objSensor is nil")
        return -1
    end

    if is_sim then
        -- log("x-telemetery7  valueMax(%s:%s) --> SIM (simulation mode)", objSensor.name, objSensor.sourceId)
        local sm = objSensor.sensors.sim
        if not sm then
            return -2
        end
        if sm.getValueMax then
            local v = sm.getValueMax()
            -- log("x-telemetery7  valueMax(%s:%s) --> SIM (simulation mode) = %s", objSensor.name, objSensor.sourceId, v)
            if (v == nil or v == 0) then
                objSensor.lastValueMax = v
            end
            return v
        end
        return -3
    end

    local sourceId = objSensor.sourceId
    if type(sourceId) == "function" then
        sourceId = sourceId()
    end

    local v = getValue(sourceId .. "+")
    if (v == nil or v == 0) then
        objSensor.lastValueMax = v
    end

    return v
end


function M.simSensors()
    local result = {}
    for key, sensor in pairs(sensorTable) do
        local name = sensor.name
        local firstSportSensor = sensor.sensors.sim and sensor.sensors.sim[1]
        if firstSportSensor then
            table.insert(result, { name = name, sensor = firstSportSensor })
        end
    end
    return result
end

-- function M.resetSensorsMinMax()
--     log("telemetry.resetSensorsMinMax() called")
--     for i = 1, 63 do
--         model.resetSensor(i)
--     end
--     log("telemetry.resetSensorsMinMax() completed")
-- end


--[[
    Function: telemetry.active
    Description: Checks if telemetry is active. Returns true if the system is in simulation mode, otherwise returns the state of telemetry.
    Returns:
        - boolean: true if in simulation mode or telemetry is active, false otherwise.
]]
function M.active()
    return rfsuite.session.telemetryState or false
end

function M.init()
    protocol = searchForProtocol()

    -- discoverAllSensors()

    -- telemetry.choose_best_sensors()
end

-- allow sensor table to be accessed externally
M.sensorTable = sensorTable


return M
