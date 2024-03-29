require "rails_helper"

RSpec.describe AddRiskAssessmentToNotification, :with_stubbed_mailer, :with_test_queue_adapter do
  let!(:notification) { create(:notification, creator:, owner_team: team, owner_user: nil) }
  let(:investigation_product) { create(:investigation_product) }

  let(:team) { create(:team) }
  let(:business) { create(:business) }

  let(:read_only_teams) { [team] }
  let(:user) { create(:user) }
  let(:creator) { user }
  let(:owner) { user }

  context "with no parameters" do
    let(:result) { described_class.call }

    it "returns a failure" do
      expect(result).to be_failure
    end
  end

  context "with no user parameter" do
    let(:result) { described_class.call(notification:) }

    it "returns a failure" do
      expect(result).to be_failure
    end
  end

  context "with no notification parameter" do
    let(:result) { described_class.call(user:) }

    it "returns a failure" do
      expect(result).to be_failure
    end
  end

  context "with required parameters" do
    def expected_email_subject
      "Notification updated"
    end

    def expected_email_body(name)
      "Risk assessment was added to the notification by #{name}."
    end

    let(:assessment_date) { Time.zone.today }

    let(:result) do
      described_class.call(
        user:,
        notification:,
        assessed_on: assessment_date,
        assessed_by_other: "RiskAssessmentsRUs",
        investigation_product_ids: [investigation_product.id],
        risk_level: :serious
      )
    end

    it "succeeds" do
      expect(result).to be_a_success
    end

    it "adds a risk assessment to the case with the supplied attributes", :aggregate_failures do
      result
      risk_assessment = notification.risk_assessments.first

      expect(risk_assessment.assessed_on).to eq assessment_date
      expect(risk_assessment.assessed_by_other).to eq "RiskAssessmentsRUs"
      expect(risk_assessment.risk_level).to eq "serious"
      expect(risk_assessment.investigation_products).to eq [investigation_product]
    end

    it "associates the added risk assessment with the user and their team", :aggregate_failures do
      result
      risk_assessment = notification.risk_assessments.first

      expect(risk_assessment.added_by_user).to eq user
      expect(risk_assessment.added_by_team).to eq user.team
    end

    it "adds an audit activity record", :aggregate_failures do
      result
      last_added_activity = notification.activities.order(:id).first

      expect(last_added_activity).to be_a(AuditActivity::RiskAssessment::RiskAssessmentAdded)
      expect(last_added_activity.added_by_user_id).to eql(user.id)
      expect(last_added_activity.metadata).to be_present

      expect(last_added_activity.decorate.title(nil)).to eql("Risk assessment")
    end

    it_behaves_like "a service which notifies the notification owner"
  end
end
