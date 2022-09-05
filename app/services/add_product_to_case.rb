class AddProductToCase
  include Interactor
  include EntitiesToNotify

  delegate :authenticity,
           :has_markings,
           :markings,
           :batch_number,
           :brand,
           :country_of_origin,
           :description,
           :barcode,
           :name,
           :product_code,
           :subcategory,
           :webpage,
           :investigation,
           :category,
           :user,
           :product,
           :affected_units_status,
           :number_of_affected_units,
           :exact_units,
           :approx_units,
           :when_placed_on_market,
           :customs_code,
           to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    when_placed_on_market = context.when_placed_on_market

    Product.transaction do
      context.product = investigation.products.create!(
        authenticity:,
        has_markings:,
        markings:,
        batch_number:,
        brand:,
        country_of_origin:,
        description:,
        barcode:,
        name:,
        product_code:,
        subcategory:,
        category:,
        webpage:,
        source: build_user_source,
        affected_units_status:,
        number_of_affected_units:,
        when_placed_on_market:,
        customs_code:,
        owning_team: investigation.owner_team
      )

      context.activity = create_audit_activity_for_product_added

      send_notification_email
    end
  end

private

  def create_audit_activity_for_product_added
    AuditActivity::Product::Add.create!(
      source: build_user_source,
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
        "Product was added to the #{investigation.case_type} by #{context.activity.source.show(recipient)}.",
        "#{investigation.case_type.upcase_first} updated"
      ).deliver_later
    end
  end

  def build_user_source
    UserSource.new(user:)
  end
end
