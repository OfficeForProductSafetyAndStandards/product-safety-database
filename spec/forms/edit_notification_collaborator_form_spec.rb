require "rails_helper"

RSpec.describe EditNotificationCollaboratorForm, :with_opensearch, :with_stubbed_mailer do
  subject(:form) { described_class.new(params) }

  let!(:investigation) { create(:allegation, creator: user, edit_access_teams: [team]) }
  let(:user) { create(:user, :activated) }
  let(:team) { create(:team) }

  let(:collaboration) { investigation.edit_access_collaborations.last }
  let(:permission_level) { EditNotificationCollaboratorForm::PERMISSION_LEVEL_DELETE }
  let(:message) { "This is a message" }
  let(:include_message) { "true" }

  let(:params) do
    {
      permission_level:,
      message:,
      include_message:,
      collaboration:
    }
  end

  describe "validations" do
    context "with no collaboration" do
      let(:collaboration) { nil }

      it "is invalid" do
        expect(form).to be_invalid
      end
    end

    context "with no permission level" do
      let(:permission_level) { nil }

      it "is invalid" do
        expect(form).to be_invalid
      end
    end

    context "with invalid permission level" do
      let(:permission_level) { "invalid" }

      it "is invalid" do
        expect(form).to be_invalid
      end
    end

    context "with no change to the permission level" do
      let(:permission_level) { "edit" }

      it "is invalid" do
        expect(form).to be_invalid
      end
    end

    context "with no message option selected" do
      let(:include_message) { nil }

      it "is invalid" do
        expect(form).to be_invalid
      end
    end

    context "with message option checked but no message" do
      let(:include_message) { "true" }
      let(:message) { "" }

      it "is invalid" do
        expect(form).to be_invalid
      end
    end

    context "with valid options" do
      it "is valid" do
        expect(form).to be_valid
      end
    end
  end

  describe "#permission_level" do
    context "when permission_level is set" do
      it "returns the set level" do
        expect(form.permission_level).to eq(EditNotificationCollaboratorForm::PERMISSION_LEVEL_DELETE)
      end
    end

    context "when permission_level is not set" do
      let(:permission_level) { nil }

      it "returns the existing level" do
        expect(form.permission_level).to eq(Collaboration::Access::Edit.model_name.human)
      end
    end
  end

  describe "#delete?" do
    context "when permission_level is delete" do
      it "returns true" do
        expect(form).to be_delete
      end
    end

    context "when permission_level is a valid access level" do
      let(:permission_level) { Collaboration::Access::Edit.model_name.human }

      it "returns false" do
        expect(form).not_to be_delete
      end
    end
  end

  describe "#new_collaboration_class" do
    context "when permission_level is delete" do
      it "returns nil" do
        expect(form.new_collaboration_class).to be_nil
      end
    end

    context "when permission_level is a valid access level" do
      let(:permission_level) { Collaboration::Access::Edit.model_name.human }

      it "returns the corresponding access class" do
        expect(form.new_collaboration_class).to eq(Collaboration::Access::Edit)
      end
    end
  end
end
