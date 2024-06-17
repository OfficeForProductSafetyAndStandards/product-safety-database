# frozen_string_literal: true

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

    @error_messages = store
    @error_messages
  end

end
