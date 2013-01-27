-- @author Peter J. Kranz (Absurd-Mind, peter@myref.net)
-- Any questions, criticism or praise just drop me an email

-- {{{ init environment
local M = {}
local capi = {
    mouse = mouse,
    screen = screen
}
units = {"KB", "MB", "GB", "TB", "PB", "EB"}
local usage = {}
-- }}}

-- {{{ local functions
-- {{{ Unit formatter
-- formats a value to the corresponding unit
local function uformat(value)
    local ret = tonumber(value)
    for i, u in pairs(units) do
        if ret < 1024 then
            return string.format("%.1f" .. u, ret)
        end
        ret = ret / 1024;
    end
    return "N/A"
end
-- }}}

-- {{{ getData
-- gets the required data from df
local function getData(onlyLocal)
    -- Fallback to listing local filesystems
    local warg = ""
    if onlyLocal == true then
        warg = "-l"
    end

    local fs_info = {} -- Get data from df
    local f = io.popen("LC_ALL=C df -kP " .. warg)

    for line in f:lines() do -- Match: (size) (used)(avail)(use%) (mount)
        local s     = string.match(line, "^.-[%s]([%d]+)")
        local u,a,p = string.match(line, "([%d]+)[%D]+([%d]+)[%D]+([%d]+)%%")
        local m     = string.match(line, "%%[%s]([%p%w]+)")

        if u and m then -- Handle 1st line and broken regexp
            fs_info[m] = {}
            fs_info[m]["size"] = s
            fs_info[m]["used"] = u
            fs_info[m]["avail"] = a
            fs_info[m]["used_p"]  = tonumber(p)
            fs_info[m]["avail_p"] = 100 - tonumber(p)
        end
    end
    f:close()
    return fs_info
end
-- }}}

-- {{{ display
-- formats the lines for the notify
local function display(orange, red, onlyLocal)
    data = getData(onlyLocal)
    local lines = "<u>diskusage:</u>\n"

    local longest = 0
    local longestSize = 0;
    local longestUsed = 0;
    for i, m in pairs(data) do
        if i:len() > longest then
            longest = i:len()
        end

        local s = uformat(m["size"])
        if s:len() > longestSize then
            longestSize = s:len()
        end

        local u = uformat(m["used"])
        if u:len() > longestUsed then
            longestUsed = u:len()
        end
    end
    longest = longest + 8

    for i, m in pairs(data) do
        local u = uformat(m["used"])
        local s = uformat(m["size"])

        if m["used_p"] >= red then 
            lines = lines .. "<span color='darkred'>"
        elseif m["used_p"] >= orange then
            lines = lines .. "<span color='orange'>"
        else
            lines = lines .. "<span color='darkgreen'>"
        end

        lines = lines
                .. "\n"
                .. i
                .. string.rep(" ", longest + longestSize - i:len() - u:len())
                .. u
                .. " / "
                .. s
                .. string.rep(" ", longestUsed - s:len())
                .. " ("
                .. m["used_p"]
                .. "%)</span>"
    end

    return lines
end
-- }}}
-- }}}

-- {{{ global functions
function M.addToWidget(mywidget, orange, red, onlyLocal)

  mywidget:add_signal('mouse::enter', function ()
        
        usage = naughty.notify({
                text = string.format('<span font_desc="%s">%s</span>', "monospace", display(orange, red, onlyLocal)),
                timeout = 0,
                hover_timeout = 0.5,
                screen = capi.mouse.screen
        })
  
  end)
  mywidget:add_signal('mouse::leave', function () naughty.destroy(usage) end)
end
-- }}}

return M