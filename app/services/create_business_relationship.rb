class CreateBusinessRelationship
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :business, :relationship, :relationship_other, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      InvestigationBusiness.create!(relationship: calculate_relationship, investigation_id: investigation.id, business_id: business.id)
    end

    create_audit_activity
    send_notification_email
  end

private

  def calculate_relationship
    if relationship == "other"
      relationship_other
    else
      relationship
    end
  end

  def create_audit_activity_for_business_added(business)
    AuditActivity::BusinessRelationship::Add.create!(
      investigation: investigation,
      source: UserSource.new(user: user),
      business: business,
      metadata: AuditActivity::BusinessRelationship::Add.build_metadata(business)
    )
  end
end
