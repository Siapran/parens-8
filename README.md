![(parens-8)](parens-8.png)

A tiny Lisp for your pico-8 carts

## Overview

Parens-8 is a tool for bypassing the pico-8 token limit. It takes up 5% of the allowed 8192 tokens, and gives you practically infinite code space in return: store extra code in strings or cart ROM, load it during init, run it like regular lua code.

Parens-8 is designed for maximum interoperability with Lua. Functions, tables, values and coroutines can be passed and used seamlessly between lua and parens-8. Think of parens-8 as Lua semantics with Lisp syntax.

```lua
local a, b, c = parens8("1 2 3")
?(b == 2) -- true

local myfunction = parens8"(fn(x) (print x))"
myfunction(42) -- prints 42

-- use the lua multiline string syntax: [[]]
parens8[[
     (set foo 256)
     (set bar (fn (a b)
          (when a
               (print b)
               (print "a was false or nil")
          )
     ))
]]

bar(foo, "hello") -- prints "hello"
bar(false, "goodbye") -- prints "a was false or nil"
```

Parens-8 comes with four base builtins:
* `(set a b)`, for assignment, aka `a = b`
* `(fn (a b c) expr)`, for lambdas, aka `function (a, b, c) return expr end`
* `(when cond a b)`, for conditionals, aka `(function() if cond then return a else return b end end)()` (think of it as a Lua `cond and a or b` ternary that supports multiple return values)
* `(quote expr)`, for preventing an expression from being evaluated.

Note that `"foo"` is translated into `(quote foo)` by the parser. You can also create lua arrays and `nil` this way: `(quote (1 2 3))`, `(quote)`

While it's possible to write [an entire game](./examples/baloonbomber_v3.p8) in parens-8, it's best to keep most of your code as plain lua. Use parens-8 for code that you know is stable, and where performance isn't critical. We'll elaborate on performance and use cases further ahead.

## Parens-8 versions

Parens-8 comes in three different versions:
* v3: 507 tokens, the fastest, safest and most memory efficient version.
* v2: 375 tokens, pretty fast, reasonably memory efficient, with a couple pitfalls.
* v1: 337 tokens, substantially slower, uses more memory, same pitfalls as v2.

v1 is an interpreter that evaluates the AST as it runs the code. This makes it the lightest version in terms of token usage.

v2 is substantially faster than v1: it compiles the AST into closures that perform only the required computations. Think of it as a bytecode compiler that compiles to Lua closures instead of a portable binary.

v3 takes the compiler one step further and compiles _scope lookup_ into proper locals, upvalues, and globals, instead of performing scope lookup at runtime.

If you're unsure of which version to pick, use v3. It has the best overall performance and the most features, at the cost of slightly heavier token cost. v3 is the version that most closely reproduces the semantics of Lua.

## Performance

For the following lua and parens-8 snippets:
```lua
function fun(cond, a, b, c)
     if cond then
          return pack(a, b, c)
     end
end
```
```lisp
(set fun (fn (cond a b c)
     (when cond (pack a b c))
))
```

Running the `fun` implementations for each language gives the following.

| language | cycles | cycles / native | native / cycles |
| --- | --- | --- | --- |
| native lua | 29 | 1 | 100% |
| parens-8 v3 | 116 | 4.0 | 25% |
| parens-8 v2 | 193 | 6.6 | 15% |
| parens-8 v1 | 330 | 11.3 | 8.7% |

For more details, see [this document](./doc/performance.md)

## Extensions

While designed as a lightweight runtime for offloading code to strings and ROM, parens-8 has extensions to turn it into a fully featured programming language.

```lisp
; comments! (disabled by default)

; operators
(set fib (fn (x)
     (when (< x 2)
          x
          (+ (fib (- x 1))
             (fib (- x 2)))
     )
))

; table constructors
(set mytable (table (a 1) (b 2) (c 3) 4 5 6))

; loops
(for ((k v) (pairs mytable))
     (print (.. k (.. ": " (.. v (.. " -> " (fib v)))))))

; field access, let, seq
(set mytable.b 42)
(let ((print print) (value 256)) (env mytable (seq
     (print b)     ; 42
     (set b value)
     (print b)     ; 256
)))
(print b)          ; nil
(print mytable.b)  ; 256

; variadics
(set add_all (fn (head ...)
     (when head (+ head (add_all ...)) 0)
))
(print (add_all 1 2 3 4 5)) ; 15
```

