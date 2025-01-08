require "rails_helper"

RSpec.describe NotifyHelper do
  describe "#inset_text_for_notify" do
    context "when a single line" do
      let(:text) { "This is my message" }

      it "adds the ^ character to the start" do
        expect(inset_text_for_notify(text)).to eql("^ This is my message")
      end
    end

    context "when multiple lines" do
      let(:text) { "This is my message:\n\nIt spans multiple lines." }

      it "adds the ^ character to the start of each line" do
        expect(inset_text_for_notify(text)).to eql("^ This is my message:\n^ \n^ It spans multiple lines.")
      end
    end

    context "when multiple lines using windows-style linebreaks" do
      let(:text) { "This is my Windows message:\r\n\r\nIt spans multiple lines." }

      it "adds the ^ character to the start of each line" do
        expect(inset_text_for_notify(text)).to eql("^ This is my Windows message:\r\n^ \r\n^ It spans multiple lines.")
      end
    end
  end
end
