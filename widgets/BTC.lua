--Bitcoin
--local t = timer({timeout = 300})
--t:add_signal("timeout", function()
--local f = io.popen("echo Bitcoin: $(/etc/wmii/bitcoin)", "r")
--local s = f:read('*a')
--f:close()
--BTC.text = s
--end)
--t:emit_signal("timeout")
--t:start()

--Return 

--{BTC:"s",}

-- {{{ Grab environment
local pairs = pairs
local tonumber = tonumber
local io = { popen = io.popen }
local math = { ceil = math.ceil }
local los = { getenv = os.getenv }
local setmetatable = setmetatable
local helpers = require("vicious.helpers")
local string = {
    gsub = string.gsub,
    match = string.match
}
-- }}}


-- OS: provides operating system information
-- vicious.widgets.os
local BTC = {}


-- {{{ BTC widget type
local function worker(format)
    local system = {
        ["BTC"]    = "N/A"
    }

    -- BTC Command.
    if system["BTC"] == "N/A" then
        local f = io.popen("echo Bitcoin: $(/etc/wmii/bitcoin)")
        local uname = f:read("*line")
        f:close()

        system["BTC"]

    return {system["BTC"]}
end
-- }}}

return setmetatable(BTC, { __call = function(_, ...) return worker(...) end })