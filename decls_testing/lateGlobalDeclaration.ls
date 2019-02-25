class A extends int
class B extends A
class C extends B
class D extends B
class E extends B

f = (a :- A,b :- B) ->
	a

g = (a, b :- B) ->
	b

m = g(new A, b0)

b0 :- B


m :- A
n :- B
