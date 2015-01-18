Awesome-3.5
==================

<img src="http://img.shields.io/gratipay/setkeh.svg">

Awesome Configs updated to 3.5

I have Finally cleaned up the Config slightly

All the Extra widgets that were custom written have now been moved to ./widgets

Vicious widgets are still where they are supposed to be.

I have also updated the bitcoin widget to no longer use the Defunct MtGox api and instead replaced it with https://bitcoinaverage.com/api

Though you will still need to add these to wi.lua yourself if you intend on using the widgets in ./widgets

---

To use this config it needs to be placed in $HOME/.config/awesome the easiest way to do this is:

	git clone https://github.com/setkeh/Awesome-3.5.git $HOME/.config/awesome

The config should be pretty Self explanitory though if you have issues please post an issue.

All of the Widgets config is in wi.lua to try to make rc.lua more manageable by default this config is setup for a laptop.

To Use the config for a Desktop you can simply edit rc.lua and comment out the battery widgets in the wibox section (or any other widgets you dont want)

Fork, Share, Have Fun :)
