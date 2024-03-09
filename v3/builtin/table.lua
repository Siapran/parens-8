-- slightly simplified: {[0] = 1} works, {[foo] = 1} doesn't
-- (table (foo 1) (0 2) 3 4 5 6)
-- (table (x 1) (y 2))
function builtin.table(...)
	return parens8[[
	(fn (exp) ((fn (closures lookup construct) (select -1
		(set construct (fn (i elem) (when elem
			((fn (step) (when (count elem)
				(select 1 (closures
					step (compile (rawget elem 2) lookup) (rawget elem 1)))
				(select 2 (closures step (compile elem lookup)))
			)) (construct (inext exp i)))
			id
		)))
		(select 3 (closures (construct (inext exp))))
	)) (deli exp 1) (deli exp 1)))
	]]{function(step, elem, key) return
		function(res, frame)
			res[key] = elem(frame)
			return step(res, frame)
		end,
		function(res, frame)
			add(res, elem(frame))
			return step(res, frame)
		end,
		function(frame)
			return (step({}, frame))
		end
	end, ...}
end
