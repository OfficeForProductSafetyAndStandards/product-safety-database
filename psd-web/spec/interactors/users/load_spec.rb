require "rails_helper"

RSpec.describe Users::Load, type: :interactor do
  let(:user)              { double(User) }
  let(:user_service)      { instance_double(CreateUserFromAuth, user: user) }
  let(:omniauth_response) { double }

  subject { described_class.call(omniauth_response: omniauth_response) }

  before do
    allow(CreateUserFromAuth)
      .to receive(:new).with(omniauth_response).and_return(user_service)
  end

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
      it { expect(subject.errors.full_messages).to eq(["RuntimeError"]) }
    end
  end
end
