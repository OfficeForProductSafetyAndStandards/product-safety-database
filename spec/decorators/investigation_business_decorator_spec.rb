require "rails_helper"

RSpec.describe InvestigationBusinessDecorator, :with_stubbed_mailer do
  subject(:decorated_object) { investigation_business.decorate }

  let(:investigation) { create(:allegation, creator: user) }
  let(:business) { create(:business) }
  let(:investigation_business) { create(:investigation_business, investigation:, business:) }
  let(:relationship) { "manufacturer" }
  let(:user) { create(:user, :opss_user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe "#pretty_relationship" do
    let(:investigation_business) { create(:investigation_business, investigation:, business:, relationship:) }

    context "when the relationship is 'manufacturer'" do
      let(:relationship) { "manufacturer" }

      it "returns the pretty relationship" do
        expect(decorated_object.pretty_relationship).to eq("Manufacturer")
      end
    end

    context "when the relationship is 'distributor'" do
      let(:relationship) { "distributor" }

      it "returns the pretty relationship" do
        expect(decorated_object.pretty_relationship).to eq("Distributor")
      end
    end

    context "with relationship of authorised_represenative" do
      let(:relationship) { "authorised_representative" }
      let(:investigation_business) { create(:investigation_business, investigation:, business:, relationship:, authorised_representative_choice:) }

      context 'when the authorised representative choice is "UK authorisation representative"' do
        let(:authorised_representative_choice) { "uk_authorised_representative" }

        it "returns the UK string" do
          expect(decorated_object.pretty_relationship).to eq("UK Authorised representative")
        end
      end

      context 'when the authorised representative choice is "EU authorisation representative"' do
        let(:authorised_representative_choice) { "eu_authorised_representative" }

        it "returns the EU string" do
          expect(decorated_object.pretty_relationship).to eq("EU Authorised representative")
        end
      end
    end
  end
end
