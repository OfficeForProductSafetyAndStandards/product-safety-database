require "rails_helper"

RSpec.describe UpdateCorrectiveAction, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:update_corrective_action) do
    described_class.call(
      corrective_action: corrective_action,
      user: user,
      corrective_action_params: corrective_action_params
    )
  end

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
  let(:corrective_action_params) do
    ActionController::Parameters.new(date_decided: { year: new_date_decided.year, month: new_date_decided.month, day: new_date_decided.day }).permit!
  end

  describe "#call" do
    context "with no parameters" do
      it "returns a failure" do
        expect(described_class.call).to be_failure
      end
    end

    context "when missing parameters" do
      let(:params) do
        {
          corrective_action: corrective_action,
          user: user,
          corrective_action_params: {}
        }
      end

      it { expect(described_class.call(params.except(:corrective_action))).to be_a_failure }
      it { expect(described_class.call(params.except(:corrective_action_params))).to be_a_failure }
      it { expect(described_class.call(params.except(:user))).to be_a_failure }
    end

    context "with required parameters that trigger a validation error" do
      before do
        corrective_action_params[:date_decided][:day] = ""
      end

      it "returns a failure", :aggregate_failures do
        expect(update_corrective_action).to be_a_failure
        expect(update_corrective_action.error).to eq("Enter date the corrective action was decided")
      end
    end

    context "with required parameters" do
      it "updates the corrective action" do
        expect {
          update_corrective_action
        }.to change(corrective_action, :date_decided).from(old_date_decided).to(new_date_decided)
      end

      it "generates an activity entry with the changes" do
        update_corrective_action

        activity_timeline_entry = investigation.activities.reload.order(:created_at).find_by!(type: "AuditActivity::CorrectiveAction::Update")
        expect(activity_timeline_entry).to have_attributes({})
      end
    end
  end
end
