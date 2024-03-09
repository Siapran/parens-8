# performance details for parens-8 v3

note: the cost of evaluating _any_ expression is 7 cycles (calling the expression closure with activation frame). this cost is omitted in the parens-8 measurements below, treat them like extra overhead _on top_ of evaluating the necessary expressions.

---

calling from parens-8:
- no args: 10 cycles (native: 6)
- one arg expression: 10 + 2 cycles (native: 7)
- N+1 arg expressions: 10 + 2 + N * 9 cycles (native: 7+N)

---

- no overhead for passing args returned from a call (this means things like reading from ROM with `(chr (peek addr len))` only has the overhead of calling `chr` with _one_ arg expression, not `len`)

---

- parens-8 function overhead (when a parens-8 function is called): 7 cycles

---

- evaluating an upvalue: 8 cycles (native: 2)
- evaluating a global: 8 cycles (native: 2)
- evaluating a local: 2 cycles (native: 0)
- evaluating a constant: 0 cycles (native: 1)

---

- assigning to an upvalue: 10 cycles (native: 2)
- assigning to a global: 10 cycles (native: 2)
- assigning to a local: 4 cycles (native: 0)

---

- conditional: 9 cycles (native: 1)

---

closure creation:
- no overhead for closures with no new captures (reuses parent captures)
- 16 cycles for first scope captured
- 8 cycles per extra scope

captures are performed eagerly:
- (fn (a) (fn () (fn () a))) captures are performed when the `(fn () (fn () a))` expression is evaluated, not when `(fn () a)` is evaluated. `(fn () a)` reuses the same captures as `(fn () (fn () a))`
- when a closure _does_ capture a new scope, it rebuilds a flat upvalue table from the parent upvalue tables and the parent frame
