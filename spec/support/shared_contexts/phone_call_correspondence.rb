RSpec.shared_context "with phone call correspondence setup" do
  include ActionDispatch::TestProcess::FixtureFile

  let(:team_recipient_email) { Faker::Internet.email }
  let(:team)                 { create :team, team_recipient_email: }
  let(:user)                 { create :user, :activated, team: }
  let(:investigation)        { create :allegation, creator: user || create(:user) }
  let(:phone_number)         { Faker::PhoneNumber.phone_number }
  let(:correspondence_date)  { Date.parse("1-1-2020") }
  let(:correspondent_name)   { Faker::Name.name }
  let(:overview)             { Faker::Hipster.paragraph }
  let(:details)              { Faker::Hipster.paragraph }
  let(:transcript)           { Rack::Test::UploadedFile.new(file_fixture("phone_call_transcript.txt")) }

  let(:params) do
    {
      transcript:,
      correspondence_date:,
      phone_number:,
      correspondent_name:,
      overview:,
      details:,
      "correspondence_date(1i)" => "2020",
      "correspondence_date(2i)" => "1",
      "correspondence_date(3i)" => "1",
    }
  end

  let(:new_correspondent_name)  { Faker::Movies::Hobbit.character }
  let(:new_phone_number)        { Faker::PhoneNumber.phone_number }
  let(:new_correspondence_date) { 2.days.ago.to_date }
  let(:new_overview)            { Faker::Hipster.sentence }
  let(:new_details)             { Faker::Hipster.sentence }
  let(:new_transcript)          { file_fixture("new_phone_call_transcript.txt") }
end
