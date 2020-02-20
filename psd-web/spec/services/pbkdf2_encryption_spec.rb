require "rails_helper"

RSpec.describe Pbkdf2Encryption do
  let(:binary_salt) { "\xC6\xAF\xE7\x91y\x91Fn\xE2\v\xF4\xE3^A\x98g" }
  let(:encryption) { Pbkdf2Encryption.new(password, salt: salt, iterations: 27500) }
  let(:encrypted_password) { "Jud2hU6IHPx5yK3COhRJGAnJawRqkQ8sZIKmjZWkYfE1XIWXTItlXt+rL6s/ExuWi9xplij+0rKOZttpTqp/PA==" }
  let(:password) { "passwordpasswordpasswordpassword" }

  describe ".generate_hash" do
    context "when salt is nil" do
      let(:salt) { nil }

      it "generates salt randomly" do
        expect(OpenSSL::Random).to receive(:random_bytes).and_return(binary_salt)

        expect(encryption.generate_hash).to eq(encrypted_password)
      end
    end

    context "when salt is provided" do
      let(:salt) { binary_salt }

      specify do
        expect(OpenSSL::Random).not_to receive(:random_bytes)

        expect(encryption.generate_hash).to eq(encrypted_password)
      end
    end
  end
end
