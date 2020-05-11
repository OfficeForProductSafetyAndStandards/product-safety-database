FactoryBot.define do
  factory :collaborator do
    include_message { "false" }
    association :collaborating, factory: :team
    association :added_by_user, factory: :user
  end

  factory :case_creator, class: "CaseCreator", parent: :collaborator
end
