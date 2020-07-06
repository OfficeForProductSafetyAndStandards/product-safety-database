require "rails_helper"

RSpec.describe InvestigationActionsForm, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  describe "validations" do
    context "when an action has been set" do
      let(:form) { described_class.new(investigation_action: "change_case_status") }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "when no action has been set" do
      let(:form) { described_class.new(investigation_action: nil) }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end
  end

  describe "#actions" do
    context "when the user is the owner of the investigation but not an OPSS user" do
      let(:user) { create(:user, :activated) }
      let(:investigation) { create(:allegation, creator: user) }
      let(:form) { described_class.new(investigation: investigation, current_user: user) }

      it "contains three possible actions" do
        expect(form.actions).to eq({
          change_case_status: "Close case",
          change_case_owner: "Change case owner",
          change_case_visibility: "Restrict this case"
        })
      end
    end

    context "when the case is closed and restricted" do
      let(:user) { create(:user, :activated) }
      let(:investigation) do
        create(:allegation, :restricted, :closed, creator: user)
      end
      let(:form) { described_class.new(investigation: investigation, current_user: user) }

      it "contains three actions with alternative labels" do
        expect(form.actions).to eq({
          change_case_status: "Reopen case",
          change_case_owner: "Change case owner",
          change_case_visibility: "Unrestrict this case"
        })
      end
    end

    context "when the user is the owner of the investigation and is an OPSS user" do
      let(:user) { create(:user, :activated, :opss_user) }
      let(:investigation) { create(:allegation, creator: user) }
      let(:form) { described_class.new(investigation: investigation, current_user: user) }

      it "contains four possible actions" do
        expect(form.actions).to eq({
          change_case_status: "Close case",
          change_case_owner: "Change case owner",
          change_case_visibility: "Restrict this case",
          send_email_alert: "Send email alert"
        })
      end
    end

    context "when the user is not involved with the investigation but is an OPSS user" do
      let(:user) { create(:user, :activated, :opss_user) }
      let(:investigation) { create(:allegation) }
      let(:form) { described_class.new(investigation: investigation, current_user: user) }

      it "contains only the 'send email alert' action" do
        expect(form.actions).to eq({ send_email_alert: "Send email alert" })
      end
    end

    context "when the user is not involved with the investigation and is not an OPSS user" do
      let(:user) { create(:user, :activated) }
      let(:investigation) { create(:allegation) }
      let(:form) { described_class.new(investigation: investigation, current_user: user) }

      it "contains no actions" do
        expect(form.actions).to eq({})
      end
    end
  end
end
