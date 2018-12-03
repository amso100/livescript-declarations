class A extends int
class B extends A
class C extends A
class D extends A
class A extends E
class E extends int

a := A

A2B = (a := A) ->
	b = new B
	b = someBFunction(a)

d = new D
d := D

bee = (b_1 := B, b_2  :=    B) ->
	A2B(b_1 + b_2)

g := Gl

AandC = (a := A,c := C) ->
	bb = A2B(c)
	d = new C
	d = A2B(bb)

r := Rr

a = new A
b1 = A2B(a)
b1 := B	
b2 = A2B(a)
b2 := A
bee(b1,b2)
c1 = new C
c1 := C
cc = AandC(b1,c1)
cc := A

