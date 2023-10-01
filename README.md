# parens-8
a tiny lisp for your pico-8 carts

## overview

parens-8 is designed for maximum compatibility with lua. lua functions and values can be called and passed from parens-8, and vice-versa. the `parens8` function evaluates a string as a parens-8 expression:
```lua
a, b, c = parens8'1 2 3'
? b == 2

?parens8'(mid a b c)'

parens8'(fn (x) (print x))'(42)
```

parens-8 has the exact same multiple return values semantics as lua, though is lacks the syntax for variadics. use `id`, `select`, `pack` and `unpack` to your advantage:
```lua

```

parens-8 comes with four base builtins:
* `(set a b)`, for assignment, aka: `a = b`
* `(fn (a b c) expr)`, for lambdas, aka: `function (a, b, c) return expr end`
* `(when cond a b)`, for conditionals, aka `(function() if cond then return a else return b end end)()`
* `(quote expr)`, for preventing an expression from being evaluated.

note that `"foo"` is turned into `(quote foo)` by the parser. you can also create lua arrays this way: `(quote (1 2 3))`



```lua

```

while designed as a lightweight runtime for offloading code to strings and ROM, parens-8 has extensions to turn it into a fully featured programming language

```lisp
(set fib
     (fn (x) (when (< x 2)
               x
               (+ (fib (- x 1))
                  (fib (- x 2))))))

(foreach (pack 1 2 3 4 5)
         (fn (x) (id (set x (fib x))
                     (print x))))

(set mytable (zip (pack "a" "b" "c")
                  (pack 1 2 3)))

(for ((k v) (pairs mytable))
     (print (.. k (.. ": " v))))

([] mytable "b" 42)
(print ([] mytable "b"))

(env mytable
     (id (print b)
         (set b "hello!")))
(print ([] mytable "b"))
```

## usage
