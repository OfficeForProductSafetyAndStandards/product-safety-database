require "rails_helper"

RSpec.describe RemoveBusinessFromCase, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:remove_business_from_case) { described_class.call({ business: business }.merge(common_context)) }

  let(:business)                 { create(:business) }
  let(:user)                     { create(:user) }
  let(:product)                  { create(:product, investigations: [investigation]) }
  let(:investigation)            { create(:allegation, :with_business, creator: user, business_to_add: business) }
  let(:common_context)           { { user: user, investigation: investigation } }

  describe "#call" do
    context "when no supporting informations are attached to the business" do
      it { is_expected.to be_a_success }

      it "has removed the business from the investigation" do
        expect {
          remove_business_from_case
        }.to change { investigation.businesses.where(businesses: { id: business }).count }.from(1).to(0)
      end
    end

    context "when a corrective action is attached to the business" do
      let(:corrective_action_params) { attributes_for(:corrective_action, business_id: business.id, product_id: product.id).merge(common_context) }
      let(:corrective_action)        { AddCorrectiveActionToCase.call!(corrective_action_params).corrective_action }

      before { corrective_action }

      it "is a failure with the relevant error", :aggregate_failures do
        expect(remove_business_from_case).to be_a_failure
        expect(remove_business_from_case.error).to eq(:business_is_attached_to_supporting_information)
      end
    end

    context "when a risk assessemnt is attached to the business" do
      let(:risk_assessment_params) do
        attributes_for(:risk_assessment, assessed_by_business_id: business.id, product_ids: [product.id]).merge(common_context)
      end
      let(:risk_assessment) { AddRiskAssessmentToCase.call!(risk_assessment_params).risk_assessment }

      before { risk_assessment }

      it "is a failure with the relevant error", :aggregate_failures do
        expect(remove_business_from_case).to be_a_failure
        expect(remove_business_from_case.error).to eq(:business_is_attached_to_supporting_information)
      end
    end
  end
end
