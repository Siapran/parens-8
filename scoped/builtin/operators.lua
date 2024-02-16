function def_builtin(name, fn)
	builtin[name] = function(exp, lookup, a1, a2)
		return function(env) return fn(env, a1, a2) end
	end
end

def_builtin("neg", function(env, a1) return -a1(env) end)
def_builtin("+", function(env, a1, a2) return a1(env)+a2(env) end)
def_builtin("-", function(env, a1, a2) return a1(env)-a2(env) end)
def_builtin("*", function(env, a1, a2) return a1(env)*a2(env) end)
def_builtin("/", function(env, a1, a2) return a1(env)/a2(env) end)
def_builtin("\\", function(env, a1, a2) return a1(env)\a2(env) end)
def_builtin("%", function(env, a1, a2) return a1(env)%a2(env) end)
def_builtin("^", function(env, a1, a2) return a1(env)^a2(env) end)

def_builtin("<", function(env, a1, a2) return a1(env)<a2(env) end)
def_builtin(">", function(env, a1, a2) return a1(env)>a2(env) end)
def_builtin("==", function(env, a1, a2) return a1(env)==a2(env) end)
def_builtin("~=", function(env, a1, a2) return a1(env)~=a2(env) end)

def_builtin("..", function(env, a1, a2) return a1(env)..a2(env) end)

def_builtin("or", function(env, a1, a2) return a1(env) or a2(env) end)
def_builtin("and", function(env, a1, a2) return a1(env) and a2(env) end)
def_builtin("not", function(env, a1, a2) return not a1(env) end)

def_builtin("#", function(env, a1) return #a1(env) end)
builtin["[]"] = function(exp, a1, a2, a3)
	return function(env)
		if (a3) a1(env)[a2(env)] = a3(env)
		return a1(env)[a2(env)]
	end
end
