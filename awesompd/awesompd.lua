---------------------------------------------------------------------------
-- @author Alexander Yakushev <yakushev.alex@gmail.com>
-- @copyright 2010-2011 Alexander Yakushev
-- @release v1.1.5
---------------------------------------------------------------------------

awesompd = {}

-- Function for checking icons and modules. Checks if a file exists,
-- and if it does, returns the path to file, nil otherwise.
function awesompd.try_load(file)
   if awful.util.file_readable(file) then
      return file
   end
end

-- Function for loading modules.
function awesompd.try_require(module)
   if awesompd.try_load(awful.util.getdir("config") .. 
                     "/awesompd/" .. module .. ".lua") then
      return require('awesompd/' .. module)
   else
      return require(module)
   end
end

awesompd.try_require("utf8")
awesompd.try_require("asyncshell")
awesompd.try_require("jamendo")
local beautiful = require('beautiful')
local naughty = naughty
local awful = awful
local format = string.format
local keygrabber = keygrabber

-- Debug stuff

local enable_dbg = true
local function dbg (...)
   if enable_dbg then
      print(...)
   end
end

local function tbl_pr(tbl,shift)
   if enable_dbg then
      local shift = shift or ""
      for k, v in pairs(tbl) do
         print(shift .. k .. ": " .. tostring(v))
         if type(v) == "table" then
            tbl_pr(v, shift .. "  ")
         end
      end
   end
end
      
-- Constants
awesompd.PLAYING = "Playing"
awesompd.PAUSED = "Paused"
awesompd.STOPPED = "MPD stopped"
awesompd.DISCONNECTED = "Disconnected"

awesompd.MOUSE_LEFT = 1
awesompd.MOUSE_MIDDLE = 2
awesompd.MOUSE_RIGHT = 3
awesompd.MOUSE_SCROLL_UP = 4
awesompd.MOUSE_SCROLL_DOWN = 5

awesompd.NOTIFY_VOLUME = 1
awesompd.NOTIFY_REPEAT = 2
awesompd.NOTIFY_RANDOM = 3
awesompd.NOTIFY_SINGLE = 4
awesompd.NOTIFY_CONSUME = 5
awesompd.FORMAT_MP3 = jamendo.FORMAT_MP3
awesompd.FORMAT_OGG = jamendo.FORMAT_OGG
awesompd.ESCAPE_SYMBOL_MAPPING = {}
awesompd.ESCAPE_SYMBOL_MAPPING["&"] = "&amp;"
-- Menus do not handle symbol escaping correctly, so they need their
-- own mapping.
awesompd.ESCAPE_MENU_SYMBOL_MAPPING = {}
awesompd.ESCAPE_MENU_SYMBOL_MAPPING["&"] = "'n'"

-- /// Current track variables and functions /// 

-- Returns a string for the given track to be displayed in the widget
-- and notification.
function awesompd.get_display_name(track)
   if track.display_name then
      return track.display_name
   elseif track.artist_name and track.track_name then
      return track.artist_name .. " - " .. track.name
   end
end

-- Returns a track display name, album name (if exists) and album
-- release year (if exists).
function awesompd.get_extended_info(track)
   local result = awesompd.get_display_name(track)
   if track.album_name then
      result = result .. "\n" .. track.album_name
   end
   if track.year then
      result = result .. "\n" .. track.year
   end
   return result
end

-- Returns true if the current status is either PLAYING or PAUSED
function awesompd:playing_or_paused()
   return self.status == awesompd.PLAYING 
      or self.status == awesompd.PAUSED
end

-- /// Helper functions ///

-- Just like awful.util.pread, but takes an argument how to read like
-- "*line" or "*all".
function awesompd.pread(com, mode)
   local f = io.popen(com, 'r')
   local result = nil
   if f then
      result = f:read(mode)
      f:close()
   end
   return result
end

-- Slightly modified function awful.util.table.join.
function awesompd.ajoin(buttons)
    local result = {}
    for i = 1, table.getn(buttons) do
        if buttons[i] then
            for k, v in pairs(buttons[i]) do
                if type(k) == "number" then
                    table.insert(result, v)
                else
                    result[k] = v
                end
            end
        end
    end
    return result
 end

-- Splits a given string with linebreaks into an array.
function awesompd.split(s)
   local l = { n = 0 }
   if s == "" then
      return l
   end
   s = s .. "\n"
   local f = function (s) 
                l.n = l.n + 1
		l[l.n] = s
	     end
   local p = "%s*(.-)%s*\n%s*"
   s = string.gsub(s,p,f)
   return l
