local bit = require"bit"
local serial = require"serial"
require"Ext3BG"

Ext3Inode = {}
Ext3Inode.format = {
       {'mode', 'uint16', 'le'},
       {'uid', 'uint16', 'le'},
       {'size', 'uint32', 'le'},
       {'atime', 'uint32', 'le'},
       {'ctime', 'uint32', 'le'},
       {'mtime', 'uint32', 'le'},
       {'dtime', 'uint32', 'le'},
       {'gid', 'uint16', 'le'},
       {'links_count', 'uint16', 'le'},
       {'blocks', 'uint32', 'le'},
       {'flags', 'uint32', 'le'},
       {'osd1', 'uint32', 'le'},
       {'block', 'array', 15, 'uint32', 'le'},
       {'generation', 'uint32', 'le'},
       {'file_acl', 'uint32', 'le'},
       {'dir_acl', 'uint32', 'le'},
       {'faddr', 'uint32', 'le'},
       {'osd2', 'bytes', 12}
}

function Ext3Inode:new(o)
       o = o or {}

       setmetatable(o, self)
       self.__index = self
       return o
end

function Ext3Inode:read(n)
	-- approximately copying from inode.c, for better or for worse
	local inodes_per_block = self.fs.block_size / self.fs.sb.inode_size
	local bgn = (n-1) / self.fs.sb.inodes_per_group

	-- help, i don't know lua, this may be dangerous
	local bg = Ext3BG:new{fs = self.fs}
	bg:read(bgn)
	-- "???"
	
	local curblock = bg.inode_table + ((n - 1) % self.fs.sb.inodes_per_group) / inodes_per_block
	local offset = self.fs.sb.inode_size * ((n - 1) % inodes_per_block)
	 
	local data = self.fs:read_block(curblock):sub(offset+1)
       
	local foo = serial.read.struct(serial.buffer(data), self.format)

	for k,v in pairs(foo) do
		self[k] = v
	end
	
	-- ???

	return self
end
