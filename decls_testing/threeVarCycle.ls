f = (x :- X) ->
	b = a
	c = b
	a = c
	a :- K
e :- L
e = f(x)

g = (x :- X) ->
	b = a
	a = b
	b :- M
n :- N
n = g(x)