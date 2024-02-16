-- parens-8
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

builtin = {}

function eval(exp, lookup)
	if type(exp) == "string" then
		local idx, where = lookup(exp)
		return where
			and function(_, upvals) return upvals[where][idx] end
			or function(frame) return frame[idx] end
	end
	if (type(exp) == "number") return function() return exp end

	local exp1, exp2, exp3 = unpack(exp)

	if exp1 == "fn" then
		local locals, captures, key = {}, {}, {}
		for i,v in ipairs(exp2) do locals[v] = i end
		local compiled = eval(exp3, function(name)
			local idx, where = locals[name]
			if idx then return idx, false end
			idx, where = lookup(name)
			captures[where] = true
			return idx, where or key
		end)
		return function(frame, upvals)
			local newupvals = {}
			for where in pairs(captures) do
				if where then newupvals[where] = upvals[where]
				else newupvals[key] = frame end
			end
			return function(...)
				return compiled({...}, newupvals)
			end
		end
	end

	local n, op, compiled = #exp, builtin[exp1], {}
	for term in all(exp) do add(compiled, eval(term, lookup)) end
	if (op) return op(exp, lookup, unpack(compiled, 2))

	return function(frame, upvals)
		local function apply(i)
			if (i < n) return compiled[i](frame, upvals), apply(i + 1)
			return compiled[i](frame, upvals)
		end
		if (n > 1) return compiled[1](frame, upvals)(apply(2))
	end
end

function builtin:quote() return function() return self[2] end end
function builtin:set(lookup, _, a2)
	local idx, where = lookup(self[2])
	return where
		and function(frame, upvals) upvals[where][idx] = a2(frame, upvals) end
		or function(frame, upvals) frame[idx] = a2(frame, upvals) end
end
function builtin:when(_, a1, a2, a3)
	return function(...)
		if (a1(...)) return a2(...)
		if (a3) return a3(...)
	end
end

function id(...) return ... end

function parens8(code)
	_pstr, _ppos = "id " .. code .. ")", 0
	return eval({parse()}, function(name) return name, 1 end)({}, {_ENV})
end
