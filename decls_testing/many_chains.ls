f = (a, b, c, d) ->
	a = b
	b = c
	c = d
	d = a

	x = y
	y = z
	z = x

	x1 = x2
	x2 = x1

	d :- A
	z :- Z
	x1 :- X

x1 = x2
x2 = x3
x3 = x4
x4 = x5
x5 = x1

y1 = y2
y3 = y4
y2 = y3
y4 = y1

x3 :- X
y3 :- Y
