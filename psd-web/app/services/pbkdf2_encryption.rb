class Pbkdf2Encryption
  HASH_FUNCTION = OpenSSL::Digest::SHA256.new
  KEY_LEN       = 64

  def initialize(plain_password, salt: nil, iterations: 27500)
    @salt = salt
    @iterations = iterations
    @plain_password = plain_password
  end

  def generate_hash
    @generate_hash ||= begin
      hashed_password = OpenSSL::KDF.pbkdf2_hmac(@plain_password, salt: salt, iterations: @iterations,
                                      length: KEY_LEN, hash: HASH_FUNCTION)
      Base64.strict_encode64(hashed_password).strip
    end
  end

  def salt
    @salt ||= OpenSSL::Random.random_bytes(16)
  end
end
