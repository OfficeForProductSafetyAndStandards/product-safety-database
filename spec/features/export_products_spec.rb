require "rails_helper"

RSpec.describe "Export products as XLSX file", :with_elasticsearch, :with_stubbed_notify, :with_stubbed_mailer, type: :request do
  describe "#index as XLSX" do
    let(:temp_dir) { "spec/tmp/" }
    let(:export_path) { Rails.root.join("#{temp_dir}export_products.xlsx") }
    let(:exported_data) do
      File.open(export_path, "w") { |f| f.write response.body }
      Roo::Excelx.new(export_path)
    end

    let!(:investigation)         { create(:allegation) }
    let!(:other_investigation)   { create(:allegation) }
    let!(:product)               { create(:product, investigations: [investigation], affected_units_status: "exact") }
    let!(:other_product)         { create(:product, investigations: [other_investigation]) }
    let!(:risk_assessment)       { create(:risk_assessment, investigation: investigation, products: [product]) }
    let!(:risk_assessment_2)     { create(:risk_assessment, investigation: investigation, products: [product]) }
    let!(:test)                  { create(:test_result, investigation: investigation, product: product, failure_details: "something bad") }
    let!(:test_2)                { create(:test_result, investigation: investigation, product: product, failure_details: "uh oh") }
    let!(:corrective_action)     { create(:corrective_action, investigation: investigation, product: product) }
    let!(:corrective_action_2)   { create(:corrective_action, investigation: investigation, product: product) }

    before do
      Dir.mkdir(temp_dir) unless Dir.exist?(temp_dir)
      sign_in(user)
    end

    context "when logged in as a normal user" do
      let(:user) { create(:user, :activated, :viewed_introduction) }

      it "shows a forbidden error", :with_errors_rendered, :aggregate_failures do
        get products_path format: :xlsx

        expect(response).to render_template("errors/forbidden")
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when logged in as a user with the psd_admin role" do
      let(:user) { create(:user, :activated, :psd_admin, :viewed_introduction) }

      it "exports correct sheets" do
        get products_path format: :xlsx

        expect(exported_data.sheets).to eq %w[product_info test_results risk_assessments corrective_actions]
      end

      context "with product_info sheet" do
        let(:sheet) { exported_data.sheet("product_info") }

        it "exports product ids" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 1)).to eq "ID"
          expect(sheet.cell(2, 1)).to eq product.id.to_s
          expect(sheet.cell(3, 1)).to eq other_product.id.to_s
        end

        it "exports affected_units_status" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 2)).to eq "affected_units_status"
          expect(sheet.cell(2, 2)).to eq product.affected_units_status
          expect(sheet.cell(3, 2)).to eq other_product.affected_units_status
        end

        it "exports authenticity" do
          get products_path format: :xlsx
          expect(sheet.cell(1, 3)).to eq "authenticity"
          expect(sheet.cell(2, 3)).to eq product.authenticity
          expect(sheet.cell(3, 3)).to eq other_product.authenticity
        end

        it "exports barcode" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 4)).to eq "barcode"
          expect(sheet.cell(2, 4)).to eq product.barcode
          expect(sheet.cell(3, 4)).to eq other_product.barcode
        end

        it "exports batch_number" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 5)).to eq "batch_number"
          expect(sheet.cell(2, 5)).to eq product.batch_number
          expect(sheet.cell(3, 5)).to eq other_product.batch_number
        end

        it "exports brand" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 6)).to eq "brand"
          expect(sheet.cell(2, 6)).to eq product.brand
          expect(sheet.cell(3, 6)).to eq other_product.brand
        end

        it "exports case_ids" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 7)).to eq "case_ids"
          expect(sheet.cell(2, 7)).to eq product.investigations.map(&:pretty_id).to_s
          expect(sheet.cell(3, 7)).to eq other_product.investigations.map(&:pretty_id).to_s
        end

        it "exports category" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 8)).to eq "category"
          expect(sheet.cell(2, 8)).to eq product.category
          expect(sheet.cell(3, 8)).to eq other_product.category
        end

        it "exports country_of_origin" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 9)).to eq "country_of_origin"
          expect(sheet.cell(2, 9)).to eq product.country_of_origin
          expect(sheet.cell(3, 9)).to eq other_product.country_of_origin
        end

        it "exports created_at" do
          get products_path format: :xlsx
          expect(sheet.cell(1, 10)).to eq "created_at"
          expect(sheet.cell(2, 10)).to eq product.created_at.to_s
          expect(sheet.cell(3, 10)).to eq other_product.created_at.to_s
        end

        it "exports customs_code" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 11)).to eq "customs_code"
          expect(sheet.cell(2, 11)).to eq product.customs_code
          expect(sheet.cell(3, 11)).to eq other_product.customs_code
        end

        it "exports description" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 12)).to eq "description"
          expect(sheet.cell(2, 12)).to eq product.description
          expect(sheet.cell(3, 12)).to eq other_product.description
        end

        it "exports has_markings" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 13)).to eq "has_markings"
          expect(sheet.cell(2, 13)).to eq product.has_markings
          expect(sheet.cell(3, 13)).to eq other_product.has_markings
        end

        it "exports markings" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 14)).to eq "markings"
          expect(sheet.cell(2, 14)).to eq product.markings.to_s
          expect(sheet.cell(3, 14)).to eq other_product.markings.to_s
        end

        it "exports name" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 15)).to eq "name"
          expect(sheet.cell(2, 15)).to eq product.name
          expect(sheet.cell(3, 15)).to eq other_product.name
        end

        it "exports number_of_affected_units" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 16)).to eq "number_of_affected_units"
          expect(sheet.cell(2, 16)).to eq product.number_of_affected_units
          expect(sheet.cell(3, 16)).to eq other_product.number_of_affected_units
        end

        it "exports product_code" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 17)).to eq "product_code"
          expect(sheet.cell(2, 17)).to eq product.product_code
          expect(sheet.cell(3, 17)).to eq other_product.product_code
        end

        it "exports subcategory" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 18)).to eq "subcategory"
          expect(sheet.cell(2, 18)).to eq product.subcategory
          expect(sheet.cell(3, 18)).to eq other_product.subcategory
        end

        it "exports updated_at" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 19)).to eq "updated_at"
          expect(sheet.cell(2, 19)).to eq product.updated_at.to_s
          expect(sheet.cell(3, 19)).to eq other_product.updated_at.to_s
        end

        it "exports webpage" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 20)).to eq "webpage"
          expect(sheet.cell(2, 20)).to eq product.webpage
          expect(sheet.cell(3, 20)).to eq other_product.webpage
        end

        it "exports when_placed_on_market" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 21)).to eq "when_placed_on_market"
          expect(sheet.cell(2, 21)).to eq product.when_placed_on_market
          expect(sheet.cell(3, 21)).to eq other_product.when_placed_on_market
        end

        it "exports reported_reason" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 22)).to eq "reported_reason"
          expect(sheet.cell(2, 22)).to eq product.investigations.first.reported_reason
          expect(sheet.cell(3, 22)).to eq other_product.investigations.first.reported_reason
        end

        it "exports hazard_type" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 23)).to eq "hazard_type"
          expect(sheet.cell(2, 23)).to eq product.investigations.first.hazard_type
          expect(sheet.cell(3, 23)).to eq other_product.investigations.first.hazard_type
        end

        it "exports non_compliant_reason" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 24)).to eq "non_compliant_reason"
          expect(sheet.cell(2, 24)).to eq product.investigations.first.non_compliant_reason
          expect(sheet.cell(3, 24)).to eq other_product.investigations.first.non_compliant_reason
        end

        it "exports risk_level" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 25)).to eq "risk_level"
          expect(sheet.cell(2, 25)).to eq product.investigations.first.risk_level
          expect(sheet.cell(3, 25)).to eq other_product.investigations.first.risk_level
        end
      end

      context "with test_results sheet" do
        let(:sheet) { exported_data.sheet("test_results") }

        it "exports product_id" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 1)).to eq "product_id"
          expect(sheet.cell(2, 1)).to eq product.id.to_s
          expect(sheet.cell(3, 1)).to eq product.id.to_s
        end

        it "exports legislation" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 2)).to eq "legislation"
          expect(sheet.cell(2, 2)).to eq test.legislation
          expect(sheet.cell(3, 2)).to eq test_2.legislation
        end

        it "exports standards" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 3)).to eq "standards"
          expect(sheet.cell(2, 3)).to eq test.standards_product_was_tested_against.to_s
          expect(sheet.cell(3, 3)).to eq test_2.standards_product_was_tested_against.to_s
        end

        it "exports date_of_test" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 4)).to eq "date_of_test"
          expect(sheet.cell(2, 4)).to eq test.date.to_s
          expect(sheet.cell(3, 4)).to eq test_2.date.to_s
        end

        it "exports result" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 5)).to eq "result"
          expect(sheet.cell(2, 5)).to eq test.result.to_s
          expect(sheet.cell(3, 5)).to eq test_2.result.to_s
        end

        it "exports how_product_failed" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 6)).to eq "how_product_failed"
          expect(sheet.cell(2, 6)).to eq test.failure_details.to_s
          expect(sheet.cell(3, 6)).to eq test_2.failure_details.to_s
        end

        it "exports further_details" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 7)).to eq "further_details"
          expect(sheet.cell(2, 7)).to eq test.details.to_s
          expect(sheet.cell(3, 7)).to eq test_2.details.to_s
        end
      end

      context "with risk_assessments sheet" do
        let(:sheet) { exported_data.sheet("risk_assessments") }

        it "exports product_id" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 1)).to eq "product_id"
          expect(sheet.cell(2, 1)).to eq product.id.to_s
          expect(sheet.cell(3, 1)).to eq product.id.to_s
        end

        it "exports date_of_assessment" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 2)).to eq "date_of_assessment"
          expect(sheet.cell(2, 2)).to eq risk_assessment.assessed_on.to_s
          expect(sheet.cell(3, 2)).to eq risk_assessment_2.assessed_on.to_s
        end

        it "exports risk_level" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 3)).to eq "risk_level"
          expect(sheet.cell(2, 3)).to eq risk_assessment.risk_level.to_s
          expect(sheet.cell(3, 3)).to eq risk_assessment_2.risk_level.to_s
        end

        it "exports assessed_by_business_id" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 4)).to eq "assessed_by_business_id"
          expect(sheet.cell(2, 4)).to eq risk_assessment.assessed_by_business_id
          expect(sheet.cell(3, 4)).to eq risk_assessment_2.assessed_by_business_id
        end

        it "exports assessed_by_team_id" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 5)).to eq "assessed_by_team_id"
          expect(sheet.cell(2, 5)).to eq risk_assessment.assessed_by_team_id.to_s
          expect(sheet.cell(3, 5)).to eq risk_assessment_2.assessed_by_team_id.to_s
        end

        it "exports further_details" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 6)).to eq "further_details"
          expect(sheet.cell(2, 6)).to eq risk_assessment.details.to_s
          expect(sheet.cell(3, 6)).to eq risk_assessment_2.details.to_s
        end
      end

      context "with corrective_actions sheet" do
        let(:sheet) { exported_data.sheet("corrective_actions") }

        it "exports product_id" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 1)).to eq "product_id"
          expect(sheet.cell(2, 1)).to eq product.id.to_s
          expect(sheet.cell(3, 1)).to eq product.id.to_s
        end

        it "exports action_taken" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 2)).to eq "action_taken"
          expect(sheet.cell(2, 2)).to eq corrective_action.action
          expect(sheet.cell(3, 2)).to eq corrective_action_2.action
        end

        it "exports date_of_action" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 3)).to eq "date_of_action"
          expect(sheet.cell(2, 3)).to eq corrective_action.date_decided.to_s
          expect(sheet.cell(3, 3)).to eq corrective_action_2.date_decided.to_s
        end

        it "exports legislation" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 4)).to eq "legislation"
          expect(sheet.cell(2, 4)).to eq corrective_action.legislation
          expect(sheet.cell(3, 4)).to eq corrective_action_2.legislation
        end

        it "exports business_responsible" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 5)).to eq "business_responsible"
          expect(sheet.cell(2, 5)).to eq corrective_action.business_id
          expect(sheet.cell(3, 5)).to eq corrective_action_2.business_id
        end

        it "exports recall_information_online" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 6)).to eq "recall_information_online"
          expect(sheet.cell(2, 6)).to eq corrective_action.online_recall_information
          expect(sheet.cell(3, 6)).to eq corrective_action_2.online_recall_information
        end

        it "exports mandatory_or_voluntary" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 7)).to eq "mandatory_or_voluntary"
          expect(sheet.cell(2, 7)).to eq corrective_action.measure_type
          expect(sheet.cell(3, 7)).to eq corrective_action_2.measure_type
        end

        it "exports how_long" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 8)).to eq "how_long"
          expect(sheet.cell(2, 8)).to eq corrective_action.duration
          expect(sheet.cell(3, 8)).to eq corrective_action_2.duration
        end

        it "exports geographic_scope" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 9)).to eq "geographic_scope"
          expect(sheet.cell(2, 9)).to eq corrective_action.geographic_scope
          expect(sheet.cell(3, 9)).to eq corrective_action_2.geographic_scope
        end

        it "exports further_details" do
          get products_path format: :xlsx

          expect(sheet.cell(1, 10)).to eq "further_details"
          expect(sheet.cell(2, 10)).to eq corrective_action.details
          expect(sheet.cell(3, 10)).to eq corrective_action_2.details
        end
      end
    end
  end
end
