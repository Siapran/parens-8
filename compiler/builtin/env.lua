function builtin:env(a1, a2)
	return function(outer)
		local tab = a1(outer)
		return a2(setmetatable(
			{}, {__index = function(_, key)
				if (tab[key] ~= nil) return tab[key]
				return outer[key]
			end, __newindex = tab}))
	end
end
