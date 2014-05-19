 -- WIP
-- CapsAdmin: On the server it says I've joined with the correct steamid 
-- but if developer mode is on it says: 	S3: Client connected with invalid ticket: UserID: 2
-- I then get rejected here in this script with: 	#GameUI_ServerRejectSteam

local ip, port = "87.245.209.42", 27015  
 
local function wireshark_hex_dump(str)
	logn((str:readablehex():gsub("(.. .. .. .. .. .. .. .. )(.. .. .. .. .. .. .. .. )", "%1\t%2\n")))
end

local CHALLENGE_REQUEST = 0x71
local CHALLENGE_SERVER_RESPONSE = 0x41
local CHALLENGE_CLIENT_RESPONSE = 0x6b

local CONNECTION_REJECTED = 0x39
local CONNECTION_SUCCESS = 0x42

local SINGLE_PACKET = 0xFFFFFFFF
local MAGIC_VERSION = 0x5A4F4933
local PROTOCOL_VERSION = 0x18 --0xf
local PROTOCOL_STEAM = 0x03 -- Protocol type (Steam authentication)
local DISCONNECT_REASON_LENGTH = 1260

-- this was tested on 2 different accounts (connecting to different servers however)

local connect = {
	request = {
		[CHALLENGE_REQUEST] = {
			{"long", SINGLE_PACKET}, -- this is for telling if the packet is split or not
			{"byte", CHALLENGE_REQUEST}, -- get challenge
			
			{"long", 0}, -- wireshark: 0x33277200, 0xc95ea209, 0xa2429f06, 0xa9339601, 0x2291370d, ...
			
			-- padding
			{"string", "0000000000"} -- wireshark: 30 30 30 30 30 30 30 30 30 30 00
		},
		[CHALLENGE_CLIENT_RESPONSE] = {
			{"long", SINGLE_PACKET}, 
			{"byte", CHALLENGE_CLIENT_RESPONSE}, 
			{"byte", PROTOCOL_VERSION}, 
			0x00, 0x00, 0x00, -- is PROTOCOL_STEAM a long?
			{"byte", PROTOCOL_STEAM}, 
			0x00, 0x00, 0x00,
			{"bytes", get = "challenge"},
			
			{"string", "CapsAdmin"}, -- nick
			{"string", "train"}, -- password, can be NULL if not provided
			{"string", "14.04.19"}, -- date? matches the date joined at if months are counted from 0
			
			
			
			-- commented bytes are example of the other accounts data
			
			-- SAME: always the same even on both accounts
			-- DIFFERENT: differs on both accounts but consistently
			-- DIFFERENT EVERYTIME: different for each response
			
			-- SAME
			0xf2, 0x00, 
			
		-- DIFFERENT
		0xef, 0x82, 0x1d, 
--		0xf5, 0x6b, 0xc7,
			
			-- SAME
			0x01, 0x01, 0x00, 0x10, 0x01, 
			
			-- auth token. 
			-- examples:
			-- 14 00 00 00 cb 1d f1 1d 4d cf 41 38 ef 82 1d 01 01 00 10 01 f5 62 79 53 00 00 00 00
			-- 14 00 00 00 89 8f aa 0e ff 12 83 45 ef 82 1d 01 01 00 10 01 83 30 77 53 18 00 00 00
			-- 14 00 00 00 76 8c e1 68 ba 8c f2 fd f5 6b c7 01 01 00 10 01 1f 21 79 53 18 00 00 00
			{"bytes", get = function(data) local key = steam.GetAuthTokenFromServer(utilities.StringToLongLong(data.gsid), ip, port, data.vac) wireshark_hex_dump(key) return key end},
			
			-- SAME
			0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 
			
		-- DIFFERENT
		0x17, 0xd9, 0xc7, 0x6d,
--		0x8b, 0xf1, 0xa4, 0x47, 
			
			-- SAME
			0x00, 0x00, 0x00, 0x00, 
						
		-- DIFFERENT EVERYTIME
		0xda, 0x87, 0x02, 0x0d, 0x03,
			 
			-- SAME
			0x00, 0x00, 0x00, 0xb2, 
			0x00, 0x00, 0x00, 0x32, 
			0x00, 0x00, 0x00, 0x04, 
			0x00, 0x00, 0x00, 
			
		-- DIFFERENT
		0xef, 0x82, 0x1d,
--		0xf5, 0x6b, 0xc7,
			
			-- SAME
			0x01, 0x01, 0x00, 0x10, 0x01, 0xa0, 0x0f, 0x00, 0x00, 
			
		-- DIFFERENT
		0x17, 0xd9, 0xc7, 0x6d, 0x0a, 0x00, 
--		0x8b, 0xf1, 0xa4, 0x47, 0x0b, 0x01,
			
			-- SAME
			0xa8, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x62, 0xa2, 0x71, 0x53, 
			
		-- DIFFERENT
		0xe2, 0x51, 
--		0xc8, 0x2b,

			-- SAME
			0x8d, 0x53, 0x01, 0x00, 
			0xda, 0x00, 0x00, 0x00, 
			0x00, 0x00, 0x00, 0x00, 
			
		-- DIFFERENT
		-- these 128 bytes change depending on the account
		0x5c, 0xe7, 0x26, 0x18, 0xdb, 0x04, 0x5d, 0xec, 
		0x5e, 0xc7, 0x4c, 0x0a, 0xcf, 0x7d, 0x51, 0xfe, 
		0xad, 0x1d, 0x63, 0x6d, 0x41, 0xe6, 0xeb, 0x56, 
		0xcf, 0x45, 0x2c, 0x19, 0xaf, 0xc7, 0x26, 0xa8, 
		0xb7, 0x84, 0x4f, 0x3f, 0x56, 0x3e, 0x47, 0x8f, 
		0x1e, 0x2a, 0x8a, 0xfd, 0x79, 0x08, 0x7c, 0xa1, 
		0xb9, 0x6d, 0x74, 0xe4, 0x74, 0xbd, 0x8a, 0x6e, 
		0x83, 0xba, 0x74, 0x12, 0x80, 0xe9, 0x19, 0xf1, 
		0xe3, 0x5e, 0xaf, 0x6a, 0xa8, 0xf2, 0xc9, 0x4a, 
		0x4a, 0x2f, 0xba, 0xc9, 0x65, 0xa9, 0xa4, 0xa6, 
		0x4c, 0x7d, 0xcd, 0x7b, 0xa5, 0xa4, 0x10, 0x82, 
		0xe6, 0xdb, 0x46, 0x9e, 0x99, 0x82, 0x23, 0xb5, 
		0x06, 0xe4, 0x7d, 0x9d, 0x6d, 0x5d, 0x22, 0xa2, 
		0x67, 0x11, 0xd0, 0x4d, 0xb9, 0xd3, 0x5c, 0xe0, 
		0xc2, 0x43, 0x95, 0xc4, 0x46, 0xe8, 0x17, 0xa1, 
		0x54, 0x75, 0xca, 0xad, 0xb6, 0x93, 0xc6, 0x96
		
		--[[
		0x5b, 0x51, 0x04, 0xcd, 0xad, 0x3f, 0xf2, 0x2a, 
		0x95, 0x23, 0x78, 0x22, 0x27, 0x90, 0x0c, 0x38, 
		0x17, 0x9e, 0x10, 0xff, 0x14, 0xa5, 0x66, 0x52, 
		0x0e, 0x19, 0x00, 0xd3, 0xa4, 0x7f, 0x19, 0x66, 
		0x43, 0xd2, 0x50, 0x6e, 0x19, 0xd2, 0x9d, 0x26, 
		0x66, 0xf3, 0xc7, 0xd8, 0x5f, 0x50, 0x6c, 0x97, 
		0x6a, 0x1e, 0xd3, 0xe2, 0xaf, 0xdd, 0xb0, 0xd2, 
		0x1a, 0x2d, 0xda, 0xef, 0x19, 0xa2, 0x27, 0x10, 
		0xf9, 0x2c, 0x85, 0x9e, 0x4d, 0x39, 0x99, 0x14, 
		0x41, 0x4a, 0xcd, 0x46, 0xc2, 0x1d, 0xe8, 0x21, 
		0xb4, 0xdb, 0xbb, 0x08, 0x7f, 0x50, 0x9e, 0xf6, 
		0x7e, 0xb5, 0x81, 0x7a, 0x8c, 0x73, 0x18, 0x26, 
		0x9a, 0x17, 0xd4, 0xbb, 0xa3, 0xba, 0x43, 0x5b, 
		0xe8, 0xd2, 0xfa, 0x15, 0x26, 0xc8, 0x80, 0x3c, 
		0x84, 0x0d, 0xd3, 0x6f, 0x51, 0x4c, 0x37, 0x88, 
		0xe5, 0xa6, 0x3b, 0x5d, 0xa2, 0x66, 0x41, 0x37,
		]]
			
		};
	},
	response = {
		{"long", "header"},
		{"byte", "type", switch = {
			[CONNECTION_REJECTED] = {
				{"long", "client_challenge"},   
				{"string", "disconnect_reason", length = DISCONNECT_REASON_LENGTH},   
			},
			[CHALLENGE_SERVER_RESPONSE] = {
				{"long", "magic_version", assert = MAGIC_VERSION},
				{"string", "challenge", length = 8}, -- this is server and client challenge combined (in the order long server_challenge, long client_challenge)
				{"byte", "protocol", assert = PROTOCOL_STEAM},
				
				{"byte", "unknown"}, -- wireshark: 00 00
				{"long", "unknown"}, -- wireshark: 00 00 00 01
				
				{"string", "gsid", length = 7}, 
				{"boolean", "vac"},
				
				{"string", "padding"}, -- wireshark: 30 30 30 30 30 30 00
			},
		}},
	},
} 
  
local function send_struct(socket, struct, values) 
	local buffer = Buffer()
	buffer:WriteStructure(struct, values)   
	socket:Send(buffer:GetString())
end

local function read_struct(str, struct)
	return Buffer(str):ReadStructure(struct)
end

do -- socket	 
	local client = luasocket.CreateClient("udp", ip, port)
	client.debug = false  

	send_struct(client, connect.request[CHALLENGE_REQUEST])

	function client:OnReceive(str)	
		local data = read_struct(str, connect.response)
					
		if data.type == CONNECTION_REJECTED then -- rejected
			logn("connection rejected: ", data.disconnect_reason)
		elseif data.type == CHALLENGE_SERVER_RESPONSE then -- challenge
			send_struct(self, connect.request[CHALLENGE_CLIENT_RESPONSE], data) 
		elseif data.type == CONNECTION_SUCCESS then -- connection
			logn("connection success")
		end
	end
end