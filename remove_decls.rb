# Function to remove all "type declarations"
# from a given text

def lineIsParamsFunctionStart(line)
	if line =~ /[A-Za-z0-9]+ *= *\([A-Za-z0-9,_ :-]*\) ->\n?/
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

def remove_decls(text)
	text.gsub(/\r\n?/, "\n")
	final_res = ""
	text.each_line do |line|
		if lineIsFunctionStart(line)
			res = line.gsub(/:- *[A-Za-z]{1}[A-Za-z0-9_]*/, " ")
		else
			res = line.gsub(/[A-Za-z]{1}[A-Za-z0-9_]* *:- *[A-Za-z]{1}[A-Za-z0-9_]*/, " ")
		end
		final_res += res
	end
	return final_res
end
