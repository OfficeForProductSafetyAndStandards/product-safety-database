module TestsHelper
  def test_result_summary_rows(test_result)
    rows = [
      {
        key: { text: "Date of test" },
        value: { text: test_result.date.to_s(:govuk) }
      },
      {
        key: { text: "Product tested" },
        value: { html: link_to(test_result.product.name, product_path(test_result.product)) }
      },
      {
        key: { text: "Legislation" },
        value: { text: test_result.legislation }
      },
      {
        key: { text: "Result" },
        value: { text: test_result.result.upcase_first }
      }
    ]

    if test_result.details.present?
      rows << {
        key: { text: "Further details" },
        value: { text: test_result.details }
      }
    end

    test_result.documents.each do |document|
      attachment_description = document.blob.metadata["description"]

      next if attachment_description.blank?

      rows << {
        key: { text: "Attachment description" },
        value: { text: attachment_description }
      }
    end

    rows
  end
end
