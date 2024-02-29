-- local _ENV = self; x = 42
-- (env self (set x 42))
parens8[[
(fn (closure) (rawset builtin "env" (fn (lookup exp1 exp2) ((fn (key)
	(closure key (compile exp1 lookup)
		(compile exp2 (fn (name)
			((fn (idx where) (id
				idx (when (tonum (tostring idx)) where key)
			)) (lookup name))
		)))
) (pack)))))
]](function (key, mapped, body)
	return function(frame)
		frame[1][key] = mapped(frame)
		return body(frame)
	end
end)

-- to save you the trouble of capturing all the globals by hand
-- (capture_api (env foo (print bar)))
-- this is more or less what pico-8 does internally at launch
-- in our case, this captures global names *at the parens8[[...]] invocation*
parens8[[
(fn (_ENV) (rawset builtin "capture_api" (fn (lookup exp) (
	(fn (names keys) (select -1
		(set keys (fn (k) (when k (keys (next _ENV k) (add names k)))))
		(keys (next _ENV))
		(compile (pack (pack "fn" names exp) (unpack names)) lookup)
	))
	(pack)
))))
]](_ENV)
