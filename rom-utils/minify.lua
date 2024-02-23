function minify(str)
	local function minify_(acc, delim, off)
		_ppos += off or 1
		local space = consume(' \n\t', true)
		space = delim and "" or sub(space, 1, 1)
		local c = _pstr[_ppos]
		if (not c) return acc
		-- if (c == ';') consume'\n' return minify_(acc)  -- comments support
		if (c == '(') return minify_(minify_(acc .. c, true), true)
		if (c == ')') return acc .. c
		if (c == '"' or c == "'") _ppos += 1 return minify_(acc .. c .. consume(c) .. c, true)
		return minify_(acc .. space .. consume' \n\t()\'"', false, 0)
	end
	_pstr, _ppos = str, 0
	return minify_("", true)
end