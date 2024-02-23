![(parens-8)](parens-8.png)

a tiny lisp for your pico-8 carts

## overview

parens-8 is a tool for bypassing the pico-8 token limit. it takes up 5% of the allowed 8192 tokens, and gives you practically infinite code space in return: store extra code in strings or cart ROM, load it during init, run it like any lua code.

parens-8 is designed for maximum interoperability with lua. functions, tables and values can be passed and used seamlessly between lua and parens-8. the `parens8` function evaluates parens-8 expressions passed as strings:

```lua
a, b, c = parens8[[1 2 3]]
?(b == 2) -- true

?parens8[[(mid a b c)]] -- 2

parens8[[
(fn (x) (print x))
]](42) -- 42
```

parens-8 comes with four base builtins:
* `(set a b)`, for assignment, aka `a = b`
* `(fn (a b c) expr)`, for lambdas, aka `function (a, b, c) return expr end`
* `(when cond a b)`, for conditionals, aka `(function() if cond then return a else return b end end)()`
* `(quote expr)`, for preventing an expression from being evaluated.

note that `"foo"` is translated into `(quote foo)` by the parser. you can also create lua arrays and `nil` this way: `(quote (1 2 3))`, `(quote)`

while it's possible to write [an entire game](./examples/baloonbomber.p8) in parens-8, it's best to keep most of your code as plain lua. use parens-8 for code that you know is stable, and where performance isn't critical. we'll elaborate on performance and use cases further ahead.

## parens-8 versions

parens-8 comes in three different versions:
* v3: 509 tokens, the fastest, safest and most memory efficient version.
* v2: 375 tokens, pretty fast, reasonably memory efficient, a couple pitfalls.
* v1: 337 tokens, substantially slower, uses more memory, same pitfalls as v2.

v1 is an interpreter that evaluates the AST as it runs the code. this makes it the lightest version in terms of token usage.
v2 is substantially faster than v1: it compiles the AST into closures that perform only the required computations. think of it as a bytecode compiler that compiles to Lua closures instead of a portable binary.
v3 takes the compiler one step further and compiles _scope lookup_ into proper locals, upvalues, and globals. v1 and v2 both use runtime scopes implemented as tables with nested `__index` metamethods.

## performance

