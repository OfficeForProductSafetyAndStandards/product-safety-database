require "rails_helper"

RSpec.describe RemoveBusinessFromNotification, :with_opensearch, :with_test_queue_adapter do
  subject(:result) do
    described_class.call(business:, reason:, user:, notification:)
  end

  let(:business)              { create(:business) }
  let(:user)                  { create(:user) }
  let(:creator)               { user }
  let(:owner)                 { user }
  let(:product)               { create(:product, investigations: [notification]) }
  let(:investigation_product) { notification.investigation_products.first }
  let(:notification)          { create(:notification, :with_business, creator:, business_to_add: business) }
  let(:common_context)        { { user:, investigation: notification } }
  let(:reason)                { Faker::Hipster.sentence }

  context "with stubbed opensearch" do
    def expected_email_subject
      "Notification updated"
    end

    def expected_email_body(name)
      "Business was removed from the notification by #{name}."
    end

    context "when no supporting informations are attached to the business" do
      it { is_expected.to be_a_success }

      it "has removed the business from the investigation" do
        expect {
          result
        }.to change { notification.businesses.where(businesses: { id: business }).count }.from(1).to(0)
      end

      it "creates an audit activity", :aggregate_failures do
        result

        activity = notification.reload.activities.find_by!(type: AuditActivity::Business::Destroy.name)
        expect(activity)
          .to have_attributes(title: nil, body: nil, business_id: business.id, metadata: { "business" => JSON.parse(business.attributes.to_json), "reason" => reason })
        expect(activity.added_by_user).to eq(user)
      end

      it_behaves_like "a service which notifies the notification owner"
    end

    context "when a corrective action is attached to the business" do
      let(:corrective_action_params) { attributes_for(:corrective_action, business_id: business.id, investigation_product_id: investigation_product.id).merge(common_context) }
      let(:corrective_action)        { AddCorrectiveActionToCase.call!(corrective_action_params).corrective_action }

      before { corrective_action }

      it "is a failure with the relevant error", :aggregate_failures do
        expect(result).to be_a_failure
        expect(result.error).to eq(:business_is_attached_to_supporting_information)
      end
    end

    context "when a risk assessment is attached to the business" do
      let(:risk_assessment_params) do
        attributes_for(:risk_assessment, assessed_by_business_id: business.id, investigation_product_ids: [investigation_product.id]).merge(common_context)
      end
      let(:risk_assessment) { AddRiskAssessmentToCase.call!(risk_assessment_params).risk_assessment }

      before { risk_assessment }

      it "is a failure with the relevant error", :aggregate_failures do
        expect(result).to be_a_failure
        expect(result.error).to eq(:business_is_attached_to_supporting_information)
      end
    end
  end
end
