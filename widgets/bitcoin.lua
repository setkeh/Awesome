-- {{{ init environment
local wakka = {}
local capi = {
    mouse = mouse,
    screen = screen
}

-- {{{ display
-- formats the lines for the notify
local function display()
    local lines = "<u>Bitcoin:</u>\n"
    local tick  = "<u>Ask:</u>\n"
    local f = io.popen("bitcoind getbalance", "r")
    local t = io.popen("curl -q -s https://api.bitcoinaverage.com/ticker/global/AUD/ask", "r")
    local s = f:read('*all')
    local g = t:read('*all')
    line = lines .. "\n" .. s .. "\n" 
    ticker = tick .. "\n" .. g .. "\n"
    f:close()
    t:close()
--  return line, ticker
    return string.format('%s%s',line, ticker)
end


function wakka.addToWidget(mywidget)
    mywidget:add_signal('mouse::enter', function ()
	run_display = display()
        usage = naughty.notify({
        text = string.format('<span font_desc="%s">%s</span>', "monospace", run_display),
        timeout = 0,
        hover_timeout = 0.5,
        screen = capi.mouse.screen
        })
    end)
    mywidget:add_signal('mouse::leave', function () naughty.destroy(usage) end)
end

return wakka
