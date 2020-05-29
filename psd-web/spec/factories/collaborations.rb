FactoryBot.define do
  factory :collaboration, class: "Collaboration" do
    include_message { "false" }
    association :investigation, factory: :allegation
    association :collaborator, factory: :team
    association :added_by_user, factory: :user

    factory :collaboration_edit_access, parent: :collaboration, class: "Collaboration::EditAccess"
  end
end
