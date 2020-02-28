require "rails_helper"
require "shared_contexts/load_user"

RSpec.describe Users::Load, type: :interactor do
  include_context "with mock user"

  subject(:load_service) do
    described_class.call(
      omniauth_response: omniauth_response,
      user_service: user_service
    )
  end

  before do
    allow(CreateUserFromAuth)
      .to receive(:new).with(omniauth_response).and_return(user_service)
  end


  describe ".call" do
    context "when successfully loading the user" do
      it { is_expected.to be_a_success }
      it { expect(load_service.user).to eq(user) }
    end

    context "when no user is loaded" do
      before { allow(user_service).to receive(:user).and_raise(RuntimeError) }

      it do
        expect(Raven).to receive(:capture_exception).with(instance_of(RuntimeError))
        load_service.user
      end

      it { is_expected.to be_a_failure }
      it { expect(load_service.user).to be nil }
      it { expect(load_service.errors.full_messages).to eq(%w[RuntimeError]) }
    end
  end
end
