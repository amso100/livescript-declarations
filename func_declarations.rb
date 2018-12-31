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

class FunctionDeclaration
	attr_accessor :name, :scope, :args, :return_type
	def initialize(name, scope)
		@name = name
		@scope = scope
		@args = Array.new
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

def single_var_return_statement(line)
	if line =~ /^\t+[A-Za-z]+[A-Za-z0-9_]* *$/
		return line[/[A-Za-z0-9_]+/]
	else
		return false
	end
end

def var_equals_exp_return_statement(line)
	if line =~ /^\t+[A-Za-z]+[A-Za-z0-9_]* *= *.+\n/
		return line[/[A-Za-z0-9_]+/]
	else
		return false
	end
end

def constant_return_statement(line)

	if line =~ /\t+[0-9]+\.[0-9]+/
		return [line[/[0-9]+(.[0-9]+)?/], "double"]

	elsif line =~ /\t+\".*\"/
		return [line[/\".*\"/], "string"]
	elsif line =~ /\t+\'.*\'/
		return [line[/\'.*\'/], "string"]
	elsif line =~ /\t+\\.*/
		return [line[/\\.*/], "string"]

	elsif line =~ /\t+[0-9_]+[A-Za-z]*/
		return [line[/[0-9_]+[A-Za-z]*/], "int"]

	elsif line =~ /\t+(true|false|on|off|yes|no)/
		return [line[/(true|false|on|off|yes|no)/], "bool"]

	elsif line =~ /\t+\[.*\]/
		return [line[/\[.*\]/], "list"]

	elsif line =~ /\t\{.+\}/
		return [line[/\{.+\}/], "dict"]

	else
		return nil
	end
end

def function_call_return_statement(line)
	if line =~ /\t+[A-Za-z0-9_]+\(.*\)/
		return line[/[A-Za-z0-9_]+/]
	else
		return false
	end
end

def parse_for_type(line, local_vars, global_vars, func_name, funcs_dict)
	var1 = single_var_return_statement(line)
	var2 = var_equals_exp_return_statement(line)
	var3 = constant_return_statement(line)
	var4 = function_call_return_statement(line)
	if var1 != false
		# puts "111"
		if local_vars[func_name] != nil and local_vars[func_name].keys.include?(var1)
			return local_vars[func_name][var1].declared_type
		elsif global_vars.keys.include?(var1)
			return global_vars[var1].declared_type
		else
			return nil
		end

	elsif var2 != false
		# puts "222"
		if local_vars[func_name] != nil and local_vars[func_name].keys.include?(var2)
			return local_vars[func_name][var2].declared_type
		elsif global_vars.keys.include?(var2)
			return global_vars[var2].declared_type
		else
			return nil
		end

	elsif var3 != nil
		# puts "333"
		return var3[1]

	elsif var4 != false
		# puts "444"
		if funcs_dict.keys.include?(var4)
			return funcs_dict[var4].return_type
		end

	else
		puts "Error identifying return variable"
	end
	return nil

end

# Returns 3 dictionaries, in the following order:
# 	1. functions_dict:
# 	A dictionary that contains for each function its argument types
# 	
#   2. global_vars:
# 	A dictionary that contains the program's global variables (if any exist)
#
# 	3. local_vars:
# 	A dictionary that contains each function's variables whose types were declared.
def get_program_declarations(text)
	text.gsub!(/\r\n?/, "\n")
	lineno = 1
	aribtrary_count = 0
	in_function = false
	prev_line = nil
	scopeno = -1
	max_scope = -1
	first_function = true
	func_name = ""
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

		# If empty line, continue
		if line.strip.length == 0
			lineno += 1
			next
		
		# Test for function with multiple arguments
		elsif lineIsParamsFunctionStart(line)
			if in_function == true
				ret_type = parse_for_type(prev_line, local_vars, global_vars, func_name, functions_dict)
				if ret_type != nil
					functions_dict[func_name].return_type = ret_type
				else
					# puts "Return type of function #{func_name} could not be determined."
				end
			end
			# puts "At line #{ind}, scope is #{scopeno}"

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
				functions_dict[func_name] = FunctionDeclaration.new(func_name, scopeno)
			end
			line[func_name.length..-1].scan(/([A-Za-z]{1}[A-Za-z0-9_]* *:= *[A-Za-z]{1}[A-Za-z0-9_]*,? *|[A-Za-z]{1}[A-Za-z0-9_]*,? *)/) do |m|
				a = m[0].scan(/([A-Za-z]{1}[A-Za-z0-9_]*)/)
				if a.length > 1
					# puts "var is #{a[0][0]}, Type is #{a[1][0]}"
					local_vars[func_name][a[0][0]] = TypeDeclaredVar.new(a[0][0], a[1][0], func_name, ind, scopeno)
					functions_dict[func_name].args << a[1][0]
				else
					# puts "var is #{a[0][0]}"
					functions_dict[func_name].args << "T'-#{aribtrary_count}"
					aribtrary_count += 1
				end
			end
			# puts line
			# puts "scope = #{scopeno}"

		# Test for functions without any arguments
		elsif lineIsNoParamsFunctionStart(line)
			if in_function == true
				ret_type = parse_for_type(prev_line, local_vars, global_vars, func_name, functions_dict)
				if ret_type != nil
					functions_dict[func_name].return_type = ret_type
				else
					puts "Return type of function #{func_name} could not be determined."
				end
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
				functions_dict[func_name] = FunctionDeclaration.new(func_name, scopeno)
				functions_dict[func_name].args << "unit"
			end
			# puts line
			# puts "scope = #{scopeno}"

		# If exited scope and previous line is not null, parse
		elsif prev_line != nil and count_tabs_at_start(line) == 0
			ret_type = parse_for_type(prev_line, local_vars, global_vars, func_name, functions_dict)
			if ret_type == nil
			end
			if ret_type != nil
				functions_dict[func_name].return_type = ret_type
			else
				puts "Return type of function #{func_name} could not be determined."
			end
			in_function = false
			scopeno = 0
			# puts line
			# puts "scope = #{scopeno}"

			declarations = get_line_declarations(line)
				declarations.each_pair do |name, type|
					global_vars[name] = TypeDeclaredVar.new(name, type, "", ind, scopeno)
				end

		# Otherwise, we're in a regular function line (or global line) 
		# and want to search for declarations
		else
			if in_function == true
				# puts line
				# puts "scope = #{scopeno}"
				# puts line
				# puts "Regular function line"
				declarations = get_line_declarations(line)
				declarations.each_pair do |name, type|
					local_vars[func_name][name] = TypeDeclaredVar.new(name, type, func_name, ind, scopeno)
				end
			else
				# puts line
				# puts "scope = 0"
				# puts "Global line"
				declarations = get_line_declarations(line)
				declarations.each_pair do |name, type|
					global_vars[name] = TypeDeclaredVar.new(name, type, "", ind, scopeno)
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
		ret_type = parse_for_type(prev_line, local_vars, global_vars, func_name, functions_dict)
		functions_dict[func_name].return_type = ret_type
	end

	# local_vars.each_pair do |k,v|
	# 	puts "Function #{k}"
	# 	v.each_pair do |name, data|
	# 		puts "#{name} := #{data.declared_type} (line #{data.lineno}) (scope #{data.scope})"
	# 	end
	# 	puts "End Function #{k}"
	# end

	# puts "Global variables:"
	# global_vars.each_pair do |k,v|
	# 	puts "#{k} := #{v.declared_type} (line #{v.lineno}) (scope #{v.scope})"
	# end

	return [functions_dict, global_vars, local_vars]
end

# text = "
# m := M
# d := D

# f = (a := A, b:= B, c, d, e:=     F) ->
# 	a
# g = (a, b, c) ->
# 	a 
# 	b
# 	c
# h = (x := int, y := double, z := A) ->
# 	x * y

# j  = (a := D, b := D, c := C) ->
# 	1
# "

text = "
m = new M
m := M
f = (a := A, c:=C) ->
	b := B
	b = new B
	0
h = (a := A) ->
	f(a)
g = (c := C) ->
	c
j =  ->
	\'i\'

k =  ->
	m
"

# text = "
# class A extends int
# a = new A
# a := A 
# f = (a := A) ->
# 	a 
# b = new A
# g = (a := B, b := B) ->
# 	b
# h =      ->
# 	10

# j =  ->
# 	\"i\"
# "

res = get_program_declarations(text)

res_funcs = res[0]
res_globs = res[1]
res_vars  = res[2]

puts "Functions:"
res_funcs.each_pair do |key, value|
	puts "Function name: #{value.name}"
	puts "Function Scope: #{value.scope}"
	puts "Arg types: #{value.args}"
	if value.return_type != nil
		puts "Return Type: #{value.return_type}"
	else
		puts "Return Type: Could not be determined."
	end
	puts ""
end

puts "Globals:"
res_globs.each_pair do |key, value|
	puts "Global name: #{value.name}"
	puts "Global Scope: #{value.scope}"
	puts "Global Type: #{value.declared_type}"
	puts "Global line: #{value.lineno}"
	puts ""
end

puts "Local Variables:"
res_vars.each_pair do |key, data|
	puts "Variable declared in #{key}:"
	data.each_pair do |k, value|
		puts "\tVar name: #{value.name}"
		puts "\tVar Scope: #{value.scope}"
		puts "\tVar Type: #{value.declared_type}"
		puts "\tVar line: #{value.lineno}"
		puts "\t----------"
	end
	puts "------------------"
end
