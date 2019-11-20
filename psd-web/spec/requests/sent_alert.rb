require "rails_helper"

describe "Sending a product safety alert", type: :request, with_keycloak_config: true do
  let(:user) { create(:user, :activated, :opss_user) }
  let(:investigation) { create(:allegation) }

  before do
    create(:user, :activated)
    create(:user, :inactive)
    sign_in(as_user: user)

    # Don't need to generate preview for these tests. govuk_notify_rails throws an exception of no valid Notify key provided
    allow(Notifications::Client).to receive(:new).and_return(nil)
    allow(NotificationsClient.instance).to receive(:generate_template_preview).and_return(OpenStruct.new(html: nil))

    get "/cases/#{investigation.pretty_id}/alerts/preview", params: { "alert[summary]" => "test", "alert[description]" => "test" }
  end

  it "shows the number of recipients the alert will be sent to" do
    expect(response.body).to match(/All users \(\d+ people\)/)
  end

  it "only includes active users" do
    expect(response.body.match(/All users \((\d+) people\)/).captures.first).to eq("2")
  end
end
