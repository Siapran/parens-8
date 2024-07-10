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
