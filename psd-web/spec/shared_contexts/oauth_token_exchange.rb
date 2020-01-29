RSpec.shared_context "oauth token exchange" do
  let(:refresh_token)   { SecureRandom.hex }
  let(:exchanged_token) { SecureRandom.hex }
  let(:omniauth_response) do
    Hashie::Mash.new("credentials" => { "refresh_token" => refresh_token })
  end
end
