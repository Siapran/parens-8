-- parens-8
-- a lisp interpreter by twomice

function any(matches)
	return function(val)
		for match in all(matches) do
			if (val == match) return true
		end
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
		local strip, c = find(str, function(x)
				return not any' \n\t'(x)
			end)
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

function eval(exp, env)
	local function ev(i) return eval(exp[i], env) end
	if (type(exp) == "string") return env[exp]
	if (type(exp) == "number") return exp
	local n, op, ex2, ex3, ex4 = #exp, unpack(exp)
	if (op == "quote") return ex2
	if op == "if" then
		if (ev(2)) return ev(3)
		if (ex4) return ev(4)
	elseif op == "fn" then
		return function(...)
			return eval(ex3, setmetatable(
				zip(ex2, {...}),
				{__index = env, __newindex = env}))
		end
	elseif op == "def" then
		env[ex2] = ev(3)
	else
		local function apply(i)
			if (i < n) return ev(i), apply(i + 1)
			if (i == n) return ev(i)
		end
		return ev(1)(apply(2))
	end
end

function identity(...) return ... end

function parens8(code)
	return eval(parse("identity "..code), _ENV)
end
