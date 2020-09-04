require "rails_helper"

RSpec.describe UpdateRiskAssessment, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus, :with_test_queue_adapter do
  let(:product1) { create(:product) }
  let(:product2) { create(:product) }
  let(:team) { create(:team, name: "Team 2") }
  let(:user) { create(:user, name: "User 2", team: team) }

  let(:investigation) { create(:allegation) }

  let(:risk_assessment) do
    create(:risk_assessment,
           investigation: investigation,
           assessed_on: Date.parse("2019-01-01"),
           risk_level: :low,
           custom_risk_level: nil,
           assessed_by_team: user.team,
           assessed_by_business: nil,
           assessed_by_other: nil,
           details: "More details",
           risk_assessment_file: Rack::Test::UploadedFile.new("test/fixtures/files/old_risk_assessment.txt"),
           products: [product1])
  end

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(risk_assessment: risk_assessment) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no risk_assessment parameter" do
      let(:result) { described_class.call(user: user) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with the required parameters" do
      let(:update_risk_assessment) do
        described_class.call(
          risk_assessment: risk_assessment,
          user: user,
          assessed_on: assessed_on,
          risk_level: risk_level,
          custom_risk_level: custom_risk_level,
          assessed_by_team_id: assessed_by_team_id,
          assessed_by_business_id: assessed_by_business_id,
          assessed_by_other: assessed_by_other,
          details: details,
          product_ids: product_ids,
          risk_assessment_file: risk_assessment_file
        )
      end

      context "when no changes have been made" do
        let(:assessed_on) { Date.parse("2019-01-01") }
        let(:risk_level) { :low }
        let(:custom_risk_level) { nil }
        let(:assessed_by_team_id) { user.team.id }
        let(:assessed_by_business_id) { nil }
        let(:assessed_by_other) { nil }
        let(:details) { "More details" }
        let(:product_ids) { [product1.id] }
        let(:risk_assessment_file) { nil }
        let(:updated_at) { 1.hour.ago }

        before do
          # Have to do this after setup as attaching the document also updates the
          # updated_at timestamp
          risk_assessment.update_column(:updated_at, updated_at)
        end

        it "does not generate an activity entry" do
          update_risk_assessment

          expect(risk_assessment.investigation.activities.where(type: AuditActivity::RiskAssessment::RiskAssessmentUpdated.to_s)).to eq []
        end

        it "does not send any case updated emails" do
          expect { update_risk_assessment }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
        end
      end

      context "when changes have been made" do
        let(:assessed_on) { Date.parse("2020-01-02") }
        let(:risk_level) { :serious }
        let(:custom_risk_level) { nil }
        let(:assessed_by_team_id) { nil }
        let(:assessed_by_business_id) { nil }
        let(:assessed_by_other) { "OtherBusiness Ltd" }
        let(:details) { "Updated details" }
        let(:product_ids) { [product2.id] }
        let(:risk_assessment_file) { Rack::Test::UploadedFile.new("test/fixtures/files/new_risk_assessment.txt") }

        it "updates the risk assessment", :aggregate_failures do
          update_risk_assessment

          expect(risk_assessment.assessed_on).to eq(Date.parse("2020-01-02"))
          expect(risk_assessment.risk_level).to eq("serious")
          expect(risk_assessment.assessed_by_team).to be nil
          expect(risk_assessment.assessed_by_business).to be nil
          expect(risk_assessment.assessed_by_other).to eq("OtherBusiness Ltd")
          expect(risk_assessment.details).to eq("Updated details")
        end

        it "updates the products associated with the risk assessment" do
          update_risk_assessment

          expect(risk_assessment.products).to eq([product2])
        end

        # rubocop:disable RSpec/ExampleLength
        it "creates an activity entry" do
          update_risk_assessment

          activity_entry = risk_assessment.investigation.activities.where(type: AuditActivity::RiskAssessment::RiskAssessmentUpdated.to_s).order(:created_at).last

          expect(activity_entry.metadata).to eql({
            "risk_assessment_id" => risk_assessment.id,
            "updates" => {
              "assessed_by_other" => [nil, "OtherBusiness Ltd"],
              "assessed_by_team_id" => [user.team.id, nil],
              "assessed_on" => %w[2019-01-01 2020-01-02],
              "details" => ["More details", "Updated details"],
              "filename" => ["old_risk_assessment.txt", "new_risk_assessment.txt"],
              "product_ids" => [[product1.id], [product2.id]],
              "risk_level" => %w[low serious],
            }
          })
        end
        # rubocop:enable RSpec/ExampleLength

        it "sends a notification email to the case owner" do
          expect { update_risk_assessment }.to have_enqueued_mail(NotifyMailer, :investigation_updated).with(
            risk_assessment.investigation.pretty_id,
            investigation.owner_user.name,
            investigation.owner_user.email,
            "User 2 (Team 2) edited a risk assessment on the allegation.",
            "Risk assessment edited for Allegation"
          )
        end
      end
    end
  end
end
