RSpec.describe AuditActivity::RiskAssessment::RiskAssessmentAdded, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:activity) do
    described_class.create!(
      added_by_user: risk_assessment.added_by_user,
      investigation:,
      metadata:
    )
  end

  let(:risk_assessment) { create(:risk_assessment, trait, assessed_by_team:, assessed_by_business:, assessed_by_other:, investigation_products: investigation.investigation_products, investigation:) }
  let(:trait) { :without_file }
  let(:assessed_by_team) { nil }
  let(:assessed_by_business) { nil }
  let(:assessed_by_other) { "test" }
  let(:investigation) { create(:allegation, :with_products) }
  let(:metadata) { described_class.build_metadata(risk_assessment) }

  describe "#metadata" do
    it "returns the metadata" do
      expect(activity.metadata).to eq(activity.read_attribute(:metadata))
    end

    # TODO: remove once migrated
    context "when metadata contains Product references" do
      let(:metadata) do
        data = described_class.build_metadata(risk_assessment)
        data["risk_assessment"]["product_ids"] = investigation.product_ids
        data["risk_assessment"].delete("investigation_product_ids")
        data
      end

      it "translates the Product IDs to InvestigationProduct IDs" do
        expect(activity.metadata["risk_assessment"]["product_ids"]).to be_nil
        expect(activity.metadata["risk_assessment"]["investigation_product_ids"]).to eq(investigation.investigation_product_ids)
      end
    end
  end

  describe "#risk_assessment" do
    it "returns the risk assessment" do
      expect(activity.risk_assessment).to eq(risk_assessment)
    end
  end

  describe "#risk_assessment_file" do
    context "with no file attached to the risk assessment" do
      it "returns nil" do
        expect(activity.risk_assessment_file).to be_nil
      end
    end

    context "with a file attached to the risk assessment" do
      let(:trait) { :with_file }

      it "returns the blob" do
        expect(activity.risk_assessment_file.filename).to eq("new_risk_assessment.txt")
      end
    end
  end

  describe "#products_assessed" do
    context "with one product on the risk assessment" do
      it "returns the product" do
        expect(activity.products_assessed).to eq([investigation.products.first])
      end
    end

    context "with multiple products on the risk assessment" do
      let(:investigation) { create(:allegation, products: [product_1, product_2]) }
      let(:product_1) { create(:product) }
      let(:product_2) { create(:product) }

      it "returns an Array of products" do
        expect(activity.products_assessed).to eq([product_1, product_2])
      end
    end
  end

  describe "#further_details" do
    it "returns the risk assessment details" do
      expect(activity.further_details).to eq(risk_assessment.details)
    end
  end

  describe "#risk_level" do
    it "returns the risk assessment risk_level" do
      expect(activity.risk_level).to eq(risk_assessment.risk_level)
    end
  end

  describe "#assessed_on" do
    it "returns the risk assessment assessed_on" do
      expect(activity.assessed_on).to eq(risk_assessment.assessed_on)
    end
  end

  describe "#assessed_by_team" do
    context "when assessed_by_team on the risk assessment is nil" do
      it "returns nil" do
        expect(activity.assessed_by_team).to be_nil
      end
    end

    context "when assessed_by_team on the risk assessment is set" do
      let(:assessed_by_team) { create(:team) }
      let(:assessed_by_other) { nil }

      it "returns the Team" do
        expect(activity.assessed_by_team).to eq(assessed_by_team)
      end
    end
  end

  describe "#assessed_by_business" do
    context "when assessed_by_business on the risk assessment is nil" do
      it "returns nil" do
        expect(activity.assessed_by_business).to be_nil
      end
    end

    context "when assessed_by_business on the risk assessment is set" do
      let(:assessed_by_business) { create(:business) }
      let(:assessed_by_other) { nil }

      it "returns the Business" do
        expect(activity.assessed_by_business).to eq(assessed_by_business)
      end
    end
  end
end
