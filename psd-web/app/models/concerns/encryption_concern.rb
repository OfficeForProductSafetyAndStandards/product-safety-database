module EncryptionConcern
  extend ActiveSupport::Concern
  included do
    has_one :keycloak_credential, foreign_key: :email, inverse_of: :user
  end

  def valid_password?(password)
    password_digest(password) == keycloak_credential.encrypted_password
  end

  def password_digest(password)
    salt = keycloak_credential.salt
    e = Pbkdf2Encryption.new(password, salt: salt)
    e.generate_hash
  end
end
