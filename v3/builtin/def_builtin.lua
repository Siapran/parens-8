function def_builtin(name, fn)
	builtin[name] = function(...)
		local a1, a2 = compile_n(...)
		return function(frame) return fn(frame, a1, a2) end
	end
end
