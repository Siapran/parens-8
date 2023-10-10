-- parens-8
-- a lisp interpreter by twomice

function zip(keys, values)
	local res = {}
	for i=1,#keys do
		res[keys[i]] = values[i]
	end
	return res
end

local _pstr
local _ppos

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
	local token = consume' \n\t()'
	return tonum(token) or token, parse(0)
end

builtin = {}

local function eval(exp)
	if (type(exp) == "string") return function(env) return env[exp] end
	if (type(exp) == "number") return function() return exp end
	local n = #exp
	local op = builtin[exp[1]]
	local compiled = {}
	for i=1,n do compiled[i] = eval(exp[i]) end
	if (op) return op(exp, unpack(compiled, 2))

	return function(env)
		local function apply(i)
			if (i < n) return compiled[i](env), apply(i + 1)
			if (i == n) return compiled[i](env)
		end
		return compiled[1](env)(apply(2))
	end
end

function builtin:quote() return function() return self[2] end end
function builtin:set(_, a2)
	return function(env) env[self[2]] = a2(env) end
end
function builtin:when(a1, a2, a3)
	return function(env)
		if (a1(env)) return a2(env)
		if (a3) return a3(env)
	end
end
function builtin:fn(_, a2)
	return function(env)
		return function(...)
			return a2(setmetatable(
				zip(self[2], {...}),
				{__index = env, __newindex = env}))
		end
	end
end

function id(...) return ... end

function parens8(code)
	_pstr, _ppos = "id " .. code .. ")", 0
	return eval({parse()})(_ENV)
end
