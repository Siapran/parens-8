pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

#include ../v3/parens8.lua
#include ../v3/builtin/def_builtin.lua
#include ../v3/builtin/operators.lua
#include ../v3/builtin/flow.lua
#include ../v3/builtin/env.lua
-- #include ../v3/builtin/table.lua

-- parens8[[
-- (set foo (fn (a ...)
-- 	(when a
-- 		(id (print a) (foo ...))
-- 	)
-- ))

-- (set tab (zip (split "a,b,c,d") (pack 1 2 3 4)))

-- ((fn (pr) (pr (env tab pr))) print)
-- ]]

-- parens8[[
-- (set foo (table (x 20) (y 20) (hello (fn () (print "hello!"))) (0 0) 1 2 3 4 5))
-- ]]

-- parens8[[
-- (set noop (fn () (quote)))
-- (let ((i 3) (j (quote)))
-- 	(loop (> i 0) (noop
-- 		(set j 3)
-- 		(loop (> j 0) (noop
-- 			(print (.. i (.. " " j)))
-- 			(set j (- j 1))
-- 		))
-- 		(set i (- i 1))
-- 	))
-- )
-- ]]

x = 1
foo = {x = 2}

parens8[[
(print x)
((fn (print id) (env foo (id
	(print x)
	(set x 3)
	(print x)
))) print id)
(print x)
]]
