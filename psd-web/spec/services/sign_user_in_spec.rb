require "rails_helper"

RSpec.describe SignUserIn do
  let(:password) { "password" }
  let(:email)    { "test@example.com" }

  subject { described_class.new(email: email, password: password) }

  describe "#valid?" do
    describe "when the email is blank" do
      let(:email) { "" }

      it "is no valid" do
        expect(subject).to be_invalid
        expect(subject.errors.full_messages_for(:email)).to eq(["Enter your email address"])
      end
    end

    context "when the email is not blank" do
      context "when it does not contain an @" do
        let(:email) { "not_an_email" }

        it "is not valid" do
          expect(subject).to be_invalid
          expect(subject.errors.full_messages_for(:email)).to eq(["Enter your email address in the correct format, like name@example.com"])
        end
      end
    end
    describe "when the password is blank" do
      let(:password) { "" }

      it "is no valid" do
        expect(subject).to be_invalid
        expect(subject.errors.full_messages_for(:password)).to eq(["Enter your password"])
      end
    end
  end
end
