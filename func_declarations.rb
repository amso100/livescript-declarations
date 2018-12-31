# Here we will create a hash where for each function, the argument types will be listed.
# Undeclared arguments will be given as T'-1, T'-2, ...
# Entry example:
# 	"f" -> ["A", "B", "T'-1", "A"]

class TypeDeclaredVar
	attr_accessor :name, :declared_type, :funcScope, :lineno, :scope
	def initialize(name, declared_type, funcScope, lineno, scope)
		@name  = name
		@declared_type  = declared_type
		@funcScope = funcScope
		@lineno = lineno
		@scope = scope
	end
end

def lineIsParamsFunctionStart(line)
	if line =~ /[A-Za-z0-9]+ *= *\([A-Za-z0-9,_ :=]*\) ->\n?/
		return true
	else
		return false
	end
end

def lineIsNoParamsFunctionStart(line)
	if line =~ /[A-Za-z0-9]+ *= *->\n?([A-Za-z0-9]*)?/
		return true
	else
		return false
	end
end

def lineIsFunctionStart(line)
	if lineIsParamsFunctionStart(line) or lineIsNoParamsFunctionStart(line)
		return true
	else
		return false
	end
end

def count_tabs_at_start(line)
	c = 0
	while line[c].ord == 9 do
		c += 1
	end
	return c
end

def get_line_declarations(line)
	declarations = Hash.new
	line.scan(/[a-zA-z_]{1}[A-Za-z0-9_]* *:= *[a-zA-z_]{1}[A-Za-z0-9_]*/) do
		|match| a = match.scan(/[a-zA-z_]{1}[A-Za-z0-9_]*/)[0]
		b = match.scan(/[a-zA-z_]{1}[A-Za-z0-9_]*/)[1]
		declarations[a] = b
	end
	return declarations
end

def lineHasGlobalVariable(line)
	return (line.scan(/^[A-Za-z0-9]+ *= */).size > 0)
end

def global_variables_exist(text)
	text.each_line do |line|

		# Only want the global variables, function lines come later.
		if lineHasGlobalVariable(line) and not lineIsFunctionStart(line)

			# puts line
			return true
		end
	end
	return false
end

def parse_for_type(line)
	# puts "Parsing line: #{line}"
end

def get_function_declarations(text)
	text.gsub!(/\r\n?/, "\n")
	lineno = 1
	aribtrary_count = 0
	in_function = false
	prev_line = nil
	scopeno = -1
	max_scope = -1
	first_function = true
	global_vars = Hash.new

	if global_variables_exist(text)
		puts "Globals"
		scopeno = 1
	else
		puts "No globals"
		scopeno = 0
	end

	max_scope = scopeno

	# global_vars: Hash var_name->declared_type
	# local_vars : Hash func_name->var_name->declared_type

	local_vars = Hash.new
	
	functions_dict = Hash.new

	text.split("\n").each_with_index do |line, ind|
		func_name = ""

		# If empty line, continue
		if line.strip.length == 0
			next
		
		# Test for function with multiple arguments
		elsif lineIsParamsFunctionStart(line)
			if in_function == true
				parse_for_type(prev_line)
			end
			puts "At line #{ind}, scope is #{scopeno}"

			if not first_function
				scopeno = max_scope + 1
			else
				first_function = false
				scopeno = max_scope
			end

			in_function = true

			line.scan(/([A-Za-z]{1}[A-Za-z0-9_]*) *= *\(/) do |m|
				func_name = m[0]
				local_vars[func_name] = Hash.new
				functions_dict[func_name] = Array.new
			end
			line[func_name.length..-1].scan(/([A-Za-z]{1}[A-Za-z0-9_]* *:= *[A-Za-z]{1}[A-Za-z0-9_]*,? *|[A-Za-z]{1}[A-Za-z0-9_]*,? *)/) do |m|
				a = m[0].scan(/([A-Za-z]{1}[A-Za-z0-9_]*)/)
				if a.length > 1
					# puts "var is #{a[0][0]}, Type is #{a[1][0]}"
					local_vars[func_name][a[0][0]] = TypeDeclaredVar.new(a[0][0], a[1][0], func_name, ind)
					functions_dict[func_name] << a[1][0]
				else
					# puts "var is #{a[0][0]}"
					functions_dict[func_name] << "T'-#{aribtrary_count}"
					aribtrary_count += 1
				end
			end
			puts line
			puts "scope = #{scopeno}"

		# Test for functions without any arguments
		elsif lineIsNoParamsFunctionStart(line)
			if in_function == true
				parse_for_type(prev_line)
			end

			if not first_function
				scopeno = max_scope + 1
			else
				first_function = false
				scopeno = max_scope
			end

			in_function = true

			line.scan(/[A-Za-z]{1}[A-Za-z0-9_]*/) do |m|
				func_name = m[0]
				local_vars[func_name] = Hash.new
				functions_dict[func_name] = Array.new
				functions_dict[func_name] << "unit"
			end
			puts line
			puts "scope = #{scopeno}"

		# If exited scope and previous line is not null, parse
		elsif prev_line != nil and count_tabs_at_start(line) == 0
			parse_for_type(prev_line)
			in_function = false
			scopeno = 0
			puts line
			puts "scope = #{scopeno}"

			declarations = get_line_declarations(line)
				declarations.each_pair do |name, type|
					global_vars[name] = TypeDeclaredVar.new(name, type, "", ind)
				end

		# Otherwise, we're in a regular function line (or global line) 
		# and want to search for declarations
		else
			if in_function == true
				puts line
				puts "scope = #{scopeno}"
				# puts line
				# puts "Regular function line"
				declarations = get_line_declarations(line)
				declarations.each_pair do |name, type|
					local_vars[func_name][name] = TypeDeclaredVar.new(name, type, func_name, ind)
				end
			else
				puts line
				puts "scope = 0"
				# puts "Global line"
				declarations = get_line_declarations(line)
				declarations.each_pair do |name, type|
					global_vars[name] = TypeDeclaredVar.new(name, type, "", ind)
				end
			end
		end

		if scopeno >= max_scope
			max_scope = scopeno
		end
		prev_line = line
		lineno += 1
	end

	# If exited program with a "leftover" line remaining, test it.
	if prev_line != nil and count_tabs_at_start(prev_line) > 0
		parse_for_type(prev_line)
	end

	local_vars.each_pair do |k,v|
		puts "Function #{k}"
		v.each_pair do |name, data|
			puts "#{name} := #{data.declared_type} (#{data.lineno})"
		end
		puts "End Function #{k}"
	end

	puts "Global variables:"
	global_vars.each_pair do |k,v|
		puts "#{k} := #{v.declared_type} (#{v.lineno})"
	end

	return functions_dict
end

# text = "
# m := M
# d := D

# f = (a := A, b:= B, c, d, f:=     F) ->
# 	a
# g = (a, b, c) ->
# 	a 
# 	b
# 	c
# h = (x := int, y := double, z := A) ->
# 	x * y

# j  = ->
# 	1
# "

text = "
class A extends int
a = new A
a := A 
f = (a) ->
	a 
b = new A
g = (a,b) ->
	b
h =      ->
	10

j =  ->
	\"i\"
"

res = get_function_declarations(text)
res.each_pair do |key, value|
	puts "Function: #{key}"
	puts "Arg types: #{value}"
end