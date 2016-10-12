Goluwa is a framework coded in LuaJIT that I use to further develop Goluwa with and satisfy my programming hobby. I don't really have any long term plans so I just code whatever I feel like coding. I'm interested in game engines and middleware for games so Goluwa ends up being something that vaguely resembles a game engine. I constantly refactor and change the api so I wouldn't recommend using Goluwa to make a game or anything like that but I'd be happy if you find code to use or learn from.

![ScreenShot](https://raw.githubusercontent.com/CapsAdmin/goluwa-assets/master/extras/screenshots/goluwa.png)

#Features

* [ffi-build](https://github.com/CapsAdmin/goluwa/tree/master/src/lua/build) to automatically build cdef and lua bindings.
* [gui](src/lua/libraries/graphics/gui) with focus on automatic layout and gwen skin support
* [markup language](src/lua/libraries/graphics/gui) used by gui and chat
* [löve wrapper](src/lua/libraries/lovemu) that lets you run löve games in goluwa
* [glua wrapper](src/lua/libraries/gmod) that lets you run garrysmod lua in goluwa
* [enitity editor](src/lua/autorun/graphics) similar to the [pac3 editor](http://steamcommunity.com/sharedfiles/filedetails/?id=104691717)
* all assets can be loaded from the internet using urls.
* fonts can be loaded directly from google webfont, dafont and other places for prototyping.
* lots of model and image formats supported for prototyping. including [source engine formats](src/lua/libraries/steam)
* most code can be reloaded without the need to restart.
* tight integration with zerobrane

I mainly use and develop this on Linux so windows support isn't high priority even though it should work there. It may also work on OSX but I can't test rendering as I'm limited to using mac in a vm.
