-- parens-8 v1
-- a lisp interpreter by twomice

function zip(keys, values)
	local res = {}
	for i=1,#keys do
		res[keys[i]] = values[i]
	end
	return res
end

function consume(matches, inv)
	local start = _ppos
	while (function()
		for m in all(matches) do
			if (_pstr[_ppos] == m) return true
		end
	end)() == inv do _ppos += 1 end
	return sub(_pstr, start, _ppos - 1)
end

function parse(off)
	_ppos += off or 1
	consume(' \n\t', true)
	local c = _pstr[_ppos]
	if (c == '(') return {parse()}, parse()
	if (c == ')') return
	if (c == '"' or c == "'") _ppos += 1 return {"quote", consume(c)}, parse()
	local token = consume' \n\t()\'"'
	return tonum(token) or token, parse(0)
end

local builtin = {}

local function eval(exp, env)
	local function ev(i) return eval(exp[i], env) end
	if (type(exp) == "string") return env[exp]
	if (type(exp) == "number") return exp
	local n = #exp
	local op = builtin[exp[1]]
	if (op) return op(exp, env, ev)
	local function apply(i)
		if (i < n) return ev(i), apply(i + 1)
		if (i == n) return ev(i)
	end
	return ev(1)(apply(2))
end

function builtin:quote() return self[2] end
function builtin:set(env, ev) env[self[2]] = ev(3) end
function builtin:when(env, ev)
	if (ev(2)) return ev(3)
	if (self[4]) return ev(4)
end
function builtin:fn(env)
	return function(...)
		return eval(self[3], setmetatable(
			zip(self[2], {...}),
			{__index = env, __newindex = env}))
	end
end

function id(...) return ... end

function parens8(code)
	_pstr, _ppos = "id " .. code .. ")", 0
	return eval({parse()}, _ENV)
end
