function builtin:env(a1, a2)
	return function(env)
		local tab = a1(env)
		return a2(setmetatable(
			{}, {__index = function(_, key)
				if (tab[key] ~= nil) return tab[key]
				return env[key]
			end, __newindex = function(_, key, val)
				if tab[key] ~= nil then tab[key] = val
				else env[key] = val end
			end}))
	end
end
