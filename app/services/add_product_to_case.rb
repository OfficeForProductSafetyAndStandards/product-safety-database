class AddProductToCase
  include Interactor
  include EntitiesToNotify

  delegate :authenticity,
           :batch_number,
           :brand,
           :country_of_origin,
           :description,
           :gtin13,
           :name,
           :product_code,
           :product_type,
           :webpage,
           :investigation,
           :category,
           :user,
           :product,
           to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    Product.transaction do
      context.product = investigation.products.create!(
        authenticity: authenticity,
        batch_number: batch_number,
        brand: brand,
        country_of_origin: country_of_origin,
        description: description,
        gtin13: gtin13,
        name: name,
        product_code: product_code,
        product_type: product_type,
        category: category,
        webpage: webpage,
        source: build_user_source
      )

      context.activity = create_audit_activity_for_product_added

      send_notification_email
    end
  end

private

  def create_audit_activity_for_product_added
    AuditActivity::Product::Add.create!(
      source: build_user_source,
      investigation: investigation,
      title: product.name,
      product: product
    )
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "Product was added to the #{investigation.case_type} by #{context.activity.source.show(recipient)}.",
        "#{investigation.case_type.upcase_first} updated"
      ).deliver_later
    end
  end

  def build_user_source
    UserSource.new(user: user)
  end
end
