require "rails_helper"

RSpec.describe "Changing case summary", :with_stubbed_mailer, :with_errors_rendered, type: :request do
  let(:user) { create(:user, :activated) }

  it "allows users to go past page 500" do
    sign_in user
    get "/cases?page=501"
    expect(response.code).to eq "200"
  end
end
