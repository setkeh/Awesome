local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local vicious = require("vicious")
local naughty = require("naughty")
--local disk = require("diskusage")

-- Spacers
volspace = wibox.widget.textbox()
volspace:set_text(" ")

-- {{{ BATTERY
-- Battery attributes
local bat_state  = ""
local bat_charge = 0
local bat_time   = 0
local blink      = true

-- Icon
baticon = wibox.widget.imagebox()
baticon:set_image(beautiful.widget_batfull)

-- Charge %
batpct = wibox.widget.textbox()
vicious.register(batpct, vicious.widgets.bat, function(widget, args)
  bat_state  = args[1]
  bat_charge = args[2]
  bat_time   = args[3]

  if args[1] == "-" then
    if bat_charge > 70 then
      baticon:set_image(beautiful.widget_batfull)
    elseif bat_charge > 30 then
      baticon:set_image(beautiful.widget_batmed)
    elseif bat_charge > 10 then
      baticon:set_image(beautiful.widget_batlow)
    else
      baticon:set_image(beautiful.widget_batempty)
    end
  else
    baticon:set_image(beautiful.widget_ac)
    if args[1] == "+" then
      blink = not blink
      if blink then
        baticon:set_image(beautiful.widget_acblink)
      end
    end
  end

  return args[2] .. "%"
end, nil, "BAT1")

-- Buttons
function popup_bat()
  local state = ""
  if bat_state == "↯" then
    state = "Full"
  elseif bat_state == "↯" then
    state = "Charged"
  elseif bat_state == "+" then
    state = "Charging"
  elseif bat_state == "-" then
    state = "Discharging"
  elseif bat_state == "⌁" then
    state = "Not charging"
  else
    state = "Unknown"
  end

  naughty.notify { text = "Charge : " .. bat_charge .. "%\nState  : " .. state ..
    " (" .. bat_time .. ")", timeout = 5, hover_timeout = 0.5 }
end
batpct:buttons(awful.util.table.join(awful.button({ }, 1, popup_bat)))
baticon:buttons(batpct:buttons())
-- End Battery}}}
--
-- {{{ PACMAN
-- Icon
pacicon = wibox.widget.imagebox()
pacicon:set_image(beautiful.widget_pac)
--
-- Upgrades
pacwidget = wibox.widget.textbox()
vicious.register(pacwidget, vicious.widgets.pkg, function(widget, args)
  if args[1] > 0 then
  pacicon:set_image(beautiful.widget_pacnew)
 else
   pacicon:set_image(beautiful.widget_pac)
 end
 return args[1]
 end, 1801, "Arch S") -- Arch S for ignorepkg
--
-- Buttons
--  function popup_pac()
--  local pac_updates = ""
--  local f = io.popen("pacman -Sup --dbpath /tmp/pacsync")
--  if f then
--  pac_updates = f:read("*a"):match(".*/(.*)-.*\n$")
--  end
--  f:close()
--  if not pac_updates then
--  pac_updates = "System is up to date"
--  end
--  naughty.notify { text = pac_updates }
--  end
--  pacwidget:buttons(awful.util.table.join(awful.button({ }, 1, popup_pac)))
--  pacicon:buttons(pacwidget:buttons())
-- End Pacman }}}
--
-- {{{ VOLUME
-- Cache
vicious.cache(vicious.widgets.volume)
--
-- Icon
volicon = wibox.widget.imagebox()
volicon:set_image(beautiful.widget_vol)
--


-- Volume Widget --
volumecfg = {}
volumecfg.cardid  = 0
volumecfg.channel = "Master"
volumecfg.widget = wibox.widget.textbox("volumecfg.widget")
--volumecfg.widget:set_text("")
--volumecfg.widget = wibox.widget.textbox()
--volumecfg.widget:set_marketup("volumecfg.widget")
volumecfg_t = awful.tooltip({ objects = { volumecfg.widget },})
volumecfg_t:set_text("Volume")
 
-- command must start with a space!
volumecfg.mixercommand = function (command)
       local fd = io.popen("amixer -c" .. volumecfg.cardid .. command)
       local status = fd:read("*all")
       fd:close()
 
       local volume = string.match(status, "(%d?%d?%d)%%")
       volume = string.format("% 3d", volume)
       status = string.match(status, "%[(o[^%]]*)%]")
       if string.find(status, "on", 1, true) then
               volume = volume .. "%"
       else
               volume = volume .. "M"
       end
       volumecfg.widget:set_text(volume)
end
volumecfg.update = function ()
       volumecfg.mixercommand(" sget " .. volumecfg.channel)
end
volumecfg.up = function ()
       volumecfg.mixercommand(" sset " .. volumecfg.channel .. " 1%+")
end
volumecfg.down = function ()
       volumecfg.mixercommand(" sset " .. volumecfg.channel .. " 1%-")
end
volumecfg.toggle = function ()
       os.execute("amixer -q sset ".. volumecfg.channel .. " toggle")
       volumecfg.mixercommand(" sset " .. volumecfg.channel .. " 0%-")
       --volumecfg.mixercommand(" sset " .. volumecfg.channel .. " toggle")
end
volumecfg.widget:buttons({
       button({ }, 4, function () volumecfg.up() end),
       button({ }, 5, function () volumecfg.down() end),
       button({ }, 1, function () volumecfg.toggle() end)
})
volumecfg.update()




-- Volume %
volpct = wibox.widget.textbox()
vicious.register(volpct, vicious.widgets.volume, "$1%", nil, "Master")
--
-- Buttons
--volicon:buttons(awful.util.table.join(
     --awful.button({ }, 1,
     --function() awful.util.spawn_with_shell("amixer -c 0 -q set Master toggle") end),
     --awful.button({ }, 4,
     --function() awful.util.spawn_with_shell("amixer -c 0 -q set Master 3%+ unmute") end),
     --awful.button({ }, 5,
    -- function() awful.util.spawn_with_shell("amixer --c 0 q set Master 3%- unmute") end)
           -- ))
  --   volpct:buttons(volicon:buttons())
--     volspace:buttons(volicon:buttons())
 -- End Volume }}}
 --

