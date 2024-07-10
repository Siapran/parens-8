pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- #include parens8_continuation.lua
-- #include ../v3/parens8.lua
-- #include ../v4/parens8.lua
-- #include ../v4/parens8_tailcall.lua
-- #include parens8_stack_tail.lua
-- #include parens8_exparray.lua
#include parens8_better_when.lua
-- #include ../misc/profiler.lua

parens8[[
(rawset builtin "loop" (fn (lookup exp2 exp3) (compile
	(pack (pack "fn" (pack "__ps8_loop") (pack "id"
		(pack "set" "__ps8_loop" (pack "fn" (pack)
			(pack "when" exp2 (pack "__ps8_loop" exp3))
		))
		(pack "__ps8_loop")
	)))
	lookup
)))
]]

parens8[[(loop 1 (print (stat 0)))]]


-- function fun_lua(cond, a, b, c)
-- 	if cond then if cond then
-- 		return pack(a, b, c)
-- 	end end
-- end

-- parens8[[
-- (set fun_ps8 (fn (cond a b c)
-- 	(when cond (when cond (pack a b c)))
-- ))
-- ]]

-- prof({locals={fun_lua, fun_ps8}},
-- function(a, b)
-- 	return a(true, 1, 2, 3)
-- end,function(a, b)
-- 	return b(true, 1, 2, 3)
-- end)

-- parens8[[
-- (set compose (fn (a b) (fn (x) (a (b x)))))
-- (set zero (fn () id))
-- (set one id)
-- (set succ (fn (n) (fn (f) (compose f (n f)))))
-- (set plus (fn (n m) (fn (f) (compose (n f) (m f)))))
-- (set mult (fn (n m) (compose n m)))

-- (set two (succ one))
-- (set five (plus two (succ two)))
-- (set ten (mult two five))

-- (set grow (fn (x) (pack 1 (unpack x))))
-- (set shrink (fn (x) (pack (unpack x 2))))
-- (set sum count)
-- ]] --[[
-- ]]
