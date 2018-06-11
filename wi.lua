local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local vicious = require("vicious")
local naughty = require("naughty")
local watch = require("awful.widget.watch")
local gears = require("gears")
local spawn = require("awful.spawn")

-- Spacers
spacer = wibox.widget.textbox()
spacer:set_text(' | ')

--
-- {{{ Start CPU
cpuicon = wibox.widget.imagebox()
cpuicon:set_image(beautiful.widget_cpu)
--
local cpugraph_widget = wibox.widget {
    max_value = 100,
    color = '#74aeab',
    background_color = "#00000000",
    forced_width = 50,
    step_width = 2,
    step_spacing = 1,
    widget = wibox.widget.graph
}

-- mirros and pushs up a bit
cpu_widget = wibox.container.margin(wibox.container.mirror(cpugraph_widget, { horizontal = true }), 0, 0, 0, 2)

local total_prev = 0
local idle_prev = 0

watch("cat /proc/stat | grep '^cpu '", 1,
    function(widget, stdout, stderr, exitreason, exitcode)
        local user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice =
        stdout:match('(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s')

        local total = user + nice + system + idle + iowait + irq + softirq + steal

        local diff_idle = idle - idle_prev
        local diff_total = total - total_prev
        local diff_usage = (1000 * (diff_total - diff_idle) / diff_total + 5) / 10

        if diff_usage > 80 then
            widget:set_color('#ff4136')
        else
            widget:set_color('#74aeab')
        end

        widget:add_value(diff_usage)

        total_prev = total
        idle_prev = idle
    end,
    cpugraph_widget
)
-- End CPU }}}
--
-- {{{ Start Mem
memicon = wibox.widget.imagebox()
memicon:set_image(beautiful.widget_ram)
--
mem = wibox.widget.textbox()
vicious.register(mem, vicious.widgets.mem, "Mem: $1% Use: $2MB Total: $3MB Free: $4MB Swap: $5%", 2)
-- End Mem }}}

-- {{{ Start Volume Widget
GET_VOLUME_CMD = 'amixer -D pulse sget Master'
INC_VOLUME_CMD = 'amixer -D pulse sset Master 5%+'
DEC_VOLUME_CMD = 'amixer -D pulse sset Master 5%-'
TOG_VOLUME_CMD = 'amixer -D pulse sset Master toggle'

volumearc = wibox.widget {
    max_value = 1,
    thickness = 2,
    start_angle = 4.71238898, -- 2pi*3/4
    forced_height = 17,
    forced_width = 17,
    bg = "#ffffff11",
    paddings = 2,
    widget = wibox.container.arcchart
}

volumearc_widget = wibox.container.mirror(volumearc, { horizontal = true })

update_graphic = function(widget, stdout, _, _, _)
    mute = string.match(stdout, "%[(o%D%D?)%]")
    volume = string.match(stdout, "(%d?%d?%d)%%")
    volume = tonumber(string.format("% 3d", volume))

    widget.value = volume / 100;
    if mute == "off" then
        widget.colors = { beautiful.widget_red }
    else
        widget.colors = { beautiful.widget_main_color }
    end
end

volumearc:connect_signal("button::press", function(_, _, _, button)
    if (button == 4) then awful.spawn(INC_VOLUME_CMD, false)
    elseif (button == 5) then awful.spawn(DEC_VOLUME_CMD, false)
    elseif (button == 1) then awful.spawn(TOG_VOLUME_CMD, false)
    end

    spawn.easy_async(GET_VOLUME_CMD, function(stdout, stderr, exitreason, exitcode)
        update_graphic(volumearc, stdout, stderr, exitreason, exitcode)
    end)
end)

watch(GET_VOLUME_CMD, 1, update_graphic, volumearc)

-- End Volume Widget }}}

-- {{ Start Spotify Widget Based on https://github.com/streetturtle/awesome-wm-widgets/tree/master/spotify-widget
SP_PATH = '/home/setkeh/.bin/sp'
GET_SPOTIFY_STATUS_CMD = SP_PATH .. ' status'
GET_CURRENT_SONG_CMD = SP_PATH .. ' current-oneline'
PATH_TO_ICONS = "/usr/share/icons/Arc"

spotify_widget = wibox.widget {
    {
        id = "icon",
        widget = wibox.widget.imagebox,
    },
    {
        id = 'current_song',
        widget = wibox.widget.textbox,
        font = 'Play 9'
    },
    layout = wibox.layout.align.horizontal,
    set_status = function(self, is_playing)
        if (is_playing) then
            self.icon.image = PATH_TO_ICONS .. "/actions/24/player_play.png"
        else
            self.icon.image = PATH_TO_ICONS .. "/actions/24/player_pause.png"
        end
    end,
    set_text = function(self, path)
        self.current_song.markup = path
    end,
}

update_widget_icon = function(widget, stdout, _, _, _)
    stdout = string.gsub(stdout, "\n", "")
    if (stdout == 'Playing') then
        widget:set_status(true)
    else
        widget:set_status(false)
    end
end

update_widget_text = function(widget, stdout, _, _, _)
    if string.find(stdout, 'Error: Spotify is not running.') ~= nil then
        widget:set_text('')
        widget:set_visible(false)
    else
        widget:set_text(stdout)
        widget:set_visible(true)
    end
end

watch(GET_SPOTIFY_STATUS_CMD, 1, update_widget_icon, spotify_widget)
watch(GET_CURRENT_SONG_CMD, 1, update_widget_text, spotify_widget)

--- Adds mouse controls to the widget:
--  - left click - play/pause
--  - scroll up - play next song
--  - scroll down - play previous song
spotify_widget:connect_signal("button::press", function(_, _, _, button)
    if (button == 1) then awful.spawn(SP_PATH .. " play", false)      -- left click
    elseif (button == 4) then awful.spawn(SP_PATH .. " next", false)  -- scroll up
    elseif (button == 5) then awful.spawn(SP_PATH .. " prev", false)  -- scroll down
    end
    awful.spawn.easy_async(GET_SPOTIFY_STATUS_CMD, function(stdout, stderr, exitreason, exitcode)
        update_widget_icon(spotify_widget, stdout, stderr, exitreason, exitcode)
    end)
end)
-- End Spotify Widget}}