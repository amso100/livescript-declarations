# Goes over file, and prints all found type declarations

def lineIsParamsFunctionStart(line)
	if line =~ /[A-Za-z0-9]+ *= *\([A-Za-z0-9,_ :=]*\) ->\n?/
		return true
	else
		return false
	end
end

def lineIsNoParamsFunctionStart(line)
	if line =~ /[A-Za-z0-9]+ *= *->\n?([A-Za-z0-9]*)?/
		return true
	else
		return false
	end
end

def lineIsFunctionStart(line)
	if lineIsParamsFunctionStart(line) or lineIsNoParamsFunctionStart(line)
		return true
	else
		return false
	end
end

def lineHasGlobalVariable(line)
	return (line.scan(/^[A-Za-z0-9]+ *= */).size > 0)
end

def lineHasGlobalDeclaration(line)
	return line =~ /[a-zA-z_]{1}[A-Za-z0-9_]* *:= *[a-zA-z_]{1}[A-Za-z0-9_]*/
end

# Finds if there are any global vars (and counting starts from 1)
# or there aren't (and counting starts from 0).
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

def count_tabs_at_start(line)
	c = 0
	while line[c].ord == 9 do
		c += 1
	end
	return c
end

def print_type_declarations(text)
	# aux = File.new("declarations.txt", "w+")
	lineno = 1
	in_scope = 0
	temp = -2
	scopeno = -1
	nested_scope = -1
	prev_nested_num = -1
	base_scope = -1
	first_func = true

	contains_globals = global_variables_exist(text)
	# if contains_globals
	# 	puts "Globals found."
	# else
	# 	puts "Globals not found."
	# end

	if contains_globals
		base_scope = 1
		scopeno = 1
	else
		base_scope = 0
		scopeno = 0
	end

	max_scope = base_scope

	text.gsub(/\r\n?/, "\n")

	result_str = ""

	text.each_line do |line|
		# puts line
		# puts "Current scope num: #{scopeno}"
		nested_scope = count_tabs_at_start(line)
		# puts "Nested scope = #{nested_scope}"

		if lineIsFunctionStart(line) and in_scope == 0
			#puts "Function start"
			in_scope = 1
			if first_func == false
				scopeno += 1
			else
				first_func = false
			end

		elsif lineIsFunctionStart(line) and in_scope == 1
			#puts "Function start, no break"
			in_scope = 1
			scopeno = max_scope + 1

		elsif nested_scope == 0 and in_scope == 1
			temp = scopeno
			scopeno = 0
			in_scope = 0
			#puts "In global scope"

		elsif line =~ /^[^\t].*/ and line.length > 1
			#puts "In global scope"
			temp = scopeno
			scopeno = 0
		end
		# puts "in_scope = #{in_scope}"
		# puts "scopeno = #{scopeno}"

		line.scan(/[a-zA-z_]{1}[A-Za-z0-9_]* *:= *[a-zA-z_]{1}[A-Za-z0-9_]*/) do
			|match| a = match.scan(/[a-zA-z_]{1}[A-Za-z0-9_]*/)[0]
			b = match.scan(/[a-zA-z_]{1}[A-Za-z0-9_]*/)[1]
			# line # | scope # | var name | Type name
			result_str += "#{lineno} ; #{scopeno} ; #{a} ; #{b}\n"
		end

		if temp != -2
			scopeno = temp
			temp = -2
		end
		# puts ""
		lineno += 1
		if scopeno >= max_scope
			max_scope = scopeno
		end
		prev_nested_num = nested_scope
	end


	return result_str
end

# text = File.open("test1.ls").read
# print_type_declarations(text)

# text = 
# " e :=    E
# g:=G
# f = (a := A, b := B, c := C) ->
# 	a + b + c

# i = ->
# 	a := A
# 	0

# "

# puts print_type_declarations(text)