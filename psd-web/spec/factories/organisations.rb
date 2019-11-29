FactoryBot.define do
  factory :organisation do
    id { SecureRandom.uuid }
    name { "test" }
    path { "/test/test" }
  end
end
