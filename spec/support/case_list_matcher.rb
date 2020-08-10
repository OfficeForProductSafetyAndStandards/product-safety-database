RSpec::Matchers.define :have_listed_case do |pretty_id|
  match do |element|
    element.has_selector?(".psd-case-card", text: pretty_id)
  end
end
