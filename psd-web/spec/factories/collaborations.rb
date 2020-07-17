FactoryBot.define do
  factory :collaboration, class: "Collaboration" do
    association :investigation, factory: :allegation
    association :collaborator, factory: :team

    factory :collaboration_edit_access, parent: :collaboration, class: "Collaboration::Access::Edit" do
      association :added_by_user, factory: :user
    end
    factory :read_only_collaboration, parent: :collaboration, class: "Collaboration::Access::ReadOnly"
  end
end
