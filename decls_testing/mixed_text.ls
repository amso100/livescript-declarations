class A extends int
class B extends int
class C extends B
class M extends B

f = (a, b, c) ->
	a :- A
	b = new B
	c = new C
	a

g = (a, b, c) ->
	f(a, b, c)
	b :- B
	c

h = (a, b, c, d) ->
	g(new A, new B, new C)
	a = b
	b = a
	b :- B

	d = c
	c = d
	c :- C

j = (a) ->
	a :- A
	m
	m :- M


x = j(new A)
