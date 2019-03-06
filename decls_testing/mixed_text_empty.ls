class A
class B
class C extends B
class M extends B

f = (a, b, c) ->
	b = new B
	c = new C
	a

g = (a, b, c) ->
	f(a,b,c)
	c

h = (a, b, c, d) ->
	a = b
	b = a

	d = c
	c = d

j = (a) ->
	m

x = j(new A)