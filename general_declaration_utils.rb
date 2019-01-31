def add_variable_reference(allReferences, newRef)
	found = false
	allReferences.each do |ref|
		
		# Inserting a reference twice will cause an infinite loop
		if ref.name == newRef.name and ref.line_found == newRef.line_found and ref.declared_type == newRef.declared_type
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
end

def update_relevant_global_references(allReferences, varName, lineDeclared)
	allReferences.each do |var|
		if var.name == varName and var.kind == "global"
			var.line_declared = lineDeclared
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