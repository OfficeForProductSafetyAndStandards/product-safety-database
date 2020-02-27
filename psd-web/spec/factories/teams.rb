FactoryBot.define do
  factory :team do
    name { "test team" }
    team_recipient_email { "test@example.com" }
    organisation
  end
end
