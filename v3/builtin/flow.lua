-- if you don't feel like using IIFEs
-- (let ((a 42) (b "foo")) (print (.. b a)))
function builtin:let(exp2, exp3)
	local names, values = {}, {}
	for binding in all(exp2) do
		add(names, binding[1])
		add(values, binding[2])
	end
	return compile({{"fn", names, exp3}, unpack(values)}, self)
end

-- (while (< x 3) (set x (+ 1 x))
def_builtin("while", function (frame, a1, a2)
	while (a1(frame)) a2(frame)
end)

-- (for (i 1 10 2) (body))
-- (for ((k v) (pairs foo)) (body))
builtin["for"] = function(lookup, exp2, exp3)
	local numeric = #exp2 > 2
	local cbody = compile({"fn", numeric and {exp2[1]} or exp2[1], exp3}, lookup)
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
