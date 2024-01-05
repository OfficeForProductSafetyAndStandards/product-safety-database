require "rails_helper"

RSpec.describe AddTeamToNotificationForm, :with_stubbed_mailer do
  subject(:form) { described_class.new(team_id:, message:, include_message:, permission_level:) }

  let(:team) { create(:team) }

  let(:team_id) { team.id }
  let(:message) { "Test message" }
  let(:include_message) { "true" }
  let(:permission_level) { "edit" }

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

    context "with no permission_level" do
      let(:permission_level) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with invalid permission_level" do
      let(:permission_level) { "invalid" }

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

  describe "#collaboration_class" do
    it "returns the corresponding access class" do
      expect(form.collaboration_class).to eq(Collaboration::Access::Edit)
    end
  end
end
