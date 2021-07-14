class ProductExportWorker < ApplicationJob
  def perform(products, product_export_id)
    product_export = ProductExport.find(product_export_id)
    return unless product_export

    Axlsx::Package.new do |p|
      book = p.workbook
      book.add_worksheet name: "product_info" do |sheet_investigations| # rubocop:disable Metrics/BlockLength
        sheet_investigations.add_row %w[ID affected_units_status authenticity barcode batch_number brand case_ids category country_of_origin
                                        created_at customs_code description has_markings markings name number_of_affected_units product_code
                                        subcategory updated_at webpage when_placed_on_market reported_reason hazard_type non_compliant_reason risk_level name]
        products.each do |product|
          sheet_investigations.add_row [
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
          ], types: :text
        end
      end

      book.add_worksheet name: "test_results" do |sheet_investigations| # rubocop:disable Metrics/BlockLength
        sheet_investigations.add_row %w[product_id legislation standards date_of_test result how_product_failed further_details product_name]
        products.each do |product|
          product.tests.where(type: "Result").sort.each do |test_result|
            sheet_investigations.add_row [
              product.id,
              test_result.legislation,
              test_result.standards_product_was_tested_against.try(:join, ","),
              test_result.date,
              test_result.result,
              test_result.failure_details,
              test_result.details,
              product.name
            ], types: :text
          end
        end
      end

      book.add_worksheet name: "risk_assessments" do |sheet_investigations| # rubocop:disable Metrics/BlockLength
        sheet_investigations.add_row %w[product_id date_of_assessment risk_level assessed_by further_details product_name]
        products.each do |product|
          product.risk_assessments.sort.each do |risk_assessment|
            sheet_investigations.add_row [
              product.id,
              risk_assessment.assessed_on,
              risk_assessment.risk_level,
              risk_assessment.decorate.assessed_by,
              risk_assessment.details,
              product.name
            ], types: :text
          end
        end
      end

      book.add_worksheet name: "corrective_actions" do |sheet_investigations| # rubocop:disable Metrics/BlockLength
        sheet_investigations.add_row %w[product_id action_taken date_of_action legislation business_responsible
                                        recall_information_online mandatory_or_voluntary how_long geographic_scope further_details product_name]
        products.each do |product|
          product.corrective_actions.sort.each do |corrective_action|
            sheet_investigations.add_row [
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
            ], types: :text
          end
        end
      end
      p.serialize(Rails.root.join("xxxx.xlsx"))

      product_export.export_file.attach(io: File.open(Rails.root.join("xxxx.xlsx")), filename: "new.xlsx")
    end
  end
end
