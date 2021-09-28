class UpdateBusinessRelationship
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :investigation_business, :relationship, :relationship_other, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      investigation_business.assign_attributes(relationship: calculate_relationship)

      break if no_changes?

      investigation_business.save!

      # create_audit_activity
      # send_notification_email
    end
  end

private

  def calculate_relationship
    if relationship == "other"
      relationship_other
    else
      relationship
    end
  end

  def no_changes?
    !investigation_business.changed?
  end
end
