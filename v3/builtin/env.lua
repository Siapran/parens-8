-- local _ENV = self; x = 42
-- (env self (set x 42))
def_builtin("env", function(frame, a1, a2)
	-- frame[1][1] = a1()
	return a2(setmetatable(
		{setmetatable({a1(frame)}, {__index = frame[1]})},
		{__index = frame, __newindex = frame}))
end)
