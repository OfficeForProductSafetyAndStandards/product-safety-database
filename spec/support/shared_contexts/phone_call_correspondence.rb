RSpec.shared_context "phone call correspondence setup" do
  include ActionDispatch::TestProcess::FixtureFile

  let(:user)                { create :user }
  let(:investigation)       { create :allegation }
  let(:phone_number)        { Faker::PhoneNumber.phone_number }
  let(:correspondence_date) { Date.parse("1-1-2020") }
  let(:correspondent_name)  { Faker::Name.name }
  let(:overview)            { Faker::Hipster.paragraph }
  let(:details)             { Faker::Hipster.paragraph }
  let(:transcript)          { Rack::Test::UploadedFile.new(file_fixture("files/phone_call_transcript.txt")) }

  let(:params) do
    {
      transcript: transcript,
      correspondence_date: correspondence_date,
      phone_number: phone_number,
      correspondent_name: correspondent_name,
      overview: overview,
      details: details
    }
  end
end
