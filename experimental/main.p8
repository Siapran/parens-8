pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- #include parens8_continuation.lua
-- #include ../v3/parens8.lua
-- #include ../v4/parens8.lua
#include ../v4/parens8_tailcall.lua
#include ../examples/profiler.lua
-- 
-- parens8[[
-- (rawset builtin "loop" (fn (lookup exp2 exp3) (compile
-- 	(pack (pack "fn" (pack "__ps8_loop") (pack "id"
-- 		(pack "set" "__ps8_loop" (pack "fn" (pack)
-- 			(pack "when" exp2 (pack "__ps8_loop" exp3))
-- 		))
-- 		(pack "__ps8_loop")
-- 	)))
-- 	lookup
-- )))
-- ]]

-- function fun_lua(cond, a, b, c)
-- 	if cond then
-- 		return pack(a, b, c)
-- 	end
-- end

-- parens8[[
-- (set fun_ps8 (fn (cond a b c)
-- 	(when cond (pack a b c))
-- ))
-- ]]

-- -- parens8[[
-- -- ((fn (x) (print x)) 42)
-- -- (set x 42)
-- -- ]]

-- -- ?x

-- -- prof({locals={fun_lua, fun_ps8}},
-- -- function(a, b)
-- -- 	return a(true, 1, 2, 3)
-- -- end,function(a, b)
-- -- 	return b(true, 1, 2, 3)
-- -- end)

-- function inc(x) return x + 1 end

-- parens8[[
-- (set search (fn (match) (callcc (fn (return i) (id
-- 	(set i 0)
-- 	(loop 1 (when (match i) (return i) (set i (inc i))))
-- )))))
-- ]]