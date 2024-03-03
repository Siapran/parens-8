-- parens-8 v3
-- a lisp interpreter by three rodents

function parens8(code)
	_pstr, _ppos = "id " .. code .. ")", 0
	return compile({parse()}, function(name) return name, 1 end){{_ENV}}
end

function id(...) return ... end

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

function compile_n(lookup, exp, ...)
	if (exp) return compile(exp, lookup), compile_n(lookup, ...)
end

function compile(exp, lookup)
	if type(exp) == "string" then
		local idx, where = lookup(exp)
		return where
			and function(frame) return frame[1][where][idx] end
			or function(frame) return frame[idx] end
	end
	if (type(exp) == "number") return function() return exp end

	local op = deli(exp, 1)
	if (builtin[op]) return builtin[op](lookup, unpack(exp))

	local function ret(s1, ...)
		local s2 = ... and ret(...)
		return s2 and function(frame)
			return s1(frame), s2(frame)
		end or s1
	end
	local fun, args =
		compile(op, lookup), ret(compile_n(lookup, unpack(exp)))
	return args and function(frame)
		return fun(frame)(args(frame))
	end or function(frame)
		return fun(frame)()
	end
end

function builtin:quote(exp1) return function() return exp1 end end

function builtin:fn(exp1, exp2)
	local locals, captures, key, close =
		parens8[[(quote ()) (quote ()) (quote ())]]
	for i,v in inext, exp1 do locals[v] = i end
	local body = compile(exp2, function(name)
		local idx = locals[name]
		if (idx) return idx + 1, false
		local idx, where = self(name)
		if where then captures[where] = true
		else close = true end
		return idx, where or key
	end)
	return close
		and function(frame)
			local upvals = {[key] = frame}
			for where in next, captures do
				upvals[where] = frame[1][where]
			end
			return function(...)
				return body{upvals, ...}
			end
		end
		or function(frame)
			return function(...)
				return body{frame[1], ...}
			end
		end
end

parens8[[
(fn (closure) (rawset builtin "when" (fn (lookup e1 e2 e3)
	(closure (compile_n lookup e1 e2 e3))
)))
]](function(a1, a2, a3) return
	function(frame)
		if (a1(frame)) return a2(frame)
		if (a3) return a3(frame)
	end
end)

parens8[[
(fn (closures) (rawset builtin "set" (fn (lookup exp1 exp2)
	((fn (compiled idx where)
		(select (when where 1 2)
			(closures compiled idx where)
		)
	) (compile exp2 lookup) (lookup exp1))
)))
]](function(compiled, idx, where) return
	function(frame) frame[1][where][idx] = compiled(frame) end,
	function(frame) frame[idx] = compiled(frame) end
end)
