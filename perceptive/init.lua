-- Perceptive, a weather notification module for Awesome WM.
--
-- Author: Ilia Glazkov

local naughty = naughty
local timer = timer
local io = require("io")
local debug = require("debug")
local string = string
local print = print

module('perceptive')

local project_path = debug.getinfo(1, 'S').source:match[[^@(.*/).*$]]
local script_path = project_path .. 'weather-fetcher.py'
local script_cmd = script_path .. ' --id='
local tmpfile = '/tmp/.awesome.weather'
local weather_data = ""
local notification = nil
local pattern = '%a.+'
local city_id = nil


function execute(cmd, output, callback)
    -- Executes command line, writes its output to temporary file, and
    -- runs the callback with output as an argument.
    local cmdline = cmd .. " &> " .. output .. " & "
    io.popen(cmdline):close()

    local execute_timer = timer({ timeout = 7 })
    execute_timer:add_signal("timeout", function()
        execute_timer:stop()
        local f = io.open(output)
        callback(f:read("*all"))
        f:close()
    end)
    execute_timer:start()
end


function fetch_weather()
    execute(script_cmd .. city_id, tmpfile, function(text)
        old_weather_data = weather_data
        weather_data = string.gsub(text, "[\n]$", "")
        if notification ~= nil and old_weather_data ~= weather_data then
            show_notification()
        end
    end)
end


function remove_notification()
    if notification ~= nil then
        naughty.destroy(notification)
        notification = nil
    end
end


function show_notification()
    remove_notification()
    notification = naughty.notify({
        text = weather_data,
    })
end


function register(widget, id)
    city_id = id
    update_timer = timer({ timeout = 600 })
    update_timer:add_signal("timeout", function()
        fetch_weather()
    end)
    update_timer:start()
    fetch_weather()

    widget:add_signal("mouse::enter", function()
        show_notification()
    end)
    widget:add_signal("mouse::leave", function()
        remove_notification()
    end)
end
