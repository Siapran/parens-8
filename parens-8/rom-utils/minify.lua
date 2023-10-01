function minify(str)
	local function minify_(acc, str, strip)
		if (str == "") return acc
		local found, c = find(str, function(x)
				return not any' \n\t'(x)
			end)
		local boundary = any'\'"()'(c)
		local space = (boundary or strip) and "" or " "
		if (found > 1) return minify_(acc .. space, sub(str, found), boundary)
		if any'\'"'(c) then
			local close = find(sub(str, 2), any(c))
			return minify_(acc .. sub(str, 1, close + 1),
				           sub(str, close + 2), true)
		end
		return minify_(acc .. c, sub(str, 2), boundary)
	end
	return minify_("", str, true)
end
