require "rails_helper"

RSpec.describe SignUserIn::FormValidator do
  let(:default_user) { User.new }
  let(:invalid)      { false }
  let(:sign_in_form) { double(SignInForm, "invalid?": invalid) }

  subject { described_class.call(resource: default_user, sign_in_form: sign_in_form) }

  describe "#call" do
    context "when the form is valid" do
      it { is_expected.to be_success }
    end

    context "when the form is invalid" do
      let(:errors) { ActiveModel::Errors.new(sign_in_form) }
      let(:error) { "foo bar baz" }
      let(:invalid) { true }

      before do
        allow(sign_in_form).to receive(:errors).and_return(errors)
        errors.add(:base, error)
      end

      it "adds error the default resource" do
        expect(subject).to be_a_failure
        expect(default_user.errors.full_messages).to eq([error])
      end
    end
  end
end
