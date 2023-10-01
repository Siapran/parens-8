
function builtin:env(env, ev)
	local tab = ev(2)
	return eval(self[3], setmetatable(
		{}, {__index = function(ev, key)
			if (tab[key] ~= nil) return tab[key]
			return env[key]
		end, __newindex = tab}))
end
