require "rails_helper"

RSpec.describe RemoveBusinessFromCase, :with_stubbed_elasticsearch, :with_stubbed_notification do
  subject { described_class.call(business: business).merge(common_context) }

  let(:business)                 { create(:business) }
  let(:user)                     { create(:user) }
  let(:investigation)            { create(:allegation, creator: user, business_to_add: business) }

  let(:common_context)           { { user: user, investigation: investigation } }

  let(:corrective_action_params) { attributes_for(:corrective_action, business: business).merge(common_context) }
  let(:corrective_action)        { AddCorrectiveActionToCase.call!.corrective_action }

  let(:risk_assessment_params)   { attributes_for(:risk_assessment, assessed_by_business: business).merge(common_context) }
  let(:risk_assessment)          { AddRiskAssessmentToCase.call!(risk_assessment_params) }

  describe "#call" do
    context "when no supporting informations are attached to the business" do
      it { is_expected.to be_a_success }
    end
  end
end
