######
#This test checks that composite types subtyping
#is considered when infering the type of the array,
#even when items altering the infered type are added after initilization.
#in this example, we will use classes A and B
######
#EXPECTED OUTPUT:
#arr type is [A].
######

class A
class B extends A

b1 = new B
b2 = new B
a1 = new A

arr = [b1,b2]
arr[2] = a1

