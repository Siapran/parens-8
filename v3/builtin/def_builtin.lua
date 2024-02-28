-- for builtins that don't alter the compilation of child expressions
parens8[[
(set def_builtin (fn (name fun)
	(rawset builtin name (fn (lookup ex1 ex2 ex3)
		(fun (compile_n lookup ex1 ex2 ex3))
	))
))
]]
