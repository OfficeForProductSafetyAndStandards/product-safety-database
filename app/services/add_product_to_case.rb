class AddProductToCase
  include Interactor
  include EntitiesToNotify

  delegate :investigation,
           :user,
           :product,
           :skip_email,
           to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "No product supplied") unless product.is_a?(Product)

    InvestigationProduct.transaction do
      # TODO: Only check existing links on active products once product retirement is implemented
      (context.fail!(error: "The product is already linked to the case") and return false) if investigation.products.include?(product)
      investigation.products << product
    end

    change_product_owner_if_unowned

    context.activity = create_audit_activity_for_product_added

    send_notification_email unless skip_email
  end

private

  def change_product_owner_if_unowned
    product.update!(owning_team: investigation.owner_team) if product.owning_team.nil?
  end

  def create_audit_activity_for_product_added
    AuditActivity::Product::Add.create!(
      added_by_user: user,
      investigation:,
      title: product.name,
      product:
    )
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "Product was added to the #{investigation.case_type} by #{user.decorate.display_name(viewer: recipient)}.",
        "#{investigation.case_type.upcase_first} updated"
      ).deliver_later
    end
  end
end
