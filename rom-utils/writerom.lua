function writerom(str, addr, filename)
	local target = filename and 0x8000 or addr
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
	local res = iterate("parens8[[\n", addr, ...) .."]]"
	print(res)
	printh(res, "@clip")
end
