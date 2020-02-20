module EncryptionConcern
  def valid_password?(password)
    password_digest(password) == keycloak_user.encrypted_password
  end

  def password_digest(password)
    salt = keycloak_user.salt
    e = Pbkdf2Encryption.new(password, salt: salt)
    e.generate_hash
  end

  def keycloak_user
    KeycloakCredential.find_by!(email: self.email)
  end
end
