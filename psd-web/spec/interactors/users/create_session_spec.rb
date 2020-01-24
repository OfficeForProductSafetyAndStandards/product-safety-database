require "rails_helper"
require "shared_contexts/load_user"
require "shared_contexts/oauth_token_exchange"

RSpec.describe Users::CreateSession do
  include_context "load user"
  include_context "oauth token exchange"

  subject do
    described_class.call(
      user_service: user_service,
      omniauth_response: omniauth_response
    )
  end

  before do
    allow(KeycloakClient.instance)
      .to receive(:exchange_refresh_token_for_token)
            .with(refresh_token)
            .and_return(exchanged_token)
  end

  describe ".call", :reset_keycloak_client do
    it { expect(subject.user).to eq(user) }
    it { expect(subject.access_token).to eq(exchanged_token) }
  end
end
