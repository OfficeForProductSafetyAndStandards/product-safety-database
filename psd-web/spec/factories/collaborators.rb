FactoryBot.define do
  factory :collaborator do
    include_message { "false" }
    association :investigation, factory: :investigation
    association :team, factory: :team
    association :added_by_user, factory: :user
  end
end
