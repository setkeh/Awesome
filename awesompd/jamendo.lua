---------------------------------------------------------------------------
-- @author Alexander Yakushev <yakushev.alex@gmail.com>
-- @copyright 2011 Alexander Yakushev
-- @release v1.1.5
---------------------------------------------------------------------------

-- Grab environment
local os = os
local awful = awful
local string = string
local table = table
local io = io
local pairs = pairs
local type = type
local assert = assert
local print = print
local tonumber = tonumber
local math = math
local tostring = tostring
local asyncshell = asyncshell

module('jamendo')

-- UTILITY STUFF
-- Checks whether file specified by filename exists.
local function file_exists(filename, mode)
   mode = mode or 'r'
   f = io.open(filename, mode)
   if f then
      f:close()
      return true
   else
      return false
   end
end

-- Global variables
FORMAT_MP3 = { display = "MP3 (128k)", 
               short_display = "MP3", 
               value = "mp31" }
FORMAT_OGG = { display = "Ogg Vorbis (q4)", 
               short_display = "Ogg", 
               value = "ogg2" }
ORDER_RATINGDAILY = { display = "Daily rating", 
                      short_display = "daily rating", 
                      value = "ratingday_desc" }
ORDER_RATINGWEEKLY = { display = "Weekly rating", 
                      short_display = "weekly rating", 
                      value = "ratingweek_desc" }
ORDER_RATINGTOTAL = { display = "All time rating", 
                      short_display = "all time rating", 
                      value = "ratingtotal_desc" }
ORDER_RANDOM = { display = "Random", 
                 short_display = "random", 
                 value = "random_desc" }
ORDER_RELEVANCE = { display = "None (consecutive)", 
                    short_display = "none",
                    value = "searchweight_desc" }
SEARCH_ARTIST = { display = "Artist",
                  unit = "artist",
                  value = "artist_id" }
SEARCH_ALBUM = { display = "Album",
                 unit = "album",
                 value = "album_id" }
SEARCH_TAG = { display = "Tag",
               unit = "tag",
               value = "tag_id" }
ALL_FORMATS = { FORMAT_MP3, FORMAT_OGG }
ALL_ORDERS = { ORDER_RELEVANCE, ORDER_RANDOM, ORDER_RATINGDAILY, 
               ORDER_RATINGWEEKLY, ORDER_RATINGTOTAL }

current_request_table = { unit = "track", 
                          fields = {"id", "artist_url", "artist_name", "name", 
                                    "stream", "album_image", "album_name" },
                          joins = { "track_album", "album_artist" },
                          params = { streamencoding = FORMAT_MP3, 
                                     order = ORDER_RATINGWEEKLY,
                                     n = 100 }}

-- Local variables
local jamendo_list = {}
local cache_file = awful.util.getdir ("cache").."/jamendo_cache"
local cache_header = "[version=1.1.0]"
local album_covers_folder = awful.util.getdir("cache") .. "/jamendo_covers/"
local default_mp3_stream = nil
local search_template = { fields = { "id", "name" },
                          joins = {},
                          params = { order = ORDER_RELEVANCE,
                                     n = 1}}

-- DEPRECATED. Will be removed in the next major release.
-- Returns default stream number for MP3 format. Requests API for it
-- not more often than every hour.
local function get_default_mp3_stream()
   if not default_mp3_stream or 
      (os.time() - default_mp3_stream.last_checked) > 3600 then
      local trygetlink = 
         perform_request("echo $(curl -w %{redirect_url} " .. 
                         "'http://api.jamendo.com/get2/stream/track/redirect/" .. 
                         "?streamencoding="..FORMAT_MP3.value.."&id=729304')")
         local _, _, prefix = string.find(trygetlink,"stream(%d+)\.jamendo\.com")
         default_mp3_stream = { id = prefix, last_checked = os.time() }
   end
   return default_mp3_stream.id
end

-- Returns the track ID from the given link to Jamendo stream. If the
-- given text is not the Jamendo stream returns nil.
function get_id_from_link(link)
   local _, _, id = string.find(link,"storage%-new.newjamendo.com%?trackid=(%d+)")
   return id
end

-- Returns link to music stream for the given track ID. Uses MP3
-- format and the default stream for it.
local function get_link_by_id(id)
   -- This function is subject to change in the future.
   return string.format("http://storage-new.newjamendo.com?trackid=%s&format=mp31&u=0", id)
end

