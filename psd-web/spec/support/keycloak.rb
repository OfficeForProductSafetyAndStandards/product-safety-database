# frozen_string_literal: true

RSpec.shared_context "with stubbed Keycloak configuration", shared_context: :metadata do
  let(:openid_config) { file_fixture("keycloak_openid_config.json").read.gsub("http://keycloak:8080/auth", ENV.fetch("KEYCLOAK_AUTH_URL")) }
  let(:response_double) { double("OpenID response", code: 200, body: openid_config) }
  before { allow(RestClient).to receive(:get).with("#{ENV.fetch('KEYCLOAK_AUTH_URL')}/realms/opss/.well-known/openid-configuration") { response_double } }
  after { KeycloakClient.instance.reset }
end

RSpec.configure do |rspec|
  rspec.include_context "with stubbed Keycloak configuration", with_stubbed_keycloak_config: true
end
