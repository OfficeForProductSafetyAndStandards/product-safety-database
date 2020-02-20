require "rails_helper"

RSpec.describe "Password reset management" do
  let(:user) { create(:user) }

  it "allows you to reset your password" do
    visit sign_in_path
  end
end
