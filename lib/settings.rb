module Settings
  PLUS = "+"
  MINUS = "-"
  DIV = "/"
  MULT = "*"
  HARD = [MULT, DIV]
  SOFT = [PLUS, MINUS]
  OPERATIONS = [:plus,:minus,:div,:mult]

  def weight_of(operation)
    case operation
      when PLUS then 1
      when MINUS then 1
      when DIV then 3
      when MULT then 2
      else 0
    end
  end

  def type_of_node(node)
    case node
    when "+" then :plus
    when "-" then :minus
    when "/" then :div
    when "*" then :mult
    else :param
    end
  end
end
