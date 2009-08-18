assert(0x7FFFFFFFFFFFFFFF ~= 0x7FFFFFFFFFFFFFFE, "RaidIO.lua requires at least 64-bit numbers")

local bit = require"bit"

RaidIO = {}
RaidIO.CHUNK_SIZE = 65536
RaidIO.SECTORS_PER_CHUNK = bit.rshift(RaidIO.CHUNK_SIZE, 9)
RaidIO.BYTES_PER_SECTOR = 512 -- er, does this belong here?
RaidIO.LVM_OFFSET = 384
RaidIO.RAID_DISKS = 3
RaidIO.DATA_DISKS = 2

function RaidIO:new(o)
	o = o or {}
	o.prefix = o.prefix or "/dev/loop"
	o.disks = o.disks or {}
	
	setmetatable(o, self)
	self.__index = self
	return o
end

function RaidIO:open()
	for i=1,3 do
		self.disks[i] = self.disks[i] or assert(io.open(self.prefix .. (i-1), "rb"))
	end
	
	return self
end

function RaidIO:close()
	for i,f in pairs(self.disks) do
		f:close()
		self.disks[i] = nil
	end
	
	return self
end

function RaidIO:compute_disk(log)
	local chunk_offset, chunk_number
	local stripe
	local dd_idx, pd_idx
	local phys
	
	chunk_offset = log % self.SECTORS_PER_CHUNK
	chunk_number = log / self.SECTORS_PER_CHUNK
	
	stripe = chunk_number / self.DATA_DISKS
	dd_idx = chunk_number % self.DATA_DISKS
	
	pd_idx = self.DATA_DISKS - stripe % self.RAID_DISKS
	dd_idx = (pd_idx + 1 + dd_idx) % self.RAID_DISKS
	
	phys = stripe * self.SECTORS_PER_CHUNK + chunk_offset
	
	return phys, dd_idx, pd_idx
end

function RaidIO:read_sector(sector, mode)
	local phys, dd_idx, pd_idx = self:compute_disk(sector + self.LVM_OFFSET)
	
	dd_idx = dd_idx + 1
	if mode then
		if mode == 0 then
			-- nothing!
		elseif mode == 1 then
			if dd_idx == 2 then
				dd_idx = 3
			elseif dd_idx == 3 then
				dd_idx = 2
			end
		else
			error("invalid mode "..mode.." for RaidIO:read_sector", 2)
		end
	end
	
	assert(self.disks[dd_idx]:seek("set", phys * 512))
	return assert(self.disks[dd_idx]:read(512))
end