--Weather Image--
weatheric = wibox.widget.textbox()
weatheric:set_text("☂ ")



---Weather Widget
weather = wibox.widget.textbox()
weather_box = awful.tooltip({ objects = { weather },})
vicious.register(weather, vicious.widgets.weather,
   function(widgets, args)
   weather_box:set_text("City: ".. args["{city}"] .. "\nSky: " .. args["{sky}"] .. "\nHumidity: " .. args["{humid}"] .. "%" .. "\nWind: " .. args["{windmph}"] .. " MP/h") return args["{tempf}"].."℉" end, 
   1200, "KLOU")
  ---Change KLOU to yours
  --For Celsius change to {tempc} instead of {tempf}

-- {{{ Start CPU
cpuicon = wibox.widget.imagebox()
cpuicon:set_image(beautiful.widget_cpu)
--
cpu = wibox.widget.textbox()
vicious.register(cpu, vicious.widgets.cpu, "All: $1% 1: $2% 2: $3% 3: $4% 4: $5%", 2)
-- End CPU }}}
--{{ Disk Usage
-- Disk usage widget
diskwidget = wibox.widget.textbox()
--diskwidget.set_image("/home/rat/.config/awesome/du.png")
diskwidget:set_text("test")
disk = require("diskusage")
disk.addToWidget(diskwidget, 75, 90, false)
--


--
-- {{{ Start Mem
memicon = wibox.widget.imagebox()
memicon:set_image(beautiful.widget_ram)
--
mem = wibox.widget.textbox()
vicious.register(mem, vicious.widgets.mem, "Mem: $1% Use: $2MB Total: $3MB Free: $4MB Swap: $5%", 2)
-- End Mem }}}
--
-- {{{ Start Gmail 
mailicon = wibox.widget.imagebox(beautiful.widget_mail)
mailwidget = wibox.widget.textbox()
gmail_t = awful.tooltip({ objects = { mailwidget },})
vicious.register(mailwidget, vicious.widgets.gmail,
        function (widget, args)
        gmail_t:set_text(args["{subject}"])
        gmail_t:add_to_object(mailicon)
            return args["{count}"]
                 end, 120) 

     mailicon:buttons(awful.util.table.join(
         awful.button({ }, 1, function () awful.util.spawn("urxvt -e mutt", false) end)
     ))
-- End Gmail }}}
--
--- {{{ Start Network Monitor
--Network Icon ↑
netwidgeticon = wibox.widget.textbox()
netwidgeticon:set_text("Network ↑: ")
-- Network widget
netwidget = awful.widget.graph()
netwidget:set_width(45)
netwidget:set_height(3)
netwidget:set_background_color("#494B4F")
netwidget:set_color("#FF5656")
--netwidget:set_colors({type = "linear" , from = {0, 0}, stops = ({0, "} , (0.5, "} , {1, } }})
netwidget:set_color({ type = "linear", from = { 0, 0 }, to = { 0, 20 }, stops = { { 0, "#FF5656"}, { 0.5, "#88A175" }, { 1, "#AECF96" } }})
netwidget_t = awful.tooltip({ objects = { netwidget.widget },})
vicious.register(netwidget, vicious.widgets.net,
                    function (widget, args)
                        netwidget_t:set_text("Network download: " .. 
args["{wlan0 down_kb}"] .. "kb/s")
                        return args["{wlan0 down_mb}"]
                    end)

-- End Network Monitor }}
---


-- {{{ Start Wifi
wifiicon = wibox.widget.imagebox()
wifiicon:set_image(beautiful.widget_wifi)
--
wifi = wibox.widget.textbox()
vicious.register(wifi, vicious.widgets.wifi, "${ssid} Rate: ${rate}MB/s Link: ${link}%", 3, "wlp0s18f2u4u1")
-- End Wifi }}}
