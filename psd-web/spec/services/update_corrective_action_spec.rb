require "rails_helper"

RSpec.describe UpdateCorrectiveAction do
  let(:user)             { create(:user) }
  let(:investigation)    { create(:allegation, creator: user) }
  let(:product)          { create(:product) }
  let(:business)         { create(:business) }
  let(:old_date_decided) { Time.zone.today }
  let(:corrective_action) do
    create(
      :corrective_action,
      :with_file,
      investigation: investigation,
      date_decided: old_date_decided,
      product: product,
      business: business
    )
  end
  let(:new_date_decided) { (old_date_decided - 1.day).to_date }

  subject(:update_corractive_action) do
    described_class.call!(
      corrective_action: corrective_action,
      user: user,
      corrective_action_params: corrective_action_params
    )
  end

  describe "#call" do
    it "updates the corrective action" do
      expect {
        update_corrective_action
      }.to change(corrective_action, :date_received.new_date_decided)
    end
  end
end
