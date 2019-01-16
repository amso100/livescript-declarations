class X extends int
class Y extends X
class Z extends Y
class W extends X
x1 = new X
x2 = new X

f = (w1 :- W, w2 :- W) ->
	max(w1, w2)

g = ->
	x1

x1 :- X
x2 :- X

h = (y :- Y, z :- Z) ->
	y = new Y
	z = new Z
	y

i = ->
	\"i\"

k = (a, b, c) ->
	a :- X
	b :- Y
	c :- Z
	a
	b
	c
x0 = k(x1, x1, x1)

n = i()
