RSpec.shared_context "with add corrective action setup" do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:product) { create(:product_washing_machine, name: "MyBrand Washing Machine") }
  let(:investigation) { create(:allegation, :with_business, products: [product], creator: user, read_only_teams: read_only_team) }
  let(:business) { investigation.businesses.first }
  let(:action_key) { (CorrectiveAction.actions.keys - %w[other]).sample }
  let(:action) { CorrectiveAction.actions[action_key] }
  let(:date_decided) { Date.parse("2020-05-01") }
  let(:legislation) { "General Product Safety Regulations 2005" }
  let(:has_online_recall_information) { "has_online_recall_information_yes" }
  let(:online_recall_information) { Faker::Internet.url(host: "example.com") }
  let(:details) { "Urgent action following consumer reports" }
  let(:file) { Rails.root + "test/fixtures/files/old_risk_assessment.txt" }
  let(:file_description) { Faker::Lorem.paragraph }
  let(:measure_type) { "Mandatory" }
  let(:duration) { "Permanent" }
  let(:geographic_scope) { "National" }
  let(:other_action) { "" }
  let(:action_for_form) { CorrectiveAction.actions[action_key] }

  let(:corrective_action_form) do
    CorrectiveActionForm.new(
      business_id: business.id,
      product_id: product.id,
      action: action_key,
      other_action: other_action,
      date_decided: date_decided,
      legislation: legislation,
      has_online_recall_information: has_online_recall_information,
      online_recall_information: online_recall_information,
      details: details,
      measure_type: measure_type,
      duration: duration,
      geographic_scope: geographic_scope,
      file: {
        file: Rack::Test::UploadedFile.new(file),
        description: file_description,
      }
    )
  end
end
