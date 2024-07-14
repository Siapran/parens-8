-- parens-8 v3
-- a lisp interpreter by three rodents


function id(...) return ... end
function const(x) return function() return x end end

function consume(matches, inv)
	local start = _ppos
	while (function()
		for m in all(matches) do
			if (_pstr[_ppos] == m) return 1
		end
	end)() == inv do _ppos += 1 end
	return sub(_pstr, start, _ppos - 1)
end

function parse()
	_ppos += 1
	consume(' \n\t', 1)
	return char_parser(_pstr[_ppos])
end

function char_parser(c)
	if (c == "(") return {parse()}, parse()
	if (c == ")") return
	return token_parser(consume' \n\t()\'"')
end

function token_parser(token)
	_ppos -= 1
	return token, parse()
end

builtin = {}

function compile(exp, lookup)
	if (type(exp) == "function") return exp
	if type(exp) == "string" then
		local idx, where = lookup(exp)
		return where
			and function(frame) return frame[1][where][idx] end
			or function(frame) return frame[idx] end
	end

	local op = deli(exp, 1)
	if (builtin[op]) return builtin[op](exp, lookup)

	if op == "fn" then
		local e1 = exp[1]
		for i,v in inext, e1 do e1[v] = i end
		local body = compile(exp[2], function(name, key)
			local idx = e1[name]
			if (idx) return idx + 1, key
			return lookup(name, e1)
		end)
		return function(frame)
			local upvals = setmetatable({[e1] = frame}, {__index = frame[1]})
			return function(...) return body{upvals, ...} end
		end
	end

	local function ret(e, ...)
		if e then
			local a1, a2 = compile(e, lookup), ret(...)
			return a2 and function(frame)
				return a1(frame), a2(frame)
			end or a1
		end
	end

	local fun, args = ret(op), ret(unpack(exp)) or const()
	return function(frame)
		-- assert(fun(frame), tostring(op))
		return fun(frame)(args(frame))
	end
end

function parens8(code)
	_pstr, _ppos = code, 0
	-- return compile({parse()}, function(name) return name, 1 end){{_ENV}}
	return compile({parse()}, id){_ENV}
end


-- function __ps8_runtime(a1, a2, a3) return
-- 	function(frame)
-- 		if (a1(frame)) return a2(frame)
-- 		return a3(frame)
-- 	end,
-- 	function(frame) frame[1][a3][a2] = a1(frame) end,
-- 	function(frame) frame[a2] = a1(frame) end
-- end

-- parens8[[(fn (code) (foreach (split code) parens8))]][[
-- (rawset builtin (type (tostr builtin)) (fn (exp) (const (unpack exp))))
-- (rawset builtin (type id) (const id))
-- ,
-- ((fn (_ENV) (id
--     (rawset _ENV (string token_parser)
--         ((fn (prev) (fn (token)
--             ((fn (num) ((select (count (pack id num)) prev
--                                 (fn () (prev (const num))))
--                         token))
--              (tonum token))))
--          token_parser)))

--  )
--  ((all ((all (function))))))
-- ]]--[=[ optional, move this line down to enable
-- ]]


--     ((fn (mkparser) (id (mkparser (string ')) (mkparser (string "))))
--      (fn (c) (rawset _parsers c (fn (nil)
--          (id (const (consume c nil (consume c 1))) (parse))
--      ))))
--     (rawset _parsers (chr 59) (fn () (parse (consume (chr 10)))))

-- (rawset builtin (chr 119 104 101 110) (fn (exp lookup nil) (__ps8_runtime
-- 	(compile (rawget exp 1) lookup) (compile (rawget exp 2) lookup)
-- 	((select (count exp) 1 (const (const nil))
-- 		(fn () (compile (rawget exp 3) lookup)))))
-- ))
-- ]][[
-- (rawset builtin "set" (fn (exp lookup)
-- 	((fn (compiled idx where)
-- 		(select (when where 2 3) (__ps8_runtime compiled idx where)))
-- 	 (compile (rawget exp 2) lookup) (lookup (rawget exp 1)))
-- ))

-- ; constants: (nil), (true), (false)
-- ((fn (mkconst) (id (mkconst "nil")
--                    (mkconst "false" (rawequal 1 0))
--                    (mkconst "true" (rawequal 1 1))))
--  (fn (name val) (rawset builtin name (fn () (const val)))))

-- ; the "poor man's while", implemented as a tail recursion.
-- (rawset builtin "loop" (fn (lookup exp2 exp3) (compile
-- 	(pack (pack "fn" (pack "__ps8_loop") (pack "id"
-- 		(pack "set" "__ps8_loop" (pack "fn" (pack)
-- 			(pack "when" exp2 (pack "__ps8_loop" exp3))
-- 		))
-- 		(pack "__ps8_loop")
-- 	)))
-- 	lookup
-- )))

-- ; (let ((a 42) (b "foo")) (print (.. b a)))
-- (rawset builtin "let" (fn (lookup exp2 exp3) (
-- 	(fn (names values) (select 2
-- 		(foreach exp2 (fn (binding) (id
-- 			(add names (rawget binding 1))
-- 			(add values (rawget binding 2))
-- 		)))
-- 		(compile (pack (pack "fn" names exp3) (unpack values)) lookup)
-- 	))
-- 	(pack) (pack)
-- )))
-- ]=]
