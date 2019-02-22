class A extends int
class B extends A
class C extends B
class D extends B
class E extends B

f = (a :- A,b :- B) ->
	a

g = (a :- A, b :- B) ->
	b

m :- A
n :- B