# Test for multiple bad assignments

f = (a :- A, b :- B) ->
	a = b


g = (a :- A, b :- B) ->
	c = a
	d = b
	c = d

h =  ->
	a = b
	b = c
	c = d
	d = a
	a :- A
	c :- C

x = y
y = z
z = w
w = v
v :- V
x :- X