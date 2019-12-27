RSpec::Matchers.define :have_error_messages do
  match do |element|
    element.has_css?(".govuk-error-message")
  end
end