it took some work, but parens-8 v3 is pretty close to [picoscript](https://carlc27843.github.io/post/picoscript/). benchmarking parens-8 against native lua and the hand-expanded picoscript closure from the blog post gives the following results for the `glstate` function defined by each language:
| language | cycles | cycles / native | native / cycles | cycles / picoscript | picoscript / cycles |
| --- | --- | --- | --- | --- | --- |
| native lua | 11 | 1 | 100% | | |
| picoscript | 94 | 8.54 | 11.7% | 1 | 100% |
| parens-8 v3 | 117 | 10.63 | 9.4% | 1.24 | 80.3% |
| parens-8 v2 | 137 | 12.45 | 8.0% | 1.46 | 68.6% |
| parens-8 v1 | 290 | 26.36 | 3.8% | 3.01 | 32.4% |

parens-8 tries to balance speed, memory usage, token cost, and flexibility. improving any one metric usually comes at the cost of another. if you have ideas to improve parens-8, feel free to contribute with a pull request or through the issue tracker.

## extensions

while designed as a lightweight runtime for offloading code to strings and ROM, parens-8 has extensions to turn it into a fully featured programming language.

```lisp
(set fib
     (fn (x) (when (< x 2)
               x
               (+ (fib (- x 1))
                  (fib (- x 2))))))

(set mytable (table (a 1) (b 2) (c 3) 4 5 6))

(for ((k v) (pairs mytable))
     (print (.. k (.. ": " (.. v (.. " -> " (fib v)))))))

([] mytable "b" 42)
(let ((print print) (id id))
     (env mytable (id
          (print b)
          (set b 256))))
(print ([] mytable "b"))
```

extensions can be found in `v*/builtin/`. include the extensions you need, and feel free to comment out builtins you aren't using.

custom builtins may be defined from both lua and parens-8. each version has a different way of defining builtins. study the `def_builtin.lua` file of each version.

the core of parens-8 v3 also comes with optional syntax extensions for:
* field access: `(set self.x (+ self.x self.dx))`
* variadics: `(fn (...) (foo ...))`

## ROM utilities

if (when) you run out of chars in your cart's code, you can store more code in the ROM of other carts. this is easily done via the utilities found in `parens-8/rom-utils/`:
* `small = minify(code)` removes as much whitespace from your parens-8 code as possible
* `length = writerom(small, address, filename)` `cstore`s your string in the data of `filename`
* `loaded = parens8(readrom(address, length, filename))` reads and parses your code back at you.

`readrom` is implemented in pure parens-8, without any extensions. you can add it to your cart essentially for free.

[this pico-8 cart](https://www.lexaloffle.com/bbs/?tid=54486) loads its _entire_ game logic with `readrom`.

## limitations

troubleshooting errors is somewhat challenging, as the language itself makes no attempt at diagnostics. debugging compiled parens-8 (v2 and v3) is slightly easier, as you can at least tell if something is a syntax error or a runtime error.

`'` and `"` can't be escaped in parens-8 strings, but you can use either as quotes:
```lisp
(print "hello, here's a single quote")
(print 'sure... a single "quote", I think we call this an apostrophe')
(print "don't make fun of me, you can't even say 'can't'")
(print "y'all know the `..` operator exists, right?")
```

in parens-8 v1 and v2 (fixed in v3!) variables with `nil` values become _invisible_, that is:
```lua
x = "oops"
parens8[[
((fn (x)
     (id (print x)
         (set x (quote))
         (print x)))
 42)
]] -- prints "42", then "oops"
```
this pitfall is _extremely_ easy to run into accidentally, and can be hard to troubleshoot. v3 fixes this issue completely.

## misc

as mentionned above, parens-8 v3 offers optional support for variadics with the `...` syntax (disabled by default):
```lisp
(set print_all (fn (a ...)
     (when a (id (print a) (print_all ...)))))
```
because of the way upvalues work in v3, parameter packs can also be captured, something native Lua can't do!
```lisp
(set store (fn (...)
     (fn () ...)))
```
all versions of parens-8 support the same behavior as lua for multiple return values. so even without the variadics support, functions like `id`, `select`, `pack` and `unpack` can and should be leveraged to your advantage.

most lisp flavors have some sort of `progn` builtin for executing sequences of statements, which is equivalent to `(select -1 exp1 exp2 expn)`. in parens-8, the choice was made to use the identity function `function id(...) return ... end` instead. `id` can be used wherever you need to run multiple statements in a single expression, and can also be used whenever you need to return multiple values from a function:
```lisp
(set print_foo_then_print_bar
     (fn () (id (print foo)
                (print bar))))
(set swap (fn (a b) (id b a)))
```

parens-8, like lua, supports tail call elimination. this can be leveraged if you plan on foregoing flow extensions:
```lisp
(set loop
     (fn (i)
         (loop (+ i 1)
               (print (.. (stat 0)
                          (.. " " i))))))
(loop 1)
```
parens-8 v3 offers this pattern as the `loop` builtin for the price of 1 (one) token. it's the poor man's while loop.

code examples so far have used proper lisp indentation, which may be confusing for some. it's perfectly valid to format your parens-8 code with a style closer to lua:
```lisp
(set my_function (fn (x) (id
     (set x (+ x 1))
     (print x)
     (when (< x 10)
          (print "lower than 10")
          (print "higher than 10")
     )
)))
```
this is [what luchak does in rp8](https://github.com/luchak/rp8/blob/main/src/rp8.p8#L19) (using a different pico-8 lisp). use whatever makes the pill easier to swallow.

there's a [code highlighter](./misc/highlight.lua). I might make a parens-8 code editor in pico-8 with tools for saving to ROM and such? who knows. it's there. you can try it.

## acknowledgements

* Peter Norvig's [tutorial](https://norvig.com/lispy.html) got me started with parens-8 v0 and v1.
* [luchak](https://github.com/luchak) helped quite a bit with parens-8 v2, and I borrowed a few tricks from his own pico-8 lisp implementations.
* Robert Nystrom's book: Crafting Interpreters. specifically, the [chapter on closures](https://craftinginterpreters.com/closures.html#upvalues) was of great help when designing parens-8 v3.
* [carlc27843](https://carlc27843.github.io/), for the tantalizing [blog post](https://carlc27843.github.io/post/picoscript/) that inspired me to implement my own extension language.
* [Wuff](https://wuffmakesgames.itch.io/), for playing around with parens-8 v0 and putting up with my shenanigans.
* the pico-8 discord server, for all the help, inspiration, resources and encouragement a developer could ask for.
