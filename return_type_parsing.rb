def single_var_return_statement(line)
	if line =~ /^\t+[A-Za-z]+[A-Za-z0-9_]* *$/ or line =~ /^\t+[A-Za-z]+[A-Za-z0-9_]* *:- *.*$/
		return line[/[A-Za-z0-9_]+/]
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

def parse_for_type(line, local_vars, global_vars, func_name, funcs_dict)
	if lineHasGlobalVariable(line)
		return nil
	end
	# puts line
	var1 = single_var_return_statement(line)
	var2 = var_equals_exp_return_statement(line)
	var3 = constant_return_statement(line)
	var4 = function_call_return_statement(line)
	if var1 != false
		if local_vars[func_name] != nil and local_vars[func_name].keys.include?(var1)
			return local_vars[func_name][var1].declared_type
		elsif global_vars.keys.include?(var1)
			return global_vars[var1].declared_type
		else
			return nil
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