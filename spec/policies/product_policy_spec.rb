require "rails_helper"

RSpec.describe ProductPolicy do
  subject(:policy) { described_class.new(user, Product) }

  let(:user) { create(:user) }

  describe "#export?" do
    context "when the user has the psd_admin role" do
      before { user.roles.create!(name: "psd_admin") }

      it "returns true" do
        expect(policy).to be_export
      end
    end

    context "when the user does not have the psd_admin role" do
      it "returns false" do
        expect(policy).not_to be_export
      end
    end
  end
end
