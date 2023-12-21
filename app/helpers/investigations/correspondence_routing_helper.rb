module Investigations
  module CorrespondenceRoutingHelper
    def format_errors_for(user, errors_for_field)
      return base_errors if user.errors.include?(:base)
      return             if errors_for_field.empty?

      { text: errors_for_field.to_sentence(last_word_connector: " and ") }
    end

  private

    def base_errors
      { text: errors.full_messages_for(:base).to_sentence(last_word_connector: " and ") }
    end
  end
end
