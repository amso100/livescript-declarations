# Class for a graph, implemented by neighbors-list

require("tsort")

class TypeGraph

	include TSort

	# neighbor-list:
	# A list of all neighbors for a given type.
	# A->B in G <==> A is a subtype of B

	def tsort_each_child(n, &b) @neighbors_list[n].each(&b) end

	def tsort_each_node(&b) @neighbors_list.each_key(&b) end
	
	# Initializes an empty graph.
	def initialize()
		@neighbors_list = Hash.new
		@arbitrary_type = 0
	end

	# Adds a new type with no connections to other types.
	# If the type already exists, does nothing.
	def add_type(type_name)
		if @neighbors_list.include?(type_name)
			return
		else
			@neighbors_list[type_name] = Array.new
		end
	end

	# Adds a new subtype relation between two existing types.
	# A is subtype of B: add_subtype_relation(B, A)
	def add_subtype_relation(larger, smaller)
		if not @neighbors_list.include?(larger) or not @neighbors_list.include?(smaller)
			return false
		elsif @neighbors_list[smaller].include?(larger)
			return true
		else
			@neighbors_list[smaller].push(larger)
			return true
		end
	end

	# Returns the array of immediate surtypes of a given type.
	def get_surtypes(type)
		return @neighbors_list[type]
	end

	# Prints all immediate surtypes of a given type.
	def print_type_relations(type)
		puts "#{type} is subtype of:"
		puts get_surtypes(type) * " ; "
	end

	# Prints all relations (the graph itself)
	def print_all_relations()
		@neighbors_list.each_pair {|key, value|
			print_type_relations(key)
			puts ""
		}
	end
end