-- if you don't feel like using IIFEs
-- (let ((a 42) (b "foo")) (print (.. b a)))
function builtin:let(_, a2)
	local bound = {}
	for binding in all(self[2]) do
		bound[binding[1]] = compile(binding[2])
	end
	return function(env)
		local runbound = {}
		for k,v in pairs(bound) do runbound[k] = v(env) end
		return a2(setmetatable(
			runbound, {__index = env, __newindex = env}))
	end
end

-- (while (< x 3) (set x (+ 1 x))
def_builtin("while", function (env, a1, a2)
	while (a1(env)) a2(env)
end)

-- (for ((k v) (pairs foo)) (body))
builtin["for"] = function(exp, _, a2)
	local iter = compile(exp[2][2])
	return function(env)
		local next, state, prev = iter(env)
		repeat
			local vars = {next(state, prev)}
			prev = vars[1]
			if (prev == nil) return
			a2(setmetatable(
				zip(exp[2][1], vars),
				{__index = env, __newindex = env}))
		until false
	end
end
