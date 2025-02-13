FactoryBot.define do
  factory :supporting_document_notification, class: "Investigation::Notification" do
    sequence(:pretty_id) { |n| "2502-#{n.to_s.rjust(4, '0')}" }
    association :creator_user, factory: :user
    association :owner_team, factory: :team
    association :creator_team, factory: :team
  end
end
