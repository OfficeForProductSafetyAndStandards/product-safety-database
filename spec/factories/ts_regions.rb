FactoryBot.define do
  factory :region do
    name { Faker::Address.state }
    acronym { Faker::Address.state_abbr }
  end
end
