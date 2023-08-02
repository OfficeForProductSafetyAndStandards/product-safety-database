require "rails_helper"

RSpec.describe "Managing documents attached to a case", :with_stubbed_mailer, :with_errors_rendered, type: :request do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:other_user) { create(:user) }
  let(:investigation) { create(:allegation, :with_document, creator: case_creator) }
  let(:case_creator) { user }
  let(:document) { investigation.documents.first }
  let(:empty_params) do
    {
      document: {
        title: ""
      }
    }
  end

  before { sign_in(user) }

  context "when adding an attachment to a case" do
    before { get new_investigation_document_path(investigation) }

    context "when the user is a collaborator on the case" do
      it "renders the form" do
        expect(response).to render_template(:new)
      end
    end

    context "when the user is not a collaborator on the case" do
      let(:case_creator) { other_user }

      it "renders an error" do
        expect(response).to render_template("errors/forbidden")
      end

      it "returns a forbidden status code" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "when submitting the form to add an attachment to a case" do
    before { post investigation_documents_path(investigation), params: empty_params }

    context "when the user is a collaborator on the case" do
      it "renders the form with validation errors" do
        expect(response).to render_template(:new)
      end
    end

    context "when the user is not a collaborator on the case" do
      let(:case_creator) { other_user }

      it "renders an error" do
        expect(response).to render_template("errors/forbidden")
      end

      it "returns a forbidden status code" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "when editing an attachment on a case" do
    before { get edit_investigation_document_path(investigation, document) }

    context "when the user is a collaborator on the case" do
      it "renders the form" do
        expect(response).to render_template(:edit)
      end
    end

    context "when the user is not a collaborator on the case" do
      let(:case_creator) { other_user }

      it "renders an error" do
        expect(response).to render_template("errors/forbidden")
      end

      it "returns a forbidden status code" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "when submitting the form to update an attachment on a case" do
    before { patch investigation_document_path(investigation, document), params: empty_params }

    context "when the user is a collaborator on the case" do
      it "renders the form with validation errors" do
        expect(response).to render_template(:edit)
      end
    end

    context "when the user is not a collaborator on the case" do
      let(:case_creator) { other_user }

      it "renders an error" do
        expect(response).to render_template("errors/forbidden")
      end

      it "returns a forbidden status code" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "when removing an attachment from a case" do
    before { get remove_investigation_document_path(investigation, document) }

    context "when the user is a collaborator on the case" do
      it "renders the form" do
        expect(response).to render_template(:remove)
      end
    end

    context "when the user is not a collaborator on the case" do
      let(:case_creator) { other_user }

      it "renders an error" do
        expect(response).to render_template("errors/forbidden")
      end

      it "returns a forbidden status code" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "when submitting the form to remove an attachment from a case" do
    before { delete investigation_document_path(investigation, document) }

    context "when the user is a collaborator on the case" do
      it "redirects to the case supporting information page" do
        expect(response).to redirect_to(investigation_supporting_information_index_path(investigation))
      end
    end

    context "when the user is not a collaborator on the case" do
      let(:case_creator) { other_user }

      it "renders an error" do
        expect(response).to render_template("errors/forbidden")
      end

      it "returns a forbidden status code" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
