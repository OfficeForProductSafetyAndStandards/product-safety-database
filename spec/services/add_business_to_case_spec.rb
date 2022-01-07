require "rails_helper"

RSpec.describe AddBusinessToCase, :with_stubbed_opensearch, :with_test_queue_adapter do
  subject(:result) { described_class.call(investigation: investigation, business: business, user: user) }

  let(:investigation) { create(:allegation, creator: creator) }
  let(:business)      { build(:business) }
  let(:user)          { create(:user) }
  let(:creator)       { user }
  let(:owner)         { user }

  describe ".call" do
    def expected_email_subject
      "Business added"
    end

    def expected_email_body(name)
      "Business was added to the #{investigation.case_type} by #{name}."
    end

    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no investigation parameter" do
      let(:result) { described_class.call(business: business, user: user) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no product parameter" do
      let(:result) { described_class.call(investigation: investigation, user: user) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with the required parameter" do
      it "saves the the businesses" do
        expect { result }.to change(investigation.businesses, :count).from(0).to(1)
      end

      context "with a primary location" do
        before do
          business.locations.new(attributes_for(:location).except(:name))
        end

        it "has set the default name", :aggregate_failures do
          result

          expect(Business.last.primary_location.name).to eq("Registered office address")
          expect(Business.last.primary_location.source.user).to eq(creator)
        end
      end

      it "creates and audit log", :aggregate_failures do
        result

        business = Business.last
        activity = investigation.reload.activities.find_by!(type: AuditActivity::Business::Add.name)
        expect(activity).to have_attributes(title: nil, body: nil, business_id: business.id, metadata: { "business" => JSON.parse(business.attributes.to_json), "investigation_business" => JSON.parse(business.investigation_businesses.find_by!(investigation: investigation).attributes.to_json) })
        expect(activity.source.user).to eq(user)
      end

      it_behaves_like "a service which notifies the case owner"
    end
  end
end
