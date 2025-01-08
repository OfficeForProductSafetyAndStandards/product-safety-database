require "rails_helper"

RSpec.describe "Terms and conditions page", type: :request do
  context "when signed in" do
    before do
      sign_in(user)
      get help_terms_and_conditions_path
    end

    context "when signed in as a non-OPSS user, having not accepted to the declaration or viewed the introduction" do
      let(:user) { create(:user, has_accepted_declaration: false, has_viewed_introduction: false) }

      it "renders the template" do
        expect(response).to render_template(:terms_and_conditions)
      end
    end

    context "when signed in as a non-OPSS user, having accepted the declaration but not yet viewed the introduction" do
      let(:user) { create(:user, has_accepted_declaration: true, has_viewed_introduction: false) }

      it "renders the template" do
        expect(response).to render_template(:terms_and_conditions)
      end
    end

    context "when signed in as an OPSS user, having not yet accepted the declaration" do
      let(:user) { create(:user, :opss_user, has_accepted_declaration: false) }

      it "renders the template" do
        expect(response).to render_template(:terms_and_conditions)
      end
    end
  end

  context "when not signed in" do
    before do
      get help_terms_and_conditions_path
    end

    it "renders the template" do
      expect(response).to render_template(:terms_and_conditions)
    end
  end
end
