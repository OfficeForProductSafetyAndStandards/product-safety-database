class NewUser
  include ActiveModel::Model
  include ActiveModel::Attributes
  include GlobalID::Identification

  attributes :email, :name, :mobile_number, :password
  attribute :encrypted_password, default: ""

  with_options on: :registration_completion do |registration_completion|
    registration_completion.validates :mobile_number, presence: true
    registration_completion.validates :mobile_number,
                                      phone: { message: I18n.t(:invalid, scope: %i[activerecord errors models user attributes mobile_number]) },
                                      unless: -> { mobile_number.blank? }
    registration_completion.validates :name, presence: true
    registration_completion.validates :password, presence: true
    registration_completion.validates :password, length: { minimum: 8 }, allow_blank: true
  end

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  def self.find(id)
    new(JSON.parse(Rails.cache.get(id)))
  end

  # TODO: set key expiry to the invitation expiry time
  def save(expires_in:)
    # TODO: handle not saved
    if expires_in
      Rails.cache.write(id, to_json)
    else
      Rails.cache.write(id, to_json, expires_in: time.to_i)
    end
    true
  end

  def as_json
    attributes.except(:password)
  end

  def delete
    # TODO: handle not found because exipired?
    Rails.cache.delete(email_address)
    self.freeze
  end
end
