require "rails_helper"

RSpec.describe Investigation::Case do
  subject(:kase) { build(:kase, date_received:).build_owner_collaborations_from(create(:user)) }

  describe "#valid?" do
    context "with valid date_received" do
      let(:date_received) { 1.day.ago }

      it { is_expected.to be_valid }
    end

    context "with empty date_received" do
      let(:date_received) { nil }

      it { is_expected.to be_valid }
    end
  end
end
