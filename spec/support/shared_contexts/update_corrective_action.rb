RSpec.shared_context "with corrective action setup for updates", :with_stubbed_elasticsearch, :with_stubbed_mailer do
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
           investigation: investigation,
           product: product_one,
           business: business_one)
  end
  let(:new_summary)          { ((CorrectiveAction.actions.keys - %W[Other #{corrective_action.action}])).sample }
  let(:new_date_decided)     { corrective_action.date_decided - 1.day }
  let(:new_legislation)      { (Rails.application.config.legislation_constants["legislation"] - [corrective_action.legislation]).sample }
  let(:new_duration)         { (CorrectiveAction::DURATION_TYPES - [corrective_action.duration]).sample }
  let(:new_details)          { Faker::Lorem.sentence }
  let(:new_measure_type) do
    (CorrectiveAction::MEASURE_TYPES - [corrective_action.measure_type]).sample
  end
  let(:new_geographic_scope) do
    (Rails.application.config.corrective_action_constants["geographic_scope"] - [corrective_action.geographic_scope]).sample
  end
  let(:new_file_description) { "new corrective action file description" }
  let(:new_file) { fixture_file_upload(file_fixture("corrective_action.txt")) }
end
