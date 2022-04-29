require "rails_helper"

RSpec.feature "Case with unsafe image", :with_stubbed_opensearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:other_user) { create(:user, :activated, has_viewed_introduction: true, team: user.team) }
  let(:investigation) { create(:allegation, :with_image, creator: user) }

  before do
    blob = investigation.images.first.blob
    blob.update!(metadata: blob.metadata.merge({ safe: false, created_by: user.id }))
  end

  context "when user is the user that originally attached the image" do
    it "displays error alerting user that an attached image is not virus free and deletes offending images" do
      sign_in(user)
      visit investigation_images_path(investigation)

      expect(page).to have_error_summary "One or more images failed to upload. Image files must be virus free"
      expect(page).to have_selector("h2", text: investigation.images.first.title)

      visit investigation_images_path(investigation)

      expect(page).not_to have_error_summary "One or more images failed to upload. Image files must be virus free"
      expect(page).not_to have_selector("h2", text: investigation.images.first.title)
    end
  end

  context "when user is not the user that originally attached the image" do
    it "does not display the error or delete the image" do
      sign_in(other_user)
      visit investigation_images_path(investigation)

      expect(page).not_to have_error_summary "One or more images failed to upload. Image files must be virus free"
      expect(page).to have_selector("h2", text: investigation.images.first.title)

      visit investigation_images_path(investigation)

      expect(page).not_to have_error_summary "One or more images failed to upload. Image files must be virus free"
      expect(page).to have_selector("h2", text: investigation.images.first.title)
    end
  end
end
