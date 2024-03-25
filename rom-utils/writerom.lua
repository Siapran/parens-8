function writerom(str, addr, filename)
	local target = filename and 0x8000 or addr
	assert(addr + #str > addr, "string does not fit in cart ROM")
	poke(target, ord(str, 1, #str))
	cstore(addr, target, #str, filename)
	return #str
end

-- make sure you include minify.lua
function write_many(addr, filename, ...)
	local function iterate(acc, a, head, ...)
		if (not head) return acc
		local len = writerom(minify(head), a, filename)
		acc ..= "(parens8 (readrom " .. sub(tostr(a, 1), 1, 6) .. " " .. len
		if (filename) acc ..= ' "' .. filename .. '"'
		acc ..= "))\n"
		return iterate(acc, a + len, ...)
	end
	return iterate("parens8[[\n", addr, ...) .."]]"
end

function write_clipboard(addr, filename, ...)
	printh(write_many(addr, filename, ...), "@clip")
end

function write_module(module_header, module_data, ...)
	printh(write_many(0, module_data, ...), module_header, true)
end