-- -- Returns the album id for given music stream.
-- function get_album_id_by_link(link)
--    local id = get_id_from_link(link, true)
--    if id and jamendo_list[id] then
--       return jamendo_list[id].album_id
--    end
-- end

-- Returns the track table for the given music stream.
function get_track_by_link(link)
   local id = get_id_from_link(link, true)
   if id and jamendo_list[id] then
      return jamendo_list[id]
   end
end

-- If a track is actually a Jamendo stream, replace it with normal
-- track name.
function replace_link(track_name)
   local track = get_track_by_link(track_name)
   if track then
      return track.display_name
   else
      return track_name
   end
end

-- Returns table of track IDs, names and other things based on the
-- request table.
function return_track_table(request_table)
   local req_string = form_request(request_table)
   local response = perform_request(req_string)
   if not response then
      return nil -- Bad internet connection
   end
   parse_table = parse_json(response)
   for i = 1, table.getn(parse_table) do
      if parse_table[i].stream == "" then
         -- Some songs don't have Ogg stream, use MP3 instead
         parse_table[i].stream = get_link_by_id(parse_table[i].id)
      end
      _, _, parse_table[i].artist_link_name = 
         string.find(parse_table[i].artist_url, "\\/artist\\/(.+)")
      -- Remove Jamendo escape slashes
      parse_table[i].artist_name =
         string.gsub(parse_table[i].artist_name, "\\/", "/")
      parse_table[i].name = string.gsub(parse_table[i].name, "\\/", "/")

      parse_table[i].display_name = 
         parse_table[i].artist_name .. " - " .. parse_table[i].name
      -- Do Jamendo a favor, extract album_id for the track yourself
      -- from album_image link :)
      local _, _, album_id = 
         string.find(parse_table[i].album_image, "\\/(%d+)\\/covers")
      parse_table[i].album_id = album_id or 0
      -- Save fetched tracks for further caching
      jamendo_list[parse_table[i].id] = parse_table[i]
   end
   save_cache()
   return parse_table
end

-- Generates the request to Jamendo API based on provided request
-- table. If request_table is nil, uses current_request_table instead.
-- For all values that do not exist in request_table use ones from
-- current_request_table.
-- return - HTTP-request
function form_request(request_table)
   local curl_str = "curl -A 'Mozilla/4.0' -fsm 5 \"%s\""
   local url = "http://api.jamendo.com/en/?m=get2%s%s"
   request_table = request_table or current_request_table
   
   local fields = request_table.fields or current_request_table.fields
   local joins = request_table.joins or current_request_table.joins
   local unit = request_table.unit or current_request_table.unit
   
   -- Form field&joins string (like field1+field2+fieldN%2Fjoin+)
   local fnj_string = "&m_params="
   for i = 1, table.getn(fields) do
      fnj_string = fnj_string .. fields[i] .. "+"
   end
   fnj_string = string.sub(fnj_string,1,string.len(fnj_string)-1)
   
   fnj_string = fnj_string .. "%2F" .. unit .. "%2Fjson%2F"
   for i = 1, table.getn(joins) do
      fnj_string = fnj_string .. joins[i] .. "+"
   end
   fnj_string = fnj_string .. "%2F"
   
   local params = {}
   -- If parameters where supplied in request_table, add them to the
   -- parameters in current_request_table.
   if request_table.params and 
      request_table.params ~= current_request_table.params then
      -- First fill params with current_request_table parameters
      for k, v in pairs(current_request_table.params) do
         params[k] = v
      end
      -- Then add and overwrite them with request_table parameters
      for k, v in pairs(request_table.params) do
         params[k] = v
      end
   else -- Or just use current_request_table.params
      params = current_request_table.params
   end
   -- Form parameter string (like param1=value1&param2=value2)
   local param_string = ""
   for k, v in pairs(params) do
      if type(v) == "table" then
         v = v.value
      end
      v = string.gsub(v, " ", "+")
      param_string = param_string .. "&" .. k .. "=" .. v
   end

   return string.format(curl_str, string.format(url, fnj_string, param_string))
end

