require "rails_helper"

RSpec.feature "Adding and removing business to a case", :with_stubbed_mailer, :with_stubbed_opensearch do
  let(:user)             { create(:user, :activated) }
  let(:investigation)    { create(:enquiry, creator: user) }
  let(:other_user)       { create(:user, :activated) }

  before do
    ChangeCaseOwner.call!(investigation:, owner: user.team, user:)
  end

  # scenario "Adding a business" do
  #   # MOVED TO CYPRESS
  # end

  scenario "Not being able to add a business to another team's case" do
    sign_in other_user
    visit "/cases/#{investigation.pretty_id}/businesses"
    expect(page).not_to have_link("Add a business")
  end
end
