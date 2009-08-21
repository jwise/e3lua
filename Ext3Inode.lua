local bit = require"bit"
local serial = require"serial"
require"Ext3BG"
require"Ext3IFile"

Ext3Inode = {}
Ext3Inode.INDIRECT1 = 12
Ext3Inode.INDIRECT2 = 13
Ext3Inode.INDIRECT3 = 14
Ext3Inode.format = {
       {'mode', 'flags', {
                -- access
                IXOTH = 0x0001,
                IWOTH = 0x0002,
                IROTH = 0x0004,
                IXGRP = 0x0008,
                IWGRP = 0x0010,
                IRGRP = 0x0020,
                IXUSR = 0x0040,
                IWUSR = 0x0080,
                IRUSR = 0x0100,
                -- exec user/group override (?)
                ISVTX = 0x0200,
                ISGID = 0x0400,
                ISUID = 0x0800,
                -- file format... except not
                x1000 = 0x1000,
                x2000 = 0x2000,
                x4000 = 0x4000,
                x8000 = 0x8000}, 'uint16', 'le'},
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

        local fileformat = (foo.mode.x1000 and 1 or 0)
                         + (foo.mode.x2000 and 2 or 0)
                         + (foo.mode.x4000 and 4 or 0)
                         + (foo.mode.x8000 and 8 or 0)
        if fileformat == 0xC then
                foo.mode.IFSOCK = true
        elseif fileformat == 0xA then
                foo.mode.IFLNK = true
        elseif fileformat == 0x8 then
                foo.mode.IFREG = true
        elseif fileformat == 0x6 then
                foo.mode.IFBLK = true
        elseif fileformat == 0x4 then
                foo.mode.IFDIR = true
        elseif fileformat == 0x2 then
                foo.mode.IFCHR = true
        elseif fileformat == 0x1 then
                foo.mode.IFIFO = true
        else
                foo.mode.IFUNKNOWN = fileformat
        end

        -- Not sure I like doing this? But leaving them around seems messy
        -- or potentially misleading?
        foo.mode.x1000 = nil
        foo.mode.x2000 = nil
        foo.mode.x4000 = nil
        foo.mode.x8000 = nil

	for k,v in pairs(foo) do
		self[k] = v
	end

	return self
end

function Ext3Inode:len()
	if self.mode.IFREG then
		return self.size + (self.dir_acl * 0x100000000)
	else
		return self.size
	end
end

function Ext3Inode:block_lookup(blockno)
	local origblockno = blockno
	local perblk = self.fs.block_size / 4
		
	-- Direct block?
	if blockno < self.INDIRECT1 then
		return self.block[blockno + 1]
	end
	
	-- How about a first-level indirect block?
	blockno = blockno - self.INDIRECT1
	if blockno < perblk then
		if self.block[self.INDIRECT1 + 1] == 0 then
			return 0
		end
		local iblock = serial.read.struct(serial.buffer(self.fs:read_block(self.block[self.INDIRECT1 + 1])), 'array', perblk, 'uint32', 'le')
		return iblock[blockno + 1]
	end
	
	error("unimplemented")
end

function Ext3Inode:block_read(blockno)
	local b = self:block_lookup(blockno)
	
	if b == 0 then
		return string.rep(string.char(0), self.fs.block_size) 
	else
		return self.fs:read_block(b)
	end
end

function Ext3Inode:file()
	return Ext3IFile:new{inode = self}
end
