require "rails_helper"

RSpec.describe "Business page", type: :request, with_stubbed_mailer: true do
  let(:user) { create(:user, :activated) }

  it "does not raise an error with a page value > 500" do
    sign_in user
    expect { get "/business?page=501" }.not_to raise_error
  end
end
