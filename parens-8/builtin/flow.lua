-- if you don't feel like using IIFEs
-- (let ((a 42) (b "foo")) (print (.. b a)))
function builtin:let(env, ev)
	local bound = {}
	for binding in all(self[2]) do
		bound[binding[1]] = eval(binding[2], env)
	end
	return eval(self[3], setmetatable(
		bound, {__index = env, __newindex = env}))
end

-- (while (< x 3) (set x (+ 1 x))
def_builtin("while", function (ev, exp)
	while (ev(2)) ev(3)
end)

-- (for ((k v) (pairs foo)) (body))
def_builtin("for", function (ev, exp, env)
	local _f, _s, _var = eval(exp[2][2], env)
	repeat
		local vars = {_f(_s, _var)}
		_var = vars[1]
		if (_var == nil) return
		eval(exp[3], setmetatable(
			zip(exp[2][1], vars),
			{__index = env, __newindex = env}))
	until false
end)
