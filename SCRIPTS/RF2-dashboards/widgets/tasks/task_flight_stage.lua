local arg = {...}
local baseDir = arg[1]
local log = arg[2]
local app_name = arg[3]

local M = {}

-- state machine
M.FLIGHT_STATE = {
    PRE_FLIGHT = 0,
    ON_AIR = 1,
    POST_FLIGHT = 2,
}
local state = M.FLIGHT_STATE.PRE_FLIGHT

-- thresholds for state transitions
local RPM_TAKEOFF_THRESHOLD = 500  -- RPM above which we consider the heli airborne
local RPM_LANDING_THRESHOLD = 300  -- RPM below which we consider the heli landed
local STATE_CHANGE_DELAY = 500  -- delay in 10ms units (500 = 5 seconds)

-- state transition tracking
local takeoff_condition_start_time = nil
local landing_condition_start_time = nil

-- state entry handlers
local function onEnterStatePreFlight()
    log("task_flight_stage: -> pre_flight")
    state = M.FLIGHT_STATE.PRE_FLIGHT
end

local function onEnterStateOnAir(head_speed)
    log("task_flight_stage: -> on_air (rpm: %s)", head_speed)
    state = M.FLIGHT_STATE.ON_AIR

    log("telemetry.resetSensorsMinMax() called")
    for i = 0, 63 do
        model.resetSensor(i)
    end
    log("telemetry.resetSensorsMinMax() completed")

    playFile("takeoff.wav")  -- optional audio notification
end

local function onEnterStatePostFlight(head_speed)
    log("task_flight_stage: -> post_flight (rpm: %s)", head_speed)
    state = M.FLIGHT_STATE.POST_FLIGHT
    playFile("landing.wav")  -- optional audio notification
end

M.init = function(wgt)
    log("task_flight_stage.init called")
    takeoff_condition_start_time = nil
    landing_condition_start_time = nil
    onEnterStatePreFlight()
end

local updateStateIfNeeded = function(head_speed)

    local current_time = getTime()

    -- state machine transitions
    if state == M.FLIGHT_STATE.PRE_FLIGHT or state == M.FLIGHT_STATE.POST_FLIGHT then
        if head_speed < RPM_TAKEOFF_THRESHOLD then
            if takeoff_condition_start_time~=nil then
                log("task_flight_stage: takeoff aborted")
            end
            takeoff_condition_start_time = nil
            return
        end

        if takeoff_condition_start_time == nil then
            takeoff_condition_start_time = current_time
            log("task_flight_stage: takeoff condition, waiting %s seconds", STATE_CHANGE_DELAY / 100)
            return
        end

        if (current_time - takeoff_condition_start_time) >= STATE_CHANGE_DELAY then
            onEnterStateOnAir(head_speed)
            takeoff_condition_start_time = nil
        end
        return

    elseif state == M.FLIGHT_STATE.ON_AIR then
        if head_speed > RPM_LANDING_THRESHOLD then
            if landing_condition_start_time~=nil then
                log("task_flight_stage: landing aborted")
            end
            landing_condition_start_time = nil
            return
        end

        if landing_condition_start_time == nil then
            landing_condition_start_time = current_time
            log("task_flight_stage: landing condition, waiting %s seconds", STATE_CHANGE_DELAY / 100)
            return
        end

        if (current_time - landing_condition_start_time) >= STATE_CHANGE_DELAY then
            onEnterStatePostFlight(head_speed)
            landing_condition_start_time = nil
        end

    end

end

M.getFlightStage = function()
    return state
end
M.getFlightStageStr = function()
    local stateStrs = {
        [M.FLIGHT_STATE.PRE_FLIGHT]  = "Pre-Flight",
        [M.FLIGHT_STATE.ON_AIR]      = "On Air",
        [M.FLIGHT_STATE.POST_FLIGHT] = "Post-Flight",
    }
    return stateStrs[state] or "---"
end

M.isOnAir = function()
    return state == M.FLIGHT_STATE.ON_AIR
end

M.isOnGround = function()
    return state == M.FLIGHT_STATE.PRE_FLIGHT or state == M.FLIGHT_STATE.POST_FLIGHT
end

M.run = function(wgt)
    local head_speed = wgt.values.rpm
    if head_speed == nil then
        return 0
    end

    updateStateIfNeeded(head_speed)
    return 0
end

return M
