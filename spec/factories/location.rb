FactoryBot.define do
  factory :location do
    association :business

    name { "Registered office" }
  end
end
