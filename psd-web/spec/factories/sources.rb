FactoryBot.define do
  factory :source do
    name { "source name" }
    association :user
  end
  factory :user_source, class: "UserSource" do
    user { create(:user, :psd_user) }
  end
end
