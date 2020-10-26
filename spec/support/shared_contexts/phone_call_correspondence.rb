RSpec.shared_context "with phone call correspondence setup" do
  include ActionDispatch::TestProcess::FixtureFile

  let(:team_recipient_email) { Faker::Internet.safe_email }
  let(:team)                 { create :team, team_recipient_email: team_recipient_email }
  let(:user)                 { create :user, :activated, team: team }
  let(:investigation)        { create :allegation, creator: user || create(:user) }
  let(:phone_number)         { Faker::PhoneNumber.phone_number }
  let(:correspondence_date)  { Date.parse("1-1-2020") }
  let(:correspondent_name)   { Faker::Name.name }
  let(:overview)             { Faker::Hipster.paragraph }
  let(:details)              { Faker::Hipster.paragraph }
  let(:transcript)           { Rack::Test::UploadedFile.new(file_fixture("files/phone_call_transcript.txt")) }

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

  let(:new_correspondent_name)  { Faker::Movies::Hobbit.character }
  let(:new_phone_number)        { Faker::PhoneNumber.phone_number }
  let(:new_correspondence_date) { 2.days.ago.to_date }
  let(:new_overview)            { Faker::Hipster.sentence }
  let(:new_details)             { Faker::Hipster.sentence }
  let(:new_transcript)          { file_fixture("files/new_phone_call_transcript.txt") }
end
