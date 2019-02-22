class X extends int
class Y extends X
class Z extends Y
class W extends X

g = ->
	x1

x1 :- X

x2 :- X

h = (y :- Y, z :- Z) ->
	y = new Y
	z = new Z
	y

i = ->
	"i"

k = (a, b, c) ->
	a :- X
	b :- X
	c :- Z
	a
	b
	c
x0 = k(x1, x2, z1)
