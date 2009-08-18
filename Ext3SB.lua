local bit = require"bit"
local serial = require"serial"

Ext3SB = {}
Ext3SB.format = {
	{'inodes_count', 'uint32', 'le'},
	{'blocks_count', 'uint32', 'le'},
	{'r_blocks_count', 'uint32', 'le'},
	{'free_blocks_count', 'uint32', 'le'},
	{'free_inodes_count', 'uint32', 'le'},
	{'first_data_block', 'uint32', 'le'},
	{'log_block_size', 'uint32', 'le'},
	{'log_frag_size', 'uint32', 'le'},
	{'blocks_per_group', 'uint32', 'le'},
	{'frags_per_group', 'uint32', 'le'},
	{'inodes_per_group', 'uint32', 'le'},
	{'mtime', 'uint32', 'le'},
	{'wtime', 'uint32', 'le'},
	{'mnt_count', 'uint16', 'le'},
	{'max_mnt_count', 'uint16', 'le'},
	{'magic', 'uint16', 'le'},
	{'state', 'uint16', 'le'},
	{'errors', 'uint16', 'le'},
	{'minor_rev_level', 'uint16', 'le'},
	{'lastcheck', 'uint32', 'le'},
	{'checkinterval', 'uint32', 'le'},
	{'creator_os', 'uint32', 'le'},
	{'rev_level', 'uint32', 'le'},
	{'def_resuid', 'uint16', 'le'},
	{'def_resgid', 'uint16', 'le'},
	{'first_ino', 'uint32', 'le'},
	{'inode_size', 'uint16', 'le'},
	{'block_group_nr', 'uint16', 'le'},
	{'feature_compat', 'flags', {
		DIR_PREALLOC = 1,
		IMAGIC_INODES = 2,
		HAS_JOURNAL = 4,
		EXT_ATTR = 8,
		RESIZE_INO = 16,
		DIR_INDEX = 32,
		ANY = 0xFFFFFFFF}, 'uint32', 'le'}, -- This is actually a bitmask!
	{'feature_incompat', 'flags', {
		COMPRESSION = 1,
		FILETYPE = 2,
		RECOVER = 4,
		JOURNAL_DEV = 8,
		META_BG = 16,
		ANY = 0xFFFFFFFF}, 'uint32', 'le'},
	{'feature_ro_compat', 'flags', {
		SPARSE_SUPER = 1,
		LARGE_FILE = 2,
		BTREE_DIR = 4,
		ANY = 0xFFFFFFFF}, 'uint32', 'le'},
	{'uuid', 'bytes', 16},
	{'volume_name', 'bytes', 16},
	{'last_mounted', 'bytes', 64},
	{'algorithm_usage_bitmap', 'uint32', 'le'},
	{'s_prealloc_blocks', 'uint8'},
	{'s_prealloc_dir_blocks', 'uint8'},
	{'s_padding1', 'uint16', 'le'}
}

function Ext3SB:new(o)
	o = o or {}
	
	setmetatable(o, self)
	self.__index = self
	return o
end

function Ext3SB:read(sbsector)
	sbsector = sbsector or 2

	local data = self.disk:read_sector(sbsector)
	local st = serial.read.struct(serial.buffer(data), self.format)
	
	self.disk = disk
	
	for k,v in pairs(st) do
		self[k] = v
	end
	
	if self.magic ~= 0xEF53 then
		print("Ext3SB:read: WARNING - ext3 magic does NOT match (expected 0xEF53, got "..bit.tohex(self.magic)..")! Pull up! Pull up!")
	end
	
	return self
end
