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
#	changed: Have any of the structures changed during the pass, to determine if done or not.
def get_program_declarations_aux(text, functions_dict, global_vars, local_vars, var_references)
	changed = false

	text.gsub!(/\r\n?/, "\n")
	aribtrary_count = 0
	in_function = false
	prev_line = nil
	scopeno = -1
	max_scope = -1
	first_function = true
	func_name = ""
	allVariableTypes = Array.new

	setup_variable_types(allVariableTypes, local_vars, global_vars)
	# puts "Types: #{allVariableTypes}"

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
				ret_type = parse_for_type(prev_line, local_vars, global_vars, func_name, functions_dict, var_references)
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
				line[func_name.length...-1].scan(/([A-Za-z]{1}[A-Za-z0-9_]* *:- *[A-Za-z]{1}[A-Za-z0-9_]*,? *|[A-Za-z]{1}[A-Za-z0-9_]*,? *)/) do |m|
					a = m[0].scan(/([A-Za-z]{1}[A-Za-z0-9_]*)/)
					
					if a.length > 1
						# puts "var is #{a[0][0]}, Type is #{a[1][0]}"
						local_vars[func_name][a[0][0]] = TypeDeclaredVar.new(a[0][0], a[1][0], func_name, ind, scopeno)
						functions_dict[func_name].args << FunctionParameter.new(a[0][0], a[1][0])
					else
						# puts "var is #{a[0][0]}"
						local_vars[func_name][a[0][0]] = TypeDeclaredVar.new(a[0][0], "T'-#{aribtrary_count}", func_name, ind, scopeno)
						functions_dict[func_name].args << FunctionParameter.new(a[0][0], "T'-#{aribtrary_count}")
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
				ret_type = parse_for_type(prev_line, local_vars, global_vars, func_name, functions_dict, var_references)
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
					functions_dict[func_name].args << FunctionParameter.new("", "unit")
				end
			end
			# puts line
			# puts "scope = #{scopeno}"

		# If exited scope and previous line is not null, parse
		elsif prev_line != nil and count_tabs_at_start(line) == 0 and count_tabs_at_start(prev_line) > 0
			ret_type = parse_for_type(prev_line, local_vars, global_vars, func_name, functions_dict, var_references)
			if ret_type != nil
				functions_dict[func_name].return_type = ret_type
			else
				#puts "Return type of function #{func_name} could not be determined."
			end
			in_function = false
			scopeno = 0
			# puts line
			# puts "scope = #{scopeno}"

			declarations = get_line_declarations(line, allVariableTypes)
			declarations.each_pair do |name, type|
				if not global_vars.keys.include?(name) and not allVariableTypes.include?(name)
					global_vars[name] = TypeDeclaredVar.new(name, type, "", ind, scopeno)
					changed = true
				end
				update_relevant_global_references(var_references, name, ind)
			end

			if declarations.size == 0 # If no declarations found, search for used variables.
				vars = get_line_variables(line, allVariableTypes)
				vars.each do |var|
					if global_vars.keys.include?(var)
						ref = VariableReference.new(var, global_vars[var].lineno, ind, global_vars[var].declared_type, "global", 0)
						# puts "ref to #{var} at line #{ind}"
						if add_variable_reference(var_references, ref)
							changed = true
						end
						# puts "Line #{ind}: Var #{var} is global declared at #{global_vars[var].lineno}"
					elsif functions_dict.keys.include?(var)
						ref = VariableReference.new(var, functions_dict[var].lineno, ind, nil, "func", 0)
						if add_variable_reference(var_references, ref)
							changed = true
						end
						# puts "Line #{ind}: Var #{var} is function defined at line #{functions_dict[var].lineno}"
					else
						ref = VariableReference.new(var, -2, ind, "T'-#{aribtrary_count}", "global", 0)
						aribtrary_count += 1
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
				# puts line
				# puts "scope = #{scopeno}"
				# puts line
				# puts "Regular function line"
				declarations = get_line_declarations(line, allVariableTypes)
				declarations.each_pair do |name, type|
					local_vars[func_name][name] = TypeDeclaredVar.new(name, type, func_name, ind, scopeno)
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
					# Identify all vars in line, and if found in dictionary, print a "reference".
					current_scope = local_vars[func_name]
					vars = get_line_variables(line, allVariableTypes)
					# puts "#{line} : vars = #{vars}"
					vars.each do |var|
						# if current_scope.keys.include?(var) and global_vars.keys.include?(var)
						# 	current_scope.delete(var)
						# end

						if current_scope.keys.include?(var)
							# if global_vars[var] != nil and current_scope[var] != nil
							# 	current_scope[var].declared_type = global_vars[var].declared_type
							# end
							if current_scope[var].declared_type != ""
								ref = VariableReference.new(var, current_scope[var].lineno, ind, current_scope[var].declared_type, "local", scopeno)
								if add_variable_reference(var_references, ref)
									changed = true
								end
							end
							# puts "Line #{ind}: Var #{var} is local  declared at line #{current_scope[var].lineno}"
						elsif global_vars.keys.include?(var)
							if global_vars[var].declared_type != ""
								ref = VariableReference.new(var, global_vars[var].lineno, ind, global_vars[var].declared_type, "global", 0)
								if add_variable_reference(var_references, ref)
									changed = true
								end
							end
							# if global_vars[var] != nil and current_scope[var] != nil
							# 	current_scope[var].declared_type = global_vars[var].declared_type
							# end
							# puts "Line #{ind}: Var #{var} is global declared at line #{global_vars[var].lineno}"
						elsif functions_dict.keys.include?(var)
							ref = VariableReference.new(var, functions_dict[var].lineno, ind, nil, "func", 0)
							if add_variable_reference(var_references, ref)
								changed = true
							end
							# puts "Line #{ind}: Var #{var} is function defined at line #{functions_dict[var].lineno}"
						else
							need = true
							var_references.each do |ref|
								# puts "#{ref.name} =?= #{var} ; #{ref.kind} ; #{ref.line_found}"
								if ref.name == var and ref.kind == "global"
									need = false
								end
							end
							if need
								current_scope[var] = TypeDeclaredVar.new(var, "T'-#{aribtrary_count}", func_name, ind, scopeno)
								aribtrary_count += 1
							end
						end
					end
				end
			else
				declarations = get_line_declarations(line, allVariableTypes)
				declarations.each_pair do |name, type|
					if not global_vars.include?(name) and not allVariableTypes.include?(name)
						global_vars[name] = TypeDeclaredVar.new(name, type, "", ind, scopeno)
						changed = true
					end
					update_relevant_global_references(var_references, name, ind)
				end

				if declarations.size == 0 # If no declarations found, search for used variables.
					vars = get_line_variables(line, allVariableTypes)
					vars.each do |var|
						if global_vars.keys.include?(var)
							ref = VariableReference.new(var, global_vars[var].lineno, ind, global_vars[var].declared_type, "global", 0)
							# puts "ref to #{var} at line #{ind}"
							if add_variable_reference(var_references, ref)
								changed = true
							end
							# puts "Line #{ind}: Var #{var} is global declared at #{global_vars[var].lineno}"
						elsif functions_dict.keys.include?(var)
							ref = VariableReference.new(var, functions_dict[var].lineno, ind, nil, "func", 0)
							if add_variable_reference(var_references, ref)
								changed = true
							end
							# puts "Line #{ind}: Var #{var} is function defined at line #{functions_dict[var].lineno}"
						else
							ref = VariableReference.new(var, -1, ind, "T'-#{aribtrary_count}", "global", 0)
							aribtrary_count += 1
							if add_variable_reference(var_references, ref)
								changed = true
							end
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
		ret_type = parse_for_type(prev_line, local_vars, global_vars, func_name, functions_dict, var_references)
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

	return [functions_dict, global_vars, local_vars, var_references, changed]
end
