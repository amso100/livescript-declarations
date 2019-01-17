

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
	text.each_line do |line|

		# Only want the global variables, function lines come later.
		if lineHasGlobalVariable(line) and not lineIsFunctionStart(line)

			# puts line
			return true
		end
	end
	return false
end