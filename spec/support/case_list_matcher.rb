RSpec::Matchers.define :have_listed_case do |pretty_id|
  match do |element|
    element.has_selector?(".psd-case-card", text: pretty_id)
  end
end

RSpec::Matchers.define :list_cases_in_order do |expected_cases|
  match do |element|
    pattern = /(Allegation|Project|Enquiry): (\d{4}-\d{4})/
    page_case_ids = element.all(".psd-case-card span", text: pattern).map(&:text).map { |t| t.match(pattern).captures.last }
    page_case_ids == expected_cases.map(&:pretty_id)
  end
end
