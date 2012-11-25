class Processor
  include Settings
  def scope_hard(expression)
    scope = ->(exp){
      i = 0
      while i < exp.size
        #puts "scoping hard"
        #puts i
        if HARD.include?(exp[i])
          j = i
          while HARD.include?(exp[j])
            j+=2
          end
          #puts "FROM #{i-1} to #{j-1}"
          #puts "FROM #{exp[i-1]} to #{exp[j-1]}"
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
      #puts i
      if exp[i] == from_op  && exp[i+2] == from_op
        operations = count_operations(exp, i, from_op)
        #puts "OP count = #{operations}"
        exp = replace_scope(exp, i, from_op, to_op, operations)
        optimize_operations!(exp, from_op, to_op)
        break
      end
      i += 1
    end
    exp
  end

  def replace_scope(exp, i, from, to, operations)
    #puts "EXPRESSION #{exp}"
    #puts "I = #{i}"
    scope = exp[i+1..i+operations*2-1]
    scope.map! {|x| x == from ? to : x }
    #puts "SCOPE #{scope}"
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
    puts "EXPRESSION #{expression.object_id}"
    result = expression.dup
    puts "RESULT #{result.object_id}"
    #puts result.class
    #p result

    node_to_struct = ->(node){
      {
        :type => type_of_node(node),
        :value => node,
        :weight => weight_of(node),
        :locked => false
      }
    }

    array_to_struct = ->(exp){
      #puts exp
      exp.each_with_index{|node, i|
        if node.is_a?(Array) 
          array_to_struct[node]
        else
          node = node_to_struct[node]
          #puts node
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
