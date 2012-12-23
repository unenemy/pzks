module Comut

  def include_unaring(tree)
    tree.each_with_index do |node, i|
      if [:param, :scope].include?(node[:type])
        unar = i>0 ? tree[i-1][:value] : "+"
        node[:unar] = unar
      end
    end
    tree.each_with_index do |node, i|
      if [:minus, :plus].include?(node[:type])
        tree.delete_at(i)
      end
    end
    p tree
  end

  def count_scopes_weight(tree)
    tree.each{|node| count_scope_weight(node) if node[:type] == :scope}
  end

  def count_scope_weight(scope)
    scope[:weight] = scope[:value].sum{|node| node[:type] == :scope ? count_scope_weight(node) : node[:weight]}
    scope[:weight]
  end

  def sort_by_weight(tree)
    tree.sort!{|a,b| a[:weight]<=>b[:weight]}
  end

  def build_node_string(scope)
    @built = ""
    build_string(scope)
  end

  def build_string(scope)
    @built ||= ""
    scope.each do |node|
      @built << (node[:unar] || "")
      if node[:type] == :scope
        @built << "("
        build_string(node[:value])
        @built << ")"
      else
        @built << node[:value]
      end
    end
    @built
  end

  def all_commutations(scope)
    @comutated = []
    comutate(scope, 1)
  end

  def comutate(scope, min)
    weights = scope.map{|x| x[:weight]}.uniq.map{|x| { :start => scope.index{|a| a[:weight] == x}, :end => scope.rindex{|a| a[:weight] == x}, :weight => x}}.select{|x| x[:weight] >= min}
    p weights
    weights.each do |w|
      if (w[:end]-w[:start] > 0) && (w[:weight] > 0)
        scope[w[:start]..w[:end]].permutation{|x|
          s = Marshal.load(Marshal.dump(scope))
          s[w[:start]..w[:end]] = x
          @comutated << build_node_string(s)
          comutate(s, w[:weight] + 1)
        }
      end
    end
    @comutated
  end
end