end

-- Icons

function awesompd.load_icons(path)
   awesompd.ICONS = {}
   awesompd.ICONS.PLAY = awesompd.try_load(path .. "/play_icon.png")
   awesompd.ICONS.PAUSE = awesompd.try_load(path .. "/pause_icon.png")
   awesompd.ICONS.PLAY_PAUSE = awesompd.try_load(path .. "/play_pause_icon.png")
   awesompd.ICONS.STOP = awesompd.try_load(path .. "/stop_icon.png")
   awesompd.ICONS.NEXT = awesompd.try_load(path .. "/next_icon.png")
   awesompd.ICONS.PREV = awesompd.try_load(path .. "/prev_icon.png")
   awesompd.ICONS.CHECK = awesompd.try_load(path .. "/check_icon.png")
   awesompd.ICONS.RADIO = awesompd.try_load(path .. "/radio_icon.png")
   awesompd.ICONS.DEFAULT_ALBUM_COVER = 
      awesompd.try_load(path .. "/default_album_cover.png")
end

-- Function that returns a new awesompd object.
function awesompd:create()
-- Initialization
   local instance = {}
   setmetatable(instance,self)
   self.__index = self
   instance.current_server = 1
   instance.widget = widget({ type = "textbox" })
   instance.notification = nil
   instance.scroll_pos = 1
   instance.text = ""
   instance.to_notify = false
   instance.album_cover = nil
   instance.current_track = { }
   instance.recreate_menu = true
   instance.recreate_playback = true
   instance.recreate_list = true
   instance.recreate_servers = true
   instance.recreate_options = true
   instance.recreate_jamendo_formats = true
   instance.recreate_jamendo_order = true
   instance.recreate_jamendo_browse = true
   instance.current_number = 0
   instance.menu_shown = false

-- Default user options
   instance.servers = { { server = "localhost", port = 6600 } }
   instance.font = "Monospace"
   instance.scrolling = true
   instance.output_size = 30
   instance.update_interval = 10
   instance.path_to_icons = ""
   instance.ldecorator = " "
   instance.rdecorator = " "
   instance.jamendo_format = awesompd.FORMAT_MP3
   instance.show_album_cover = true
   instance.album_cover_size = 50
   instance.browser = "firefox"
   
-- Widget configuration
   instance.widget:add_signal("mouse::enter", function(c)
                                                 instance:notify_track()
                                              end)
   instance.widget:add_signal("mouse::leave", function(c)
                                                 instance:remove_hint()
                                              end)
   return instance
end

-- Registers timers for the widget
function awesompd:run()
   enable_dbg = self.debug_mode
   self.load_icons(self.path_to_icons)
   jamendo.set_current_format(self.jamendo_format)
   if self.album_cover_size > 100 then
      self.album_cover_size = 100
   end

   self:update_track()
   self:check_playlists()
   self.update_widget_timer = timer({ timeout = 1 })
   self.update_widget_timer:add_signal("timeout", function() 
                                                     self:update_widget() 
                                                  end)
   self.update_widget_timer:start()
   self.update_track_timer = timer({ timeout = self.update_interval })
   self.update_track_timer:add_signal("timeout", function() 
                                                    self:update_track() 
                                                 end)
   self.update_track_timer:start()
end

-- Function that registers buttons on the widget.
function awesompd:register_buttons(buttons)
   widget_buttons = {}
   self.global_bindings = {}
   for b=1,table.getn(buttons) do
      if type(buttons[b][1]) == "string" then
         mods = { buttons[b][1] }
      else
         mods = buttons[b][1]
      end
      if type(buttons[b][2]) == "number" then 
         -- This is a mousebinding, bind it to the widget
         table.insert(widget_buttons, 
                      awful.button(mods, buttons[b][2], buttons[b][3]))
      else 
         -- This is a global keybinding, remember it for later usage in append_global_keys
         table.insert(self.global_bindings, awful.key(mods, buttons[b][2], buttons[b][3]))
      end
   end
   self.widget:buttons(self.ajoin(widget_buttons))
end

-- Takes the current table with keybindings and adds widget's own
-- global keybindings that were specified in register_buttons.
-- If keytable is not specified, then adds bindings to default
-- globalkeys table. If specified, then adds bindings to keytable and
-- returns it.
function awesompd:append_global_keys(keytable)
   if keytable then
      for i = 1, table.getn(self.global_bindings) do
         keytable = awful.util.table.join(keytable, self.global_bindings[i])
      end
      return keytable
   else
      for i = 1, table.getn(self.global_bindings) do
         globalkeys = awful.util.table.join(globalkeys, self.global_bindings[i])
      end
   end
