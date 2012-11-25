class Automat
  attr_accessor :str
  attr_reader :result

  TABLE = {
    :num   => {
      :begin => [:num, :add],
      :start => [:num, :add],
      :num   => [:num, :add],
      :point => [:fnum, :add],
      :fnum  => [:fnum, :add],
      :char  => [:char, :add],
      :op    => [:start, :next],
      :open  => [:start, :next],
      :close => [:final, "Close cant be followed with a number!"]
    },
    :point => {
      :begin => [:final, "Cant start any node with point"],
      :start => [:final, "Cant start any node with point"],
      :num   => [:point, :add],
      :point => [:final, "Cant be 2 points one by one!"],
      :fnum  => [:final, "Cant be 2 points in float number!"],
      :char  => [:final, "Cant be a point in variable"],
      :op    => [:final, "Cant be a point after operation"],
      :open  => [:final, "Cant be a point after open"],
      :close => [:final, "Cant be a point after close"]
    },
    :char    => {
      :begin => [:char, :add],
      :start => [:char, :add],
      :num   => [:final, "Cant be a character in integer value"],
      :point => [:final, "Cant be a char after point"],
      :fnum  => [:final, "Cant be a char in the float value"],
      :char  => [:char, :add],
      :op    => [:start, :next],
      :open  => [:start, :next],
      :close => [:final, "Cant be a char after close"]
    },
    :pm    => {
      :begin => [:op, :add],
      :start => [:op, :add],
      :num   => [:start, :next],
      :point => [:final, "Cant be +/- after point"],
      :fnum  => [:start, :next],
      :char  => [:start, :next],
      :op    => [:final, "Cant be +/- after operations"],
      :open  => [:start, :next],
      :close => [:start, :next]
    },
    :dm    => {
      :begin => [:final, "Cant start with * or / operations"],
      :start => [:op, :add],
      :num   => [:start, :next],
      :point => [:final, "Cant be * or / after point!"],
      :fnum  => [:start, :next],
      :char  => [:start, :next],
      :op    => [:final, "Cant be * or / after any operation!"],
      :open  => [:final, "Cant be * or / after open!"],
      :close => [:start, :next]
    },
    :open  => {
      :begin => [:open, :addo],
      :start => [:open, :addo],
      :num   => [:final, "Cant be open after a number!"],
      :point => [:final, "Cant be open after point"],
      :fnum  => [:final, "Cant be open after float number"],
      :char  => [:final, "cant be open after variable"],
      :op    => [:start, :next],
      :open  => [:start, :next],
      :close => [:final, "Cant be open after close"]
    },
    :close => {
      :begin => [:final, "Cant be started with close!"],
      :start => [:close, :addc],
      :num   => [:start, :next],
      :point => [:final, "Cant be close after point"],
      :fnum  => [:start, :next],
      :char  => [:start, :next],
      :op    => [:final, "Cant be close after operation"],
      :open  => [:final, "Cant be empty scopes"],
      :close => [:start, :next]
    },
    :eos   => {
      :begin => [:final, "Stupid beginning of expression"],
      :start => [:final, :cc],
      :num   => [:final, :cc],
      :point => [:final, "Cant be end of line after point"],
      :fnum  => [:final, :cc],
      :char  => [:final, :cc],
      :op    => [:final, "Cant be end of line after operation"],
      :open  => [:final, "Cant be end of line after open"],
      :close => [:final, :cc]
    }
  }

  def initialize(str)
    @str = str.split("")
  end

  def type(char)
    case char
      when /[a-zA-Z]/ then :char
      when /[+-]/ then :pm
      when /[\/\*]/ then :dm
      when /[0-9]/ then :num
      when '(' then :open
      when ')' then :close
      when '.' then :point
      when ' ' then :space
      when "\n" then :eos
      else :other
    end
  end

  def parse
    @state = :begin
    @result = []
    @scopes_stack = [@result]
    @working_scope = @result
    @pointer = 0
    @node = ""
    @scopes = 0
    action = nil
    while @state != :final && action != :cc
      char = @str[@pointer]
      if type(char) == :other
        @error_message = "ERROR - WRONG CHARACHTER"
        break
      end
      @state, action = TABLE[type(char)][@state]
      #puts "STATE: #@state"
      #puts "ACTION: #{action}"
      if action.is_a? String
        @error_message = action
      else
        self.send(action)
      end
      @pointer += 1
      return error_checking unless error_checking[0]
    end
    p @result
    return error_checking unless error_checking[0]
    [true, "EVERYTHING IS OKAY", @result]
  end
  
  def insert_node
    @working_scope << @node unless @node.empty?
    @node = ""
  end

  def add
    @node << @str[@pointer]
  end

  def next
    insert_node
    @pointer -= 1
  end

  def addc
    @scopes -= 1
    @error_message = "ERROR! too much closings" and return if @scopes < 0
    insert_node
    @scopes_stack.delete_at(-1)
    @working_scope = @scopes_stack[-1]
  end

  def addo
    @scopes += 1
    newopen = []
    @working_scope << newopen
    @working_scope = newopen
    @scopes_stack << newopen
  end

  def cc
    puts "checking scopes"
    insert_node
    puts "SCOPES: #@scopes"
    @error_message = "ERROR! WRONG open-close!" and return if @scopes > 0
    puts "EVERYTHING is OKAY!"
  end

  def error_checking
    if @error_message
      puts @error_message
      #puts "PARSED:"
      #p @result
      #puts "FAILED:"
      #p @node
      puts "FAILED at #{@str[0..@pointer-1]}"
      puts @str[0..@pointer-1].flatten.join
      puts "Index: #{@pointer-1}"
      return [false, @error_message,@str[0..@pointer-1].flatten.join]
    else
      return [true]
    end
  end
end
