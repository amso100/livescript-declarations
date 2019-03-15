f = ->
	a = b
	b = c
	c = a
	a :- A
	b :- B

x :- X
x = y
y = x
y :- Y