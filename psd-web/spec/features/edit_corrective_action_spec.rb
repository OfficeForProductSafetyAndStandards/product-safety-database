require "rails_helper"

RSpec.feature "Edit corrective action", :with_stubbed_elasticsearch, :with_stubbed_mailer do
  let(:user)              { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation)     { create(:allegation, creator: user) }
  let(:corrective_action) { create(:corrective_action, :with_file, investigation: investigation) }

  before { sign_in user }

  it "provides a mean to edit a corrective action" do
    visit "/cases/#{investigation.pretty_id}/corrective-actions/#{corrective_action.id}"

    click_link "Edit corrective action"
  end
end
