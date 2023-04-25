require "rails_helper"

RSpec.describe "User accepting declaration", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  context "with no parameters" do
    before { post declaration_accept_path }

    it "renders the index template again" do
      expect(response).to render_template(:index)
    end

    it "renders an error" do
      expect(response.body).to include("You must agree to the declaration to use this service")
    end
  end

  context "with the agree checkbox checked" do
    let(:params) { { agree: "checked" } }

    before { allow(UserDeclarationService).to receive(:accept_declaration) }

    it "calls UserDeclarationService.accept_declaration" do
      post(declaration_accept_path, params:)
      expect(UserDeclarationService).to have_received(:accept_declaration).with(user)
    end

    it "redirects the user to root_path" do
      post(declaration_accept_path, params:)
      expect(response).to redirect_to(authenticated_root_path)
    end
  end
end
