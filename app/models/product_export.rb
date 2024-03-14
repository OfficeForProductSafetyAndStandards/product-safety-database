class ProductExport < ApplicationRecord
  include ProductsHelper

  belongs_to :user
  has_one_attached :export_file

  redacted_export_with :id, :created_at, :updated_at

  def params
    self[:params].deep_symbolize_keys
  end

  def export!
    raise "No products to export" unless products.length.positive?

    spreadsheet = to_spreadsheet.to_stream
    self.export_file = { io: spreadsheet, filename: "products_export.xlsx" }

    raise "No file attached" unless export_file.attached?

    save!
  end

  def to_spreadsheet
    products.each { |product| add_product_to_sheets(product.decorate) }

    package
  end

private

  def products
    @search = SearchParams.new(params)
    search_for_products(user, for_export: true).sort
  end

  def add_product_to_sheets(product)
    product.investigation_products.uniq(&:investigation_id).each do |investigation_product|
      product_info_sheet.add_row(attributes_for_info_sheet(product, investigation_product:), types: :text)
    end

    product.test_results.sort.each do |test_result|
      test_results_sheet.add_row(attributes_for_test_results_sheet(product, test_result.decorate), types: :text)
    end

    product.risk_assessments.sort.each do |risk_assessment|
      risk_assessments_sheet.add_row(attributes_for_risk_assessments_sheet(product, risk_assessment.decorate), types: :text)
    end

    product.corrective_actions.sort.each do |corrective_action|
      corrective_actions_sheet.add_row(attributes_for_corrective_actions_sheet(product, corrective_action.decorate), types: :text)
    end
  end

  def package
    @package ||= Axlsx::Package.new
  end

  def product_info_sheet
    return @product_info_sheet if @product_info_sheet

    sheet = package.workbook.add_worksheet name: "product_info"
    sheet.add_row %w[psd_ref
                     ID
                     authenticity
                     barcode
                     brand
                     case_id
                     category
                     country_of_origin
                     created_at
                     description
                     has_markings
                     markings
                     name
                     product_code
                     subcategory
                     updated_at
                     webpage
                     when_placed_on_market
                     owning_team
                     affected_units_status
                     number_of_affected_units
                     batch_number
                     customs_code
                     case_type]

    @product_info_sheet = sheet
  end

  def test_results_sheet
    return @test_results_sheet if @test_results_sheet

    sheet = package.workbook.add_worksheet name: "test_results"
    sheet.add_row %w[psd_ref
                     product_id
                     legislation
                     standards
                     date_of_test
                     result
                     how_product_failed
                     further_details
                     product_name
                     case_id
                     case_type]

    @test_results_sheet = sheet
  end

  def risk_assessments_sheet
    return @risk_assessments_sheet if @risk_assessments_sheet

    sheet = package.workbook.add_worksheet name: "risk_assessments"
    sheet.add_row %w[psd_ref
                     product_id
                     date_of_assessment
                     risk_level
                     assessed_by
                     further_details
                     product_name
                     case_id
                     reported_reason
                     hazard_type
                     case_type]

    @risk_assessments_sheet = sheet
  end

  def corrective_actions_sheet
    return @corrective_actions_sheet if @corrective_actions_sheet

    sheet = package.workbook.add_worksheet name: "corrective_actions"
    sheet.add_row %w[psd_ref
                     product_id
                     action_taken
                     date_of_action
                     legislation
                     business_responsible
                     recall_information_online
                     mandatory_or_voluntary
                     how_long
                     geographic_scope
                     further_details
                     product_name
                     case_id
                     reported_reason
                     hazard_type
                     risk_level
                     case_type]

    @corrective_actions_sheet = sheet
  end

  def attributes_for_info_sheet(product, investigation_product:)
    investigation = investigation_product.investigation.decorate
    [
      product.psd_ref,
      product.id,
      product.authenticity,
      product.barcode,
      product.brand,
      investigation.pretty_id,
      product.category,
      format_country_code(code: product.country_of_origin),
      product.created_at.to_formatted_s(:xmlschema),
      product.description,
      product.has_markings,
      product.markings,
      product.name,
      product.product_code,
      product.subcategory,
      product.updated_at.to_formatted_s(:xmlschema),
      product.webpage,
      product.when_placed_on_market,
      product.owning_team.try(:name),
      investigation_product.affected_units_status,
      investigation_product.number_of_affected_units,
      investigation_product.batch_number,
      investigation_product.customs_code,
      investigation.case_type || "case"
    ]
  end

  def attributes_for_test_results_sheet(product, test_result)
    investigation = test_result.investigation.decorate
    [
      product.psd_ref,
      product.id,
      test_result.legislation,
      test_result.standards_product_was_tested_against,
      test_result.date_of_activity,
      test_result.result,
      test_result.failure_details,
      restricted_field(test_result.details),
      product.name,
      test_result.case_id,
      investigation.case_type || "case"
    ]
  end

  def attributes_for_risk_assessments_sheet(product, risk_assessment)
    investigation = risk_assessment.investigation.decorate
    [
      product.psd_ref,
      product.id,
      risk_assessment.assessed_on.to_formatted_s(:xmlschema),
      risk_assessment.risk_level,
      risk_assessment.decorate.assessed_by,
      restricted_field(risk_assessment.details),
      product.name,
      risk_assessment.case_id,
      investigation.reported_reason,
      investigation.hazard_type,
      investigation.case_type || "case"
    ]
  end

  def attributes_for_corrective_actions_sheet(product, corrective_action)
    investigation = corrective_action.investigation.decorate
    [
      product.psd_ref,
      product.id,
      corrective_action.decorate.page_title,
      corrective_action.date_of_activity,
      corrective_action.legislation,
      corrective_action.business.try(:legal_name),
      corrective_action.online_recall_information,
      corrective_action.measure_type,
      corrective_action.duration,
      corrective_action.geographic_scopes,
      restricted_field(corrective_action.details),
      product.name,
      corrective_action.case_id,
      investigation.reported_reason,
      investigation.hazard_type,
      investigation.risk_level_description,
      investigation.case_type || "case"
    ]
  end

  def format_country_code(code:)
    return if code.blank?

    code.split(":")&.last
  end

  def filter_params(user)
    must_match_filters = [
      get_category_filter,
      get_status_filter,
      get_retired_filter
    ].compact

    should_match_filters = [
      get_owner_filter(user)
    ].compact.flatten

    { must: must_match_filters, should: should_match_filters }
  end

  def get_category_filter
    if params[:category].present?
      { match_phrase: { "category" => @search.category } }
    end
  end

  def get_status_filter
    if @search.case_status == "open_only"
      { term: { "investigations.is_closed" => "false" } }
    end
  end

  def get_retired_filter
    return if @search.retired_status == "all"

    if @search.retired_status == "active" || @search.retired_status.blank?
      return { term: { "retired?" => false } }
    end

    if @search.retired_status == "retired"
      { term: { "retired?" => true } }
    end
  end

  def restricted_field(text)
    return text if user.is_opss?

    "Restricted"
  end
end
