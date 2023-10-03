![(parens-8)](parens-8.png)

a tiny lisp for your pico-8 carts

## overview

parens-8 is designed for maximum compatibility with lua. lua functions and values can be called and passed from parens-8, and vice-versa. the `parens8` function evaluates a string as a parens-8 expression:

```lua
a, b, c = parens8[[1 2 3]]
?(b == 2) -- true

?parens8[[(mid a b c)]] -- 2

parens8[[
(fn (x) (print x))
]](42) -- 42
```

parens-8 has the exact same multiple return values semantics as lua, though it lacks the syntax for variadics. leverage `id`, `select`, `pack` and `unpack` to your advantage.

parens-8 comes with four base builtins:
* `(set a b)`, for assignment, aka `a = b`
* `(fn (a b c) expr)`, for lambdas, aka `function (a, b, c) return expr end`
* `(when cond a b)`, for conditionals, aka `(function() if cond then return a else return b end end)()`
* `(quote expr)`, for preventing an expression from being evaluated.

note that `"foo"` is translated into `(quote foo)` by the parser. you can also create lua arrays this way: `(quote (1 2 3))`

## parens-8 extensions

while designed as a lightweight (404 tokens!) runtime for offloading code to strings and ROM, parens-8 has extensions to turn it into a fully featured programming language.

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

extensions can be found in `parens-8/builtin/`. include the extensions you need, and feel free to comment out builtins you aren't using.

you may also define you own builtins using the `def_builtin` function found in `builtin/def_builtin.lua`. builtins can even be defined from within parens-8!
```lisp
(def_builtin "if"
  (fn (ev exp)
      (when (ev 2)
        (ev 3)
        (when ([] exp 4)
          (ev 4)))))

(if 1 (print "A") (print "B"))
```

this opens up interesting avenues for metaprogramming. in fact, all the builtins in `builtin/flow.lua` could be implemented in pure parens-8 (yes, even `while`, using tail recursion).

## limitations

parens-8 has a few limitations that will stay, in the interest of token economy.

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

well, it's far from being [picoscript](https://carlc27843.github.io/post/picoscript/), I'll tell you that much. a parens-8 implementation of the identity function `(fn (x) x)` is about six times slower than native lua, and it only gets worse with scale. every access to a symbol is liable to go through a pretty long chain of `__index` metamethods for scope resolution, and that bogs down performance pretty dramatically.

parens-8 is first and foremost designed for "glue" code, bits and pieces of logic you'd rather pay for in overhead instead of tokens. what parens-8 doesn't have in performance, it makes up for in flexibility and accessibility.

## ROM utilities

if (when) you run out of chars in your cart's code, you can store more code in the ROM of other carts. this is easily done via the utilities found in `parens-8/romutils/`:
* `small = minify(code)` removes as much whitespace from your parens-8 code as possible
* `length = writerom(small, address, filename)` `cstore`s your string in the data of `filename`
* `loaded = parens8(readrom(address, length, filename))` reads and parses your code back at you.

`readrom` is implemented in pure parens-8, without any extensions! it's the perfect example of glue code.

## misc

there's a, uh, parens-8 syntax highlighter? I guess? it colors literals and matching parenthesis pairs.

## acknowledgements

* Peter Norvig's [excellent tutorial](https://norvig.com/lispy.html) on how to implement your own lisp.
* [Wuff](https://wuffmakesgames.itch.io/), for integrating parens-8 into PicOS, and putting up with my shenanigans.
* [luchak](https://github.com/luchak), for showing me his own pico-8 lisp interpreter (I stole a couple bits).
* the pico-8 discord server, for all the help and resources a developer could ask for.