end

-- /// Group of mpc command functions ///

-- Takes a command to mpc and a hook that is provided with awesompd
-- instance and the result of command execution.
function awesompd:command(com,hook)
   local file = io.popen(self:mpcquery() .. com)
   if hook then
      hook(self,file)
   end
   file:close()
end

-- Takes a command to mpc and read mode and returns the result.
function awesompd:command_read(com, mode)
   mode = mode or "*line"
   self:command(com, function(_, f)
                        result = f:read(mode)
                     end)
   return result
end

function awesompd:command_playpause()
   return function()
             self:command("toggle",self.update_track)
          end
end

function awesompd:command_next_track()
   return function()
             self:command("next",self.update_track)
          end
end

function awesompd:command_prev_track()
   return function()
             self:command("seek 0")
             self:command("prev",self.update_track)
          end
end

function awesompd:command_stop()
   return function()
             self:command("stop",self.update_track)
          end
end

function awesompd:command_play_specific(n)
   return function()
             self:command("play " .. n,self.update_track)
          end
end

function awesompd:command_volume_up()
   return function()
             self:command("volume +5")
             self:update_track() -- Nasty! I should replace it with proper callback later.
             self:notify_state(self.NOTIFY_VOLUME)
          end
end

function awesompd:command_volume_down()
   return function()
             self:command("volume -5")
             self:update_track()
             self:notify_state(self.NOTIFY_VOLUME)
          end
end

function awesompd:command_load_playlist(name)
   return function()
             self:command("load " .. name, function() 
                                              self.recreate_menu = true 
                                           end)
          end
end

function awesompd:command_replace_playlist(name)
   return function()
             self:command("clear")
             self:command("load " .. name)
             self:command("play 1", self.update_track)
          end
end

function awesompd:command_clear_playlist()
   return function()
             self:command("clear", self.update_track)
             self.recreate_list = true
             self.recreate_menu = true
          end
end

function awesompd:command_open_in_browser(link)
   return function()
             if self.browser then
                awful.util.spawn(self.browser .. " '" .. link .. "'")
             end
          end
end

-- /// End of mpc command functions ///

-- /// Menu generation functions ///

function awesompd:command_show_menu()
   return 
   function()
      self:remove_hint()
      if self.recreate_menu then 
         local new_menu = {}
         if self.main_menu ~= nil then 
            self.main_menu:hide() 
         end 
         if self.status ~= awesompd.DISCONNECTED
         then 
            self:check_list() 
            self:check_playlists()
            local jamendo_menu = { { "Search by", 
                                     { { "Nothing (Top 100)", self:menu_jamendo_top() },
                                       { "Artist", self:menu_jamendo_search_by(jamendo.SEARCH_ARTIST) },
                                       { "Album", self:menu_jamendo_search_by(jamendo.SEARCH_ALBUM) },
                                       { "Tag", self:menu_jamendo_search_by(jamendo.SEARCH_TAG) }}} }
            local browse_menu = self:menu_jamendo_browse()
            if browse_menu then 
               table.insert(jamendo_menu, browse_menu)
            end
            table.insert(jamendo_menu, self:menu_jamendo_format())
            table.insert(jamendo_menu, self:menu_jamendo_order())

            new_menu = { { "Playback", self:menu_playback() },
                         { "Options", self:menu_options() },
                         { "List", self:menu_list() },
                         { "Playlists", self:menu_playlists() },
                         { "Jamendo", jamendo_menu } }
         end 
         table.insert(new_menu, { "Servers", self:menu_servers() }) 
         self.main_menu = awful.menu({ items = new_menu, width = 300 }) 
         self.recreate_menu = false 
      end 
      self.main_menu:toggle() 
   end 
end

-- Returns an icon for a checkbox menu item if it is checked, nil
-- otherwise.
function awesompd:menu_item_toggle(checked)
   return checked and self.ICONS.CHECK or nil
end

-- Returns an icon for a radiobox menu item if it is selected, nil
-- otherwise.
function awesompd:menu_item_radio(selected)
   return selected and self.ICONS.RADIO or nil
end

