class KeycloakCredential < ApplicationRecord
  def self.authenticate(email, plain_password)
    kc = self.find_by!(email: email)

    encryption = Pbkdf2Encryption.new(plain_password, salt: kc.salt, iterations: kc.hash_iterations)
    hashed_password = encryption.generate_hash

    hashed_password == kc.encrypted_password
  end
end
