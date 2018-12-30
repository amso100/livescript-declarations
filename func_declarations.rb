# Here we will create a hash where for each function, the argument types will be listed.
# Undeclared arguments will be given as T'-1, T'-2, ...
# Entry example:
# 	"f" -> ["A", "B", "T'-1", "A"]

def get_function_declarations(text)
	text.gsub!(/\r\n?/, "\n")
	lineno = 1
	aribtrary_count = 0
	
	functions_dict = Hash.new

	text.each_line do |line|
		func_name = ""
		
		# Test for function with multiple arguments
		if line =~ /[A-Za-z]{1}[A-Za-z0-9_]* *= *\(([A-Za-z]{1}[A-Za-z0-9_]* *:= *[A-Za-z]{1}[A-Za-z0-9_]*,? *|[A-Za-z]{1}[A-Za-z0-9_]*,? *)*\) *->/
			line.scan(/([A-Za-z]{1}[A-Za-z0-9_]*) *= *\(/) do |m|
				func_name = m[0]
				functions_dict[func_name] = Array.new
			end
			line[func_name.length..-1].scan(/([A-Za-z]{1}[A-Za-z0-9_]* *:= *[A-Za-z]{1}[A-Za-z0-9_]*,? *|[A-Za-z]{1}[A-Za-z0-9_]*,? *)/) do |m|
				a = m[0].scan(/([A-Za-z]{1}[A-Za-z0-9_]*)/)
				if a.length > 1
					# puts "var is #{a[0][0]}, Type is #{a[1][0]}"
					functions_dict[func_name] << a[1][0]
				else
					# puts "var is #{a[0][0]}"
					functions_dict[func_name] << "T'-#{aribtrary_count}"
					aribtrary_count += 1
				end
			end

		# Test for functions without any arguments
		elsif line =~ /[A-Za-z]{1}[A-Za-z0-9_]* *= *->\n/
			line.scan(/[A-Za-z]{1}[A-Za-z0-9_]*/) do |m|
				func_name = m[0]
				functions_dict[func_name] = Array.new
				functions_dict[func_name] << "unit"
			end
		end
		lineno += 1
	end
	return functions_dict
end

text = "
f = (a := A, b:= B, c, d, f:=     F) ->
	a

g = (a, b, c) ->
	a 
	b
	c

h = (x := int, y := double, z := A) ->
	x * y

j  = ->
	1
"

res = get_function_declarations(text)
res.each_pair do |key, value|
	puts "Function: #{key}"
	puts "Arg types: #{value}"
end