-- if you don't feel like using IIFEs
-- (let ((a 42) (b "foo")) (print (.. b a)))

-- function builtin:let(exp2, exp3)
-- 	local names, values = {}, {}
-- 	for binding in all(exp2) do
-- 		add(names, binding[1])
-- 		add(values, binding[2])
-- 	end
-- 	return compile({{"fn", names, exp3}, unpack(values)}, self)
-- end

parens8[[
(rawset builtin "let" (fn (lookup exp2 exp3) (
	(fn (names values) (select 2
		(foreach exp2 (fn (binding) (id
			(add names (rawget binding 1))
			(add values (rawget binding 2))
		)))
		(compile (pack (pack "fn" names exp3) (unpack values)) lookup)
	))
	(quote ()) (quote ())
)))

(rawset builtin "loop" (fn (lookup exp2 exp3) (compile
	(pack (pack "fn" (pack "__ps8_loop") (pack "id"
		(pack "set" "__ps8_loop" (pack "fn" (pack)
			(pack "when" exp2 (pack "__ps8_loop" exp3))
		))
		(pack "__ps8_loop")
	)))
lookup)))
]]

-- the "loop" builtin is a "poor man's while", implemented as a tail recursion.
-- thanks to lua, such an implementation will not blow up the stack.
-- if you're really strapped for tokens, it will at least save you the headache
-- of implementing a tail recursion loop correctly yourself.

-- (fn (__ps8_loop) (id
-- 	(set __ps8_loop (fn () 
-- 		(when exp2 (__ps8_loop exp3))
-- 	))
-- 	(__ps8_loop)
-- ))

-- if you *really* need proper loops and can justify the token cost however...

-- (while (< x 3) (set x (+ 1 x))
def_builtin("while", function(frame, a1, a2)
	while (a1(frame)) a2(frame)
end)

-- (for (i 1 10 2) (body))
-- (for ((k v) (pairs foo)) (body))
builtin["for"] = function(lookup, exp2, exp3)
	local numeric = #exp2 > 2
	local cbody =
		compile({"fn", numeric and {exp2[1]} or exp2[1], exp3}, lookup)
	if numeric then
		local a, b, c = compile_n(lookup, unpack(exp2, 2))
		return function(frame)
			local body = cbody(frame)
			for i = a(frame), b(frame), c and c(frame) or 1 do
				body(i)
			end
		end
	else
		local iter = compile(exp2[2], lookup)
		return function(frame)
			local body, next, state, prev, vars = cbody(frame), iter(frame)
			repeat
				vars = {next(state, prev)}
				prev = vars[1]
				if (prev == nil) return
				body(unpack(vars))
			until false
		end
	end
end

-- here's your damn seq
-- returns the last expression
function builtin:seq(...)
	local compiled = {compile_n(self, ...)}
	local last = deli(compiled)
	return function(frame)
		for step in all(compiled) do
			step(frame)
		end
		return last(frame)
	end
end
-- was it worth it? just use id or select
