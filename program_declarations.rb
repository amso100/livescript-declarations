# Here we will create a hash where for each function, the argument types will be listed.
# Undeclared arguments will be given as T'-1, T'-2, ...
# Entry example:
# 	"f" -> ["A", "B", "T'-1", "A"]

require("./remove_decls.rb")
require("./util_line_funcs.rb")
require("./return_type_parsing.rb")
require("./parse_inferences.rb")
require("./general_declaration_utils.rb")
require("./declaration_structures.rb")
require("./declarations_auxiliary.rb")
require("./missing_type_completion_try.rb")

# def get_program_declarations_aux(text, functions_dict, global_vars, local_vars, var_references)

# The goal of this function is to use the above aux function until no further
# changes have been made, and the result is returned.
# The return value is the same, apart from the value of "changed", which is not
# returned, as it has no meaning to an outsider.
def getProgramDeclarationsAndReferences(program_text)
	res_funcs = Hash.new
	res_globs = Hash.new
	res_vars  = Hash.new
	res_references = Array.new

	res = get_program_declarations_aux(program_text, res_funcs, res_globs, res_vars, res_references)

	changed = true

	while changed do
		res_funcs = res[0]
		res_globs = res[1]
		res_vars  = res[2]
		res_references = res[3]
		changed   = res[4]
		#clean_accidental_locals(res_references, res_vars)
		res = get_program_declarations_aux(program_text, res_funcs, res_globs, res_vars, res_references)
	end
	res_funcs = res[0]
	res_globs = res[1]
	res_vars  = res[2]
	res_references = res[3]
	#clean_accidental_locals(res_references, res_vars)

	return [res_funcs, res_globs, res_vars, res_references]
end

# text = "class A extends int
# class B extends A
# class M extends A
# class C extends double
# a = new A

# f = (a1 :- A, b :- B) ->
# 	b = new B
# 	a1
# g = (a1) ->
# 	c :- C
# 	c = new C
# 	x = j(a, c) 
# 	10
# m = new M
# m :- M

# k =  ->
# 	m
# 	b :- B

# j = (s :- S, t :- T) ->
# 	a
# b = new B
# a :- A
# x = j(a,m)
# y = g(a)

# noTypes = (b1 :- B, l :- L) ->
# 	b1

# "

# res_declared = getProgramDeclarationsAndReferences(text)
# declared_funcs  = res_declared[0]
# declared_globs  = res_declared[1]
# declared_locals = res_declared[2]

# res_var_infers = parse_locals_globals_infers(text)
# inferred_locals = res_var_infers[0]
# inferred_globs  = res_var_infers[1]
# inferred_funcs  = parse_function_infers(text)

# puts remove_decls(text)

# try_to_complete_missing_types(inferred_locals, inferred_globs, inferred_funcs, declared_locals, declared_globs, declared_funcs)

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

# total_res = res_declared

# res_funcs = total_res[0]
# res_globs = total_res[1]
# res_vars  = total_res[2]
# res_references = total_res[3]

# puts "Functions:"
# res_funcs.each_pair do |key, value|
# 	puts "Function name: #{value.name}"
# 	puts "Function Scope: #{value.scope}"
# 	puts "Arg types: #{value.args.map {|arg| arg.type}}"
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
# 	puts "Local variables in #{key}:"
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
