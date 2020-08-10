require "rails_helper"

RSpec.describe ActiveStorage::AttachmentDecorator do
  include ActionView::Helpers::TextHelper

  subject(:decorated_attachment) { attachment.decorate }

  let(:attachment) { ActiveStorage::Attachment.new.tap(&:build_blob) }

  describe "#description" do
    let(:description) { "something\nwith\nnew lines" }

    before do
      attachment.metadata[:description] = description
    end

    it "formats the metadata description" do
      expect(decorated_attachment.description).to eq(simple_format(description))
    end
  end
end
