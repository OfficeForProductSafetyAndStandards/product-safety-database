class ChangeCaseStatus
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :new_status, :rationale, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No status supplied") if new_status.nil?
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    investigation.is_closed = closed?
    investigation.date_closed = closed? ? Time.zone.now : nil

    return if investigation.changes.none?

    ActiveRecord::Base.transaction do
      investigation.save!
      if closed?
        mark_investigation_products_as_closed
        handle_product_ownership_changes
      end

      create_audit_activity_for_case_status_changed
    end

    investigation.reload.products.each do |product|
      product.reload.__elasticsearch__.update_document
    end

    investigation.businesses.each do |business|
      business.reload.__elasticsearch__.update_document
    end

    send_notification_email
  end

private

  def create_audit_activity_for_case_status_changed
    metadata = activity_class.build_metadata(investigation, rationale)

    activity_class.create!(
      added_by_user: user,
      investigation:,
      title: nil,
      body: nil,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateStatus
  end

  def send_notification_email
    email_recipients.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        email_body(recipient),
        email_subject
      ).deliver_later
    end
  end

  def email_recipients
    (email_recipients_for_case_owner + email_recipients_for_case_creator).uniq
  end

  def email_subject
    I18n.t("change_case_status.email_subject_text", case_type: email_case_type, status: email_status)
  end

  def email_body(viewer = nil)
    user_name = user.decorate.display_name(viewer:)
    I18n.t(
      "change_case_status.#{email_update_text_key}",
      case_type: email_case_type,
      name: user_name
    )
  end

  def email_case_type
    investigation.case_type.upcase_first
  end

  def closed?
    new_status == "closed"
  end

  def email_status
    closed? ? "closed" : "re-opened"
  end

  def number_of_other_team_investigation_linked_to_product(product)
    product.investigation_products.where(investigation_closed_at: nil).map(&:investigation).count { |investigation| investigation.owner_team == user.team }
  end

  def handle_product_ownership_changes
    investigation.products.each do |product|
      next if product.owning_team_id != user.team.id || number_of_other_team_investigation_linked_to_product(product).positive?

      product.update!(owning_team_id: nil)
    end
  end

  def mark_investigation_products_as_closed
    investigation.investigation_products.where(investigation_closed_at: nil).update_all(investigation_closed_at: investigation.date_closed)
  end

  def email_update_text_key
    closed? ? "email_update_text_closed" : "email_update_text_reopened"
  end
end
