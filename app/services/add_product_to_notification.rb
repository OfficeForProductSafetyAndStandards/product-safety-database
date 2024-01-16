class AddProductToNotification
  include Interactor
  include EntitiesToNotify

  delegate :notification,
           :user,
           :product,
           :skip_email,
           to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "No product supplied") unless product.is_a?(Product)
    context.fail!(error: "The product is retired") if product.retired?

    InvestigationProduct.transaction do
      (context.fail!(error: "The product is already linked to the notification") and return false) if duplicate_investigation_product
      notification.products << product
    end

    change_product_owner_if_unowned

    context.investigation_product = investigation_product
    context.activity = create_audit_activity_for_product_added

    send_notification_email unless skip_email
  end

private

  def change_product_owner_if_unowned
    product.update!(owning_team: notification.owner_team) if product.owning_team.nil?
  end

  def create_audit_activity_for_product_added
    AuditActivity::Product::Add.create!(
      added_by_user: user,
      investigation: notification,
      title: product.name,
      investigation_product:
    )
  end

  def send_notification_email
    return unless notification.sends_notifications?

    email_recipients_for_case_owner(notification).each do |recipient|
      NotifyMailer.notification_updated(
        notification.pretty_id,
        recipient.name,
        recipient.email,
        "Product was added to the notification by #{user.decorate.display_name(viewer: recipient)}.",
        "Notification updated"
      ).deliver_later
    end
  end

  def investigation_product
    InvestigationProduct.find_by(product_id: product.id, investigation_id: notification.id)
  end

  def duplicate_investigation_product
    InvestigationProduct.find_by(product_id: product.id, investigation_id: notification.id, investigation_closed_at: notification.date_closed)
  end
end
