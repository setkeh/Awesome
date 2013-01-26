---------------------------
-- Default SETKEH theme --
---------------------------

local awful = require("awful")

--Configure home path so you dont have too
home_path  = os.getenv('HOME') .. '/'

theme = {}
theme.wallpaper = awful.util.getdir("config") .. "/themes/default/bg.png"
theme.font          = "terminus 8"

theme.bg_normal     = "#222222"
theme.bg_focus      = "#535d6c"
theme.bg_urgent     = "#ff0000"
theme.bg_minimize   = "#444444"
theme.bg_tooltip    = "#d6d6d6"
theme.bg_em         = "#5a5a5a"
theme.bg_systray    = theme.bg_normal

theme.fg_normal     = "#aaaaaa"
theme.fg_focus      = "#ffffff"
theme.fg_urgent     = "#ffffff"
theme.fg_minimize   = "#ffffff"
theme.fg_tooltip    = "#1a1a1a"
theme.fg_em         = "#d6d6d6"

theme.border_width  = "1"
theme.border_normal = "#000000"
theme.border_focus  = "#535d6c"
theme.border_marked = "#91231c"
theme.fg_widget_value = "#aaaaaa"
theme.fg_widget_clock = "#aaaaaa"
theme.fg_widget_value_important = "#aaaaaa"
theme.fg_widget = "#908884"
theme.fg_center_widget = "#636363"
theme.fg_end_widget = "#1a1a1a"
theme.bg_widget = "#2a2a2a"
theme.border_widget = "#3F3F3F"

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- mouse_finder_[color|timeout|animate_timeout|radius|factor]
-- Example:
--theme.taglist_bg_focus = "#ff0000"

-- Display the taglist squares
theme.taglist_squares_sel   = home_path .. '.config/awesome/themes/default/taglist/squarefw.png'
theme.taglist_squares_unsel = home_path .. '.config/awesome/themes/default/taglist/squarew.png'

theme.tasklist_floating_icon = home_path .. '.config/awesome/themes/default/tasklist/floatingw.png'

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = home_path .. '.config/awesome/themes/default/submenu.png'
theme.menu_height = "15"
theme.menu_width  = "100"

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

-- Define the image to load
theme.titlebar_close_button_normal = home_path .. '.config/awesome/themes/default/titlebar/close_normal.png'
theme.titlebar_close_button_focus  = home_path .. '.config/awesome/themes/default/titlebar/close_focus.png'

theme.titlebar_ontop_button_normal_inactive = home_path .. '.config/awesome/themes/default/titlebar/ontop_normal_inactive.png'
theme.titlebar_ontop_button_focus_inactive  = home_path .. '.config/awesome/themes/default/titlebar/ontop_focus_inactive.png'
theme.titlebar_ontop_button_normal_active = home_path .. '/home/setkeh/.config/awesome/themes/default/titlebar/ontop_normal_active.png'
theme.titlebar_ontop_button_focus_active  = home_path .. '.config/awesome/themes/default/titlebar/ontop_focus_active.png'

theme.titlebar_sticky_button_normal_inactive = home_path .. '.config/awesome/themes/default/titlebar/sticky_normal_inactive.png'
theme.titlebar_sticky_button_focus_inactive  = home_path .. '.config/awesome/themes/default/titlebar/sticky_focus_inactive.png'
theme.titlebar_sticky_button_normal_active = home_path .. '.config/awesome/themes/default/titlebar/sticky_normal_active.png'
theme.titlebar_sticky_button_focus_active  = home_path .. '.config/awesome/themes/default/titlebar/sticky_focus_active.png'

theme.titlebar_floating_button_normal_inactive = home_path .. '.config/awesome/themes/default/titlebar/floating_normal_inactive.png'
theme.titlebar_floating_button_focus_inactive  = home_path .. '.config/awesome/themes/default/titlebar/floating_focus_inactive.png'
theme.titlebar_floating_button_normal_active = home_path .. '.config/awesome/themes/default/titlebar/floating_normal_active.png'
theme.titlebar_floating_button_focus_active  = home_path .. '.config/awesome/themes/default/titlebar/floating_focus_active.png'

theme.titlebar_maximized_button_normal_inactive = home_path .. '.config/awesome/themes/default/titlebar/maximized_normal_inactive.png'
theme.titlebar_maximized_button_focus_inactive  = home_path .. '.config/awesome/themes/default/titlebar/maximized_focus_inactive.png'
theme.titlebar_maximized_button_normal_active = home_path .. '.config/awesome/themes/default/titlebar/maximized_normal_active.png'
theme.titlebar_maximized_button_focus_active  = home_path .. '.config/awesome/themes/default/titlebar/maximized_focus_active.png'

