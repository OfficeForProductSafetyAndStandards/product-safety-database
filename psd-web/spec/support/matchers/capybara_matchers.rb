module PageMatchers
  # Matcher for items within the [Summary list](https://design-system.service.gov.uk/components/summary-list/) component.
  #
  # Note: currently this expects table markup. However this should be updated to use
  # definition list (`<dd>` and `<dt>`) markup when the template is updated.
  class HaveSummaryItem
    def initialize(key:, value:)
      @key = key
      @value = value
    end

    def matches?(page)
      @page = page
      begin
        @key_element = @page.find("th", text: @key, exact_text: true)
        @sibling_element = @key_element.sibling("td", text: @value, exact_text: true)
      end
      @sibling_element
    end
  end

  def have_summary_item(key:, value:)
    HaveSummaryItem.new(key: key, value: value)
  end
end
