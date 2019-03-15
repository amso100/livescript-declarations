class TypeDeclaredVar
	attr_accessor :name, :declared_type, :funcScope, :lineno, :scope
	def initialize(name, declared_type, funcScope, lineno, scope)
		@name  = name
		@declared_type  = declared_type
		@funcScope = funcScope
		@lineno = lineno
		@scope = scope
	end
end

class FunctionDeclaration
	attr_accessor :name, :scope, :args, :return_type, :lineno, :initialized
	def initialize(name, lineno, scope)
		@name = name
		@scope = scope
		@lineno = lineno
		@args = Array.new
		@initialized = false
	end
end

class FunctionParameter
	attr_accessor :name, :type
	def initialize(name, type)
		@name = name
		@type = type
	end
end

class VariableReference
	# Name: Variable's name
	# line_declared: Line in which var was declared
	# line_found: Line in which urrent instance was found
	# declared_type: The type this var was declared with (If function, nil)
	# kind: local | global | func
	attr_accessor :name, :line_declared, :line_found, :declared_type, :kind, :scope, :inferred_type, :func_name
	def initialize(name, line_declared, line_found, decl_type, kind, scope, func_name = "")
		@name = name
		@line_declared = line_declared
		@line_found = line_found
		@declared_type = decl_type
		@kind = kind
		@scope = scope
		@inferred_type = ""
		@func_name = func_name
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

class TypeInferredFunction
	attr_accessor :name, :args, :return_type
	def initialize(name, ret_type)
		@name = name
		@args = Array.new
		@return_type = ret_type
	end
end

# Class for keeping data on an assignment of incompatible types.
class BadAssignment
	attr_accessor :lineno, :line, :var1, :type1, :var2, :type2
	def initialize(lineno, line, var1, type1, var2, type2)
		@lineno = lineno
		@line = line
		@var1 = var1
		@type1 = type1
		@var2 = var2
		@type2 = type2
	end
end
