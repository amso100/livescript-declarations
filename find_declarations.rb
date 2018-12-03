# Goes over file, and prints all found type declarations

def print_type_declarations(text)
	# aux = File.new("declarations.txt", "w+")
	lineno = 1
	scopeno = 1
	in_scope = 0
	temp = -2
	text.gsub!(/\r\n?/, "\n")
	text.each_line do |line|
		if line =~ /[A-Za-z0-9]+ *= *\([A-Za-z0-9,_ :=]*\) ->\n?/ and in_scope == 0
			in_scope = 1

		elsif line.length == 1 and in_scope == 1
			in_scope = 0
			scopeno += 1

		elsif line =~ /^[^\t].*/ and line.length > 1
			temp = scopeno
			scopeno = 0
		end

		decls = line.scan(/[a-zA-z_]{1}[A-Za-z0-9_]* *:= *[a-zA-z_]{1}[A-Za-z0-9_]*/) do
			|match| a = match.scan(/[a-zA-z_]{1}[A-Za-z0-9_]*/)[0]
			b = match.scan(/[a-zA-z_]{1}[A-Za-z0-9_]*/)[1]
			# printf(aux, "#{lineno} ; #{scopeno} ; #{a} ; #{b}\n")
			puts "#{lineno} ; #{scopeno} ; #{a} ; #{b}"
		end

		if temp != -2
			scopeno = temp
			temp = -2
		end
		lineno += 1
	end
end

text = File.open("test1.ls").read
print_type_declarations(text)