require "rails_helper"

RSpec.describe BannerHelper do
  describe "#banner" do
    context "with a text param" do
      let(:banner) { helper.banner(text: "There is a problem") }

      it "outputs the text within a container" do
        expect(banner).to eql("<div class=\"app-banner\"><div class=\"app-banner__message\">There is a problem</div></div>")
      end
    end

    context "with an html param" do
      let(:banner) { helper.banner(html: tag.p("There is a problem")) }

      it "outputs the text within a container" do
        expect(banner).to eql("<div class=\"app-banner\"><div class=\"app-banner__message\"><p>There is a problem</p></div></div>")
      end
    end

    context "with a block" do
      let(:banner) {
        helper.banner do
          tag.p("There is a problem")
        end
      }

      it "outputs the text within a container" do
        expect(banner).to eql("<div class=\"app-banner\"><div class=\"app-banner__message\"><p>There is a problem</p></div></div>")
      end
    end
  end
end