-- Primitive function for parsing Jamendo API JSON response.  Does not
-- support arrays. Supports only strings and numbers as values.
-- Provides basic safety (correctly handles special symbols like comma
-- and curly brackets inside strings)
-- text - JSON text
function parse_json(text)
   local parse_table = {}
   local block = {}
   local i = 0
   local inblock = false
   local instring = false
   local curr_key = nil
   local curr_val = nil
   while i and i < string.len(text) do
      if not inblock then -- We are not inside the block, find next {
         i = string.find(text, "{", i+1)
         inblock = true
         block = {}
      else
         if not curr_key then -- We haven't found key yet
            if not instring then -- We are not in string, check for more tags
               local j = string.find(text, '"', i+1)
               local k = string.find(text, '}', i+1)
               if j and j < k then -- There are more tags in this block
                  i = j
                  instring = true
               else -- Block is over, we found its ending
                  i = k
                  inblock = false
                  table.insert(parse_table, block)
               end
            else -- We are in string, find its ending
               _, i, curr_key = string.find(text,'(.-[^%\\])"', i+1)
               instring = false
            end
         else -- We have the key, let's find the value
            if not curr_val then -- Value is not found yet
               if not instring then -- Not in string, check if value is string
                  local j = string.find(text, '"', i+1)
                  local k = string.find(text, '[,}]', i+1)
                  if j and j < k then -- Value is string
                     i = j
                     instring = true
                  else -- Value is int
                     _, i, curr_val = string.find(text,'(%d+)', i+1)
                  end
               else -- We are in string, find its ending
                  local j = string.find(text, '"', i+1)
                  if j == i+1 then -- String is empty
                     i = j
                     curr_val = ""
                  else
                     _, i, curr_val = string.find(text,'(.-[^%\\])"', i+1)
                     curr_val = utf8_codes_to_symbols(curr_val)
                  end
                  instring = false
               end
            else -- We have both key and value, add it to table
               block[curr_key] = curr_val
               curr_key = nil
               curr_val = nil
            end
         end
      end
   end
   return parse_table
end

-- Jamendo returns Unicode symbols as \uXXXX. Lua does not transform
-- them into symbols so we need to do it ourselves.
function utf8_codes_to_symbols (s)
   local hexnums = "[%dabcdefABCDEF]"
   local pattern = string.format("\\u(%s%s%s%s?)", 
                                 hexnums, hexnums, hexnums, hexnums)
   local decode = function(code)
                     code = tonumber(code, 16)
                     if code < 128 then -- one-byte symbol
                        return string.char(code)
                     elseif code < 2048 then -- two-byte symbol
                        -- Grab high and low bytes
                        local hi = math.floor(code / 64)
                        local lo = math.mod(code, 64)
                        -- Return symbol as \hi\lo
                        return string.char(hi + 192, lo + 128)
                     elseif code < 65536 then
                        -- Grab high, middle and low bytes
                        local hi = math.floor(code / 4096)
                        local leftover = code - hi * 4096
                        local mi = math.floor(leftover / 64)
                        leftover = leftover - mi * 64
                        local lo = math.mod(leftover, 64)
                        -- Return symbol as \hi\mi\lo
                        return string.char(hi + 224, mi + 160, lo + 128)
                     elseif code < 1114112 then
                        -- Grab high, highmiddle, lowmiddle and low bytes
                        local hi = math.floor(code / 262144)
                        local leftover = code - hi * 262144
                        local hm = math.floor(leftover / 4096)
                        leftover = leftover - hm * 4096
                        local lm = math.floor(leftover / 64)
                        local lo = math.mod(leftover, 64)
                        -- Return symbol as \hi\hm\lm\lo
                        return string.char(hi + 240, hm + 128, lm + 128, lo + 128)
                     else -- It is not Unicode symbol at all
                        return tostring(code)
                     end
                  end
   return string.gsub(s, pattern, decode)
end

-- Retrieves mapping of track IDs to track names and album IDs to
-- avoid redundant queries when Awesome gets restarted.
local function retrieve_cache()
   local bus = io.open(cache_file)
   local track = {}
   if bus then
      local header = bus:read("*line")
      if header == cache_header then 
         for l in bus:lines() do
            local _, _, id, artist_link_name, album_name, album_id, track_name = 
               string.find(l,"(%d+)-([^-]+)-([^-]+)-(%d+)-(.+)")
            track = {}
            track.id = id
            track.artist_link_name = string.gsub(artist_link_name, '\\_', '-')
            track.album_name = string.gsub(album_name, '\\_', '-')
            track.album_id = album_id
            track.display_name = track_name
            jamendo_list[id] = track
         end
      else 
         -- We encountered an outdated version of the cache
         -- file. Let's just remove it.
         awful.util.spawn("rm -f " .. cache_file)
      end
   end
end

-- Saves track IDs to track names and album IDs mapping into the cache
-- file.
function save_cache()
   local bus = io.open(cache_file, "w")
   bus:write(cache_header .. "\n")
   for id,track in pairs(jamendo_list) do
      bus:write(string.format("%s-%s-%s-%s-%s\n", id, 
                              string.gsub(track.artist_link_name, '-', '\\_'),
                              string.gsub(track.album_name, '-', '\\_'),
                              track.album_id, track.display_name))
   end
   bus:flush()
   bus:close()
end

-- Retrieve cache on initialization
retrieve_cache()

-- Returns a filename of the album cover and formed wget request that
-- downloads the album cover for the given track name. If the album
-- cover already exists returns nil as the second argument.
function fetch_album_cover_request(track_id)
   local track = jamendo_list[track_id]
   local album_id = track.album_id

   if album_id == 0 then -- No cover for tracks without album!
      return nil
   end
   local file_path = album_covers_folder .. album_id .. ".jpg"

   if not file_exists(file_path) then -- We need to download it  
      -- First check if cache directory exists
      f = io.popen('test -d ' .. album_covers_folder .. ' && echo t')
      if f:read("*line") ~= 't' then
         awful.util.spawn("mkdir " .. album_covers_folder)
      end
      f:close()
      
      if not track.album_image then      -- Wow! We have album_id, but
         local a_id = tostring(album_id) --don't have album_image. Well,
         local prefix =                  --it happens.
            string.sub(a_id, 1, string.len(a_id) - 3) 
         track.album_image = 
            string.format("http://imgjam.com/albums/s%s/%s/covers/1.100.jpg",
                          prefix == "" and 0 or prefix, a_id)
      end
      
      return file_path, string.format("wget %s -O %s 2> /dev/null",
                                      track.album_image, file_path)
   else -- Cover already downloaded, return its filename and nil
      return file_path, nil
   end
end

-- Returns a file containing an album cover for given track id.  First
-- searches in the cache folder. If file is not there, fetches it from
-- the Internet and saves into the cache folder.
function get_album_cover(track_id)
   local file_path, fetch_req = fetch_album_cover_request(track_id)
   if fetch_req then
      local f = io.popen(fetch_req)
      f:close()

      -- Let's check if file is finally there, just in case
      if not file_exists(file_path) then
         return nil
      end
   end
   return file_path
end

-- Same as get_album_cover, but downloads (if necessary) the cover
-- asynchronously.
function get_album_cover_async(track_id)
   local file_path, fetch_req = fetch_album_cover_request(track_id)
   if fetch_req then
      asyncshell.request(fetch_req)
   end
end

-- Checks if track_name is actually a link to Jamendo stream. If true
-- returns the file with album cover for the track.
function try_get_cover(track_name)
   local id = get_id_from_link(track_name)
   if id then 
      return get_album_cover(id)
   end
end

-- Same as try_get_cover, but calls get_album_cover_async inside.
function try_get_cover_async(track_name)
   local id = get_id_from_link(track_name)
   if id then
      return get_album_cover_async(id)
   end
end

-- Returns the track table for given query and search method.
-- what - search method - SEARCH_ARTIST, ALBUM or TAG
-- s - string to search
function search_by(what, s)
   -- Get a default request and set unit and query
   local req = search_template
   req.unit = what.unit
   req.params.searchquery = s
   local resp = perform_request(form_request(req))
   if resp then
      local search_res = parse_json(resp)[1]
      
      if search_res then
         -- Now when we got the search result, find tracks filtered by
         -- this result.
         local params = {}
         params[what.value] = search_res.id
         req = { params = params }
         local track_table = return_track_table(req)
         return { search_res = search_res, tracks = track_table }
      end
   end
end

-- Executes request_string with io.popen and returns the response.
function perform_request(reqest_string)
   local bus = assert(io.popen(reqest_string,'r'))
   local response = bus:read("*all")
   bus:close()
   -- Curl with popen can sometimes fail to fetch data when the
   -- connection is slow. Let's try again if it fails.
   if string.len(response) == 0 then
      bus = assert(io.popen(reqest_string,'r'))
      response = bus:read("*all")
      bus:close()
      -- If it still can't read anything, return nil
      if string.len(response) ~= 0 then 
         return nil
      end
   end
   return response
end

-- Sets default streamencoding in current_request_table.
function set_current_format(format)
   current_request_table.params.streamencoding = format
end

-- Sets default order in current_request_table.
function set_current_order(order)
   current_request_table.params.order = order
end
