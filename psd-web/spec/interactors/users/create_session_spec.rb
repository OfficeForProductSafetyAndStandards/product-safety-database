require "rails_helper"
require "shared_contexts/load_user"

RSpec.describe Users::CreateSession do
  include_context "load user"

  subject do
    described_class.call(
      user_service: user_service,
      omniauth_response: omniauth_response
    )
  end

  describe ".call", :reset_keycloak_client do
    it { expect(subject.user).to eq(user) }
  end
end
