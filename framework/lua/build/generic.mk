LUA_DIR = ../luajit/
LUA_BIN = $(LUA_DIR)repo/src/luajit

all: $(LUA_BIN)
	export LD_LIBRARY_PATH=".:$LD_LIBRARY_PATH" && ./$(LUA_BIN) build.lua ${ARGS}

$(LUA_BIN):
	cd ../luajit && make

clean:
	rm -f lib*.lua
	rm -rf repo
	rm -f lib*.so
	rm -f lib*.dylib
