
class A extends int
class B extends int
class C extends int

f = (a, b, c) ->
	a
	b
	c

g = (a, b  ) ->
	a

f(new A, new B, new C)

g(new A, b0)