function def_builtin(name, fn)
	builtin[name] = function(exp, a1, a2)
		return function(env) return fn(env, a1, a2) end
	end
end
