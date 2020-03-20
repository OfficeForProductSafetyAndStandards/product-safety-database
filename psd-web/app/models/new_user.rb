class NewUser
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email
  attribute :name
  attribute :mobile_number
  attribute :password
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

  def save(expires_in:)
    if expires_in
      Rails.cache.write(id, to_json)
    else
      Rails.cache.write(id, to_json, expires_in: time.to_i)
    end
    true
  end

  def as_json
    attributes.except("password")
  end

  def delete
    Rails.cache.delete(email_address)
    self.freeze
  end
end
