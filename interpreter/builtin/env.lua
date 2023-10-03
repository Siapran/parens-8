function builtin:env(outer, ev)
	local tab = ev(2)
	return eval(self[3], setmetatable(
		{}, {__index = function(ev, key)
			if (tab[key] ~= nil) return tab[key]
			return outer[key]
		end, __newindex = tab}))
end
