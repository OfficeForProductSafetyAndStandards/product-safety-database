class BulkProductsAddBusinessDetailsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :trading_name
  attribute :legal_name
  attribute :company_number
  attribute :country

  attribute :locations, default: []
  attribute :contacts, default: []

  attribute :locations_attributes
  attribute :contacts_attributes

  validates :trading_name, presence: true
  validate :validate_trading_name_not_default
  validate :validate_country_set_for_location

  def initialize(*args)
    super
    # Detect a default trading name and don't show it to force the user to enter their own
    self.trading_name = nil if trading_name.start_with?("Auto-generated business for notification")
    self.locations = [Location.new] if locations.empty?
    self.contacts = [Contact.new] if contacts.empty?
    locations_attributes["0"].store(:country, country) if country.present?
    locations << Location.new(locations_attributes["0"]) if locations_attributes.present?
  end

  def primary_location
    locations.first
  end

  def primary_contact
    contacts.first
  end

  def self.from(bulk_products_upload)
    business = bulk_products_upload.investigation_business&.business

    if business.present?
      new(
        **business.serializable_hash.slice("trading_name", "legal_name", "company_number"),
        locations: business.locations,
        contacts: business.contacts
      )
    else
      new
    end
  end

private

  def validate_trading_name_not_default
    errors.add(:trading_name, :invalid) if trading_name.start_with?("Auto-generated business for notification")
  end

  def validate_country_set_for_location
    return if locations_attributes["0"][:country].present?

    errors.add(:country, "Select a country")
  end
end
