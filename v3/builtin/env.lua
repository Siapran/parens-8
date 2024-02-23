-- local _ENV = self; x = 42
-- (env self (set x 42))
def_builtin("env", function(frame, a1, a2)
	-- frame[1][1] = a1()
	return a2(setmetatable(
		{setmetatable({a1(frame)}, {__index = frame[1]})},
		{__index = frame, __newindex = frame}))
end)

-- this version is slightly more convenient than above,
-- it falls back on the outer env when reading a missing field.
-- this means you don't have to explicitly capture all the global
-- functions like `print` or `foreach`, etc.
-- with this you can just do `(env foo (print bar))` without any issues.
-- of course, the other version works fine if you wrap your entire
-- code in a big `((fn (print foreach etc) (code)) print foreach etc)`.
-- so it's up to you, really. is it worth the tokens, perf, etc
def_builtin("env", function(frame, a1, a2)
	local target, fallback = a1(frame), frame[1][1]
	local proxy = setmetatable({}, {__index = function(self, field)
			local res = target[field]
			if (res == nil) return fallback[field]
			return res
		end, __newindex = target})
	return a2(setmetatable(
		{setmetatable({proxy}, {__index = frame[1]})},
		{__index = frame, __newindex = frame}))
end)

-- note: if you aren't particularly strapped for tokens, I'd recommend
--       using field syntax (a.b.c) instead. it'll be faster than setting up
--       all the metatable trickery above for every call.
--       the `[]` builtin is also an option, if a slightly inconvenient one.
--       or, y'know, `rawget` and `rawset` if you *really* need the tokens.