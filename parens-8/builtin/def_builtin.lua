function def_builtin(name, fn)
	builtin[name] = function(exp, env, ev) return fn(ev, exp, env) end
end
