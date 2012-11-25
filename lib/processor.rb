class Processor
  PLUS = "+"
  MINUS = "-"
  DIV = "/"
  MULT = "*"
  HARD = [MULT, DIV]
  SOFT = [PLUS, MINUS]

  def scope_hard(expression)
    scope = ->(exp){
      i = 0
      while i < exp.size
        puts "scoping hard"
        puts i
        if HARD.include?(exp[i])
          j = i
          while HARD.include?(exp[j])
            j+=2
          end
          puts "FROM #{i-1} to #{j-1}"
          puts "FROM #{exp[i-1]} to #{exp[j-1]}"
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
    optimize_minus!(expression)
  end

  def optimize_minus!(exp)
    i = 0
    while i < exp.size
      puts i
      if exp[i] == "-" && exp[i+2] == "-"
        operations = count_operations(exp, i, "-")
        puts "OP count = #{operations}"
        exp = replace_scope(exp, i, "-", "+", operations)
        optimize_minus!(exp)
        break
      end
      i += 1
    end
    p exp
    exp
  end

  def replace_scope(exp, i, from, to, operations)
    puts "EXPRESSION #{exp}"
    puts "I = #{i}"
    scope = exp[i+1..i+operations*2-1]
    scope.map! {|x| x == from ? to : x }
    puts "SCOPE #{scope}"
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

  def find_indexes(scope, by)

  end
end
