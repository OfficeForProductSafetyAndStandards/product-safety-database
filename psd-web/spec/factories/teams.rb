FactoryBot.define do
  factory :team do
    id { SecureRandom.uuid }
    name { "test team" }
    team_recipient_email { "test@example.com" }
    organisation
    path { "/team/test" }
  end
end
