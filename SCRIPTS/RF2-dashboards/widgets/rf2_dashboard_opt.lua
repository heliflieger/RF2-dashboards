local M = {

    options = {
        {"showTotalVoltage", BOOL  , 0      }, -- 0=Show as average Lipo cell level, 1=show the total voltage (voltage as is)
        -- {"enableCapa", BOOL, 1 },
        {"guiStyle"     , CHOICE, 1 , {
            "1-Fancy",
            "2-Modern",
        }},
        {"currTop"      , VALUE , 150 , 40,300 },
        {"tempTop"      , VALUE ,  90 , 30,150 },
        {"textColor"    , COLOR , WHITE },
        {"enableAudio"  , BOOL  , 1      }, -- 0=disable audio announcements, 1=enable audio announcements
    },

    translate = function(name)
        local translations = {
            showTotalVoltage="Show Total Voltage",
            -- enableCapa="Enable Capacity",
            -- useTelemetry="Use Telemetry (faster update)",
            guiStyle="GUI Style",
            currTop="Max Current",
            tempTop="Max ESC Temp",
            textColor="Text Color",
            enableAudio="Enable Audio Announcements",
        }
        return translations[name]
    end

}

return M
