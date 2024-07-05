parens8[[
(fn (closures) ((fn (ops loopfn) (select -1
	(set loopfn (fn (i op) (when i (loopfn (select 2
		(rawset builtin op (fn (lookup e1 e2 e3)
			(select i (closures (compile_n lookup e1 e2 e3)))
		))
		(inext ops i)
	)))))
	(loopfn (inext ops))
)) (split "+,-,*,/,\,%,^,<,>,==,~=,..,or,and,not,#,[]")))
]](function(a1, a2, a3) return
	function(f) return a1(f)+a2(f) end,
	a2 and function(f) return a1(f)-a2(f) end
		or function(f) return -a1(f) end,
	function(f) return a1(f)*a2(f) end,
	function(f) return a1(f)/a2(f) end,
	function(f) return a1(f)\a2(f) end,
	function(f) return a1(f)%a2(f) end,
	function(f) return a1(f)^a2(f) end,
	function(f) return a1(f)<a2(f) end,
	function(f) return a1(f)>a2(f) end,
	function(f) return a1(f)==a2(f) end,
	function(f) return a1(f)~=a2(f) end,
	function(f) return a1(f)..a2(f) end,
	function(f) return a1(f) or a2(f) end,
	function(f) return a1(f) and a2(f) end,
	function(f) return not a1(f) end,
	function(f) return #a1(f) end,
	a3 and function(f) a1(f)[a2(f)] = a3(f) end
		or function(f) return a1(f)[a2(f)] end
end)

parens8[[
(foreach (split "+,-,*,/,\,%,^,..") (fn (op)
	(rawset builtin (.. op "=") (fn (lookup e1 e2)
		(compile (pack "set" e1 (pack op e1 e2)) lookup)
	))
))
]]