-- Returns the playback menu. Menu contains of:
-- Play\Pause - always
-- Previous - if the current track is not the first 
-- in the list and playback is not stopped
-- Next - if the current track is not the last 
-- in the list and playback is not stopped
-- Stop - if the playback is not stopped
-- Clear playlist - always
function awesompd:menu_playback()
   if self.recreate_playback then
      local new_menu = {}
      table.insert(new_menu, { "Play\\Pause", 
                               self:command_toggle(), 
                               self.ICONS.PLAY_PAUSE })
      if self:playing_or_paused() then
         if self.list_array and self.list_array[self.current_number-1] then
            table.insert(new_menu, 
                         { "Prev: " .. 
                           awesompd.protect_string(jamendo.replace_link(
                                                      self.list_array[self.current_number - 1]),
                                                   true),
                        self:command_prev_track(), self.ICONS.PREV })
         end
         if self.list_array and self.current_number ~= table.getn(self.list_array) then
            table.insert(new_menu, 
                         { "Next: " .. 
                           awesompd.protect_string(jamendo.replace_link(
                                                      self.list_array[self.current_number + 1]), 
                                                   true), 
                        self:command_next_track(), self.ICONS.NEXT })
         end
         table.insert(new_menu, { "Stop", self:command_stop(), self.ICONS.STOP })
         table.insert(new_menu, { "", nil })
      end
      table.insert(new_menu, { "Clear playlist", self:command_clear_playlist() })
      self.recreate_playback = false
      playback_menu = new_menu
   end
   return playback_menu
end

-- Returns the current playlist menu. Menu consists of all elements in the playlist.
function awesompd:menu_list()
   if self.recreate_list then
      local new_menu = {}
      if self.list_array then
         local total_count = table.getn(self.list_array) 
         local start_num = (self.current_number - 15 > 0) and self.current_number - 15 or 1
         local end_num = (self.current_number + 15 < total_count ) and self.current_number + 15 or total_count
         for i = start_num, end_num do
            table.insert(new_menu, { jamendo.replace_link(self.list_array[i]),
                                     self:command_play_specific(i),
                                     self.current_number == i and 
                                        (self.status == self.PLAYING and self.ICONS.PLAY or self.ICONS.PAUSE)
                                     or nil} )
         end
      end
      self.recreate_list = false
      self.list_menu = new_menu
   end
   return self.list_menu
end
	     
-- Returns the playlists menu. Menu consists of all files in the playlist folder.
function awesompd:menu_playlists()
   if self.recreate_playlists then
      local new_menu = {}
      if table.getn(self.playlists_array) > 0 then
	 for i = 1, table.getn(self.playlists_array) do
	    local submenu = {}
	    submenu[1] = { "Add to current", self:command_load_playlist(self.playlists_array[i]) }
	    submenu[2] = { "Replace current", self:command_replace_playlist(self.playlists_array[i]) }
	    new_menu[i] = { self.playlists_array[i], submenu }
	 end
	 table.insert(new_menu, {"", ""}) -- This is a separator
      end
      table.insert(new_menu, { "Refresh", function() self:check_playlists() end })
      self.recreate_playlists = false
      self.playlists_menu = new_menu
   end
   return self.playlists_menu
end

-- Returns the server menu. Menu consists of all servers specified by user during initialization.
function awesompd:menu_servers()
   if self.recreate_servers then
      local new_menu = {}
      for i = 1, table.getn(self.servers) do
	 table.insert(new_menu, {"Server: " .. self.servers[i].server .. 
				 ", port: " .. self.servers[i].port,
			      function() self:change_server(i) end,
                              self:menu_item_radio(i == self.current_server)})
      end
      self.servers_menu = new_menu
   end
   return self.servers_menu
end

-- Returns the options menu. Menu works like checkboxes for it's elements.
function awesompd:menu_options()
   if self.recreate_options then 
      local new_menu = { { "Repeat", self:menu_toggle_repeat(), 
                           self:menu_item_toggle(self.state_repeat == "on")},
                         { "Random", self:menu_toggle_random(), 
                           self:menu_item_toggle(self.state_random == "on")},
                         { "Single", self:menu_toggle_single(), 
                           self:menu_item_toggle(self.state_single == "on")},
                         { "Consume", self:menu_toggle_consume(), 
                           self:menu_item_toggle(self.state_consume == "on")} }
      self.options_menu = new_menu
      self.recreate_options = false      
   end
   return self.options_menu
end

function awesompd:menu_toggle_random()
   return function()
             self:command("random",self.update_track)
             self:notify_state(self.NOTIFY_RANDOM)
          end
end

function awesompd:menu_toggle_repeat()
   return function()
             self:command("repeat",self.update_track)
             self:notify_state(self.NOTIFY_REPEAT)
          end
