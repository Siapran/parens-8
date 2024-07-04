function writerom(str, addr, filename)
	assert(
		addr>>16 + #str>>16 < 0x0.4300,
		"string does not fit in cart ROM")
	local target = filename and 0x8000 or addr
	poke(target, ord(str, 1, #str))
	cstore(addr, target, #str, filename)
	return #str
end

-- make sure you include minify.lua
function write_many(addr, filename, ...)
	local function hex(num) return sub(tostr(num, 1), 1, 6) end
	local function iterate(acc, a, head, ...)
		if (not head) return acc, a
		local len = writerom(minify(head), a, filename)
		acc ..= "(parens8 (readrom " .. hex(a) .. " " .. hex(len)
		if (filename) acc ..= ' "' .. filename .. '"'
		acc ..= "))\n"
		return iterate(acc, a + len, ...)
	end
	local res, len = iterate("parens8[[\n", addr, ...)
	print("wrote " .. len .. " (" .. hex(len) .. ") bytes")
	return res .."]]"
end

function write_clipboard(addr, filename, ...)
	local str, len = write_many(addr, filename, ...)
	printh(str, "@clip")
	return len
end

function write_module(module_header, addr, module_data, ...)
	local str, len = write_many(addr, module_data, ...)
	printh(str, module_header, true)
	return len
end
