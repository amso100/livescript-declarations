# Test for multiple bad assignments

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
