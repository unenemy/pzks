class Processor
  include Settings
  include Comut
  include Scoper
  def scope_hard(expression)
    scope = ->(exp){
      i = 0
      while i < exp.size
        if HARD.include?(exp[i])
          j = i
          while HARD.include?(exp[j])
            j+=2
          end
          range_in_scope!(exp, i-1, j-1)
        end
        i+=1
      end
    }
    scope_in_scope = ->(exp){
      exp.each{|node| scope_in_scope[node] if node.is_a?(Array)}
      scope[exp]
    }
    scope_in_scope[expression]
    expression
  end

  def zero_if_operation_in_scope(expression)
    expression.unshift("0") if expression.first == MINUS
    expression.delete_at(0) if expression.first == PLUS
    expression.each{|node|
      zero_if_operation_in_scope(node) if node.is_a?(Array)
    }
  end

  def normalize_scopes!(expression)
    if expression.size == 1
      scope = expression.first
      scope.each{|node| expression << node}
      expression.delete_at(0)
    end
    expression.each{|node| normalize_scopes!(node) if node.is_a?(Array)}
  end

  def range_in_scope!(exp, from, to)
    scope = exp[from..to]
    (to-from).times{ exp.delete_at(from+1)}
    exp[from] = scope
    exp
  end
  
  def optimize_neibours(expression)
    optimize_operations!(expression, MINUS, PLUS)
    optimize_operations!(expression, DIV, MULT)
  end

  def optimize_operations!(exp, from_op, to_op)
    i = 0
    exp.each{|node| optimize_operations!(node, from_op, to_op) if node.is_a?(Array)}
    while i < exp.size
      if exp[i] == from_op  && exp[i+2] == from_op
        operations = count_operations(exp, i, from_op)
        exp = replace_scope(exp, i, from_op, to_op, operations)
        optimize_operations!(exp, from_op, to_op)
        break
      end
      i += 1
    end
    exp
  end

  def replace_scope(exp, i, from, to, operations)
    scope = exp[i+1..i+operations*2-1]
    scope.map! {|x| x == from ? to : x }
    exp[i+1] = scope
    ((operations-1)*2).times { exp.delete_at(i+2) }
    exp
  end

  def count_operations(exp, i, op)
    counter = 0
    while exp[i] == op
      counter += 1
      i += 2
    end
    counter
  end

  def to_struct(expression)
    result = expression.dup

    node_to_struct = ->(node){
      {
        :type => type_of_node(node),
        :value => node,
        :weight => weight_of(node),
        :locked => false
      }
    }

    array_to_struct = ->(exp){
      exp.each_with_index{|node, i|
        if node.is_a?(Array) 
          array_to_struct[node]
        else
          node = node_to_struct[node]
          exp[i] = node
        end
      }
    }

    array_to_struct[result]
    result
  end

  # makes :type => :scope from []
  def rescope_struct(struct)
    struct.each_with_index{|node, i|
      if node.is_a?(Array)
        rescope_struct(node)
        struct[i] = {
          :value => node,
          :type => :scope,
          :weight => 0,
          :locked => true
        }
      end
    }
  end

  def define_first_state(struct)
    struct.each_with_index{|node, i|
      if node[:type] == :scope
        define_first_state(node[:value])
      elsif OPERATIONS.include?(node[:type])
        node[:locked] = struct[i-1][:locked] || struct[i+1][:locked]
      else
      end
    }
  end

  def refresh_state(struct)
    struct.flatten.each{|node| 
      if [:complex, :param].include?(node[:type])
        node[:locked] = false
      elsif node[:type] == :scope
        refresh_state(node[:value])
      end
    }
  end

  def build_yarus(struct)
    p struct
    struct.each_with_index{|node,i|
      if node[:type] == :scope
        build_yarus(node[:value])
      elsif OPERATIONS.include?(node[:type]) && !node[:locked]
        unless struct[i-1][:used] || struct[i+1][:used]
          struct[i] = {
            :value => node[:value],
            :weight => node[:weight],
            :type => :complex,
            :left => struct[i-1].dup,
            :right => struct[i+1].dup,
            :used => true
          } 
          struct.delete_at(i+1)
          struct.delete_at(i-1)
        end
      end
    }
  end

  def free_scopes(struct)
    p struct
    struct.each_with_index{|node,i|
      if node[:type] == :scope
        if node[:value].size == 1
          struct[i] = node[:value].first
        else
          free_scopes(node[:value])
        end
      end
    }
  end

  def refresh_use(struct)
    struct.flatten.each{|node| 
      node[:used] = false
      refresh_use(node[:value]) if node[:type] == :scope
    }
  end

  def numerate_tree(tree)
    i = 1
    numerate = ->(struct){
      #puts "STRUCT"
      #puts struct
      #puts struct.class
      struct[:num] = i
      i+=1
      numerate[struct[:left]] if struct[:left]
      numerate[struct[:right]] if struct[:right]
    }
    numerate[tree.first]
  end

  def deepness_for_tree(tree)
    deep = ->(struct, d){
      struct[:deepness] = d
      deep[struct[:left], d+1] if struct[:left]
      deep[struct[:right], d+1] if struct[:right]
    }
    deep[tree.first, 1]
  end

  def build_tree(struct)
    while struct.size != 1
      p struct
      build_yarus(struct)
      free_scopes(struct)
      refresh_use(struct)
      refresh_state(struct)
      define_first_state(struct)
    end
  end
end
