class ProductExport < ApplicationRecord
  include ProductsHelper
  include SearchHelper

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
    # Filter investigations once
    valid_products_investigations = product.investigation_products.uniq(&:investigation_id).reject { |ip| draft_notifcation?(ip.investigation.decorate) }
    valid_products_investigations_lookup = valid_products_investigations.map(&:investigation_id)

    valid_products_investigations.each do |investigation_product|
      product_info_sheet.add_row(attributes_for_info_sheet(product, investigation_product:), types: :text)
    end

    product.test_results.sort.each do |test_result|
      next unless valid_products_investigations_lookup.include?(test_result.investigation_id)

      test_results_sheet.add_row(attributes_for_test_results_sheet(product, test_result.decorate), types: :text)
    end

    product.risk_assessments.sort.each do |risk_assessment|
      next unless valid_products_investigations_lookup.include?(risk_assessment.investigation_id)

      risk_assessments_sheet.add_row(attributes_for_risk_assessments_sheet(product, risk_assessment.decorate), types: :text)
    end

    product.corrective_actions.sort.each do |corrective_action|
      next unless valid_products_investigations_lookup.include?(corrective_action.investigation_id)

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
                     case_id
                     case_type
                     category
                     subcategory
                     barcode
                     brand
                     authenticity
                     name
                     product_code
                     description
                     has_markings
                     markings
                     country_of_origin
                     webpage
                     when_placed_on_market
                     affected_units_status
                     number_of_affected_units
                     batch_number
                     customs_code
                     created_at
                     updated_at
                     owning_team]

    @product_info_sheet = sheet
  end

  def test_results_sheet
    return @test_results_sheet if @test_results_sheet

    sheet = package.workbook.add_worksheet name: "test_results"
    sheet.add_row %w[psd_ref
                     product_id
                     case_id
                     case_type
                     product_name
                     date_of_test
                     legislation
                     standards
                     result
                     how_product_failed
                     further_details
                     date_added
                     funded_under_opss_sampling_protocol
                     tso_sample_reference_number
                     date_issued]

    @test_results_sheet = sheet
  end

  def risk_assessments_sheet
    return @risk_assessments_sheet if @risk_assessments_sheet

    sheet = package.workbook.add_worksheet name: "risk_assessments"
    sheet.add_row %w[psd_ref
                     product_id
                     case_id
                     case_type
                     product_name
                     date_of_assessment
                     risk_level
                     assessed_by
                     further_details
                     reported_reason
                     hazard_type
                     date_added]

    @risk_assessments_sheet = sheet
  end

  def corrective_actions_sheet
    return @corrective_actions_sheet if @corrective_actions_sheet

    sheet = package.workbook.add_worksheet name: "corrective_actions"
    sheet.add_row %w[psd_ref
                     product_id
                     case_id
                     case_type
                     product_name
                     action_taken
                     date_of_action
                     legislation
                     business_responsible
                     mandatory_or_voluntary
                     how_long
                     geographic_scope
                     recall_information_online
                     further_details
                     reported_reason
                     risk_level
                     hazard_type
                     date_added]

    @corrective_actions_sheet = sheet
  end

  def attributes_for_info_sheet(product, investigation_product:)
    investigation = investigation_product.investigation.decorate
    [
      product.psd_ref,
      product.id,
      investigation.pretty_id,
      investigation.case_type || "case",
      product.category,
      product.subcategory,
      product.barcode,
      product.brand,
      product.authenticity,
      product.name,
      product.product_code,
      product.description,
      product.has_markings,
      product.markings,
      format_country_code(code: product.country_of_origin),
      product.webpage,
      product.when_placed_on_market,
      investigation_product.affected_units_status,
      investigation_product.number_of_affected_units,
      investigation_product.batch_number,
      investigation_product.customs_code,
      product.created_at.to_formatted_s(:xmlschema),
      product.updated_at.to_formatted_s(:xmlschema),
      product.owning_team.try(:name)
    ]
  end

  def attributes_for_test_results_sheet(product, test_result)
    investigation = test_result.investigation.decorate
    [
      product.psd_ref,
      product.id,
      test_result.case_id,
      investigation.case_type || "case",
      product.name,
      test_result.date_of_activity,
      test_result.legislation,
      test_result.standards_product_was_tested_against,
      test_result.result,
      test_result.failure_details,
      restricted_field(test_result.details),
      test_result.created_at.to_formatted_s(:xmlschema),
      test_result.tso_certificate_issue_date.present?,
      test_result.tso_certificate_reference_number,
      test_result.tso_certificate_issue_date&.to_formatted_s(:xmlschema),
    ]
  end

  def attributes_for_risk_assessments_sheet(product, risk_assessment)
    investigation = risk_assessment.investigation.decorate
    [
      product.psd_ref,
      product.id,
      risk_assessment.case_id,
      investigation.case_type || "case",
      product.name,
      risk_assessment.assessed_on.to_formatted_s(:xmlschema),
      risk_assessment.risk_level,
      risk_assessment.decorate.assessed_by,
      restricted_field(risk_assessment.details),
      investigation.reported_reason,
      investigation.hazard_type,
      risk_assessment.created_at.to_formatted_s(:xmlschema)
    ]
  end

  def attributes_for_corrective_actions_sheet(product, corrective_action)
    investigation = corrective_action.investigation.decorate
    [
      product.psd_ref,
      product.id,
      corrective_action.case_id,
      investigation.case_type || "case",
      product.name,
      corrective_action.decorate.page_title,
      corrective_action.date_of_activity,
      corrective_action.legislation,
      corrective_action.business.try(:legal_name),
      corrective_action.measure_type,
      corrective_action.duration,
      corrective_action.geographic_scopes,
      corrective_action.online_recall_information,
      restricted_field(corrective_action.details),
      investigation.reported_reason,
      investigation.risk_level_description,
      investigation.hazard_type,
      corrective_action.created_at.to_formatted_s(:xmlschema)
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

  def draft_notifcation?(investigation)
    return true if investigation.state == "draft" && investigation.type == "Investigation::Notification"

    false
  end
end
