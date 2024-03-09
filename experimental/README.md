# experiments

experimantal implementations with alternative stack/frame/upvalue implementations.

don't use these unless you have a good reason to (upvalue lifetime is an issue) and you know what you're doing. I have _not_ ported extensions for these.

## curried
instead of passing upvalues _with_ the frame, pass it to the child expression tree on closure instantiation (when new upvalues are needed).

pros:
- no upvalue lifetime issues from v3
- marginally faster function overhead
cons:
- _much_ slower closure instantiation (problematic with `let`, `for`, `env`, etc)
- a lot more tokens

## stack
instead of piggybacking the lua stack with activation frames, do our own stack management in functions.

pros:
- no upvalue lifetime issues from v3
- potentially faster for complex expressions (nullary calls instead of unary calls)
cons:
- no tail call elimination (bad, can't do recursion loops anymore)
- function overhead is slower
