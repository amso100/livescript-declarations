def add_variable_reference(allReferences, newRef)
	found = false
	allReferences.each do |ref|
		# Inserting a reference twice will cause an infinite loop
		if ref.name == newRef.name and ref.line_found == newRef.line_found and ref.column_found == newRef.column_found
			return false
		end
	end
	allReferences << newRef
	return true
end

# Checks if array type declarations are simplified.
# Aux for the simplify_array function
# Simplified: T-x :- A, T-x :- [A]
# Not simplified: [T-x] :- [A], [[T-x]] :- [[[A]]]
def array_simplified(a, b)
	return (/^[A-Za-z_]{1}[A-Za-z0-9_-]*$/.match?(a) and /^[\[]*[A-Za-z_]{1}[A-Za-z0-9_]*[\]]*$/.match?(b))
end

def simplify_array_declaration(a, b)
	if array_simplified(a, b) == true
		return [a, b]
	else
		a = a[1..-2]
		b = b[1..-2]
		return simplify_array_declaration(a, b)
	end
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
			if isArbitraryType(varData.declared_type) and global_vars.include? varName
				varData.declared_type = global_vars[varName].declared_type
			end
		end
	end
end

def fix_references_types(var_references, varName, scope, actualType, local_vars, global_vars, funcs_dict)
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
	local_vars.each_pair do |func, vars|
		vars.each_pair do |name, data|
			if data.declared_type == currentType
				data.declared_type = actualType
			end
		end
	end
	global_vars.each_pair do |name, data|
		if data.declared_type == currentType
			data.declared_type = actualType
		end
	end
	funcs_dict.each do |name, data|
		if data.return_type == currentType
			data.return_type = actualType
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
