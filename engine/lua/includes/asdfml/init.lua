include("sfml.lua")

addons.AutorunAll()

function main()
	hook.Call("Initialize")
	
	print("ASDasd")
	
	while true do
		hook.Call("OnUpdate")
		timer.Update()
	end
	
	hook.Call("ShutDown")
end

hook.Add("Initialized", "main", main)