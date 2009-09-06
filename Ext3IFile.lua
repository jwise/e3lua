local bit = require"bit"
local serial = require"serial"

Ext3IFile = {}

function Ext3IFile:new(o)
	assert(o.inode)
	
	o.curblock = 0
	o.blockofs = 0
	o.pos = 0
	
	o.len = o.inode:len()
	o.fs = o.inode.fs
	o.disk = o.fs.disk

	setmetatable(o, self)
	self.__index = self
	return o
end

function Ext3IFile:read(len)
	local buf = ""
	local fs, inode, disk = self.fs, self.inode, self.disk
	
	while len > 0 do
		local nbytes
		
		nbytes = math.min(fs.block_size - self.blockofs,
		                  self.len - self.pos,
		                  len)
		if nbytes == 0 then
			break
		end
		
		buf = buf .. inode:block_read(self.curblock):sub(self.blockofs+1, self.blockofs+nbytes)
		
		self.blockofs = self.blockofs + nbytes
		if self.blockofs == fs.block_size then
			self.blockofs = 0
			self.curblock = self.curblock + 1
		end
		self.pos = self.pos + nbytes
		len = len - nbytes
	end
	
	return buf
end

function Ext3IFile:seek(pos)
	if pos == nil then
		return self.pos
	end
	
	pos = math.min(pos, self.len)
	pos = math.max(pos, 0)
	
	self.curblock = pos / self.fs.block_size
	self.blockofs = pos % self.fs.block_size
	self.pos = pos
	
	return self.pos
end

function Ext3IFile:receive(pat, pfx)
	if type(pat) ~= "number" then
		error("Ext3IFile:receive doesn't know how to handle non-numbers")
	end
	pfx = pfx or ""
	
	return pfx..self:read(pat)
end

function Ext3IFile:length()
	return self.len - self.pos
end

function Ext3IFile:readdir()
	if self.pos == self.len then
		return nil
	end
	
	local de = serial.read.fstruct(self, function(self)
		self 'inodenum' ('uint32', 'le')
		self 'rec_len' ('uint16', 'le')
		self 'name_len' ('uint8')
		self 'file_type' ('uint8')
		self 'name' ('bytes', self.name_len)
		self 'pad' ('bytes', self.rec_len - self.name_len - 1 - 1 - 2 - 4)
		end)
	local ft = de.file_type
	de.filetype = {}
	if ft == 1 then
		de.filetype.REG_FILE = true
	elseif ft == 2 then
		de.filetype.DIR = true
	elseif ft == 3 then
		de.filetype.CHRDEV = true
	elseif ft == 4 then
		de.filetype.BLKDEV = true
	elseif ft == 5 then
		de.filetype.FIFO = true
	elseif ft == 6 then
		de.filetype.SOCK = true
	elseif ft == 7 then
		de.filetype.SYMLINK = true
	else
		de.filetype.UNKNOWN = ft
	end
	
	de.inode = function (...)
		return self.fs:inode(de.inodenum, ...)
	end
	de.file = function (...)
		return self.fs:inode(de.inodenum, ...):file(...)
	end
	de.directory = function (...)
		return self.fs:inode(de.inodenum, ...):directory(...)
	end
	
	return de
end

function Ext3IFile:directory()
	local d = {}
	local de
	
	de = self:readdir()
	while de do
		table.insert(d, de)
		d[de.name] = de
		de = self:readdir()
	end
	
	return d
end
