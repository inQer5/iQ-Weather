ESX = exports["es_extended"]:getSharedObject()

local currentWeather = 'CLEAR'
local gameTime = {hours = 12, minutes = 0}
local weatherFilePath = 'weather_time.json'
local gameMinuteDuration = 2000

-- Aktuální verze skriptu
local currentVersion = '0.0.2'

local function getLatestRelease()
    PerformHttpRequest('https://api.github.com/repos/inQer5/iQ-Weather/releases/latest', function(statusCode, response, headers)
        if statusCode == 200 then
            local releaseInfo = json.decode(response)
            local latestVersion = releaseInfo.tag_name:match("^%s*(.-)%s*$")  -- Trim whitespace
            if currentVersion == latestVersion then
                print("\27[32mYou are using the latest version!\27[0m")
            else
                print("\27[31mYour version is outdated. Please download the latest version.\27[0m")
            end
            TriggerClientEvent('carwash:checkVersion', -1, currentVersion, latestVersion)
        else
            print("Failed to fetch release info. Status code: " .. statusCode)
        end
    end, 'GET', '', {['User-Agent'] = 'lua-script'})
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        getLatestRelease()
    end
end)

local function loadWeatherAndTime()
    local file = LoadResourceFile(GetCurrentResourceName(), weatherFilePath)
    if file then
        local data = json.decode(file)
        if data then
            if data.weather then
                currentWeather = data.weather
            end
            if data.time then
                gameTime.hours = data.time.hours or gameTime.hours
                gameTime.minutes = data.time.minutes or gameTime.minutes
            end
        end
    end
end

local function saveWeatherAndTime()
    local data = json.encode({
        weather = currentWeather,
        time = gameTime
    })
    SaveResourceFile(GetCurrentResourceName(), weatherFilePath, data, -1)
end

loadWeatherAndTime()

RegisterCommand('weather', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        -- Kontrola oprávnění pomocí ACE
        if IsPlayerAceAllowed(source, "iQ-Weather") then
            TriggerClientEvent('iQ-Weather:openWeatherMenu', source)
        else
            -- Pokud hráč nemá oprávnění, poslat lokalizovanou notifikaci zpět
            TriggerClientEvent('iQ-Weather:showNotification', source, {
                title = 'access_denied',
                description = 'no_permission',
                type = 'error'
            })
        end
    end
end, true) -- 'true' nastavuje příkaz jako omezený pro administrátory


RegisterNetEvent('iQ-Weather:changeWeather')
AddEventHandler('iQ-Weather:changeWeather', function(weatherType)
    currentWeather = weatherType
    saveWeatherAndTime()
    TriggerClientEvent('iQ-Weather:updateWeather', -1, weatherType)
end)

RegisterNetEvent('iQ-Weather:requestSync')
AddEventHandler('iQ-Weather:requestSync', function()
    local src = source
    TriggerClientEvent('iQ-Weather:syncWeatherAndTime', src, currentWeather, gameTime.hours, gameTime.minutes)
end)

RegisterNetEvent('iQ-Weather:changeTime')
AddEventHandler('iQ-Weather:changeTime', function(hours, minutes)
    gameTime.hours = (gameTime.hours + hours) % 24
    gameTime.minutes = (gameTime.minutes + minutes) % 60
    if gameTime.minutes < 0 then
        gameTime.minutes = gameTime.minutes + 60
        gameTime.hours = gameTime.hours - 1
    end
    if gameTime.hours < 0 then
        gameTime.hours = gameTime.hours + 24
    end
    saveWeatherAndTime()
    TriggerClientEvent('iQ-Weather:updateTime', -1, gameTime.hours, gameTime.minutes)
end)

CreateThread(function()
    while true do
        Wait(gameMinuteDuration)
        gameTime.minutes = gameTime.minutes + 1
        if gameTime.minutes >= 60 then
            gameTime.minutes = 0
            gameTime.hours = (gameTime.hours + 1) % 24
        end
        saveWeatherAndTime()
        TriggerClientEvent('iQ-Weather:updateTime', -1, gameTime.hours, gameTime.minutes)
    end
end)
