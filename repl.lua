require"readline"

function repl(fs)
	local dirpath = {}
	local inopath = {2}
	local curi = fs:inode(2):file():directory()
	local running = true
	
	local cmds = {
		exit =
			function (args)
				running = false
			end,
		cd =
			function(args)
				if not args[2] then
					print ("cd: invalid arguments")
					return
				end
				if args[2] == ".." then
					if #dirpath == 0 then
						print ("cd: already at root")
						return
					end
					table.remove(dirpath)
					table.remove(inopath)
					curi = fs:inode(inopath[#inopath]):file():directory()
					return
				end
				if not curi[args[2]] then
					print ("cd: subdirectory does not exist")
					return
				end
				
				local newi = curi[args[2]].inode{}:directory()
				dirpath[#dirpath + 1] = args[2]
				inopath[#inopath + 1] = curi[args[2]].inodenum
				curi = newi
			end,
		ls =
			function (args)
				for k,v in ipairs(curi) do
					print(string.format("[%10d] %s", v.inodenum, v.name))
				end
			end
	}
	
	while running do
		local cwd = ""
		for _,v in ipairs(dirpath) do
			cwd = cwd.."/"..v
		end
		if cwd:len() == 0 then
			cwd = "/"
		end
		
		local str = readline.readline("e3lua:"..cwd.."["..inopath[#inopath].."]> ")
		if str == nil then
			print""
			break
		end
		str = str:gsub("^[%s]*", "")
		if str ~= "" then
	--		readline.add_history(str)
		end
		
		local toks = {}
		for w in string.gmatch(str, "[^%s]+") do
			toks[#toks + 1] = w
		end
		
		if cmds[toks[1]] then
			cmds[toks[1]](toks)
		else
			print("unrecognized command: "..toks[1])
		end
	end
end
