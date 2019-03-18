# Functions for completion of missing types that the Type Inference part did not manage to complete.
require "./general_declaration_utils.rb"

def try_to_complete_missing_types(	inferredLocals, inferredGlobals, inferredFunctions,
									declaredLocals, declaredGlobals, declaredFunctions,
									var_references)
	completionHash = Hash.new

	# puts "Local completion:"
	inferredLocals.each do |inferredVar|
		if not isArbitraryType(inferredVar.inferred_type)
			# puts "Type of #{inferredVar.name} is #{inferredVar.inferred_type}"
			next
		end
		
		match = find_inferred_var_in_declared(inferredVar, declaredLocals)
		if match == nil or match == ""
			# puts "#{inferredVar.name}: #{inferredVar.inferred_type} =:= NIL"
		else
			# puts "#{inferredVar.name}: #{inferredVar.inferred_type} =:= #{match.declared_type}"
			check = try_to_simplify(inferredVar.inferred_type, match.declared_type)
			if check != nil
				a_new = check[0]
				b_new = check[1]
				add_declared_type_to_hash(completionHash, a_new, b_new)
			end
		end
	end

	# puts ""

	# puts "Global completion:"
	inferredGlobals.each do |inferredVar|
		# puts "#{inferredVar.name}, #{inferredVar.inferred_type}"
		if not isArbitraryType(inferredVar.inferred_type)
			# puts "Type of #{inferredVar.name} is #{inferredVar.inferred_type}"
			next
		end
		
		match = find_inferred_var_in_globals(inferredVar, declaredGlobals)
		if match == nil or match == ""
			# puts "#{inferredVar.name}: #{inferredVar.inferred_type} =:= NIL"
		else
			# puts "#{inferredVar.name}: #{inferredVar.inferred_type} =:= #{match.declared_type}"
			check = try_to_simplify(inferredVar.inferred_type, match.declared_type)
			if check != nil
				a_new = check[0]
				b_new = check[1]
				add_declared_type_to_hash(completionHash, a_new, b_new)
			end
		end
	end

	# puts ""

	# puts "Functions completion:"
	inferredFunctions.each_pair do |funcName, inferredFunc|
		# puts "Function #{funcName}"
		match = find_inferred_func_in_funcs(funcName, declaredFunctions)
		if match != nil
			if isArbitraryType(inferredFunc.return_type)
				if match.return_type == nil or match.return_type == ""
					# puts "#{funcName}  [Return]: #{inferredFunc.return_type} =:= NIL"
				else
					# puts "#{funcName}  [Return]: #{inferredFunc.return_type} =:= #{match.return_type}"
					check = try_to_simplify(inferredFunc.return_type, match.return_type)
					if check != nil
						a_new = check[0]
						b_new = check[1]
						add_declared_type_to_hash(completionHash, a_new, b_new)
					end
				end
			end
			inferredFunc.args.each_with_index do |val, index|
				if isArbitraryType(val)
					# puts "Arg \##{index+1}: #{val} =:= #{match.args[index].type}"
					check = try_to_simplify(val, match.args[index].type)
					if check != nil
						a_new = check[0]
						b_new = check[1]
						add_declared_type_to_hash(completionHash, a_new, b_new)
					end
				end
			end
		end
		# puts "-----------------------"
	end

	var_references.each do |ref|
		if ref.inferred_type.include? "->"
			next
		end
		if isArbitraryType(ref.inferred_type) and not isArbitraryType(ref.declared_type)
			add_declared_type_to_hash(completionHash, ref.inferred_type, ref.declared_type)
		end
	end

	# # puts "Result Hash:"
	# completionHash.each_pair do |key, val|
	# 	# puts "#{key} =:= #{val}"
	# end
	return completionHash
end

def add_declared_type_to_hash(completionHash, inf_type, dec_type)
	if isArbitraryType(dec_type)
		return
	end

	if completionHash[inf_type] == nil
		completionHash[inf_type] = dec_type
	end
end
