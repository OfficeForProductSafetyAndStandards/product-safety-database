class ErrorSummaryUpperCasePresenter
  def initialize(error_messages)
    @error_messages = [error_messages, @errors.to_h]
  end

  def formatted_error_messages
    store = []

    @error_messages.each do |attribute|
      attribute.each do |arr|
        arr[1].each do |message|
          store << [arr[0], message]
        end
      end
    end

    if store.map { |x| x[1] }.include? "Select yes if you know when the accident happened"
      if store.map { |x| x[1] }.include? "Select the product involved in the accident"
        @check = true
        index = store.map { |x| x[1] }.find_index("Select the product involved in the accident")
        error = store[index]
        store.delete_at(index)
        store.unshift(error)
      end
      index = store.map { |x| x[1] }.find_index("Select yes if you know when the accident happened")
      error = store[index]
      store.delete_at(index)
      store.unshift(error)
    end

    if (store.map { |x| x[1] }.include? "Select the product involved in the accident") && !@check
      index = store.map { |x| x[1] }.find_index("Select the product involved in the accident")
      error = store[index]
      store.delete_at(index)
      store.unshift(error)
    end

    @error_messages = store
    @error_messages
  end
end
