class HomeController < ApplicationController
  def index
    @expression = params[:expression]
    if @expression
      automat = Automat.new(@expression << "\n")
      @okay, @message, @result = automat.parse
      return unless @okay
      processor = Processor.new
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
      Grapher.write_graph(@tree.first, "graphe")
    end
  end
end
