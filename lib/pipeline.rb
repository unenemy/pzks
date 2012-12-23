class Pipeline
  include Settings
  attr_reader :pipeline
  def initialize(layers, expression)
    @layers = layers
    @exp = expression
    @pipeline = []
    @queue = []
    @nodes = []
  end

  def load
    redo_params
    collect_nodes
    #puts "NODES: #{@nodes}"
    while !all_done?
      #puts "queue: #{@queue.map{|x| [x[:left][:value], x[:value], x[:right][:value]]}}"
      #puts "PIPELINE: #{@pipeline}"
      collect_queue
      load_node
    end
    @pipeline
    to_struct
  end

  def load_node
    @queue.sort{|a,b| a[:deepness]<=>b[:deepness]}
    if @queue.first
      @pipeline << @queue.first
      @queue.shift
    else
      @pipeline << {:empty => true, :value => "empty"}
    end
    @pipeline.last[:time] = 0
    @pipeline.last[:done] = true
    @pipeline.each{|x| x[:time]+=1}
  end

  def redo_params
    trick = ->(struct){
      struct[:done] = !["+","-","*","/"].include?(struct[:value])
      struct[:time] = @layers if struct[:done]
      trick[struct[:left]] if struct[:left]
      trick[struct[:right]] if struct[:right]
    }
    trick[@exp.first]
  end

  def collect_queue
    trick = ->(struct){
      @queue << struct if struct[:left][:done] && struct[:right][:done] && struct[:left][:time] >= @layers && struct[:right][:time] >= @layers
      trick[struct[:left]] if struct[:left] && !struct[:left][:done]
      trick[struct[:right]] if struct[:right] && !struct[:right][:done]
    }
    trick[@exp.first]
    @queue.uniq
    @queue = @queue - @pipeline
  end

  def collect_nodes
    collector = ->(struct){
      @nodes << struct
      collector[struct[:left]] if struct[:left]
      collector[struct[:left]] if struct[:rigth]
    }
    collector[@exp.first]
  end

  def all_done?
    @nodes.all?{|x| x[:done] == true}
  end

  def to_struct
    weight = weight_of(@nodes.max{|x| weight_of(x[:value])}[:value])
    result = []
    @pipeline.each_with_index do |line, i|
      @layers.times do |j|
        result[i+j] = [] unless result[i+j]
        result[i+j][j] = line
      end
    end
    result.each{|x| 
      @layers.times{|i|
        x[i] = {:type => :empty, :value => "empty"} unless x[i]
      }
    }
    {:layers => @layers, :pipeline => result, :weight => weight}
  end
end
