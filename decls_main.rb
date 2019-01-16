# This will be the main "declarations" program, which will run
# the other functions and print (or convert to json later)

require("./program_declarations.rb")

if ARGV.size == 0
	puts("File name missing")
	exit()
end

ls_file = ARGV[0]
if ARGV[0].split('.')[-1] != 'ls'
	puts("Must be a livescript file")
	exit()
end

f_prog = File.open(ls_file, "r")
text = f_prog.read
f_prog.close()

res_declared = getProgramDeclarationsAndReferences(text)
declared_funcs  = res_declared[0]
declared_globs  = res_declared[1]
declared_locals = res_declared[2]
res_references = res_declared[3]

res_var_infers = parse_locals_globals_infers(text)
inferred_locals = res_var_infers[0]
inferred_globs  = res_var_infers[1]
inferred_funcs  = parse_function_infers(text)

try_to_complete_missing_types(inferred_locals, inferred_globs, inferred_funcs, declared_locals, declared_globs, declared_funcs)

puts "Functions:"
declared_funcs.each_pair do |key, value|
	puts "Function name: #{value.name}"
	puts "Function Scope: #{value.scope}"
	puts "Arg types: #{value.args.map {|arg| arg.type}}"
	if value.return_type != nil
		puts "Return Type: #{value.return_type}"
	else
		puts "Return Type: Could not be determined."
	end
	puts ""
end

puts "Globals:"
declared_globs.each_pair do |key, value|
	puts "Global name: #{value.name}"
	puts "Global Type: #{value.declared_type}"
	puts "Global line: #{value.lineno}"
	puts ""
end

puts "Local Variables:"
declared_locals.each_pair do |key, data|
	puts "Local variables in #{key}:"
	data.each_pair do |k, value|
		puts "\tVar name: #{value.name}"
		puts "\tVar Scope: #{value.scope}"
		puts "\tVar Type: #{value.declared_type}"
		puts "\tVar line: #{value.lineno}"
		puts "\t----------"
	end
	puts "------------------"
end

puts ""

puts "Variable References:"
res_references.each do |data|
	puts "\tVariable #{data.name} used in line #{data.line_found}:"
	puts "\tVariable kind is #{data.kind}"
	if data.declared_type != nil
		puts "\tVariable declared as #{data.declared_type}"
	end
	puts "\tVariable declared in line #{data.line_declared}"
	puts "\t----------"
end
