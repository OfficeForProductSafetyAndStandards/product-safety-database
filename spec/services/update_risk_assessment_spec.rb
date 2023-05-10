require "rails_helper"

RSpec.describe UpdateRiskAssessment, :with_stubbed_opensearch, :with_stubbed_mailer, :with_stubbed_antivirus, :with_test_queue_adapter do
  let(:investigation_product1) { create(:investigation_product) }
  let(:investigation_product2) { create(:investigation_product) }
  let(:team) { create(:team, name: "Team 2") }
  let(:user) { create(:user, name: "User 2", team:) }

  let(:investigation) { create(:allegation) }

  let(:assessed_on) { Date.parse("2019-01-01") }
  let(:risk_level) { :low }
  let(:custom_risk_level) { nil }
  let(:assessed_by_team_id) { user.team.id }
  let(:assessed_by_business_id) { nil }
  let(:assessed_by_other) { nil }
  let(:details) { "More details" }

  let(:risk_assessment) do
    create(:risk_assessment,
           investigation:,
           assessed_on: Date.parse("2019-01-01"),
           risk_level: :low,
           custom_risk_level: nil,
           assessed_by_team: user.team,
           assessed_by_business: nil,
           assessed_by_other: nil,
           details: "More details",
           risk_assessment_file: Rack::Test::UploadedFile.new("test/fixtures/files/old_risk_assessment.txt"),
           investigation_products: [investigation_product1])
  end

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(risk_assessment:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no risk_assessment parameter" do
      let(:result) { described_class.call(user:) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with the required parameters" do
      let(:result) do
        described_class.call(
          risk_assessment:,
          user:,
          assessed_on:,
          risk_level:,
          custom_risk_level:,
          assessed_by_team_id:,
          assessed_by_business_id:,
          assessed_by_other:,
          details:,
          investigation_product_ids:,
          risk_assessment_file:
        )
      end

      let(:activity_entry) { risk_assessment.investigation.activities.where(type: AuditActivity::RiskAssessment::RiskAssessmentUpdated.to_s).order(:created_at).last }

      context "when no changes have been made" do
        let(:assessed_on) { Date.parse("2019-01-01") }
        let(:risk_level) { :low }
        let(:custom_risk_level) { nil }
        let(:assessed_by_team_id) { user.team.id }
        let(:assessed_by_business_id) { nil }
        let(:assessed_by_other) { nil }
        let(:details) { "More details" }
        let(:investigation_product_ids) { [investigation_product1.id] }
        let(:risk_assessment_file) { nil }
        let(:updated_at) { 1.hour.ago }

        before do
          # Have to do this after setup as attaching the document also updates the
          # updated_at timestamp
          risk_assessment.update_column(:updated_at, updated_at)
        end

        it "does not generate an activity entry" do
          result

          expect(risk_assessment.investigation.activities.where(type: AuditActivity::RiskAssessment::RiskAssessmentUpdated.to_s)).to eq []
        end

        it "does not send any case updated emails" do
          expect { result }.not_to have_enqueued_mail(NotifyMailer, :investigation_updated)
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
        let(:investigation_product_ids) { [investigation_product2.id] }
        let(:risk_assessment_file) { Rack::Test::UploadedFile.new("test/fixtures/files/new_risk_assessment.txt") }

        it "updates the risk assessment", :aggregate_failures do
          result

          expect(risk_assessment.assessed_on).to eq(Date.parse("2020-01-02"))
          expect(risk_assessment.risk_level).to eq("serious")
          expect(risk_assessment.assessed_by_team).to be nil
          expect(risk_assessment.assessed_by_business).to be nil
          expect(risk_assessment.assessed_by_other).to eq("OtherBusiness Ltd")
          expect(risk_assessment.details).to eq("Updated details")
        end

        it "updates the investigation products associated with the risk assessment" do
          result

          expect(risk_assessment.investigation_products).to eq([investigation_product2])
        end

        # rubocop:disable RSpec/ExampleLength
        it "creates an activity entry" do
          result

          expect(activity_entry.metadata).to eql({
            "risk_assessment_id" => risk_assessment.id,
            "updates" => {
              "assessed_by_other" => [nil, "OtherBusiness Ltd"],
              "assessed_by_team_id" => [user.team.id, nil],
              "assessed_on" => %w[2019-01-01 2020-01-02],
              "details" => ["More details", "Updated details"],
              "filename" => ["old_risk_assessment.txt", "new_risk_assessment.txt"],
              "investigation_product_ids" => [[investigation_product1.id], [investigation_product2.id]],
              "risk_level" => %w[low serious],
            }
          })
        end
        # rubocop:enable RSpec/ExampleLength

        def expected_email_subject
          "Risk assessment edited for Case"
        end

        def expected_email_body(name)
          "#{name} edited a risk assessment on the case."
        end

        it_behaves_like "a service which notifies the case owner"
      end

      context "when only the file has changed" do
        let(:investigation_product_ids) { [investigation_product1.id] }
        let(:risk_assessment_file) { Rack::Test::UploadedFile.new("test/fixtures/files/new_risk_assessment.txt") }

        before { result }

        it "creates an activity entry" do
          expect(activity_entry.metadata).to eql({
            "risk_assessment_id" => risk_assessment.id,
            "updates" => {
              "filename" => ["old_risk_assessment.txt", "new_risk_assessment.txt"],
            }
          })
        end
      end
    end
  end
end