end

function awesompd:menu_toggle_single()
   return function()
             self:command("single",self.update_track)
             self:notify_state(self.NOTIFY_SINGLE)
          end
end

function awesompd:menu_toggle_consume()
   return function()
             self:command("consume",self.update_track)
             self:notify_state(self.NOTIFY_CONSUME)
          end
end

function awesompd:menu_jamendo_top()
   return 
   function ()
      local track_table = jamendo.return_track_table()
      if not track_table then
         self:add_hint("Can't connect to Jamendo server", "Please check your network connection")
      else
         self:add_jamendo_tracks(track_table)
         self:add_hint("Jamendo Top 100 by " .. 
                       jamendo.current_request_table.params.order.short_display,
                    format("Added %s tracks to the playlist",
                           table.getn(track_table)))
      end
   end
end

function awesompd:menu_jamendo_format()
   if self.recreate_jamendo_formats then
      local setformat =
         function(format)
            return function()
                      jamendo.set_current_format(format)
                      self.recreate_menu = true
                      self.recreate_jamendo_formats = true
                   end
         end

      local iscurr = 
         function(f)
            return jamendo.current_request_table.params.streamencoding.value
               == f.value
         end

      local new_menu = {}
      for _, format in pairs(jamendo.ALL_FORMATS) do
         table.insert(new_menu, { format.display, setformat(format),
                                  self:menu_item_radio(iscurr(format))})
      end
      self.recreate_jamendo_formats = false
      self.jamendo_formats_menu = { 
         "Format: " ..
            jamendo.current_request_table.params.streamencoding.short_display,
         new_menu }
   end
   return self.jamendo_formats_menu
end

function awesompd:menu_jamendo_browse()
   if self.recreate_jamendo_browse and self.browser 
      and self.current_track.unique_name then
      local track = jamendo.get_track_by_link(self.current_track.unique_name)
      local new_menu
      if track then
         local artist_link = 
            "http://www.jamendo.com/artist/" .. track.artist_link_name
         local album_link =
            "http://www.jamendo.com/album/" .. track.album_id
         new_menu = { { "Artist's page" , 
                        self:command_open_in_browser(artist_link) },
                      { "Album's page" ,
                        self:command_open_in_browser(album_link) } }
         self.jamendo_browse_menu = { "Browse on Jamendo", new_menu }
      else
         self.jamendo_browse_menu = nil
      end
   end
   return self.jamendo_browse_menu
end

function awesompd:menu_jamendo_order()
   if self.recreate_jamendo_order then
      local setorder =
         function(order)
            return function()
                      jamendo.set_current_order(order)
                      self.recreate_menu = true
                      self.recreate_jamendo_order = true
                   end
         end

      local iscurr = 
         function(o)
            return jamendo.current_request_table.params.order.value
               == o.value
         end

      local new_menu = {}
      for _, order in pairs(jamendo.ALL_ORDERS) do
         table.insert(new_menu, { order.display, setorder(order),
                                  self:menu_item_radio(iscurr(order))})
      end
      self.recreate_jamendo_order = false
      self.jamendo_order_menu = { 
         "Order: " ..
            jamendo.current_request_table.params.order.short_display,
         new_menu }
   end
   return self.jamendo_order_menu
end

function awesompd:menu_jamendo_search_by(what)
   return function()
             local callback = 
                function(s)
                   local result = jamendo.search_by(what, s)
                   if result then
                      local track_count = table.getn(result.tracks)
                      self:add_jamendo_tracks(result.tracks)
                      self:add_hint(format("%s \"%s\" was found",
                                           what.display,
                                           result.search_res.name),
                                    format("Added %s tracks to the playlist",
                                           track_count))
                   else
                      self:add_hint("Search failed",
                                    format("%s \"%s\" was not found",
                                           what.display, s))
                   end
                end
             self:display_inputbox("Search music on Jamendo",
                                   what.display, callback)
          end
end

-- Checks if the current playlist has changed after the last check.
function awesompd:check_list()
   local bus = io.popen(self:mpcquery() .. "playlist")
   local info = bus:read("*all")
   bus:close()
   if info ~= self.list_line then
      self.list_line = info
      if string.len(info) > 0 then
	 self.list_array = self.split(string.sub(info,1,string.len(info)))
      else
	 self.list_array = {}
      end
      self.recreate_menu = true
      self.recreate_list = true
   end
end

