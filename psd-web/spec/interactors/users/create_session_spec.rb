require "rails_helper"
require "shared_contexts/load_user"

RSpec.describe Users::CreateSession do
  include_context "with mock user"

  subject(:create_session_service) do
    described_class.call(
      user_service: user_service,
      omniauth_response: omniauth_response
    )
  end

  describe ".call", :reset_keycloak_client do
    it { expect(create_session_service.user).to eq(user) }
  end
end