Extensions can be found in `v*/builtin/`. Parens-8 v3 with all builtin extensions enabled is 941 tokens. The field and variadics syntax extensions are enabled separately by including `v3/parens8_field.lua` (547 tokens) or `v3/parens8_variadics.lua` (524 tokens) instead of `v3/parens8.lua` (495 tokens).

Remember: it's unlikely you will need all extensions. Pick a few ones you know will be useful for _your_ use case, and make sure you get as much mileage as you can out of them. About half of parens-8 v3 is written _in parens-8_, with only the four core builtins, no extensions.

## ROM utilities

If (when) you run out of chars in your cart's code, you can store more code in the ROM of other carts. This is easily done via the utilities found in `parens-8/rom-utils/`:
* `small = minify(code)` removes as much whitespace from your parens-8 code as possible.
* `length = writerom(small, address, filename)` `cstore`s your string in the ROM data of `filename`.
* `parens8(readrom(address, length, filename))` runs your code from where you stored it in ROM.
* `parens8[[(parens8 (readrom address length filename))]]` does the same as above with less tokens!

This [pico-8 cart](https://www.lexaloffle.com/bbs/?tid=54486) loads its _entire_ game logic with `readrom`.

## Limitations

Troubleshooting errors is somewhat challenging, as the language itself makes no attempt at diagnostics. Debugging compiled parens-8 (v2 and v3) is slightly easier, as you can at least tell if something is a syntax error or a runtime error.

`'` and `"` can't be escaped in parens-8 strings, but you can use either as quotes:
```lisp
(print "hello, here's a single quote")
(print 'sure... a single "quote", I think we call this an apostrophe')
(print "don't make fun of me, you can't even say 'can't'")
(print "y'all know the `..` operator exists, right?")
```

In parens-8 v1 and v2 (fixed in v3!) variables with `nil` values become _invisible_, that is:
```lua
x = "oops"
parens8[[
((fn (x) (id
     (print x)
     (set x (quote))
     (print x)
)) 42)
]] -- prints "42", then "oops"
```
This pitfall is _extremely_ easy to run into accidentally, and can be hard to troubleshoot. v3 fixes this issue completely.

## Misc

As mentionned above, parens-8 v3 offers optional support for variadics with the `...` syntax. Because of the way upvalues work in v3, parameter packs can also be captured, something native Lua can't do!
```lisp
(set store (fn (...)
     (fn () ...)
))
```
All versions of parens-8 support the same behavior as lua for multiple return values. So even without the variadics support, functions like `id`, `select`, `pack` and `unpack` can and should be leveraged to your advantage.

Most Lisp flavors support some sort of `seq` or `progn` builtin for executing sequences of statements. Parens-8 does offer an _optional_ `seq` builtin if you find yourself writing a lot of imperative code, but the identity function `function id(...) return ... end` and `select` are reasonable substitutes if you would rather save on tokens, though `seq` is significantly faster. `id` is also useful for returning multiple values:
```lisp
(set print_foo_then_print_bar
     (fn () (id (print foo)
                (print bar))))
(set swap (fn (a b) (id b a)))
```

Parens-8, like Lua, supports tail call elimination. This can be leveraged if you plan on foregoing flow extensions:
```lisp
(set loop (fn (i) (loop (+ i 1)
     (print (.. (stat 0) (.. " " i)))
)))
(loop 1)
```
Parens-8 v3 offers this pattern as the `loop` builtin for the price of 1 (one) token. It's the poor man's while loop.

there's a [code highlighter](./misc/highlight.lua). I might make a parens-8 code editor in pico-8 with tools for saving to ROM and such? who knows. it's there. you can try it.

## Acknowledgements

* Peter Norvig's [tutorial](https://norvig.com/lispy.html) got me started with parens-8 v0 and v1.
* [luchak](https://github.com/luchak) helped quite a bit with parens-8 v2, and I borrowed a few tricks from his own pico-8 lisp implementations.
* Robert Nystrom's book: Crafting Interpreters. Specifically, the [chapter on closures](https://craftinginterpreters.com/closures.html#upvalues) was of great help when designing parens-8 v3.
* [carlc27843](https://carlc27843.github.io/), for the tantalizing [blog post](https://carlc27843.github.io/post/picoscript/) that inspired me to implement my own extension language.
* [Wuff](https://wuffmakesgames.itch.io/), for playing around with parens-8 v0 and putting up with my shenanigans.
* The pico-8 discord server, for all the help, inspiration, resources and encouragement a developer could ask for.
