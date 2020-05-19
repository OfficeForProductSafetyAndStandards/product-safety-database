FactoryBot.define do
  factory :collaboration, class: 'Collaboration' do
    include_message { "false" }
    association :investigation, factory: :investigation
    association :collaborator, factory: :team
    association :added_by_user, factory: :user

    factory :edition, parent: :collaboration, class: 'Edition' do
    end
  end
end
