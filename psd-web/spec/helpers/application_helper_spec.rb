require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#title_for" do
    let(:title) { "A page title" }
    let(:user) { build :user }

    context "without errors" do
      it {
        expect { helper.title_for(user, title) }
          .to change { helper.content_for(:page_title) }.from(nil).to(title) }
    end

    context "with errors" do
      before { user.errors.add(:base, "foo") }

      it "prepends errors to the page title" do
        expect { helper.title_for(user, title) }
          .to change { helper.content_for(:page_title) }.from(nil).to("Error: #{title}")
      end
    end
  end
end
