class HomeController < ApplicationController
  def index
    @current_page = "index"
    @expression = params[:expression]
    if @expression
      automat = Automat.new(@expression << "\n")
      @okay, @message, @result = automat.parse
      @parsed = Marshal.load(Marshal.dump(@result))
      return unless @okay
      processor = Processor.new
      processor.normalize_scopes!(@result)
      processor.zero_if_operation_in_scope(@result)
      @parsed = Marshal.load(Marshal.dump(@result))
      processor.scope_hard(@result)
      processor.normalize_scopes!(@result)
      processor.optimize_neibours(@result)
      @optimized = Marshal.load(Marshal.dump(@result))
      @tree = processor.to_struct(@result)
      processor.rescope_struct(@tree)
      processor.define_first_state(@tree)
      @pre_tree = Marshal.load(Marshal.dump(@tree))
      processor.build_tree(@tree)
      processor.numerate_tree(@tree)
      processor.deepness_for_tree(@tree)
      puts "TREEEEEE"
      p @tree
      Grapher.write_graph(@tree.first, "graphe")
    end
  end

  def com
    @current_page = "com"
    @expression = params[:expression]
    @commutations = []
    if @expression
      automat = Automat.new(@expression << "\n")
      @okay, @message, @result = automat.parse
      @parsed = Marshal.load(Marshal.dump(@result))
      return unless @okay
      processor = Processor.new
      processor.normalize_scopes!(@result)
      processor.zero_if_operation_in_scope(@result)
      @parsed = Marshal.load(Marshal.dump(@result))
      processor.scope_hard(@result)
      processor.normalize_scopes!(@result)
      #processor.optimize_neibours(@result)
      @optimized = Marshal.load(Marshal.dump(@result))
      @tree = processor.to_struct(@result)
      processor.rescope_struct(@tree)
      processor.count_scopes_weight(@tree)
      processor.include_unaring(@tree)
      p processor.build_node_string(@tree)
      processor.sort_by_weight(@tree)
      @sorted = [processor.expression_clear_str(@tree)]
      puts @tree
      puts @tree.size
      p @tree.map{|x| x[:weight]}
      p processor.build_node_string(@tree)
      @commutations = processor.all_commutations(@tree).uniq.map{|x| x.first == "+" ? x[1..-1] : x}
      @commutations = @sorted if @commutations.empty?
    end
  end

  def scopes
    @current_page = "scopes"
    @expression = params[:expression]
    @scopes = []
    @tree = []
    if @expression
      automat = Automat.new(@expression << "\n")
      @okay, @message, @result = automat.parse
      @parsed = Marshal.load(Marshal.dump(@result))
      return unless @okay
      processor = Processor.new
      processor.normalize_scopes!(@result)
      processor.zero_if_operation_in_scope(@result)
      @parsed = Marshal.load(Marshal.dump(@result))
      processor.scope_hard(@result)
      processor.normalize_scopes!(@result)
      #processor.optimize_neibours(@result)
      @optimized = Marshal.load(Marshal.dump(@result))
      @tree = Scoping.to_struct(@result)
      Scoping.rescope_struct(@tree, @tree)
      Scoping.unaring(@tree)
      Scoping.out_lists(@tree)
      Scoping.out_them_all(@tree)
      p @tree.map{|x| x[:out]}
      #processor.rescope_struct(@tree)
      #processor.init_solid(@tree)
      #processor.reset_out_lists_for_nodes(@tree)
      #processor.count_scopes_weight(@tree)
      #processor.include_unaring(@tree)
      #puts @tree
      #puts processor.build_node_string(@tree)
      #p @tree.size
      return
      processor.sort_by_weight(@tree)
      @sorted = [processor.build_node_string(@tree)]
      puts @tree
      puts @tree.size
      p @tree.map{|x| x[:weight]}
      p processor.build_node_string(@tree)
      @commutations = processor.all_commutations(@tree).uniq.map{|x| x.first == "+" ? x[1..-1] : x}
      @commutations = @sorted if @commutations.empty?
    end
  end

  def pipeline
    @current_page = "pipeline"
    @expression = params[:expression]
    copied_exp = Marshal.load(Marshal.dump(@expression))
    @layers = params[:layers].to_i ||= 3
    @scopes = []
    @tree = []
    @all = []
    if @expression
      automat = Automat.new(@expression << "\n")
      @okay, @message, @result = automat.parse
      @parsed = Marshal.load(Marshal.dump(@result))
      return unless @okay
      processor = Processor.new
      processor.normalize_scopes!(@result)
      processor.zero_if_operation_in_scope(@result)
      @parsed = Marshal.load(Marshal.dump(@result))
      processor.scope_hard(@result)
      processor.normalize_scopes!(@result)
      #processor.optimize_neibours(@result)
      @optimized = Marshal.load(Marshal.dump(@result))
      @tree = Scoping.to_struct(@result)
      Scoping.rescope_struct(@tree, @tree)
      Scoping.unaring(@tree)
      Scoping.out_lists(@tree)
      outed = Scoping.out_them_all(@tree)

      automat = Automat.new(@expression << "\n")
      @okay, @message, @result = automat.parse
      @parsed = Marshal.load(Marshal.dump(@result))
      return unless @okay
      processor = Processor.new
      processor.normalize_scopes!(@result)
      processor.zero_if_operation_in_scope(@result)
      @parsed = Marshal.load(Marshal.dump(@result))
      processor.scope_hard(@result)
      processor.normalize_scopes!(@result)
      #processor.optimize_neibours(@result)
      @optimized = Marshal.load(Marshal.dump(@result))
      @tree = processor.to_struct(@result)
      processor.rescope_struct(@tree)
      processor.count_scopes_weight(@tree)
      processor.include_unaring(@tree)
      p processor.build_node_string(@tree)
      processor.sort_by_weight(@tree)
      @sorted = [copied_exp]
      puts @tree
      puts @tree.size
      p @tree.map{|x| x[:weight]}
      p processor.build_node_string(@tree)
      puts "!SORDED: #{@sorted}"
      @commutations = processor.all_commutations(@tree).uniq.map{|x| x.first == "+" ? x[1..-1] : x}
      puts "!!Comutations are: #{@commutations}"
      @commutations = @sorted if @commutations.empty?
      puts "!!Comutations are: #{@commutations}"

      outed += @commutations

      #outed << @expression
      outed.select{|x| !x.empty?}.each_with_index do |exp, i|
        automat = Automat.new(exp << "\n")
        @okay, @message, @result = automat.parse
        @parsed = Marshal.load(Marshal.dump(@result))
        return unless @okay
        processor = Processor.new
        processor.normalize_scopes!(@result)
        processor.zero_if_operation_in_scope(@result)
        @parsed = Marshal.load(Marshal.dump(@result))
        processor.scope_hard(@result)
        processor.normalize_scopes!(@result)
        processor.optimize_neibours(@result)
        @optimized = Marshal.load(Marshal.dump(@result))
        @tree = processor.to_struct(@result)
        processor.rescope_struct(@tree)
        processor.define_first_state(@tree)
        @pre_tree = Marshal.load(Marshal.dump(@tree))
        processor.build_tree(@tree)
        processor.numerate_tree(@tree)
        processor.deepness_for_tree(@tree)
        pipeline = Pipeline.new(@layers,@tree)
        @all << {:pipeline => pipeline.load, :exp => i.to_s, :expression => exp}
        Grapher.write_graph(@tree.first, i.to_s)
      end
      @all.sort!{|a,b| a[:pipeline][:sum_weight]<=>b[:pipeline][:sum_weight]}
    end
  end

   def pipeline2
    @current_page = "pipeline"
    @expression = params[:expression]
    @layers = params[:layers].to_i ||= 3
    @scopes = []
    @tree = []
    @result = []
    if @expression
      automat = Automat.new(@expression << "\n")
      @okay, @message, @result = automat.parse
      @parsed = Marshal.load(Marshal.dump(@result))
      return unless @okay
      processor = Processor.new
      processor.normalize_scopes!(@result)
      processor.zero_if_operation_in_scope(@result)
      @parsed = Marshal.load(Marshal.dump(@result))
      processor.scope_hard(@result)
      processor.normalize_scopes!(@result)
      processor.optimize_neibours(@result)
      @optimized = Marshal.load(Marshal.dump(@result))
      @tree = processor.to_struct(@result)
      processor.rescope_struct(@tree)
      processor.define_first_state(@tree)
      @pre_tree = Marshal.load(Marshal.dump(@tree))
      processor.build_tree(@tree)
      processor.numerate_tree(@tree)
      processor.deepness_for_tree(@tree)
      pipeline = Pipeline.new(@layers,@tree)
      @result = pipeline.load
      puts "result"
      p @result
      puts "TREEEEEE"
      p @tree
      Grapher.write_graph(@tree.first, "graphe")
    end
  end
end
