function def_builtin(name, fn)
	builtin[name] = function(exp, ...)
		local args = {...}
		return function(env) return fn(env, args) end
	end
end

def_builtin("neg", function(env, a) return -a[1](env) end)
def_builtin("+", function(env, a) return a[1](env)+a[2](env) end)
def_builtin("-", function(env, a) return a[1](env)-a[2](env) end)
def_builtin("*", function(env, a) return a[1](env)*a[2](env) end)
def_builtin("/", function(env, a) return a[1](env)/a[2](env) end)
def_builtin("\\", function(env, a) return a[1](env)\a[2](env) end)
def_builtin("%", function(env, a) return a[1](env)%a[2](env) end)
def_builtin("^", function(env, a) return a[1](env)^a[2](env) end)

def_builtin("<", function(env, a) return a[1](env)<a[2](env) end)
def_builtin(">", function(env, a) return a[1](env)>a[2](env) end)
def_builtin("==", function(env, a) return a[1](env)==a[2](env) end)
def_builtin("~=", function(env, a) return a[1](env)~=a[2](env) end)

def_builtin("..", function(env, a) return a[1](env)..a[2](env) end)

def_builtin("or", function(env, a) return a[1](env) or a[2](env) end)
def_builtin("and", function(env, a) return a[1](env) and a[2](env) end)
def_builtin("not", function(env, a) return not a[1](env) end)

def_builtin("#", function(env, a) return #a[2](env) end)
def_builtin("[]", function(env, a)
	if (a[3]) a[1](env)[a[2](env)] = a[3](env)
	return a[1](env)[a[2](env)]
end)