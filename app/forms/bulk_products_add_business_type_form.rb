class BulkProductsAddBusinessTypeForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :type
  attribute :online_marketplace_id
  attribute :other_marketplace_name
  attribute :authorised_representative_choice

  BUSINESS_TYPES = %w[
    retailer online_seller online_marketplace manufacturer exporter importer fulfillment_house distributor authorised_representative responsible_person
  ].freeze

  validates :type, inclusion: { in: BUSINESS_TYPES }
  validates :online_marketplace_id, presence: true, if: -> { is_approved_online_marketplace? }
  validates :authorised_representative_choice, presence: true, if: -> { is_authorised_representative? }

  def self.from(bulk_products_upload)
    investigation_business = bulk_products_upload.investigation_business
    online_marketplace = investigation_business&.online_marketplace

    if investigation_business.present?
      new(
        type: investigation_business.relationship,
        online_marketplace_id: investigation_business.online_marketplace_id,
        other_marketplace_name: online_marketplace&.approved_by_opss ? nil : online_marketplace&.name,
        authorised_representative_choice: investigation_business.authorised_representative_choice
      )
    else
      new
    end
  end

private

  def is_authorised_representative?
    type == "authorised_representative"
  end

  def is_approved_online_marketplace?
    type == "online_marketplace" && other_marketplace_name.blank?
  end
end
