RSpec::Matchers.define :have_listed_case do |pretty_id|
  match do |element|
    element.has_selector?("td.govuk-table__cell", text: pretty_id)
  end
end

RSpec::Matchers.define :list_cases_in_order do |expected_cases_ids|
  match do |element|
    pattern = /\d{4}-\d{4}/
    page_case_ids = element.all("td.govuk-table__cell", text: pattern).map { |e| e.text.strip }
    page_case_ids == expected_cases_ids
  end
end
