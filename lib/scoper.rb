module Scoper
  include Settings
  def init_solid(exp)
    exp.each do |node|
      puts node[:type]
      unless [:plus, :minus, :mult, :div].include?(node[:type])
        node[:solid] = node[:type] == :scope ? !node[:value].any?{|x| [:plus, :minus].include?(x[:type])} : true
        if node[:type] == :scope
          #p node
          init_solid(node[:value]) #unless node[:solid]
        end
      end
    end
  end

  def reset_out_lists_for_nodes(exp)
    exp.each do |node|
      if [:param,:scope].include?(node[:type])
        node[:out_list] = node[:solid] ? out_list(node[:value]) : ["*#{build_node_string([node])}"]
      end
    end
  end

  def out_list(value)
    if value.is_a?(Array)
      list = []
      value.each_with_index do |node, i|
        if [:param, :scope].include?(node[:type])
          op = i == 0 ? "*" : value[i-1][:value]
          list << [op, node[:value].is_a?(Array) ? "(#{build_node_string(node[:value])})" : [node[:value]]].join
        end
      end
    else
      list = ["*#{value}"]
    end
    list
  end

end
