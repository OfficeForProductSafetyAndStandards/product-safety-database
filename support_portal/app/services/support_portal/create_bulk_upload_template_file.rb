require "support_portal/xlsx_utils"

module SupportPortal
  class CreateBulkUploadTemplateFile
    include Interactor
    include SupportPortal::XlsxUtils

    delegate :product_taxonomy_import, to: :context

    def call
      context.fail!(error: "No product taxonomy import supplied") unless product_taxonomy_import.is_a?(ProductTaxonomyImport)

      # Create a bulk upload template file
      export_package = Axlsx::Package.new
      export_workbook = export_package.workbook

      # Add all the content
      create_main_worksheet(export_workbook)
      create_hidden_worksheets(export_workbook)

      # Create the XLSX
      output_file = serialize_to_file(type: "bulk_upload_template", axlsx_package: export_package)

      # Attach to the product taxonomy import
      attach_to_model(model: product_taxonomy_import.bulk_upload_template_file, file: output_file)

      product_taxonomy_import.mark_as_bulk_upload_template_created!
    end

  private

    def create_main_worksheet(export_workbook)
      export_workbook.add_worksheet(name: "Non compliance Form") do |sheet|
        styles = add_styles(sheet)
        add_header_rows(sheet, styles)
        add_content_rows(sheet, styles)
        add_data_validations(sheet)
        set_column_widths(sheet)
      end
    end

    def add_styles(sheet)
      {
        title: sheet.styles.add_style(sz: 20, b: true, alignment: { horizontal: :center }),
        heading: sheet.styles.add_style(b: true, u: true, alignment: { horizontal: :center }, bg_color: "004472C4", fg_color: "FFFFFFFF", border: { style: :medium, color: "00000000", edges: %i[top bottom] }),
        bold: sheet.styles.add_style(b: true),
        bg_grey: sheet.styles.add_style(bg_color: "00D9D9D9", border: { style: :thin, color: "00AAAAAA", edges: %i[left right] }),
        bg_white: sheet.styles.add_style(bg_color: "FFFFFFFF", border: { style: :thin, color: "00AAAAAA", edges: %i[left right] })
      }
    end

    def add_header_rows(sheet, styles)
      # Add note and title
      sheet.add_row(["* - Depicts a mandatory field"], style: styles[:bold])
      sheet.merge_cells("A1:N1")
      sheet.add_row(["PSD High Volume Product Entry - Non-compliance form"], style: styles[:title])
      sheet.merge_cells("A2:N2")
      # Add headings
      sheet.add_row(BulkProductsUploadProductsFileForm::WORKSHEET_HEADERS, style: styles[:heading])
    end

    def add_content_rows(sheet, styles)
      # Add some starter rows
      empty_rest_of_row = Array.new(13) { "" }
      sheet.add_row(["1", *empty_rest_of_row], style: styles[:bg_grey])
      sheet.add_row(["2", *empty_rest_of_row], style: styles[:bg_white])
      sheet.add_row(["3", *empty_rest_of_row], style: styles[:bg_grey])
      sheet.add_row(["4", *empty_rest_of_row], style: styles[:bg_white])
      # Add alternating stripes to "make space" for adding products (1138 matches the original template)
      empty_row = Array.new(14) { "" }
      1138.times { |index| sheet.add_row(empty_row, style: index.odd? ? styles[:bg_white] : styles[:bg_grey]) }
    end

    def add_data_validations(sheet)
      sheet.add_data_validation("B4:B1145", type: :list, formula1: "Categories!$A$1:$A$#{::ProductCategory.count}")
      sheet.add_data_validation("C4:C1145", type: :list, formula1: "Subcategories!$A$1:$A$#{::ProductSubcategory.count}")
      sheet.add_data_validation("E4:E1145", type: :list, formula1: "Countries!$A$1:$A$#{::Country.all.length}")
      sheet.add_data_validation("L4:L1145", type: :list, formula1: '"Yes, No, Uncertain"')
      sheet.add_data_validation("M4:M1145", type: :list, formula1: "Markings!$A$1:$A$9")
      sheet.add_data_validation("N4:N1145", type: :list, formula1: '"Yes, No, Unable to ascertain"')
    end

    def set_column_widths(sheet)
      sheet.column_info[0].width = 20
    end

    def create_hidden_worksheets(export_workbook)
      # Add hidden worksheets to support data validations
      export_workbook.add_worksheet(name: "Categories", state: :hidden) do |sheet|
        ::ProductCategory.all.find_each do |category|
          sheet.add_row([category.name])
        end
      end

      export_workbook.add_worksheet(name: "Subcategories", state: :hidden) do |sheet|
        ::ProductSubcategory.all.find_each do |subcategory|
          sheet.add_row([subcategory.name])
        end
      end

      export_workbook.add_worksheet(name: "Countries", state: :hidden) do |sheet|
        ::Country.all.each do |country| # rubocop:disable Rails/FindEach
          sheet.add_row([country[0]])
        end
      end

      # If you change these, you must also update the data validation formula that references this worksheet.
      export_workbook.add_worksheet(name: "Markings", state: :hidden) do |sheet|
        sheet.add_row(%w[UKCA])
        sheet.add_row(%w[UKNI])
        sheet.add_row(%w[CE])
        sheet.add_row(["UKCA, UKNI"])
        sheet.add_row(["UKCA, CE"])
        sheet.add_row(["UKNI, CE"])
        sheet.add_row(["UKCA, UKNI, CE"])
        sheet.add_row(%w[No])
        sheet.add_row(%w[Unknown])
      end
    end
  end
end
