class M extends string
class B extends string


m :- M

f = (a :- A, b) ->
	b = new B
	b :- B


h = (a :- A) ->
	f(a,a)

g = (c :- C) ->
	h(c)
j =  ->
	"i"

p = (n :- N) ->
	j()

q = (n :- N) ->
	g(n)

s = ->
	q(m)

k =  ->
	m
