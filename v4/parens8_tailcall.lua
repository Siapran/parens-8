-- parens-8 v3
-- a lisp interpreter by three rodents

function id(...) return ... end

function parens8(code)
	_pstr, _ppos = "id " .. code .. ")", 0
	return compile({parse()}, function(name) return name, 1 end)(id)
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
	-- if (c == ';') consume'\n' return parse()  -- comments support
	if (c == '(') return {parse()}, parse()
	if (c == ')') return
	if (c == '"' or c == "'") _ppos += 1 return {"quote", consume(c)}, parse()
	local token = consume' \n\t()\'"'
	return tonum(token) or token, parse(0)
end

builtin = {}

function dot(a, b)
	return function(...)
		return a(b(...))
	end
end

function compile_n(lookup, exp, ...)
	if (exp) return compile(exp, lookup), compile_n(lookup, ...)
end

local _frame, _upvalues = {}, {_ENV}

function compile(exp, lookup)
	if type(exp) == "string" then
		local idx, where = lookup(exp)
		return where
			and function(k) return k(_upvalues[where][idx]) end
			or function(k) return k(_frame[idx]) end
	end
	if (type(exp) == "number") return function(k) return k(exp) end

	local op = deli(exp, 1)
	if (builtin[op]) return builtin[op](lookup, unpack(exp))

	local function ret(s1, ...)
		local s2 = ... and ret(...)
		return s2 and function(k)
			return s1(function(val)
				return s2(function(...)
					return k(val, ...)
				end)
			end)
		end or s1
	end
	local fun, args =
		compile(op, lookup), ret(compile_n(lookup, unpack(exp)))
	return args and function(k)
		return fun(function(fun)
			return args(function(...)
				return fun(k)(...)
			end)
		end) 
	end or function(k)
		return fun(function(fun) return fun(k)() end)
	end
end

function builtin:quote(exp1)
	return function(k) return k(exp1) end
end

function builtin:fn(exp1, exp2)
	local locals, captures, key, close =
		parens8[[(quote ()) (quote ()) (quote ())]]
	for i,v in inext, exp1 do locals[v] = i end
	local body = compile(exp2, function(name)
		local idx = locals[name]
		if (idx) return idx, false
		local idx, where = self(name)
		if where then captures[where] = true
		else close = true end
		return idx, where or key
	end)
	return close
		and function(k)
			local upvals = {[key] = _frame}
			for where in next, captures do
				upvals[where] = _upvalues[where]
			end
			return k(function(k) return function(...)
				local frame, upvalues = _frame, _upvalues
				_frame, _upvalues = {...}, upvals
				return body(function(...)
					_frame, _upvalues = frame, upvalues
					return k(...)
				end)
			end end)
		end
		or function(k)
			return k(function(k) return function(...)
				local frame = _frame
				_frame = {...}
				return body(function(...)
					_frame = frame
					return k(...)
				end)
			end end)
		end
end

function builtin:callcc(exp1)
	local compiled = compile(exp1, self)
	return function(k)
		return fun(function(fun) return fun(k)(k) end)
	end
end

-- builtin["return"] = function(lookup, exp1)
-- 	return function(k) return k(exp1) end
-- end

-- parens8[[
-- (fn (closure) (rawset builtin "when" (fn (lookup e1 e2 e3)
-- 	(closure (compile_n lookup e1 e2 e3))
-- )))
-- ]](function(a1, a2, a3) return
-- 	function(k)
-- 		return a1(function(val)
-- 			if (val) return a2(k)
-- 			if (a3) return a3(k)
-- 		end)
-- 	end
-- 	-- function(k)
-- 	-- 	return a1(dot(k, function(val)
-- 	-- 		if (val) return a2()
-- 	-- 		if (a3) return a3()
-- 	-- 	end))
-- 	-- end
-- end)

-- parens8[[
-- (fn (closures) (rawset builtin "set" (fn (lookup exp1 exp2)
-- 	((fn (compiled idx where)
-- 		(select (when where 1 2)
-- 			(closures compiled idx where)
-- 		)
-- 	) (compile exp2 lookup) (lookup exp1))
-- )))
-- ]](function(compiled, idx, where) return
-- 	function(k) return compiled(function(val)
-- 		_upvalues[where][idx] = val return k()
-- 	end) end,
-- 	function(k) return compiled(function(val)
-- 		_frame[idx] = val return k()
-- 	end) end
-- end)
