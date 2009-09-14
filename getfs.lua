function printtbl(t)
	for k,v in pairs(t) do
		print(k,"->",v)
	end
end

function printdir(t)
	for k,v in ipairs(t) do
		print(v.inodenum,v.name)
	end
end


require "Ext3FS"
require "RaidIO"
fs = Ext3FS:new{disk=RaidIO:new():open()}:open()
root = fs:inode(2):file()
rootdir = root:directory()

