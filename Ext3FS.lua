local bit = require"bit"
local serial = require"serial"
require"Ext3SB"
require"Ext3Inode"

Ext3FS = {}

function Ext3FS:new(o)
	o = o or {}
	
	setmetatable(o,self)
	self.__index = self
	return o
end

function Ext3FS:open(disk)
	self.disk = disk or self.disk
	self.sb = Ext3SB:new{disk = self.disk}
	self.sb:read()
	self.block_size = bit.lshift(1024, self.sb.log_block_size)
	
	return self
end

-- XXX will need alternate read modes to be passed through
function Ext3FS:read_block(blockn, islame)
	local nsectors = self.block_size / self.disk.BYTES_PER_SECTOR
	local start = blockn * nsectors
	local data = ""

	for i = 0,(nsectors-1) do
		data = data .. self.disk:read_sector(start+i, islame)
	end

	return data
end

function Ext3FS:inode(n, lame)
	local inode = Ext3Inode:new({fs = self, lame = lame})
	if type(n) == 'table' then
		n = n.inode
	end
	return inode:read(n, lame)
end
