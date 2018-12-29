# Function to remove all "type declarations"
# from a given text

def remove_decls(text)
	text.gsub(/\r\n?/, "\n")
	res = text.gsub(/:= *[A-Za-z]{1}[A-Za-z0-9_]*/, " ")
	return res
end

text = "
f(a := A, b:= B, c, d, f:=     F) ->
	a

g(a, b, c) ->
	a

h(x := int, y := double, z := A) ->
	x * y
"

# puts remove_decls(text)