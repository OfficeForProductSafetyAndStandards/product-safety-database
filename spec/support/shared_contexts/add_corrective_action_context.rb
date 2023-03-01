RSpec.shared_context "with add corrective action setup" do
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product_washing_machine, name: "MyBrand Washing Machine") }
  let(:products) { [product] }
  let(:investigation) { create(:allegation, :with_business, products:, creator: user, read_only_teams: read_only_team) }
  let(:investigation_product) { investigation.investigation_products.first }
  let(:business) { investigation.businesses.first }
  let(:action_key) { (CorrectiveAction.actions.keys - %w[other]).sample }
  let(:action) { CorrectiveAction.actions[action_key] }
  let(:date_decided) { Date.parse("2020-05-01") }
  let(:legislation) { "General Product Safety Regulations 2005" }
  let(:has_online_recall_information) { "has_online_recall_information_yes" }
  let(:online_recall_information) { Faker::Internet.url(host: "example.com") }
  let(:details) { "Urgent action following consumer reports" }
  let(:file) { Rails.root.join "test/fixtures/files/old_risk_assessment.txt" }
  let(:file_description) { Faker::Lorem.paragraph }
  let(:measure_type) { "Mandatory" }
  let(:duration) { "Permanent" }
  let!(:geographic_scopes_last_index) { rand(CorrectiveAction::GEOGRAPHIC_SCOPES.size - 1) }
  let(:geographic_scopes) do
    CorrectiveAction::GEOGRAPHIC_SCOPES[0..geographic_scopes_last_index]
  end
  let(:other_action) { "" }
  let(:action_for_form) { CorrectiveAction.actions[action_key] }

  let(:corrective_action_form) do
    CorrectiveActionForm.new(
      business_id: business.id,
      investigation_product_id: investigation_product.id,
      action: action_key,
      other_action:,
      date_decided:,
      legislation:,
      has_online_recall_information:,
      online_recall_information:,
      details:,
      measure_type:,
      duration:,
      geographic_scopes:,
      file: {
        file: Rack::Test::UploadedFile.new(file),
        description: file_description,
      }
    )
  end
end
