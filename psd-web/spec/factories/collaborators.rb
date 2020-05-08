FactoryBot.define do
  factory :collaborator do
    include_message { "false" }
    association :investigation, factory: :investigation
    association :collaborating, factory: :team
    association :added_by_user, factory: :user

    factory :case_creator, class: "CaseCreator" do
    end
  end
end
