RSpec::Matchers.define :have_error_messages do
  match do |element|
    element.has_css?(".govuk-error-message")
  end
end

RSpec::Matchers.define :have_error_summary do |messages|
  match do |element|
    element.has_css?(".govuk-error-summary") &&
      Array(messages).all? { |message| element.has_selector?("a", text: message) }
  end
end
