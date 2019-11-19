require "nokogiri"

module ResponseMatcher
  class CssMatcher
    def initialize(expected_path)
      @expected_path = expected_path
    end

    def matches?(html)
      @html = html
      @body = Nokogiri::HTML(@html).at_css("body")
      !@body.at_css(@expected_path).nil?
    end

    def failure_message
      "expected:\n\n#{@body.to_xhtml(indent: 3)}\n\n ...to match CSS path #{@expected_path}"
    end

    def failure_message_when_negated
      "expected:\n\n#{@body.to_xhtml(indent: 3)}\n\n ...not to match CSS path #{@expected_path}"
    end
  end

  def have_css(html)
    CssMatcher.new(html)
  end
end

RSpec.configure do |config|
  config.include ResponseMatcher
end
