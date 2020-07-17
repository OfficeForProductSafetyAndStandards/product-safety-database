require "rails_helper"

RSpec.describe AddTeamToCaseForm, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:form) { described_class.new(team_id: team_id, message: message, include_message: include_message) }

  let(:team) { create(:team) }

  let(:team_id) { team.id }
  let(:message) { "Test message" }
  let(:include_message) { "true" }

  describe "validations" do
    context "with valid params" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with no team_id" do
      let(:team_id) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with include_message and no message" do
      let(:message) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end
  end

  describe "#team" do
    it "returns the Team object" do
      expect(form.team).to eq(team)
    end
  end
end