-- Checks if the collection of playlists changed after the last check.
function awesompd:check_playlists()
   local bus = io.popen(self:mpcquery() .. "lsplaylists")
   local info = bus:read("*all")
   bus:close()
   if info ~= self.playlists_line then
      self.playlists_line = info
      if string.len(info) > 0 then
	 self.playlists_array = self.split(info)
      else
	 self.playlists_array = {}
      end
      self.recreate_menu = true
      self.recreate_playlists = true
   end
end

-- Changes the current server to the specified one.
function awesompd:change_server(server_number)
   self.current_server = server_number
   self:remove_hint()
   self.recreate_menu = true
   self.recreate_playback = true
   self.recreate_list = true
   self.recreate_playlists = true
   self.recreate_servers = true
   self:update_track()
end

function awesompd:add_jamendo_tracks(track_table)
   for i = 1,table.getn(track_table) do
      self:command("add '" .. string.gsub(track_table[i].stream, '\\/', '/') .. "'")
   end
   self.recreate_menu = true
   self.recreate_list = true
end

-- /// End of menu generation functions ///

function awesompd:add_hint(hint_title, hint_text, hint_image)
   self:remove_hint()
   self.notification = naughty.notify({ title      =  hint_title
					, text       = awesompd.protect_string(hint_text)
					, timeout    = 5
					, position   = "top_right"
                                        , icon       = hint_image
                                        , icon_size  = self.album_cover_size
                                     })
end

function awesompd:remove_hint()
   if self.notification ~= nil then
      naughty.destroy(self.notification)
      self.notification = nil
   end
end

function awesompd:notify_track()
   if self:playing_or_paused() then
      local caption = self.status_text
      local nf_text = self.get_display_name(self.current_track)
      local al_cover = nil
      if self.show_album_cover then
         nf_text = self.get_extended_info(self.current_track)
         al_cover = self.current_track.album_cover
      end
      self:add_hint(caption, nf_text, al_cover)
   end
end

function awesompd:notify_state(state_changed)
   state_array = { "Volume: " .. self.state_volume ,
		   "Repeat: " .. self.state_repeat ,
		   "Random: " .. self.state_random ,
		   "Single: " .. self.state_single ,
		   "Consume: " .. self.state_consume }
   state_header = state_array[state_changed]
   table.remove(state_array,state_changed)
   full_state = state_array[1]
   for i = 2, table.getn(state_array) do
      full_state = full_state .. "\n" .. state_array[i]
   end
   self:add_hint(state_header, full_state)
end

function awesompd:wrap_output(text)
   return format('<span font="%s">%s%s%s</span>', 
                 self.font, self.ldecorator, 
                 awesompd.protect_string(text), self.rdecorator)
end

function awesompd:mpcquery()
   return "mpc -h " .. self.servers[self.current_server].server .. 
      " -p " .. self.servers[self.current_server].port .. " "
end

-- This function actually sets the text on the widget.
function awesompd:set_text(text)
   self.widget.text = self:wrap_output(text)
end

function awesompd.find_pattern(text, pattern, start)
   return utf8sub(text, string.find(text, pattern, start))
end

-- Scroll the given text by the current number of symbols.
function awesompd:scroll_text(text)
   local result = text
   if self.scrolling then
      if self.output_size < utf8len(text) then
         text = text .. " - "
         if self.scroll_pos + self.output_size - 1 > utf8len(text) then
            result = utf8sub(text, self.scroll_pos)
            result = result .. utf8sub(text, 1, self.scroll_pos + self.output_size - 1 - utf8len(text))
            self.scroll_pos = self.scroll_pos + 1
            if self.scroll_pos > utf8len(text) then
               self.scroll_pos = 1
            end
         else
            result = utf8sub(text, self.scroll_pos, self.scroll_pos + self.output_size - 1)
            self.scroll_pos = self.scroll_pos + 1
         end
      end
   else
      if self.output_size < utf8len(text) then
         result = utf8sub(text, 1, self.output_size)
      end
   end
   return result
end

-- This function is called every second.
function awesompd:update_widget()
   self:set_text(self:scroll_text(self.text))
   self:check_notify()
end

-- This function is called by update_track each time content of
-- the widget must be changed.
function awesompd:update_widget_text()
   if self:playing_or_paused() then
      self.text = self.get_display_name(self.current_track)
   else
      self.text = self.status
   end
end

-- Checks if notification should be shown and shows if positive.
function awesompd:check_notify()
   if self.to_notify then
      self:notify_track()
      self.to_notify = false
   end
end

