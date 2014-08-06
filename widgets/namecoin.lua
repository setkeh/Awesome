-- {{{ init environment
local wakka = {}
local capi = {
    mouse = mouse,
    screen = screen
}

-- {{{ display
-- formats the lines for the notify
local function display()
    local lines = "<u>Namecoin:</u>\n"
    local f = io.popen("namecoind getbalance", "r")
    local s = f:read('*all')
    line = lines .. "\n" .. s .. "\n"
    f:close()
    return line
end
-- }}}
-- }}}

function wakka.addToWidget(mywidget)
    mywidget:add_signal('mouse::enter', function ()
        usage = naughty.notify({
        text = string.format('<span font_desc="%s">%s</span>', "monospace", display()),
        timeout = 0,
        hover_timeout = 0.5,
        screen = capi.mouse.screen
        })
    end)
    mywidget:add_signal('mouse::leave', function () naughty.destroy(usage) end)
end

return wakka
