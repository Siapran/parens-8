pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- parens-8 sandbox   ~(>  <)~
-- by three rodents      <3)~
--[[----------------------------

the parens-8 extension language
  batteries included sandbox

--------------------------------
        ~(> overview <)~
--------------------------------
| tab 0 | usage guide          |
| tab 1 | (internals)          |
| tab 2 | your code here       |
--------------------------------

--------------------------------
       ~(> usage guide <)~
--------------------------------

😐? what's this? what's a lisp?
    i was promised more tokens!

~(> this is parens-8, a tiny,
    yet very fast and memory
    efficient extension
    language for pico-8.

    pick any lua function in
    your code, rewrite it in
    parens-8, store it as a
    string or in rom, then use
    it just like regular lua.

😐? but... how does that give
    me more tokens? 

~(> because parens-8 code can
    be stored as characters, it
    doesn't cost any tokens.
    every bit of code you 
    rewrite in parens-8 is that
    many tokens saved!

    the parens-8 interpreter
    does cost a bit of tokens
    (between 495 and 1021,
    depending on the features).
    it's a small investment
    that gives you functionally
    infinite tokens in return!

😐? so what's a lisp, and why
    not just use lua syntax?

~(> lisps are a family of
    programming languages that
    use lists of expressions as
    their main, and sometimes
    only syntax. it's an
    extremely simple syntax to
    parse and evaluate, which
    is how parens-8 manages to
    keep its token cost so low.
    
    parsing lua code would take
    a lot more tokens, whereas
    the parens-8 parser fits in
    in just 111 tokens!

😐? but isn't lisp weird and
    complicated? i don't want
    to learn a new language...

~(> parens-8 is a lisp because
    of its syntax, but it keeps
    most of the lua semantics
    you already know.
    
    let's look at an example.
    this is a lua function that
    prints all the elements of
    an array:

      function print_all(tab)
        for elem in all(tab) do
          print(elem)
        end
      end

    and this how you write the
    same function in parens-8:

      (set print_all (fn (tab)
        (for ((elem) (all tab))
          (print elem)
        )
      ))

    see? that wasn't so bad!
    the syntax is a bit weird,
    but you can use the same
    functions and control flow
    you would in lua... with
    one exception: you can't
    do early returns.

    in lisp, you don't have
    statements, you only have
    expressions. this means the
    following lua function:

      function add(a, b)
        return a + b
      end

    is written in parens-8 as:

      (set add (fn (a b)
        (+ a b)
      ))

    no return keyword in lisp!
    a lisp function is just one
    big return statement! if
    you look at a lua function
    that returns early:

      function min(a, b)
        if a < b then
          return a
        else
          return b
        end
      end
    
    the parens-8 equivalent is:

      (set min (fn (a b)
        (when (< a b)
          a
          b
        )
      ))

    the `when` keyword is like
    the `if` of lua, except it
    returns the result of the
    branch that was taken. it's
    like a less janky version
    of the lua ternary pattern:

      foo = cond and a or b

      (set foo (when cond a b))

    and that's pretty much all
    there is to it. if you
    understand this much, you
    shouldn't run into any
    suprises down the line.

😐? that's... weird, but ok.
    should i just write my
    entire game in parens-8?

~(> you can... but you probably
    shouldn't. on average,
    parens-8 is about 1/4th the
    speed of lua. this doesn't
    mean your entire game slows
    down if you use parens-8.
    i've written a game demo
    entirely in parens-8 and it
    runs surprisingly fast!

    remember, you can call lua
    and parens-8 functions from
    each other! you should
    keep performance critical
    code as lua and focus on
    translating the rest.
    things like:

      - your _draw and _update
        functions.
        these are only called
        once per frame!

      - any code that is called
        from _init. it's only
        called once per game!

      - complicated game logic
        that tends to be really
        expensive in tokens.
        code that's called in
        response to player
        actions, like playing a
        card, colliding with an
        other entity, etc.

    remember you can check the
    performance of your game
    with ctrl+p. the most cpu
    intensive parts of pico-8
    games tend to be:

      - the amount of pixels
        you're drawing on the
        screen per frame.
        this is completely
        unaffected by parens-8:
        it's the same drawing
        routines that are used
        from lua and parens-8!

      - physics engines and
        particle systems.
        these should really be
        kept in lua. writing
        tight loops in parens-8
        is usually a bad idea.

      - pathfinding, for the
        same reasons as above.
        write the pathfinder in
        lua, then call it from
        your parens-8 code.

😐? alright. anything else i
    should know? what was that
    about storing code in rom?

~(> if you like what you see,
    there's a more thorough
    guide on my github. it
    explains things like
    storing code in the rom of
    another cart and other
    clever tricks you can do
    with parens-8.

  github.com/siapran/parens-8/
    
]]------------------------------

-->8
-- internals

-- parens-8 v3
-- a lisp interpreter by three rodents

--------------------------------
-- core interpreter
-- field & variadics syntax
--------------------------------

function parens8(code)
	_pstr, _ppos = "id " .. code .. ")", 0
	return compile({parse()}, function(name) return name, 1 end){{_ENV}}
end

function id(...) return ... end

function consume(matches, inv)
	local start = _ppos
	while (function()
		for m in all(matches) do
			if (_pstr[_ppos] == m) return true
		end
	end)() == inv do _ppos += 1 end
	return sub(_pstr, start, _ppos - 1)
end

function parse(off)
	_ppos += off or 1
	consume(' \n\t', true)
	local c = _pstr[_ppos]
	if (c == ';') consume'\n' return parse()  -- comments support (optional)
	if (c == '(') return {parse()}, parse()
	if (c == ')') return
	if (c == '"' or c == "'") _ppos += 1 return {"quote", consume(c)}, parse()
	local token = consume' \n\t()\'"'
	return tonum(token) or token, parse(0)
end

builtin = {}

function compile_n(lookup, exp, ...)
	if (exp) return compile(exp, lookup), compile_n(lookup, ...)
end

function compile(exp, lookup)
	if type(exp) == "string" then
		local fields, variadic = split(exp, "."), exp == "..."
		if (fields[2] and not variadic) return fieldview(lookup, deli(fields, 1), fields)
		local idx, where = lookup(exp)
		if variadic then
			return where
				and function(frame) return unpack(frame[1][where], idx) end
				or function(frame) return unpack(frame, idx) end
		end
		return where
			and function(frame) return frame[1][where][idx] end
			or function(frame) return frame[idx] end
	end
	if (type(exp) == "number") return function() return exp end

	local op = deli(exp, 1)
	if (builtin[op]) return builtin[op](lookup, unpack(exp))

	local function ret(s1, ...)
		local s2 = ... and ret(...)
		return s2 and function(frame)
			return s1(frame), s2(frame)
		end or s1
	end
	local fun, args =
		compile(op, lookup), ret(compile_n(lookup, unpack(exp)))
	return args and function(frame)
		return fun(frame)(args(frame))
	end or function(frame)
		return fun(frame)()
	end
end

--------------------------------
-- core builtins
--------------------------------

function builtin:quote(exp2) return function() return exp2 end end

function builtin:fn(exp1, exp2)
	local locals, captures, key, close =
		parens8[[(quote ()) (quote ()) (quote ())]]
	for i,v in inext, exp1 do locals[v] = i end
	local body = compile(exp2, function(name)
		local idx = locals[name]
		if (idx) return idx + 1, false
		local idx, where = self(name)
		if where then captures[where] = true
		else close = true end
		return idx, where or key
	end)
	return close
		and function(frame)
			local upvals = {[key] = frame}
			for where in next, captures do
				upvals[where] = frame[1][where]
			end
			return function(...)
				return body{upvals, ...}
			end
		end
		or function(frame)
			return function(...)
				return body{frame[1], ...}
			end
		end
end

parens8[[
(fn (closure) (rawset builtin "when" (fn (lookup e1 e2 e3)
	(closure (compile_n lookup e1 e2 e3))
)))
]](function(a1, a2, a3) return
	function(frame)
		if (a1(frame)) return a2(frame)
		if (a3) return a3(frame)
	end
end)

parens8[[
(fn (closures) (rawset builtin "set" (fn (lookup exp1 exp2)
	((fn (compiled fields) ((fn (head tail) (when tail
		(select 3 (closures compiled tail (fieldview lookup head fields)))
		((fn (idx where) (select (when where 1 2)
			(closures compiled idx where)
		)) (lookup head))
	)) (deli fields 1) (deli fields))) (compile exp2 lookup) (split exp1 "."))
)))
]](function(compiled, idx, where) return
	function(frame) frame[1][where][idx] = compiled(frame) end,
	function(frame) frame[idx] = compiled(frame) end,
	function(frame) where(frame)[idx] = compiled(frame) end
end)

parens8[[
(fn (closure) (set fieldview (fn (lookup tab fields view) (select -1
	(set view (fn (step i field) (when field (view
		(closure step field)
		(inext fields i)
	) step)))
	(view (compile tab lookup) (inext fields))
))))
]](function(step, field)
	return function(frame)
		return step(frame)[field]
	end
end)

--------------------------------
-- optional builtins
--------------------------------
-- each of those code blocks
-- can be commented out if you
-- don't need the associated
-- feature.

--------------------------------
-- operators

parens8[[
(fn (closures) ((fn (ops loopfn) (select -1
	(set loopfn (fn (i op) (when i (loopfn (select 2
		(rawset builtin op (fn (lookup e1 e2 e3)
			(select i (closures (compile_n lookup e1 e2 e3)))
		))
		(inext ops i)
	)))))
	(loopfn (inext ops))
)) (split "+,-,*,/,\,%,^,<,>,==,~=,..,or,and,not,#,[]")))
]](function(a1, a2, a3) return
	function(f) return a1(f)+a2(f) end,
	a2 and function(f) return a1(f)-a2(f) end
		or function(f) return -a1(f) end,
	function(f) return a1(f)*a2(f) end,
	function(f) return a1(f)/a2(f) end,
	function(f) return a1(f)\a2(f) end,
	function(f) return a1(f)%a2(f) end,
	function(f) return a1(f)^a2(f) end,
	function(f) return a1(f)<a2(f) end,
	function(f) return a1(f)>a2(f) end,
	function(f) return a1(f)==a2(f) end,
	function(f) return a1(f)~=a2(f) end,
	function(f) return a1(f)..a2(f) end,
	function(f) return a1(f) or a2(f) end,
	function(f) return a1(f) and a2(f) end,
	function(f) return not a1(f) end,
	function(f) return #a1(f) end,
	a3 and function(f) a1(f)[a2(f)] = a3(f) end
		or function(f) return a1(f)[a2(f)] end
end)

parens8[[
(foreach (split "+,-,*,/,\,%,^,..") (fn (op)
	(rawset builtin (.. op "=") (fn (lookup e1 e2)
		(compile (pack "set" e1 (pack op e1 e2)) lookup)
	))
))
]]

--------------------------------
-- control flow

-- if you don't feel like writing IIFEs, this writes them for you
-- (let ((a 42) (b "foo")) (print (.. b a)))
parens8[[
(rawset builtin "let" (fn (lookup exp2 exp3) (
	(fn (names values) (select 2
		(foreach exp2 (fn (binding) (id
			(add names (rawget binding 1))
			(add values (rawget binding 2))
		)))
		(compile (pack (pack "fn" names exp3) (unpack values)) lookup)
	))
	(pack) (pack)
)))

(rawset builtin "loop" (fn (lookup exp2 exp3) (compile
	(pack (pack "fn" (pack "__ps8_loop") (pack "id"
		(pack "set" "__ps8_loop" (pack "fn" (pack)
			(pack "when" exp2 (pack "__ps8_loop" exp3))
		))
		(pack "__ps8_loop")
	)))
	lookup
)))
]]

-- the "loop" builtin is a "poor man's while", implemented as a tail recursion.
-- thanks to lua, such an implementation will not blow up the stack.
-- if you're really strapped for tokens, it will at least save you the headache
-- of implementing a tail recursion loop correctly yourself.

-- this is what the generated code looks like:
-- (fn (__ps8_loop) (id
-- 	(set __ps8_loop (fn () 
-- 		(when exp2 (__ps8_loop exp3))
-- 	))
-- 	(__ps8_loop)
-- ))

-- if you *really* need proper loops and can justify the token cost however...

-- (while (< x 3) (set x (+ 1 x))
parens8[[
(fn (closure) (rawset builtin "while" (fn (lookup cond body)
	(closure (compile_n lookup cond body))
)))
]](function(a1, a2) return function(frame)
	while (a1(frame)) a2(frame)
end end)

-- `foreach` should take care of your collection traversal needs, but if for
-- some reason you think doing numeric loops in parens-8 is a good idea (it
-- usually isn't), there's a builtin for it:

-- (for (i 1 10 2) (body))
-- (for ((k v) (pairs foo)) (body))
parens8[[
(fn (closures) (rawset builtin "for" (fn (lookup args body)
	(when (rawget args 3)
		(select 1 (closures
			(compile (pack "fn" (pack (rawget args 1)) body) lookup)
			(compile_n lookup (unpack args 2))))
		(select 2 (closures
			(compile (pack "fn" (rawget args 1) body) lookup)
			(compile (rawget args 2) lookup)))
	)
)))
]](function(cbody, a, b, c) return
	function(frame) -- numeric for loop (28 tokens)
		local body = cbody(frame)
		for i = a(frame), b(frame), c and c(frame) or 1 do
			body(i)
		end
	end,
	function(frame) -- generic for loop (41 tokens)
		local body, next, state = cbody(frame), a(frame)
		local function loop(var, ...)
			if (var == nil) return
			body(var, ...)
			return loop(next(state, var))
		end
		return loop(next(state))
	end
end)

--------------------------------
-- environment remapping

-- local _ENV = self; x = 42
-- (env self (set x 42))
parens8[[
(fn (closure) (rawset builtin "env" (fn (lookup exp1 exp2) ((fn (key)
	(closure key (compile exp1 lookup)
		(compile exp2 (fn (name)
			((fn (idx where) (id
				idx (when (tonum (tostring idx)) where key)
			)) (lookup name))
		)))
) (pack)))))
]](function (key, mapped, body)
	return function(frame)
		frame[1][key] = mapped(frame)
		return body(frame)
	end
end)

-- to save you the trouble of capturing all the globals by hand
-- (capture_api (env foo (print bar)))
-- this is more or less what pico-8 does internally at launch
-- in our case, this captures global names *at the parens8[[...]] invocation*
parens8[[
(fn (_ENV) (rawset builtin "capture_api" (fn (lookup exp) (
	(fn (names keys) (select -1
		(set keys (fn (k) (when k (keys (next _ENV k) (add names k)))))
		(keys (next _ENV))
		(compile (pack (pack "fn" names exp) (unpack names)) lookup)
	))
	(pack)
))))
]](_ENV)

--------------------------------
-- table constructor

-- slightly simplified: {[0] = 1} works, {[foo] = 1} doesn't
-- (table (foo 1) (0 2) 3 4 5 6)
-- (table (x 1) (y 2))
function builtin.table(...)
	return parens8[[
	(fn (exp) ((fn (closures lookup construct) (select -1
		(set construct (fn (i elem) (when elem
			((fn (step) (when (count elem)
				(select 1 (closures
					step (compile (rawget elem 2) lookup) (rawget elem 1)))
				(select 2 (closures step (compile elem lookup)))
			)) (construct (inext exp i)))
			id
		)))
		(select 3 (closures (construct (inext exp))))
	)) (deli exp 1) (deli exp 1)))
	]]{function(step, elem, key) return
		function(res, frame)
			res[key] = elem(frame)
			return step(res, frame)
		end,
		function(res, frame)
			add(res, elem(frame))
			return step(res, frame)
		end,
		function(frame)
			return (step({}, frame))
		end
	end, ...}
end

--------------------------------
-- statement sequence

-- inlined statement sequence, returns the last expression
-- significantly improves performance compared to `(id s1 s2 s3 ...)`
function builtin.seq(...)
	return parens8[[
		(fn (exp) ((fn (unroll lookup e1 e2 e3) 
			((fn (s1 s2) (select (mid 3 (rawlen exp)) s1 (unroll s1 s2 (when e3
				((rawget builtin "seq") lookup (unpack exp 3)))))
			) (compile_n lookup e1 e2))
		) (deli exp 1) (deli exp 1) (unpack exp)))
	]]{function(s1, s2, s3)
		return function(frame)
			s1(frame)
			return s2(frame)
		end, function(frame)
			s1(frame)
			s2(frame)
			return s3(frame)
		end
	end, ...}
end

-->8
--[[ profiler.lua -- by pancelor
more info: https://www.lexaloffle.com/bbs/?tid=46117
minor tweaks by rodents

usage:
  prof(function()
    memcpy(0,0x200,64)
  end,function()
    poke4(0,peek4(0x200,16))
  end)

passing locals:
  prof(
  	{locals={3,5}},
    function(a,b)
      local c=(a+1)*(b+1)-1
    end,
    function(a,b)
      local c=a*b+a+b
    end
  )
]]

-- prof([opts],fn1,fn2,...,fnN)
--
-- opts.locals: values to pass
-- opts.name: text label
-- opts.n: number of iterations
-- opts.noop: reference noop function
function prof(...)
  local funcs={...}
  local opts=type(funcs[1])=="table" and deli(funcs, 1) or {}

  -- build output string
  local msg=""
  local function log(s)
    msg..=s.."\n"
  end

  if opts.name then
    log("prof: "..opts.name)
  end
  for fn in all(funcs) do
    local dat=prof_one(fn,opts)
    log(sub("  "..dat.total,-3)
      .." ("
      ..dat.lua
      .." lua, "
      ..dat.sys
      .." sys)")
  end

  -- copy to clipboard
  printh(msg,"@clip")
  -- print + pause
  cls()
  stop(msg)
end

function prof_one(func, opts)
  opts = opts or {}
  local n = opts.n or 0x200 --how many times to call func
  local locals = opts.locals or {} --locals to pass func

  -- we want to type
  --   local m = 0x80_0000/n
  -- but 8MHz is too large to fit in a pico-8 number,
  -- so we do (0x80_0000>>16)/(n>>16) instead
  -- (n is always an integer, so n>>16 won't lose any bits)
  local m = 0x80/(n>>16)
  assert(0x80/m << 16 == n, "n is too small") -- make sure m didn't overflow
  local fps = stat(8)

  -- given three timestamps (pre-calibration, middle, post-measurement),
  --   calculate how many more CPU cycles func() took compared to noop()
  -- derivation:
  --   T := ((t2-t1)-(t1-t0))/n (frames)
  --     this is the extra time for each func call, compared to noop
  --     this is measured in #-of-frames -- it will be a small fraction for most ops
  --   F := 1/30 (seconds/frame) (or 1/60 if this test is running at 60fps)
  --     this is just the framerate that the tests run at, not the framerate of your game
  --   M := 256*256*128 = 0x80_0000 = 8MHz (cycles/second)
  --     (PICO-8 runs at 8MHz; see https://www.lexaloffle.com/dl/docs/pico-8_manual.html#CPU)
  --   cycles := T frames * F seconds/frame * M cycles/second
  -- optimization / working around pico-8's fixed point numbers:
  --   T2 := T*n = (t2-t1)-(t1-t0)
  --   M2 := M/n = (M>>16)/(n>>16) := m (e.g. when n is 0x1000, m is 0x800)
  --   cycles := T2*M2*F
  local function cycles(t0,t1,t2)
    local diff = (t2-t1)-(t1-t0)
    local e1 = "must use inline functions -- see usage guide"
    assert(0<=diff,e1)
    local thresh = 0x7fff.ffff/(m/fps)
    local e2 = "code is too large or slow -- try profiling manually with stat(1)"
    assert(diff<=thresh,e2)
    return diff*(m/fps)
  end

  local noop = opts.noop or function() end -- this must be local, because func is local
  flip() --avoid flipping mid-measurement
  local atot,asys=stat(1),stat(2)
  for _=1,n do noop(unpack(locals)) end -- calibrate
  local btot,bsys=stat(1),stat(2)
  for _=1,n do func(unpack(locals)) end -- measure
  local ctot,csys=stat(1),stat(2)

  -- gather results
  local tot=cycles(atot,btot,ctot)
  local sys=cycles(asys,bsys,csys)
  return {
    lua=tot-sys,
    sys=sys,
    total=tot,
  }
end

-->8
-- your code here

local a = setmetatable({}, {__index = {foo = 42}})
local b = setmetatable({}, {__index = a})
local c = {foo = 42}

prof({locals = {a, b, c}},
function(a, b, c)
	local res = a.foo
end,
function(a, b, c)
	local res = b.foo
end,
function(a, b, c)
	local res = c.foo
end
)

-- ball = {x=64, y=0, dx=0, dy=0, r=10}

-- function run_physics(_ENV)
-- 	dy += 1
-- 	dx *= .99
-- 	dy *= .99
-- 	x += dx
-- 	y += dy
-- end

-- parens8[[
-- (set apply_input (fn (obj) (seq
-- 	(when (btn 0) (-= obj.dx 1))
-- 	(when (btn 1) (+= obj.dx 1))
-- 	(when (btn 2) (-= obj.dy 2))
-- 	(when (btn 3) (+= obj.dy 1))
-- )))

-- (set bounce (fn (obj) (env obj (seq
	
-- ))))

-- (set _update (fn () (seq
-- 	(apply_input ball)
-- 	(run_physics ball)
-- )))

-- (set _draw (fn () (seq
-- 	(cls)
-- 	(circfill ball.x ball.y ball.r 13)
-- 	(color 7)
-- 	(print "open the code editor!")
-- )))
-- ]]


__label__
00050500050005050555050500500500050005000505050505000505050005050505050005050505050005050505050005050505050005050505050005050505
00050500050005050505055500500500055005000555055505000550050005550555050005500000055005050000050005550555050005500000050005050505
00050500050005050505050000500500050005000500050505000505050005000505050005050000050005050000050005000505050005050000050005050505
00500050005505500505050005550555055500500500050500550505005005000505005505050000050005050000005005000505005505050000055505500550
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50055050505050555055005050050055505550055050505050500005500550555055505500505005000500555055500550505050505550550050500500555055
50500050505050500050505050500050505050500050505050500050505050505050005050505000505000505050505000505050500500505050505000505050
50500055000000550050500000500055505550500055000000500050505050555055005050000000505000555055505000550000000500505000005000555055
50500050500000500050500000500050005050500050500000500050505050500050005050000000505000500050505000505000000500505000005000500050
50055050500000500050500000050050005050055050500000555055005500500050005050000005000500500050500550505000005550555000000500500050
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50555055500500555055000500555055505500550055505500055005000500555055000500555055005500000055005550555055500550050055505550505005
50505000505000500050505000505005005050505005005050500000505000050050505000505050505050000050505050555050005000500050505050505050
00555055505000550050505000550005005050505005005050500000505000050050505000555050505050000050505550505055005550500055005550505050
50500050005000500050505000505005005050505005005050505000505000050050505000505050505050000050505050505050000050500050505050555050
50500055500500500050500500555055505050555055505050555005000500555055500500505055505550000050505050505055505500050050505050555055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00500555055500550505005005550555005505050505055505500505005005550555005505050505050000550055055505550550050500500050055505550055
05000505050505000505050005050505050005050505050005050505050005050505050005050505050005050505050505000505050500050500050505050500
05000555055505000550050005550555050005500000055005050000050005550555050005500000050005050505055505500505000000050500055505550500
05000500050505000505050005000505050005050000050005050000050005000505050005050000050005050505050005000505000000050500050005050500
00500500050500550505005005000505005505050000050005050000005005000505005505050000055505500550050005000505000000500050050005050055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50055505550055050500500555055500550505050505550550050505500555055505550055000005550505055505550050005005050550055505550055050500
00050505050500050505000505050505000505050505000505050505050505055505000500000005000505050500050005050005050505050505050500050500
00055505550500055005000555055505000550000005500505000005050555050505500555000005500050055500550005050005050505055505550500055000
00050005050500050505000500050505000505000005000505000005050505050505000005000005000505050000050005050005050505050005050500050500
50050005050055050500500500050500550505000005000505000005050505050505550550000005550505050005550050005000550505050005050055050500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00500050005005550550055000000505055505000505055500550050055505550505005505550555000005550555055005500555055000550000055500500050
00050005050005050505050500000505050505000505050005000500050505050505050005000050000005050050050505050050050505000000000500050005
00050005050005550505050500000505055505000505055005550500055005550505050005500050000005500050050505050050050505000000055500050005
00050005050005050505050500000555050505000505050000050500050505050555050505000050000005050050050505050050050505050000050000050005
00500050005005050555055500000050050505550055055505500050050505050555055505550050000005550555050505550555050505550000055500500050
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00550555000005550050055500550555055505550055050500000555050505550555005005550550005005550555055005500555055000550050005005550550
05000050000000050500050005050505050005050500050500000500050505050005050005000505050005050050050505050050050505000005050000500505
05000050000005550500055005050550055005550500055500000550005005550555050005500505050005500050050505050050050505000005050000500505
05000050000005000500050005050505050005050500050500000500050505000500050005000505050005050050050505050050050505050005050000500505
00550050000005550050050005500505055505050055050500000555050505000555005005000505005005550555050505550555050505550050005005550555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50005005000055005505050505055500000555050505550555000005550505055505550050005000500555055000500550055505550555005500000505055505
05050005000505050505050505050500000500050505050005000005000505050500050005050005000500050505000505050505550500050000000505050505
05050005000505050505500505055500000550005005550555000005500050055500550005050005000550050505000505055505050550055500000505055505
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000066777799ffffffffff000022eeeeeeeeee22dddddddddd000011cccccccccc33bbbbbbbb00000099aaaaaaaa000000000000002288888888006677770000
000066777799ffffffffff000022eeeeeeeeee22dddddddddd000011cccccccccc33bbbbbbbb00000099aaaaaaaa000000000000002288888888006677770000
006677770099ffffffffffff22eeeeeeeeeeee22dddddddddddd11cccccccccccc33bbbbbbbbbb0099aaaaaaaaaaaa0000000000228888888888880066777700
006677770099ffffffffffff22eeeeeeeeeeee22dddddddddddd11cccccccccccc33bbbbbbbbbb0099aaaaaaaaaaaa0000000000228888888888880066777700
006677770099ffff0099ffff22eeee0022eeee22dddd0022dddd11cccc0000000033bbbb0033bbbb99aaaa000000000000000000228888002288880066777700
006677770099ffff0099ffff22eeee0022eeee22dddd0022dddd11cccc0000000033bbbb0033bbbb99aaaa000000000000000000228888002288880066777700
667777000099ffff0099ffff22eeee0022eeee22dddd0022dddd11cccc0000000033bbbb0033bbbb99aaaa000000000000000000228888002288880000667777
667777000099ffff0099ffff22eeee0022eeee22dddd0022dddd11cccc0000000033bbbb0033bbbb99aaaa000000000000000000228888002288880000667777
667777000099ffffffffffff22eeeeeeeeeeee22dddddddddd0011cccccccccc0033bbbb0033bbbb99aaaaaaaaaa004499999999002288888888000000667777
667777000099ffffffffffff22eeeeeeeeeeee22dddddddddd0011cccccccccc0033bbbb0033bbbb99aaaaaaaaaa004499999999002288888888000000667777
667777000099ffffffffff0022eeeeeeeeeeee22dddddddddd0011cccccccccc0033bbbb0033bbbb0099aaaaaaaaaa4499999999228888888888880000667777
667777000099ffffffffff0022eeeeeeeeeeee22dddddddddd0011cccccccccc0033bbbb0033bbbb0099aaaaaaaaaa4499999999228888888888880000667777
667777000099ffff0000000022eeee0022eeee22dddd0022dddd11cccc0000000033bbbb0033bbbb0000000099aaaa0000000000228888002288880000667777
667777000099ffff0000000022eeee0022eeee22dddd0022dddd11cccc0000000033bbbb0033bbbb0000000099aaaa0000000000228888002288880000667777
006677770099ffff0000000022eeee0022eeee22dddd0022dddd11cccc0000000033bbbb0033bbbb0000000099aaaa0000000000228888002288880066777700
006677770099ffff0000000022eeee0022eeee22dddd0022dddd11cccc0000000033bbbb0033bbbb0000000099aaaa0000000000228888002288880066777700
006677770099ffff0000000022eeee0022eeee22dddd0022dddd11cccccccccccc33bbbb0033bbbb99aaaaaaaaaaaa0000000000228888888888880066777700
006677770099ffff0000000022eeee0022eeee22dddd0022dddd11cccccccccccc33bbbb0033bbbb99aaaaaaaaaaaa0000000000228888888888880066777700
000066777799ffff0000000022eeee0022eeee22dddd0022dddd11cccccccccccc33bbbb0033bbbb99aaaaaaaaaa000000000000002288888888006677770000
000066777799ffff0000000022eeee0022eeee22dddd0022dddd11cccccccccccc33bbbb0033bbbb99aaaaaaaaaa000000000000002288888888006677770000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006666600006666660660666600066006600006600000660066660066666000006666600066660066666000006666600660066660006666000000066660000
00066666600006666660660666660066006600006600000660666666066666600006666660666666066666600006666660660666666066666600000666666000
00066006600000066000660660066066006600006600000660660000066006600006600000660066066006600006600660660660000066006600000660066000
00066006600000066000660660066066006600006600000660660000066006600006600000660066066006600006600660660660000066006600000660066000
00066666600000066000660660066066666600006600000660666660066666600006666000660066066666000006666660660660000066006606660066660000
00066666600000066000660660066006666000006600000660066666066666000006666000660066066666000006666600660660000066006606660666666000
00066006600000066000660660066000660000006600000660000066066000000006600000660066066006600006600000660660000066006600000660066000
00066006600000066000660660066000660000006600000660000066066000000006600000660066066006600006600000660660000066006600000660066000
00066006600000066000660660066000660000006666660660666666066000000006600000666666066006600006600000660666666066666600000666666000
00066006600000066000660660066000660000006666660660666660066000000006600000066660066006600006600000660066660006666000000066660000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05500505055005500555050005550000055000500555055505000550050505000550005005050505005005050500000505000050050505000555050505050000
05000505050505000505050005050000050005050500050005000500050505000505005005050505005005050505000505000050050505000505050505050000
05000550050505550505005505050000055505050500055500500500050500500555055505050555055505050555005000500555055500500505055505550000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55005500500050050000550055050505050555005000500050005005550555005505050050005005550555005505050050005000500050005005550555050500
00050000050005050005050505050505050505000500050005050005050505050005050005050005050505050005050005000500050005050005050505050505
50055500050005050005050505055005050555000500050005050005550555050005500005050005550555050005500005000500050005050005500555050505
00000500050005050005050505050505050500000500050005050005000505050005050005050005000505050005050005000500050005050005050505055500
55055000500050055505500550050500550500005000500050005005000505005505050050005005000505005505050050005000500050005005050505055505
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055005000500555055000500555055005500000055005550555055500550050055505550505005505550555000005550555055005500555055000550000055
50500000505000050050505000505050505050000050505050555050005000500050505050505050005000050000005050050050505050050050505000000005
50500000505000050050505000555050505050000050505550505055005550500055005550505050005500050000005500050050505050050050505000000005
50505000505000050050505000505050505050000050505050505050000050500050505050555050505000050000005050050050505050050050505050000005
50555005000500555055500500505055505550000050505050505055505500050050505050555055505550050000005550555050505550555050505550000055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050055505550055050500500050005000500050055505550505005505550555000005550505055505000555055505500505050000550055055505050050055
50500050505050500050500050005000500050500050505050505050005000050000005050505005005000050005005050505050005050505050505050500050
50500055505550500055000050005000500050500055005550505055505500050000005500505005005000050005005050000050005050505055500000500055
50500050005050500050500050005000500050500050505050555000505000050000005050505005005000050005005050000050005050505050000000500050
00050050005050055050500500050005000500050050505050555055005550050000005550055055505550050055505050000055505500550050000000050050
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55005005550550005005550555055005500555055000550050005005550550005005550550055000000550055505550555005500500555055505050055055505
05050005000505050005050050050505050050050505000005050000500505050005050505050500000505050505550500050005000505050505050500050000
55050005500505050005500050050505050050050505000005050000500505050005550505050500000505055505050550055505000550055505050500055000
00050005000505050005050050050505050050050505050005050000500505050005050505050500000505050505050500000505000505050505550505050000
55005005000505005005550555050505550555050505550050005005550555005005050555055500000505050505050555055000500505050505550555055500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05005550555050500550555055500000555055505500550055505500055000005500050005000500555055005500000050505550500050505550055005005550
50005050505050505000500005000000505005005050505005005050500000000500005000505000505050505050000050505050500050505000500050005050
50005500555050505000550005000000550005005050505005005050500000000500005000505000555050505050000050505550500050505500555050005500
50005050505055505050500005000000505005005050505005005050505000000500005000505000505050505050000055505050500050505000005050005050
05005050505055505550555005000000555055505050555055505050555000005550050005000500505055505550000005005050555005505550550005005050
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50500050505550055005005550555050500550555055500000555055505500550055505500055000005550050005000500050005000500055005505550555055
50500050505000500050005050505050505000500005000000505005005050505005005050500000000050005000500050005000505000500050505550505005
50500050505500555050005500555050505000550005000000550005005050505005005050500000005550005000500050005000505000500050505050555005
50500050505000005050005050505055505050500005000000505005005050505005005050505000005000005000500050005000505000500050505050500005
50555005505550550005005050505055505550555005000000555055505050555055505050555000005550050005000500050005000500055055005050500055
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55055505500505005000500050005005000055005505050505055500500050005000500555055505050055055505550000055505050555050005550555055005
05050005050505000500050005000505000505050505050505050500050005000505000505050505050500050000500000050505050050050000500050050505
55055005050000000500050005000505000505050505500505055500050005000505000550055505050555055000500000055005050050050000500050050500
00050005050000000500050005000505000505050505050505050000050005000505000505050505550005050000500000050505050050050000500050050500