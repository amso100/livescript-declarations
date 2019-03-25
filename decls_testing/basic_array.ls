# Test for entire array declarations

arr = [x1, x2, x3]
a = arr[i]
arr :- [int]

brr = [y1, y2, y3]
y1 :- int
y2 :- float
y3 :- float

crr = []
crr :- [[int]]

drr = [[y1], [y2], [3.0]]
drr :- [[float]]