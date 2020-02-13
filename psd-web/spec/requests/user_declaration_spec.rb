require "rails_helper"

RSpec.describe "User accepting declaration", type: :request, with_stubbed_keycloak_config: true do
  let(:user) { create(:user) }

  before { sign_in(user) }

  context "with no parameters" do
    before { post declaration_accept_path }

    it "renders the index template again with an error" do
      expect(response).to render_template(:index)
      expect(response.body).to include("You must agree to the declaration to use this service")
    end
  end

  context "with the agree checkbox checked" do
    let(:params) { { agree: "checked" } }

    it "calls UserDeclarationService.accept_declaration and redirects the user to root_path" do
      expect(UserDeclarationService).to receive(:accept_declaration).with(user)

      post declaration_accept_path, params: params

      expect(response).to redirect_to(root_path)
    end
  end
end