function awesompd:notify_connect()
   self:add_hint("Connected", "Connection established to " .. self.servers[self.current_server].server ..
		 " on port " .. self.servers[self.current_server].port)
end

function awesompd:notify_disconnect()
   self:add_hint("Disconnected", "Cannot connect to " .. self.servers[self.current_server].server ..
		 " on port " .. self.servers[self.current_server].port)
end

function awesompd:update_track(file)
   local file_exists = (file ~= nil)
   if not file_exists then
      file = io.popen(self:mpcquery())
   end
   local track_line = file:read("*line")
   local status_line = file:read("*line")
   local options_line = file:read("*line")
   if not file_exists then
      file:close()
   end

   if not track_line or string.len(track_line) == 0 then
      if self.status ~= awesompd.DISCONNECTED then
	 self:notify_disconnect()
	 self.recreate_menu = true
         self.status = awesompd.DISCONNECTED
         self.current_track = { }
         self:update_widget_text()
      end
   else
      if self.status == awesompd.DISCONNECTED then
	 self:notify_connect()
	 self.recreate_menu = true
         self:update_widget_text()
      end
      if string.find(track_line,"volume:") or string.find(track_line,"Updating DB") then
	 if self.status ~= awesompd.STOPPED then
            self.status = awesompd.STOPPED
	    self.current_number = 0
	    self.recreate_menu = true
	    self.recreate_playback = true
	    self.recreate_list = true
            self.album_cover = nil
            self.current_track = { }
            self:update_widget_text()
	 end
         self:update_state(track_line)
      else
         self:update_state(options_line)
         local _, _, new_file, new_album = 
            string.find(self:command_read('current -f "%file%-<>-%album%"', "*line"), "(.+)%-<>%-(.*)")
	 if new_file ~= self.current_track.unique_name then
            self.current_track = jamendo.get_track_by_link(new_file)
            if not self.current_track then
               self.current_track = { display_name = track_line,
                                      album_name = new_album }
            end
            self.current_track.unique_name = new_file
            if self.show_album_cover then
               self.current_track.album_cover = self:get_cover(new_file)
            end
	    self.to_notify = true
	    self.recreate_menu = true
	    self.recreate_playback = true
	    self.recreate_list = true
	    self.current_number = tonumber(self.find_pattern(status_line,"%d+"))
            self:update_widget_text()

            -- If the track is not the last, asynchronously download
            -- the cover for the next track.
            if self.list_array and self.current_number ~= table.getn(self.list_array) then
               -- Get the link (in case it is Jamendo stream) to the next track
               local next_track = 
                  self:command_read('playlist -f "%file%" | head -' .. 
                                    self.current_number + 1 .. ' | tail -1', "*line")
               jamendo.try_get_cover_async(next_track)
            end
	 end
	 local tmp_pst = string.find(status_line,"%d+%:%d+%/")
	 local progress = self.find_pattern(status_line,"%#%d+/%d+") .. " " .. string.sub(status_line,tmp_pst)
         local new_status = awesompd.PLAYING
	 if string.find(status_line,"paused") then
            new_status = awesompd.PAUSED
	 end
	 if new_status ~= self.status then
	    self.to_notify = true
	    self.recreate_list = true
            self.status = new_status
            self:update_widget_text()
	 end
	 self.status_text = self.status .. " " .. progress
      end
   end
end

function awesompd:update_state(state_string)
   self.state_volume = self.find_pattern(state_string,"%d+%% ")
   if string.find(state_string,"repeat: on") then
      self.state_repeat = self:check_set_state(self.state_repeat, "on")
   else
      self.state_repeat = self:check_set_state(self.state_repeat, "off")
   end
   if string.find(state_string,"random: on") then
      self.state_random = self:check_set_state(self.state_random, "on")
   else
      self.state_random = self:check_set_state(self.state_random, "off")
   end
   if string.find(state_string,"single: on") then
      self.state_single = self:check_set_state(self.state_single, "on")
   else
      self.state_single = self:check_set_state(self.state_single, "off")
   end
   if string.find(state_string,"consume: on") then
      self.state_consume = self:check_set_state(self.state_consume, "on")
   else
      self.state_consume = self:check_set_state(self.state_consume, "off")
   end
end

function awesompd:check_set_state(statevar, val)
   if statevar ~= val then
      self.recreate_menu = true
      self.recreate_options = true
   end
   return val
end

function awesompd:run_prompt(welcome,hook)
   awful.prompt.run({ prompt = welcome },
		    self.promptbox[mouse.screen].widget,
		    hook)
end

