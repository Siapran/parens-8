-- parens-8
-- a lisp interpreter by twomice

function any(matches, inv)
	return function(val)
		for match in all(matches) do
			if (val == match) return not inv
		end
		return inv
	end
end

function find(list, pred)
	for i=1,#list do
		if (pred(list[i])) return i, list[i]
	end
	return #list + 1
end

function zip(keys, values)
	local res = {}
	for i=1,#keys do
		res[keys[i]] = values[i]
	end
	return res
end

function parse(str)
	local res = {}
	while #str > 0 do
		local strip, c = find(str, any(' \n\t', true))
		str = sub(str, strip)
		if c == '(' then
			local list, rest = parse(sub(str, 2))
			add(res, list)
			str = rest
		elseif c == ')' then
			return res, sub(str, 2)
		elseif any'\'"'(c) then
			local close = find(sub(str, 2), any(c))
			add(res, {"quote", sub(str, 2, close)})
			str = sub(str, close + 2)
		else
			local close = find(str, any' \n\t()"\'')
			local token = sub(str, 1, close - 1)
			add(res, tonum(token) or token)
			str = sub(str, close)
		end
	end
	return res, str
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
	return eval(parse("id "..code))(_ENV)
end
