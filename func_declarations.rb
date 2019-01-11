# Here we will create a hash where for each function, the argument types will be listed.
# Undeclared arguments will be given as T'-1, T'-2, ...
# Entry example:
# 	"f" -> ["A", "B", "T'-1", "A"]

require("./remove_decls.rb")

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
	attr_accessor :name, :scope, :args, :return_type, :lineno, :initialized
	def initialize(name, lineno, scope)
		@name = name
		@scope = scope
		@lineno = lineno
		@args = Array.new
		@initialized = false
	end
end

class VariableReference
	# Name: Variable's name
	# line_declared: Line in which var was declared
	# line_found: Line in which urrent instance was found
	# declared_type: The type this var was declared with (If function, nil)
	# kind: local | global | func
	attr_accessor :name, :line_declared, :line_found, :declared_type, :kind
	def initialize(name, line_declared, line_found, decl_type, kind)
		@name = name
		@line_declared = line_declared
		@line_found = line_found
		@declared_type = decl_type
		@kind = kind
	end
end

def lineIsParamsFunctionStart(line)
	if line =~ /[A-Za-z0-9]+ *= *\([A-Za-z0-9,_ :-]*\) ->\n?/
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
	line.scan(/[A-Za-z_]{1}[A-Za-z0-9_]* *:- *[A-Za-z_]{1}[A-Za-z0-9_]*/) do
		|match| a = match.scan(/[a-zA-z_]{1}[A-Za-z0-9_]*/)[0]
		b = match.scan(/[a-zA-z_]{1}[A-Za-z0-9_]*/)[1]
		declarations[a] = b
	end
	return declarations
end

def get_line_variables(line)
	vars = Array.new
	line.scan(/[A-Za-z]{1}[A-Za-z0-9_]*/) do |m|
		if m == "new" # or m == [some other keyword]
			next
		end
		vars << m 
	end
	return vars
end

def lineHasGlobalVariable(line)
	return (line.scan(/^[A-Za-z0-9]+ *= */).size > 0)
end

def lineHasFunctionCall(line)
	if line =~ /^.*[A-Za-z0-9_]+\(.*\).*/
		return line[/[A-Za-z0-9_]+\(.*\)/]
	else
		return false
	end
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
	if line =~ /^\t+[A-Za-z]+[A-Za-z0-9_]* *$/ or line =~ /^\t+[A-Za-z]+[A-Za-z0-9_]* *:- *.*$/
		return line[/[A-Za-z0-9_]+/]
	else
		return false
	end
end

