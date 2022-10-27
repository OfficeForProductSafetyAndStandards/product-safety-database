class RemoveProductFromCase
  include Interactor
  include EntitiesToNotify

  delegate :product, :investigation, :user, :reason, to: :context

  def call
    context.fail!(error: "No product supplied") unless product.is_a?(Product)
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    # TODO: Versioned/historic products can't be removed from a case. Ensure
    #   this is caught once product versioning is implemented.

    InvestigationProduct.transaction do
      product.reload
      investigation.products.delete product
      change_product_ownership
    end

    investigation.__elasticsearch__.update_document
    product.__elasticsearch__.update_document

    context.activity = create_audit_activity_for_product_removed

    send_notification_email
  end

private

  def change_product_ownership
    # If the product was owned by the team who owns this case, and is not linked
    # to any other cases owned by this team, it become unowned.
    if product.owning_team == investigation.owner_team && product.investigations.none? { |inv| inv.owner_team == product.owning_team }
      product.update! owning_team: nil
    end
  end

  def create_audit_activity_for_product_removed
    # TODO: Refer to the correct version of the product record once versioning
    #   is implemented.
    AuditActivity::Product::Destroy.create!(
      added_by_user: user,
      investigation:,
      product:,
      metadata: AuditActivity::Product::Destroy.build_metadata(product, reason)
    )
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "Product was removed from the #{investigation.case_type} by #{user.decorate.display_name(viewer: recipient)}.",
        "#{investigation.case_type.upcase_first} updated"
      ).deliver_later
    end
  end
end
