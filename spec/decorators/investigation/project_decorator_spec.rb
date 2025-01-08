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
      let(:user_title) { "user title" }
      let(:investigation) { create(:project, user_title:, complainant_reference: nil) }

      it { expect(decorated_investigation.title).to eq(user_title) }
    end

    context "without a user_title but with a complainant_reference" do
      let(:complainant_reference) { "complainant reference" }
      let(:investigation) { create(:project, user_title: nil, complainant_reference:) }

      it { expect(decorated_investigation.title).to eq(complainant_reference) }
    end

    context "without a user_title or a complainant_reference" do
      let(:investigation) { create(:project, user_title: nil, complainant_reference: nil) }

      it "uses the pretty_id" do
        expect(decorated_investigation.title).to eq(investigation.pretty_id)
      end
    end
  end
end
