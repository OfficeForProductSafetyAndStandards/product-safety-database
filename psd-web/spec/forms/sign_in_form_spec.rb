require "rails_helper"

RSpec.describe SignInForm do
  let(:password) { "password" }
  let(:email)    { "test@example.com" }

  subject { described_class.new(email: email, password: password) }

  describe "#valid?" do
  end
end
