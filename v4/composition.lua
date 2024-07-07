f1 = function(x) return x + 1 end
f2 = function(x) return x * 2 end

f2(f1(3))

f3 = function(x)
	return f2(f1(x))
end

function compose(a, b)
	return function(x)
		return a(b(x))
	end
end
function id(...) return ... end

function bn(n)
	if (n == 0) return id
	if (n == 1) return compose
	return compose(bn(n - 1), compose)
end

b0 = bn(0)
b1 = bn(1)
b2 = bn(2)

halt = id
function ret(n) return function(k) return k(n) end end

function sub(k) return function(m) return function(n)
	return k(m - n)
end end end

function eval(e)
	local function eval_(e) return function(k)
		if (type(e) == "number") return ret(e)
		return b1(eval_(e[1]))(b2(eval_(e[2])(sub)))
	end end
	return eval_(e)(halt)
end