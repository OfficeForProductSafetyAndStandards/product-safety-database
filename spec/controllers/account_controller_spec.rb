require "rails_helper"

RSpec.describe AccountController, type: :controller do
  describe "GET #show" do
    it "returns a successful response" do
      user = create(:user, has_accepted_declaration: true, has_viewed_introduction: true)
      sign_in user

      get :show
      puts response.status
      puts response.location if response.redirect?
      puts response.body

      expect(response).to be_successful
    end
  end
end
