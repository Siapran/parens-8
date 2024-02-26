-- parens-8 v3
-- a lisp interpreter by twomice

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

function id(...) return ... end

builtin = {}

function compile_n(lookup, exp, ...)
	if (exp) return compile(exp, lookup), compile_n(lookup, ...)
end

function compile(exp, lookup)
	if type(exp) == "string" then
		local fields = split(exp, ".")
		exp = deli(fields, 1)
		local idx, where = lookup(exp)

		if fields[1] then
			local function view(tab)
				for field in all(fields) do tab = tab[field] end
				return tab
			end
			return where
				and function(frame) return view(frame[1][where][idx]) end
				or function(frame) return view(frame[idx]) end
		end

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

function builtin:quote(exp2) return function() return exp2 end end

function builtin:fn(exp2, exp3)
	local locals, captures, key =
		parens8[[(quote ()) (quote ()) (quote ())]]
	for i,v in ipairs(exp2) do locals[v] = i end
	local body = compile(exp3, function(name)
		local idx, where = locals[name]
		if idx then return idx + 1, false end
		idx, where = self(name)
		captures[where] = true
		return idx, where or key
	end)
	return captures[false]
		and function(frame)
			local upvals = {[key] = frame}
			for where in pairs(captures) do
				if (where) upvals[where] = frame[1][where]
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

function builtin.set(...)
	local fields, last, compiled, idx, where = parens8[[
		(fn (lookup exp2 exp3) ((fn (fields) (id
			fields
			(when (rawget fields 2) (deli fields))
			(compile exp3 lookup)
			(lookup (deli fields 1))
		)) (split exp2 ".")))
	]](...)

	if last then
		local function view(tab)
			for field in all(fields) do tab = tab[field] end
			return tab
		end
		return where
			and function(frame)
				view(frame[1][where][idx])[last] = compiled(frame)
			end
			or function(frame) view(frame[idx])[last] = compiled(frame) end
	end

	return where
		and function(frame) frame[1][where][idx] = compiled(frame) end
		or function(frame) frame[idx] = compiled(frame) end
end

function builtin.when(...)
	local a1, a2, a3 = compile_n(...)
	return function(frame)
		if (a1(frame)) return a2(frame)
		if (a3) return a3(frame)
	end
end

function parens8(code)
	_pstr, _ppos = "id " .. code .. ")", 0
	return compile({parse()}, function(name) return name, 1 end){{_ENV}}
end
