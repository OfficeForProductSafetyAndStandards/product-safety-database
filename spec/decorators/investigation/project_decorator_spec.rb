require "rails_helper"

RSpec.describe Investigation::ProjectDecorator, :with_stubbed_mailer do
  include ActionView::Helpers::DateHelper

  subject(:decorated_investigation) { investigation.decorate }

  let(:user)          { build_stubbed(:user) }
  let(:investigation) { create(:project) }

  before do
    create(:complainant, investigation:)
  end

  describe "#title" do
    context "with a user_title" do
      let(:investigation) { create(:project, user_title:) }
      let(:user_title)    { "user title" }

      it { expect(decorated_investigation.title).to eq(user_title) }
    end

    context "without a user_title" do
      let(:investigation) { create(:project, user_title: nil) }

      it "uses the pretty_id" do
        expect(decorated_investigation.title).to eq(investigation.pretty_id)
      end
    end
  end
end
