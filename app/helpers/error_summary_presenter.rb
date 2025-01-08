class ErrorSummaryPresenter
  def initialize(error_messages)
    @error_messages = [error_messages]
  end

  def formatted_error_messages
    store = []
    @error_messages.each do |hash|
      hash.each do |key, arr|
        arr = arr.map { |x| [key, x] }
        store += arr
      end
    end
    @error_messages = store
  end
end
