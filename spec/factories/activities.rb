FactoryBot.define do
  factory :audit_activity_test_result, class: "AuditActivity::Test::Result" do
    title { Faker::Hipster.word }
    investigation
    product
  end
end
