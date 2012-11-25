class HomeController < ApplicationController
  def index
    @expression = params[:expression]
    if @expression
      automat = Automat.new(@expression << "\n")
      @okay, @message, @result = automat.parse
      return unless @okay
      @parsed = Marshal.load(Marshal.dump(@result))
      processor = Processor.new
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
      #g = GraphV
      #iz.new( :G, :type => :digraph)

      #hello = g.add_nodes("Hello")
      #world = g.add_nodes("World")

      #g.add_edges(hello, world)
      #g.output(:png => "#{Rails.root}/public/images/graph.png")
    end
  end
end
