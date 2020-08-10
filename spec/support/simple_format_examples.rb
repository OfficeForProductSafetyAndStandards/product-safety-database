RSpec.shared_examples "a formated text" do |instance, text_attribute|
  include ActionView::Helpers::TextHelper
  let(:text) { "this is\n\nmulti line\n\nformated" }
  before { public_send(instance).public_send(:"#{text_attribute}=", text) }

  it "keeps the line breaks" do
    expect(subject.public_send(text_attribute)).to eq(simple_format(text))
  end
end
