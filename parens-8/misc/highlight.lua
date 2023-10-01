function parencol(i)
	local colors = "9ade"
	return "\f" .. colors[i % #colors + 1]
end

function highlight(str, depth)
	depth = depth or 0
	local res = ""
	while #str > 0 do
		local strip, c = find(str, function(x)
				return not any' \n\t'(x)
			end)
		res ..= sub(str, 1, strip - 1)
		str = sub(str, strip)
		if c == '(' then
			local nested, rest = highlight(sub(str, 2), depth + 1)
			res ..= parencol(depth) .. c .. nested
			str = rest
		elseif c == ')' then
			if (depth == 0) return res, str
			return res .. parencol(depth - 1) .. c, sub(str, 2)
		elseif any'\'"'(c) then
			local close = find(sub(str, 2), any(c))
			res ..= "\fb" .. sub(str, 1, close + 1)
			str = sub(str, close + 2)
		else
			local close = find(str, any' \n\t()"\'')
			local token = sub(str, 1, close - 1)
			res ..= (tonum(token) and "\fc" or "\f7") .. token
			str = sub(str, close)
		end
	end
	return res, str
end
