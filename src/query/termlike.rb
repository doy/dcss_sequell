require 'query/ast/ast_walker'

module Query
  module Termlike
    attr_accessor :arguments

    def next_sibling(parent)
      return nil unless parent
      parent.child_offset_from(self, 1)
    end

    def child_offset_from(child, offset)
      return nil unless arguments
      index = arguments.find_index { |arg| arg.eql?(child) }
      return nil unless index
      arguments[index + offset]
    end

    def flag(key)
      @flags && @flags[key]
    end

    def flags
      @flags ||= { }
    end

    def with_flags(flags)
      return self if flags.empty?
      self.each_node { |node| node.with_flags(flags) unless node.equal?(self) }
      self.flags.merge!(flags)
      self
    end

    def flag!(flag_name, value=true)
      self.flags[flag_name] = value
      self
    end

    def recursive_flag!(flag_name)
      self.each_node { |node| node.flag!(flag_name) }
      self
    end

    def sql_expr?
      flag(:sql_expr)
    end

    def negatable?
      false
    end

    def value?
      false
    end

    def args
      self.arguments
    end

    def empty?
      arguments.empty?
    end

    def aggregate?
      arguments.any?(&:aggregate?)
    end

    def display_value(raw_value, display_format=nil)
      self.type.display_value(raw_value, display_format)
    end

    def boolean?
      self.type.boolean?
    end

    def equality?
      self.operator && self.operator.equality?
    end

    def value
      self.right.value if self.right && self.right.kind == :value
    end

    def value=(new_value)
      self.right.value = new_value
    end

    def kind
      :termlike
    end

    def arity
      arguments.size
    end

    def left
      arguments[0]
    end

    alias :first :left

    def right
      arguments[1]
    end

    def single_argument?
      operator && arguments.size == 1
    end

    def field_value?
      filelog { "Caller: #{caller}" }
      arguments.size == 2 &&
        self.left.kind == :field &&
        self.right.kind == :value
    end

    def field
      self.left if self.field_value?
    end

    def field=(field)
      self.arguments[0] = field
    end

    def field_value_predicate?
      boolean? && field_value?
    end

    def field_equality?
      self.operator && self.operator.equality? && self.arity == 2 &&
        self.left.kind == :field
    end

    def field_value_equality?
      field_equality? && self.right.kind == :value
    end

    # Given a value, converts it into a value that can be simply
    # compared with <, based on the type of this term.
    def comparison_value(raw_value)
      self.type.comparison_value(raw_value)
    end

    def map_nodes_as!(mapper, *args, &block)
      self.arguments = self.arguments.map { |arg|
        Query::AST::ASTWalker.send(mapper, arg, *args, &block)
      }.compact
      Query::AST::ASTWalker.send(mapper, self, *args, &block)
    end

    def transform_nodes!(&block)
      self.map_nodes_as!(:map_nodes, &block)
    end

    def transform!(&block)
      block.call(self)
    end

    def map_fields(&block)
      map_nodes_as!(:map_fields, &block)
    end

    def each_field(&block)
      Query::AST::ASTWalker.each_field(self, &block)
    end

    def each(&block)
      self.arguments.each(&block)
    end

    def each_predicate(&block)
      # Do nothing
    end

    def each_node(&block)
      Query::AST::ASTWalker.each_node(self, &block)
    end

    def each_value(&block)
      Query::AST::ASTWalker.each_value(self, &block)
    end

    def without(&filter)
      Query::AST::ASTWalker.map_nodes(self.dup, nil, filter) { nil }
    end

    def wrap_if(condition, left, right=left)
      expr = yield
      return left + expr + right if condition
      expr
    end

    def sql_values
      []
    end

    def to_sql_output
      type.coerce_expr(to_sql)
    end

    def to_query_string(paren=false)
      to_s
    end

    def convert_types!
      self
    end

    def convert_to_type(type)
      self
    end
  end
end
