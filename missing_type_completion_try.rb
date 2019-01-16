def try_to_complete_missing_types(	inferredLocals, inferredGlobals, inferredFunctions,
									declaredLocals, declaredGlobals, declaredFunctions)
	puts "Local completion:"
	inferredLocals.each do |inferredVar|
		if not isArbitraryType(inferredVar.inferred_type)
			# puts "Type of #{inferredVar.name} is #{inferredVar.inferred_type}"
			next
		end
		
		match = find_inferred_var_in_declared(inferredVar, declaredLocals)
		if match != nil
			puts "#{inferredVar.name}: #{inferredVar.inferred_type} =:= #{match.declared_type}"
		else
			puts "Type of var #{inferredVar.name} was not declared."
		end
	end

	puts ""

	puts "Global completion:"
	inferredGlobals.each do |inferredVar|
		if not isArbitraryType(inferredVar.inferred_type)
			# puts "Type of #{inferredVar.name} is #{inferredVar.inferred_type}"
			next
		end
		
		match = find_inferred_var_in_globals(inferredVar, declaredGlobals)
		if match != nil
			puts "#{inferredVar.name}: #{inferredVar.inferred_type} =:= #{match.declared_type}"
		else
			puts "Type of var #{inferredVar.name} was not declared."
		end
	end

	puts ""

	puts "Functions completion:"
	inferredFunctions.each_pair do |funcName, inferredFunc|
		match = find_inferred_func_in_funcs(funcName, declaredFunctions)
		puts "In function #{inferredFunc.name}"
		if match != nil
			if isArbitraryType(inferredFunc.return_type)
				if match.return_type == nil
					puts "#{funcName}  [Return]: #{inferredFunc.return_type} =:= NIL"
				else
					puts "#{funcName}  [Return]: #{inferredFunc.return_type} =:= #{match.return_type}"
				end
			else
				puts "#{funcName}  [Return]: #{inferredFunc.return_type}"
			end
			inferredFunc.args.each_with_index do |val, index|
				if isArbitraryType(val)
					puts "Arg \##{index+1}: #{val} =:= #{match.args[index].type}"
				else
					puts "Arg \##{index+1}: #{val} =:= #{val}"
				end
			end
		end
		puts "-----------------------"
	end
end