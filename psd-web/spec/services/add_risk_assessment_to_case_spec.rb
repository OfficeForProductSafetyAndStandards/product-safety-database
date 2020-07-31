require "rails_helper"

RSpec.describe AddRiskAssessmentToCase, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  # Create the case before running tests so that we can check which emails are sent by the service
  let!(:investigation) { create(:allegation, creator: creator, read_only_teams: read_only_teams) }
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

      context "when the team has an email address" do
        it "notifies the team", :aggregate_failures do
          result
          email = delivered_emails.last
          expect(email.recipient).to eq(team.email)
          expect(email.action_name).to eq("investigation_updated")
        end
      end

      context "when the team does not have an email address" do
        let(:team) { create(:team, team_recipient_email: nil) }
        let!(:active_team_user) { create(:user, :activated, team: team, organisation: team.organisation) }
        let!(:inactive_team_user) { create(:user, :inactive, team: team, organisation: team.organisation) }

        before { result }

        it "notifies the team's activated users", :aggregate_failures do
          email = delivered_emails.last
          expect(email.recipient).to eq(active_team_user.email)
          expect(email.action_name).to eq("investigation_updated")
        end

        it "does not notify the team's inactive users" do
          expect(delivered_emails.collect(&:recipient)).not_to include(inactive_team_user.email)
        end
      end

      it "adds an audit activity record", :aggregate_failures do
        result
        last_added_activity = investigation.activities.order(:id).first

        expect(last_added_activity).to be_a(AuditActivity::RiskAssessment::RiskAssessmentAdded)
        expect(last_added_activity.source.user_id).to eql(user.id)
        expect(last_added_activity.metadata).to be_present

        expect(last_added_activity.decorate.title(nil)).to eql("Risk assessment")
      end
    end
  end
end
