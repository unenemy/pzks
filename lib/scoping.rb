class Scoping
  class << self
    include Settings
    def init(exp)
      p exp
    end

    # makes :type => :scope from []
    def rescope_struct(struct, main)
      struct.each_with_index{|node, i|
        if node.is_a?(Array)
          rescope_struct(node, main)
          struct[i] = {
            :value => node,
            :type => :scope,
            :weight => 0,
            :locked => true,
            :main => main
          }
        end
      }
    end

    def to_struct(expression)
      node_to_struct = ->(node){
        {
          :type => type_of_node(node),
          :value => node,
          :weight => weight_of(node),
          :locked => false,
          :main => expression
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

      array_to_struct[expression]
      expression
    end

    def show_struct(expression)
      fake = Marshal.load(Marshal.dump(expression))
      min = ->(exp){
        exp.each do |node|
          node[:main] = node[:main].object_id
          if node[:type] == :scope
            min[node[:value]]
          end
        end
      }
      min[fake]
    end

    def unaring(exp)
      if scope_soft?(exp)
        unar_scope(exp) 
      else
        hard_scope(exp)
      end

      exp.each do |node|
        unaring(node[:value]) if node[:type] == :scope
      end
    end

    def unar_scope(scope)
      scope.each_with_index do |node, i|
        if [:param, :scope].include?(node[:type])
          unar = i>0 ? scope[i-1][:value] : "+"
          node[:unar] = unar
        end
      end
      scope.each_with_index do |node, i|
        if [:minus, :plus].include?(node[:type])
          scope.delete_at(i)
        end
      end
    end

    def hard_scope(scope)
      scope.each_with_index do |node, i|
        if [:param, :scope].include?(node[:type])
          unar = i>0 ? scope[i-1][:value] : "*"
          node[:hard] = unar
        end
      end
      scope.each_with_index do |node, i|
        if [:mult, :div].include?(node[:type])
          scope.delete_at(i)
        end
      end
    end

    def scope_soft?(scope)
      scope.any?{|x| [:plus, :minus].include?(x[:type])}
    end
    
    def out_lists(exp)
      exp.each do |node|
        node[:out] = [] if node[:unar] || node[:type] == :scope
        if node[:type] == :scope
          out_lists(node[:value])
          if soft_node?(node)
            node[:out] << scope_to_dirty_s(node)
          else
            node[:value].each{|x|
              if x[:type] == :scope
                node[:out] << scope_to_dirty_s(x)
              else
                node[:out] << "#{x[:hard]||'*'}#{x[:value]}" if x[:value] != "1"
              end
            }
          end
        else
          node[:out] << "#{node[:hard]||'*'}#{node[:value]}" if node[:unar] && node[:value] != "1"
        end
      end
    end

    def soft_node?(node)
      node[:type] == :param || node[:value].any?{|x| x[:unar]}
    end

    def scope_to_dirty_s(scope)
      str = ""
      tos = ->(node){
        str << (node[:unar] || node[:hard])
        if node[:type] == :scope
          str << "("
          node[:value].each{|x| tos[x]}
          str << ")"
        else
          str << node[:value]
        end
      }
      tos[scope]
      #puts "FOR scope #{scope} was generated string"
      #p str
      str
    end

    def all_may_outed_scopes(expression)
      scopes = [expression]
      collect_scopes = ->(expression){
        expression.each do |node|
          if node[:type] == :scope
            collect_scopes[node[:value]]
            scopes << node[:value] if soft_node?(node)
          end
        end
      }
      collect_scopes[expression]
      scopes.map{|x| {:scope => x, :exp => scope_to_dirty_s({:type => :scope, :unar => "+", :value => x}), :to_out => can_be_outed(x)}}
    end

    def can_be_outed(expression)
      expression.size > 1 ? expression.map{|x| x[:out]}.permutation(2).to_a.map{|x| x.first & x.last}.flatten.uniq : []
    end

    def out_them_all(exp)
      outed_list = []
      collect_outed = ->(expression){
        out_lists(expression)
        out_scopes = all_may_outed_scopes(expression).select{|x| x[:to_out].any?}
        puts "OUT"
        p out_scopes.size
        out_scopes.each_with_index do |scope, i|
          scope[:to_out].each_with_index do |to_out, j|
            copy_out_scope = Marshal.load(Marshal.dump(scope))
            outed = do_out(copy_out_scope[:scope], to_out)
            collect_outed[outed]
            outed_list << outed
          end
        end
      }
      collect_outed[exp]
      puts "sooo"
      outed_list.each{|x| away_empty_scopes(x)}
      p outed_list.map{|x| expression_clear_str(x)}
    end

    def do_out(scope, what)
      puts "TTROLOLO"
      #puts scope
      puts what
      from = scope.select{|x| x[:out].include?(what)}
      from.each{|x| scope.delete(x)}
      puts "FROM"
      p from
      bitch = if from.first[:type] == :scope
                from.first[:value].find{ |x| 
                  #puts "X"
                  #puts x
                  str = x[:type] == :scope ? scope_to_dirty_s(x) : "#{x[:hard]}#{x[:value]}"
                  p str
                  str == what
                }
              else
                from.first
              end
      bitch_2 = Marshal.load(Marshal.dump(bitch))
      bitch_2[:hard] = what.first
      bitch_2.delete(:unar)
      from.each{|x| exclude_from_node(x,what)}
      puts "The bitch is"
      puts bitch[:value]
      scope << {:type => :scope, :value => [{:type => :scope, :value => from, :hard => "*", :main => bitch[:main]}, bitch_2], :unar => "+"}
      puts "GOT"
      p scope_to_dirty_s({:type => :scope, :value => bitch[:main], :unar => "+"})
      bitch[:main]
    end

    def exclude_from_node(node, what)
      if node[:type] == :scope
        if node[:value].size > 1
          index_to_delete = node[:value].index(node[:value].find{|x| 
            str = x[:type] == :scope ? scope_to_dirty_s(x) : "#{x[:hard]}#{x[:value]}"
            str == what
          })
          if index_to_delete == 0 and node[:value][1][:hard] == "/"
            node[:value][index_to_delete][:value] = "1"
          else
            node[:value].delete_at(index_to_delete)
          end
        else
          node[:value].first[:value] = "1"
        end
      else
        node[:value] = "1"
      end
    end

    def expression_clear_str(expression)
      str = ""
      exp_to_str = ->(exp){
        exp.each_with_index do |node, i|
          str << node[:unar] if node[:unar] && (i!=0 || node[:unar] == "-")
          str << node[:hard] if i!=0 && node[:hard]
          if node[:type] == :scope
            str << "("
            exp_to_str[node[:value]]
            str << ")"
          else
            str << node[:value]
          end
        end
      }
      exp_to_str[expression]
      str
    end

    def away_empty_scopes(expression)
      expression.each_with_index do |node, i|
        if node[:type] == :scope
          away_empty_scopes(node[:value])
          if node[:value].size == 1

            node[:value].first[:unar] = node[:unar]
            node[:value].first[:hard] = node[:hard]
            node[:value].first.delete(:hard) if node[:value].first[:type] != :scope
            expression[i] = node[:value].first
          end
        end
      end
    end

  end
end
