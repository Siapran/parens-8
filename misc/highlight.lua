function highlight(str)
	local function parencol(i)
		local colors = "9ade"
		return "\f" .. colors[i % #colors + 1]
	end

	local function highlight_(acc, depth, off)
		_ppos += off or 1
		acc ..= consume(' \n\t', true)
		local c = _pstr[_ppos]
		if not c then return acc
		-- elseif c == ';' then  -- comments support
		-- 	return highlight_(acc .. "\f5" .. consume'\n', depth, 0)
		elseif c == '(' then
			return highlight_(highlight_(acc .. parencol(depth) .. c, depth + 1), depth)
		elseif c == ')' then
			if (depth == 0) return acc, sub(_pstr, _ppos)
			return acc .. parencol(depth - 1) .. c
		elseif c == '"' or c == "'" then
			_ppos += 1
			return highlight_(acc .. "\fb" .. c .. consume(c) .. c, depth)
		end
		local token = consume' \n\t()\'"'
		return highlight_(
			acc .. (tonum(token) and "\fc" or "\f7") .. token, depth, 0)
	end

	_pstr, _ppos = str, 0
	return highlight_("", 0)
end