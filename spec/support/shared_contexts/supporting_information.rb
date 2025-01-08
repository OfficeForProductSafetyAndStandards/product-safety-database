RSpec.shared_context "with all types of supporting information", :with_stubbed_antivirus do
  # rubocop:disable RSpec/LetSetup
  let!(:corrective_action) { create(:corrective_action, :with_file, action: "other", other_action: "Corrective action", owner_id: user.id, investigation:).decorate }
  let!(:email)             { create(:email, overview: "Email correspondence", investigation:).decorate }
  let!(:phone_call)        { create(:correspondence_phone_call, overview: "Phone call correspondence", investigation:, correspondence_date: 14.days.ago).decorate }

  let(:investigation_product) { create(:investigation_product) }
  let!(:test_request)         { create(:test_request, investigation_product:, investigation:).decorate }
  let!(:test_result)          { create(:test_result, investigation_product:, investigation:, result: :passed).decorate }
  # rubocop:enable RSpec/LetSetup
end
