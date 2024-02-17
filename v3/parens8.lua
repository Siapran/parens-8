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

		-- uncomment for field syntax: (print a.b.c)

		-- local fields = split(exp, ".")
		-- exp = deli(fields, 1)

		local idx, where = lookup(exp)

		-- if fields[1] then
		-- 	local function view(tab)
		-- 		for field in all(fields) do tab = tab[field] end
		-- 		return tab
		-- 	end
		-- 	return where
		-- 		and function(frame) return view(frame[1][where][idx]) end
		-- 		or function(frame) return view(frame[idx]) end
		-- end

		-- uncomment for variadics support: (fn (foo ...) (foo ...))

		-- if exp == "..." then
		-- 	return where
		-- 		and function(frame) return unpack(frame[1][where], idx) end
		-- 		or function(frame) return unpack(frame, idx) end
		-- end

		return where
			and function(frame) return frame[1][where][idx] end
			or function(frame) return frame[idx] end
	end
	if (type(exp) == "number") return function() return exp end

	local op = builtin[exp[1]]
	if (op) return op(lookup, unpack(exp, 2))

	local n, compiled = #exp, {compile_n(lookup, unpack(exp))}
	return n < 2
		and function(frame)
			return compiled[1](frame)()
		end
		or function(frame)
			local function apply(i)
				if (i < n) return compiled[i](frame), apply(i + 1)
				return compiled[i](frame)
			end
			return compiled[1](frame)(apply(2))
		end
end

function builtin:fn(exp2, exp3)
	local locals, captures, key = {}, {}, {}
	for i,v in ipairs(exp2) do locals[v] = i end
	local compiled = compile(exp3, function(name)
		local idx, where = locals[name]
		if idx then return idx + 1, false end
		idx, where = self(name)
		captures[where] = true
		return idx, where or key
	end)
	return function(frame)
		local upvals = {}
		for where in pairs(captures) do
			if where then upvals[where] = frame[1][where]
			else upvals[key] = frame end
		end
		return function(...)
			return compiled{upvals, ...}
		end
	end
end

function builtin:quote(exp2) return function() return exp2 end end

function builtin:set(exp2, exp3)
	-- uncomment for field syntax: (set a.b.c 42)

	-- local fields = split(exp2, ".")
	-- exp2 = deli(fields, 1)
	-- local last = deli(fields)

	local compiled, idx, where = compile(exp3, self), self(exp2)

	-- if last then
	-- 	local function view(tab)
	-- 		for field in all(fields) do tab = tab[field] end
	-- 		return tab
	-- 	end
	-- 	return where
	-- 		and function(frame)
	-- 			view(frame[1][where][idx])[last] = compiled(frame)
	-- 		end
	-- 		or function(frame) view(frame[idx])[last] = compiled(frame) end
	-- end

	return where
		and function(frame) frame[1][where][idx] = compiled(frame) end
		or function(frame) frame[idx] = compiled(frame) end
end

function builtin:when(...)
	local a1, a2, a3 = compile_n(self, ...)
	return function(frame)
		if (a1(frame)) return a2(frame)
		if (a3) return a3(frame)
	end
end

function id(...) return ... end

function parens8(code)
	_pstr, _ppos = "id " .. code .. ")", 0
	return compile({parse()}, function(name) return name, 1 end){{_ENV}}
end
