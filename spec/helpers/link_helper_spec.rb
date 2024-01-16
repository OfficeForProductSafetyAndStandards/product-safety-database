RSpec.describe LinkHelper do
  describe "#link_with_hidden_text_to" do
    subject(:link) { helper.link_with_hidden_text_to(title, hidden_text, url, class: class_name) }

    let(:url) { unauthenticated_root_path }
    let(:title) { "Home page" }
    let(:hidden_text) { "(hidden text)" }
    let(:class_name) { "test" }

    it "outputs hidden text" do
      expect(link).to eq("<a class=\"#{class_name}\" href=\"#{url}\">#{title}<span class=\"govuk-visually-hidden\"> #{hidden_text}</span>\n</a>")
    end
  end
end
