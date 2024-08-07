# rubocop:disable RSpec/LetSetup
# rubocop:disable RSpec/ExampleLength
require "rails_helper"

RSpec.describe ProductExport, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_notify do
  let!(:investigation) do
    create(:notification,
           reported_reason: "unsafe",
           hazard_type: "Electromagnetic disturbance",
           hazard_description: "Much fire",
           non_compliant_reason: "On fire, lots of fire",
           risk_level: "serious").decorate
  end
  let!(:other_investigation) { create(:notification).decorate }
  let(:initial_product_description) { "Widget" }
  let(:new_product_description) { "Sausage" }
  # Create a new product version to ensure only the current version is rendered
  let(:country_of_origin)       { "country:GB-ENG" }
  let!(:product)                { create(:product, :with_versions, country_of_origin:, description: initial_product_description, new_description: new_product_description).decorate }
  let!(:other_product)          { create(:product, country_of_origin: nil).decorate }
  let!(:investigation_product)  { create(:investigation_product, product:, investigation:, affected_units_status: "approx", number_of_affected_units: 49, batch_number: "2112", customs_code: "6987") }
  let!(:investigation_product_2) { create(:investigation_product, product: other_product, investigation: other_investigation) }
  let!(:notification) { create(:better_notif, creator: user) }
  let!(:risk_assessment)        { create(:risk_assessment, investigation:, investigation_products: [investigation_product]).decorate }
  let!(:risk_assessment_2)      { create(:risk_assessment, investigation:, investigation_products: [investigation_product]).decorate }
  let!(:test)                   { create(:test_result, investigation:, investigation_product:, failure_details: "something bad", tso_certificate_issue_date: Time.zone.now, tso_certificate_reference_number: "12321").decorate }
  let!(:test_2)                 { create(:test_result, investigation:, investigation_product:, failure_details: "uh oh", standards_product_was_tested_against: ["EN71, EN72, test"]).decorate }
  let!(:corrective_action)      { create(:corrective_action, investigation:, investigation_product:).decorate }
  let!(:corrective_action_2)    { create(:corrective_action, investigation:, investigation_product:, geographic_scopes: %w[great_britain eea_wide worldwide]).decorate }
  let!(:user)                   { create(:user, :opss_user, :activated, has_viewed_introduction: true) }
  let(:params)                  { {} }
  let(:product_export)          { described_class.create!(user:, params:) }

  describe "#export!" do
    let(:result) { product_export.export! }

    it "attaches the spreadsheet as a file" do
      result
      expect(product_export.export_file).to be_attached
    end
  end

  describe "#get_owner_filter" do
    it "equal the owner output" do
      AddProductToNotification.call!(notification:, product:, user:)
      AddProductToNotification.call!(notification:, product: other_product, user:)
      product_export.send(:products)
      product_export.send(:filter_params, user)

      product_export = described_class.create!(user:, params: { case_owner: "my_team" })
      product_export.send(:products)
      expect(product_export.send(:filter_params, user)).to eq my_team_query

      product_export = described_class.create!(user:, params: { case_owner: "me" })
      product_export.send(:products)
      expect(product_export.send(:filter_params, user)).to eq my_query
    end
  end

  describe "#to_spreadsheet" do
    let(:spreadsheet) { product_export.to_spreadsheet.to_stream }
    let(:exported_data) { Roo::Excelx.new(spreadsheet) }
    let(:product_sheet) { exported_data.sheet("product_info") }
    let(:test_result_sheet) { exported_data.sheet("test_results") }
    let(:risk_assessments_sheet) { exported_data.sheet("risk_assessments") }
    let(:corrective_actions_sheet) { exported_data.sheet("corrective_actions") }

    it "exports product data", :aggregate_failures do
      expect(product_sheet.cell(1, 1)).to eq "psd_ref"
      expect(product_sheet.cell(2, 1)).to eq product.psd_ref
      expect(product_sheet.cell(3, 1)).to eq other_product.psd_ref

      expect(product_sheet.cell(1, 2)).to eq "ID"
      expect(product_sheet.cell(2, 2)).to eq product.id.to_s
      expect(product_sheet.cell(3, 2)).to eq other_product.id.to_s

      expect(product_sheet.cell(1, 3)).to eq "case_id"
      expect(product_sheet.cell(2, 3)).to eq investigation.pretty_id
      expect(product_sheet.cell(3, 3)).to eq other_investigation.pretty_id

      expect(product_sheet.cell(1, 4)).to eq "case_type"
      expect(product_sheet.cell(2, 4)).to eq investigation.case_type
      expect(product_sheet.cell(3, 4)).to eq other_investigation.case_type

      expect(product_sheet.cell(1, 5)).to eq "category"
      expect(product_sheet.cell(2, 5)).to eq product.category
      expect(product_sheet.cell(3, 5)).to eq other_product.category

      expect(product_sheet.cell(1, 6)).to eq "subcategory"
      expect(product_sheet.cell(2, 6)).to eq product.subcategory
      expect(product_sheet.cell(3, 6)).to eq other_product.subcategory

      expect(product_sheet.cell(1, 7)).to eq "barcode"
      expect(product_sheet.cell(2, 7)).to eq product.barcode
      expect(product_sheet.cell(3, 7)).to eq other_product.barcode

      expect(product_sheet.cell(1, 8)).to eq "brand"
      expect(product_sheet.cell(2, 8)).to eq product.brand
      expect(product_sheet.cell(3, 8)).to eq other_product.brand

      expect(product_sheet.cell(1, 9)).to eq "authenticity"
      expect(product_sheet.cell(2, 9)).to eq product.authenticity
      expect(product_sheet.cell(3, 9)).to eq other_product.authenticity

      expect(product_sheet.cell(1, 10)).to eq "name"
      expect(product_sheet.cell(2, 10)).to eq product.name
      expect(product_sheet.cell(3, 10)).to eq other_product.name

      expect(product_sheet.cell(1, 11)).to eq "product_code"
      expect(product_sheet.cell(2, 11)).to eq product.product_code
      expect(product_sheet.cell(3, 11)).to eq other_product.product_code

      expect(product_sheet.cell(1, 12)).to eq "description"
      expect(product_sheet.cell(2, 12)).to eq "<p>#{new_product_description}</p>"
      expect(product_sheet.cell(3, 12)).to eq other_product.description

      expect(product_sheet.cell(1, 13)).to eq "has_markings"
      expect(product_sheet.cell(2, 13)).to eq product.has_markings
      expect(product_sheet.cell(3, 13)).to eq other_product.has_markings

      expect(product_sheet.cell(1, 14)).to eq "markings"
      expect(product_sheet.cell(2, 14)).to eq product.markings
      expect(product_sheet.cell(3, 14)).to eq other_product.markings

      expect(product_sheet.cell(1, 15)).to eq "country_of_origin"
      expect(product_sheet.cell(2, 15)).to eq "GB-ENG"
      expect(product_sheet.cell(3, 15)).to be_nil

      expect(product_sheet.cell(1, 16)).to eq "webpage"
      expect(product_sheet.cell(2, 16)).to eq product.webpage
      expect(product_sheet.cell(3, 16)).to eq other_product.webpage

      expect(product_sheet.cell(1, 17)).to eq "when_placed_on_market"
      expect(product_sheet.cell(2, 17)).to eq product.when_placed_on_market
      expect(product_sheet.cell(3, 17)).to eq other_product.when_placed_on_market

      expect(product_sheet.cell(1, 18)).to eq "affected_units_status"
      expect(product_sheet.cell(2, 18)).to eq investigation_product.affected_units_status
      expect(product_sheet.cell(3, 18)).to eq investigation_product_2.affected_units_status

      expect(product_sheet.cell(1, 19)).to eq "number_of_affected_units"
      expect(product_sheet.cell(2, 19)).to eq investigation_product.number_of_affected_units
      expect(product_sheet.cell(3, 19)).to eq investigation_product_2.number_of_affected_units

      expect(product_sheet.cell(1, 20)).to eq "batch_number"
      expect(product_sheet.cell(2, 20)).to eq investigation_product.batch_number
      expect(product_sheet.cell(3, 20)).to eq investigation_product_2.batch_number

      expect(product_sheet.cell(1, 21)).to eq "customs_code"
      expect(product_sheet.cell(2, 21)).to eq investigation_product.customs_code
      expect(product_sheet.cell(3, 21)).to eq investigation_product_2.customs_code

      expect(product_sheet.cell(1, 22)).to eq "created_at"
      expect(product_sheet.cell(2, 23)).to eq product.created_at.to_formatted_s(:xmlschema)
      expect(product_sheet.cell(3, 22)).to eq other_product.created_at.to_formatted_s(:xmlschema)

      expect(product_sheet.cell(1, 23)).to eq "updated_at"
      expect(product_sheet.cell(2, 23)).to eq product.updated_at.to_formatted_s(:xmlschema)
      expect(product_sheet.cell(3, 23)).to eq other_product.updated_at.to_formatted_s(:xmlschema)

      expect(test_result_sheet.cell(1, 1)).to eq "psd_ref"
      expect(test_result_sheet.cell(2, 1)).to eq product.psd_ref
      expect(test_result_sheet.cell(3, 1)).to eq product.psd_ref

      expect(test_result_sheet.cell(1, 2)).to eq "product_id"
      expect(test_result_sheet.cell(2, 2)).to eq product.id.to_s
      expect(test_result_sheet.cell(3, 2)).to eq product.id.to_s

      expect(test_result_sheet.cell(1, 3)).to eq "case_id"
      expect(test_result_sheet.cell(2, 3)).to eq test.investigation.pretty_id
      expect(test_result_sheet.cell(3, 3)).to eq test_2.investigation.pretty_id

      expect(test_result_sheet.cell(1, 4)).to eq "case_type"
      expect(test_result_sheet.cell(2, 4)).to eq test.investigation.case_type
      expect(test_result_sheet.cell(3, 4)).to eq test_2.investigation.case_type

      expect(test_result_sheet.cell(1, 5)).to eq "product_name"
      expect(test_result_sheet.cell(2, 5)).to eq product.name
      expect(test_result_sheet.cell(3, 5)).to eq product.name

      expect(test_result_sheet.cell(1, 6)).to eq "date_of_test"
      expect(test_result_sheet.cell(2, 6)).to eq test.date_of_activity
      expect(test_result_sheet.cell(3, 6)).to eq test_2.date_of_activity

      expect(test_result_sheet.cell(1, 7)).to eq "legislation"
      expect(test_result_sheet.cell(2, 7)).to eq test.legislation
      expect(test_result_sheet.cell(3, 7)).to eq test_2.legislation

      expect(test_result_sheet.cell(1, 8)).to eq "standards"
      expect(test_result_sheet.cell(2, 8)).to eq test.standards_product_was_tested_against
      expect(test_result_sheet.cell(3, 8)).to eq test_2.standards_product_was_tested_against

      expect(test_result_sheet.cell(1, 9)).to eq "result"
      expect(test_result_sheet.cell(2, 9)).to eq test.result.to_s
      expect(test_result_sheet.cell(3, 9)).to eq test_2.result.to_s

      expect(test_result_sheet.cell(1, 10)).to eq "how_product_failed"
      expect(test_result_sheet.cell(2, 10)).to eq test.failure_details.to_s
      expect(test_result_sheet.cell(3, 10)).to eq test_2.failure_details.to_s

      expect(test_result_sheet.cell(1, 11)).to eq "further_details"
      expect(test_result_sheet.cell(2, 11)).to eq test.details.to_s
      expect(test_result_sheet.cell(3, 11)).to eq test_2.details.to_s

      expect(test_result_sheet.cell(1, 12)).to eq "date_added"
      expect(test_result_sheet.cell(2, 12)).to eq test.created_at.to_formatted_s(:xmlschema)
      expect(test_result_sheet.cell(3, 12)).to eq test_2.created_at.to_formatted_s(:xmlschema)

      expect(test_result_sheet.cell(1, 13)).to eq "funded_under_opss_sampling_protocol"
      expect(test_result_sheet.cell(2, 13)).to eq "true"
      expect(test_result_sheet.cell(3, 13)).to eq "false"

      expect(test_result_sheet.cell(1, 14)).to eq "tso_sample_reference_number"
      expect(test_result_sheet.cell(2, 14)).to eq test.tso_certificate_reference_number
      expect(test_result_sheet.cell(3, 14)).to be_nil

      expect(test_result_sheet.cell(1, 15)).to eq "date_issued"
      expect(test_result_sheet.cell(2, 15)).to eq test.tso_certificate_issue_date.to_formatted_s(:xmlschema)
      expect(test_result_sheet.cell(3, 15)).to be_nil

      expect(risk_assessments_sheet.cell(1, 1)).to eq "psd_ref"
      expect(risk_assessments_sheet.cell(2, 1)).to eq product.psd_ref
      expect(risk_assessments_sheet.cell(3, 1)).to eq product.psd_ref

      expect(risk_assessments_sheet.cell(1, 2)).to eq "product_id"
      expect(risk_assessments_sheet.cell(2, 2)).to eq product.id.to_s
      expect(risk_assessments_sheet.cell(3, 2)).to eq product.id.to_s

      expect(risk_assessments_sheet.cell(1, 3)).to eq "case_id"
      expect(risk_assessments_sheet.cell(2, 3)).to eq risk_assessment.investigation.pretty_id
      expect(risk_assessments_sheet.cell(3, 3)).to eq risk_assessment_2.investigation.pretty_id

      expect(risk_assessments_sheet.cell(1, 4)).to eq "case_type"
      expect(risk_assessments_sheet.cell(2, 4)).to eq risk_assessment.investigation.case_type
      expect(risk_assessments_sheet.cell(3, 4)).to eq risk_assessment_2.investigation.case_type

      expect(risk_assessments_sheet.cell(1, 5)).to eq "product_name"
      expect(risk_assessments_sheet.cell(2, 5)).to eq product.name
      expect(risk_assessments_sheet.cell(3, 5)).to eq product.name

      expect(risk_assessments_sheet.cell(1, 6)).to eq "date_of_assessment"
      expect(risk_assessments_sheet.cell(2, 6)).to eq risk_assessment.assessed_on.to_formatted_s(:xmlschema)
      expect(risk_assessments_sheet.cell(3, 6)).to eq risk_assessment_2.assessed_on.to_formatted_s(:xmlschema)

      expect(risk_assessments_sheet.cell(1, 7)).to eq "risk_level"
      expect(risk_assessments_sheet.cell(2, 7)).to eq risk_assessment.risk_level.to_s
      expect(risk_assessments_sheet.cell(3, 7)).to eq risk_assessment_2.risk_level.to_s

      expect(risk_assessments_sheet.cell(1, 8)).to eq "assessed_by"
      expect(risk_assessments_sheet.cell(2, 8)).to eq Team.find(risk_assessment.assessed_by_team_id).name
      expect(risk_assessments_sheet.cell(3, 8)).to eq Team.find(risk_assessment_2.assessed_by_team_id).name

      expect(risk_assessments_sheet.cell(1, 9)).to eq "further_details"
      expect(risk_assessments_sheet.cell(2, 9)).to eq risk_assessment.details.to_s
      expect(risk_assessments_sheet.cell(3, 9)).to eq risk_assessment_2.details.to_s

      expect(risk_assessments_sheet.cell(1, 10)).to eq "reported_reason"
      expect(risk_assessments_sheet.cell(2, 10)).to eq risk_assessment.investigation.reported_reason
      expect(risk_assessments_sheet.cell(3, 10)).to eq risk_assessment_2.investigation.reported_reason

      expect(risk_assessments_sheet.cell(1, 11)).to eq "hazard_type"
      expect(risk_assessments_sheet.cell(2, 11)).to eq risk_assessment.investigation.hazard_type
      expect(risk_assessments_sheet.cell(3, 11)).to eq risk_assessment_2.investigation.hazard_type

      expect(risk_assessments_sheet.cell(1, 12)).to eq "date_added"
      expect(risk_assessments_sheet.cell(2, 12)).to eq risk_assessment.created_at.to_formatted_s(:xmlschema)
      expect(risk_assessments_sheet.cell(3, 12)).to eq risk_assessment.created_at.to_formatted_s(:xmlschema)

      expect(corrective_actions_sheet.cell(1, 1)).to eq "psd_ref"
      expect(corrective_actions_sheet.cell(2, 1)).to eq product.psd_ref
      expect(corrective_actions_sheet.cell(3, 1)).to eq product.psd_ref

      expect(corrective_actions_sheet.cell(1, 2)).to eq "product_id"
      expect(corrective_actions_sheet.cell(2, 2)).to eq product.id.to_s
      expect(corrective_actions_sheet.cell(3, 2)).to eq product.id.to_s

      expect(corrective_actions_sheet.cell(1, 3)).to eq "case_id"
      expect(corrective_actions_sheet.cell(2, 3)).to eq corrective_action.investigation.pretty_id
      expect(corrective_actions_sheet.cell(3, 3)).to eq corrective_action_2.investigation.pretty_id

      expect(corrective_actions_sheet.cell(1, 4)).to eq "case_type"
      expect(corrective_actions_sheet.cell(2, 4)).to eq corrective_action.investigation.case_type
      expect(corrective_actions_sheet.cell(3, 4)).to eq corrective_action_2.investigation.case_type

      expect(corrective_actions_sheet.cell(1, 5)).to eq "product_name"
      expect(corrective_actions_sheet.cell(2, 5)).to eq product.name
      expect(corrective_actions_sheet.cell(3, 5)).to eq product.name

      expect(corrective_actions_sheet.cell(1, 6)).to eq "action_taken"
      expect(corrective_actions_sheet.cell(2, 6)).to eq CorrectiveAction.actions[corrective_action.action]
      expect(corrective_actions_sheet.cell(3, 6)).to eq CorrectiveAction.actions[corrective_action_2.action]

      expect(corrective_actions_sheet.cell(1, 7)).to eq "date_of_action"
      expect(corrective_actions_sheet.cell(2, 7)).to eq corrective_action.date_of_activity
      expect(corrective_actions_sheet.cell(3, 7)).to eq corrective_action_2.date_of_activity

      expect(corrective_actions_sheet.cell(1, 8)).to eq "legislation"
      expect(corrective_actions_sheet.cell(2, 8)).to eq corrective_action.legislation
      expect(corrective_actions_sheet.cell(3, 8)).to eq corrective_action_2.legislation

      expect(corrective_actions_sheet.cell(1, 9)).to eq "business_responsible"
      expect(corrective_actions_sheet.cell(2, 9)).to eq corrective_action.business_id
      expect(corrective_actions_sheet.cell(3, 9)).to eq corrective_action_2.business_id

      expect(corrective_actions_sheet.cell(1, 10)).to eq "mandatory_or_voluntary"
      expect(corrective_actions_sheet.cell(2, 10)).to eq corrective_action.measure_type
      expect(corrective_actions_sheet.cell(3, 10)).to eq corrective_action_2.measure_type

      expect(corrective_actions_sheet.cell(1, 11)).to eq "how_long"
      expect(corrective_actions_sheet.cell(2, 11)).to eq corrective_action.duration
      expect(corrective_actions_sheet.cell(3, 11)).to eq corrective_action_2.duration

      expect(corrective_actions_sheet.cell(1, 12)).to eq "geographic_scope"
      expect(corrective_actions_sheet.cell(2, 12)).to eq corrective_action.geographic_scopes
      expect(corrective_actions_sheet.cell(3, 12)).to eq corrective_action_2.geographic_scopes

      expect(corrective_actions_sheet.cell(1, 13)).to eq "recall_information_online"
      expect(corrective_actions_sheet.cell(2, 13)).to eq corrective_action.online_recall_information
      expect(corrective_actions_sheet.cell(3, 13)).to eq corrective_action_2.online_recall_information

      expect(corrective_actions_sheet.cell(1, 14)).to eq "further_details"
      expect(corrective_actions_sheet.cell(2, 14)).to eq corrective_action.details
      expect(corrective_actions_sheet.cell(3, 14)).to eq corrective_action_2.details

      expect(corrective_actions_sheet.cell(1, 15)).to eq "reported_reason"
      expect(corrective_actions_sheet.cell(2, 15)).to eq corrective_action.investigation.reported_reason
      expect(corrective_actions_sheet.cell(3, 15)).to eq corrective_action_2.investigation.reported_reason

      expect(corrective_actions_sheet.cell(1, 16)).to eq "risk_level"
      expect(corrective_actions_sheet.cell(2, 16)).to eq corrective_action.investigation.risk_level_description
      expect(corrective_actions_sheet.cell(3, 16)).to eq corrective_action_2.investigation.risk_level_description

      expect(corrective_actions_sheet.cell(1, 17)).to eq "hazard_type"
      expect(corrective_actions_sheet.cell(2, 17)).to eq corrective_action.investigation.hazard_type
      expect(corrective_actions_sheet.cell(3, 17)).to eq corrective_action_2.investigation.hazard_type

      expect(corrective_actions_sheet.cell(1, 18)).to eq "date_added"
      expect(corrective_actions_sheet.cell(2, 18)).to eq corrective_action.created_at.to_formatted_s(:xmlschema)
      expect(corrective_actions_sheet.cell(3, 18)).to eq corrective_action.created_at.to_formatted_s(:xmlschema)
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

    it "exports the product into multiple rows, each with a different case", :aggregate_failures do
      expect(products_sheet.cell(1, 1)).to eq "psd_ref"
      expect(products_sheet.cell(2, 1)).to eq product.psd_ref
      expect(products_sheet.cell(3, 1)).to eq other_product.psd_ref
      expect(products_sheet.cell(4, 1)).to eq multiple_case_product.psd_ref
      expect(products_sheet.cell(5, 1)).to eq multiple_case_product.psd_ref

      expect(products_sheet.cell(1, 3)).to eq "case_id"
      expect(products_sheet.cell(2, 3)).to eq investigation.pretty_id
      expect(products_sheet.cell(3, 3)).to eq other_investigation.pretty_id
      expect(products_sheet.cell(4, 3)).to eq investigation_a.pretty_id
      expect(products_sheet.cell(5, 3)).to eq investigation_b.pretty_id
    end
  end
end

def my_query
  { must: [{ term: { "retired?" => false } }],
    should: [user.id].map do |a|
              { match: { "investigations.owner_id" => a } }
            end }
end

def my_team_query
  { must: [{ term: { "retired?" => false } }],
    should: ([user.team.id] + user.team.users.map(&:id)).map do |a|
              { match: { "investigations.owner_id" => a } }
            end }
end

# rubocop:enable RSpec/ExampleLength
# rubocop:enable RSpec/LetSetup
