# This will be iterating over declared and inferred types,
# and matching declared to inferred by their scope.
# TODO:
# For each variable in it_d, also compare it to all possible inf_globals
# For each variable in decls_globs, also compare it to all possible inf_globals

require('./typegraph.rb')
require('set')
require "./remove_decls.rb"
require "./find_declarations.rb"

# Class for a variable with declared type.
class TypeDeclaredVar
	attr_accessor :name, :declared_type, :scope
	def initialize(name, declared_type, scope)
		@name  = name
		@declared_type  = declared_type
		@scope = scope
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

class ClassInherits
	attr_accessor :surtype, :subtype
	def initialize(sur, subt)
		@surtype = sur
		@subtype = subt
	end
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

def parse_declarations(program)
	res = []
	globals = []
	tmp = []
	i = -1
	f_declarations = program
	
	f_declarations.each_line do |line|
		aux = line.split(" ; ")
		if i == -1 and aux[1].to_i > 0
			i = aux[1].to_i
		end
		
		if aux[1].to_i == 0
			globals << TypeDeclaredVar.new(aux[2], aux[3].strip, aux[1].to_i)
			next
		end

		if aux[1].to_i != i
			res = res + tmp
			tmp = []
			i = aux[1].to_i
		end

		tmp << TypeDeclaredVar.new(aux[2], aux[3].strip, aux[1].to_i)
	end

	if tmp.length > 0
		res = res + tmp
	end

	res = globals + res

	return res
end

def parse_infers(program)
	res = []
	globals = []
	tmp = []
	i = 0
	
	aux = remove_decls(program)
	f_in = File.new("for_params.ls", "w")
	f_in.write(aux)
	f_in.close()

	f_inferred = `ruby type_infers.rb for_params.ls`
	scopes = f_inferred.split("-----\n")
	scopes.each do |scope|
		scope.split("\n").each do |var|
			if var.include? "-"	# Don't want class/funcs declarations
				next
			end
			name = var.split(" : ")[0].strip
			type = var.split(" : ")[1].strip
			tmp << TypeInferredVar.new(name, type, i)
		end
		if scope.strip.length < 3
			next
		end

		if tmp.length == 0
			next
		end

		res = res + tmp
		tmp = []
		i += 1
	end

	if tmp.length > 0
		res = res + tmp
	end

	while res[0].scope == 0 do
		globals << res[0]
		res = res.drop(1)
	end

	res = [res, globals]

	File.delete("for_params.ls")

	return res
end

def parse_class_inheritance(program)
	res = []
	f_prog = program
	f_prog.each_line do |line|
		if line =~ /class [a-zA-z]{1}[A-Za-z0-9_]* extends [a-zA-z]{1}[A-Za-z0-9_]*\n?/
			sbt, srt = line.match(/class ([a-zA-z]{1}[A-Za-z0-9_]*) extends ([a-zA-z]{1}[A-Za-z0-9_]*)\n?/i).captures
			res << ClassInherits.new(srt, sbt)
		end
	end

	return res
end

def find_in_globals(var_name, globals)
	#puts "In find_in_globals..."
	globals.each do |var|
	#	puts "global name = #{var.name}, var_name = #{var_name}"
		if var.name == var_name
			return var
		end
	end
	return nil
end

def add_type_if_needed(var1, var2, tg)
	d_t = var1.declared_type
	i_t = var2.inferred_type

	if not isArbitraryType(var1.declared_type) and not isArbitraryType(var2.inferred_type)
		tg.add_type(d_t)
		tg.add_type(i_t)
		return
	end

	# Otherwise, one of the types is T-x. We want to add the relationship.

	# The type can be the declared one, or anything that inherits that.
	#puts "#{i_t} is subtype of #{d_t}"
	tg.add_subtype_relation(d_t, i_t)
end

