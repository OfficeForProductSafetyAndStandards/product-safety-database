class KeycloakCredential < ApplicationRecord
  HASH_FUNCTION = OpenSSL::Digest::SHA256.new
  KEY_LEN       = 64

  def self.authenticate(email, plain_password)
    kc = self.find_by!(email: email)
    hashed_password = OpenSSL::KDF.pbkdf2_hmac(plain_password, salt: kc.salt, iterations: kc.hash_iterations,
                                    length: KEY_LEN, hash: HASH_FUNCTION)
    hashed_password64 = Base64.strict_encode64(hashed_password).strip
    hashed_password64 == kc.encrypted_password
  end
end
