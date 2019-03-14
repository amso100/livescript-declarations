class B
class A

f = (a1 :- A, b1 :- B) ->
	a1
	b1
	a1

a = b
b = c
c = d

x1 = x2
x3 = x4
x5 = x6

y1 = y2
y2 = y3
y3 = y4

y4 :- Y
x4 :- X
x2 :- X
d :- A

x = f(a, new B)
