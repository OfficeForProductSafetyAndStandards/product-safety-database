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

      # Add all the content and data validations
      main_worksheet = create_main_worksheet(export_workbook)
      product_categories_worksheet = create_hidden_worksheets(export_workbook)
      add_data_validations(export_workbook, main_worksheet, product_categories_worksheet)

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
        set_column_widths(sheet)
        sheet
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

    def set_column_widths(sheet)
      sheet.column_info[0].width = 20
    end

    def create_hidden_worksheets(export_workbook)
      # Add hidden worksheets to support data validations
      product_categories_worksheet = export_workbook.add_worksheet(name: "Product categories", state: :hidden) do |sheet|
        # Get all product subcategories grouped by their parent product category
        grouped_product_subcategories = ::ProductSubcategory.joins(:product_category).reorder("product_categories.name ASC, product_subcategories.name ASC").group_by(&:product_category)

        # Add empty rows and columns for all the data we'll need
        # This is required since Axlsx works with sparse worksheets, hence cells are not accessible until a row including them has been added
        empty_row = Array.new(grouped_product_subcategories.length + 1) { "" } # one column per category plus one for the list of categories
        max_subcategories_count = grouped_product_subcategories.max_by { |_, product_subcategories| product_subcategories.length }&.last&.length || 0
        (max_subcategories_count + 1).times { sheet.add_row(empty_row) }

        # Add product categories in column A, and associated product subcategories in consecutive columns with the product category as the heading
        sheet.rows[0].cells[0].value = "Product category*"
        grouped_product_subcategories.each_with_index do |(product_category, product_subcategories), product_category_index|
          next_cell_index = product_category_index + 1

          sheet.rows[next_cell_index].cells[0].value = product_category.name
          sheet.rows[0].cells[next_cell_index].value = product_category.name

          product_subcategories.each_with_index do |product_subcategory, product_subcategory_index|
            sheet.rows[product_subcategory_index + 1].cells[next_cell_index].value = product_subcategory.name
          end
        end
      end

      export_workbook.add_worksheet(name: "Countries", state: :hidden) do |sheet|
        ::Country.all.each do |country| # rubocop:disable Rails/FindEach
          sheet.add_row([country[0]])
        end
      end

      # If you change these, you must also update the data validation formula that references this worksheet in `add_data_validations`
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

      product_categories_worksheet
    end

    def add_data_validations(export_workbook, main_worksheet, product_categories_worksheet)
      # Add defined names to support the product category/subcategory data validations
      # These limit the product category column, and the product subcategory column to the relevant product subcategories
      # See https://www.contextures.com/xlDataVal15.html for more information on dependent lists
      export_workbook.add_defined_name("'Product categories'!$A$2:INDEX('Product categories'!$A:$A,COUNTA('Product categories'!$A:$A))", name: "Master")
      export_workbook.add_defined_name("'Product categories'!$A$2:INDEX('Product categories'!$1:$#{product_categories_worksheet.rows.length},#{product_categories_worksheet.rows.length},COUNTA('Product categories'!$1:$1))", name: "ValData")
      export_workbook.add_defined_name("COUNTA(INDEX(ValData,,MATCH('Non compliance Form'!XFD1,'Product categories'!$1:$1,0)))", name: "Counter")
      export_workbook.add_defined_name("INDEX(ValData,1,MATCH('Non compliance Form'!XFD1,'Product categories'!$1:$1,0)): INDEX(ValData,Counter,MATCH('Non compliance Form'!XFD1,'Product categories'!$1:$1,0))", name: "UseList")

      main_worksheet.add_data_validation("B4:B1145", type: :list, formula1: "Master")
      main_worksheet.add_data_validation("C4:C1145", type: :list, formula1: "UseList")
      main_worksheet.add_data_validation("E4:E1145", type: :list, formula1: "Countries!$A$1:$A$#{::Country.all.length}")
      main_worksheet.add_data_validation("L4:L1145", type: :list, formula1: '"Yes, No, Uncertain"')
      main_worksheet.add_data_validation("M4:M1145", type: :list, formula1: "Markings!$A$1:$A$9")
      main_worksheet.add_data_validation("N4:N1145", type: :list, formula1: '"Yes, No, Unable to ascertain"')
    end
  end
end
