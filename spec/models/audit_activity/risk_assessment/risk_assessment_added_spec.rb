require "rails_helper"

RSpec.describe AuditActivity::RiskAssessment::RiskAssessmentAdded, :with_stubbed_opensearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  subject(:activity) do
    described_class.create!(
      added_by_user: risk_assessment.added_by_user,
      investigation: risk_assessment.investigation,
      metadata:
    )
  end

  let(:risk_assessment) { create(:risk_assessment, trait, assessed_by_team:, assessed_by_business:, assessed_by_other:, investigation_products:) }
  let(:trait) { :without_file }
  let(:assessed_by_team) { nil }
  let(:assessed_by_business) { nil }
  let(:assessed_by_other) { "test" }
  let(:investigation_products) { [build(:investigation_product)] }
  let(:metadata) { described_class.build_metadata(risk_assessment) }

  describe "#metadata" do
    context "when the metadata is in the current format" do
      it "returns the metadata" do
        expect(activity.metadata).to eq(activity.read_attribute(:metadata))
      end
    end

    context "when the activity was generated prior to the metadata structure revision" do
      let(:trait) { :with_file }
      let(:metadata) do
        {
          risk_assessment_id: risk_assessment.id,
          assessed_on: risk_assessment.assessed_on,
          risk_level: risk_assessment.risk_level,
          custom_risk_level: risk_assessment.custom_risk_level,
          assessed_by_team_id: risk_assessment.assessed_by_team_id,
          assessed_by_business_id: risk_assessment.assessed_by_business_id,
          assessed_by_other: risk_assessment.assessed_by_other,
          details: risk_assessment.details,
          investigation_product_ids: risk_assessment.investigation_product_ids
        }
      end

      # rubocop:disable RSpec/ExampleLength
      it "returns a Hash in the new format" do
        expect(activity.metadata).to match({
          "risk_assessment" => hash_including({
            "id" => risk_assessment.id,
            "investigation_id" => risk_assessment.investigation_id,
            "assessed_on" => "2020-07-20",
            "assessed_by_team_id" => risk_assessment.assessed_by_team_id,
            "assessed_by_business_id" => risk_assessment.assessed_by_business_id,
            "assessed_by_other" => risk_assessment.assessed_by_other,
            "details" => risk_assessment.details,
            "custom_risk_level" => risk_assessment.custom_risk_level,
            "added_by_user_id" => risk_assessment.added_by_user_id,
            "added_by_team_id" => risk_assessment.added_by_team_id,
            "risk_level" => risk_assessment.risk_level,
            "investigation_product_ids" => risk_assessment.investigation_product_ids
          })
        })
      end
      # rubocop:enable RSpec/ExampleLength

      context "when the risk assessment has not been subsequently updated" do
        it "returns the file blob metadata" do
          expect(JSON.parse(activity.metadata["risk_assessment"]["risk_assessment_file"].to_json)).to eq(JSON.parse(risk_assessment.risk_assessment_file.blob.attributes.to_json))
        end

        it "returns the updated_at of the risk assessment" do
          expect(activity.metadata["risk_assessment"]["updated_at"].to_i).to eq(risk_assessment.updated_at.to_i)
        end
      end

      context "when the risk assessment has been subsequently updated" do
        before do
          UpdateRiskAssessment.call!(
            user: risk_assessment.added_by_user,
            risk_assessment:,
            details: "test update",
            assessed_on: risk_assessment.assessed_on,
            risk_level: risk_assessment.risk_level,
            investigation_product_ids: risk_assessment.investigation_product_ids,
            assessed_by_other: risk_assessment.assessed_by_other
          )
        end

        it "does not return the file blob metadata" do
          expect(activity.metadata["risk_assessment"]["risk_assessment_file"]).to be_nil
        end

        it "returns the updated_at of the activity" do
          expect(activity.metadata["risk_assessment"]["updated_at"]).to eq(activity.updated_at)
        end
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
      let(:product) { create(:investigation_product) }
      let(:investigation_products) { [product] }

      it "returns the product" do
        expect(activity.products_assessed).to eq(investigation_products)
      end
    end

    context "with multiple products on the risk assessment" do
      let(:product_1) { create(:investigation_product) }
      let(:product_2) { create(:investigation_product) }
      let(:investigation_products) { [product_1, product_2] }

      it "returns an Array of products" do
        expect(activity.products_assessed).to eq(investigation_products)
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

  describe "#custom_risk_level" do
    it "returns the risk assessment custom_risk_level" do
      expect(activity.custom_risk_level).to eq(risk_assessment.custom_risk_level)
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
