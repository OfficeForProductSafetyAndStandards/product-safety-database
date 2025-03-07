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
    before do
      AddProductToNotification.call!(notification:, product:, user:)
      AddProductToNotification.call!(notification:, product: other_product, user:)
    end

    context "when case_owner is my_team" do
      let(:product_export) { described_class.create!(user:, params: { case_owner: "my_team" }) }

      it "returns the correct filter params" do
        product_export.send(:products)
        expect(product_export.send(:filter_params, user)).to eq my_team_query
      end
    end

    context "when case_owner is me" do
      let(:product_export) { described_class.create!(user:, params: { case_owner: "me" }) }

      it "returns the correct filter params" do
        product_export.send(:products)
        expect(product_export.send(:filter_params, user)).to eq my_query
      end
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
      expect(product_sheet.row(1)[0..23]).to eq %w[psd_ref ID case_id case_type category subcategory barcode brand authenticity name product_code description has_markings markings country_of_origin webpage when_placed_on_market affected_units_status number_of_affected_units batch_number customs_code created_at updated_at owning_team]
      expect(product_sheet.row(2)[0..23]).to eq [product.psd_ref, product.id.to_s, investigation.pretty_id, investigation.case_type, product.category, product.subcategory, product.barcode, product.brand, product.authenticity, product.name, product.product_code, "<p>#{new_product_description}</p>", product.has_markings, product.markings, "GB-ENG", product.webpage, product.when_placed_on_market, investigation_product.affected_units_status, investigation_product.number_of_affected_units, investigation_product.batch_number, investigation_product.customs_code, product.created_at.to_formatted_s(:xmlschema), product.updated_at.to_formatted_s(:xmlschema), product.owning_team.try(:name)]
      expect(product_sheet.row(3)[0..23]).to eq [other_product.psd_ref, other_product.id.to_s, other_investigation.pretty_id, other_investigation.case_type, other_product.category, other_product.subcategory, other_product.barcode, other_product.brand, other_product.authenticity, other_product.name, other_product.product_code, other_product.description, other_product.has_markings, other_product.markings, nil, other_product.webpage, other_product.when_placed_on_market, investigation_product_2.affected_units_status, investigation_product_2.number_of_affected_units, investigation_product_2.batch_number, investigation_product_2.customs_code, other_product.created_at.to_formatted_s(:xmlschema), other_product.updated_at.to_formatted_s(:xmlschema), other_product.owning_team.try(:name)]
    end

    it "exports test result data", :aggregate_failures do
      expect(test_result_sheet.row(1)[0..14]).to eq %w[psd_ref product_id case_id case_type product_name date_of_test legislation standards result how_product_failed further_details date_added funded_under_opss_sampling_protocol tso_sample_reference_number date_issued]
      expect(test_result_sheet.row(2)[0..14]).to eq [product.psd_ref, product.id.to_s, test.investigation.pretty_id, test.investigation.case_type, product.name, test.date_of_activity, test.legislation, test.standards_product_was_tested_against, test.result.to_s, test.failure_details.to_s, test.details.to_s, test.created_at.to_formatted_s(:xmlschema), "true", test.tso_certificate_reference_number, test.tso_certificate_issue_date.to_formatted_s(:xmlschema)]
      expect(test_result_sheet.row(3)[0..14]).to eq [product.psd_ref, product.id.to_s, test_2.investigation.pretty_id, test_2.investigation.case_type, product.name, test_2.date_of_activity, test_2.legislation, test_2.standards_product_was_tested_against, test_2.result.to_s, test_2.failure_details.to_s, test_2.details.to_s, test_2.created_at.to_formatted_s(:xmlschema), "false", nil, nil]
    end

    it "exports risk assessment data", :aggregate_failures do
      expect(risk_assessments_sheet.row(1)[0..11]).to eq %w[psd_ref product_id case_id case_type product_name date_of_assessment risk_level assessed_by further_details reported_reason hazard_type date_added]
      expect(risk_assessments_sheet.row(2)[0..11]).to eq [product.psd_ref, product.id.to_s, risk_assessment.investigation.pretty_id, risk_assessment.investigation.case_type, product.name, risk_assessment.assessed_on.to_formatted_s(:xmlschema), risk_assessment.risk_level.to_s, Team.find(risk_assessment.assessed_by_team_id).name, risk_assessment.details.to_s, risk_assessment.investigation.reported_reason, risk_assessment.investigation.hazard_type, risk_assessment.created_at.to_formatted_s(:xmlschema)]
      expect(risk_assessments_sheet.row(3)[0..11]).to eq [product.psd_ref, product.id.to_s, risk_assessment.investigation.pretty_id, risk_assessment.investigation.case_type, product.name, risk_assessment_2.assessed_on.to_formatted_s(:xmlschema), risk_assessment_2.risk_level.to_s, Team.find(risk_assessment_2.assessed_by_team_id).name, risk_assessment_2.details.to_s, risk_assessment_2.investigation.reported_reason, risk_assessment_2.investigation.hazard_type, risk_assessment_2.created_at.to_formatted_s(:xmlschema)]
    end

    it "exports corrective action data", :aggregate_failures do
      expect(corrective_actions_sheet.row(1)[0..17]).to eq %w[psd_ref product_id case_id case_type product_name action_taken date_of_action legislation business_responsible mandatory_or_voluntary how_long geographic_scope recall_information_online further_details reported_reason risk_level hazard_type date_added]
      expect(corrective_actions_sheet.row(2)[0..17]).to eq [product.psd_ref, product.id.to_s, corrective_action.investigation.pretty_id, corrective_action.investigation.case_type, product.name, CorrectiveAction.actions[corrective_action.action], corrective_action.date_of_activity, corrective_action.legislation, corrective_action.business_id, corrective_action.measure_type, corrective_action.duration, corrective_action.geographic_scopes, corrective_action.online_recall_information, corrective_action.details, corrective_action.investigation.reported_reason, corrective_action.investigation.risk_level_description, corrective_action.investigation.hazard_type, corrective_action.created_at.to_formatted_s(:xmlschema)]
      expect(corrective_actions_sheet.row(3)[0..17]).to eq [product.psd_ref, product.id.to_s, corrective_action_2.investigation.pretty_id, corrective_action_2.investigation.case_type, product.name, CorrectiveAction.actions[corrective_action_2.action], corrective_action_2.date_of_activity, corrective_action_2.legislation, corrective_action_2.business_id, corrective_action_2.measure_type, corrective_action_2.duration, corrective_action_2.geographic_scopes, corrective_action_2.online_recall_information, corrective_action_2.details, corrective_action_2.investigation.reported_reason, corrective_action_2.investigation.risk_level_description, corrective_action_2.investigation.hazard_type, corrective_action_2.created_at.to_formatted_s(:xmlschema)]
    end
  end

  context "when there is a product with multiple cases" do
    let(:investigation_a) { create(:allegation).decorate }
    let(:investigation_b) { create(:allegation).decorate }
    let!(:multiple_case_product) { create(:product, investigations: [investigation_a, investigation_b]).decorate }

    let(:spreadsheet) { product_export.to_spreadsheet.to_stream }
    let(:exported_data) { Roo::Excelx.new(spreadsheet) }
    let(:products_sheet) { exported_data.sheet("product_info") }

    it "exports the product into multiple rows, each with a different case", :aggregate_failures do
      expect(products_sheet.cell(1, 1)).to eq "psd_ref"
      expect(products_sheet.cell(2, 1)).to eq product.psd_ref
      expect(products_sheet.cell(3, 1)).to eq other_product.psd_ref
      expect(products_sheet.cell(4, 1)).to eq multiple_case_product.psd_ref
      expect(products_sheet.cell(5, 1)).to eq multiple_case_product.psd_ref
    end

    it "exports the product investigation id's into multiple rows, each with a different case", :aggregate_failures do
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
