-- for builtins that don't alter the compilation of child expressions
function def_builtin(name, fun)
	builtin[name] = function(...)
		return fun(compile_n(...))
	end
end
