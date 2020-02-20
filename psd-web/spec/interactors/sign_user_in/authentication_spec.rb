require "rails_helper"
require "devise/strategies/database_authenticatable"

RSpec.describe SignUserIn::Authentication do
  let(:default_user) { User.new(password: "wrong", email: Faker::Internet.safe_email) }
  let(:user) { create(:user, :activated) }
  let(:warden_strategy) do
    double(Devise::Strategies::DatabaseAuthenticatable, authenticate: user)
  end

  subject { described_class.call(warden: warden_strategy, resource: default_user) }

  context "when the user is successully authenticated" do
    it "stores the new user as the resource" do
      expect(subject.resource).to eq(user)
    end
  end

  context "when the user is not authenticated successully" do
    let(:user) { nil }

    it "the resource remains the non saved user" do
      expect(subject.resource).to eq(default_user)
      expect(subject).to be_a_failure
      expect(subject.resource.errors.full_messages).to eq(["Enter correct email address and password"])
    end
  end
end
