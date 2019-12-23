require "rails_helper"

RSpec.describe LinkHelper do
  describe "#link_with_hidden_text_to" do
    let(:url) { root_path }
    let(:title) { "Home page" }
    let(:hidden_text) { "hidden text" }
    let(:class_name) { "test" }

    subject { helper.link_with_hidden_text_to(title, hidden_text, url, { class: class_name }) }

    it "outputs hidden text" do
      expect(subject).to eq("<a class=\"#{class_name}\" href=\"#{url}\">#{title}<span class=\"govuk-visually-hidden\"> (#{hidden_text})</span></a>")
    end
  end
end
