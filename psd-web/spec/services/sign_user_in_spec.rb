require "rails_helper"

RSpec.describe SignUserIn do

  describe "#valid?" do
    describe "when the email is blank" do
      it "is no valid" do
        expect(subject).to be_invalid
        expect(subject.errors.full_messages_for(:email)).to eq(["Enter your email address in the correct format, like name@example.com", "Enter your email address"])
      end
    end

    describe "when the password is blank" do
      it "is no valid" do
        expect(subject).to be_invalid
        expect(subject.errors.full_messages_for(:password)).to eq(["Enter your password"])
      end
    end
  end
end
