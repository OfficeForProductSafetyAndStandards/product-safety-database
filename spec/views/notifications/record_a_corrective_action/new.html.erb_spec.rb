require "rails_helper"

RSpec.describe "notifications/record_a_corrective_action/new", type: :view do
  let(:notification) { build_stubbed(:notification) }
  let(:corrective_action_form) { CorrectiveActionForm.new }

  before do
    assign(:notification, notification)
    assign(:corrective_action_form, corrective_action_form)

    without_partial_double_verification do
      allow(view).to receive(:notification_add_record_a_corrective_action_path).and_return("/path")
      allow(view).to receive(:render).with(any_args).and_call_original
      allow(view).to receive(:render).with("investigations/corrective_actions/form", any_args).and_return("Corrective action form rendered")
      allow(view).to receive(:render).with("related_attachment_fields", any_args).and_return("Attachment fields rendered")
    end

    render
  end

  it "displays the correct heading" do
    expect(rendered).to have_css("h1.govuk-heading-l", text: "Record a corrective action")
  end

  it "displays the notification title" do
    expect(rendered).to have_css("span.govuk-caption-l", text: notification.user_title)
  end

  it "includes a form with the correct action" do
    expect(rendered).to have_css("form[action='/path'][method='post']")
  end

  it "renders the corrective action form partial" do
    expect(rendered).to include("Corrective action form rendered")
  end

  it "renders the related attachment fields" do
    expect(rendered).to include("Attachment fields rendered")
  end

  it "has a submit button with the correct text" do
    expect(rendered).to have_css("button.govuk-button", text: "Record a corrective action")
  end

  it "includes a file upload section" do
    expect(rendered).to have_css("fieldset", text: /Are there any files related to the action?/)
  end

  it "has Yes/No radio buttons for file upload" do
    expect(rendered).to have_field("corrective_action[related_file]", type: "radio", with: "true")
    expect(rendered).to have_field("corrective_action[related_file]", type: "radio", with: "false")
  end
end
