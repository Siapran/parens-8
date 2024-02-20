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
builtin["[]"] = function(...)
	local a1, a2, a3 = compile_n(...)
	return a3
		and function(frame) a1(frame)[a2(frame)] = a3(frame) end
		or function(frame) return a1(frame)[a2(frame)] end
end