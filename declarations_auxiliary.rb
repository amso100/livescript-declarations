# Gets a program, and does a single pass over it to find declarations.
# Returns:
#
#	functions_dict: Hash
#		Key: function name
#		Value: FunctionDeclaration object (name, scope, line, FunctionParameter[])
#
#	global_vars: Hash
#		Key: var name
#		Value: TypeDeclaredVar object (name, scope, "", line declared, type)
#
#	local_vars: Hash
#		Key: function name
#		Value: Hash (of local variable declarations)
#			Key: var name
#			Value: TypeDeclaredVar
#
#	var_references: List of type VariableReference
#
# 	badAssignments: Hash
#		Key: line number
#		Value: bad assignment data
#
#	changed: Have any of the structures changed during the pass, to determine if done or not.
def get_program_declarations_aux(text, functions_dict, global_vars, local_vars, var_references, globals_exist)
	changed = false

	text.gsub!(/\r\n?/, "\n")
	aribtrary_count = 0
	in_function = false
	prev_line = nil
	last_real_line = nil
	scopeno = -1
	max_scope = -1
	first_function = true
	func_name = ""
	allVariableTypes = Array.new
	badAssignments = Hash.new

	setup_variable_types(allVariableTypes, local_vars, global_vars)
	allVariableTypes = allVariableTypes + get_all_class_names(text)
	
	if globals_exist
		scopeno = 1
	else
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
				ret_type = parse_for_type(last_real_line, local_vars, global_vars, func_name, functions_dict, var_references)
				if ret_type != nil
					functions_dict[func_name].return_type = ret_type
				end
			end

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
				line[func_name.length...-1].scan(/([A-Za-z]{1}[A-Za-z0-9_]* *:- *[A-Za-z]{1}[A-Za-z0-9_]*,? *|[A-Za-z]{1}[A-Za-z0-9_]*,? *)/) do |m|
					a = m[0].scan(/([A-Za-z]{1}[A-Za-z0-9_]*)/)
					
					if a.length > 1
						local_vars[func_name][a[0][0]] = TypeDeclaredVar.new(a[0][0], a[1][0], func_name, ind, scopeno)
						functions_dict[func_name].args << FunctionParameter.new(a[0][0], a[1][0])
					else
						local_vars[func_name][a[0][0]] = TypeDeclaredVar.new(a[0][0], "T'-#{aribtrary_count}", func_name, ind, scopeno)
						functions_dict[func_name].args << FunctionParameter.new(a[0][0], "T'-#{aribtrary_count}")
						aribtrary_count += 1
					end
				end
				functions_dict[func_name].initialized = true
			end

		# Test for functions without any arguments
		elsif lineIsNoParamsFunctionStart(line)
			if in_function == true
				ret_type = parse_for_type(last_real_line, local_vars, global_vars, func_name, functions_dict, var_references)
				if ret_type != nil
					functions_dict[func_name].return_type = ret_type
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
					functions_dict[func_name].args << FunctionParameter.new("", "unit")
				end
			end

		# If exited scope and previous line is not null, parse
		elsif prev_line != nil and count_tabs_at_start(line) == 0 and count_tabs_at_start(prev_line) > 0
			# puts line
			ret_type = parse_for_type(last_real_line, local_vars, global_vars, func_name, functions_dict, var_references)
			if ret_type != nil
				functions_dict[func_name].return_type = ret_type
			end
			in_function = false
			scopeno = 0

			declarations = get_line_declarations(line, allVariableTypes)
			declarations.each_pair do |name, type|
				if not global_vars.keys.include?(name) and not allVariableTypes.include?(name)
					global_vars[name] = TypeDeclaredVar.new(name, type, "", ind, 0)
					fix_references_types(var_references, name, 0, type, local_vars, global_vars, functions_dict)
					changed = true
				end
				update_relevant_global_references(var_references, name, ind, type)
			end

			if declarations.size == 0 # If no declarations found, search for used variables.
				# Check if this is a '=' line and forward declarations if found.
				check_equals_statement = global_parse_for_type(line, global_vars, var_references, functions_dict)
				if check_equals_statement != nil
					assigned_name = check_equals_statement[0]
					found_type = check_equals_statement[1]
					assigned_to = check_equals_statement[2]
					if global_vars[assigned_name] != nil and global_vars[assigned_to] != nil
						t1 = global_vars[assigned_name].declared_type
						t2 = global_vars[assigned_to].declared_type
						if not isArbitraryType(t1) and not isArbitraryType(t2) and t1 != t2
							badAssignments[ind] = BadAssignment.new(ind, line, assigned_to, t1, assigned_name, t2)
						end
					end
					var_references.each do |ref|
						if ref.kind == "global" and ref.name == assigned_name and (ref.declared_type == nil or isArbitraryType(ref.declared_type))
							ref.declared_type = found_type
							if found_type != nil and not isArbitraryType(found_type)
								changed = true
							end
						end
					end
				end

				vars = get_line_variables(line, allVariableTypes)
				vars.each do |var|
					places = get_variable_columns(line, var)
					places.each do |pl|
						ref = nil
						if global_vars.keys.include?(var)
							ref = VariableReference.new(var, global_vars[var].lineno, ind, global_vars[var].declared_type, "global", 0, "", pl)
						elsif functions_dict.keys.include?(var)
							ref = VariableReference.new(var, functions_dict[var].lineno, ind, nil, "func", 0, "", pl)
						else
							possible_type = find_type_in_references(var_references, var, 0)
							if check_equals_statement != nil and found_type != nil and assigned_name == var
								ref = VariableReference.new(var, -2, ind, found_type, "global", 0, "", pl)
							elsif possible_type != nil
								ref = VariableReference.new(var, -2, ind, possible_type, "global", 0, "", pl)
							else
								ref = VariableReference.new(var, -2, ind, "T'-#{aribtrary_count}", "global", 0, "", pl)
								aribtrary_count += 1
							end
						end
						if add_variable_reference(var_references, ref)
							changed = true
						end
					end
				end
			end

		# Otherwise, we're in a regular function line (or global line) 
		# and want to search for declarations
		else
			if in_function == true
				declarations = get_line_declarations(line, allVariableTypes)
				declarations.each_pair do |name, type|
					if local_vars[func_name][name] == nil or isArbitraryType(local_vars[func_name][name].declared_type)
						changed = true
					end
					local_vars[func_name][name] = TypeDeclaredVar.new(name, type, func_name, ind, scopeno)
					var_references.each do |varRef|
						if varRef.scope == scopeno and varRef.name == name and isArbitraryType(varRef.declared_type)
							varRef.declared_type = type
							varRef.line_declared = ind
						end
					end
				end

				# Check if one of the declared vars is also a parameter, and if so, update the function.
				declarations.each_pair do |name, type|
					functions_dict[func_name].args.each do |arg|
						if arg.name == name and isArbitraryType(arg.type)
							arg.type = type
						end
					end
				end

				if declarations.size == 0
					# Check if line has '=' statement
					check_equals_statement = local_parse_for_type(line, local_vars, func_name, var_references, scopeno, functions_dict, ind)
					if check_equals_statement != nil
						assigned_name = check_equals_statement[0]
						found_type = check_equals_statement[1]
						assigned_to = check_equals_statement[2]
						if local_vars[func_name][assigned_name] != nil and local_vars[func_name][assigned_to] != nil
							t1 = local_vars[func_name][assigned_name].declared_type
							t2 = local_vars[func_name][assigned_to].declared_type
							if not isArbitraryType(t1) and not isArbitraryType(t2) and t1 != t2
								badAssignments[ind] = BadAssignment.new(ind, line, assigned_to, t1, assigned_name, t2)
							end
						end
						var_references.each do |ref|
							if ref.kind == "local" and ref.name == assigned_name and ref.scope == scopeno and  isArbitraryType(ref.declared_type)
								ref.declared_type = found_type
								current_function_args = functions_dict[func_name].args
								current_function_args.each do |arg|
									if arg.name == assigned_name and isArbitraryType(arg.type)
										arg.type = found_type
									end
								end
								if found_type != nil and not isArbitraryType(found_type)
									changed = true
								end
							end

						end
					end

					# Identify all vars in line, and if found in dictionary, print a "reference".
					current_scope = local_vars[func_name]
					vars = get_line_variables(line, allVariableTypes)
					vars.each do |var|
						places = get_variable_columns(line, var)
						places.each do |pl|
							if current_scope.keys.include?(var)
								if current_scope[var].declared_type != ""
									ref = VariableReference.new(var, current_scope[var].lineno, ind, current_scope[var].declared_type, "local", scopeno, func_name, pl)
									if add_variable_reference(var_references, ref)
										changed = true
									end
								end
							elsif global_vars.keys.include?(var)
								if global_vars[var].declared_type != ""
									ref = VariableReference.new(var, global_vars[var].lineno, ind, global_vars[var].declared_type, "global", 0, "", pl)
									if add_variable_reference(var_references, ref)
										changed = true
									end
								end
							elsif functions_dict.keys.include?(var)
								ref = VariableReference.new(var, functions_dict[var].lineno, ind, nil, "func", 0, "", pl)
								if add_variable_reference(var_references, ref)
									changed = true
								end
							else
								need = true
								var_references.each do |ref|
									if ref.name == var and ref.kind == "global"
										need = false
									end
								end
								if need
									current_scope[var] = TypeDeclaredVar.new(var, "T'-#{aribtrary_count}", func_name, -2, scopeno)
									aribtrary_count += 1
								end
							end
						end
					end
				end
			else
				declarations = get_line_declarations(line, allVariableTypes)
				declarations.each_pair do |name, type|
					if not global_vars.include?(name) and not allVariableTypes.include?(name)
						global_vars[name] = TypeDeclaredVar.new(name, type, "", ind, scopeno)
						fix_references_types(var_references, name, 0, type, local_vars, global_vars, functions_dict)
						changed = true
					end
					update_relevant_global_references(var_references, name, ind, type)
				end

				if declarations.size == 0 # If no declarations found, search for used variables.
					# Check if this is a '=' line and forward declarations if found.
					found_type = nil
					assigned_name = nil
					check_equals_statement = nil
					check_equals_statement = global_parse_for_type(line, global_vars, var_references, functions_dict)
					if check_equals_statement != nil
						assigned_name = check_equals_statement[0]
						found_type = check_equals_statement[1]
						assigned_to = check_equals_statement[2]
						if global_vars[assigned_name] != nil and global_vars[assigned_to] != nil
							t1 = global_vars[assigned_name].declared_type
							t2 = global_vars[assigned_to].declared_type
							if not isArbitraryType(t1) and not isArbitraryType(t2) and t1 != t2
								badAssignments[ind] = BadAssignment.new(ind, line, assigned_to, t1, assigned_name, t2)
							end
						end
						var_references.each do |ref|
							if ref.kind == "global" and ref.name == assigned_name and (ref.declared_type == nil or isArbitraryType(ref.declared_type))
								ref.declared_type = found_type
								if found_type != nil and not isArbitraryType(found_type)
									changed = true
								end
							end
						end
					end

					vars = get_line_variables(line, allVariableTypes)
					vars.each do |var|
						places = get_variable_columns(line, var)
						places.each do |pl|
							ref = nil
							if global_vars.keys.include?(var)
								ref = VariableReference.new(var, global_vars[var].lineno, ind, global_vars[var].declared_type, "global", 0, "", pl)
							elsif functions_dict.keys.include?(var)
								ref = VariableReference.new(var, functions_dict[var].lineno, ind, nil, "func", 0, "", pl)
							else
								if line.include? "class "
									cls_name = line[5..-1][/[A-Z]+[A-Za-z]/]
									allVariableTypes << cls_name
								else
									possible_type = find_type_in_references(var_references, var, 0)
									if check_equals_statement != nil and found_type != nil and assigned_name == var
										# puts "111 #{var} :- #{found_type}"
										ref = VariableReference.new(var, -2, ind, found_type, "global", 0, "", pl)
									elsif possible_type != nil
										ref = VariableReference.new(var, -2, ind, possible_type, "global", 0, "", pl)
									else
										ref = VariableReference.new(var, -2, ind, "T'-#{aribtrary_count}", "global", 0, "", pl)
										aribtrary_count += 1
									end
								end
							end
							if add_variable_reference(var_references, ref)
								changed = true
							end
						end
					end
				end

			end
		end
		# puts "#{scopeno} : #{line}"
		if scopeno >= max_scope
			max_scope = scopeno
		end
		prev_line = line
		if not line.include? ":-"
			last_real_line = line
		end
		# puts "Variable References:"
		# var_references.each do |data|
		# 	if data.declared_type == nil
		# 		data.declared_type = "func"
		# 	end
		# 	if data.inferred_type == ""
		# 		data.inferred_type = "?"
		# 	end
		# 	puts "\tline #{data.line_found+1} column #{data.column_found}: \"#{data.name}\", #{data.kind} [declared: line #{data.line_declared+1}, as #{data.declared_type}], type #{data.inferred_type}, scope #{data.scope}"
		# end
	end

	# If exited program with a "leftover" line remaining, test it.
	if prev_line != nil and count_tabs_at_start(prev_line) > 0
		ret_type = parse_for_type(last_real_line, local_vars, global_vars, func_name, functions_dict, var_references)
		functions_dict[func_name].return_type = ret_type
	end

	# Remove any types that were accidentally added to local_vars:
	local_vars.each_pair do |funcName, funcVars|
		funcVars.each_pair do |varName, varData|
			if allVariableTypes.include? varName
				local_vars[funcName].delete(varName)
			end
		end
	end

	global_vars.each do |name, var|
		if allVariableTypes.include? name
			global_vars.delete(name)
		end
	end 

	var_references.reject! { |ref| allVariableTypes.include? ref.name }

	# var_references.each do |data|
	# 	if data.declared_type == nil
	# 		data.declared_type = "func"
	# 	end
	# 	puts "\tline #{data.line_found+1}: \"#{data.name}\", #{data.kind} [declared: line #{data.line_declared+1}, as #{data.declared_type}]"
	# end
	# puts "-----------------------------"
	return [functions_dict, global_vars, local_vars, var_references, changed, badAssignments]
end
