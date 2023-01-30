require "rails_helper"

RSpec.describe InvestigationProductDecorator, :with_stubbed_opensearch, :with_stubbed_mailer do
  subject(:decorated_object) { investigation_product.decorate }

  let(:investigation) { create(:allegation, creator: user) }
  let(:investigation_product) { create(:investigation_product, investigation:, product:) }
  let(:user) { create(:user, :opss_user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe "#owning_team_link" do
    subject(:result) { decorated_object.owning_team_link }

    let(:product) { create(:product, owning_team:) }

    context "when the product is not owned" do
      let(:owning_team) { nil }

      it "returns 'No owner'" do
        expect(result).to eq("No owner")
      end
    end

    context "when the product is owned by the user's team" do
      let(:owning_team) { user.team }

      it "returns 'Your team is the product record owner'" do
        expect(result).to eq("Your team is the product record owner")
      end
    end

    context "when the product is owned by another team" do
      let(:owning_team) { build(:team, name: "Other Team") }

      it "returns a link to the other team's contact details" do
        expect(result).to have_link("Other Team", href: owner_investigation_investigation_product_path(investigation, investigation_product))
      end
    end
  end

  describe "#product_overview_summary_list", :aggregate_failures do
    subject(:result) { decorated_object.product_overview_summary_list }

    let(:product) { create(:product, owning_team: user.team) }

    it "summarises the product's metadata" do
      travel_to(10.minutes.ago) do
        investigation_product
      end

      expect(result).to summarise("Last updated", text: "10 minutes ago")
      expect(result).to summarise("Created", text: "10 minutes ago")
      expect(result).to summarise("Product record owner", text: "Your team is the product record owner")
    end
  end
end