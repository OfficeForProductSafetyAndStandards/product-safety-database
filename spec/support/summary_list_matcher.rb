RSpec::Matchers.define :summarise do |expected_key, expected_value|
  match do |actual|
    summary_list = Capybara.string(actual)
    summary_list.has_css?("dt.govuk-summary-list__key", text: expected_key) &&
      summary_list.has_css?("dd.govuk-summary-list__value", **expected_value)
  end
end
