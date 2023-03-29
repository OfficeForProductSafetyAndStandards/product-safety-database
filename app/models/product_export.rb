class ProductExport < ApplicationRecord
  include ProductSearchHelper

  # Helps to manage the database query execution time within the PaaS imposed limits
  FIND_IN_BATCH_SIZE = 1000

  belongs_to :user
  has_one_attached :export_file

  redacted_export_with :id, :created_at, :updated_at

  def params
    self[:params].deep_symbolize_keys
  end

  def export!
    raise "No products to export" unless product_ids.length.positive?

    spreadsheet = to_spreadsheet.to_stream
    self.export_file = { io: spreadsheet, filename: "products_export.xlsx" }

    raise "No file attached" unless export_file.attached?

    save!
  end

  def to_spreadsheet
    product_ids.each_slice(FIND_IN_BATCH_SIZE) do |batch_product_ids|
      find_products(batch_product_ids).each { |product| add_product_to_sheets(product.decorate) }
    end

    package
  end

private

  def product_ids
    return @product_ids if @product_ids

    @search = SearchParams.new(params)
    query = search_query(user)
    @product_ids = Product.search_in_batches(query).map(&:id)
  end

  def find_products(ids)
    Product
      .includes([:investigations, :owning_team, { investigation_products: [:test_results, { corrective_actions: [:business], risk_assessments: %i[assessed_by_business assessed_by_team] }] }])
      .find(ids)
  end

  def add_product_to_sheets(product)
    product.case_ids.each do |case_id|
      product_info_sheet.add_row(attributes_for_info_sheet(product, case_id:), types: :text)
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
                     owning_team]

    @product_info_sheet = sheet
  end

  def test_results_sheet
    return @test_results_sheet if @test_results_sheet

    sheet = package.workbook.add_worksheet name: "test_results"
    sheet.add_row %w[psd_ref product_id legislation standards date_of_test result how_product_failed further_details product_name]

    @test_results_sheet = sheet
  end

  def risk_assessments_sheet
    return @risk_assessments_sheet if @risk_assessments_sheet

    sheet = package.workbook.add_worksheet name: "risk_assessments"
    sheet.add_row %w[psd_ref product_id date_of_assessment risk_level assessed_by further_details product_name]

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
                     product_name]

    @corrective_actions_sheet = sheet
  end

  def attributes_for_info_sheet(product, case_id:)
    [
      product.psd_ref,
      product.id,
      product.authenticity,
      product.barcode,
      product.brand,
      case_id,
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
      product.owning_team.try(:name)
    ]
  end

  def attributes_for_test_results_sheet(product, test_result)
    [
      product.psd_ref,
      product.id,
      test_result.legislation,
      test_result.standards_product_was_tested_against,
      test_result.date_of_activity,
      test_result.result,
      test_result.failure_details,
      test_result.details,
      product.name
    ]
  end

  def attributes_for_risk_assessments_sheet(product, risk_assessment)
    [
      product.psd_ref,
      product.id,
      risk_assessment.assessed_on.to_formatted_s(:xmlschema),
      risk_assessment.risk_level,
      risk_assessment.decorate.assessed_by,
      risk_assessment.details,
      product.name
    ]
  end

  def attributes_for_corrective_actions_sheet(product, corrective_action)
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
      corrective_action.details,
      product.name
    ]
  end

  def format_country_code(code:)
    return if code.blank?

    code.split(":")&.last
  end
end
