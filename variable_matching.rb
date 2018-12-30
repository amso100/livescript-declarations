# Remaking of the "decls_infers_matching.rb", in a
# WAY more organized and readable way.

require "./find_declarations.rb"
require "./typegraph.rb"
require "set"
require "./remove_decls.rb"

def isArbitraryType(typeName)
	if typeName =~ /T-[0-9]+/
		return true
	elsif typeName =~ /T'-[0-9]+/
		return true
	else
		return false
	end
end

# Class for a variable with declared type.
class TypeDeclaredVar
	attr_accessor :name, :declared_type, :scope, :lineno
	def initialize(name, declared_type, scope, lineno)
		@name  = name
		@declared_type  = declared_type
		@scope = scope
		@lineno = lineno
	end
end

# Class for a variable with inferred type.
class TypeInferredVar
	attr_accessor :name, :inferred_type, :scope
	def initialize(name, inferred_type, scope)
		@name  = name
		@inferred_type  = inferred_type
		@scope = scope
	end
end

def parse_infers(program)
	res =  Hash.new
	tmp = []
	scope_num = 0
	
	aux = remove_decls(program)
	f_in = File.new("for_params.ls", "w")
	f_in.write(aux)
	f_in.close()

	f_inferred = `ruby type_infers.rb for_params.ls`
	scopes = f_inferred.split("-----\n")
	scopes.each do |scope|
		scope.split("\n").each do |var|

			if var.include? "->"	# Don't want class/funcs declarations right now
				next
			end

			name = var.split(" : ")[0]
			type = var.split(" : ")[1]

			if name == nil or type == nil
				next
			else
				name = name.strip
				type = type.strip
			end

			tmp << TypeInferredVar.new(name, type, scope_num)
		end
		if scope.strip.length < 3
			next
		end

		if tmp.length == 0
			next
		end

		res[scope_num] = tmp
		tmp = []
		scope_num += 1
	end

	if tmp.length > 0
		res[scope_num] = tmp
	end

	File.delete("for_params.ls")

	return res
end

def parse_declarations(program)
	aux = print_type_declarations(program)

	res = Hash.new

	aux.each_line do |line|
		line_arr   = line.split(" ; ")
		
		line_num   = line_arr[0].to_i
		scope_num  = line_arr[1].to_i
		var_name   = line_arr[2]
		type_name  = line_arr[3]

		if res[scope_num] == nil
			res[scope_num] = Array.new
		end
		var_data = TypeDeclaredVar.new(var_name, type_name, scope_num, line_num)
		res[scope_num] << var_data
	end
	return res
end

def get_max_scope_num(dict)
	if dict.keys.size == 0
		return -1
	end
	return dict.keys.max
end

def seachDeclaredVars(vars, name, scope)
	# puts "Searching scope #{scope}..."
	if vars == nil
		return nil
	end
	vars.each do |var|
		# puts "Var name is #{var.name}"
		if var.name == name and var.scope == scope
			return var
		end
	end
	return nil
end

def tryToMatchVariables(program)
	declared_vars = parse_declarations(program)
	declared_vars.each_pair do |k,v|
		puts "Scope #{k}:"
		v.each do |var|
			puts "#{var.name}: #{var.declared_type}"
		end
	end
	inferred_vars = parse_infers(program)
	inferred_vars.each_pair do |k,v|
		puts "Scope #{k}:"
		v.each do |var|
			puts "#{var.name}: #{var.inferred_type}"
		end
	end

	max1 = get_max_scope_num(declared_vars)
	max2 = get_max_scope_num(inferred_vars)

	max_scope_num = max2 #[max1, max2].max
	scope_num = 0

	while scope_num <= max_scope_num do

		# Go over inferred, if found T-x see if same var is in declared
		# If so, add the corresponding subtype relation.
		# If not, print "unmatched type T-x"

		scope_declared = declared_vars[scope_num]
		scope_inferred = inferred_vars[scope_num]
		scope_inferred.each do |var|
			if isArbitraryType(var.inferred_type)
				matched_var = seachDeclaredVars(scope_declared, var.name, var.scope)
				if matched_var != nil and not isArbitraryType(matched_var.declared_type)
					
					# If found arbitrary type inferred, and declared is not arbitrary,
					# then we have a match and want to print it / use it.
					puts "#{var.inferred_type} <: #{matched_var.declared_type}"
				else
					# If the inferred type is arbitrary but we could not find a declaration
					# then the type is currently unknown (unless proven by a later variable).
					puts "Type #{var.inferred_type} could not be established."
				end
			else
				next
			end
		end
		scope_num += 1
	end
end

# text = "
# f = (a := A, b:= B, c, d, e:=     F) ->
# 	a

# g = (b, c:=C, e := E) ->
# 	b
# j =   ->
# 	1
# "

text = "
class A extends int

f = (a := A) ->
	a

a = f(new A)
"

tryToMatchVariables(text)