local bit = require"bit"
local serial = require"serial"

Ext3BG = {}
Ext3BG.format = {
        {'block_bitmap', 'uint32', 'le'},
        {'inode_bitmap', 'uint32', 'le'},
        {'inode_table', 'uint32', 'le'},
        {'free_blocks_count', 'uint16', 'le'},
        {'free_inodes_count', 'uint16', 'le'},
        {'used_dirs_count', 'uint16', 'le'},
        {'pad', 'uint16', 'le'},
        {'reserved0', 'uint32', 'le'},
        {'reserved1', 'uint32', 'le'},
        {'reserved2', 'uint32', 'le'}
}

function Ext3BG:new(o)
        o = o or {}
        
        setmetatable(o,self)
        self.__index = self
        return o
end

function Ext3BG:read(disk, sb, bg)
        local sectors_per_block = bit.lshift(1024 / disk.BYTES_PER_SECTOR, sb.log_block_size)
        local sector = (sb.block_group_nr * sb.blocks_per_group + 1) * sectors_per_block
        -- 32: sizeof(ext3 block descriptor); there is probably a nicer way
        -- to get this value, but i don't know what it is. halp, lunary. --car
        sector = sector + (bg * 32) / disk.BYTES_PER_SECTOR

        local data = disk:read_sector(sector)
        local desc = serial.read.struct(serial.buffer(data), self.format)

        -- copied from Ext3SB.lua ... is this necessary? i do not know.
        -- may be a good idea.
        self.disk = disk

        for k,v in pairs(desc) do
                self[k] = v
        end

        return self
end
