f = ->
	a = b
	b = c
	c = a
	a :- A

x = y
y = x
z = w
w = z
y :- Y
z :- Z