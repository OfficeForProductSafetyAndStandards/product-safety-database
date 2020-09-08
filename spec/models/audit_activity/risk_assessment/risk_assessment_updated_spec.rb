require "rails_helper"

RSpec.describe AuditActivity::RiskAssessment::RiskAssessmentUpdated, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:activity) { investigation.reload.activities.first }

  let(:investigation) { create(:allegation, :with_products, creator: user) }
  let(:user) { create(:user) }
  let(:date) { Time.zone.today }
  let(:new_date) { Time.zone.today - 10.days }
  let(:file) { fixture_file_upload(file_fixture("risk_assessment.txt")) }
  let(:risk_assessment) do
    AddRiskAssessmentToCase.call!(
      investigation: investigation,
      user: user,
      assessed_on: date,
      assessed_by_team_id: user.team.id,
      risk_level: "high",
      details: "Test",
      product_ids: investigation.product_ids,
      risk_assessment_file: file
    ).risk_assessment
  end

  before do
    UpdateRiskAssessment.call!(
      risk_assessment: risk_assessment,
      user: user,
      assessed_on: new_date,
      assessed_by_team_id: user.team.id,
      risk_level: "serious",
      details: "Test 2",
      product_ids: investigation.product_ids
    )
  end

  describe "#new_assessed_on" do
    context "when the date has changed" do
      it "returns a Date object" do
        expect(activity.new_assessed_on).to be_a(Date)
      end

      it "returns the new date" do
        expect(activity.new_assessed_on).to eq(new_date)
      end
    end

    context "when the date has not changed" do
      let(:new_date) { date }

      it "returns nil" do
        expect(activity.new_assessed_on).to be_nil
      end
    end
  end
end
