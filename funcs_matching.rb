# String to match arguments from declared functions types
# to inferred functions types, to try and find which args
# really need to be declared or inferred-through-scc.

require "./remove_decls.rb"

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
	puts data[2]
	data.each do |funcLine|
		if data.length < 2
			next
		end
		puts data
		func_name = funcLine.split(" : ")[0]
		
		funcArgs  = funcLine.split(" : ")[1].split("->")
		funcArgs.pop # Last element is return type

		res[func_name] = Array.new
		funcArgs.each do |argType|
			if(argType != "unit")
				res[func_name] << argType
			end
		end
	end
	return res
end

text = "
g = (a, b, c) ->
	a
j = ->
	10
"

# text = "
# foo = (a,b) ->
#   a
#"

res = parse_inferred_funcs(text)
res.each_pair do |k, v|
	puts "Func name is #{k}"
	puts "Func Args are #{v}"
end