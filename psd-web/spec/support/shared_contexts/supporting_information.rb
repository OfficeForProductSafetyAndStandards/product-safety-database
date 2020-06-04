RSpec.shared_context "with all types of supporting information", :with_stubbed_antivirus do
  let!(:corrective_action) { create(:corrective_action, :with_file, owner_id: user.id, investigation: investigation) }
  let!(:email)             { create(:correspondence_email,      investigation: investigation) }
  let!(:phone_call)        { create(:correspondence_phone_call, investigation: investigation) }
  let!(:meeting)           { create(:correspondence_meeting,    investigation: investigation) }

  let(:product)            { create(:product) }
  let!(:test_request)      { create(:test_request, product: product, investigation: investigation) }
  let!(:test_result)       { create(:test_result, product: product, investigation: investigation) }
end
