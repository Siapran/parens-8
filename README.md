![(parens-8)](parens-8.png)

a tiny lisp for your pico-8 carts

## overview

parens-8 is designed for maximum interoperability with lua. lua functions and values can be called and passed from parens-8, and vice-versa. the `parens8` function evaluates parens-8 expressions passed as strings:

```lua
a, b, c = parens8[[1 2 3]]
?(b == 2) -- true

?parens8[[(mid a b c)]] -- 2

parens8[[
(fn (x) (print x))
]](42) -- 42
```

parens-8 has the same multiple return values behavior as lua, though it lacks the syntax for variadics. leverage `id`, `select`, `pack` and `unpack` to your advantage.

parens-8 comes with four base builtins:
* `(set a b)`, for assignment, aka `a = b`
* `(fn (a b c) expr)`, for lambdas, aka `function (a, b, c) return expr end`
* `(when cond a b)`, for conditionals, aka `(function() if cond then return a else return b end end)()`
* `(quote expr)`, for preventing an expression from being evaluated.

note that `"foo"` is translated into `(quote foo)` by the parser. you can also create lua arrays this way: `(quote (1 2 3))`

## interpreter vs compiler

parens-8 comes in two flavors:
* the interpreter: 402 tokens, found in `interpreter/parens8.lua`
* the compiler: 440 tokens, found in `compiler/parens8.lua`

both flavors support the same features, and while heavier in tokens and memory usage, compiled parens-8 is over twice as fast as interpreted parens-8. extensions also take a few more tokens each for compiled parens-8, speaking of which...

## parens-8 extensions

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

## limitations

parens-8 has a few limitations that are here to stay, in the interest of token economy.

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

## performance

well, it's no [picoscript](https://carlc27843.github.io/post/picoscript/), but compiled parens-8 isn't too far off. benchmarking parens-8 against native lua and the hand-expanded picoscript closure from the blog post gives the following results:

| language | time / native | native / time |
| --- | --- | --- |
| native lua | 1 | 100% |
| picoscript | 1.3088 | 76.4023% |
| parens-8 interpreter | 8.4138 | 11.8851% |
| parens-8 compiler | 4.1508 | 24.0906% |

parens-8 is first and foremost designed for "glue" code: bits and pieces of logic you'd rather pay for in overhead instead of tokens. what parens-8 doesn't have in performance, it makes up for in flexibility and accessibility.

## ROM utilities

if (when) you run out of chars in your cart's code, you can store more code in the ROM of other carts. this is easily done via the utilities found in `parens-8/romutils/`:
* `small = minify(code)` removes as much whitespace from your parens-8 code as possible
* `length = writerom(small, address, filename)` `cstore`s your string in the data of `filename`
* `loaded = parens8(readrom(address, length, filename))` reads and parses your code back at you.

`readrom` is implemented in pure parens-8, without any extensions! it's the perfect example of glue code.

## misc

parens-8, like lua, supports tail call elimination. this can be leveraged if you plan on foregoing flow extensions:
```lisp
(set loop
     (fn (i)
         (loop (+ i 1)
               (print (.. (stat 0)
                          (.. " " i))))))
(loop 1)
```

there's a, uh, parens-8 syntax highlighter? I guess? it colors literals and matching parenthesis pairs, using p8scii control codes.

## acknowledgements

* Peter Norvig's [excellent tutorial](https://norvig.com/lispy.html) on how to implement your own lisp.
* [luchak](https://github.com/luchak) helped quite a bit with the compiler, and I borrowed a few tricks from his own pico-8 lisp implementations.
* [carlc27843](https://carlc27843.github.io/), for the tantalizing [blog post](https://carlc27843.github.io/post/picoscript/) that inspired me to implement my own extension language.
* [Wuff](https://wuffmakesgames.itch.io/), for integrating parens-8 into PicOS, and putting up with my shenanigans.
* the pico-8 discord server, for all the help, inspiration and resources a developer could ask for.
