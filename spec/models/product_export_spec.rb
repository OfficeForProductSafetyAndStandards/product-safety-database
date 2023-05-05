# rubocop:disable RSpec/LetSetup
# rubocop:disable RSpec/MultipleExpectations
# rubocop:disable RSpec/ExampleLength
require "rails_helper"

RSpec.describe ProductExport, :with_opensearch, :with_stubbed_notify, :with_stubbed_mailer, :with_stubbed_antivirus do
  let!(:investigation)          { create(:allegation).decorate }
  let!(:other_investigation)    { create(:allegation).decorate }
  let(:initial_product_description) { "Widget" }
  let(:new_product_description) { "Sausage" }
  # Create a new product version to ensure only the current version is rendered
  let(:country_of_origin)       { "country:GB-ENG" }
  let!(:product)                { create(:product, :with_versions, investigations: [investigation], country_of_origin:, description: initial_product_description, new_description: new_product_description).decorate }
  let!(:other_product)          { create(:product, investigations: [other_investigation], country_of_origin: nil).decorate }
  let!(:investigation_product)  { create(:investigation_product, product:, investigation:) }
  let!(:risk_assessment)        { create(:risk_assessment, investigation:, investigation_products: [investigation_product]).decorate }
  let!(:risk_assessment_2)      { create(:risk_assessment, investigation:, investigation_products: [investigation_product]).decorate }
  let!(:test)                   { create(:test_result, investigation:, investigation_product:, failure_details: "something bad").decorate }
  let!(:test_2)                 { create(:test_result, investigation:, investigation_product:, failure_details: "uh oh", standards_product_was_tested_against: ["EN71, EN72, test"]).decorate }
  let!(:corrective_action)      { create(:corrective_action, investigation:, investigation_product:).decorate }
  let!(:corrective_action_2)    { create(:corrective_action, investigation:, investigation_product:, geographic_scopes: %w[great_britain eea_wide worldwide]).decorate }
  let!(:user)                   { create(:user, :activated, has_viewed_introduction: true) }
  let(:params)                  { {} }
  let(:product_export)          { described_class.create!(user:, params:) }

  before { Product.import force: true, refresh: :wait }

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

    it "exports product data" do
      expect(product_sheet.cell(1, 1)).to eq "psd_ref"
      expect(product_sheet.cell(2, 1)).to eq product.psd_ref
      expect(product_sheet.cell(3, 1)).to eq other_product.psd_ref

      expect(product_sheet.cell(1, 2)).to eq "ID"
      expect(product_sheet.cell(2, 2)).to eq product.id.to_s
      expect(product_sheet.cell(3, 2)).to eq other_product.id.to_s

      expect(product_sheet.cell(1, 3)).to eq "authenticity"
      expect(product_sheet.cell(2, 3)).to eq product.authenticity
      expect(product_sheet.cell(3, 3)).to eq other_product.authenticity

      expect(product_sheet.cell(1, 4)).to eq "barcode"
      expect(product_sheet.cell(2, 4)).to eq product.barcode
      expect(product_sheet.cell(3, 4)).to eq other_product.barcode

      expect(product_sheet.cell(1, 5)).to eq "brand"
      expect(product_sheet.cell(2, 5)).to eq product.brand
      expect(product_sheet.cell(3, 5)).to eq other_product.brand

      expect(product_sheet.cell(1, 6)).to eq "case_id"
      expect(product_sheet.cell(2, 6)).to eq product.case_ids.first.to_s
      expect(product_sheet.cell(3, 6)).to eq other_product.case_ids.first.to_s

      expect(product_sheet.cell(1, 7)).to eq "category"
      expect(product_sheet.cell(2, 7)).to eq product.category
      expect(product_sheet.cell(3, 7)).to eq other_product.category

      expect(product_sheet.cell(1, 8)).to eq "country_of_origin"
      expect(product_sheet.cell(2, 8)).to eq "GB-ENG"
      expect(product_sheet.cell(3, 8)).to eq nil

      expect(product_sheet.cell(1, 9)).to eq "created_at"
      expect(product_sheet.cell(2, 9)).to eq product.created_at.to_formatted_s(:xmlschema)
      expect(product_sheet.cell(3, 9)).to eq other_product.created_at.to_formatted_s(:xmlschema)

      expect(product_sheet.cell(1, 10)).to eq "description"
      expect(product_sheet.cell(2, 10)).to eq "<p>#{new_product_description}</p>"
      expect(product_sheet.cell(3, 10)).to eq other_product.description

      expect(product_sheet.cell(1, 11)).to eq "has_markings"
      expect(product_sheet.cell(2, 11)).to eq product.has_markings
      expect(product_sheet.cell(3, 11)).to eq other_product.has_markings

      expect(product_sheet.cell(1, 12)).to eq "markings"
      expect(product_sheet.cell(2, 12)).to eq product.markings
      expect(product_sheet.cell(3, 12)).to eq other_product.markings

      expect(product_sheet.cell(1, 13)).to eq "name"
      expect(product_sheet.cell(2, 13)).to eq product.name
      expect(product_sheet.cell(3, 13)).to eq other_product.name

      expect(product_sheet.cell(1, 14)).to eq "product_code"
      expect(product_sheet.cell(2, 14)).to eq product.product_code
      expect(product_sheet.cell(3, 14)).to eq other_product.product_code

      expect(product_sheet.cell(1, 15)).to eq "subcategory"
      expect(product_sheet.cell(2, 15)).to eq product.subcategory
      expect(product_sheet.cell(3, 15)).to eq other_product.subcategory

      expect(product_sheet.cell(1, 16)).to eq "updated_at"
      expect(product_sheet.cell(2, 16)).to eq product.updated_at.to_formatted_s(:xmlschema)
      expect(product_sheet.cell(3, 16)).to eq other_product.updated_at.to_formatted_s(:xmlschema)

      expect(product_sheet.cell(1, 17)).to eq "webpage"
      expect(product_sheet.cell(2, 17)).to eq product.webpage
      expect(product_sheet.cell(3, 17)).to eq other_product.webpage

      expect(product_sheet.cell(1, 18)).to eq "when_placed_on_market"
      expect(product_sheet.cell(2, 18)).to eq product.when_placed_on_market
      expect(product_sheet.cell(3, 18)).to eq other_product.when_placed_on_market

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
      expect(risk_assessments_sheet.cell(2, 3)).to eq risk_assessment.assessed_on.to_formatted_s(:xmlschema)
      expect(risk_assessments_sheet.cell(3, 3)).to eq risk_assessment_2.assessed_on.to_formatted_s(:xmlschema)

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
  end

  context "when there is a product with multiple cases" do
    let(:investigation_a) { create(:allegation).decorate }
    let(:investigation_b) { create(:allegation).decorate }
    let!(:multiple_case_product) { create(:product, investigations: [investigation_a, investigation_b]).decorate }
    let!(:investigation_product_a)  { create(:investigation_product, product: multiple_case_product, investigation: investigation_a) }
    let!(:investigation_product_b)  { create(:investigation_product, product: multiple_case_product, investigation: investigation_b) }
    let!(:risk_assessment) { create(:risk_assessment, investigation: investigation_a, investigation_products: [investigation_product_a]).decorate }
    let!(:risk_assessment_2) { create(:risk_assessment, investigation: investigation_b, investigation_products: [investigation_product_b]).decorate }

    let(:spreadsheet) { product_export.to_spreadsheet.to_stream }
    let(:exported_data) { Roo::Excelx.new(spreadsheet) }
    let(:products_sheet) { exported_data.sheet("product_info") }

    it "exports the product into multiple rows, each with a different case" do
      expect(products_sheet.cell(1, 1)).to eq "psd_ref"
      expect(products_sheet.cell(2, 1)).to eq product.psd_ref
      expect(products_sheet.cell(3, 1)).to eq other_product.psd_ref
      expect(products_sheet.cell(4, 1)).to eq multiple_case_product.psd_ref
      expect(products_sheet.cell(5, 1)).to eq multiple_case_product.psd_ref

      expect(products_sheet.cell(1, 6)).to eq "case_id"
      expect(products_sheet.cell(2, 6)).to eq product.case_ids.first.to_s
      expect(products_sheet.cell(3, 6)).to eq other_product.case_ids.first.to_s
      expect(products_sheet.cell(4, 6)).to eq multiple_case_product.case_ids[0].to_s
      expect(products_sheet.cell(5, 6)).to eq multiple_case_product.case_ids[1].to_s
    end
  end
end

# rubocop:enable RSpec/MultipleExpectations
# rubocop:enable RSpec/ExampleLength
# rubocop:enable RSpec/LetSetup
