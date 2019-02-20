def parse_function_infers(program)
	aux = remove_decls(program)
	f_in = File.new("for_params.ls", "w")
	f_in.write(aux)
	f_in.close()
	f_inferred = `ruby type_infers.rb for_params.ls`
	functions_dict = Hash.new
	# puts f_inferred
	globals = []
	global_scope = f_inferred.split("-----\n")[1]
	global_scope.each_line do |line|
		if line =~ /->/ # Function line
			function_data = line.split(" : ")
			func_name = function_data[0]
			func_args_return = function_data[1].split("->")
			return_type = func_args_return.pop(1)[0].strip
			
			functions_dict[func_name] = TypeInferredFunction.new(func_name, return_type)

			func_args_return.each do |argType|
				functions_dict[func_name].args << argType
			end
		end
	end
	File.delete("for_params.ls")
	return functions_dict
end

def parse_locals_globals_infers(program)
	res = []
	tmp = []
	globals = []
	i = 0
	
	aux = remove_decls(program)
	f_in = File.new("for_params.ls", "w")
	f_in.write(aux)
	f_in.close()

	f_inferred = `ruby type_infers.rb for_params.ls`
	scopes = f_inferred.split("-----\n")
	scopes.each do |scope|
		if scope =~ /->\n$/ # Empty function
			i += 1
			next
		end
		if scope.strip.length < 2
			next
		end
		scope.split("\n").each do |var|
			
			if var.include? "->" or var =~ /- [A-Za-z0-9_]+ -/ # Don't want class/funcs declarations
				next
			end
			name = var.split(" : ")[0].strip
			type = var.split(" : ")[1].strip
			tmp << TypeInferredVar.new(name, type, i)
		end

		if tmp.length == 0 and not scope.include? "_global_"
			next
		end

		res = res + tmp
		tmp = []
		i += 1
	end

	if tmp.length > 0
		res = res + tmp
	end

	while res.size > 0 and res[0].scope == 0 do
		globals << res[0]
		res = res.drop(1)
	end

	res = [res, globals]

	File.delete("for_params.ls")

	return res
end
