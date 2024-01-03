require "rails_helper"

RSpec.describe AddBusinessToNotification, :with_test_queue_adapter do
  subject(:result) { described_class.call(investigation:, business:, user:) }

  let(:investigation) { create(:allegation, creator:) }
  let(:business)      { build(:business) }
  let(:user)          { create(:user) }
  let(:creator)       { user }
  let(:owner)         { user }

  context "with no parameters" do
    let(:result) { described_class.call }

    it "returns a failure" do
      expect(result).to be_failure
    end
  end

  context "with no investigation parameter" do
    let(:result) { described_class.call(business:, user:) }

    it "returns a failure" do
      expect(result).to be_failure
    end
  end

  context "with no product parameter" do
    let(:result) { described_class.call(investigation:, user:) }

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
        expect(Business.last.primary_location.added_by_user).to eq(creator)
      end
    end

    it "creates and audit log", :aggregate_failures do
      result

      business = Business.last
      activity = investigation.reload.activities.find_by!(type: AuditActivity::Business::Add.name)
      expect(activity).to have_attributes(title: nil, body: nil, business_id: business.id, metadata: { "business" => JSON.parse(business.attributes.to_json), "investigation_business" => JSON.parse(business.investigation_businesses.find_by!(investigation:).attributes.to_json) })
      expect(activity.added_by_user).to eq(user)
    end

    it_behaves_like "a service which notifies the investigation owner"
  end

  context "with a relationship" do
    subject(:result) { described_class.call(investigation:, business:, user:, relationship:) }

    let(:relationship) { "Manufacturer" }

    it "saves the the businesses" do
      expect { result }.to change(investigation.businesses, :count).from(0).to(1)
    end

    it "persists the relationship on the investigation_business" do
      result

      expect(Business.last.investigation_businesses.find_by!(investigation:).relationship).to eq(relationship)
    end

    it "creates and audit log", :aggregate_failures do
      result

      business = Business.last
      activity = investigation.reload.activities.find_by!(type: AuditActivity::Business::Add.name)
      expect(activity).to have_attributes(title: nil, body: nil, business_id: business.id, metadata: { "business" => JSON.parse(business.attributes.to_json), "investigation_business" => JSON.parse(business.investigation_businesses.find_by!(investigation:).attributes.to_json) })
      expect(activity.added_by_user).to eq(user)
    end

    it_behaves_like "a service which notifies the investigation owner"
  end

  context "with an approved online marketplace" do
    subject(:result) { described_class.call(investigation:, business:, user:, online_marketplace:) }

    let(:online_marketplace) { create(:online_marketplace) }

    it "saves the the businesses" do
      expect { result }.to change(investigation.businesses, :count).from(0).to(1)
    end

    it "associates the online marketplace to the investigation_business" do
      result

      expect(Business.last.investigation_businesses.find_by!(investigation:).online_marketplace).to eq(online_marketplace)
    end

    it "creates an audit log", :aggregate_failures do
      result

      business = Business.last
      activity = investigation.reload.activities.find_by!(type: AuditActivity::Business::Add.name)
      expect(activity).to have_attributes(title: nil, body: nil, business_id: business.id, metadata: { "business" => JSON.parse(business.attributes.to_json), "investigation_business" => JSON.parse(business.investigation_businesses.find_by!(investigation:).attributes.to_json) })
      expect(activity.added_by_user).to eq(user)
    end

    it_behaves_like "a service which notifies the investigation owner"
  end

  context "with a choice for authorised_representative" do
    subject(:result) { described_class.call(investigation:, business:, user:, authorised_representative_choice:) }

    let(:authorised_representative_choice) { "EU Authorised representative" }

    it "saves the the businesses" do
      expect { result }.to change(investigation.businesses, :count).from(0).to(1)
    end

    it "sets the authorised_representative_choice on investigation_business" do
      result

      expect(Business.last.investigation_businesses.find_by!(investigation:).authorised_representative_choice).to eq("EU Authorised representative")
    end

    it "creates an audit log", :aggregate_failures do
      result

      business = Business.last
      activity = investigation.reload.activities.find_by!(type: AuditActivity::Business::Add.name)
      expect(activity).to have_attributes(title: nil, body: nil, business_id: business.id, metadata: { "business" => JSON.parse(business.attributes.to_json), "investigation_business" => JSON.parse(business.investigation_businesses.find_by!(investigation:).attributes.to_json) })
      expect(activity.added_by_user).to eq(user)
    end

    it_behaves_like "a service which notifies the investigation owner"
  end

  context "when given just the name of a new 'other' online marketplace" do
    subject(:result) { described_class.call(investigation:, business:, user:, other_marketplace_name:) }

    let(:other_marketplace_name) { Faker::Company.name }

    it "saves the the businesses" do
      expect { result }.to change(investigation.businesses, :count).from(0).to(1)
    end

    it "creates a new online marketplace as unapproved" do
      result

      expect(Business.last.investigation_businesses.find_by!(investigation:).online_marketplace.approved_by_opss).to be_falsey
    end

    it "associates the new online marketplace to the investigation_business" do
      result

      expect(Business.last.investigation_businesses.find_by!(investigation:).online_marketplace.name).to eq(other_marketplace_name)
    end

    it "creates and audit log", :aggregate_failures do
      result

      business = Business.last
      activity = investigation.reload.activities.find_by!(type: AuditActivity::Business::Add.name)
      expect(activity).to have_attributes(title: nil, body: nil, business_id: business.id, metadata: { "business" => JSON.parse(business.attributes.to_json), "investigation_business" => JSON.parse(business.investigation_businesses.find_by!(investigation:).attributes.to_json) })
      expect(activity.added_by_user).to eq(user)
    end

    it_behaves_like "a service which notifies the investigation owner"

    context "when the name is not unique" do
      let(:online_marketplace) { create(:online_marketplace) }
      let(:other_marketplace_name) { online_marketplace.name }

      it "prevents another online marketplace being created" do
        expect { result }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name has already been taken")
      end
    end
  end

  def expected_email_subject
    "Business added"
  end

  def expected_email_body(name)
    "Business was added to the notification by #{name}."
  end
end
