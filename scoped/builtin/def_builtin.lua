function def_builtin(name, fn)
	builtin[name] = function(lookup, ...)
		local a1, a2 = compile_n(lookup, ...)
		return function(frame) return fn(frame, a1, a2) end
	end
end
