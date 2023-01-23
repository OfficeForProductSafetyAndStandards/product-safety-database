require "rails_helper"

RSpec.describe InvestigationProductDecorator, :with_stubbed_opensearch, :with_stubbed_mailer do
  subject(:decorated_investigation_product) { investigation_product.decorate }

  let(:investigation) { create(:allegation, creator: user) }
  let(:investigation_product) { create(:investigation_product, investigation:, product:) }
  let(:team) { create(:team) }
  let(:user) { create(:user, :opss_user, team:) }

  describe "#owning_team_link" do
    let(:product) { create(:product, owning_team:) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context "when the product is not owned" do
      let(:owning_team) { nil }

      it "returns 'No owner'" do
        expect(decorated_investigation_product.owning_team_link).to eq("No owner")
      end
    end

    context "when the product is owned by the user's team" do
      let(:owning_team) { user.team }

      it "returns 'Your team is the product record owner'" do
        expect(decorated_investigation_product.owning_team_link).to eq("Your team is the product record owner")
      end
    end

    context "when the product is owned by another team" do
      let(:owning_team) { build(:team, name: "Other Team") }

      it "returns a link to the other team's contact details" do
        expect(decorated_investigation_product.owning_team_link).to have_link("Other Team", href: owner_investigation_investigation_product_path(investigation, investigation_product))
      end
    end
  end
end
