# This will be the main "declarations" program, which will run
# the other functions and print (or convert to json later)

require("./program_declarations.rb")
require "pp"
require "json"
require "./ast.rb"
require "./remove_decls.rb"

ls_file = ARGV[0]
ast = `lsc --ast --json #{ls_file}`	
if ast == ""
	exit()
end

def get_function_type(funcData)
	str = ""
	funcData.args.each do |arg|
		str += "#{arg}->"
	end
	str += funcData.return_type
	return str
end

def getDeclared_function_type(funcData, retType)
	str = ""
	funcData.args.each do |arg|
		str += "#{arg.type}->"
	end
	str += retType
	return str
end

def fill_inferred_types_in_references(var_references, inferred_locals, inferred_globs, inferred_funcs, funcs_dict)
	
	# Will map the arbitrary T' types to their correct inferred type
	fix_hash = Hash.new

	var_references.each do |ref|
		puts "#{ref.name}, #{ref.line_found}, #{ref.kind}"
		scopeno = ref.scope
		if ref.kind == "func"
			inferred_funcs.each_pair do |funcName, func|
				if ref.name == funcName
					check_func = funcs_dict[funcName]
						if check_func != nil
							check_func.args.each_with_index do |argData, ind|
								if isArbitraryType(argData.type)
									fix_hash[argData.type] = func.args[ind]
								end
							end
						end
					ref.inferred_type = get_function_type(func)
					break
				end
			end
		elsif ref.kind == "global"
			inferred_globs.each do |global_var|
				if ref.name == global_var.name
					if isArbitraryType(ref.declared_type)
						fix_hash[ref.declared_type] = global_var.inferred_type
					end
					ref.inferred_type = global_var.inferred_type
					break
				end
			end
		else # regular local variable, might be reference to global or func though.
			found = false
			inferred_locals.each do |local_var|
				puts "local #{local_var.name}, #{local_var.scope}"
				if ref.name == local_var.name and ref.scope == local_var.scope
					if isArbitraryType(ref.declared_type)
						fix_hash[ref.declared_type] = local_var.inferred_type
					end
					ref.inferred_type = local_var.inferred_type
					found = true
					break
				end
			end
			if not found
				inferred_globs.each do |global_var|
					puts "global #{global_var.name}"
					if ref.name == global_var.name and ref.kind == "global"
						if isArbitraryType(ref.declared_type)
							fix_hash[ref.declared_type] = global_var.inferred_type
						end
						ref.inferred_type = global_var.inferred_type
						ref.kind = "global"
						found = true
						break
					end
				end
			elsif not found
				inferred_funcs.each_pair do |funcName, func|
					if ref.name == funcName
						ref.inferred_type = get_function_type(func)
						check_func = funcs_dict[funcName]
						if check_func != nil
							check_func.args.each_with_index do |argData, ind|
								if isArbitraryType(argData.type)
									fix_hash[argData.type] = func.args[ind]
								end
							end
						end
						ref.kind = "func"
						found = true
						break
					end
				end
			end
		end
	end

	funcs_dict.each_pair do |name1, funcData|
		inferred_funcs.each_pair do |name2, func|
			if name1 == name2
				# puts "match #{name1}"
				check_func = funcData
				check_func.args.each_with_index do |argData, ind|
					# puts "type is #{argData.type}"
					if isArbitraryType(argData.type)
						# puts "arbitrary #{argData.type}"
						fix_hash[argData.type] = func.args[ind]
					end
				end
				if isArbitraryType(check_func.return_type)
					fix_hash[check_func.return_type] = func.return_type
					funcData.return_type = func.return_type
				end
			end
		end
	end
end

def fill_types_from_references(local_vars, global_vars, var_references)
	var_references.each do |varRef|
		if local_vars[varRef.func_name] != nil
			local_vars[varRef.func_name].each_pair do |name, data|
				if varRef.name == name and isArbitraryType(data.declared_type)
					local_vars[varRef.func_name][name].declared_type = varRef.declared_type
					break
				end
			end
		end
		global_vars.each_pair do |name, data|
			if varRef.name == name and isArbitraryType(data.declared_type)
				global_vars[name].declared_type = varRef.declared_type
				break
			end
		end
	end
end

# puts "Inferred Variables:"
# inferred_locals.each do |var|
# 	declared_funcs.each_pair do |name, funcData|
# 		if var.scope == funcData.scope
# 			puts "\tinferred #{var.name} [in function #{funcData.name}] as type #{var.inferred_type}"
# 		end
# 	end
# end
# inferred_globs.each do |var|
# 	puts "\tinferred #{var.name} [global] as type #{var.inferred_type}"
# end
# inferred_funcs.each_pair do |name, func|
# 	puts "\tinferred #{func.name} [function] as type #{get_function_type(func)}"
# end

# puts ""

# puts "Functions:"
# declared_funcs.each_pair do |key, value|
# 	funcType = declared_funcs[value.name].return_type
# 	funcType = getDeclared_function_type(value, funcType)
# 	puts "\tline #{value.lineno+1}: \"#{value.name}\", function, #{funcType}"
# 	# puts "Function name: #{value.name}"
# 	# puts "Function Scope: #{value.scope}"
# 	# puts "Arg types: #{value.args.map {|arg| arg.type}}"
# 	# if value.return_type != nil
# 	# 	puts "Return Type: #{value.return_type}"
# 	# else
# 	# 	puts "Return Type: Could not be determined."
# 	# end
# 	# puts ""
# end

