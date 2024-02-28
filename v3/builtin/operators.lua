def_builtin("neg", function(a1) return function(f) return -a1(f) end end)
def_builtin("+", function(a1, a2) return function(f) return a1(f)+a2(f) end end)
def_builtin("-", function(a1, a2) return function(f) return a1(f)-a2(f) end end)
def_builtin("*", function(a1, a2) return function(f) return a1(f)*a2(f) end end)
def_builtin("/", function(a1, a2) return function(f) return a1(f)/a2(f) end end)
def_builtin("\\", function(a1, a2) return function(f) return a1(f)\a2(f) end end)
def_builtin("%", function(a1, a2) return function(f) return a1(f)%a2(f) end end)
def_builtin("^", function(a1, a2) return function(f) return a1(f)^a2(f) end end)

def_builtin("<", function(a1, a2) return function(f) return a1(f)<a2(f) end end)
def_builtin(">", function(a1, a2) return function(f) return a1(f)>a2(f) end end)
def_builtin("==", function(a1, a2) return function(f) return a1(f)==a2(f) end end)
def_builtin("~=", function(a1, a2) return function(f) return a1(f)~=a2(f) end end)

def_builtin("..", function(a1, a2) return function(f) return a1(f)..a2(f) end end)

def_builtin("or", function(a1, a2) return function(f) return a1(f) or a2(f) end end)
def_builtin("and", function(a1, a2) return function(f) return a1(f) and a2(f) end end)
def_builtin("not", function(a1, a2) return function(f) return not a1(f) end end)

def_builtin("#", function(a1) return function(f) return -a1(f) end end)
def_builtin("[]", function(a1, a2, a3)
	return a3
		and function(f) a1(f)[a2(f)] = a3(f) end
		or function(f) return a1(f)[a2(f)] end
end)
