class ErrorSummaryUpperCasePresenter
  def initialize(error_messages)
    @error_messages = [error_messages]
  end

  def formatted_error_messages
    @error_messages = @error_messages.each.map { |y| y.to_a.map { |x| [x[0], x[1].join] } }
    @error_messages = @error_messages[0] + @error_messages[1] if @error_messages.length == 2
    @error_messages[0]
  end
end
