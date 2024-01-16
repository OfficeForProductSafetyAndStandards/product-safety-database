RSpec.describe "Validate risk level", type: :request, with_stubbed_mailer: true, with_stubbed_opensearch: true do
  let(:user) { create(:user, :activated) }
  let(:other_user) { create(:user, :activated) }

  let(:investigation) do
    create(
      :allegation,
      is_closed: false,
      creator: user
    )
  end

  let(:params) do
    {
      investigation: { is_risk_validated: true }
    }
  end

  context "when the user has the `risk_level_validator` role" do
    before do
      other_user.roles.create!(name: "risk_level_validator")
      sign_in other_user
      put investigation_risk_validations_url(investigation.pretty_id), params:
    end

    it "does not return a forbidden status code" do
      expect(response).not_to have_http_status(:forbidden)
    end
  end

  context "when the user does not have the `risk_level_validator` role" do
    before do
      sign_in other_user
      put investigation_risk_validations_url(investigation.pretty_id), params:
    end

    it "returns a forbidden status code" do
      expect(response).to have_http_status(:forbidden)
    end
  end
end
