require "rails_helper"

RSpec.describe InvestigationSerializer, :with_stubbed_mailer, :with_test_queue_adapter, type: :serializers do
  subject { described_class.new(investigation) }

  let(:investigation) { build(:allegation) }
  let(:hash) { subject.to_h }

  it "serializes an investigation object", :aggregate_failures do
    expect(hash[:type]).to eq(investigation.type)
    expect(hash[:hazard_type]).to eq(investigation.hazard_type)
    expect(hash[:user_title]).to eq(investigation.user_title)
    expect(hash[:pretty_id]).to eq(investigation.pretty_id)
  end

  describe "#last_change_at" do
    let(:investigation_last_change) { time - 7.days }
    let(:time) { Time.zone.parse("16 Oct 2023 00:00") }
    let(:investigation) { build(:allegation, updated_at: investigation_last_change, created_at: investigation_last_change) }

    context "when an investigation has activities" do
      let(:investigation) { create(:allegation, updated_at: investigation_last_change, created_at: investigation_last_change) }
      let(:test_result_activity) { create(:audit_activity_test_result, investigation:) }

      it "returns the test_result_activity_created_at" do
        expect(hash[:last_change_at].to_i).to eq(test_result_activity.created_at.to_i)
      end
    end

    context "when an investigation has no activities" do
      it "returns the investigation updated_at" do
        expect(hash[:last_change_at].to_i).to eq(investigation_last_change.to_i)
      end
    end
  end
end
