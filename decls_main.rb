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

res_var_infers = parse_locals_globals_infers(text)
inferred_locals = res_var_infers[0]
inferred_globs  = res_var_infers[1]
inferred_funcs  = parse_function_infers(text)

try_to_complete_missing_types(inferred_locals, inferred_globs, inferred_funcs, declared_locals, declared_globs, declared_funcs)