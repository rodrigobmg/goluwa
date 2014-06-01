local cd = ""

console.AddCommand("ls", function()
	local files = vfs.Find(cd)
	table.print(files)
end)

console.AddCommand("cat", function(line, file)
	if vfs.Exists(cd .. file) then
		log(vfs.Read(file))
	end
end, nil, function(arg, args)
	if #args > 1 then return end
	
	return vfs.Find(cd)
end)
console.AddCommand("cd", function(line, folder)
	if not folder then
		logn(cd)
	elseif folder == ".." then
		cd = cd:match("(.+)/")
	elseif vfs.IsDir(cd .. "/" .. folder) then
		cd = cd .. "/" .. folder .. "/"
	end
end, nil, function(arg, args)
	if #args > 1 then return end
	print(#args)
	
	return vfs.Find(cd)
end)

console.AddCommand("quit", function()
	os.exit()
end)

console.AddCommand("exit", function()
	os.exit()
end)

console.AddCommand("restart", function()
	system.Restart()
end) 