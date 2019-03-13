
f1 = (a :- A) ->
	-1

f2 = (a :- A, b :- B) ->
	b

f3 = (a :- A, b) ->
	b
	b :- B

f4 = (a :- A, b :- B, c :- C) ->
	a
	b
	c

f5 = (a, b, c) ->
	a :- A
	b :- B
	c = a

f6 = (a, b, c) ->
	a :- A
	c = b
	b :- B

f7 = (a,b) ->
	a = b
	b = a
	b :- A

f8 = (a :- int, b :- int) ->
	min(a, b)

n = f8(x0, y0)
n :- int

f9 = (x, y, z, w) ->
	x = y
	y = z
	z = w
	w = x
	y :- M

