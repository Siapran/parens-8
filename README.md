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

note that `"foo"` is translated into `(quote foo)` by the parser. you can also create lua arrays this way: `(quote (1 2 3))`

while it's possible to write [an entire game](./examples/baloonbomber.p8) in parens-8, it's best to keep most of your code as plain lua. use parens-8 for code that you know is stable, and where performance isn't critical. we'll elaborate on performance and use cases further ahead.

## compiled vs interpreted

parens-8 comes in two flavors:
* the compiler: 375 tokens, found in `compiler/parens8.lua`
* the interpreter: 337 tokens, found in `interpreter/parens8.lua`

compiled parens-8 has much better performance than interpreted parens-8, both in speed and memory usage, for a slightly higher token cost. if unsure, use compiled parens-8: the two flavors are completely interchangeable (the compiler doesn't require more setup than the interpreter, the compile step is done within pico-8). the interpreter is here if you _absolutely_ can't afford the extra 38 tokens.

## builtin extensions

while designed as a lightweight runtime for offloading code to strings and ROM, parens-8 has extensions to turn it into a fully featured programming language.

```lisp
(set fib
     (fn (x) (when (< x 2)
               x
               (+ (fib (- x 1))
                  (fib (- x 2))))))

(set mytable (zip (pack "a" "b" "c")
                  (pack 1 2 3)))

(for ((k v) (pairs mytable))
     (print (.. k (.. ": " (.. v (.. " -> " (fib v)))))))

([] mytable "b" 42)
(print ([] mytable "b"))

(env mytable
     (id (print b)
         (set b "hello!")))
(print ([] mytable "b"))
```

extensions can be found in `flavor/builtin/`. include the extensions you need, and feel free to comment out builtins you aren't using.

custom builtins may be defined from both lua and parens-8. compiled builtins are written slightly differently than interpreted builtins:
* interpreted builtins are best defined through `def_builtin`, found in `interpreter/builtin/def_builtin.lua`
* compiled builtins are a bit trickier. study the files `compiler/parens8.lua` and `compiler/builtin/operators.lua`

while builtin definitions and the code that uses them can be in the same `parens8` interpreter call, the same cannot be said of the compiler. if you're defining a builtin from within compiled parens-8, it won't be available until the next `parens8` invocation.

## performance

well, it's no [picoscript](https://carlc27843.github.io/post/picoscript/), but compiled parens-8 isn't too far off. benchmarking parens-8 against native lua and the hand-expanded picoscript closure from the blog post gives the following results for the `glstate` function defined by each language:
| language | time / native | native / time |
| --- | --- | --- |
| native lua | 1 | 100% |
| picoscript | 5.2007 | 19.2276% |
| parens-8 compiler | 9.0315 | 11.0718% |
| parens-8 interpreter | 18.2374 | 5.4825% |

parens-8 is first and foremost designed for "glue" code: bits and pieces of logic you'd rather pay for in overhead instead of tokens. what parens-8 doesn't have in performance, it makes up for in flexibility and accessibility.

## ROM utilities

if (when) you run out of chars in your cart's code, you can store more code in the ROM of other carts. this is easily done via the utilities found in `parens-8/rom-utils/`:
* `small = minify(code)` removes as much whitespace from your parens-8 code as possible
* `length = writerom(small, address, filename)` `cstore`s your string in the data of `filename`
* `loaded = parens8(readrom(address, length, filename))` reads and parses your code back at you.

`readrom` is implemented in pure parens-8, without any extensions! it's the perfect example of glue code.

[this pico-8 cart](https://www.lexaloffle.com/bbs/?tid=54486) loads its _entire_ game logic with `readrom`.

## limitations

parens-8 has a few limitations that are probably here to stay, in the interest of token economy.

variables with `nil` values become "invisible", that is:
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
this also applies when using the `env`, `let` and `for` builtin extensions.

while parens-8 supports the same multiple return values behavior as lua, it lacks the `...` syntax for variadics. the `id`, `select`, `pack` and `unpack` functions should be leveraged when handling parameter packs.

`'` and `"` can't be escaped in parens-8 strings, but you can use either as quotes:
```lisp
(print "hello, here's a single quote")
(print 'sure... a single "quote", I think we call this an apostrophe')
(print "don't make fun of me, you can't even say 'can't'")
(print "y'all know the `..` operator exists, right?")
```

troubleshooting errors is somewhat challenging, as the language itself makes no attempt at diagnostics. debugging compiled parens-8 is slightly easier, as you can at least tell if something is a syntax error or a runtime error.

## misc

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

the compiler separates the AST traversal from evaluation by returning a chain of closures with the pre-compiled AST held in upvalues. this does make each `parens8` call slower, but functions defined within that call are much faster.

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

## acknowledgements

* Peter Norvig's [excellent tutorial](https://norvig.com/lispy.html) on how to implement your own lisp.
* [luchak](https://github.com/luchak) helped quite a bit with the compiler, and I borrowed a few tricks from his own pico-8 lisp implementations.
* [carlc27843](https://carlc27843.github.io/), for the tantalizing [blog post](https://carlc27843.github.io/post/picoscript/) that inspired me to implement my own extension language.
* [Wuff](https://wuffmakesgames.itch.io/), for integrating parens-8 into PicOS, and putting up with my shenanigans.
* the pico-8 discord server, for all the help, inspiration and resources a developer could ask for.
