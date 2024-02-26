-- inlined statement sequence, returns the last expression
-- significantly improves performance compared to `(id s1 s2 s3 ...)`

-- 42 tokens, inlines up to 3 before looping
function builtin.seq(...)
	local n, s1, s2, s3 = parens8[[
		(fn (exp) ((fn (lookup e1 e2 e3) 
			((fn (s1 s2) (id (mid 3 (rawlen exp)) s1 s2 (when e3
				((rawget builtin "seq") lookup (unpack exp 3))))
			) (compile_n lookup e1 e2))
		) (deli exp 1) (unpack exp)))
	]]{...}
	return select(n,
		s1,function(frame)
			s1(frame)
			return s2(frame)
		end,function(frame)
			s1(frame)
			s2(frame)
			return s3(frame)
		end)
end

-- 59 tokens, inlines up to 4 before looping
-- function builtin.seq(...)
-- 	local n, s1, s2, s3, s4 = parens8[[
-- 		(fn (exp) ((fn (lookup e1 e2 e3 e4) 
-- 			((fn (s1 s2 s3) (id (mid 4 (rawlen exp)) s1 s2 s3 (when e4
-- 				((rawget builtin "seq") lookup (unpack exp 4))))
-- 			) (compile_n lookup e1 e2 e3))
-- 		) (deli exp 1) (unpack exp)))
-- 	]]{...}
-- 	return select(n,
-- 		s1,function(frame)
-- 			s1(frame)
-- 			return s2(frame)
-- 		end,function(frame)
-- 			s1(frame)
-- 			s2(frame)
-- 			return s3(frame)
-- 		end,function(frame)
-- 			s1(frame)
-- 			s2(frame)
-- 			s3(frame)
-- 			return s4(frame)
-- 		end)
-- end
