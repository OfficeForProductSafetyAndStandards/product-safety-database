require "rails_helper"

RSpec.describe AddRiskAssessmentToCase, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_test_queue_adapter do
  # Create the case before running tests so that we can check which emails are sent by the service
  let!(:investigation) { create(:allegation, creator: creator, owner_team: team, owner_user: nil) }
  let(:product) { create(:product_washing_machine) }

  let(:team) { create(:team) }
  let(:business) { create(:business) }

  let(:read_only_teams) { [team] }
  let(:user) { create(:user) }
  let(:creator) { user }
  let(:owner) { user }

  describe ".call" do
    context "with no parameters" do
      let(:result) { described_class.call }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no user parameter" do
      let(:result) { described_class.call(investigation: investigation) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with no investigation parameter" do
      let(:result) { described_class.call(user: user) }

      it "returns a failure" do
        expect(result).to be_failure
      end
    end

    context "with required parameters" do
      def expected_email_subject
        "Allegation updated"
      end

      def expected_email_body(name)
        "Risk assessment was added to the #{investigation.case_type} by #{name}."
      end

      let(:assessment_date) { Time.zone.today }

      let(:result) do
        described_class.call(
          user: user,
          investigation: investigation,
          assessed_on: assessment_date,
          assessed_by_other: "RiskAssessmentsRUs",
          product_ids: [product.id],
          risk_level: :serious
        )
      end

      it "succeeds" do
        expect(result).to be_a_success
      end

      it "adds a risk assessment to the case with the supplied attributes", :aggregate_failures do
        result
        risk_assessment = investigation.risk_assessments.first

        expect(risk_assessment.assessed_on).to eq assessment_date
        expect(risk_assessment.assessed_by_other).to eq "RiskAssessmentsRUs"
        expect(risk_assessment.risk_level).to eq "serious"
        expect(risk_assessment.products).to eq [product]
      end

      it "associates the added risk assessment with the user and their team", :aggregate_failures do
        result
        risk_assessment = investigation.risk_assessments.first

        expect(risk_assessment.added_by_user).to eq user
        expect(risk_assessment.added_by_team).to eq user.team
      end

      it "adds an audit activity record", :aggregate_failures do
        result
        last_added_activity = investigation.activities.order(:id).first

        expect(last_added_activity).to be_a(AuditActivity::RiskAssessment::RiskAssessmentAdded)
        expect(last_added_activity.source.user_id).to eql(user.id)
        expect(last_added_activity.metadata).to be_present

        expect(last_added_activity.decorate.title(nil)).to eql("Risk assessment")
      end

      it_behaves_like "a service which notifies the case owner"
    end
  end
end
