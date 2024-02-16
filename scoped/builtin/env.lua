def_builtin("env", function (frame, a1, a2)
	-- frame[1][1] = a1()
	local newframe = setmetatable(
		{setmetatable({a1(frame)}, {__index = frame[1]})},
		{__index = frame, __newindex = frame})
	for k in pairs(frame) do
		print(tostr(k) .. ": " .. tostr(newframe[k]))
	end
	return a2(newframe)
end)