Perceptive, a weather notification module for awesome
================================

Perceptive is a module for awesome wm for brief and compact
weather notification via naughty lib and Yahoo! Weather API.

Requirements
------------
- awesome 3.4 (awesome 3.5 is not supported yet)
- /tmp directory (I'll store a temporary file over there.)
- python 2.7

Usage
-----
Clone perceptive repository into your $XDG_CONFIG_HOME/awesome (awesome config dir).
Then, add on top of rc.lua :

    require("perceptive")

Bind perceptive notification to some widget:

    perceptive.register(mytextclock, 2123260)

Where the second argument is so-called WOEID code of your city.
To obtain it you can google 'yahoo weather %CITYNAME%' and follow the first link.
It will look like http://weather.yahoo.com/united-states/california/san-diego-2487889/
and the last number in that link will be the ID you need.

Screenshot
-----
![Screenshot][1]

[1]: http://github.com/ioga/perceptive/raw/master/screenshot.png

License
-----
Copyright (C) 2011-2013 Ilia Glazkov.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
