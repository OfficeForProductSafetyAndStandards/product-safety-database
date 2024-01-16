RSpec.describe ContentHelper do
  describe "#format_with_line_breaks" do
    context "when including a single line break" do
      it "adds a <br> tag" do
        expect(helper.format_with_line_breaks("Test\nTest")).to eql("<p>Test\n<br />Test</p>")
      end
    end

    context "when including a multiple line breaks" do
      it "splits the text into paragraphs" do
        expect(helper.format_with_line_breaks("Test\n\nTest")).to eql("<p>Test</p>\n\n<p>Test</p>")
      end
    end

    context "when including html tags" do
      it "escapes the tags" do
        expect(helper.format_with_line_breaks("<b>Test</b>")).to eql("<p>&lt;b&gt;Test&lt;/b&gt;</p>")
      end
    end
  end
end
