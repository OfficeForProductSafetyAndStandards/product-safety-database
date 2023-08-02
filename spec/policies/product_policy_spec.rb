require "rails_helper"

RSpec.describe ProductPolicy do
  let(:user) { create(:user) }

  describe "#export?" do
    subject(:policy) { described_class.new(user, Product) }

    context "when the user has the all_data_exporter role" do
      before { user.roles.create!(name: "all_data_exporter") }

      it "returns true" do
        expect(policy).to be_export
      end
    end

    context "when the user does not have the all_data_exporter role" do
      it "returns false" do
        expect(policy).not_to be_export
      end
    end
  end

  describe "#update?" do
    subject(:policy) { described_class.new(user, product) }

    let(:product) { build(:product) }

    context "when there is no owning team", :with_stubbed_mailer do
      let(:team) { create(:team) }
      let(:user) { create(:user, team:) }
      let(:product) { create(:product, owning_team: nil) }

      context "when the user's team does not have any cases linked to the product" do
        it { is_expected.not_to be_update }
      end

      context "when the user's team has closed cases linked to the product" do
        let(:investigation) { create(:allegation, creator: user) }

        before do
          AddProductToCase.call!(investigation:, user:, product:)
          ChangeCaseStatus.call!(investigation:, user:, new_status: "closed")
        end

        it { is_expected.not_to be_update }
      end

      context "when the user's team has open cases linked to the product" do
        let(:investigation) { create(:allegation, creator: user) }

        before { AddProductToCase.call! investigation:, user:, product: }

        it { is_expected.to be_update }
      end
    end

    context "when the owning team is the user's team" do
      before { product.owning_team = user.team }

      it { is_expected.to be_update }
    end

    context "when the owning team is not the user's team" do
      before { product.owning_team = build(:team) }

      it { is_expected.not_to be_update }
    end

    context "with an old version", :with_stubbed_opensearch do
      let(:product) do
        product = create(:product, :with_versions)
        product.paper_trail.previous_version
      end

      it { is_expected.not_to be_update }
    end

    context "with a retired product", :with_stubbed_opensearch do
      let(:product) { build(:product, :retired) }

      it { is_expected.not_to be_update }
    end
  end
end