# Adds connections, will be user first on (decls, infrs, inf_globs, 0),
# then on (infs, decls, dec_globs, 1).
# Direction is 0 if to denote add_relation(decl, infr), 1 for add_relation(infr, decl)
def add_necessary_connections(list1, list2, globals, direction)
	it_d = 0
	it_n = 0
	decls = list1
	infrs = list2
	inf_globs = globals
	while it_d < decls.length do
		if it_n == infrs.length or it_d == decls.length
			break
		end

		check_global = find_in_globals(decls[it_d].name, inf_globs)
		
		if check_global != nil
			add_type_if_needed(decls[it_d], check_global, tg)
		end
		# puts "decls[it_d] = #{decls[it_d].declared_type},  #{decls[it_d].name}"
		# puts "infrs[it_n] = #{infrs[it_n].inferred_type},  #{infrs[it_n].name}"
		# puts "---------------"
		if decls[it_d].scope < infrs[it_n].scope
			it_d += 1

		elsif decls[it_d].scope > infrs[it_n].scope
			it_n += 1

		else
			if decls[it_d].name == infrs[it_n].name
				add_type_if_needed(decls[it_d], infrs[it_n], tg)

				it_d += 1
				it_n += 1
			
			else
				it_n += 1
			end
		end
	end
end

prog = "

"


decls = parse_declarations()

infrs = parse_infers()
inf_globs = infrs[1]
infrs = infrs[0]

cls   = parse_class_inheritance()

puts "Declarations:"
decls.each do |var|
	puts "#{var.scope}, #{var.name}, #{var.declared_type}"
end

puts "---------------------------------------------------"

puts "Inferences:"
inf_globs.each do |var|
	puts "#{var.scope}, #{var.name}, #{var.inferred_type}"
end
infrs.each do |var|
	puts "#{var.scope}, #{var.name}, #{var.inferred_type}"
end

# puts "---------------------------------------------------"

# puts "dec = #{decls.length}    ;    inf = #{infrs.length}"

it_d = 0
it_n = 0

tg = TypeGraph.new

infrs.each do |type|
	tg.add_type(type.inferred_type)
end

inf_globs.each do |type|
	tg.add_type(type.inferred_type)
end

decls.each do |type|
	tg.add_type(type.declared_type)
end

while it_d < decls.length do
	if it_n == infrs.length or it_d == decls.length
		break
	end

	check_global = find_in_globals(decls[it_d].name, inf_globs)
	
	if check_global != nil
		add_type_if_needed(decls[it_d], check_global, tg)
	end
	# puts "decls[it_d] = #{decls[it_d].declared_type},  #{decls[it_d].name}"
	# puts "infrs[it_n] = #{infrs[it_n].inferred_type},  #{infrs[it_n].name}"
	# puts "---------------"
	if decls[it_d].scope < infrs[it_n].scope
		it_d += 1

	elsif decls[it_d].scope > infrs[it_n].scope
		it_n += 1

	else
		if decls[it_d].name == infrs[it_n].name
			add_type_if_needed(decls[it_d], infrs[it_n], tg)

			it_d += 1
			it_n += 1
		
		else
			it_n += 1
		end
	end

end

cls.each do |rel|
	tg.add_type(rel.surtype)
	tg.add_type(rel.subtype)

	tg.add_subtype_relation(rel.surtype, rel.subtype)
end

tg.print_all_relations()

possible_types = Hash.new

def get_possible_types(tg, type)
	possible_specific = []
	tg.each_strongly_connected_component_from(type) do |scc|
		scc.each do |t|
			if t == type
				next
			else
				possible_specific << t
			end
		end
	end
	return possible_specific
end

combined = infrs + inf_globs + decls + cls

combined.each do |var|
	var_type = nil
	if var.respond_to?(:declared_type)
		var_type = var.declared_type
	elsif var.respond_to?(:surtype)
		var_type = var.surtype
	else
		var_type = var.inferred_type
	end
	if possible_types.keys.include?(var_type)
		possible_types[var_type] = possible_types[var_type].union(get_possible_types(tg,var_type))
	else
		possible_types[var_type] = Set.new
		possible_types[var_type] = possible_types[var_type].union(get_possible_types(tg,var_type))
	end
end

def set_to_str(s)
	res = ""
	s.each do |var|
		res += (var.to_s + " ")
	end
	return res
end

possible_types.each do |key, value|
	puts "#{key}: #{set_to_str(value)}"
	puts "-----"
end

puts "---------------------------------------------------"

combined = infrs + inf_globs
combined.each do |var|
	puts "Possible surtypes for #{var.name} of type #{var.inferred_type}:"
	puts "#{set_to_str(possible_types[var.inferred_type])}"
	puts "-----"
end