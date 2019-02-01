def try_to_complete_missing_types(	inferredLocals, inferredGlobals, inferredFunctions,
									declaredLocals, declaredGlobals, declaredFunctions)
	puts "Local completion:"
	inferredLocals.each do |inferredVar|
		if not isArbitraryType(inferredVar.inferred_type)
			# puts "Type of #{inferredVar.name} is #{inferredVar.inferred_type}"
			next
		end
		
		match = find_inferred_var_in_declared(inferredVar, declaredLocals)
		if match == nil or match == ""
			puts "#{inferredVar.name}: #{inferredVar.inferred_type} =:= NIL"
		else
			puts "#{inferredVar.name}: #{inferredVar.inferred_type} =:= #{match.declared_type}"
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
		if match == nil or match == ""
			puts "#{inferredVar.name}: #{inferredVar.inferred_type} =:= NIL"
		else
			puts "#{inferredVar.name}: #{inferredVar.inferred_type} =:= #{match.declared_type}"
		end
	end

	puts ""

	puts "Functions completion:"
	inferredFunctions.each_pair do |funcName, inferredFunc|
		puts "Function #{funcName}"
		match = find_inferred_func_in_funcs(funcName, declaredFunctions)
		if match != nil
			if isArbitraryType(inferredFunc.return_type)
				if match.return_type == nil or match.return_type == ""
					puts "#{funcName}  [Return]: #{inferredFunc.return_type} =:= NIL"
				else
					puts "#{funcName}  [Return]: #{inferredFunc.return_type} =:= #{match.return_type}"
				end
			# else
			# 	puts "#{funcName}  [Return]: #{inferredFunc.return_type}"
			end
			inferredFunc.args.each_with_index do |val, index|
				if isArbitraryType(val)
					puts "Arg \##{index+1}: #{val} =:= #{match.args[index].type}"
				# else
				# 	# If inferred correctly, no need to give our declaration, especially if there wasn't one
				# 	puts "Arg \##{index+1}: #{val} =:= #{val}"
				end
			end
		end
		puts "-----------------------"
	end
end