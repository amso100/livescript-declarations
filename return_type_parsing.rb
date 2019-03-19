def single_var_return_statement(line)
	if line =~ /^\t+[A-Za-z]+[A-Za-z0-9_]* *$/ or line =~ /^\t+[A-Za-z]+[A-Za-z0-9_]* *:- *.*$/
		return line[/[A-Za-z0-9_]+/]
	else
		return false
	end
end

def var_equals_var_statement(line)
	if line =~ /^[\t]?[A-Za-z]+[A-Za-z0-9_]* *= *[A-Za-z]+[A-Za-z0-9_]*$/
		var0 = line[/[A-Za-z0-9_]+/]
		i1 = line.index('=')
		line = line[i1..-1]
		var1 = line[/[A-Za-z0-9_]+/]
		return [var0, var1]
	elsif line =~ /^[\t]?[A-Za-z]+[A-Za-z0-9_]* *= *[A-Za-z]+[A-Za-z0-9_]*\(.*\)$/
		var0 = line[/[A-Za-z0-9_]+/]
		i1 = line.index('=')
		line = line[i1..-1]
		var1 = line[/[A-Za-z0-9_]+/]
		return [var0, var1]
	else
		return false
	end
end

def var_equals_exp_return_statement(line)
	if line =~ /^\t+[A-Za-z]+[A-Za-z0-9_]* *= *.+/
		return line[/[A-Za-z0-9_]+/]
	else
		return false
	end
end

def constant_return_statement(line)

	if line =~ /\t+[0-9]+\.[0-9]+/
		return [line[/[0-9]+(.[0-9]+)?/], "double"]

	elsif line =~ /\t+\".*\"/
		return [line[/\".*\"/], "string"]
	elsif line =~ /\t+\'.*\'/
		return [line[/\'.*\'/], "string"]
	elsif line =~ /\t+\\.*/
		return [line[/\\.*/], "string"]

	elsif line =~ /\t+[0-9_]+[A-Za-z]*/
		return [line[/[0-9_]+[A-Za-z]*/], "int"]

	elsif line =~ /\t+(true|false|on|off|yes|no)/
		return [line[/(true|false|on|off|yes|no)/], "bool"]

	elsif line =~ /\t+\[.*\]/
		return [line[/\[.*\]/], "list"]

	elsif line =~ /\t\{.+\}/
		return [line[/\{.+\}/], "dict"]

	else
		return nil
	end
end

def function_call_return_statement(line)
	if line =~ /\t+[A-Za-z0-9_]+\(.*\)/
		return line[/[A-Za-z0-9_]+/]
	else
		return false
	end
end

def check_global_references(var, var_references)
	var_references.each do |ref|
		if var == ref.name and ref.kind == "global"
			return ref
		end
	end
	return nil
end

def parse_for_type(line, local_vars, global_vars, func_name, funcs_dict, var_references)
	if lineHasGlobalVariable(line)
		return nil
	end
	var1 = single_var_return_statement(line)
	var12 = var_equals_var_statement(line)
	var2 = var_equals_exp_return_statement(line)
	var3 = constant_return_statement(line)
	var4 = function_call_return_statement(line)
	if var1 != false
		# puts var1
		if local_vars[func_name] != nil and local_vars[func_name].keys.include?(var1)
			return local_vars[func_name][var1].declared_type
		elsif global_vars.keys.include?(var1)
			return global_vars[var1].declared_type
		else
			check_global = check_global_references(var1, var_references)
			if check_global != nil
				return check_global.declared_type
			else
				return nil
			end
		end

	elsif var12 != false
		var1 = var12[1]
		if local_vars[func_name] != nil and local_vars[func_name].keys.include?(var1)
			return local_vars[func_name][var1].declared_type
		elsif global_vars.keys.include?(var1)
			return global_vars[var1].declared_type
		else
			check_global = check_global_references(var1, var_references)
			if check_global != nil
				return check_global.declared_type
			else
				return nil
			end
		end

	elsif var2 != false
		if local_vars[func_name] != nil and local_vars[func_name].keys.include?(var2)
			return local_vars[func_name][var2].declared_type
		elsif global_vars.keys.include?(var2)
			return global_vars[var2].declared_type
		else
			return nil
		end

	elsif var3 != nil
		return var3[1]

	elsif var4 != false
		if funcs_dict.keys.include?(var4)
			return funcs_dict[var4].return_type
		end

	else
		# puts "Error identifying return variable"
	end
	return nil

end

def local_parse_for_type(cur_line, local_vars, func_name, var_references, scope, funcs_dict, line=0)
	local_vars = local_vars[func_name]
	var0 = var_equals_var_statement(cur_line)
	if var0 == false
		return nil
	end
	var1 = var0[1]
	var0 = var0[0]
	if var1 != nil
		if local_vars.include? var1 and not isArbitraryType(local_vars[var1].declared_type)
			return [var0, local_vars[var1].declared_type, var1]
		elsif funcs_dict.include? var1 and not isArbitraryType(funcs_dict[var1].return_type)
			return [var0, funcs_dict[var1].return_type, var1]
		else
			var_references.each do |ref|
				if ref != nil and ref.name == var1 and ref.func_name == func_name and ref.declared_type != nil and not isArbitraryType(ref.declared_type)
					return [var0, ref.declared_type, var1]
				end
			end
		end
	end
	return nil
end

def global_parse_for_type(cur_line, global_vars, var_references, funcs_dict)
	# puts cur_line
	var0 = var_equals_var_statement(cur_line)
	if var0 == false
		return nil
	end
	var1 = var0[1]
	var0 = var0[0]
	if var1 != nil
		if global_vars.include? var1
			return [var0, global_vars[var1].declared_type, var1]
		elsif funcs_dict.include? var1
			# puts "(#{global_vars[var0].declared_type}) #{var0} = #{var1} (#{funcs_dict[var1].return_type})"
			return [var0, funcs_dict[var1].return_type, var1]
		else
			var_references.each do |ref|
				if ref != nil and ref.name == var1 and ref.kind == "global" and ref.declared_type != nil and not isArbitraryType(ref.declared_type)
					return [var0, ref.declared_type, var1]
				end
			end
		end
	end
	return nil
end