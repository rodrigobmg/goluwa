local love = (...) or _G.lovemu.love

love.sound = {}

local SoundData = {}

SoundData.Type = "SoundData"

function SoundData:getPointer()
	return self.samples
end

function SoundData:getSize()
	return self.buffer:GetSize()
end

function SoundData:getString()
	return ffi.string(self.buffer:GetData())
end

function SoundData:getBitDepth()
	return self.buffer:GetBits()
end

function SoundData:getBits()
	return self.buffer:GetBits()
end

function SoundData:getChannels()
	return self.buffer:GetChannels()
end

function SoundData:getDuration()
	return self.buffer:GetDuration()
end

function SoundData:getSample(i)
	return self.samples[i]
end

function SoundData:getSampleCount()
	return self.buffer:GetLength()
end

function SoundData:getSampleRate()
	return self.buffer:GetSampleRate()
end
function SoundData:setSample(i, sample)
	self.samples[i] = sample*127
	self.buffer:SetData(self.buffer:GetData()) -- slow!!!
end

local al = require("lj-openal.al")

local function get_format(channels, bits)
	if channels == 1 and bits == 8 then
		return al.e.AL_FORMAT_MONO8
	elseif channels == 1 and bits == 16 then
		return al.e.AL_FORMAT_MONO16
	elseif channels == 2 and bits == 8 then
		return al.e.AL_FORMAT_STEREO8
	elseif channels == 2 and bits == 16 then
		return al.e.AL_FORMAT_STEREO16
	end
	
	return 0
end

function love.sound.newSoundData(samples, rate, bits, channels)
	local self = lovemu.CreateObject(SoundData)
	local buffer = audio.CreateBuffer()
	self.buffer = buffer
	
	if type(samples) == "string" then
		resource.Download(samples, function(path)
			local data = vfs.Read(path)
			
			local data, length, info = audio.Decode(data, var)
			
			if data then
				local buffer = audio.CreateBuffer()
				buffer:SetFormat(info.channels == 1 and al.e.AL_FORMAT_MONO16 or al.e.AL_FORMAT_STEREO16)
				buffer:SetSampleRate(info.samplerate)
				buffer:SetData(data, length)
				
				self:SetBuffer(buffer)

				self.decode_info = info
				self.ready = true

				-- in case it's instantly loaded and OnLoad is defined the same frame
				event.Delay(0, function() 
					if self:IsValid() and self.OnLoad then 
						self:OnLoad(info)
						if self.play_when_ready then
							self:Play()
							self.play_when_ready = nil
						end
					end 
				end)
			end
		end)
		
		return self
	end
	
	
	buffer:SetFormat(get_format(channels, bits))
	buffer:SetData(ffi.new("int8_t[?]", samples * channels), samples * channels)
	
	self.samples = buffer:GetData()
	
	return self
end