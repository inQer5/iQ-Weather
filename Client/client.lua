local ESX = exports['es_extended']:getSharedObject()
local Config = Config or {}

-- Načítání lokalizace
local function loadLocale(locale)
    local localeFile = ('Locales/%s.lua'):format(locale)
    if not LoadResourceFile(GetCurrentResourceName(), localeFile) then
        print(('Locale file for "%s" does not exist. Falling back to default "en".'):format(locale))
        locale = 'en'
        localeFile = 'Locales/en.lua'
    end
    local locales = LoadResourceFile(GetCurrentResourceName(), localeFile)
    assert(load(locales))()
end

-- Funkce pro načtení lokalizačních textů
local function _U(entry, ...)
    if Locales[entry] then
        return string.format(Locales[entry], ...)
    else
        return entry
    end
end

-- Načíst lokalizaci při startu
loadLocale(Config.Locale)

-- Přidání event listeneru na klientovi pro zobrazení notifikace
RegisterNetEvent('iQ-Weather:showNotification')
AddEventHandler('iQ-Weather:showNotification', function(data)
    local title = _U(data.title)
    local description = _U(data.description)

    exports.ox_lib:notify({
        title = title,
        description = description,
        type = data.type
    })
end)



RegisterNetEvent('iQ-Weather:openWeatherMenu')
AddEventHandler('iQ-Weather:openWeatherMenu', function()
    -- Registrace hlavního menu
    exports.ox_lib:registerContext({
        id = 'weather_menu',
        title = _U('weather_menu_title'),
        options = {
            {
                title = _U('weather_option'),
                menu = 'weather_submenu',
                arrow = true,
                icon = 'fa-sun'
            },
            {
                title = _U('time_option'),
                menu = 'time_submenu',
                arrow = true,
                icon = 'fa-clock'
            }
        }
    })

    exports.ox_lib:showContext('weather_menu')
end)


local weatherTypes = {
    {title = _U('clear'), weatherType = 'CLEAR', icon = 'sun'},
    {title = _U('extrasunny'), weatherType = 'EXTRASUNNY', icon = 'sun'},
    {title = _U('clouds'), weatherType = 'CLOUDS', icon = 'cloud'},
    {title = _U('overcast'), weatherType = 'OVERCAST', icon = 'cloud'},
    {title = _U('rain'), weatherType = 'RAIN', icon = 'cloud-rain'},
    {title = _U('clearing'), weatherType = 'CLEARING', icon = 'cloud-sun'},
    {title = _U('thunder'), weatherType = 'THUNDER', icon = 'bolt'},
    {title = _U('smog'), weatherType = 'SMOG', icon = 'smog'},
    {title = _U('foggy'), weatherType = 'FOGGY', icon = 'smog'},
    {title = _U('xmas'), weatherType = 'XMAS', icon = 'snowflake'},
    {title = _U('snowlight'), weatherType = 'SNOWLIGHT', icon = 'snowflake'},
    {title = _U('blizzard'), weatherType = 'BLIZZARD', icon = 'snowflake'},
    {title = _U('snow'), weatherType = 'SNOW', icon = 'snowflake'}
}


local weatherOptions = {}
for _, weather in ipairs(weatherTypes) do
    table.insert(weatherOptions, {
        title = weather.title,
        event = 'iQ-Weather:selectWeather',
        args = weather.weatherType,
        icon = weather.icon,
        keepMenuOpen = true
    })
end

-- Registrace submenu pro počasí
exports.ox_lib:registerContext({
    id = 'weather_submenu',
    title = _U('weather'),
    menu = 'weather_menu',
    onBack = function()
        exports.ox_lib:showContext('weather_menu')
    end,
    options = weatherOptions
})

local timeOptions = {
    {
        title = _U('move_time_forward_hour'),
        event = 'iQ-Weather:adjustTime',
        args = {hours = 1, minutes = 0},
        icon = 'clock',
        keepMenuOpen = true
    },
    {
        title = _U('move_time_backward_hour'),
        event = 'iQ-Weather:adjustTime',
        args = {hours = -1, minutes = 0},
        icon = 'clock',
        keepMenuOpen = true
    },
    {
        title = _U('move_time_forward_minute'),
        event = 'iQ-Weather:adjustTime',
        args = {hours = 0, minutes = 1},
        icon = 'clock',
        keepMenuOpen = true
    },
    {
        title = _U('move_time_backward_minute'),
        event = 'iQ-Weather:adjustTime',
        args = {hours = 0, minutes = -1},
        icon = 'clock',
        keepMenuOpen = true
    }
}

-- Registrace submenu pro čas
exports.ox_lib:registerContext({
    id = 'time_submenu',
    title = _U('time'),
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
    local timeString = _U('current_time', hours, minutes)
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
    exports.ox_lib:showContext('weather_submenu')
    exports.ox_lib:notify({
        title = _U('weather'),
        description = _U('weather_changed', weatherType),
        type = 'success'
    })
end)

RegisterNetEvent('iQ-Weather:adjustTime')
AddEventHandler('iQ-Weather:adjustTime', function(args)
    TriggerServerEvent('iQ-Weather:changeTime', args.hours, args.minutes)
    exports.ox_lib:showContext('time_submenu')

    local hours = GetClockHours()
    local minutes = GetClockMinutes()
    exports.ox_lib:notify({
        title = _U('time'),
        description = _U('time_changed', hours, minutes),
        type = 'success'
    })
end)

RegisterNetEvent('iQ-Weather:syncWeatherAndTime')
AddEventHandler('iQ-Weather:syncWeatherAndTime', function(weatherType, hours, minutes)
    SetWeatherTypeNowPersist(weatherType)
    SetWeatherTypeOverTime(weatherType, 1.0)
    SetWeatherTypeNow(weatherType)
    SetOverrideWeather(weatherType)
    NetworkOverrideClockTime(hours, minutes, 0)
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('iQ-Weather:requestSync')
end)
