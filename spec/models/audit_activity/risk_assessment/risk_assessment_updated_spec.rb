require "rails_helper"

RSpec.describe AuditActivity::RiskAssessment::RiskAssessmentUpdated, :with_stubbed_mailer, :with_stubbed_antivirus do
  include ActionDispatch::TestProcess::FixtureFile

  subject(:activity) { investigation.reload.activities.where(type: described_class.to_s).first }

  let(:investigation) { create(:allegation, :with_products, creator: user) }
  let(:user) { create(:user) }
  let(:date) { Time.zone.today }
  let(:new_date) { Time.zone.today - 10.days }
  let(:file) { fixture_file_upload("risk_assessment.txt") }
  let(:risk_assessment) do
    AddRiskAssessmentToNotification.call!(
      investigation:,
      user:,
      assessed_on: date,
      assessed_by_team_id: user.team.id,
      risk_level: "high",
      details: "Test",
      investigation_product_ids: investigation.investigation_product_ids,
      risk_assessment_file: file
    ).risk_assessment
  end

  describe ".build_metadata" do
    subject(:metadata) { described_class.build_metadata(risk_assessment:, previous_investigation_product_ids: investigation.investigation_product_ids, attachment_changed:, previous_attachment_filename:) }

    context "when the attachment has not changed" do
      let(:attachment_changed) { false }
      let(:previous_attachment_filename) { nil }

      before { risk_assessment.update!(assessed_on: new_date) }

      it "builds a list of changes" do
        expect(metadata).to eq({
          risk_assessment_id: risk_assessment.id,
          updates: {
            "assessed_on" => [date, new_date]
          }
        })
      end
    end

    context "when the attachment has changed" do
      let(:attachment_changed) { true }
      let(:new_file) { fixture_file_upload("new_risk_assessment.txt") }
      let(:previous_attachment_filename) { "risk_assessment.txt" }

      before do
        risk_assessment.risk_assessment_file.detach
        risk_assessment.risk_assessment_file.attach(new_file)
        risk_assessment.save!
      end

      it "builds a list of changes" do
        expect(metadata).to eq({
          risk_assessment_id: risk_assessment.id,
          updates: {
            "filename" => ["risk_assessment.txt", "new_risk_assessment.txt"]
          }
        })
      end
    end
  end

  describe "#metadata" do
    # TODO: remove once migrated
    context "when metadata contains a Product reference" do
      let(:new_investigation_product) { create(:investigation_product, investigation:) }
      let(:activity) { described_class.new(metadata: { updates: { investigation_product_id: [investigation.investigation_product_ids.first, new_investigation_product.id] } }.deep_stringify_keys) }

      it "translates the Product ID to InvestigationProduct ID" do
        expect(activity.metadata["updates"]["product_id"]).to be_nil
        expect(activity.metadata["updates"]["investigation_product_id"]).to eq([investigation.investigation_product_ids.first, new_investigation_product.id])
      end
    end
  end

  describe "#new_assessed_on" do
    before do
      UpdateRiskAssessment.call!(
        risk_assessment:,
        user:,
        assessed_on: new_date,
        assessed_by_team_id: user.team.id,
        risk_level: "serious",
        details: "Test 2",
        previous_investigation_product_ids: investigation.investigation_product_ids,
        investigation_product_ids: investigation.investigation_product_ids
      )
    end

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
