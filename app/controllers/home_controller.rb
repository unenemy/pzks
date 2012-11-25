class HomeController < ApplicationController
  def index
    @expression = params[:expression]
    if @expression
      automat = Automat.new(@expression << "\n")
      @okay, @message, @result = automat.parse
      @parsed = @result.dup
      processor = Processor.new
      processor.scope_hard(@result)
      processor.normalize_scopes!(@result)
      processor.optimize_neibours(@result)
    end
  end
end
