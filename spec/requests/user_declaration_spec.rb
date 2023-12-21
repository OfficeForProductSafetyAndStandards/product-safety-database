require "rails_helper"

RSpec.describe "User accepting declaration", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  context "with the agree checkbox not checked" do
    let(:params) { { "declaration_form[agree]": "0" } }

    before { post declaration_accept_path(params:) }

    it "renders the index template again" do
      expect(response).to render_template(:index)
    end

    it "renders an error" do
      expect(response.body).to include("You must agree to the declaration to use this service")
    end
  end

  context "with the agree checkbox checked" do
    let(:params) { { "declaration_form[agree]": "1" } }

    before do
      allow(UserDeclarationService).to receive(:accept_declaration)
      post declaration_accept_path(params:)
    end

    it "calls UserDeclarationService.accept_declaration" do
      expect(UserDeclarationService).to have_received(:accept_declaration).with(user)
    end

    it "redirects the user to root_path" do
      expect(response).to redirect_to(authenticated_root_path)
    end
  end
end
