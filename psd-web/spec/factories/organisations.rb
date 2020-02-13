FactoryBot.define do
  factory :organisation do
    id { SecureRandom.uuid }
    name { "test organisation" }
    path { "/organisation/test" }
  end
end
