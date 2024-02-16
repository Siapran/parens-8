function def_builtin(name, fn)
	builtin[name] = function(lookup, ...)
		local a1, a2 = compile_n(lookup, ...)
		return function(frame) return fn(frame, a1, a2) end
	end
end

def_builtin("neg", function(frame, a1) return -a1(frame) end)
def_builtin("+", function(frame, a1, a2) return a1(frame)+a2(frame) end)
def_builtin("-", function(frame, a1, a2) return a1(frame)-a2(frame) end)
def_builtin("*", function(frame, a1, a2) return a1(frame)*a2(frame) end)
def_builtin("/", function(frame, a1, a2) return a1(frame)/a2(frame) end)
def_builtin("\\", function(frame, a1, a2) return a1(frame)\a2(frame) end)
def_builtin("%", function(frame, a1, a2) return a1(frame)%a2(frame) end)
def_builtin("^", function(frame, a1, a2) return a1(frame)^a2(frame) end)

def_builtin("<", function(frame, a1, a2) return a1(frame)<a2(frame) end)
def_builtin(">", function(frame, a1, a2) return a1(frame)>a2(frame) end)
def_builtin("==", function(frame, a1, a2) return a1(frame)==a2(frame) end)
def_builtin("~=", function(frame, a1, a2) return a1(frame)~=a2(frame) end)

def_builtin("..", function(frame, a1, a2) return a1(frame)..a2(frame) end)

def_builtin("or", function(frame, a1, a2) return a1(frame) or a2(frame) end)
def_builtin("and", function(frame, a1, a2) return a1(frame) and a2(frame) end)
def_builtin("not", function(frame, a1, a2) return not a1(frame) end)

def_builtin("#", function(frame, a1) return #a1(frame) end)
builtin["[]"] = function(lookup, ...)
	local a1, a2, a3 = compile_n(lookup, ...)
	return a3
		and function(frame) a1(frame)[a2(frame)] = a3(frame) end
		or function(frame) return a1(frame)[a2(frame)] end
end
