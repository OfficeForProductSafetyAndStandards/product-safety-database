require 'base64'
require 'openssl'

class KeycloakConnector < ApplicationRecord
  KEY_LEN = 64
  CREDENTIALS_QUERY = <<-SQL
SELECT c.salt, c.value, c.hash_iterations, u.email, c.type FROM credential c INNER JOIN user_entity u ON c.user_id = u.id
  SQL

  establish_connection :keycloak

  def self.copy_keycloak_credentials
    row = KeycloakConnector.connection.query(CREDENTIALS_QUERY)
    rows.each do |salt, encrypted_password, iterations, email, credential_type|
      KeycloakCredential.create! do |kc|
        kc.salt = salt
        kc.encrypted_password = encrypted_password
        kc.hash_iterations = iterations
        kc.email = email
        kc.credential_type = credential_type
      end
    end
  end

  def encrypt_password(plain_password, salt, iterations)
    hash = OpenSSL::Digest::SHA256.new
    value = OpenSSL::KDF.pbkdf2_hmac(plain_password, salt: salt, iterations: iterations,
                                    length: KEY_LEN, hash: hash)
    # we want to remove trailing newline
    Base64.strict_encode64(value).strip
  end
end

