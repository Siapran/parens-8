def_builtin("neg", function(ev) return -ev(2) end)
def_builtin("+", function(ev) return ev(2)+ev(3) end)
def_builtin("-", function(ev) return ev(2)-ev(3) end)
def_builtin("*", function(ev) return ev(2)*ev(3) end)
def_builtin("/", function(ev) return ev(2)/ev(3) end)
def_builtin("\\", function(ev) return ev(2)\ev(3) end)
def_builtin("%", function(ev) return ev(2)%ev(3) end)
def_builtin("^", function(ev) return ev(2)^ev(3) end)

def_builtin("<", function(ev) return ev(2)<ev(3) end)
def_builtin(">", function(ev) return ev(2)>ev(3) end)
def_builtin("==", function(ev) return ev(2)==ev(3) end)
def_builtin("~=", function(ev) return ev(2)~=ev(3) end)

def_builtin("..", function(ev) return ev(2)..ev(3) end)

def_builtin("or", function(ev) return ev(2) or ev(3) end)
def_builtin("and", function(ev) return ev(2) and ev(3) end)
def_builtin("not", function(ev) return not ev(2) end)

def_builtin("#", function(ev) return #ev(2) end)
def_builtin("[]", function(ev, exp)
	if (exp[4]) ev(2)[ev(3)] = ev(4)
	return ev(2)[ev(3)]
end)
