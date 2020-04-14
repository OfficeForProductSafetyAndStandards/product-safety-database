require "rails_helper"

RSpec.describe "Managing a case’s coronavirus status", :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify, type: :request do
  let(:investigation) { create(:enquiry) }

  before { sign_in create(:user, :activated, has_accepted_declaration: true) }

  describe "a crafty user fiddles the HTML and sends an invalid value" do
    it "displays an error", :aggregate_failures do
      patch investigation_coronavirus_related_path(investigation), params: { investigation: { coronavirus_related: nil } }

      expect(response).to render_template(:show)
      expect(assigns(:investigation)).not_to be_valid
      expect(assigns(:investigation).errors[:coronavirus_related]).to eq(["Select whether or not the case is related to the coronavirus outbreak"])
    end
  end

  context "when submitting the same value" do
    it "does not create an audit log", :aggregate_failures do
      expect {
        patch investigation_coronavirus_related_path(investigation), params: { investigation: { coronavirus_related: investigation.coronavirus_related } }
      }.not_to(change { investigation.reload.activities.where(type: "AuditActivity::Investigation::UpdateCoronavirusStatus").count })
      expect(response).to redirect_to(investigation_path(investigation))
      expect(flash[:success]).to be nil
    end
  end

  context "when changing the value" do
    it "creates an audit log", :aggregate_failures do
      expect {
        patch investigation_coronavirus_related_path(investigation), params: { investigation: { coronavirus_related: !investigation.coronavirus_related } }
      }.to(change { investigation.reload.activities.where(type: "AuditActivity::Investigation::UpdateCoronavirusStatus").count }.by(1))
      expect(response).to redirect_to(investigation_path(investigation))
      expect(flash[:success]).to eq("#{investigation.case_type.titleize} was successfully updated.")
    end
  end
end