def var_equals_exp_return_statement(line)
	if line =~ /^\t+[A-Za-z]+[A-Za-z0-9_]* *= *.+/
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
	if lineHasGlobalVariable(line)
		return nil
	end
	# puts line
	var1 = single_var_return_statement(line)
	var2 = var_equals_exp_return_statement(line)
	var3 = constant_return_statement(line)
	var4 = function_call_return_statement(line)
	if var1 != false
		# puts "111"
		# puts var1
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
		# puts var4
		if funcs_dict.keys.include?(var4)
			return funcs_dict[var4].return_type
		end

	else
		# puts "Error identifying return variable"
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
def get_program_declarations_aux(text, functions_dict, global_vars, local_vars)
	changed = false

	text.gsub!(/\r\n?/, "\n")
	aribtrary_count = 0
	in_function = false
	prev_line = nil
	scopeno = -1
	max_scope = -1
	first_function = true
	func_name = ""
	var_references = Array.new

	if global_variables_exist(text)
		# puts "Globals"
		scopeno = 1
	else
		# puts "No globals"
		scopeno = 0
	end

	max_scope = scopeno

	text.split("\n").each_with_index do |line, ind|

		# If empty line, continue
		if line.strip.length == 0
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
				if not functions_dict.keys.include?(func_name)
					changed = true
					local_vars[func_name] = Hash.new
					functions_dict[func_name] = FunctionDeclaration.new(func_name, ind, scopeno)
				end
			end
			if functions_dict[func_name].initialized
				# Func exists
			else
				line[func_name.length..-1].scan(/([A-Za-z]{1}[A-Za-z0-9_]* *:- *[A-Za-z]{1}[A-Za-z0-9_]*,? *|[A-Za-z]{1}[A-Za-z0-9_]*,? *)/) do |m|
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
				functions_dict[func_name].initialized = true
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
					#puts "Return type of function #{func_name} could not be determined."
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
				if not functions_dict.keys.include?(func_name)
					local_vars[func_name] = Hash.new
					changed = true
					functions_dict[func_name] = FunctionDeclaration.new(func_name, ind, scopeno)
					functions_dict[func_name].args << "unit"
				end
			end
			# puts line
			# puts "scope = #{scopeno}"

		# If exited scope and previous line is not null, parse
		elsif prev_line != nil and count_tabs_at_start(line) == 0 and count_tabs_at_start(prev_line) > 0
			ret_type = parse_for_type(prev_line, local_vars, global_vars, func_name, functions_dict)
			if ret_type != nil
				functions_dict[func_name].return_type = ret_type
			else
				#puts "Return type of function #{func_name} could not be determined."
			end
			in_function = false
			scopeno = 0
			# puts line
			# puts "scope = #{scopeno}"

			declarations = get_line_declarations(line)
			declarations.each_pair do |name, type|
				if not global_vars.keys.include?(name)
					global_vars[name] = TypeDeclaredVar.new(name, type, "", ind, scopeno)
					changed = true
				end
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

				# Identify all vars in line, and if found in dictionary, print a "reference".
				current_scope = local_vars[func_name]
				vars = get_line_variables(line)
				vars.each do |var|
					if current_scope.keys.include?(var)
						var_references << VariableReference.new(var, current_scope[var].lineno, ind, current_scope[var].declared_type, "local")
						# puts "Line #{ind}: Var #{var} is local  declared at line #{current_scope[var].lineno}"
					elsif global_vars.keys.include?(var)
						var_references << VariableReference.new(var, global_vars[var].lineno, ind, global_vars[var].declared_type, "global")
						# puts "Line #{ind}: Var #{var} is global declared at line #{global_vars[var].lineno}"
					elsif functions_dict.keys.include?(var)
						var_references << VariableReference.new(var, functions_dict[var].lineno, ind, nil, "func")
						# puts "Line #{ind}: Var #{var} is function defined at line #{functions_dict[var].lineno}"
					end
				end
			else
				declarations = get_line_declarations(line)
				declarations.each_pair do |name, type|
					global_vars[name] = TypeDeclaredVar.new(name, type, "", ind, scopeno)
				end

				if declarations.size == 0 # If no declarations found, search for used variables.
					vars = get_line_variables(line)
					vars.each do |var|
						if global_vars.keys.include?(var)
							var_references << VariableReference.new(var, global_vars[var].lineno, ind, global_vars[var].declared_type, "global")
							# puts "Line #{ind}: Var #{var} is global declared at #{global_vars[var].lineno}"
						elsif functions_dict.keys.include?(var)
							var_references << VariableReference.new(var, functions_dict[var].lineno, ind, nil, "func")
							# puts "Line #{ind}: Var #{var} is function defined at line #{functions_dict[var].lineno}"
						end
					end
				end

			end
		end
		if scopeno >= max_scope
			max_scope = scopeno
		end
		prev_line = line
	end

	# If exited program with a "leftover" line remaining, test it.
	if prev_line != nil and count_tabs_at_start(prev_line) > 0
		ret_type = parse_for_type(prev_line, local_vars, global_vars, func_name, functions_dict)
		functions_dict[func_name].return_type = ret_type
	end

	return [functions_dict, global_vars, local_vars, var_references, changed]
end

# Main Function for declarations:
# Returns an array of 3 hashs and an array.
# The hashs contain all found declarations for variables in the program
# The array contains all references from a used variable to its declaration.
def getProgramDeclarationsAndReferences(program_text)
	res_funcs = Hash.new
	res_globs = Hash.new
	res_vars  = Hash.new
	res_references = Array.new

	res = get_program_declarations_aux(program_text, res_funcs, res_globs, res_vars)

	changed = true

	while changed do
		res_funcs = res[0]
		res_globs = res[1]
		res_vars  = res[2]
		res_references = res[3]
		changed   = res[4]

		res = get_program_declarations_aux(program_text, res_funcs, res_globs, res_vars)
	end
	return [res_funcs, res_globs, res_vars, res_references]
end

# ----- Structures for parsing inferred types -----

# Class for a variable with inferred type.
class TypeInferredVar
	attr_accessor :name, :inferred_type, :scope
	def initialize(name, inferred_type, scope)
		@name  = name
		@inferred_type  = inferred_type
		@scope = scope
	end
end

class TypeInferredFunction
	attr_accessor :name, :args, :return_type
	def initialize(name, ret_type)
		@name = name
		@args = Array.new
		@return_type = ret_type
	end
end

def isArbitraryType(typeName)
	if typeName =~ /T-[0-9]+/
		return true
	elsif typeName =~ /T'-[0-9]+/
		return true
	else
		return false
	end
end

def parse_function_infers(program)
	aux = remove_decls(program)
	f_in = File.new("for_params.ls", "w")
	f_in.write(aux)
	f_in.close()
	f_inferred = `ruby type_infers.rb for_params.ls`
	functions_dict = Hash.new
	
	globals = []
	global_scope = f_inferred.split("-----\n")[1]
	global_scope.each_line do |line|
		if line =~ /->/ # Function line
			function_data = line.split(" : ")
			func_name = function_data[0]
			func_args_return = function_data[1].split("->")
			return_type = func_args_return.pop(1)[0].strip
			# puts "Func name: #{func_name}"
			# puts "Return Type: #{return_type}"
			# puts "Args List:"
			
			functions_dict[func_name] = TypeInferredFunction.new(func_name, return_type)

			func_args_return.each do |argType|
				functions_dict[func_name].args << argType
			end
		end
	end
	File.delete("for_params.ls")
	return functions_dict
