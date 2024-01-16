RSpec.describe AuditActivity::RiskAssessment::RiskAssessmentAddedDecorator, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:activity) do
    AuditActivity::RiskAssessment::RiskAssessmentAdded.create!(
      added_by_user: risk_assessment.added_by_user,
      investigation: risk_assessment.investigation,
      metadata: described_class.build_metadata(risk_assessment)
    ).decorate
  end

  let(:risk_assessment) { create(:risk_assessment, trait, risk_level:, assessed_by_team:, assessed_by_business:, assessed_by_other:, investigation_products:) }
  let(:trait) { :without_file }
  let(:risk_level) { "serious" }
  let(:assessed_by_team) { nil }
  let(:assessed_by_business) { nil }
  let(:assessed_by_other) { "test" }
  let(:investigation_products) { [build(:investigation_product)] }

  describe "#assessed_on" do
    it "returns a generated String" do
      expect(activity.assessed_on).to eq("20 July 2020")
    end
  end

  describe "#risk_level" do
    it "returns a generated String based on risk_level" do
      expect(activity.risk_level).to eq("Serious risk")
    end
  end

  describe "#assessed_by_name" do
    context "when assessed_by_team is set" do
      let(:assessed_by_team) { build(:team) }
      let(:assessed_by_other) { nil }

      it "returns the team name" do
        expect(activity.assessed_by_name).to eq(assessed_by_team.name)
      end
    end

    context "when assessed_by_business is set" do
      let(:assessed_by_business) { build(:business, trading_name: "test") }
      let(:assessed_by_other) { nil }

      it "returns the business trading name" do
        expect(activity.assessed_by_name).to eq(assessed_by_business.trading_name)
      end
    end

    context "when neither assessed_by_team nor assessed_by_business is set" do
      it "returns assessed_by_other" do
        expect(activity.assessed_by_name).to eq(assessed_by_other)
      end
    end
  end

  describe "#products_assessed" do
    context "with one product" do
      let(:product) { build(:investigation_product) }
      let(:investigation_products) { [product] }

      it "returns the product name" do
        expect(activity.products_assessed).to eq(product.name)
      end
    end

    context "with multiple products" do
      let(:product_1) { build(:investigation_product) }
      let(:product_2) { build(:investigation_product) }
      let(:product_3) { build(:investigation_product) }
      let(:investigation_products) { [product_1, product_2, product_3] }

      it "returns the product names in a single String" do
        expect(activity.products_assessed).to eq("#{product_1.name}, #{product_2.name} and #{product_3.name}")
      end
    end
  end
end
