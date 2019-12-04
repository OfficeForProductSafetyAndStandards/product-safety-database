FactoryBot.define do
  factory :organisation do
    id { SecureRandom.uuid }
    name { "test organisation" }
    path { "/test/test" }
  end
end