# # puts "Globals:"
# # declared_globs.each_pair do |key, value|
# # 	puts "Global name: #{value.name}"
# # 	puts "Global Type: #{value.declared_type}"
# # 	puts "Global line: #{value.lineno+1}"
# # 	puts ""
# # end

# # puts "Local Variables:"
# # declared_locals.each_pair do |key, data|
# # 	puts "Local variables in #{key}:"
# # 	data.each_pair do |k, value|
# # 		puts "\tVar name: #{value.name}"
# # 		puts "\tVar Scope: #{value.scope}"
# # 		puts "\tVar Type: #{value.declared_type}"
# # 		puts "\tVar line: #{value.lineno+1}"
# # 		puts "\t----------"
# # 	end
# # 	puts "------------------"
# # end

# # puts ""

if ARGV.size == 0
	puts("File name missing")
	exit()
end

ls_file = ARGV[0]
if ARGV[0].split('.')[-1] != 'ls'
	puts("Must be a livescript file")
	exit()
end

ls_file = ARGV[0]

f_ls_program = File.open(ls_file, "r")
ls_program = f_ls_program.read
f_ls_program.close()

ls_decl_free = remove_decls(ls_program)

f_decl_free = File.open("decls_free.ls", "w")
f_decl_free.write(ls_decl_free)
f_decl_free.close()

ast = `lsc --ast --json decls_free.ls`	
if ast == ""
	exit()
end

res_declared = getProgramDeclarationsAndReferences(ls_program)
declared_funcs  = res_declared[0]
declared_globs  = res_declared[1]
declared_locals = res_declared[2]
res_references = res_declared[3]

res_var_infers = parse_locals_globals_infers(ls_program)
inferred_locals = res_var_infers[0]
inferred_globs  = res_var_infers[1]
inferred_funcs  = parse_function_infers(ls_program)

fill_inferred_types_in_references(res_references, inferred_locals, inferred_globs, inferred_funcs, declared_funcs)

fill_types_from_references(declared_locals, declared_globs, res_references)

completionHash = try_to_complete_missing_types(inferred_locals, inferred_globs, inferred_funcs, declared_locals, declared_globs, declared_funcs, res_references)

fill_inferred_types_in_references(res_references, inferred_locals, inferred_globs, inferred_funcs, declared_funcs)

# puts ast

ast_j = JSON.parse(ast)


def isLineArrayIndexGetter(line)
	line['type'] == "Assign" && line['right']['type'] == "Chain" && line['right']['tails'][0]['type'] == "Index"
end

def changeIndexGetToMethodGet(line)
	array = line['right']['head'].clone
	index = line['right']['tails'][0]['key']['it'].clone

	line['right']['head']['value'] = "get"
	line['right']['tails'][0]['type'] = "Call"
	line['right']['tails'][0]['args'] = [array, index]
end

def changeIndexSetToMethodSet(line)
	line['type'] = "Chain"
	headOfChainBefore = line['left']['head'].clone
	array = line['left']['head'].clone
	index = line['left']['tails'][0]['key']['it'].clone
	valueToAssign = line['right'].clone
	line['head'] = {'type' => "Var", 'value' => "set", 'first_line' => headOfChainBefore['first_line'],
									'first_column' => headOfChainBefore['first_column'], 'last_line' => headOfChainBefore['last_line'],
									'last_column' => headOfChainBefore['last_column'], 'line' => headOfChainBefore['line'], 'column' => headOfChainBefore['column']}
	line['tails'] = [{'type' => "Call", 'args' => [array, index, valueToAssign]}]
end

def isLineArrayIndexSetter(line)
	line['type'] == "Assign" && line['left']['type'] == "Chain" && line['left']['tails'][0]['type'] == "Index"
end

ast_j['lines'].each {|line|
	if isLineArrayIndexSetter(line)
		changeIndexSetToMethodSet(line)
	end
	if isLineArrayIndexGetter(line)
		changeIndexGetToMethodGet(line)
	end
}
# pp ast_j
ast = Ast.new ast_j

# puts "Completion Results:"
# completionHash.each_pair do |arb, comp|
# 	puts "#{arb} =:= #{comp}"
# end

# ast.add_completion_subtype_equations(completionHash)

ast.get_vars
puts "--------------------------------------------------------------------------------------------------------------"
# pp ast
puts "--------------------------------------------------------------------------------------------------------------"

puts "Variable References:"
res_references.each do |data|
	if data.declared_type == nil
		data.declared_type = "func"
	end
	if isArbitraryType(data.declared_type)
		data.declared_type = "NIL"
	end
	if data.inferred_type == ""
		data.inferred_type = "?"
	end
	puts "\tline #{data.line_found+1}: \"#{data.name}\", #{data.kind} [declared: line #{data.line_declared+1}, as #{data.declared_type}], type #{data.inferred_type} (#{data.scope})"
end

File.delete("decls_free.ls")
