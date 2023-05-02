class AddBusinessToCaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :current_user

  attribute :legal_name
  attribute :trading_name
  attribute :company_number
  attribute :relationship, default: ""

  attribute :locations, default: [Location.new]
  attribute :contacts, default: [Contact.new]

  attribute :locations_attributes
  attribute :contacts_attributes

  validates :current_user, :trading_name, presence: true

  def valid?
    super && !contacts_have_errors? && !locations_have_errors?
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

# private

  def new_location
    location = Location.new(locations_attributes["0"])
    location.name = "Registered office address"
    location.added_by_user = current_user
    location
  end

  def new_contact
    Contact.new(contacts_attributes["0"])
  end

  def given_location?
    location = locations_attributes["0"]
    location[:address_line_1].present? ||
      location[:address_line_2].present? ||
      location[:city].present? ||
      location[:county].present? ||
      location[:country].present? ||
      location[:postal_code].present?
  end

  def given_contact?
    contact = contacts_attributes["0"]
    contact[:name].present? ||
      contact[:email].present? ||
      contact[:phone_number].present? ||
      contact[:job_title].present?
  end

  def contacts_have_errors?
    return false unless given_contact?

    new_contact.errors.any?
  end

  def locations_have_errors?
    return false unless given_location?

    new_location.errors.any?
  end
end
