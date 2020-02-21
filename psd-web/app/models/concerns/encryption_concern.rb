module EncryptionConcern
  extend ActiveSupport::Concern

  def password=(password)
    return unless password

    @password = password
    e = Pbkdf2Encryption.new(password, iterations: self.hash_iterations)
    self.salt               = e.salt
    self.encrypted_password = e.generate_hash
  end

  def valid_password?(password)
    password_digest(password) == encrypted_password
  end

  def password_digest(password)
    e = Pbkdf2Encryption.new(password, salt: self.salt)
    e.generate_hash
  end
end
