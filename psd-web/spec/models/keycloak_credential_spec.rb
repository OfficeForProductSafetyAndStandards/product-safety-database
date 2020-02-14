require 'rails_helper'

RSpec.describe KeycloakCredential, type: :model do
  context "authentication" do
    before do
      create(:keycloak_credential)
    end

    let(:password) do
      "passwordpasswordpasswordpassword"
    end
    let(:email)       { "test@example.org" }
    let(:wrong_email) { "wrong@example.org" }

    context "when successful" do
      let(:email)       { "test@example.org" }

      it "returns true" do
        expect(KeycloakCredential.authenticate(email, password)).to be_truthy
      end
    end

    context "when unsuccessful" do
      it "raises NotFound when email not found" do
        expect { KeycloakCredential.authenticate("notsuch@email.org", password) }
          .to raise_exception(ActiveRecord::RecordNotFound)
      end

      it "returns false when password does not match" do
        expect(KeycloakCredential.authenticate(email, password.reverse)).to be_falsy
      end
    end
  end
end
