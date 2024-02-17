-- slightly simplified: {[0] = 1} works, but not {[foo] = 1}
-- (table (foo 1) (0 2) 3 4 5 6)
-- (table (x 1) (y 2))
function builtin:table(...)
	local steps = {}
	for element in all{...} do
		if type(element) == "table" then
			local key, compiled = element[1], compile(element[2], self)
			add(steps, function(frame, res)
				res[key] = compiled(frame)
			end)
		else
			local compiled = compile(element, self)
			add(steps, function(frame, res)
				add(res, compiled(frame))
			end)
		end
	end
	return function(frame)
		local res = {}
		for step in all(steps) do
			step(frame, res)
		end
		return res
	end
end
