class AddBusinessToCaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :current_user

  attribute :legal_name
  attribute :trading_name
  attribute :company_number
  attribute :relationship, default: ""
  attribute :online_marketplace_id
  attribute :other_marketplace_name

  attribute :locations, default: []
  attribute :contacts, default: []

  attribute :locations_attributes
  attribute :contacts_attributes

  validates :current_user, :trading_name, presence: true

  def initialize(*args)
    super
    self.locations = [Location.new] if locations.empty?
    self.contacts = [Contact.new] if contacts.empty?
  end

  def business_object
    object = Business.new(
      legal_name:,
      trading_name:,
      company_number:,
      added_by_user: current_user
    )
    object.locations = [new_location] if given_location?
    object.contacts = [new_contact] if given_contact?
    object
  end

  def primary_location
    locations.first
  end

  def primary_contact
    contacts.first
  end

  def online_marketplace
    OnlineMarketplace.find_by(id: online_marketplace_id)
  end

private

  def new_location
    location = Location.new(location_attrs)
    location.name = "Registered office address"
    location.added_by_user = current_user
    location
  end

  def new_contact
    Contact.new(contact_attrs)
  end

  def given_location?
    location_attrs.values.any?(&:present?)
  end

  def given_contact?
    contact_attrs.values.any?(&:present?)
  end

  def location_attrs
    locations_attributes["0"]
  end

  def contact_attrs
    contacts_attributes["0"]
  end
end
