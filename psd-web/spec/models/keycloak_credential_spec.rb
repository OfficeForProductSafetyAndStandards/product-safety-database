require "rails_helper"

RSpec.describe KeycloakCredential, type: :model do
  describe ".authenticate" do
    before do
      create(:keycloak_credential)
    end

    let(:password) do
      "passwordpasswordpasswordpassword"
    end
    let(:email) { "test@example.org" }

    it "returns true when password matches" do
      expect(KeycloakCredential.authenticate(email, password)).to be_truthy
    end

    it "raises NotFound when email not found" do
      expect { KeycloakCredential.authenticate("notsuch@email.org", password) }
        .to raise_exception(ActiveRecord::RecordNotFound)
    end

    it "returns false when password does not match" do
      expect(KeycloakCredential.authenticate(email, password.reverse)).to be_falsy
    end
  end
end
