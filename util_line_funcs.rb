
require "./ast.rb"

def get_line_declarations(line, allTypes)
	declarations = Hash.new
	line.scan(/[A-Za-z_]{1}[A-Za-z0-9_]* *:- *[A-Za-z_]{1}[A-Za-z0-9_]*/) do
		|match| a = match.scan(/[a-zA-z_]{1}[A-Za-z0-9_]*/)[0]
		b = match.scan(/[a-zA-z_]{1}[A-Za-z0-9_]*/)[1]
		if allTypes.include?(a) or b == nil
			next
		end

		# If actually a declaration
		declarations[a] = b
	end
	return declarations
end

def get_line_variables(line, possibleTypes)
	vars = Array.new
	line.scan(/[A-Za-z]{1}[A-Za-z0-9_]*[^"]\n?|[A-Za-z]{1}[A-Za-z0-9_]*$/) do |m|
		# puts "#{m.split("")}"
		if m =~ /^[A-Za-z]{1}[A-Za-z0-9_]*\"\n?$/
			# Do nothing. Not a variable.
		elsif not m =~ /^[A-Za-z]{1}[A-Za-z0-9_]*$/
			m = m[0...-1]
		end

		if m == "new" or m == "class" or m == "extends" # or m == [some other keyword]
			next
		elsif possibleTypes.include? m
			next
		end
		# puts "found var #{m} in linenoine \"#{line}\""
		vars << m 
	end
	return vars
end

def lineHasGlobalVariable(line)
	return (line.scan(/^[A-Za-z0-9]+ *= */).size > 0)
end

def lineHasFunctionCall(line)
	if line =~ /^.*[A-Za-z0-9_]+\(.*\).*/
		return line[/[A-Za-z0-9_]+\(.*\)/]
	else
		return false
	end
end

def count_tabs_at_start(line)
	c = 0
	while line[c].ord == 9 do
		c += 1
	end
	return c
end

def global_variables_exist(text)
	f_in = File.open("for_globals.ls", "w")
	aux = remove_decls(text)
	f_in.write(aux)
	f_in.close()
	uninferred_vars_text = `ruby type_infers.rb for_globals.ls`
	global_scope = uninferred_vars_text.split("-----\n")[1]
	global_scope.each_line do |line|
		if line.include? "->" or line =~ /- [A-Za-z0-9_]+ -/
			next
		end
		File.delete("for_globals.ls")
		return true
	end
	File.delete("for_globals.ls")
	return false
end

# def get_global_variable_names(text)
# 	names = Array.new
# 	f_in = File.open("for_globals.ls", "w")
# 	aux = remove_decls(text)
# 	f_in.write(aux)
# 	f_in.close()
# 	uninferred_vars_text = `ruby type_infers.rb for_globals.ls`
# 	global_scope = uninferred_vars_text.split("-----\n")[1]
# 	global_scope.each_line do |line|
# 		if line.include? "->" or line =~ /- [A-Za-z0-9_]+ -/
# 			next
# 		end
# 		if line.split(" : ").length < 2
# 			next
# 		end
# 		name = line.split(" : ")[0].strip
# 		names << name
# 	end
# 	File.delete("for_globals.ls")
# 	return names
# end