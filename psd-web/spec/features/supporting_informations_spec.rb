require "rails_helper"

RSpec.feature "Supporting informations", :with_stubbed_elasticsearch, :with_stubbed_mailer do
  let(:investigation) { create(:allegation, :with_antivirus_checked_document) }

  before { sign_in create(:user, :activated, has_viewed_introduction: true) }

  scenario "listing supporting informations" do
    visit "/cases/#{investigation.pretty_id}"

    click_on "Supporting informations (1)"

    save_and_open_page
  end
end
