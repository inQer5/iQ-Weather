local ESX = exports["es_extended"]:getSharedObject()

RegisterCommand('weather', function()
    -- Registrace hlavního menu
    exports.ox_lib:registerContext({
        id = 'weather_menu',
        title = 'Menu Počasí a Čas',
        options = {
            {
                title = 'Počasí',
                menu = 'weather_submenu',
                arrow = true
            },
            {
                title = 'Čas',
                menu = 'time_submenu',
                arrow = true
            }
        }
    })
    -- Zobrazení hlavního menu
    exports.ox_lib:showContext('weather_menu')
end, false)

-- Seznam typů počasí s ikonami
local weatherTypes = {
    {title = 'Clear', weatherType = 'CLEAR', icon = 'sun'},
    {title = 'Extrasunny', weatherType = 'EXTRASUNNY', icon = 'sun'},
    {title = 'Clouds', weatherType = 'CLOUDS', icon = 'cloud'},
    {title = 'Overcast', weatherType = 'OVERCAST', icon = 'cloud'},
    {title = 'Rain', weatherType = 'RAIN', icon = 'cloud-rain'},
    {title = 'Clearing', weatherType = 'CLEARING', icon = 'cloud-sun'},
    {title = 'Thunder', weatherType = 'THUNDER', icon = 'bolt'},
    {title = 'Smog', weatherType = 'SMOG', icon = 'smog'},
    {title = 'Foggy', weatherType = 'FOGGY', icon = 'smog'},
    {title = 'XMAS', weatherType = 'XMAS', icon = 'snowflake'},
    {title = 'Snowlight', weatherType = 'SNOWLIGHT', icon = 'snowflake'},
    {title = 'Blizzard', weatherType = 'BLIZZARD', icon = 'snowflake'},
    {title = 'Snow', weatherType = 'SNOW', icon = 'snowflake'}
}

-- Vytvoření seznamu možností pro submenu počasí
local weatherOptions = {}
for _, weather in ipairs(weatherTypes) do
    table.insert(weatherOptions, {
        title = weather.title,
        event = 'iQ-Weather:selectWeather',
        args = weather.weatherType,
        icon = weather.icon,
        keepMenuOpen = true -- Přidání tohoto atributu pro ponechání menu otevřeného
    })
end

-- Registrace submenu pro počasí
exports.ox_lib:registerContext({
    id = 'weather_submenu',
    title = 'Počasí',
    menu = 'weather_menu',
    onBack = function()
        exports.ox_lib:showContext('weather_menu')
    end,
    options = weatherOptions
})

-- Seznam možností pro submenu času
local timeOptions = {
    {
        title = 'Posunout čas o hodinu dopředu',
        event = 'iQ-Weather:adjustTime',
        args = {hours = 1, minutes = 0},
        icon = 'clock',
        keepMenuOpen = true -- Přidání tohoto atributu pro ponechání menu otevřeného
    },
    {
        title = 'Posunout čas o hodinu zpět',
        event = 'iQ-Weather:adjustTime',
        args = {hours = -1, minutes = 0},
        icon = 'clock',
        keepMenuOpen = true -- Přidání tohoto atributu pro ponechání menu otevřeného
    },
    {
        title = 'Posunout čas o minutu dopředu',
        event = 'iQ-Weather:adjustTime',
        args = {hours = 0, minutes = 1},
        icon = 'clock',
        keepMenuOpen = true -- Přidání tohoto atributu pro ponechání menu otevřeného
    },
    {
        title = 'Posunout čas o minutu zpět',
        event = 'iQ-Weather:adjustTime',
        args = {hours = 0, minutes = -1},
        icon = 'clock',
        keepMenuOpen = true -- Přidání tohoto atributu pro ponechání menu otevřeného
    }
}

-- Registrace submenu pro čas
exports.ox_lib:registerContext({
    id = 'time_submenu',
    title = 'Čas',
    menu = 'weather_menu',
    onBack = function()
        exports.ox_lib:showContext('weather_menu')
    end,
    options = timeOptions
})

RegisterNetEvent('iQ-Weather:showTime')
AddEventHandler('iQ-Weather:showTime', function()
    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    local timeString = string.format("Aktuální čas: %02d:%02d", hours, minutes)
    ESX.ShowNotification(timeString)
end)

RegisterNetEvent('iQ-Weather:updateWeather')
AddEventHandler('iQ-Weather:updateWeather', function(weatherType)
    SetWeatherTypeNowPersist(weatherType)
    SetWeatherTypeOverTime(weatherType, 1.0)
    SetWeatherTypeNow(weatherType)
    SetOverrideWeather(weatherType)
end)

RegisterNetEvent('iQ-Weather:updateTime')
AddEventHandler('iQ-Weather:updateTime', function(hours, minutes)
    NetworkOverrideClockTime(hours, minutes, 0)
end)

RegisterNetEvent('iQ-Weather:selectWeather')
AddEventHandler('iQ-Weather:selectWeather', function(weatherType)
    TriggerServerEvent('iQ-Weather:changeWeather', weatherType)
    exports.ox_lib:showContext('weather_submenu') -- Ujistěte se, že se menu znovu zobrazí
end)

RegisterNetEvent('iQ-Weather:adjustTime')
AddEventHandler('iQ-Weather:adjustTime', function(args)
    TriggerServerEvent('iQ-Weather:changeTime', args.hours, args.minutes)
    exports.ox_lib:showContext('time_submenu') -- Ujistěte se, že se menu znovu zobrazí
end)

-- Synchronizace počasí a času při připojení hráče
RegisterNetEvent('iQ-Weather:syncWeatherAndTime')
AddEventHandler('iQ-Weather:syncWeatherAndTime', function(weatherType, hours, minutes)
    SetWeatherTypeNowPersist(weatherType)
    SetWeatherTypeOverTime(weatherType, 1.0)
    SetWeatherTypeNow(weatherType)
    SetOverrideWeather(weatherType)
    NetworkOverrideClockTime(hours, minutes, 0)
end)

-- Po připojení hráče požádá server o aktuální počasí a čas
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('iQ-Weather:requestSync')
end)