end

def parse_locals_globals_infers(program)
	res = []
	tmp = []
	globals = []
	i = 0
	
	aux = remove_decls(program)
	f_in = File.new("for_params.ls", "w")
	f_in.write(aux)
	f_in.close()

	f_inferred = `ruby type_infers.rb for_params.ls`
	scopes = f_inferred.split("-----\n")
	scopes.each do |scope|
		scope.split("\n").each do |var|
			if var.include? "-"	# Don't want class/funcs declarations
				next
			end
			name = var.split(" : ")[0].strip
			type = var.split(" : ")[1].strip
			tmp << TypeInferredVar.new(name, type, i)
		end
		if scope.strip.length < 3
			next
		end

		if tmp.length == 0
			next
		end

		res = res + tmp
		tmp = []
		i += 1
	end

	if tmp.length > 0
		res = res + tmp
	end

	while res[0].scope == 0 do
		globals << res[0]
		res = res.drop(1)
	end

	res = [res, globals]

	File.delete("for_params.ls")

	return res
end

def try_to_complete_missing_types(	inferredLocals, inferredGlobals, inferredFunctions,
									declaredLocals, declatedGlobals, declaredFunctions)

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

# text = "

# m = new M
# m := M

# f = (a := A, c:=C) ->
# 	b := B
# 	b = new B
# 	0
# h = (a := A) ->
# 	f(a)
# g = (c := C) ->
# 	c
# j =  ->
# 	\'i\'

# p = (n := N) ->
# 	j()

# q = (n := N) ->
# 	g(n)

# s = ->
# 	q(1)

# k =  ->
# 	m
# "

text = "class A extends int
class B extends A
class M extends A
class C extends double
a = new A

f = (a :- A, b :- B) ->
	b = new B
	a
g = (a) ->
	c :- C
	c = new C
	x = j(a, c) 
	10
m = new M
m :- M

k =  ->
	m
	b :- B
j = (s, t) ->
	a
b = new B
a :- A
x = j(a,m)
y = g(a)
"

# text = "class A extends int
# class B extends A
# class C extends A

# a :- A

# A2B = (a) ->
# 	b = new B
# 	b = someBFunction(a)

# bee = (b_1, b_2) ->
# 	c = 1
# 	A2B(b_1 + b_2)

# AandC = (a,c) ->
# 	bb = A2B(c)
# 	d = new C
# 	d :- B
# 	d = A2B(bb)

# a = new A
# b1 :- B
# b1 = A2B(a)	
# b2 = A2B(a)
# b2 :- B
# bee(b1,b2)
# c1 = new C
# cc = AandC(b1,c1)"

# parse_function_infers(text)
# res2 = parse_locals_globals_infers(text)
# res_globs = res2[1]
# res_local = res2[0]
# res_globs.each do |varType|
# 	puts "Var #{varType.name} in scope #{varType.scope} is of type #{varType.inferred_type}"
# end
# res_local.each do |varType|
# 	puts "Var #{varType.name} in scope #{varType.scope} is of type #{varType.inferred_type}"
# end

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

# total_res = getProgramDeclarationsAndReferences(text)

# res_funcs = total_res[0]
# res_globs = total_res[1]
# res_vars  = total_res[2]
# res_references = total_res[3]

# puts "Functions:"
# res_funcs.each_pair do |key, value|
# 	puts "Function name: #{value.name}"
# 	puts "Function Scope: #{value.scope}"
# 	puts "Arg types: #{value.args}"
# 	if value.return_type != nil
# 		puts "Return Type: #{value.return_type}"
# 	else
# 		puts "Return Type: Could not be determined."
# 	end
# 	puts ""
# end

# puts "Globals:"
# res_globs.each_pair do |key, value|
# 	puts "Global name: #{value.name}"
# 	puts "Global Type: #{value.declared_type}"
# 	puts "Global line: #{value.lineno}"
# 	puts ""
# end

# puts "Local Variables:"
# res_vars.each_pair do |key, data|
# 	puts "Variables declared in #{key}:"
# 	data.each_pair do |k, value|
# 		puts "\tVar name: #{value.name}"
# 		puts "\tVar Scope: #{value.scope}"
# 		puts "\tVar Type: #{value.declared_type}"
# 		puts "\tVar line: #{value.lineno}"
# 		puts "\t----------"
# 	end
# 	puts "------------------"
# end

# puts ""

# puts "Variable References:"
# res_references.each do |data|
# 	puts "\tVariable #{data.name} used in line #{data.line_found}:"
# 	puts "\tVariable kind is #{data.kind}"
# 	if data.declared_type != nil
# 		puts "\tVariable declared as #{data.declared_type}"
# 	end
# 	puts "\tVariable declared in line #{data.line_declared}"
# 	puts "\t----------"
# end
