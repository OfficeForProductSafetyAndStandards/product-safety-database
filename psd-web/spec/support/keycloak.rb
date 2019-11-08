# frozen_string_literal: true
RSpec.shared_context 'with Keycloak configuration', shared_context: :metadata do
  before { allow(Keycloak::Client).to receive(:openid_configuration) { true } }
end

RSpec.configure do |rspec|
  rspec.include_context 'with Keycloak configuration', with_keycloak_config: true
end
