local bit = require"bit"
local serial = require"serial"
require"Ext3SB"

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
function Ext3FS:read_block(blockn)
        local nsectors = self.block_size / self.disk.BYTES_PER_SECTOR
        local start = blockn * nsectors
        local data = ""

        for i = 0,nsectors do
                data = data .. self.disk:read_sector(start+i)
        end

        return data
end

--[[
function Ext3FS:inode(n)
       local inode = Ext3Inode.new(...?)
       return inode:read(n)
end
]]--
