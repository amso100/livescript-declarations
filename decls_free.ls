# Test for multiple bad assignments

f = (a  , b  ) ->
	a = b


g = (a  , b  ) ->
	c = a
	d = b
	c = d

h =  ->
	a = b
	b = c
	c = d
	d = a
	 
	 

x = y
y = z
z = w
w = v
 
 