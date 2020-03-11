module UIMatchers
  RSpec::Matchers.define :show_case_card_with do |expected|
    match do |page|
      page.all(".govuk-grid-row.psd-case-card .govuk-grid-column-one-half span.govuk-caption-m", expected).any?
    end

    failure_message do |actual|
      other_cards = actual.all(".govuk-grid-row.psd-case-card .govuk-grid-column-one-half span.govuk-caption-m").map(&:text)
      message = "Expected to find the following element '.govuk-grid-row.psd-case-card .govuk-grid-column-one-half span.govuk-caption-m' "
      if other_cards.any?
        message << "Also found other cards: #{other_cards.to_sentence(last_word_connector: ' and ')}"
      else
        message << "but nothing was found."
      end
      message
    end

    failure_message_when_negated do
      "Expected to not find the following element '.govuk-grid-row.psd-case-card .govuk-grid-column-one-half span.govuk-caption-m' with #{expected.inspect}"
    end
  end
end
