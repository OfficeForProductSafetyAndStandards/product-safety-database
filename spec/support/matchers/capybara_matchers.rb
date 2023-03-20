module PageMatchers
  # Matcher for items within the [Summary list](https://design-system.service.gov.uk/components/summary-list/) component.
  #
  # Note: by default this expects definition list (`<dd>` and `<dt>`) markup, as recommended by the
  # GOV.UK Design System. However some of our existing summary lists use table markup (`<th>` and `<td>`),
  # which can be matched using the `table: true` param.
  class HaveSummaryItem
    def initialize(key:, value:, table: false)
      @key = key
      @value = value
      @table = table
    end

    def matches?(page)
      key_element = @table ? "th" : "dt"
      value_element = @table ? "td" : "dd"

      page.find(key_element, text: @key, exact_text: true).sibling(value_element, text: @value, exact_text: true)
    end
  end

  # TODO: remove once all summary lists have been switched to definition list markup
  def have_summary_table_item(key:, value:)
    Rails.logger.warn "#have_summary_table_item is deprecated: use #have_summary_item instead"
    HaveSummaryItem.new(key:, value:, table: true)
  end

  def have_summary_item(key:, value:)
    HaveSummaryItem.new(key:, value:)
  end

  def have_summary_error(text)
    have_css(".govuk-error-summary__list", text:)
  end

  def have_h1(text)
    have_selector("h1", text:)
  end

  def have_h2(text)
    have_selector("h2", text:)
  end
end
