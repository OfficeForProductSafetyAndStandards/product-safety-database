FactoryBot.define do
  factory :audit_activity_test_result, class: "AuditActivity::Test::Result" do
    title { Faker::Hipster.word }
    investigation
    investigation_product
  end

  factory :legacy_audit_activity_test_result, class: "AuditActivity::Test::Result" do
    title { Faker::Hipster.word }
    metadata { nil }
    investigation
    investigation_product
  end

  factory :legacy_audit_activity_corrective_action, class: "AuditActivity::CorrectiveAction::Base" do
    metadata { nil }
    investigation { create :allegation }
    investigation_product
  end

  factory :legacy_audit_add_activity_corrective_action, class: "AuditActivity::CorrectiveAction::Add", parent: :legacy_audit_activity_corrective_action
  factory :legacy_audit_update_activity_corrective_action, class: "AuditActivity::CorrectiveAction::Update", parent: :legacy_audit_activity_corrective_action

  factory :legacy_audit_investigation_update_status, class: "AuditActivity::Investigation::UpdateStatus" do
    investigation { create :allegation }
    title { "Allegation closed" }
  end

  factory :legacy_audit_business_remove_status, class: "AuditActivity::Business::Destroy" do
    investigation { create :allegation }
    business { create(:business) }
    title { "Removed: A business name" }
  end

  factory :legacy_audit_business_added_status, class: "AuditActivity::Business::Add" do
    investigation { create :allegation }
    business { create(:business) }
    title { "A business name" }
    body { "Role: **fulfillment\\_house**" }
  end

  factory :legacy_audit_product_destroyed, class: "AuditActivity::Product::Destroy" do
    investigation { create :allegation }
    investigation_product
    title { "Product removed from case" }
  end

  factory :legacy_audit_investigation_visibility_status, class: "AuditActivity::Investigation::UpdateVisibility" do
    investigation { create :allegation }
    title { "Allegation visibility\n            restricted" }
  end
end
