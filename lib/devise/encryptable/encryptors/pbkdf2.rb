require "devise/encryptable/encryptors/base"

module Devise
  module Encryptable
    module Encryptors
      class PBKDF2 < Base
        HASH_FUNCTION = OpenSSL::Digest.new("SHA256")
        KEY_LEN = 64
        def self.digest(password, _stretches, salt, _pepper)
          hashed_password = OpenSSL::KDF.pbkdf2_hmac(
            password,
            salt:,
            iterations: 27_500,
            length: KEY_LEN,
            hash: HASH_FUNCTION
          )

          Base64.strict_encode64(hashed_password).strip
        end
      end
    end
  end
end
