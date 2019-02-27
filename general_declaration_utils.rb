def add_variable_reference(allReferences, newRef)
	found = false
	allReferences.each do |ref|
		
		# Inserting a reference twice will cause an infinite loop
		if ref.name == newRef.name and ref.line_found == newRef.line_found
			return false
		end

		if ref.name == newRef.name and ref.line_found == newRef.line_found
			found = true
			ref.declared_type = newRef.declared_type
			return true
		end
	end
	if not found
		# puts "adding reference to var #{newRef.name.split("")}"
		allReferences << newRef
		return true
	end
	return false
end

def setup_variable_types(allTypes, local_vars, global_vars)
	local_vars.each_pair do |scope, scopeVars|
		scopeVars.each_pair do |name, varData|
			if not allTypes.include? varData.declared_type
				allTypes << varData.declared_type
			end
		end
	end

	global_vars.each_pair do |name, varData|
		if not allTypes.include? varData.declared_type
			allTypes << varData.declared_type
		end
	end
	allTypes << "int" << "string" << "double" << "float" << "char"
end

def update_relevant_global_references(allReferences, varName, lineDeclared, typeDeclared)
	allReferences.each do |ref|
		if ref.kind == "local" and ref.name == varName and isArbitraryType(ref.declared_type)
			# puts "#{ref.name} : #{ref.kind} : #{ref.scope} : #{ref.declared_type}"
			ref.kind = "global"
			ref.declared_type = typeDeclared
			ref.line_declared = lineDeclared

		elsif ref.name == varName and ref.kind == "global"
			ref.line_declared = lineDeclared
			ref.declared_type = typeDeclared
		end
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

def find_inferred_var_in_declared(var, declaredHash)
	# puts "Searching for #{var.name} (scope #{var.scope})"
	declaredHash.each_pair do |funcName, localVars|
		if localVars.size == 0
			next
		elsif localVars[localVars.keys[0]].scope != var.scope
			next
		else
			return localVars[var.name]
		end
	end
	return nil
end

def find_inferred_var_in_globals(var, globalsHash)
	return globalsHash[var.name]
end

def find_inferred_func_in_funcs(func, declaredFunctions)
	return declaredFunctions[func]
end

def fix_reference_type(allReferences)
	allReferences.each do |ref|
		if ref.scope != 0
			ref.kind = "local"
		end
	end
end

def get_all_class_names(program_text)
	names = Array.new
	program_text.each_line do |line|
		if line =~ /class .+$/
			className = ""
			if line.include? "extends"
				className = line[/ .+ /]
				className.sub! "extends", ""
			else
				className = line[/ .+$/]
			end
			className.strip!
			names << className
		end
	end
	return names
end


def fix_globals_identified_local(local_vars, global_vars, var_references)
	local_vars.each_pair do |funcName, locals|
		locals.each_pair do |varName, varData|
			# puts "Checking: #{varName} of type #{varData.declared_type} (scope #{varData.scope})"
			if isArbitraryType(varData.declared_type) and global_vars.include? varName
				# puts "Fixing: #{varName} :- #{global_vars[varName].declared_type}"
				varData.declared_type = global_vars[varName].declared_type
				# fix_accidental_local_references(varName, varData, var_references, locals)
			end
		end
	end
end

def fix_references_types(var_references, varName, scope, actualType)
	currentType = ""
	var_references.each do |ref|
		if ref.name == varName and ref.scope == scope and isArbitraryType(ref.declared_type)
			currentType = ref.declared_type
			break
		end
	end
	if currentType == ""
		return
	end
	var_references.each do |ref|
		if ref.scope == scope and ref.declared_type == currentType
			ref.declared_type = actualType
		end
	end
end

def find_type_in_references(var_references, var_name, scope)
	var_references.each do |ref|
		if ref.name == var_name and ref.scope == scope
			return ref.declared_type
		end
	end
	return nil
end

# def fix_accidental_local_references(varName, varData, var_references, locals)
# 	var_references.each do |ref|
# 		if ref.kind == "local" and ref.scope == varData.scope and ref.name == varName
			
# 			if not locals.keys.include? varName
# 				puts "11"
# 				ref.kind = "global"
# 				ref.declared_type = varData.declared_type
# 			end
# 		end
# 	end
# end