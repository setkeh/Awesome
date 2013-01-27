--Bitcoin
BTC = widget({type="textbox"})
local t = timer({timeout = 300})
t:add_signal("timeout", function()
local f = io.popen("echo Bitcoin: $(/etc/wmii/bitcoin)", "r")
local s = f:read('*a')
f:close()
BTC.text = s
end)
t:emit_signal("timeout")
t:start()