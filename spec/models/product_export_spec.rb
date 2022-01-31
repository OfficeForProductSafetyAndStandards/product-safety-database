require "rails_helper"

RSpec.describe ProductExport, :with_opensearch, :with_stubbed_notify, :with_stubbed_mailer, :with_stubbed_antivirus do
  let!(:investigation)       { create(:allegation).decorate }
  let!(:other_investigation) { create(:allegation).decorate }
  let!(:product)             { create(:product, investigations: [investigation], affected_units_status: "exact").decorate }
  let!(:other_product)       { create(:product, investigations: [other_investigation]).decorate }
  let!(:risk_assessment)     { create(:risk_assessment, investigation: investigation, products: [product]).decorate }
  let!(:risk_assessment_2)   { create(:risk_assessment, investigation: investigation, products: [product]).decorate }
  let!(:test)                { create(:test_result, investigation: investigation, product: product, failure_details: "something bad").decorate }
  let!(:test_2)              { create(:test_result, investigation: investigation, product: product, failure_details: "uh oh", standards_product_was_tested_against: ["EN71, EN72, test"]).decorate }
  let!(:corrective_action)   { create(:corrective_action, investigation: investigation, product: product).decorate }
  let!(:corrective_action_2) { create(:corrective_action, investigation: investigation, product: product, geographic_scopes: %w[great_britain eea_wide worldwide]).decorate }
  let!(:user)                { create(:user, :activated, has_viewed_introduction: true) }
  let(:params)               { {} }
  let(:product_export)       { described_class.create!(user: user, params: params) }

  before { Product.__elasticsearch__.import force: true, refresh: :wait }

  describe "#export!" do
    let(:result) { product_export.export! }

    it "attaches the spreadsheet as a file" do
      result
      expect(product_export.export_file).to be_attached
    end
  end

  describe "#to_spreadsheet" do
    let(:spreadsheet) { product_export.to_spreadsheet.to_stream }
    let(:exported_data) { Roo::Excelx.new(spreadsheet) }
    let(:product_sheet) { exported_data.sheet("product_info") }
    let(:test_result_sheet) { exported_data.sheet("test_results") }
    let(:risk_assessments_sheet) { exported_data.sheet("risk_assessments") }
    let(:corrective_actions_sheet) { exported_data.sheet("corrective_actions") }

    # rubocop:disable RSpec/MultipleExpectations
    # rubocop:disable RSpec/ExampleLength
    it "exports product data" do
      expect(product_sheet.cell(1, 1)).to eq "psd_ref"
      expect(product_sheet.cell(2, 1)).to eq product.psd_ref
      expect(product_sheet.cell(3, 1)).to eq other_product.psd_ref

      expect(product_sheet.cell(1, 2)).to eq "ID"
      expect(product_sheet.cell(2, 2)).to eq product.id.to_s
      expect(product_sheet.cell(3, 2)).to eq other_product.id.to_s

      expect(product_sheet.cell(1, 3)).to eq "affected_units_status"
      expect(product_sheet.cell(2, 3)).to eq product.affected_units_status
      expect(product_sheet.cell(3, 3)).to eq other_product.affected_units_status

      expect(product_sheet.cell(1, 4)).to eq "authenticity"
      expect(product_sheet.cell(2, 4)).to eq product.authenticity
      expect(product_sheet.cell(3, 4)).to eq other_product.authenticity

      expect(product_sheet.cell(1, 5)).to eq "barcode"
      expect(product_sheet.cell(2, 5)).to eq product.barcode
      expect(product_sheet.cell(3, 5)).to eq other_product.barcode

      expect(product_sheet.cell(1, 6)).to eq "batch_number"
      expect(product_sheet.cell(2, 6)).to eq product.batch_number
      expect(product_sheet.cell(3, 6)).to eq other_product.batch_number

      expect(product_sheet.cell(1, 7)).to eq "brand"
      expect(product_sheet.cell(2, 7)).to eq product.brand
      expect(product_sheet.cell(3, 7)).to eq other_product.brand

      expect(product_sheet.cell(1, 8)).to eq "case_ids"
      expect(product_sheet.cell(2, 8)).to eq product.case_ids.to_s
      expect(product_sheet.cell(3, 8)).to eq other_product.case_ids.to_s

      expect(product_sheet.cell(1, 9)).to eq "category"
      expect(product_sheet.cell(2, 9)).to eq product.category
      expect(product_sheet.cell(3, 9)).to eq other_product.category

      expect(product_sheet.cell(1, 10)).to eq "country_of_origin"
      expect(product_sheet.cell(2, 10)).to eq product.country_of_origin
      expect(product_sheet.cell(3, 10)).to eq other_product.country_of_origin

      expect(product_sheet.cell(1, 11)).to eq "created_at"
      expect(product_sheet.cell(2, 11)).to eq product.created_at.to_s
      expect(product_sheet.cell(3, 11)).to eq other_product.created_at.to_s

      expect(product_sheet.cell(1, 12)).to eq "customs_code"
      expect(product_sheet.cell(2, 12)).to eq product.customs_code
      expect(product_sheet.cell(3, 12)).to eq other_product.customs_code

      expect(product_sheet.cell(1, 13)).to eq "description"
      expect(product_sheet.cell(2, 13)).to eq product.description
      expect(product_sheet.cell(3, 13)).to eq other_product.description

      expect(product_sheet.cell(1, 14)).to eq "has_markings"
      expect(product_sheet.cell(2, 14)).to eq product.has_markings
      expect(product_sheet.cell(3, 14)).to eq other_product.has_markings

      expect(product_sheet.cell(1, 15)).to eq "markings"
      expect(product_sheet.cell(2, 15)).to eq product.markings
      expect(product_sheet.cell(3, 15)).to eq other_product.markings

      expect(product_sheet.cell(1, 16)).to eq "name"
      expect(product_sheet.cell(2, 16)).to eq product.name
      expect(product_sheet.cell(3, 16)).to eq other_product.name

      expect(product_sheet.cell(1, 17)).to eq "number_of_affected_units"
      expect(product_sheet.cell(2, 17)).to eq product.number_of_affected_units
      expect(product_sheet.cell(3, 17)).to eq other_product.number_of_affected_units

      expect(product_sheet.cell(1, 18)).to eq "product_code"
      expect(product_sheet.cell(2, 18)).to eq product.product_code
      expect(product_sheet.cell(3, 18)).to eq other_product.product_code

      expect(product_sheet.cell(1, 19)).to eq "subcategory"
      expect(product_sheet.cell(2, 19)).to eq product.subcategory
      expect(product_sheet.cell(3, 19)).to eq other_product.subcategory

      expect(product_sheet.cell(1, 20)).to eq "updated_at"
      expect(product_sheet.cell(2, 20)).to eq product.updated_at.to_s
      expect(product_sheet.cell(3, 20)).to eq other_product.updated_at.to_s

      expect(product_sheet.cell(1, 21)).to eq "webpage"
      expect(product_sheet.cell(2, 21)).to eq product.webpage
      expect(product_sheet.cell(3, 21)).to eq other_product.webpage

      expect(product_sheet.cell(1, 22)).to eq "when_placed_on_market"
      expect(product_sheet.cell(2, 22)).to eq product.when_placed_on_market
      expect(product_sheet.cell(3, 22)).to eq other_product.when_placed_on_market

      expect(product_sheet.cell(1, 23)).to eq "reported_reason"
      expect(product_sheet.cell(2, 23)).to eq product.investigations.first.reported_reason
      expect(product_sheet.cell(3, 23)).to eq other_product.investigations.first.reported_reason

      expect(product_sheet.cell(1, 24)).to eq "hazard_type"
      expect(product_sheet.cell(2, 24)).to eq product.investigations.first.hazard_type
      expect(product_sheet.cell(3, 24)).to eq other_product.investigations.first.hazard_type

      expect(product_sheet.cell(1, 25)).to eq "non_compliant_reason"
      expect(product_sheet.cell(2, 25)).to eq product.investigations.first.non_compliant_reason
      expect(product_sheet.cell(3, 25)).to eq other_product.investigations.first.non_compliant_reason

      expect(product_sheet.cell(1, 26)).to eq "risk_level"
      expect(product_sheet.cell(2, 26)).to eq product.investigations.first.risk_level
      expect(product_sheet.cell(3, 26)).to eq other_product.investigations.first.risk_level

      expect(test_result_sheet.cell(1, 1)).to eq "psd_ref"
      expect(test_result_sheet.cell(2, 1)).to eq product.psd_ref
      expect(test_result_sheet.cell(3, 1)).to eq product.psd_ref

      expect(test_result_sheet.cell(1, 2)).to eq "product_id"
      expect(test_result_sheet.cell(2, 2)).to eq product.id.to_s
      expect(test_result_sheet.cell(3, 2)).to eq product.id.to_s

      expect(test_result_sheet.cell(1, 3)).to eq "legislation"
      expect(test_result_sheet.cell(2, 3)).to eq test.legislation
      expect(test_result_sheet.cell(3, 3)).to eq test_2.legislation

      expect(test_result_sheet.cell(1, 4)).to eq "standards"
      expect(test_result_sheet.cell(2, 4)).to eq test.standards_product_was_tested_against
      expect(test_result_sheet.cell(3, 4)).to eq test_2.standards_product_was_tested_against

      expect(test_result_sheet.cell(1, 5)).to eq "date_of_test"
      expect(test_result_sheet.cell(2, 5)).to eq test.date_of_activity
      expect(test_result_sheet.cell(3, 5)).to eq test_2.date_of_activity

      expect(test_result_sheet.cell(1, 6)).to eq "result"
      expect(test_result_sheet.cell(2, 6)).to eq test.result.to_s
      expect(test_result_sheet.cell(3, 6)).to eq test_2.result.to_s

      expect(test_result_sheet.cell(1, 7)).to eq "how_product_failed"
      expect(test_result_sheet.cell(2, 7)).to eq test.failure_details.to_s
      expect(test_result_sheet.cell(3, 7)).to eq test_2.failure_details.to_s

      expect(test_result_sheet.cell(1, 8)).to eq "further_details"
      expect(test_result_sheet.cell(2, 8)).to eq test.details.to_s
      expect(test_result_sheet.cell(3, 8)).to eq test_2.details.to_s

      expect(test_result_sheet.cell(1, 9)).to eq "product_name"
      expect(test_result_sheet.cell(2, 9)).to eq product.name
      expect(test_result_sheet.cell(3, 9)).to eq product.name

      expect(risk_assessments_sheet.cell(1, 1)).to eq "psd_ref"
      expect(risk_assessments_sheet.cell(2, 1)).to eq product.psd_ref
      expect(risk_assessments_sheet.cell(3, 1)).to eq product.psd_ref

      expect(risk_assessments_sheet.cell(1, 2)).to eq "product_id"
      expect(risk_assessments_sheet.cell(2, 2)).to eq product.id.to_s
      expect(risk_assessments_sheet.cell(3, 2)).to eq product.id.to_s

      expect(risk_assessments_sheet.cell(1, 3)).to eq "date_of_assessment"
      expect(risk_assessments_sheet.cell(2, 3)).to eq risk_assessment.assessed_on.to_s
      expect(risk_assessments_sheet.cell(3, 3)).to eq risk_assessment_2.assessed_on.to_s

      expect(risk_assessments_sheet.cell(1, 4)).to eq "risk_level"
      expect(risk_assessments_sheet.cell(2, 4)).to eq risk_assessment.risk_level.to_s
      expect(risk_assessments_sheet.cell(3, 4)).to eq risk_assessment_2.risk_level.to_s

      expect(risk_assessments_sheet.cell(1, 5)).to eq "assessed_by"
      expect(risk_assessments_sheet.cell(2, 5)).to eq Team.find(risk_assessment.assessed_by_team_id).name
      expect(risk_assessments_sheet.cell(3, 5)).to eq Team.find(risk_assessment_2.assessed_by_team_id).name

      expect(risk_assessments_sheet.cell(1, 6)).to eq "further_details"
      expect(risk_assessments_sheet.cell(2, 6)).to eq risk_assessment.details.to_s
      expect(risk_assessments_sheet.cell(3, 6)).to eq risk_assessment_2.details.to_s

      expect(risk_assessments_sheet.cell(1, 7)).to eq "product_name"
      expect(risk_assessments_sheet.cell(2, 7)).to eq product.name
      expect(risk_assessments_sheet.cell(3, 7)).to eq product.name

      expect(corrective_actions_sheet.cell(1, 1)).to eq "psd_ref"
      expect(corrective_actions_sheet.cell(2, 1)).to eq product.psd_ref
      expect(corrective_actions_sheet.cell(3, 1)).to eq product.psd_ref

      expect(corrective_actions_sheet.cell(1, 2)).to eq "product_id"
      expect(corrective_actions_sheet.cell(2, 2)).to eq product.id.to_s
      expect(corrective_actions_sheet.cell(3, 2)).to eq product.id.to_s

      expect(corrective_actions_sheet.cell(1, 3)).to eq "action_taken"
      expect(corrective_actions_sheet.cell(2, 3)).to eq CorrectiveAction.actions[corrective_action.action]
      expect(corrective_actions_sheet.cell(3, 3)).to eq CorrectiveAction.actions[corrective_action_2.action]

      expect(corrective_actions_sheet.cell(1, 4)).to eq "date_of_action"
      expect(corrective_actions_sheet.cell(2, 4)).to eq corrective_action.date_of_activity
      expect(corrective_actions_sheet.cell(3, 4)).to eq corrective_action_2.date_of_activity

      expect(corrective_actions_sheet.cell(1, 5)).to eq "legislation"
      expect(corrective_actions_sheet.cell(2, 5)).to eq corrective_action.legislation
      expect(corrective_actions_sheet.cell(3, 5)).to eq corrective_action_2.legislation

      expect(corrective_actions_sheet.cell(1, 6)).to eq "business_responsible"
      expect(corrective_actions_sheet.cell(2, 6)).to eq corrective_action.business_id
      expect(corrective_actions_sheet.cell(3, 6)).to eq corrective_action_2.business_id

      expect(corrective_actions_sheet.cell(1, 7)).to eq "recall_information_online"
      expect(corrective_actions_sheet.cell(2, 7)).to eq corrective_action.online_recall_information
      expect(corrective_actions_sheet.cell(3, 7)).to eq corrective_action_2.online_recall_information

      expect(corrective_actions_sheet.cell(1, 8)).to eq "mandatory_or_voluntary"
      expect(corrective_actions_sheet.cell(2, 8)).to eq corrective_action.measure_type
      expect(corrective_actions_sheet.cell(3, 8)).to eq corrective_action_2.measure_type

      expect(corrective_actions_sheet.cell(1, 9)).to eq "how_long"
      expect(corrective_actions_sheet.cell(2, 9)).to eq corrective_action.duration
      expect(corrective_actions_sheet.cell(3, 9)).to eq corrective_action_2.duration

      expect(corrective_actions_sheet.cell(1, 10)).to eq "geographic_scope"
      expect(corrective_actions_sheet.cell(2, 10)).to eq corrective_action.geographic_scopes
      expect(corrective_actions_sheet.cell(3, 10)).to eq corrective_action_2.geographic_scopes

      expect(corrective_actions_sheet.cell(1, 11)).to eq "further_details"
      expect(corrective_actions_sheet.cell(2, 11)).to eq corrective_action.details
      expect(corrective_actions_sheet.cell(3, 11)).to eq corrective_action_2.details

      expect(corrective_actions_sheet.cell(1, 12)).to eq "product_name"
      expect(corrective_actions_sheet.cell(2, 12)).to eq product.name
      expect(corrective_actions_sheet.cell(3, 12)).to eq product.name
    end
    # rubocop:enable RSpec/MultipleExpectations
    # rubocop:enable RSpec/ExampleLength
  end
end
