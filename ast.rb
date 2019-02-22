require "./nodes.rb"
require "./scope.rb"
require "./unify.rb"

class Ast
	attr_accessor :defined_vars
	def initialize(ast_json)
		Node.scope = ClassScope.new("__global__") 
		@head= parseAstFromJsonToNodes(ast_json)
	end

	def add_completion_subtype_equations(completionHash)
		completionHash.each_pair do |arbitraryType, completeVal|
			eq1 = Equation.new(TypeVar.new(arbitraryType), Constant.new(completeVal))
			eq2 = Equation.new(Constant.new(completeVal), TypeVar.new(arbitraryType))
			Scope.unifier.add_equation(eq1)
			Scope.unifier.add_equation(eq2)
		end
	end

	def get_vars
		@head.get_vars
		pp "____BEFORE____"
		puts "\n\nPrinting vars\n\n"
		Node.scope.print_vars(0)
		puts "\n\nPrinting subtypes equations\n\n"

		Scope.unifier.print_subtypes_equations

		puts "\n\n\n"
		pp "____AFTER____"
		puts "\n\nInfering\n\n"
		Node.scope.infer
		puts "Printing resolved vars"
		# Scope.unifier.infer why calling it twice?
		# Scope.unifier.print_subtypes_equations
		Node.scope.print_vars(0)
	end

	def print_vars
		@head.get_vars
		Node.scope.infer
		Node.scope.print_vars(0)
	end
end