-- Replaces control characters with escaped ones.
-- for_menu - defines if the special escable table for menus should be
-- used.
function awesompd.protect_string(str, for_menu)
   if for_menu then
      return utf8replace(str, awesompd.ESCAPE_MENU_SYMBOL_MAPPING)
   else
      return utf8replace(str, awesompd.ESCAPE_SYMBOL_MAPPING)
   end
end

-- Displays an inputbox on the screen (looks like naughty with prompt).
-- title_text - bold text on the first line
-- prompt_text - preceding text on the second line
-- hook - function that will be called with input data
-- Use it like this:
-- self:display_inputbox("Search music on Jamendo", "Artist", print)
function awesompd:display_inputbox(title_text, prompt_text, hook)
   if self.inputbox then -- Inputbox already exists, replace it
      keygrabber.stop()
      self.inputbox.screen = nil
      self.inputbox = nil
   end
   local width = 200
   local height = 30
   local border_color = beautiful.bg_focus or '#535d6c'
   local margin = 5
   local wbox = wibox({ name = "awmpd_ibox", height = height , width = width, 
                        border_color = border_color, border_width = 1 })
   self.inputbox = wbox
   local ws = screen[mouse.screen].workarea

   wbox:geometry({ x = ws.width - width - 5, y = 25 })
   wbox.screen = mouse.screen
   wbox.ontop = true

   local exe_callback = function(s)
                           hook(s)
                           wbox.screen = nil
                           self.inputbox = nil
                        end
   local done_callback = function()
                            wbox.screen = nil
                            self.inputbox = nil
                         end
   local wprompt = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
   local wtbox = widget({ type = "textbox" })
   wtbox:margin({ right = margin, left = margin, bottom = margin, top = margin })
   wtbox.text = "<b>" .. title_text .. "</b>"
   wbox.widgets = { wtbox, wprompt, layout = awful.widget.layout.vertical.flex }
   awful.prompt.run( { prompt = " " .. prompt_text .. ": " }, wprompt.widget, 
                     exe_callback, nil, nil, nil, done_callback)
end

-- Gets the cover for the given track. First looks in the Jamendo
-- cache. If the track is not a Jamendo stream, looks in local
-- folders. If there is no cover art either returns the default album
-- cover.
function awesompd:get_cover(track)
   return jamendo.try_get_cover(track) or 
   self:try_get_local_cover() or self.ICONS.DEFAULT_ALBUM_COVER
end

-- Tries to find an album cover for the track that is currently
-- playing.
function awesompd:try_get_local_cover()
   if self.mpd_config then
      local result
      -- First find the music directory in MPD configuration file
      local _, _, music_folder = string.find(
         self.pread('cat ' .. self.mpd_config .. ' | grep -v "#" | grep music_directory', "*line"),
         'music_directory%s+"(.+)"')
      music_folder = music_folder .. "/"
      
      -- If the music_folder is specified with ~ at the beginning,
      -- replace it with user home directory
      if string.sub(music_folder, 1, 1) == "~" then
         local user_folder = self.pread("echo ~", "*line")
         music_folder = user_folder .. string.sub(music_folder, 2)
      end

      -- Get the path to the file currently playing.
      local current_file = self:command_read('current -f "%file%"')
      local _, _, current_file_folder = string.find(current_file, '(.+%/).*')

      -- Check if the current file is not some kind of http stream or
      -- Spotify track (like spotify:track:5r65GeuIoebfJB5sLcuPoC)
      if not current_file_folder or string.match(current_file, "%w+://") then
          return -- Let the default image to be the cover
      end

      local folder = music_folder .. current_file_folder
      
      -- Get all images in the folder. Also escape occasional single
      -- quotes in folder name.
      local request = format("ls '%s' | grep -P '\.jpg\|\.png\|\.gif|\.jpeg'",
                             string.gsub(folder, "'", "'\\''"))

      local covers = self.pread(request, "*all")
      local covers_table = self.split(covers)
      
      if covers_table.n > 0 then
         result = folder .. covers_table[1]
         if covers_table.n > 1 then
            -- Searching for front cover with grep because Lua regular
            -- expressions suck:[
            local front_cover = 
               self.pread('echo "' .. covers .. 
                          '" | grep -i "cover\|front\|folder\|albumart" | head -n 1', "*line")
            if front_cover then
               result = folder .. front_cover
            end
         end
      end
      return result
   end   
end

-- /// Deprecated, left for some backward compatibility in
-- configuration ///

function awesompd:command_toggle()
   return self:command_playpause()
end
