# String to match arguments from declared functions types
# to inferred functions types, to try and find which args
# really need to be declared or inferred-through-scc.

require "./remove_decls.rb"
require "./func_declarations"

# Returns dictionary of all functions parsed,
# with the inferred input types as their values.
def parse_inferred_funcs(program)
	aux = remove_decls(program)
	f_in = File.new("for_funcs.ls", "w")
	f_in.write(aux)
	f_in.close()

	res = Hash.new

	func_infers = `ruby type_infers.rb for_funcs.ls`
	data = func_infers.split("- __global__ -")[1].split("-----")[0].split("\n")
	data.each do |funcLine|
		if funcLine.length < 2
			next
		end
		func_name = funcLine.split(" : ")[0]

		funcArgs  = funcLine.split(" : ")[1].split("->")
		funcArgs.pop # Last element is return type

		res[func_name] = Array.new
		funcArgs.each do |argType|
			res[func_name] << argType
		end
	end
	File.delete("for_funcs.ls")
	return res
end

def get_declared_funcs(program)
	return get_function_declarations(program)
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

def findSubtypeRelations(program)
	
	functionsInferred = parse_inferred_funcs(program)

	functionsDeclared = get_declared_funcs(program)

	functionsDeclared.each_pair do |funcName, argTypes|
		puts "Function name: #{funcName}"
		inferredArgTypes = functionsInferred[funcName]
		inferredArgTypes.each_with_index do |inferredType, ind|
			if not isArbitraryType(inferredType)
				next
			else
				if isArbitraryType(argTypes[ind])
					puts "Unknown type of variable in function #{funcName}"
				else
					puts "#{inferredType} <: #{argTypes[ind]}"
				end
			end
		end
	end
end

text = "
f = (a := A, b := B, c := C, d := D) ->
	a

g = (a := A, b, c := C) ->
	a += 0.1
	b += 0.2
	c = a + b
	c


h = (x, y, z) ->
	x * y * z + 1
"

# j  = ->
# 	1
# "

findSubtypeRelations(text)