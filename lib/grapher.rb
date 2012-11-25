class Grapher
  class << self
    def write_graph(tree, filename)
      g = GraphViz.new( :G, :type => :digraph)

      add_edge = ->(struct, parent){
        left = g.add_nodes(struct[:left][:value].dup << struct[:left].object_id.to_s, :label => struct[:left][:value])
        right = g.add_nodes(struct[:right][:value].dup << struct[:right].object_id.to_s, :label => struct[:right][:value])
        g.add_edges(left, parent)
        g.add_edges(right, parent)
        add_edge[struct[:left], left] if struct[:left][:type] == :complex
        add_edge[struct[:right], right] if struct[:right][:type] == :complex
      }
      add_edge[tree, g.add_nodes(tree[:value].dup << tree.object_id.to_s, :label => tree[:value])]

      g.output(:png => "#{Rails.root}/app/assets/images/#{filename}.png")
    end
  end
end
