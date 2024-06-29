ESX = exports["es_extended"]:getSharedObject()
local currentWeather = 'CLEAR'
local gameTime = {hours = 12, minutes = 0}
local weatherFilePath = 'weather_time.json'
local gameMinuteDuration = 2000 -- Délka jedné herní minuty v milisekundách (2 sekundy reálného času)

-- Načtení počasí a času ze souboru
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

-- Uložení počasí a času do souboru
local function saveWeatherAndTime()
    local data = json.encode({
        weather = currentWeather,
        time = gameTime
    })
    SaveResourceFile(GetCurrentResourceName(), weatherFilePath, data, -1)
end

-- Načtení počasí a času při startu serveru
loadWeatherAndTime()

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

-- Periodická aktualizace herního času každou herní minutu
CreateThread(function()
    while true do
        Wait(gameMinuteDuration) -- čeká jednu herní minutu
        gameTime.minutes = gameTime.minutes + 1
        if gameTime.minutes >= 60 then
            gameTime.minutes = 0
            gameTime.hours = (gameTime.hours + 1) % 24
        end
        saveWeatherAndTime()
        TriggerClientEvent('iQ-Weather:updateTime', -1, gameTime.hours, gameTime.minutes)
    end
end)
