require "rails_helper"
require "rake"

RSpec.describe BackfillProductOwner, :with_stubbed_notify, :with_stubbed_mailer, :with_stubbed_opensearch do
  context "when product does not have an owning_team_id" do
    let(:product) { create(:product) }

    context "when product does not have an investigation attached" do
      it "owning_team_id remains nil" do
        described_class.call
        expect(product.reload.owning_team_id).to eq nil
      end
    end

    context "when product has an investigation attached" do
      let!(:investigation) { create(:allegation, products: [product]) }

      before do
        product.update!(owning_team_id: nil)
      end

      context "when investigation is open" do
        it "owning_team_id is updated to the investigation's owner_team" do
          described_class.call
          expect(product.reload.owning_team_id).to eq investigation.owner_team.id
        end
      end

      context "when investigation is closed" do
        let!(:investigation) { create(:allegation, products: [product], is_closed: true) }

        before do
          product.update!(owning_team_id: nil)
        end

        # rubocop:disable RSpec/MultipleExpectations
        it "owning_team_id is not updated" do
          described_class.call
          expect(product.reload.owning_team_id).not_to eq investigation.owner_team.id
          expect(product.reload.owning_team_id).to eq nil
        end
        # rubocop:enable RSpec/MultipleExpectations
      end
    end
  end

  context "when product has an owning_team_id" do
    let(:product) { create(:product) }
    let(:other_team) { create(:team) }
    let!(:investigation) { create(:allegation, products: [product]) }

    before do
      product.update!(owning_team_id: other_team.id)
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "owning_team_id does not change" do
      described_class.call
      expect(product.reload.owning_team_id).not_to eq investigation.owner_team.id
      expect(product.owning_team_id).to eq other_team.id
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
