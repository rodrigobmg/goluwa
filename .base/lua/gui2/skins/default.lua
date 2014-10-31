local gui2 = ... or _G.gui2

local scale = 2
local ninepatch_size = 32
local ninepatch_corner_size = 4
local ninepatch_pixel_border = scale
local bg = ColorBytes(64, 44, 128, 200) 

local S = scale

local text_size = 5*S 

surface.CreateFont("snow_font", {
	path = "Roboto", 
	size = 11,
}) 

surface.CreateFont("snow_font_green", {
	path = "fonts/zfont.txt", 
	size = text_size,
	shadow = S,
	shadow_color = Color(0,1,0,0.4),
}) 

surface.CreateFont("snow_font_noshadow", {
	path = "Roboto", 
	size = 11,
})

local texture = Texture("textures/gui/skin.png")

local skin = {}

local function add(name, u,v, w,h, corner_size, color)
	skin[name] = {
		texture = texture, 
		texture_rect = Rect(u, v, w, h),
		corner_size = corner_size, 
		color = color,
		ninepatch = true,
	}
end

local function add_simple(name, u,v, w,h, color)
	skin[name] = {
		texture = texture, 
		texture_rect = Rect(u, v, w, h),
		size = Vec2(w, h),
		color = color,
	}
end

add("button_inactive", 480,0, 31,31, 4)
add("button_active", 480,96, 31,31, 4) 

add_simple("close_inactive", 32,452, 29,16) 
add_simple("close_active", 96,452, 29,16) 

add_simple("minimize_inactive", 132,452, 29,16) 
add_simple("minimize_active", 196,452, 29,16) 

add_simple("maximize_inactive", 225,484, 29,16) 
add_simple("maximize_active", 290,484, 29,16) 

add_simple("maximize2_inactive", 225,452, 29,16) 
add_simple("maximize2_active", 290,452, 29,16) 

add_simple("up_inactive", 464,224, 15,15) 
add_simple("up_active", 480,224, 15,15) 

add_simple("down_inactive", 464,256, 15,15) 
add_simple("down_active", 480,256, 15,15) 

add_simple("left_inactive", 464,208, 15,15) 
add_simple("left_active", 480,208, 15,15) 

add_simple("right_inactive", 464,240, 15,15) 
add_simple("right_active", 480,240, 15,15) 

add_simple("menu_right_arrow", 472,116, 4,7) 
add_simple("list_up_arrow", 385,114, 5,3) 
add_simple("list_down_arrow", 385,122, 5,3) 

add_simple("check", 448,32, 15,15) 
add_simple("uncheck", 464,32, 15,15)
 
add_simple("+", 451,99, 9,9) 
add_simple("-", 467,99, 9,9)

add("scroll_vertical_track", 384,208, 15,127, 4) 
add("scroll_vertical_handle_inactive", 400,208, 15,127, 4) 
add("scroll_vertical_handle_active", 432,208, 15,127, 4)

add("scroll_horizontal_track", 384,128, 127,15, 4) 
add("scroll_horizontal_handle_inactive", 384,144, 127,15, 4) 
add("scroll_horizontal_handle_active", 384,176, 127,15, 4) 

add("button_rounded_active", 480,64, 31,31, 4) 
add("button_rounded_inactive", 480,64, 31,31, 4) 

add("tab_active", 0,384, 61,24, 16) 
add("tab_inactive", 128,384, 61,24, 16) 

add("menu_select", 130,258, 123,27, 16)
add("frame", 480,32, 31,31, 16)
add("property", 256,256, 63,127, 4)
add("tab_frame", 0,256+32, 127,127-32, 16)

add("gradient", 480,96, 31,31, 16)
add("gradient1", 480,96, 31,31, 16)
add("gradient2", 480,96, 31,31, 16)
add("gradient3", 480,96, 31,31, 16)

skin.tab_active_text_color = Color(0.25,0.25,0.25)
skin.tab_inactive_text_color = Color(0.5,0.5,0.5)

skin.default_font_color = Color(0.25,0.25,0.25)
skin.font_edit_color = Color(0.75,0.75,0.75)
skin.font_edit_background = Color(0.1,0.1,0.1)
skin.default_font = "snow_font"
skin.scale = scale

skin.background = Color(0.5, 0.5, 0.5)

gui2.SetSkin(skin) 