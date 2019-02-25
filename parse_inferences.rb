def parse_function_infers(program, is_inferred = false)
	f_inferred = ""
	if not is_inferred
		aux = remove_decls(program)
		f_in = File.new("for_params.ls", "w")
		f_in.write(aux)
		f_in.close()
		f_inferred = `ruby type_infers.rb for_params.ls`
	else
		f_inferred = program
	end

	functions_dict = Hash.new
	# puts f_inferred
	globals = []
	if is_inferred
		f_inferred = f_inferred.split("_AFTER_")[1].split("vars")[1]
	end
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

	if not is_inferred
		File.delete("for_params.ls")
	end

	return functions_dict
end

def parse_locals_globals_infers(program, is_inferred = false)
	res = []
	tmp = []
	globals = []
	no_globals = false
	i = 0
	f_inferred = ""
	if not is_inferred
		aux = remove_decls(program)
		f_in = File.new("for_params.ls", "w")
		f_in.write(aux)
		f_in.close()
		f_inferred = `ruby type_infers.rb for_params.ls`
	else
		f_inferred = program
	end
	if is_inferred
		f_inferred = f_inferred.split("_AFTER_")[1].split("vars")[1]
	end
	scopes = f_inferred.split("-----\n")
	scopes.each do |scope|
		# puts scope
		if scope =~ /->\n$/ # Empty function
			# puts "111"
			i += 1
			next
		end
		if scope =~ /- [A-Za-z0-9_]+ -/ and not scope =~ /- __global__ -/
			# puts "222"
			next
		end
		if scope.strip.length < 2
			# puts "333"
			next
		end
		# puts "444"
		# puts i
		scope.split("\n").each do |var|
			if var.include? "->" or var =~ /- [A-Za-z0-9_]+ -/ # Don't want class/funcs declarations
				next
			end
			if var.split(" : ").length < 2
				next
			end
			name = var.split(" : ")[0].strip
			type = var.split(" : ")[1].strip
			# puts "#{name}, #{type}"
			tmp << TypeInferredVar.new(name, type, i)
		end

		if tmp.length == 0 #and not scope.include? "_global_"
			if scope.include? "_global_"
				no_globals = true
			end
			next
		end

		res = res + tmp
		tmp = []
		i += 1
		# puts "------------------"
	end

	if tmp.length > 0
		res = res + tmp
	end

	while res.size > 0 and res[0].scope == 0 and not no_globals do
		globals << res[0]
		res = res.drop(1)
	end

	res = [res, globals]

	if not is_inferred
		File.delete("for_params.ls")
	end

	return res
end
