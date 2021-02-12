require "rails_helper"

RSpec.describe ProductPolicy do
  subject(:policy) { described_class.new(user, Product) }

  let(:user) { create(:user) }

  describe "#export?" do
    context "when the user has the psd_admin role" do
      before { user.roles.create!(name: "psd_admin") }

      it "returns true" do
        expect(policy.export?).to be true
      end
    end

    context "when the user does not have the psd_admin role" do
      it "returns false" do
        expect(policy.export?).to be false
      end
    end
  end
end
