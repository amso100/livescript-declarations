
class A extends int
a = new A
a :- A 
f = (a :- A) ->
	a 
b = new A
g = (a :- B, c :- B) ->
	a
	c
	b
h =      ->
	10

j =  ->
	h()
	"i"
j()