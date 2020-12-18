FactoryBot.define do
  factory :audit_activity_test_result, class: "AuditActivity::Test::Result" do
    title { Faker::Hipster.word }
    investigation
    product
  end

  factory :legacy_audit_activity_test_result, class: "AuditActivity::Test::Result" do
    title { Faker::Hipster.word }
    metadata { nil }
    investigation
    product
  end
end