-- You can use your own layout icons like this:
theme.layout_fairh = home_path .. '.config/awesome/themes/default/layouts/fairhw.png'
theme.layout_fairv = home_path .. '.config/awesome/themes/default/layouts/fairvw.png'
theme.layout_floating  = home_path .. '.config/awesome/themes/default/layouts/floatingw.png'
theme.layout_magnifier = home_path .. '.config/awesome/themes/default/layouts/magnifierw.png'
theme.layout_max = home_path .. '.config/awesome/themes/default/layouts/maxw.png'
theme.layout_fullscreen = home_path .. '.config/awesome/themes/default/layouts/fullscreenw.png'
theme.layout_tilebottom = home_path .. '.config/awesome/themes/default/layouts/tilebottomw.png'
theme.layout_tileleft   = home_path .. '.config/awesome/themes/default/layouts/tileleftw.png'
theme.layout_tile = home_path .. '.config/awesome/themes/default/layouts/tilew.png'
theme.layout_tiletop = home_path .. '.config/awesome/themes/default/layouts/tiletopw.png'
theme.layout_spiral  = home_path .. '.config/awesome/themes/default/layouts/spiralw.png'
theme.layout_dwindle = home_path .. '.config/awesome/themes/default/layouts/dwindlew.png'

theme.awesome_icon = home_path .. '.config/awesome/themes/default/icon/awesome16.png'
theme.arch_icon = home_path .. '.config/awesome/themes/default/icon/Arch.png'

-- {{{ Widgets
theme.widget_disk = awful.util.getdir("config") .. "/themes/default/widgets/disk.png"
theme.widget_cpu = awful.util.getdir("config") .. "/themes/default/widgets/cpu.png"
theme.widget_ac = awful.util.getdir("config") .. "/themes/default/widgets/ac.png"
theme.widget_acblink = awful.util.getdir("config") .. "/themes/default/widgets/acblink.png"
theme.widget_blank = awful.util.getdir("config") .. "/themes/default/widgets/blank.png"
theme.widget_batfull = awful.util.getdir("config") .. "/themes/default/widgets/batfull.png"
theme.widget_batmed = awful.util.getdir("config") .. "/themes/default/widgets/batmed.png"
theme.widget_batlow = awful.util.getdir("config") .. "/themes/default/widgets/batlow.png"
theme.widget_batempty = awful.util.getdir("config") .. "/themes/default/widgets/batempty.png"
theme.widget_vol = awful.util.getdir("config") .. "/themes/default/widgets/vol.png"
theme.widget_mute = awful.util.getdir("config") .. "/themes/default/widgets/mute.png"
theme.widget_pac = awful.util.getdir("config") .. "/themes/default/widgets/pac.png"
theme.widget_pacnew = awful.util.getdir("config") .. "/themes/default/widgets/pacnew.png"
theme.widget_mail = awful.util.getdir("config") .. "/themes/default/widgets/mail.png"
theme.widget_mailnew = awful.util.getdir("config") .. "/themes/default/widgets/mailnew.png"
theme.widget_temp = awful.util.getdir("config") .. "/themes/default/widgets/temp.png"
theme.widget_tempwarn = awful.util.getdir("config") .. "/themes/default/widgets/tempwarm.png"
theme.widget_temphot = awful.util.getdir("config") .. "/themes/default/widgets/temphot.png"
theme.widget_wifi = awful.util.getdir("config") .. "/themes/default/widgets/wifi.png"
theme.widget_nowifi = awful.util.getdir("config") .. "/themes/default/widgets/nowifi.png"
theme.widget_mpd = awful.util.getdir("config") .. "/themes/default/widgets/mpd.png"
theme.widget_play = awful.util.getdir("config") .. "/themes/default/widgets/play.png"
theme.widget_pause = awful.util.getdir("config") .. "/themes/default/widgets/pause.png"
theme.widget_ram = awful.util.getdir("config") .. "/themes/default/widgets/ram.png"
theme.widget_mem = awful.util.getdir("config") .. "/themes/default/tp/ram.png"
theme.widget_swap = awful.util.getdir("config") .. "/themes/default/tp/swap.png"
theme.widget_fs = awful.util.getdir("config") .. "/themes/default/tp/fs_01.png"
theme.widget_fs2 = awful.util.getdir("config") .. "/themes/default/tp/fs_02.png"
theme.widget_up = awful.util.getdir("config") .. "/themes/default/tp/up.png"
theme.widget_down = awful.util.getdir("config") .. "/themes/default/tp/down.png"
-- }}}

return theme
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
