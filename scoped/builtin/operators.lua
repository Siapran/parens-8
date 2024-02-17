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