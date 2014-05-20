local ffmpeg = require("lj-ffmpeg")

local path = R"videos/casiopea.webm"
local decoder = assert(ffmpeg.Open(path))

local texture = Texture(decoder:GetConfig().width, decoder:GetConfig().height)
local sound = audio.CreateSource()

sound:SetBufferFormat(e.AL_FORMAT_STEREO16)
sound:SetBufferCount(4)
 
timer.Create("decoder_test", 0, 1/30, function()
	local audio_data, texture_buffer = decoder:Read(4096*4)
	
	for key, data in ipairs(audio_data) do
		sound:FeedBuffer(data.buffer, data.length)
	end	
	
	if texture_buffer then
		texture:Upload(texture_buffer)
	end
end)

function goluwa.decoder_test.OnDraw2D()
	surface.Color(1,1,1,1)
	
	surface.SetTexture(texture)
	surface.DrawRect(0,0, texture.w,texture.h)
	
	surface.SetTextPos(0, 20)
	surface.DrawText("image queue size: " .. #decoder.streams[0].queue)
	surface.SetTextPos(0, 40)
	surface.DrawText("frame skips: " .. decoder.frame_skips)
end