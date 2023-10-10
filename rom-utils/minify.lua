function minify(str)
	local function any(matches)
		return function(v)
			for m in all(matches) do
				if (v == m) return true
			end
		end
	end

	local function minify_(acc, off)
		_ppos += off or 1
		local last = _pstr[_ppos - 1]
		local space = consume(' \n\t', true)
		space = any'\'"()'(last)
			and "" or sub(space, 1, 1)
		local c = _pstr[_ppos]
		if (not c) return acc
		if (c == '(') return minify_(minify_(acc .. c))
		if (c == ')') return acc .. c
		if (any'\'"'(c)) _ppos += 1 return minify_(acc .. c .. consume(c) .. c)
		return minify_(acc .. space .. consume' \n\t()', 0)
	end
	_pstr, _ppos = str, 0
	return minify_("")
end