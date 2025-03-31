require "rails_helper"

RSpec.describe "notifications/record_a_corrective_action/edit", type: :view do
  let(:notification) { build_stubbed(:notification) }
  let(:corrective_action) { build_stubbed(:corrective_action) }
  let(:corrective_action_form) { CorrectiveActionForm.new }
  let(:file_blob) { nil }

  before do
    assign(:notification, notification)
    assign(:corrective_action, corrective_action)
    assign(:corrective_action_form, corrective_action_form)
    assign(:file_blob, file_blob)

    without_partial_double_verification do
      allow(view).to receive(:notification_edit_record_a_corrective_action_path).and_return("/path")
      allow(view).to receive(:render).with(any_args).and_call_original
      allow(view).to receive(:render).with("investigations/corrective_actions/form", any_args).and_return("Corrective action form rendered")
      allow(view).to receive(:render).with("related_attachment_fields", any_args).and_return("Attachment fields rendered")
    end

    render
  end

  it "displays the correct heading" do
    expect(rendered).to have_css("h1.govuk-heading-l", text: "Edit corrective action")
  end

  it "displays the notification title" do
    expect(rendered).to have_css("span.govuk-caption-l", text: notification.user_title)
  end

  it "includes a form with the correct action and method" do
    expect(rendered).to have_css("form[action='/path'][method='post']")
    expect(rendered).to have_css("input[name='_method'][value='put']", visible: false)
  end

  it "renders the corrective action form partial" do
    expect(rendered).to include("Corrective action form rendered")
  end

  it "includes a file upload field" do
    expect(rendered).to have_css("input[type='file'][name='corrective_action[document]']")
  end

  it "has a submit button with the correct text" do
    expect(rendered).to have_css("button.govuk-button", text: "Update corrective action")
  end

  it "includes a file upload section" do
    expect(rendered).to have_css("fieldset", text: /Are there any files related to the action?/)
  end

  it "has Yes/No radio buttons for file upload" do
    expect(rendered).to have_field("corrective_action[related_file]", type: "radio", with: "true")
    expect(rendered).to have_field("corrective_action[related_file]", type: "radio", with: "false")
  end

  context "when a file is attached" do
    let(:corrective_action_form) { CorrectiveActionForm.new(related_file: true) }
    let(:file_blob) { build_stubbed(:active_storage_blob) }

    before do
      allow(corrective_action_form).to receive_messages(document: true, related_file?: true)
      render
    end

    it "checks the Yes radio button" do
      expect(rendered).to have_field("corrective_action[related_file]", type: "radio", with: "true", checked: true)
    end

    it "shows 'Remove attached file' for the No option" do
      expect(rendered).to have_field("corrective_action[related_file]", type: "radio", with: "false")
      expect(rendered).to have_css("label", text: "Remove attached file")
    end
  end
end
