require "rails_helper"
require "shared_contexts/load_user"

RSpec.describe Users::Load, type: :interactor do
  include_context "load user"

  subject { described_class.call(omniauth_response: omniauth_response) }

  describe ".call" do
    context "when successfully loading the user" do
      it { is_expected.to be_a_success }
      it { expect(subject.user).to eq(user) }
    end

    context "when no user is loaded" do
      before { allow(user_service).to receive(:user).and_raise(RuntimeError) }

      it do
        expect(Raven).to receive(:capture_exception).with(instance_of(RuntimeError))
        subject.user
      end
      it { is_expected.to be_a_failure }
      it { expect(subject.user).to be nil }
      it { expect(subject.errors.full_messages).to eq(%w[RuntimeError]) }
    end
  end
end
