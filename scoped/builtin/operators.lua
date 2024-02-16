function def_builtin(name, fn)
	builtin[name] = function(exp, lookup, a1, a2)
		return function(frame, upvalues)
			return fn(
				function() return a1(frame, upvalues) end,
				function() return a2(frame, upvalues) end)
		end
	end
end

def_builtin("neg", function(a1) return -a1() end)
def_builtin("+", function(a1, a2) return a1()+a2() end)
def_builtin("-", function(a1, a2) return a1()-a2() end)
def_builtin("*", function(a1, a2) return a1()*a2() end)
def_builtin("/", function(a1, a2) return a1()/a2() end)
def_builtin("\\", function(a1, a2) return a1()\a2() end)
def_builtin("%", function(a1, a2) return a1()%a2() end)
def_builtin("^", function(a1, a2) return a1()^a2() end)

def_builtin("<", function(a1, a2) return a1()<a2() end)
def_builtin(">", function(a1, a2) return a1()>a2() end)
def_builtin("==", function(a1, a2) return a1()==a2() end)
def_builtin("~=", function(a1, a2) return a1()~=a2() end)

def_builtin("..", function(a1, a2) return a1()..a2() end)

def_builtin("or", function(a1, a2) return a1() or a2() end)
def_builtin("and", function(a1, a2) return a1() and a2() end)
def_builtin("not", function(a1, a2) return not a1() end)

def_builtin("#", function(env, a1) return #a1(env) end)
builtin["[]"] = function(exp, lookup, a1, a2, a3)
	return function(...)
		if (a3) a1(...)[a2(...)] = a3(...)
		return a1(...)[a2(...)]
	end
end
