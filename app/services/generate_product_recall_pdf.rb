class GenerateProductRecallPdf
  attr_reader :params, :product, :file

  def initialize(params, product, file)
    @params = params
    @product = product
    @file = file
    preload_fonts
  end

  def self.generate_pdf(params, product, file)
    new(params, product, file).generate_pdf
  end

  def generate_pdf
    metadata = {
      Title: "OPSS - #{title} - #{params['pdf_title']}",
      Author: product.owning_team&.name,
      Subject: title,
      Creator: "Product Safety Database",
      Producer: "Prawn",
      CreationDate: Time.zone.now
    }
    pdf = Prawn::Document.new(page_size: "A4", font_size: 11, info: metadata)

    update_font_families(pdf)

    pdf.font("Arial")

    # Header
    pdf.table([
      [{ image: File.open(Rails.root.join("app/assets/images/opss-logo.jpg")), fit: [140, 140] },
       { content: title, text_color: "FF0000", font_style: :bold, size: 20, align: :right, valign: :bottom }]
    ], width: pdf.bounds.width, cell_style: { borders: [] })

    # Main Content
    pdf.table([
      [{ content: params["pdf_title"], colspan: 2, font_style: :bold, size: 14 }],
      [{ content: "Aspect", font_style: :bold }, { content: "Details", font_style: :bold }],
      [{ content: "Images", font_style: :bold }, build_sub_table(pdf)],
      [{ content: "Alert Number", font_style: :bold }, params["alert_number"]],
      [{ content: "Product Type", font_style: :bold }, [params["product_type"], params["subcategory"]].compact.join(" - ")],
      [{ content: "Product Identifiers", font_style: :bold }, params["product_identifiers"]],
      [{ content: "Product Description", font_style: :bold }, params["product_description"]],
      [{ content: "Country of Origin", font_style: :bold }, country_from_code(params["country_of_origin"])],
      [{ content: "Counterfeit", font_style: :bold }, counterfeit],
      [{ content: "Risk Type", font_style: :bold }, params["risk_type"]],
      risk_level_row,
      [{ content: "Risk Description", font_style: :bold }, params["risk_description"]],
      [{ content: "Corrective Measures", font_style: :bold }, params["corrective_actions"]],
      [{ content: "Online Marketplace", font_style: :bold }, online_marketplace],
      [{ content: "Notifier", font_style: :bold }, params["notified_by"]]
    ].compact, width: pdf.bounds.width, column_widths: { 0 => 120 })

    # Footer
    pdf.repeat :all do
      pdf.bounding_box [pdf.bounds.left, pdf.bounds.bottom + 25], width: pdf.bounds.width do
        pdf.text_box 'The OPSS Product Safety Alerts, Reports and Recalls Site can be accessed at the following link: <color rgb="#0000FF"><u><link href="https://www.gov.uk/guidance/product-recalls-and-alerts">https://www.gov.uk/guidance/product-recalls-and-alerts</link></u></color>', inline_format: true
      end
    end

    pdf.render(file)
  end

private

  def preload_fonts
    @arial_font = Rails.root.join("app/assets/fonts/arial.ttf")
    @arial_bold_font = Rails.root.join("app/assets/fonts/arial-bold.ttf")
  end

  def update_font_families(pdf)
    pdf.font_families.update(
      "Arial" => {
        normal: { file: @arial_font, font: "Arial" },
        bold: { file: @arial_bold_font, font: "Arial-Bold" }
      }
    )
  end

  def product_safety_report?
    params["type"] == "product_safety_report"
  end

  def title
    product_safety_report? ? "Product Safety Report" : "Product Recall"
  end

  def build_sub_table(pdf)
    rows = image_rows
    return if rows.blank?

    flattened_array = rows.flatten(1)
    new_array = flattened_array.each_slice(3).to_a

    pdf.make_cell(new_array, width: pdf.bounds.width - 120)
  end

  def image_rows
    return if params["product_image_ids"].blank?

    params["product_image_ids"].reject(&:blank?).map { |image_id| [image_cell(image_id)] }
  end

  def image_cell(id)
    image_upload = ImageUpload.find_by(id:, upload_model: product)
    return if image_upload.blank?

    image_upload.file_upload.blob.open do |file|
      { image: File.open(file.path), fit: [100, 100], borders: [] }
    end
  end

  def risk_level_row
    [{ content: "Risk Level", font_style: :bold }, params["risk_level"].presence || "Unknown"]
  end

  def country_from_code(code)
    Country.all.find { |c| c[1] == code }&.first || code
  end

  def counterfeit
    { "counterfeit" => "Yes", "genuine" => "No", "unsure" => "Unsure" }[params["counterfeit"]] || "Unknown"
  end

  def online_marketplace
    if params["online_marketplace"].nil?
      "N/A"
    elsif params["online_marketplace"]
      params["other_marketplace_name"].presence || params["online_marketplace_id"] || "Yes"
    else
      "No"
    end
  end
end
