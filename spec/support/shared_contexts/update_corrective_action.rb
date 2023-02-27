RSpec.shared_context "with corrective action setup for updates", :with_stubbed_opensearch, :with_stubbed_mailer do
  include ActionDispatch::TestProcess::FixtureFile

  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:product_one)   { create(:product) }
  let(:product_two)   { create(:product) }
  let(:business_one)  { create(:business) }
  let(:business_two)  { create(:business) }
  let(:investigation) do
    create(:allegation,
           creator: user,
           products: [product_one, product_two])
  end
  let(:corrective_action) do
    create(:corrective_action,
           :with_file,
           investigation:,
           investigation_product:,
           business: business_one,
           has_online_recall_information:)
  end
  let(:has_online_recall_information) { "has_online_recall_information_no" }
  let(:new_summary)          { ((CorrectiveAction.actions.keys - %W[other #{corrective_action.action}])).sample }
  let(:new_date_decided)     { corrective_action.date_decided - 1.day }
  let(:new_legislation)      { (Rails.application.config.legislation_constants["legislation"] - [corrective_action.legislation]).sample }
  let(:new_duration)         { (CorrectiveAction::DURATION_TYPES - [corrective_action.duration]).sample }
  let(:new_details)          { Faker::Lorem.sentence }
  let(:new_measure_type) do
    (CorrectiveAction::MEASURE_TYPES - [corrective_action.measure_type]).sample
  end
  let(:new_geographic_scopes) do
    CorrectiveAction::GEOGRAPHIC_SCOPES[0..]
  end
  let(:new_action) { CorrectiveAction.actions[new_summary] }
  let(:new_other_action) { Faker::Hipster.paragraph(sentence_count: 3) }
  let(:new_file_description) { "new corrective action file description" }
  let(:new_file) { fixture_file_upload("corrective_action.txt") }
  let(:new_document)                      { fixture_file_upload(file_fixture("corrective_action.txt")) }
  let(:new_has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_yes"] }
  let(:new_online_recall_information) { Faker::Internet.url(host: "example.com") }
  let(:existing_document_file_id) { nil }
  let(:related_file)              { false }
  let(:file_form)                 { { file: new_document, description: new_file_description } }

  let(:product)                   { create(:product) }
  let(:investigation_product)     { investigation.investigation_products.first }
  let(:business)                  { create(:business) }

  before { new_geographic_scopes }
end
