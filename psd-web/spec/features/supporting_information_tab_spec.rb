require "rails_helper"

RSpec.feature "Manage Images", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:investigation, owner: user.team) }
  let(:file)          { Rails.root + "test/fixtures/files/testImage.png" }
  let(:title)         { Faker::Lorem.sentence }
  let(:description)   { Faker::Lorem.paragraph }

  let!(:corrective_action_with_file) { create(:corrective_action, :with_file, owner_id: user.id, investigation: investigation) }
  let!(:corrective_action_without_file) { create(:corrective_action, investigation: investigation) }

  before { sign_in user }

  scenario "completing the add attachment flow saves the attachment" do
    visit "/cases/#{investigation.pretty_id}"

    click_link "Supporting information"

    save_and_open_page

    expect(page).to have_css("h2", text: corrective_action_with_file.documents.first.title)
    expect(page).not_to have_css("h2", text: corrective_action_without_file.title)
  end
end
