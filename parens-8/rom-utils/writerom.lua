function writerom(str, addr, filename)
	local target = filename and 0x8000 or addr
	poke(target, ord(str, 1, #str))
	if (filename) cstore(addr, target, #str, filename)
	return #str
end
