class ProductExport < ApplicationRecord
  # Helps to manage the database query execution time within the PaaS imposed limits
  FIND_IN_BATCH_SIZE = 1000

  has_one_attached :export_file

  redacted_export_with :id, :created_at, :updated_at

  def export(product_ids)
    raise "No products to export" unless product_ids.length.positive?

    spreadsheet = to_spreadsheet(product_ids).to_stream
    self.export_file = { io: spreadsheet, filename: "products_export.xlsx" }

    raise "No file attached" unless export_file.attached?

    save!
  end

  def to_spreadsheet(product_ids)
    product_ids.each_slice(FIND_IN_BATCH_SIZE) do |batch_product_ids|
      find_products(batch_product_ids).each { |product| add_product_to_sheets(product) }
    end

    package
  end

private

  def find_products(ids)
    Product
      .includes([:investigations, :test_results, { corrective_actions: [:business], risk_assessments: %i[assessed_by_business assessed_by_team] }])
      .find(ids)
  end

  def add_product_to_sheets(product)
    product_info_sheet.add_row(attributes_for_info_sheet(product), types: :text)

    product.test_results.sort.each do |test_result|
      test_results_sheet.add_row(attributes_for_test_results_sheet(product, test_result), types: :text)
    end

    product.risk_assessments.sort.each do |risk_assessment|
      risk_assessments_sheet.add_row(attributes_for_risk_assessments_sheet(product, risk_assessment), types: :text)
    end

    product.corrective_actions.sort.each do |corrective_action|
      corrective_actions_sheet.add_row(attributes_for_corrective_actions_sheet(product, corrective_action), types: :text)
    end
  end

  def package
    @package ||= Axlsx::Package.new
  end

  def product_info_sheet
    return @product_info_sheet if @product_info_sheet

    sheet = package.workbook.add_worksheet name: "product_info"
    sheet.add_row %w[ID
                     affected_units_status
                     authenticity
                     barcode
                     batch_number
                     brand
                     case_ids
                     category
                     country_of_origin
                     created_at
                     customs_code
                     description
                     has_markings
                     markings
                     name
                     number_of_affected_units
                     product_code
                     subcategory
                     updated_at
                     webpage
                     when_placed_on_market
                     reported_reason
                     hazard_type
                     non_compliant_reason
                     risk_level
                     name]

    @product_info_sheet = sheet
  end

  def test_results_sheet
    return @test_results_sheet if @test_results_sheet

    sheet = package.workbook.add_worksheet name: "test_results"
    sheet.add_row %w[product_id legislation standards date_of_test result how_product_failed further_details product_name]

    @test_results_sheet = sheet
  end

  def risk_assessments_sheet
    return @risk_assessments_sheet if @risk_assessments_sheet

    sheet = package.workbook.add_worksheet name: "risk_assessments"
    sheet.add_row %w[product_id date_of_assessment risk_level assessed_by further_details product_name]

    @risk_assessments_sheet = sheet
  end

  def corrective_actions_sheet
    return @corrective_actions_sheet if @corrective_actions_sheet

    sheet = package.workbook.add_worksheet name: "corrective_actions"
    sheet.add_row %w[product_id
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

  def attributes_for_info_sheet(product)
    [
      product.id,
      product.affected_units_status,
      product.authenticity,
      product.barcode,
      product.batch_number,
      product.brand,
      product.investigations.map(&:pretty_id).join(","),
      product.category,
      product.country_of_origin,
      product.created_at,
      product.customs_code,
      product.description,
      product.has_markings,
      product.markings.try(:join, ","),
      product.name,
      product.number_of_affected_units,
      product.product_code,
      product.subcategory,
      product.updated_at,
      product.webpage,
      product.when_placed_on_market,
      product.investigations.first.try(:reported_reason),
      product.investigations.first.try(:hazard_type),
      product.investigations.first.try(:non_compliant_reason),
      product.investigations.first.try(:risk_level)
    ]
  end

  def attributes_for_test_results_sheet(product, test_result)
    [
      product.id,
      test_result.legislation,
      test_result.standards_product_was_tested_against.try(:join, ","),
      test_result.date,
      test_result.result,
      test_result.failure_details,
      test_result.details,
      product.name
    ]
  end

  def attributes_for_risk_assessments_sheet(product, risk_assessment)
    [
      product.id,
      risk_assessment.assessed_on,
      risk_assessment.risk_level,
      risk_assessment.decorate.assessed_by,
      risk_assessment.details,
      product.name
    ]
  end

  def attributes_for_corrective_actions_sheet(product, corrective_action)
    [
      product.id,
      corrective_action.decorate.page_title,
      corrective_action.date_decided,
      corrective_action.legislation,
      corrective_action.business.try(:legal_name),
      corrective_action.online_recall_information,
      corrective_action.measure_type,
      corrective_action.duration,
      corrective_action.geographic_scopes.join(","),
      corrective_action.details,
      product.name
    ]
  end
end
